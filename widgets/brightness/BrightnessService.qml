pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool testMode: false
    property int testPercent: 65

    property bool available: testMode ? true : false
    property int current: 0
    property int max: 100
    readonly property int percent: testMode ? testPercent : (max > 0 ? Math.round(current / max * 100) : 0)

    function set(pct) {
        if (testMode) {
            testPercent = Math.max(1, Math.min(100, Math.round(pct)));
            return;
        }
        _setProc.command = ["brightnessctl", "set", Math.round(pct) + "%"];
        _setProc.running = true;
    }

    function adjust(delta) {
        var next = Math.max(1, Math.min(100, percent + delta));
        set(next);
    }

    property string _device: ""

    Process {
        id: _detectProc
        running: !root.testMode
        command: ["sh", "-c", "d=$(ls /sys/class/backlight 2>/dev/null | head -1); " + "if [ -n \"$d\" ]; then echo \"$d\"; cat \"/sys/class/backlight/$d/max_brightness\"; fi"]

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                if (lines.length >= 2 && lines[0].length > 0) {
                    root._device = lines[0];
                    root.max = parseInt(lines[1]) || 100;
                } else {
                    root.available = false;
                }
            }
        }
    }

    // Rely on inotify to let us know brightness has changed
    FileView {
        id: _currentFile
        path: root._device ? ("/sys/class/backlight/" + root._device + "/actual_brightness") : ""
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.current = parseInt(text()) || 0;
            root.available = true;
        }
    }

    Process {
        id: _setProc
        running: false
    }
}
