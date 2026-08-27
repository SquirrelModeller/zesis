pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "./"

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"

    property int _refCount: 0
    property int _refCountLeft: 0
    property int _refCountRight: 0
    readonly property bool running: _refCount > 0
    readonly property bool runningLeft: _refCountLeft > 0
    readonly property bool runningRight: _refCountRight > 0

    property var bars: []
    property var barsLeft: []
    property var barsRight: []

    property bool cavaAvailable: true

    function acquire(channel) {
        if (channel === "left")
            root._refCountLeft++;
        else if (channel === "right")
            root._refCountRight++;
        else
            root._refCount++;
    }

    function release(channel) {
        if (channel === "left")
            root._refCountLeft = Math.max(0, root._refCountLeft - 1);
        else if (channel === "right")
            root._refCountRight = Math.max(0, root._refCountRight - 1);
        else
            root._refCount = Math.max(0, root._refCount - 1);
    }

    // Live reload goes brrrrr
    function _configText(monoOption) {
        var lines = ["[general]", "live-config = 1", "framerate = 60", "bars = " + CavaSettings.barCount, "", "[input]", "method = pipewire", "source = auto", "", "[output]", "method = raw", "raw_target = /dev/stdout", "data_format = ascii", "ascii_max_range = 1000", "bar_delimiter = 59", "frame_delimiter = 10", "channels = mono", "mono_option = " + monoOption, "", "[smoothing]", "noise_reduction = 77", ""];
        return lines.join("\n");
    }

    // If the two frames math, we probably have silence
    function _framesEqual(a, b) {
        if (a.length !== b.length)
            return false;
        for (var i = 0; i < a.length; i++)
            if (a[i] !== b[i])
                return false;
        return true;
    }

    function _onFrame(line, channel) {
        line = line.trim();
        if (!line)
            return;
        var raw = line.split(";").filter(p => p.length > 0);
        var out = new Array(raw.length);
        for (var i = 0; i < raw.length; i++)
            out[i] = Math.max(0, Math.min(1, (parseInt(raw[i], 10) || 0) / 1000));
        if (channel === "left") {
            if (!root._framesEqual(root.barsLeft, out))
                root.barsLeft = out;
        } else if (channel === "right") {
            if (!root._framesEqual(root.barsRight, out))
                root.barsRight = out;
        } else {
            if (!root._framesEqual(root.bars, out))
                root.bars = out;
        }
    }

    onRunningChanged: {
        if (running) {
            root.bars = new Array(CavaSettings.barCount).fill(0);
            configFile.setText(root._configText("average"));
            cavaProc.running = true;
        } else {
            cavaProc.running = false;
        }
    }

    onRunningLeftChanged: {
        if (runningLeft) {
            root.barsLeft = new Array(CavaSettings.barCount).fill(0);
            configFileLeft.setText(root._configText("left"));
            cavaProcLeft.running = true;
        } else {
            cavaProcLeft.running = false;
        }
    }

    onRunningRightChanged: {
        if (runningRight) {
            root.barsRight = new Array(CavaSettings.barCount).fill(0);
            configFileRight.setText(root._configText("right"));
            cavaProcRight.running = true;
        } else {
            cavaProcRight.running = false;
        }
    }

    Connections {
        target: CavaSettings
        function onBarCountChanged() {
            if (root.running) {
                root.bars = new Array(CavaSettings.barCount).fill(0);
                configFile.setText(root._configText("average"));
            }
            if (root.runningLeft) {
                root.barsLeft = new Array(CavaSettings.barCount).fill(0);
                configFileLeft.setText(root._configText("left"));
            }
            if (root.runningRight) {
                root.barsRight = new Array(CavaSettings.barCount).fill(0);
                configFileRight.setText(root._configText("right"));
            }
        }
    }

    Process {
        id: mkdirProc
        running: true
        command: ["mkdir", "-p", root._configDir]
    }

    Process {
        id: cavaProbe
        running: true
        command: ["sh", "-c", "command -v cava"]
        onExited: exitCode => root.cavaAvailable = exitCode === 0
    }

    FileView {
        id: configFile
        path: root._configDir + "/cava-widget.conf"
        printErrors: false
    }
    FileView {
        id: configFileLeft
        path: root._configDir + "/cava-widget-left.conf"
        printErrors: false
    }
    FileView {
        id: configFileRight
        path: root._configDir + "/cava-widget-right.conf"
        printErrors: false
    }

    Process {
        id: cavaProc
        running: false
        command: ["cava", "-p", configFile.path]
        stdout: SplitParser {
            onRead: data => root._onFrame(data, "average")
        }
    }
    Process {
        id: cavaProcLeft
        running: false
        command: ["cava", "-p", configFileLeft.path]
        stdout: SplitParser {
            onRead: data => root._onFrame(data, "left")
        }
    }
    Process {
        id: cavaProcRight
        running: false
        command: ["cava", "-p", configFileRight.path]
        stdout: SplitParser {
            onRead: data => root._onFrame(data, "right")
        }
    }
}
