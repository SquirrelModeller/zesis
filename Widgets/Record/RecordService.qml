pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool recording: _recorder.running
    property int elapsed: 0
    property string lastFile: ""
    property string _currentFile: ""
    property var _pendingCmd: null

    function _timestamp() {
        var now = new Date();
        var pad = n => String(n).padStart(2, "0");
        return now.getFullYear() + pad(now.getMonth() + 1) + pad(now.getDate()) + "_" + pad(now.getHours()) + pad(now.getMinutes()) + pad(now.getSeconds());
    }

    function _videoDir() {
        return (Quickshell.env("HOME") || "") + "/Videos";
    }

    function start(geometry) {
        if (recording)
            return;
        var file = _videoDir() + "/recording_" + _timestamp() + ".mp4";
        _currentFile = file;
        _pendingCmd = geometry ? ["wf-recorder", "-g", geometry, "-f", file] : ["wf-recorder", "-f", file];
        _mkdir.running = true;
    }

    function stop() {
        if (!recording)
            return;
        _stopper.running = true;
    }

    function toggle() {
        if (recording)
            stop();
        else
            start(null);
    }

    function startRegion() {
        if (recording)
            return;
        _slurpBuf = "";
        _slurp.running = true;
    }

    property string _slurpBuf: ""

    Process {
        id: _mkdir
        running: false
        command: ["mkdir", "-p", root._videoDir()]
        onRunningChanged: {
            if (!running && root._pendingCmd) {
                _recorder.command = root._pendingCmd;
                _recorder.running = true;
                root._pendingCmd = null;
            }
        }
    }

    Process {
        id: _slurp
        running: false
        command: ["slurp"]
        stdout: SplitParser {
            onRead: data => root._slurpBuf = data.trim()
        }
        onRunningChanged: {
            if (!running && root._slurpBuf !== "") {
                root.start(root._slurpBuf);
                root._slurpBuf = "";
            }
        }
    }

    Process {
        id: _recorder
        running: false
        onRunningChanged: {
            if (!running) {
                root.lastFile = root._currentFile;
                root._currentFile = "";
            }
        }
    }

    Process {
        id: _stopper
        running: false
        command: ["pkill", "-INT", "wf-recorder"]
    }

    Timer {
        interval: 1000
        running: root.recording
        repeat: true
        onTriggered: root.elapsed++
    }

    onRecordingChanged: {
        if (!recording)
            elapsed = 0;
    }
}
