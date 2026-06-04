// qmllint disable import
pragma Singleton
// qmllint enable import
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _home: Quickshell.env("HOME")
    readonly property string _cacheDir: _home + "/.cache/zesis"
    readonly property string _stateFile: _cacheDir + "/state.json"
    readonly property string thumbsDir: _cacheDir + "/thumbs"

    property string palette: "dark"
    property string lastWallpaper: ""
    property bool applying: false

    Process {
        command: ["mkdir", "-p", root.thumbsDir]
        running: true
    }

    JsonAdapter {
        id: stateData
        property string palette: "dark"
        property string lastWallpaper: ""
    }

    FileView {
        path: root._stateFile
        adapter: stateData
        onLoaded: {
            root.palette = stateData.palette;
            root.lastWallpaper = stateData.lastWallpaper;
        }
    }

    function apply(wallpaperPath) {
        if (root.applying) return;
        root.applying = true;
        applyProcess._wallpaperPath = wallpaperPath;
        applyProcess.command = [
            "bash", "-c",
            "awww img \"$1\" --transition-type fade --transition-duration 1; wallust run \"$1\" -p \"$2\" && hyprctl reload",
            "--", wallpaperPath, root.palette
        ];
        applyProcess.running = true;
    }

    Process {
        id: applyProcess
        property string _wallpaperPath: ""
        onExited: (code, status) => {
            root.applying = false;
            if (code === 0) {
                root.lastWallpaper = applyProcess._wallpaperPath;
                _persistState();
            }
        }
    }

    Process {
        id: saveProcess
    }

    function _persistState() {
        var json = JSON.stringify({ palette: root.palette, lastWallpaper: root.lastWallpaper });
        saveProcess.command = [
            "bash", "-c",
            "printf '%s' \"$1\" > \"$2\"",
            "--", json, root._stateFile
        ];
        saveProcess.running = true;
    }
}
