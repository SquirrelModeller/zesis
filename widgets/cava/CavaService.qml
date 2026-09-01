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
    readonly property bool running: _refCount > 0

    // bars       - mean of left and right
    // barsLeft   - left channel,  low frequency at index 0
    // barsRight  - right channel, low frequency at index 0
    property var bars: []
    property var barsLeft: []
    property var barsRight: []

    property bool cavaAvailable: true

    function acquire(channel) {
        root._refCount++;
    }

    function release(channel) {
        root._refCount = Math.max(0, root._refCount - 1);
    }

    // Live reload goes brrrrr.
    // We request both left and right, which means we need the visualizer
    // barcount * 2.
    function _configText() {
        var lines = ["[general]", "live-config = 1", "framerate = 60", "bars = " + (CavaSettings.barCount * 2), "", "[input]", "method = pipewire", "source = auto", "", "[output]", "method = raw", "raw_target = /dev/stdout", "data_format = ascii", "ascii_max_range = 1000", "bar_delimiter = 59", "frame_delimiter = 10", "channels = stereo", "", "[smoothing]", "noise_reduction = 77", ""];
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

    function _onFrame(line) {
        line = line.trim();
        if (!line)
            return;
        var raw = line.split(";").filter(p => p.length > 0);
        var n = raw.length >> 1;
        if (n < 1)
            return;
        var left = new Array(n);
        var right = new Array(n);
        var avg = new Array(n);
        for (var i = 0; i < n; i++) {
            // Left half is mirrored. Index 0 is the highest frequency bar.
            var l = Math.max(0, Math.min(1, (parseInt(raw[n - 1 - i], 10) || 0) / 1000));
            var r = Math.max(0, Math.min(1, (parseInt(raw[n + i], 10) || 0) / 1000));
            left[i] = l;
            right[i] = r;
            avg[i] = (l + r) / 2;
        }
        if (!root._framesEqual(root.bars, avg))
            root.bars = avg;
        if (!root._framesEqual(root.barsLeft, left))
            root.barsLeft = left;
        if (!root._framesEqual(root.barsRight, right))
            root.barsRight = right;
    }

    function _resetBars() {
        var zero = new Array(CavaSettings.barCount).fill(0);
        root.bars = zero;
        root.barsLeft = zero.slice();
        root.barsRight = zero.slice();
    }

    onRunningChanged: {
        if (running) {
            root._resetBars();
            configFile.setText(root._configText());
            cavaProc.running = true;
        } else {
            cavaProc.running = false;
        }
    }

    Connections {
        target: CavaSettings
        function onBarCountChanged() {
            if (root.running) {
                root._resetBars();
                configFile.setText(root._configText());
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

    Process {
        id: cavaProc
        running: false
        command: ["cava", "-p", configFile.path]
        stdout: SplitParser {
            onRead: data => root._onFrame(data)
        }
    }
}
