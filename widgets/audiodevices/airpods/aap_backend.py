#!/usr/bin/env python3
# Note: Claude Code helped me understand and partially write this
# AAP protocol constants and packet structure based on reverse-engineering
# documented in kavishdevar/librepods (GPL-3.0).
# https://github.com/kavishdevar/librepods
"""
AirPods AAP backend.

Connects via AAP (L2CAP PSM 0x1001), does the handshake, then:
  - prints a JSON line to stdout whenever device state changes
    (battery, ear detection, noise-control mode, conversational awareness,
     device metadata)
  - reads newline-delimited JSON commands from stdin and translates them
    into AAP control packets (noise mode, adaptive level, CA toggle,
    ear-detection toggle, one-bud ANC, press-and-hold config, rename)

Output format (one JSON line per change):
  {"connected": true,
   "left": 48, "right": 47, "case": 45,
   "left_charging": false, "right_charging": false, "case_charging": false,
   "left_ear": true, "right_ear": true,
   "noise_mode": "anc", "ca_enabled": true, "ca_level": 0,
   "model": "A3048", "firmware": "..."}

Command format (one JSON object per line on stdin):
  {"cmd": "noise", "mode": "off|anc|transparency|adaptive"}
  {"cmd": "adaptive_level", "value": 0..100}
  {"cmd": "ca", "enabled": true|false}
  {"cmd": "ear_detection", "enabled": true|false}
  {"cmd": "one_bud_anc", "enabled": true|false}
  {"cmd": "allow_off", "enabled": true|false}
  {"cmd": "case_sounds", "enabled": true|false}
  {"cmd": "case_tone_volume", "value": 0..100}
  {"cmd": "chime_volume", "value": 0..100}
  {"cmd": "mic_mode", "mode": "auto|left|right"}
  {"cmd": "volume_swipe", "enabled": true|false}
  {"cmd": "adaptive_volume", "enabled": true|false}
  {"cmd": "sleep_detection", "enabled": true|false}
  {"cmd": "press_hold", "modes": ["anc", "transparency", "adaptive", "off"]}
  {"cmd": "rename", "name": "New Name"}
  {"cmd": "refresh"}

Usage:
  python aap_backend.py <MAC>
  python aap_backend.py # auto-detect first paired AirPods
"""

import json
import os
import re
import select
import socket
import subprocess
import sys
import time
from typing import TypedDict, cast

# AAP protocol constants (from LibrePods / kavishdevar)

AAP_PSM = 0x1001

HANDSHAKE = bytes.fromhex("00000400010002000000000000000000")
SET_FEATURES = bytes.fromhex("040004004d00d700000000000000")
REQ_NOTIFS = bytes.fromhex("040004000f00ffffffffff")

H_HANDSHAKE_ACK = bytes.fromhex("01000400")
H_FEATURES_ACK = bytes.fromhex("040004002b00")
H_BATTERY = bytes.fromhex("040004000400")
H_EAR = bytes.fromhex("040004000600")
H_NOISE = bytes.fromhex("0400040009000d")
H_CA_STATE = bytes.fromhex("04000400090028")
H_CA_SPEAK = bytes.fromhex("040004004b00020001")
H_METADATA = bytes.fromhex("040004001d")

COMPONENT = {0x01: "headset", 0x02: "right", 0x04: "left", 0x08: "case"}
STATUS = {0x01: "charging", 0x02: "discharging", 0x04: "disconnected"}

NOISE_NAMES = {1: "off", 2: "anc", 3: "transparency", 4: "adaptive"}
NOISE_BYTES = {v: k for k, v in NOISE_NAMES.items()}
# press-and-hold cycle bitmask (ListeningModeConfigs, id 0x1A)
PH_BITS = {"off": 0x01, "anc": 0x02, "transparency": 0x04, "adaptive": 0x08}


def find_adapter() -> str:
    """Return BD address of the busiest (most TX bytes) local HCI adapter."""
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


def find_airpods_mac() -> str | None:
    """Return MAC of first paired AirPods (vendor 004C = Apple) via bluetoothctl."""
    out = subprocess.run(
        ["bluetoothctl", "devices"], capture_output=True, text=True
    ).stdout
    for line in out.splitlines():
        # line: "Device AA:BB:CC:DD:EE:FF Name"
        m = re.match(r"Device ([0-9A-Fa-f:]{17})", line)
        if m:
            mac = m.group(1)
            info = subprocess.run(
                ["bluetoothctl", "info", mac], capture_output=True, text=True
            ).stdout
            if "74ec2172-0bad-4d01-8f77-997b2be0722a" in info:
                return mac
    return None


# packet parsers


class BatteryComponent(TypedDict):
    level: int
    charging: bool
    connected: bool


class EarState(TypedDict):
    left_ear: bool
    right_ear: bool


class Metadata(TypedDict, total=False):
    name: str
    model: str
    firmware: str


def parse_battery(data: bytes) -> dict[str, BatteryComponent] | None:
    if not data.startswith(H_BATTERY):
        return None
    count = data[6]
    if count > 3 or len(data) != 7 + 5 * count:
        return None
    result: dict[str, BatteryComponent] = {}
    for i in range(count):
        o = 7 + 5 * i
        name = COMPONENT.get(data[o], f"comp_{data[o]:02x}")
        level = data[o + 2]
        status = STATUS.get(data[o + 3], "unknown")
        result[name] = {
            "level": level,
            "charging": status == "charging",
            "connected": status != "disconnected",
        }
    return result


def parse_ear(data: bytes) -> EarState | None:
    if not data.startswith(H_EAR) or len(data) < 8:
        return None

    def in_ear(b: int) -> bool:
        return b == 0x00

    return {"left_ear": in_ear(data[6]), "right_ear": in_ear(data[7])}


def parse_noise(data: bytes) -> str | None:
    if not data.startswith(H_NOISE) or len(data) < 8:
        return None
    return NOISE_NAMES.get(data[7])


def parse_ca_state(data: bytes) -> bool | None:
    if not data.startswith(H_CA_STATE) or len(data) < 8:
        return None
    if data[7] == 0x01:
        return True
    if data[7] == 0x02:
        return False
    return None


def parse_ca_level(data: bytes) -> int | None:
    if not data.startswith(H_CA_SPEAK) or len(data) < 10:
        return None
    return data[9]


def parse_metadata(data: bytes) -> Metadata | None:
    if not data.startswith(H_METADATA):
        return None
    parts = [
        p
        for p in data[len(H_METADATA) :].split(b"\x00")
        if len(p) >= 2 and all(32 <= b < 127 for b in p)
    ]
    if not parts:
        return None
    txt = [p.decode("ascii", "ignore") for p in parts]
    out: Metadata = {"name": txt[0]}
    if len(txt) > 1:
        out["model"] = txt[1]
    fw = ""
    if "Apple Inc." in txt:
        i = txt.index("Apple Inc.")
        if len(txt) > i + 2:
            fw = txt[i + 2]
    elif len(txt) > 4:
        fw = txt[4]
    if fw:
        out["firmware"] = fw
    return out


# outbound control packets


def control(ident: int, d1: int, d2: int = 0) -> bytes:
    """Build a fixed-length AACP control command (opcode 0x09)."""
    return bytes(
        [
            0x04,
            0x00,
            0x04,
            0x00,
            0x09,
            0x00,
            ident & 0xFF,
            d1 & 0xFF,
            d2 & 0xFF,
            0x00,
            0x00,
        ]
    )


def rename_packet(name: str) -> bytes:
    nb = name.encode("utf-8")[:255]
    return bytes.fromhex("040004001a0001") + bytes([len(nb), 0x00]) + nb


class State:
    def __init__(self):
        self.left: int = 0
        self.right: int = 0
        self.case: int = 0
        self.left_charging: bool = False
        self.right_charging: bool = False
        self.case_charging: bool = False
        self.left_ear: bool = False
        self.right_ear: bool = False
        self.connected: bool = False
        self.noise_mode: str = ""  # "" | off | anc | transparency | adaptive
        self.ca_enabled: bool | None = None  # None | True | False
        self.ca_level: int = 0
        self.model: str = ""
        self.firmware: str = ""

    def update_battery(self, parsed: dict[str, BatteryComponent]) -> bool:
        changed = False
        for comp, info in parsed.items():
            if comp == "left":
                if self.left != info["level"] or self.left_charging != info["charging"]:
                    self.left, self.left_charging = info["level"], info["charging"]
                    changed = True
            elif comp == "right":
                if (
                    self.right != info["level"]
                    or self.right_charging != info["charging"]
                ):
                    self.right, self.right_charging = info["level"], info["charging"]
                    changed = True
            elif comp == "case":
                if info["connected"] and (
                    self.case != info["level"] or self.case_charging != info["charging"]
                ):
                    self.case, self.case_charging = info["level"], info["charging"]
                    changed = True
            elif comp == "headset":
                # AirPods Max, map to left for simplicity
                if self.left != info["level"] or self.left_charging != info["charging"]:
                    self.left, self.left_charging = info["level"], info["charging"]
                    changed = True
        return changed

    def update_ear(self, parsed: EarState) -> bool:
        changed = (
            self.left_ear != parsed["left_ear"] or self.right_ear != parsed["right_ear"]
        )
        self.left_ear = parsed["left_ear"]
        self.right_ear = parsed["right_ear"]
        return changed

    def set_noise(self, mode: str) -> bool:
        if mode and self.noise_mode != mode:
            self.noise_mode = mode
            return True
        return False

    def set_ca(self, enabled: bool) -> bool:
        if self.ca_enabled != enabled:
            self.ca_enabled = enabled
            return True
        return False

    def set_ca_level(self, level: int) -> bool:
        if self.ca_level != level:
            self.ca_level = level
            return True
        return False

    def set_meta(self, meta: Metadata) -> bool:
        changed = False
        model = meta.get("model")
        if model and self.model != model:
            self.model = model
            changed = True
        firmware = meta.get("firmware")
        if firmware and self.firmware != firmware:
            self.firmware = firmware
            changed = True
        return changed

    def emit(self):
        print(
            json.dumps(
                {
                    "connected": self.connected,
                    "left": self.left,
                    "right": self.right,
                    "case": self.case,
                    "left_charging": self.left_charging,
                    "right_charging": self.right_charging,
                    "case_charging": self.case_charging,
                    "left_ear": self.left_ear,
                    "right_ear": self.right_ear,
                    "noise_mode": self.noise_mode,
                    "ca_enabled": self.ca_enabled,
                    "ca_level": self.ca_level,
                    "model": self.model,
                    "firmware": self.firmware,
                }
            ),
            flush=True,
        )


def _cmd_str(c: dict[str, object], key: str, default: str = "") -> str:
    v = c.get(key)
    return v if isinstance(v, str) else default


def _cmd_int(c: dict[str, object], key: str, default: int = 0) -> int:
    v = c.get(key)
    if isinstance(v, (int, float, str)):
        try:
            return int(v)
        except ValueError:
            return default
    return default


def handle_command(line: str, sock: socket.socket, state: State):
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

    cmd = c.get("cmd")
    try:
        if cmd == "noise":
            b = NOISE_BYTES.get(_cmd_str(c, "mode"))
            if b:
                _ = sock.send(control(0x0D, b))
        elif cmd == "adaptive_level":
            v = max(0, min(100, _cmd_int(c, "value")))
            _ = sock.send(control(0x2E, v))
        elif cmd == "ca":
            _ = sock.send(control(0x28, 0x01 if c.get("enabled") else 0x02))
        elif cmd == "ear_detection":
            _ = sock.send(control(0x0A, 0x01 if c.get("enabled") else 0x02))
        elif cmd == "one_bud_anc":
            _ = sock.send(control(0x1B, 0x01 if c.get("enabled") else 0x02))
        elif cmd == "allow_off":
            # unlock the "Off" listening mode (rejected with an error tone otherwise)
            _ = sock.send(control(0x34, 0x01 if c.get("enabled") else 0x02))
        elif cmd == "case_sounds":
            # In Case Tone config: 0x01 = tone plays, 0x02 = silent
            _ = sock.send(control(0x31, 0x01 if c.get("enabled") else 0x02))
        elif cmd == "case_tone_volume":
            _ = sock.send(control(0x40, max(0, min(100, _cmd_int(c, "value")))))
        elif cmd == "chime_volume":
            _ = sock.send(control(0x1F, max(0, min(100, _cmd_int(c, "value")))))
        elif cmd == "mic_mode":
            # 0x00 = automatic, 0x01 = right, 0x02 = left
            mic = {"auto": 0x00, "right": 0x01, "left": 0x02}.get(
                _cmd_str(c, "mode"), 0x00
            )
            _ = sock.send(control(0x01, mic))
        elif cmd == "volume_swipe":
            _ = sock.send(control(0x25, 0x01 if c.get("enabled") else 0x02))
        elif cmd == "adaptive_volume":
            _ = sock.send(control(0x26, 0x01 if c.get("enabled") else 0x02))
        elif cmd == "sleep_detection":
            _ = sock.send(control(0x35, 0x01 if c.get("enabled") else 0x02))
        elif cmd == "press_hold":
            mask = 0
            modes = c.get("modes")
            if isinstance(modes, list):
                for m in cast("list[object]", modes):
                    if isinstance(m, str):
                        mask |= PH_BITS.get(m, 0)
            _ = sock.send(control(0x1A, mask))
        elif cmd == "rename":
            name = str(c.get("name", "")).strip()
            if name:
                _ = sock.send(rename_packet(name))
        elif cmd == "refresh":
            state.emit()
        else:
            print(f"# unknown command: {cmd!r}", file=sys.stderr)
    except OSError as e:
        print(f"# command send failed: {e}", file=sys.stderr)


# main loop

RECONNECT_DELAY = 5


def connect(mac: str, local: str) -> socket.socket:
    sock = socket.socket(
        socket.AF_BLUETOOTH, socket.SOCK_SEQPACKET, socket.BTPROTO_L2CAP
    )
    sock.settimeout(10.0)
    sock.bind((local, 0))
    sock.connect((mac, AAP_PSM))
    return sock


def dispatch(data: bytes, sock: socket.socket, state: State, step: str) -> str:
    if step == "handshake" and data.startswith(H_HANDSHAKE_ACK):
        _ = sock.send(SET_FEATURES)
        return "features"

    if step == "features" and data.startswith(H_FEATURES_ACK):
        _ = sock.send(REQ_NOTIFS)
        return "listening"

    if step == "listening":
        if data.startswith(H_BATTERY):
            parsed = parse_battery(data)
            if parsed and state.update_battery(parsed):
                state.emit()
        elif data.startswith(H_EAR):
            parsed = parse_ear(data)
            if parsed and state.update_ear(parsed):
                state.emit()
        elif data.startswith(H_CA_SPEAK):
            lvl = parse_ca_level(data)
            if lvl is not None and state.set_ca_level(lvl):
                state.emit()
        elif data.startswith(H_CA_STATE):
            v = parse_ca_state(data)
            if v is not None and state.set_ca(v):
                state.emit()
        elif data.startswith(H_NOISE):
            m = parse_noise(data)
            if m and state.set_noise(m):
                state.emit()
        elif data.startswith(H_METADATA):
            m = parse_metadata(data)
            if m and state.set_meta(m):
                state.emit()

    return step


def run(mac: str):
    local = find_adapter()
    print(f"# adapter={local}  airpods={mac}", file=sys.stderr)

    state = State()
    stdin_open = True
    stdin_buf = ""

    while True:
        try:
            sock = connect(mac, local)
        except OSError as e:
            print(
                f"# connect failed: {e} - retrying in {RECONNECT_DELAY}s",
                file=sys.stderr,
            )
            time.sleep(RECONNECT_DELAY)
            continue

        print("# connected", file=sys.stderr)
        state.connected = True
        state.emit()
        step = "handshake"
        _ = sock.send(HANDSHAKE)

        try:
            while True:
                watch = [sock, sys.stdin] if stdin_open else [sock]
                readable, _, _ = select.select(watch, [], [], 1.0)

                if sock in readable:
                    data = sock.recv(4096)
                    if not data:
                        print("# device closed connection", file=sys.stderr)
                        break
                    step = dispatch(data, sock, state, step)

                if stdin_open and sys.stdin in readable:
                    try:
                        chunk = os.read(0, 65536)
                    except OSError:
                        chunk = b""
                    if not chunk:
                        print("# stdin closed - exiting", file=sys.stderr)
                        sock.close()
                        return
                    stdin_buf += chunk.decode("utf-8", "ignore")
                    while "\n" in stdin_buf:
                        line, stdin_buf = stdin_buf.split("\n", 1)
                        handle_command(line, sock, state)

        except OSError as e:
            print(f"# socket error: {e}", file=sys.stderr)
        finally:
            sock.close()

        state.connected = False
        state.emit()
        print(f"# disconnected - retrying in {RECONNECT_DELAY}s", file=sys.stderr)
        time.sleep(RECONNECT_DELAY)


if __name__ == "__main__":
    if len(sys.argv) == 2:
        mac = sys.argv[1]
    else:
        mac = find_airpods_mac()
        if not mac:
            print("No paired AirPods found. Pass MAC as argument.", file=sys.stderr)
            sys.exit(1)
        print(f"# auto-detected: {mac}", file=sys.stderr)

    try:
        run(mac)
    except KeyboardInterrupt:
        print("\n# interrupted", file=sys.stderr)
