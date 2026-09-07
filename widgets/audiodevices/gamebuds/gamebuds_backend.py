#!/usr/bin/env python3
"""
GameBuds RFCOMM/SPP backend UNVERIFIED!!!

This has been built from analyzing a decompiled Arctis Companion APK
(com.steelseries.arctiscompanion 6.7.0).

From the decompiled project TransportLayerPacket.java (symmetric
encode/parse, no CRC):
  - framing: sync(1)=0xAA, seq(1), length(2 LE) = 2+len(payload),
    eventId(2 LE) = 0x3000 (command) or 0x3002 (sync/notify), payload(N)
  - transport: Bluetooth SPP/RFCOMM, standard UUID 0x1101
    (Consts.BLUETOOTH_SPP_UUID)

Output format (one JSON line per received frame):
  {"connected": true}
  {"event": "sync", "opcode": "0xc6", "name": "SYNC_WEAR_SENSE_STATUS",
   "raw": "aa00040000c601", "decoded": {"wear_sense_status": true}}
  {"event": "reply", "opcode": "0xc5", "name": "SET_WEAR_SENSE_CONFIG",
   "raw": "..."}

Command format (one JSON object per line on stdin)
Taken from GameBudsBTService.java:
  {"cmd": "get_headset_status"}
  {"cmd": "set_wear_sense_config", "enabled": true}
  {"cmd": "set_transparent_anc_enabled", "mode": "off|transparency|anc"}
  {"cmd": "set_anc_level", "value": 1..3}           # raw passthrough
  {"cmd": "set_transparent_level", "value": 1..3}   # UI level, device-mapped
  {"cmd": "set_mic_muted", "enabled": true}
  {"cmd": "set_mic_level", "value": 1..10}          # raw passthrough
  {"cmd": "set_sidetone_level", "value": 0..3}      # UI level, device-mapped
  {"cmd": "set_bluetooth_volume", "value": 0..15}   # raw passthrough
  {"cmd": "set_24g_volume", "value": 0..15}         # raw passthrough
  {"cmd": "set_auto_off_timer", "value": 0..255}    # minutes, raw passthrough
                                                    # (QA menu only used 0..90?)
  {"cmd": "set_volume_limiter", "enabled": true}
  {"cmd": "set_audio_mode", "mode": "2.4g|bt"}
  {"cmd": "raw", "opcode": "0xc5", "hex": "01"}     # escape hatch for anything
                                                    # not in the table yet
  {"cmd": "refresh"}                                # re-request headset status

Usage:
  python gamebuds_backend.py <MAC> [rfcomm-channel]
  python gamebuds_backend.py <MAC>  # SDP-discovers the SPP channel via sdptool
"""

import json
import re
import select
import socket
import subprocess
import sys
import time
from typing import cast

SPP_UUID = "00001101-0000-1000-8000-00805f9b34fb"
SYNC_WORD = 0xAA
EVENT_CMD = 0x3000
EVENT_SYNC = 0x3002

RECONNECT_DELAY = 5

# opcode table, taken from Consts.java$GameBuds
OPCODES: dict[str, int] = {
    "save_profile": 0x09,
    "get_firmware_version": 0x10,
    "get_headset_status": 0x11,
    "get_serial_number": 0x12,
    "get_eq_preset_names": 0x18,
    "set_eq_preset_names": 0x19,
    "get_audio_settings": 0x20,
    "set_audio_settings": 0x21,
    "get_bluetooth_volume": 0x22,
    "set_bluetooth_volume": 0x23,
    "get_24g_volume": 0x24,
    "set_24g_volume": 0x25,
    "get_volume_limiter": 0x26,
    "set_volume_limiter": 0x27,
    "set_custom_bt_eq_band": 0x28,
    "set_custom_two_four_ghz_eq_band": 0x31,
    "set_custom_eq": 0x33,
    "set_custom_bt_eq": 0x36,
    "set_mic_level": 0x37,
    "set_sidetone_level": 0x39,
    "set_onboard_effects": 0x3B,
    "set_eq_sync": 0xA7,
    "get_eq_sync": 0xA8,
    "set_audio_mode": 0xAA,
    "get_audio_mode": 0xAB,
    "get_headset_wireless_settings": 0xB0,
    "set_headset_wireless_settings": 0xB1,
    "sync_wireless_connection_status": 0xB5,
    "sync_battery_status": 0xB7,
    "set_anc_level": 0xB8,
    "set_transparent_level": 0xB9,
    "set_mic_muted": 0xBB,
    "set_transparent_anc_enabled": 0xBD,
    "get_auto_off_timer": 0xC0,
    "set_auto_off_timer": 0xC1,
    "get_wear_sense_config": 0xC4,
    "set_wear_sense_config": 0xC5,
    "sync_wear_sense_status": 0xC6,
    "get_button_mappings": 0xC8,
    "set_button_mappings": 0xC9,
    "factory_reset": 0xFD,
}
OPCODE_NAMES = {v: k.upper() for k, v in OPCODES.items()}

# GameBudsNoiseControlType, SET_TRANSPARENT_ANC_ENABLED (0xBD) payload
NOISE_NAMES = {0x00: "off", 0x01: "transparency", 0x02: "anc"}
NOISE_BYTES = {v: k for k, v in NOISE_NAMES.items()}

# GameBudsDeviceRadioType, SET/GET_AUDIO_MODE (0xAA/0xAB) payload
RADIO_NAMES = {0x00: "2.4g", 0x01: "bt"}
RADIO_BYTES = {v: k for k, v in RADIO_NAMES.items()}

# GameBudsBTService.convertUITransparencyToDevice(): UI level {1,2,3} ->
# device byte.
TRANSPARENCY_UI_TO_DEVICE = {1: 3, 2: 6, 3: 10}
# GameBudsBTService.setSidetoneVolume()'s switch: UI level {0,1,2,3} ->
# device byte.
SIDETONE_UI_TO_DEVICE = {0: 0, 1: 3, 2: 6, 3: 10}


def _clamp(value: object, lo: int, hi: int) -> int:
    try:
        return max(lo, min(hi, int(cast("int | str", value))))
    except (TypeError, ValueError):
        return lo


def find_channel(mac: str) -> int:
    """SDP-resolve the RFCOMM channel for the standard SPP UUID.

    Falls back to channel 1 if sdptool is missing, errors, or
    the buds haven't been paired/aren't reachable for SDP.
    """
    try:
        out = subprocess.run(
            ["sdptool", "search", "--bdaddr", mac, "SP"],
            capture_output=True,
            text=True,
            timeout=10,
        ).stdout
    except (OSError, subprocess.TimeoutExpired) as e:
        print(f"# sdptool unavailable ({e}) - defaulting to channel 1", file=sys.stderr)
        return 1
    m = re.search(r"Channel:\s*(\d+)", out)
    if m:
        return int(m.group(1))
    print("# sdptool found no SP record - defaulting to channel 1", file=sys.stderr)
    return 1


def find_adapter() -> str:
    out = subprocess.run(["hciconfig", "-a"], capture_output=True, text=True).stdout
    blocks = re.split(r"\n(?=hci\d)", out.strip())
    best_addr, best_tx = "00:00:00:00:00:00", -1
    for block in blocks:
        addr = re.search(r"BD Address:\s+([0-9A-Fa-f:]{17})", block)
        tx = re.search(r"TX bytes:(\d+)", block)
        if addr and tx and int(tx.group(1)) > best_tx:
            best_tx = int(tx.group(1))
            best_addr = addr.group(1)
    return best_addr


def encode_packet(event_id: int, payload: bytes, seq: int) -> bytes:
    length = 2 + len(payload)
    return (
        bytes([SYNC_WORD, seq & 0xFF])
        + length.to_bytes(2, "little")
        + event_id.to_bytes(2, "little")
        + payload
    )


class FrameReader:
    """Symmetric counterpart to encode_packet() for a live RFCOMM stream.

    RFCOMM is a byte stream, so frames can arrive split or coalesced across
    reads. This buffers and resyncs on the 0xAA sync word.
    """

    def __init__(self):
        self.buf = bytearray()

    def feed(self, data: bytes) -> list[tuple[int, int, bytes]]:
        self.buf.extend(data)
        out: list[tuple[int, int, bytes]] = []
        while True:
            while self.buf and self.buf[0] != SYNC_WORD:
                del self.buf[0]
            if len(self.buf) < 6:
                break
            length = self.buf[2] | (self.buf[3] << 8)
            total = 4 + length
            if len(self.buf) < total:
                break
            frame = bytes(self.buf[:total])
            del self.buf[:total]
            event_id = frame[4] | (frame[5] << 8)
            payload = frame[6:total]
            out.append((event_id, event_id, payload))
        return out


def opcode_name(op: int) -> str:
    return OPCODE_NAMES.get(op, f"UNKNOWN_0x{op:02x}")


def decode_payload(op: int, payload: bytes) -> dict[str, object] | None:
    """Best-effort decode for the handful of opcodes we're confident about."""
    if not payload:
        return None
    if op == OPCODES["sync_wear_sense_status"]:
        return {"wear_sense_status": bool(payload[0])}
    if op == OPCODES["get_wear_sense_config"] or op == OPCODES["set_wear_sense_config"]:
        return {"wear_sense_config": bool(payload[0])}
    if op == OPCODES["set_transparent_anc_enabled"]:
        name = NOISE_NAMES.get(payload[0])
        return {"noise_mode": name} if name else None
    if op == OPCODES["set_mic_muted"]:
        return {"mic_muted": bool(payload[0])}
    if op in (OPCODES["get_audio_mode"], OPCODES["set_audio_mode"]):
        name = RADIO_NAMES.get(payload[0])
        return {"audio_mode": name} if name else None
    return None


def emit(obj: dict[str, object]):
    print(json.dumps(obj), flush=True)


def build_command(c: dict[str, object]) -> tuple[int, bytes] | None:
    cmd = c.get("cmd")
    if not isinstance(cmd, str):
        return None

    if cmd == "raw":
        op_s = c.get("opcode")
        hex_s = c.get("hex", "")
        if not isinstance(op_s, str) or not isinstance(hex_s, str):
            return None
        try:
            op = int(op_s, 0)
            payload = bytes.fromhex(hex_s)
        except ValueError:
            return None
        return op, payload

    if cmd == "refresh":
        cmd = "get_headset_status"

    op = OPCODES.get(cmd)
    if op is None:
        print(f"# unknown command: {cmd!r}", file=sys.stderr)
        return None

    if cmd == "set_wear_sense_config":
        return op, bytes([0x01 if c.get("enabled") else 0x00])
    if cmd == "set_transparent_anc_enabled":
        mode = c.get("mode")
        b = NOISE_BYTES.get(mode if isinstance(mode, str) else "")
        if b is None:
            return None
        return op, bytes([b])
    if cmd == "set_mic_muted":
        return op, bytes([0x01 if c.get("enabled") else 0x00])
    if cmd == "set_audio_mode":
        mode = c.get("mode")
        b = RADIO_BYTES.get(mode if isinstance(mode, str) else "")
        if b is None:
            return None
        return op, bytes([b])
    if cmd == "set_anc_level":
        v = _clamp(c.get("value"), 1, 3)
        return op, bytes([v])
    if cmd == "set_bluetooth_volume" or cmd == "set_24g_volume":
        v = _clamp(c.get("value"), 0, 15)
        return op, bytes([v])
    if cmd == "set_mic_level":
        v = _clamp(c.get("value"), 1, 10)
        return op, bytes([v])
    if cmd == "set_auto_off_timer":
        v = _clamp(c.get("value"), 0, 255)
        return op, bytes([v])
    if cmd == "set_transparent_level":
        # convertUITransparencyToDevice(): UI level {1,2,3} -> device byte
        v = _clamp(c.get("value"), 1, 3)
        return op, bytes([TRANSPARENCY_UI_TO_DEVICE[v]])
    if cmd == "set_sidetone_level":
        # setSidetoneVolume()'s switch: UI level {0,1,2,3} -> device byte
        v = _clamp(c.get("value"), 0, 3)
        return op, bytes([SIDETONE_UI_TO_DEVICE[v]])
    if cmd in ("set_volume_limiter", "set_onboard_effects", "set_eq_sync"):
        return op, bytes([0x01 if c.get("enabled") else 0x00])

    # everything else (get_* with no args, factory_reset, save_profile, ...)
    return op, b""


def handle_command(line: str, sock: socket.socket, seq_box: list[int]):
    line = line.strip()
    if not line:
        return
    parsed: object
    try:
        parsed = cast("object", json.loads(line))
    except ValueError:
        parsed = None
    if not isinstance(parsed, dict):
        print(f"# bad command: {line!r}", file=sys.stderr)
        return
    c = cast("dict[str, object]", parsed)

    built = build_command(c)
    if built is None:
        return
    op, payload = built
    frame = encode_packet(EVENT_CMD, bytes([op]) + payload, seq_box[0])
    seq_box[0] = (seq_box[0] + 1) & 0xFF
    try:
        _ = sock.send(frame)
        print(f"# sent {opcode_name(op)} raw={frame.hex()}", file=sys.stderr)
    except OSError as e:
        print(f"# command send failed: {e}", file=sys.stderr)


def connect(mac: str, local: str, channel: int) -> socket.socket:
    sock = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_STREAM, socket.BTPROTO_RFCOMM)
    sock.settimeout(10.0)
    sock.bind((local, 0))
    sock.connect((mac, channel))
    return sock


def run(mac: str, channel: int | None):
    local = find_adapter()
    ch = channel if channel is not None else find_channel(mac)
    print(f"# adapter={local}  gamebuds={mac}  rfcomm_channel={ch}", file=sys.stderr)

    stdin_buf = ""
    reader = FrameReader()

    while True:
        try:
            sock = connect(mac, local, ch)
        except OSError as e:
            print(
                f"# connect failed: {e} - retrying in {RECONNECT_DELAY}s",
                file=sys.stderr,
            )
            time.sleep(RECONNECT_DELAY)
            continue

        print("# connected", file=sys.stderr)
        emit({"connected": True})
        seq_box = [0]
        # kick things off the same way the app would, ask for status
        handle_command('{"cmd": "get_headset_status"}', sock, seq_box)

        try:
            while True:
                readable, _, _ = select.select([sock, sys.stdin], [], [], 1.0)

                if sock in readable:
                    data = sock.recv(4096)
                    if not data:
                        print("# device closed connection", file=sys.stderr)
                        break
                    for event_id, _dup, payload in reader.feed(data):
                        if not payload:
                            continue
                        op = payload[0]
                        args = payload[1:]
                        kind = "sync" if event_id == EVENT_SYNC else "reply"
                        obj: dict[str, object] = {
                            "event": kind,
                            "opcode": f"0x{op:02x}",
                            "name": opcode_name(op),
                            "raw": payload.hex(),
                        }
                        decoded = decode_payload(op, args)
                        if decoded is not None:
                            obj["decoded"] = decoded
                        emit(obj)

                if sys.stdin in readable:
                    chunk = sys.stdin.readline()
                    if not chunk:
                        print("# stdin closed - exiting", file=sys.stderr)
                        sock.close()
                        return
                    stdin_buf += chunk
                    while "\n" in stdin_buf:
                        cmdline, stdin_buf = stdin_buf.split("\n", 1)
                        handle_command(cmdline, sock, seq_box)

        except OSError as e:
            print(f"# socket error: {e}", file=sys.stderr)
        finally:
            sock.close()

        emit({"connected": False})
        print(f"# disconnected - retrying in {RECONNECT_DELAY}s", file=sys.stderr)
        time.sleep(RECONNECT_DELAY)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(
            "Usage: python gamebuds_backend.py <MAC> [rfcomm-channel]\n"
            "UNVERIFIED against real hardware.",
            file=sys.stderr,
        )
        sys.exit(1)

    mac_arg = sys.argv[1]
    channel_arg = int(sys.argv[2]) if len(sys.argv) > 2 else None

    try:
        run(mac_arg, channel_arg)
    except KeyboardInterrupt:
        print("\n# interrupted", file=sys.stderr)
