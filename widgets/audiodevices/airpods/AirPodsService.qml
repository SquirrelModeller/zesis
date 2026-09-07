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
    readonly property int leftLevel: _state.left
    readonly property int rightLevel: _state.right
    readonly property int caseLevel: _state.caseVal
    readonly property bool leftCharging: _state.leftCharging
    readonly property bool rightCharging: _state.rightCharging
    readonly property bool caseCharging: _state.caseCharging
    readonly property bool leftEar: _state.leftEar
    readonly property bool rightEar: _state.rightEar
    readonly property string deviceName: _state.deviceName

    // "" | "off" | "anc" | "transparency" | "adaptive"
    readonly property string noiseMode: _state.noiseMode
    // null (unknown) | true | false
    readonly property var caEnabled: _state.caEnabled
    readonly property int caLevel: _state.caLevel
    readonly property string model: _state.model
    readonly property string firmware: _state.firmware

    // commands (no-op unless the daemon is live)

    function setNoiseMode(mode) {
        // "Off" is locked on AirPods Pro until explicitly unlocked
        if (mode === "off")
            _send({
                cmd: "allow_off",
                enabled: true
            });
        _send({
            cmd: "noise",
            mode: mode
        });
    }
    function setAdaptiveLevel(v) {
        _send({
            cmd: "adaptive_level",
            value: Math.round(v)
        });
        AirPodsSettings.writeAdaptiveLevel(Math.round(v));
    }
    function setConversationalAwareness(on) {
        _send({
            cmd: "ca",
            enabled: !!on
        });
        // AirPods don't echo a state packet when CA is toggled, so reflect it now
        _state.caEnabled = !!on;
        AirPodsSettings.writeCaEnabled(!!on);
    }
    function setEarDetection(on) {
        _send({
            cmd: "ear_detection",
            enabled: !!on
        });
        AirPodsSettings.writeEarDetection(!!on);
    }
    function setOneBudAnc(on) {
        _send({
            cmd: "one_bud_anc",
            enabled: !!on
        });
        AirPodsSettings.writeOneBudAnc(!!on);
    }
    function setCaseSounds(on) {
        _send({
            cmd: "case_sounds",
            enabled: !!on
        });
        AirPodsSettings.writeCaseSounds(!!on);
    }
    function setCaseToneVolume(v) {
        _send({
            cmd: "case_tone_volume",
            value: Math.round(v)
        });
        AirPodsSettings.set("caseToneVolume", Math.round(v));
    }
    function setChimeVolume(v) {
        _send({
            cmd: "chime_volume",
            value: Math.round(v)
        });
        AirPodsSettings.set("chimeVolume", Math.round(v));
    }
    function setMicMode(mode) {
        _send({
            cmd: "mic_mode",
            mode: mode
        });
        AirPodsSettings.set("micMode", mode);
    }
    function setVolumeSwipe(on) {
        _send({
            cmd: "volume_swipe",
            enabled: !!on
        });
        AirPodsSettings.set("volumeSwipe", !!on);
    }
    function setAdaptiveVolume(on) {
        _send({
            cmd: "adaptive_volume",
            enabled: !!on
        });
        AirPodsSettings.set("adaptiveVolume", !!on);
    }
    function setSleepDetection(on) {
        _send({
            cmd: "sleep_detection",
            enabled: !!on
        });
        AirPodsSettings.set("sleepDetection", !!on);
    }
    function setPressHoldModes(arr) {
        _send({
            cmd: "press_hold",
            modes: arr
        });
        AirPodsSettings.writePressHoldModes(arr);
    }
    function rename(name) {
        _send({
            cmd: "rename",
            name: name
        });
        if (name)
            _state.deviceName = name;
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
        property int left: 0
        property int right: 0
        property int caseVal: 0
        property bool leftCharging: false
        property bool rightCharging: false
        property bool caseCharging: false
        property bool leftEar: false
        property bool rightEar: false
        property string deviceName: ""
        property string noiseMode: ""
        property var caEnabled: null
        property int caLevel: 0
        property string model: ""
        property string firmware: ""
    }

    property int _earCountPrev: 0
    property bool _autoPaused: false
    property bool _casePresentPrev: false

    function _maybeCaseAppeared() {
        const present = _state.caseVal > 0;
        if (present === root._casePresentPrev)
            return;
        root._casePresentPrev = present;
        if (present && _daemon.running) {
            root._send({
                cmd: "case_sounds",
                enabled: AirPodsSettings.caseSounds
            });
            root._send({
                cmd: "case_tone_volume",
                value: AirPodsSettings.caseToneVolume
            });
        }
    }

    function _maybeAutoPause() {
        if (!_state.connected)
            return;
        const earCount = (_state.leftEar ? 1 : 0) + (_state.rightEar ? 1 : 0);
        if (earCount === root._earCountPrev)
            return;
        const decreased = earCount < root._earCountPrev;
        root._earCountPrev = earCount;

        if (!AirPodsSettings.autoPauseEnabled)
            return;

        if (decreased) {
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
                cmd: "ear_detection",
                enabled: AirPodsSettings.earDetection
            });
            root._send({
                cmd: "one_bud_anc",
                enabled: AirPodsSettings.oneBudAnc
            });
            root._send({
                cmd: "ca",
                enabled: AirPodsSettings.caEnabled
            });
            _state.caEnabled = AirPodsSettings.caEnabled;
            root._send({
                cmd: "case_sounds",
                enabled: AirPodsSettings.caseSounds
            });
            root._send({
                cmd: "press_hold",
                modes: AirPodsSettings.pressHoldModes
            });
            root._send({
                cmd: "adaptive_level",
                value: AirPodsSettings.adaptiveLevel
            });
            root._send({
                cmd: "mic_mode",
                mode: AirPodsSettings.micMode
            });
            root._send({
                cmd: "volume_swipe",
                enabled: AirPodsSettings.volumeSwipe
            });
            root._send({
                cmd: "adaptive_volume",
                enabled: AirPodsSettings.adaptiveVolume
            });
            root._send({
                cmd: "sleep_detection",
                enabled: AirPodsSettings.sleepDetection
            });
            root._send({
                cmd: "chime_volume",
                value: AirPodsSettings.chimeVolume
            });
        }
    }

    onConnectedChanged: {
        if (connected) {
            _reapplyTimer.restart();
        } else {
            root._earCountPrev = 0;
            root._autoPaused = false;
            root._casePresentPrev = false;
        }
    }

    // device watcher

    Instantiator {
        model: BluetoothService.activeAdapter?.devices.values ?? []

        delegate: QtObject {
            id: deviceWatcher
            required property var modelData
            property bool deviceConnected: modelData?.connected ?? false
            property bool ready: false
            Component.onCompleted: {
                ready = true;
                if (deviceWatcher.deviceConnected)
                    _checker.check(deviceWatcher.modelData.address, deviceWatcher.modelData.name || deviceWatcher.modelData.address);
            }

            onDeviceConnectedChanged: {
                if (!deviceWatcher.ready)
                    return;
                if (deviceWatcher.deviceConnected) {
                    _checker.check(deviceWatcher.modelData.address, deviceWatcher.modelData.name || deviceWatcher.modelData.address);
                } else if (deviceWatcher.modelData.address === root._activeMac) {
                    root._activeMac = "";
                    _daemon.running = false;
                    _state.connected = false;
                }
            }
        }
    }

    // UUID checker
    // We look for the AAP UUID in output.

    Process {
        id: _checker
        property string _mac: ""
        property string _name: ""
        property var _queue: []

        function check(mac, name) {
            if (_daemon.running)
                return;
            if (running) {
                _queue.push({
                    mac: mac,
                    name: name
                });
                return;
            }
            _mac = mac;
            _name = name;
            command = ["bluetoothctl", "info", mac];
            running = true;
        }

        function _runNext() {
            if (_daemon.running || _queue.length === 0)
                return;
            const next = _queue.shift();
            _mac = next.mac;
            _name = next.name;
            command = ["bluetoothctl", "info", next.mac];
            running = true;
        }

        stdout: SplitParser {
            onRead: line => {
                if (!line.includes("74ec2172-0bad-4d01-8f77-997b2be0722a"))
                    return;
                if (_daemon.running)
                    return;
                root._activeMac = _checker._mac;
                _state.deviceName = _checker._name;
                _checker._queue = [];
                _daemon.running = true;
                if (!AirPodsSettings.everSeen)
                    AirPodsSettings.set("everSeen", true);
            }
        }

        onRunningChanged: {
            if (!running)
                Qt.callLater(_checker._runNext);
        }
    }

    // daemon
    // Persistent: connects, does AAP handshake, streams JSON on state changes,
    // accepts newline-delimited JSON commands on stdin. Has its own reconnect
    // loop, QML just owns start/stop.

    Process {
        id: _daemon
        readonly property string _script: Qt.resolvedUrl("aap_backend.py").toString().slice(7)
        command: ["python3", _script, root._activeMac]
        stdinEnabled: true

        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("#"))
                    return;
                try {
                    const d = JSON.parse(line);
                    _state.connected = d.connected ?? false;
                    _state.left = d.left ?? 0;
                    _state.right = d.right ?? 0;
                    _state.caseVal = d.case ?? 0;
                    _state.leftCharging = d.left_charging ?? false;
                    _state.rightCharging = d.right_charging ?? false;
                    _state.caseCharging = d.case_charging ?? false;
                    _state.leftEar = d.left_ear ?? false;
                    _state.rightEar = d.right_ear ?? false;
                    _state.noiseMode = d.noise_mode ?? "";
                    _state.caEnabled = (d.ca_enabled === undefined) ? null : d.ca_enabled;
                    _state.caLevel = d.ca_level ?? 0;
                    _state.model = d.model ?? "";
                    _state.firmware = d.firmware ?? "";
                    root._maybeAutoPause();
                    root._maybeCaseAppeared();
                } catch (e) {}
            }
        }

        onRunningChanged: {
            if (!running)
                _state.connected = false;
        }
    }
}
