#!/usr/bin/env python3
"""
GameBuds RFCOMM/SPP backend.

Protocol reverse-engineered from the Arctis Companion APK
(com.steelseries.arctiscompanion 6.7.0) and verified against its
decompiled sources.

Transport framing (TransportLayerPacket.encode), no CRC:
  AA | tseq(1) | length(2 LE) | event_id(2 LE) | payload(length - 2)
    - length counts event_id + payload
    - tseq: TransportLayer.d - starts at 1, wraps 255->1, One counter,
      shared by outgoing commands and acks.
    - event_id 0x3000 (EVENT_ID)      = command / command-reply
      event_id 0x3002 (SYNC_EVENT_ID) = unsolicited sync/notify
      event_id 0x0000                 = ack (isAckPkt: event_id == 0)
    - the device also emits frames on other event-ids (0x0c30, 0x0708,
      ...). RealSil telemetry/DFU channels the GameBuds app itself
      ignores (onDataReceived only handles 0x3000 / 0x3002). We ack them
      (the app does too) and pass them through as {"event": "other"}.

GameBuds command payload (GameBudsBTService.buildAndQueueCommand):
  aseq(1) | opcode(1) | params(N)
    - aseq: GameBudsState.commandSequenceId, 0..255 wrapping, bumped once
      per command, commands only (acks carry no aseq). The device echoes
      it back as parameters[0]. The app never validates it.

Received-frame parameters (bytes after event_id):
  parameters[0]  = aseq echo (ignored)
  parameters[1]  = opcode  -> dispatch
  parameters[2:] = data
  parameters empty on a 0x3000 frame => device wants the app to flush its
  command queue (desync recovery).

Three replies carry L/R/case battery (nullable - 0..100 via toIntBatteryLevel,
else unknown), all write the same GameBudsState fields:
  - GET_HEADSET_STATUS (0x11) reply: eventParams[78/79/80], + the full
    firmware-version block. Also [81]=transparency dev byte, [82]=ANC,
    [83]=noise, [86/87]=wear cfg/status, [114]=audio mode
  - GET_HEADSET_WIRELESS_SETTINGS (0xB0) reply: eventParams[6/7/8] - the
    compact frame, same tail fields as 0x11 minus the firmware block. Send
    {"cmd": "get_headset_wireless_settings"} for a light refresh.
  - SYNC_BATTERY_STATUS (0xB7): a 0x3002 push, eventParams[2/3/4]
    eventParams == our `parameters`; _status_tail() decodes the shared block
    for 0x11 (base 76) and 0xB0 (base 4).

Acks (TransportLayer.sendAck / AckPacket.encode): every received 0x3000 /
0x3002 frame is acked with event_id=0x0000, payload = toAckId(2 LE) + status(1)
toAckId is the transport event_id of the acked frame (0x3000 / 0x3002).
status 0 = COMPLETE. ackRequired defaults true and nothing registers ignore-ack
events.

Commands are writeType(1) = NO_RESPONSE: the transport layer sends them
once and neither waits for nor retransmits on the device's ack. Flow
control is app-level only. A single-threaded executor sleeps commandDelay
(GameBuds overrides RTKBluetoothService's 30ms with 50ms) after every
send, and resendCommandIfNoResponse re-sends a command up to 3x at 1s
spacing if no reply event arrives.

Output (one JSON line per received frame):
  {"connected": true}
  {"event": "sync", "opcode": "0xc6", "name": "SYNC_WEAR_SENSE_STATUS",
   "raw": "...", "decoded": {"wear_sense_status": true}}
  {"event": "reply", "opcode": "0x11", "name": "GET_HEADSET_STATUS", "raw": "..."}
  {"event": "ack", "acked_event": "0x3000", "status": 0}
  {"event": "other", "event_id": "0x0c30", "raw": "..."}

Command format (one JSON object per line on stdin):
  {"cmd": "get_headset_status"}                     # alias: {"cmd": "refresh"}
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
  {"cmd": "set_volume_limiter", "enabled": true}
  {"cmd": "set_audio_mode", "mode": "2.4g|bt"}
  {"cmd": "raw", "opcode": "0xc5", "hex": "01"}     # opcode + param hex
                                                    # aseq is added for you

Usage:
  python gamebuds_backend.py <MAC> [rfcomm-channel]
  python gamebuds_backend.py <MAC>  # SDP-discovers the SPP channel via sdptool

Debug log: every diagnostic line and every frame in/out is appended,
timestamped, to $XDG_CACHE_HOME/zesis/gamebuds_debug.log (~/.cache/zesis/
if unset).
"""

import json
import os
import re
import select
import socket
import subprocess
import sys
import time
from typing import cast

SPP_UUID = "00001101-0000-1000-8000-00805f9b34fb"
SYNC_WORD = 0xAA
EVENT_CMD = 0x3000  # Consts.GameBuds.EVENT_ID          - command / command-reply
EVENT_SYNC = 0x3002  # Consts.GameBuds.SYNC_EVENT_ID    - unsolicited sync/notify
# TransportLayerPacket.isAckPkt(): a frame whose event-id field is 0.
EVENT_ACK = 0x0000
ACK_STATUS_COMPLETE = 0x00
# TransportLayerPacket.isAckRequired(): event_id != 769. In practice the
# device only ever sends 0x3000 / 0x3002 / 0x0000 (and the telemetry
# event-ids, which it does want acked) so this never fires. It is kept to
# mirror the app.
ACK_EXEMPT_EVENT_ID = 769

RECONNECT_DELAY = 5
COMMAND_DELAY = 0.05

_LOG_DIR = (
    os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache")
) + "/zesis"
_LOG_PATH = _LOG_DIR + "/gamebuds_debug.log"
_log_file = None


def log(msg: str) -> None:
    print(msg, file=sys.stderr)
    global _log_file
    if _log_file is None:
        try:
            os.makedirs(_LOG_DIR, exist_ok=True)
            _log_file = open(_LOG_PATH, "a", buffering=1)
        except OSError:
            return
    ts = time.strftime("%H:%M:%S") + f".{int(time.time() * 1000) % 1000:03d}"
    try:
        _ = _log_file.write(f"[{ts}] {msg}\n")
        _log_file.flush()
    except OSError:
        pass


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
        log(f"# sdptool unavailable ({e}) - defaulting to channel 1")
        return 1
    m = re.search(r"Channel:\s*(\d+)", out)
    if m:
        return int(m.group(1))
    log("# sdptool found no SP record - defaulting to channel 1")
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


def next_tseq(seq_box: list[int]) -> int:
    """TransportLayer.a(): transport seq is 1..255, wraps to 1, never 0.
    One counter shared by commands and acks. Returns the value to use, then
    advances the box.
    """
    s = seq_box[0]
    seq_box[0] = 1 if s >= 255 else s + 1
    return s


def encode_packet(event_id: int, payload: bytes, seq: int) -> bytes:
    length = 2 + len(payload)
    return (
        bytes([SYNC_WORD, seq & 0xFF])
        + length.to_bytes(2, "little")
        + event_id.to_bytes(2, "little")
        + payload
    )


def send_ack(sock: socket.socket, acked_event_id: int, seq_box: list[int]) -> None:
    """TransportLayer.sendAck() after every received 0x3000 / 0x3002 frame.
    Without it the device times out waiting and drops the connection.
    toAckId is the acked frame's transport event-id.
    """
    payload = acked_event_id.to_bytes(2, "little") + bytes([ACK_STATUS_COMPLETE])
    frame = encode_packet(EVENT_ACK, payload, next_tseq(seq_box))
    try:
        _ = sock.send(frame)
        log(f"# ack -> 0x{acked_event_id:04x} raw={frame.hex()}")
    except OSError as e:
        log(f"# ack send failed: {e}")


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
            # GameBuds frames top out around 130 bytes. A huge length means
            # this header came out of a desynced stream. Drop the 0xAA and
            # rescan.
            if length > 2048:
                del self.buf[0]
                continue
            total = 4 + length
            if len(self.buf) < total:
                break
            frame = bytes(self.buf[:total])
            del self.buf[:total]
            seq_num = frame[1]
            event_id = frame[4] | (frame[5] << 8)
            params = frame[6:total]
            out.append((event_id, seq_num, params))
        return out


def opcode_name(op: int) -> str:
    return OPCODE_NAMES.get(op, f"UNKNOWN_0x{op:02x}")


def _batt(v: int) -> int | None:
    """toIntBatteryLevel(): 0..100 valid, anything else (0xff etc.) = unknown."""
    return v if 0 <= v <= 100 else None


def _transparency_dev_to_ui(d: int) -> int:
    """GameBudsBTService.convertDeviceTransparencyToUI(). The device byte is
    read Java-signed there, so >=128 behaves like a negative -> UI 1.
      device 0..3 -> 1, 4..6 -> 2, 7..10 -> 3, >=11 -> 1
    """
    if d >= 128:
        d -= 256
    if d < 7 or d >= 11:
        return 1 if (d < 4 or d >= 7) else 2
    return 3


def _status_tail(data: bytes, base: int) -> dict[str, object] | None:
    """The battery + noise/wear/audio block shared by two replies:
    GET_HEADSET_STATUS (0x11, base=76) and GET_HEADSET_WIRELESS_SETTINGS
    (0xB0, base=4). data is params[2:] (== the app's eventParams[2:]).
    base is the left-earbud battery index within it. Offsets from base
    match handleGetHeadsetStatus / handleGetHeadsetWirelessSettings:
        +0/+1/+2 L/R/case battery +3 transparency device byte +4 ANC level
        +5 noise mode +8 wear-sense config +9 wear-sense status +36 audio mode
    """
    if len(data) < base + 10:
        return None
    out: dict[str, object] = {
        "left_level": _batt(data[base]),
        "right_level": _batt(data[base + 1]),
        "case_level": _batt(data[base + 2]),
        "transparent_level": _transparency_dev_to_ui(data[base + 3]),
        "anc_level": data[base + 4],
        "wear_sense_config": bool(data[base + 8]),
        "wear_sense_status": bool(data[base + 9]),
    }
    nm = NOISE_NAMES.get(data[base + 5])
    if nm:
        out["noise_mode"] = nm
    if len(data) >= base + 37:
        am = RADIO_NAMES.get(data[base + 36])
        if am:
            out["audio_mode"] = am
    return out


def decode_payload(op: int, payload: bytes) -> dict[str, object] | None:
    """Best-effort decode for the handful of opcodes we're confident about."""
    if not payload:
        return None
    if op == OPCODES["get_headset_status"]:
        return _status_tail(payload, 76)
    if op == OPCODES["get_headset_wireless_settings"]:
        return _status_tail(payload, 4)
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
    # SYNC_BATTERY_STATUS push. handleGetBatteryStatus reads eventParams[2/3/4]
    # raw (no clamp). We apply the same 0..100 filter as the other two paths.
    if op == OPCODES["sync_battery_status"]:
        if len(payload) >= 3:
            return {
                "left_level": _batt(payload[0]),
                "right_level": _batt(payload[1]),
                "case_level": _batt(payload[2]),
            }
        return None
    return None


def emit(obj: dict[str, object]):
    line = json.dumps(obj)
    print(line, flush=True)
    log(f"# emit {line}")


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
        log(f"# unknown command: {cmd!r}")
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


def handle_command(
    line: str,
    sock: socket.socket,
    seq_box: list[int],
    app_seq_box: list[int],
    last_send_box: list[float],
):
    line = line.strip()
    if not line:
        return
    parsed: object
    try:
        parsed = cast("object", json.loads(line))
    except ValueError:
        parsed = None
    if not isinstance(parsed, dict):
        log(f"# bad command: {line!r}")
        return
    c = cast("dict[str, object]", parsed)

    built = build_command(c)
    if built is None:
        return
    op, params = built
    # GameBuds command payload = aseq(1) | opcode(1) | params. aseq is a
    # per-command counter (commands only, never acks). The device echoes it
    # back as parameters[0] of the reply.
    a_seq = app_seq_box[0]
    app_seq_box[0] = (a_seq + 1) & 0xFF
    frame = encode_packet(EVENT_CMD, bytes([a_seq, op]) + params, next_tseq(seq_box))

    elapsed = time.monotonic() - last_send_box[0]
    if elapsed < COMMAND_DELAY:
        time.sleep(COMMAND_DELAY - elapsed)

    try:
        _ = sock.send(frame)
        log(f"# sent {opcode_name(op)} raw={frame.hex()}")
    except OSError as e:
        log(f"# command send failed: {e}")
    finally:
        last_send_box[0] = time.monotonic()


def connect(mac: str, local: str, channel: int) -> socket.socket:
    sock = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_STREAM, socket.BTPROTO_RFCOMM)
    sock.settimeout(10.0)
    sock.bind((local, 0))
    sock.connect((mac, channel))
    return sock


def run(mac: str, channel: int | None):
    local = find_adapter()
    ch = channel if channel is not None else find_channel(mac)
    log(f"# adapter={local}  gamebuds={mac}  rfcomm_channel={ch}")

    stdin_buf = ""
    reader = FrameReader()

    while True:
        try:
            sock = connect(mac, local, ch)
        except OSError as e:
            log(f"# connect failed: {e} - retrying in {RECONNECT_DELAY}s")
            time.sleep(RECONNECT_DELAY)
            continue

        log("# connected")
        emit({"connected": True})
        sock.settimeout(None)  # drop the connect timeout; select() drives reads
        seq_box = [1]  # transport seq: 1..255, wraps to 1, never 0
        app_seq_box = [0]  # app command seq: 0..255 wrapping, commands only
        last_send_box = [0.0]
        # kick things off the same way the app would, ask for status
        handle_command(
            '{"cmd": "get_headset_status"}', sock, seq_box, app_seq_box, last_send_box
        )

        try:
            while True:
                readable, _, _ = select.select([sock, sys.stdin], [], [], 1.0)

                if sock in readable:
                    data = sock.recv(4096)
                    if not data:
                        log("# device closed connection")
                        break
                    for event_id, rx_seq, params in reader.feed(data):
                        if event_id == EVENT_ACK:
                            # AckPacket: [toAckId(2 LE), status]. Never ack an
                            # ack, that would loop forever.
                            if len(params) >= 3:
                                acked = params[0] | (params[1] << 8)
                                emit(
                                    {
                                        "event": "ack",
                                        "acked_event": f"0x{acked:04x}",
                                        "status": params[2],
                                    }
                                )
                            continue

                        # every received frame is acked, toAckId is the
                        # transport event-id
                        if event_id != ACK_EXEMPT_EVENT_ID:
                            send_ack(sock, event_id, seq_box)

                        if event_id == EVENT_SYNC:
                            kind = "sync"
                        elif event_id == EVENT_CMD:
                            kind = "reply"
                        else:
                            # RealSil telemetry / DFU event-ids that the
                            # GameBuds app itself ignores (onDataReceived only
                            # handles 0x3000 / 0x3002).
                            emit(
                                {
                                    "event": "other",
                                    "seq": rx_seq,
                                    "event_id": f"0x{event_id:04x}",
                                    "raw": params.hex(),
                                }
                            )
                            continue

                        if len(params) == 0:
                            # 0x3000 with no params => device wants us to drop
                            # any queued commands (desync recovery).
                            emit({"event": kind, "seq": rx_seq, "note": "flush"})
                            continue
                        if len(params) < 2:
                            emit(
                                {
                                    "event": kind,
                                    "seq": rx_seq,
                                    "raw": params.hex(),
                                    "note": "short",
                                }
                            )
                            continue

                        # params[0] = app-seq echo, [1] = opcode, [2:] = data
                        op = params[1]
                        obj: dict[str, object] = {
                            "event": kind,
                            "seq": rx_seq,
                            "opcode": f"0x{op:02x}",
                            "name": opcode_name(op),
                            "raw": params.hex(),
                        }
                        decoded = decode_payload(op, params[2:])
                        if decoded is not None:
                            obj["decoded"] = decoded
                        emit(obj)

                if sys.stdin in readable:
                    try:
                        chunk = os.read(0, 65536)
                    except OSError:
                        chunk = b""
                    if not chunk:
                        log("# stdin closed - exiting")
                        sock.close()
                        return
                    stdin_buf += chunk.decode("utf-8", "ignore")
                    while "\n" in stdin_buf:
                        cmdline, stdin_buf = stdin_buf.split("\n", 1)
                        handle_command(
                            cmdline, sock, seq_box, app_seq_box, last_send_box
                        )

        except OSError as e:
            log(f"# socket error: {e}")
        finally:
            sock.close()

        emit({"connected": False})
        log(f"# disconnected - retrying in {RECONNECT_DELAY}s")
        time.sleep(RECONNECT_DELAY)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        log("Usage: python gamebuds_backend.py <MAC> [rfcomm-channel]")
        sys.exit(1)

    mac_arg = sys.argv[1]
    channel_arg = int(sys.argv[2]) if len(sys.argv) > 2 else None

    try:
        run(mac_arg, channel_arg)
    except KeyboardInterrupt:
        log("\n# interrupted")
