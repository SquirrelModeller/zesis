pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../../bluetooth"

Singleton {
    id: root

    readonly property bool connected: _state.connected
    readonly property string deviceName: _state.deviceName
    readonly property int leftLevel: _state.left
    readonly property int rightLevel: _state.right
    readonly property int caseLevel: _state.caseLevel

    // live "currently in ear" push (bool|null = unknown)
    readonly property var wearSenseStatus: _state.wearSenseStatus
    readonly property var wearSenseConfig: _state.wearSenseConfig
    // "" | "off" | "transparency" | "anc"
    readonly property string noiseMode: _state.noiseMode
    readonly property var micMuted: _state.micMuted
    // "" | "2.4g" | "bt"
    readonly property string audioMode: _state.audioMode
    readonly property int ancLevel: _state.ancLevel
    readonly property int transparentLevel: _state.transparentLevel
    readonly property int bluetoothVolume: _state.bluetoothVolume
    // {opcode, name, raw} | null - last frame we couldn't decode
    readonly property var lastRawEvent: _state.lastRawEvent

    // commands (no-op unless the daemon is live)

    function setWearSenseConfig(on) {
        _send({
            cmd: "set_wear_sense_config",
            enabled: !!on
        });
        GameBudsSettings.set("wearSenseEnabled", !!on);
    }
    function setNoiseMode(mode) {
        _send({
            cmd: "set_transparent_anc_enabled",
            mode: mode
        });
    }
    function setAncLevel(v) {
        _send({
            cmd: "set_anc_level",
            value: Math.round(v)
        });
        _state.ancLevel = Math.round(v);
    }
    function setTransparentLevel(v) {
        _send({
            cmd: "set_transparent_level",
            value: Math.round(v)
        });
        _state.transparentLevel = Math.round(v);
    }
    function setMicMuted(on) {
        _send({
            cmd: "set_mic_muted",
            enabled: !!on
        });
    }
    function setMicLevel(v) {
        _send({
            cmd: "set_mic_level",
            value: Math.round(v)
        });
        GameBudsSettings.set("micLevel", Math.round(v));
    }
    function setSidetoneLevel(v) {
        _send({
            cmd: "set_sidetone_level",
            value: Math.round(v)
        });
        GameBudsSettings.set("sidetoneLevel", Math.round(v));
    }
    function setVolumeLimiter(on) {
        _send({
            cmd: "set_volume_limiter",
            enabled: !!on
        });
        GameBudsSettings.set("volumeLimiter", !!on);
    }
    function setAudioMode(mode) {
        _send({
            cmd: "set_audio_mode",
            mode: mode
        });
    }
    function setAutoOffTimer(minutes) {
        _send({
            cmd: "set_auto_off_timer",
            value: Math.round(minutes)
        });
        GameBudsSettings.set("autoOffTimer", Math.round(minutes));
    }
    function setBluetoothVolume(v) {
        _send({
            cmd: "set_bluetooth_volume",
            value: Math.round(v)
        });
        _state.bluetoothVolume = Math.round(v);
    }

    function _send(obj) {
        if (!_daemon.running)
            return;
        _daemon.write(JSON.stringify(obj) + "\n");
    }

    // internal state

    property string _activeMac: ""

    QtObject {
        id: _state
        property bool connected: false
        property string deviceName: ""
        property int left: 0
        property int right: 0
        property int caseLevel: 0
        property var wearSenseStatus: null
        property var wearSenseConfig: null
        property string noiseMode: ""
        property var micMuted: null
        property string audioMode: ""
        property var lastRawEvent: null
        property int ancLevel: 2
        property int transparentLevel: 2
        property int bluetoothVolume: 8
    }

    property bool _wearPrev: true
    property bool _autoPaused: false

    function _maybeAutoPause() {
        if (!_state.connected || _state.wearSenseStatus === null)
            return;
        const worn = !!_state.wearSenseStatus;
        if (worn === root._wearPrev)
            return;
        root._wearPrev = worn;

        if (!GameBudsSettings.autoPauseEnabled)
            return;

        if (!worn) {
            let paused = false;
            for (const p of Mpris.players.values) {
                if (p.playbackState === MprisPlaybackState.Playing && p.canPause) {
                    p.pause();
                    paused = true;
                }
            }
            if (paused)
                root._autoPaused = true;
        } else if (root._autoPaused) {
            for (const p of Mpris.players.values) {
                if (p.canPlay && p.playbackState !== MprisPlaybackState.Playing)
                    p.play();
            }
            root._autoPaused = false;
        }
    }

    Timer {
        id: _reapplyTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (!_daemon.running)
                return;
            root._send({
                cmd: "set_wear_sense_config",
                enabled: GameBudsSettings.wearSenseEnabled
            });
            root._send({
                cmd: "set_mic_level",
                value: GameBudsSettings.micLevel
            });
            root._send({
                cmd: "set_sidetone_level",
                value: GameBudsSettings.sidetoneLevel
            });
            root._send({
                cmd: "set_volume_limiter",
                enabled: GameBudsSettings.volumeLimiter
            });
            root._send({
                cmd: "set_auto_off_timer",
                value: GameBudsSettings.autoOffTimer
            });
        }
    }

    onConnectedChanged: {
        if (connected) {
            _reapplyTimer.restart();
        } else {
            root._wearPrev = true;
            root._autoPaused = false;
        }
    }

    // device watcher
    // Match on name, the buds only advertise a generic 0x1101 UUID

    Instantiator {
        model: BluetoothService.activeAdapter?.devices.values ?? []

        delegate: QtObject {
            id: deviceWatcher
            required property var modelData
            property bool deviceConnected: modelData?.connected ?? false
            property bool ready: false

            function _isGameBuds() {
                const n = (deviceWatcher.modelData?.name || "").toLowerCase();
                return n.includes("arctis") || n.includes("gamebuds");
            }

            Component.onCompleted: {
                ready = true;
                if (deviceWatcher.deviceConnected && deviceWatcher._isGameBuds())
                    root._connectTo(deviceWatcher.modelData.address, deviceWatcher.modelData.name);
            }

            onDeviceConnectedChanged: {
                if (!deviceWatcher.ready)
                    return;
                if (deviceWatcher.deviceConnected && deviceWatcher._isGameBuds()) {
                    root._connectTo(deviceWatcher.modelData.address, deviceWatcher.modelData.name);
                } else if (deviceWatcher.modelData.address === root._activeMac) {
                    root._activeMac = "";
                    _daemon.running = false;
                    _state.connected = false;
                }
            }
        }
    }

    // Same logic from the decompiled java files
    property double _lastConnectAttempt: 0
    readonly property int _connectCooldownMs: 30000

    function _connectTo(mac, name) {
        if (_daemon.running)
            return;
        const now = Date.now();
        if (now - root._lastConnectAttempt < root._connectCooldownMs)
            return;
        root._lastConnectAttempt = now;
        root._activeMac = mac;
        _state.deviceName = name || mac;
        _daemon.running = true;
        if (!GameBudsSettings.everSeen)
            GameBudsSettings.set("everSeen", true);
    }

    // daemon
    // Persistent: connects over RFCOMM, streams JSON on received frames,
    // accepts newline-delimited JSON commands on stdin. Has its own
    // reconnect loop, QML just owns start/stop.

    Process {
        id: _daemon
        readonly property string _script: Qt.resolvedUrl("gamebuds_backend.py").toString().slice(7)
        command: ["python3", _script, root._activeMac]
        stdinEnabled: true

        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("#"))
                    return;
                try {
                    const d = JSON.parse(line);
                    if ("connected" in d) {
                        _state.connected = d.connected;
                        return;
                    }
                    const decoded = d.decoded;
                    if (decoded) {
                        if ("wear_sense_status" in decoded)
                            _state.wearSenseStatus = decoded.wear_sense_status;
                        if ("wear_sense_config" in decoded)
                            _state.wearSenseConfig = decoded.wear_sense_config;
                        if ("noise_mode" in decoded)
                            _state.noiseMode = decoded.noise_mode;
                        if ("mic_muted" in decoded)
                            _state.micMuted = decoded.mic_muted;
                        if ("audio_mode" in decoded)
                            _state.audioMode = decoded.audio_mode;
                        if ("left_level" in decoded)
                            _state.left = decoded.left_level || 0;
                        if ("right_level" in decoded)
                            _state.right = decoded.right_level || 0;
                        if ("case_level" in decoded)
                            _state.caseLevel = decoded.case_level || 0;
                        if ("anc_level" in decoded)
                            _state.ancLevel = decoded.anc_level;
                        if ("transparent_level" in decoded)
                            _state.transparentLevel = decoded.transparent_level;
                    } else if (d.opcode) {
                        _state.lastRawEvent = {
                            opcode: d.opcode,
                            name: d.name,
                            raw: d.raw
                        };
                    }
                    root._maybeAutoPause();
                } catch (e) {}
            }
        }

        onRunningChanged: {
            if (!running)
                _state.connected = false;
        }
    }
}
