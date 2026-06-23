pragma Singleton
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
    property string schemeType: "scheme-tonal-spot"
    property bool applying: false

    Process {
        command: ["mkdir", "-p", root.thumbsDir]
        running: true
    }

    JsonAdapter {
        id: stateData
        property string palette: "dark"
        property string lastWallpaper: ""
        property string schemeType: "scheme-tonal-spot"
    }

    FileView {
        path: root._stateFile
        adapter: stateData // qmllint disable missing-type
        onLoaded: {
            root.palette = stateData.palette;
            root.lastWallpaper = stateData.lastWallpaper;
            root.schemeType = stateData.schemeType;
        }
    }

    function apply(wallpaperPath) {
        if (root.applying)
            return;
        root.applying = true;
        applyProcess._wallpaperPath = wallpaperPath;
        applyProcess.command = ["bash", "-c", "awww img \"$1\" --transition-type fade --transition-duration 1 && matugen image \"$1\" --source-color-index 0 --type \"$2\" --mode \"$3\"", "--", wallpaperPath, root.schemeType, root.palette];
        applyProcess.running = true;
    }

    function togglePalette() {
        root.palette = (root.palette === "dark" ? "light" : "dark");
        root._persistState();
        if (root.applying || root.lastWallpaper === "")
            return;
        root.applying = true;
        applyProcess._wallpaperPath = root.lastWallpaper;
        applyProcess.command = ["bash", "-c", "matugen image \"$1\" --source-color-index 0 --type \"$2\" --mode \"$3\"", "--", root.lastWallpaper, root.schemeType, root.palette];
        applyProcess.running = true;
    }

    Process {
        id: applyProcess
        property string _wallpaperPath: ""
        onExited: (code, status) => { // qmllint disable signal-handler-parameters
            root.applying = false;
            if (code === 0) {
                root.lastWallpaper = applyProcess._wallpaperPath;
                root._persistState();
                if (!hookProcess.running)
                    hookProcess.running = true;
            }
        }
    }

    Process {
        id: hookProcess
        command: ["bash", "-c", "hook=\"$1\"; [ -x \"$hook\" ] && exec \"$hook\"", "--", root._home + "/.config/zesis/on-theme-change"]
    }

    Process {
        id: saveProcess
    }

    function _persistState() {
        var json = JSON.stringify({
            palette: root.palette,
            lastWallpaper: root.lastWallpaper,
            schemeType: root.schemeType
        });
        saveProcess.command = ["bash", "-c", "printf '%s' \"$1\" > \"$2\"", "--", json, root._stateFile];
        saveProcess.running = true;
    }
}
