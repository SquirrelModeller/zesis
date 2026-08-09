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
    property string wallpaperBackend: "awww"
    property string customWallpaperCommand: ""
    property bool applying: false
    property string lastError: ""
    // Per-monitor overrides: { "DP-1": "/path/to/wall.png", ... }. A monitor with no entry
    // here just shows lastWallpaper.
    property var perMonitorWallpaper: ({})
    // Which monitor's wallpaper drives matugen. "" = the global/all-monitors wallpaper
    property string colorSourceMonitor: ""

    readonly property var wallpaperBackends: [
        {
            id: "awww",
            label: "awww",
            command: "awww img \"$1\" --transition-type fade --transition-duration 1",
            monitorCommand: "awww img \"$1\" --transition-type fade --transition-duration 1 --outputs \"$2\""
        },
        {
            id: "swww",
            label: "swww",
            command: "swww img \"$1\" --transition-type fade --transition-duration 1",
            monitorCommand: "swww img \"$1\" --transition-type fade --transition-duration 1 --outputs \"$2\""
        },
        {
            id: "hyprpaper",
            label: "hyprpaper",
            command: "hyprctl hyprpaper preload \"$1\" && hyprctl hyprpaper wallpaper \",$1\"",
            monitorCommand: "hyprctl hyprpaper preload \"$1\" && hyprctl hyprpaper wallpaper \"$2,$1\""
        },
        {
            id: "feh",
            label: "feh (X11)",
            // feh has no concept of named Wayland outputs, idk what to do here
            command: "feh --bg-fill \"$1\"",
            monitorCommand: "feh --bg-fill \"$1\""
        },
        {
            id: "custom",
            label: "Custom command...",
            command: "",
            monitorCommand: ""
        }
    ]

    // monitor is "" for the global/all-monitors wallpaper.
    function _wallpaperSetCmd(monitor) {
        if (root.wallpaperBackend === "custom")
            return root.customWallpaperCommand.trim();
        for (var i = 0; i < root.wallpaperBackends.length; i++) {
            if (root.wallpaperBackends[i].id === root.wallpaperBackend)
                return monitor ? root.wallpaperBackends[i].monitorCommand : root.wallpaperBackends[i].command;
        }
        return monitor ? root.wallpaperBackends[0].monitorCommand : root.wallpaperBackends[0].command;
    }

    Process {
        command: ["mkdir", "-p", root.thumbsDir]
        running: true
    }

    JsonAdapter {
        id: stateData
        property string palette: "dark"
        property string lastWallpaper: ""
        property string schemeType: "scheme-tonal-spot"
        property string wallpaperBackend: "awww"
        property string customWallpaperCommand: ""
        property var perMonitorWallpaper: ({})
        property string colorSourceMonitor: ""
    }

    FileView {
        path: root._stateFile
        adapter: stateData // qmllint disable missing-type
        onLoaded: {
            root.palette = stateData.palette;
            root.lastWallpaper = stateData.lastWallpaper;
            root.schemeType = stateData.schemeType;
            root.wallpaperBackend = stateData.wallpaperBackend;
            root.customWallpaperCommand = stateData.customWallpaperCommand;
            root.perMonitorWallpaper = stateData.perMonitorWallpaper;
            root.colorSourceMonitor = stateData.colorSourceMonitor;
        }
    }

    function _effectiveWallpaper(monitor) {
        if (!monitor)
            return root.lastWallpaper;
        return root.perMonitorWallpaper[monitor] || root.lastWallpaper;
    }

    // Sets the wallpaper for every monitor. This overwrites every output at the daemon
    // level, so it also wipes any per-monitor overrides (onExited below) and always
    // recomputes the system color scheme from it.
    function apply(wallpaperPath) {
        root._apply(wallpaperPath, "", true);
    }

    function applyToMonitor(wallpaperPath, monitor) {
        if (!monitor)
            return;
        root._apply(wallpaperPath, monitor, root.colorSourceMonitor === monitor);
    }

    function resetMonitor(monitor) {
        if (!monitor || !(monitor in root.perMonitorWallpaper))
            return;
        var next = Object.assign({}, root.perMonitorWallpaper);
        delete next[monitor];
        root.perMonitorWallpaper = next;
        root._persistState();
        // Re-run the backend command to visually sync the output, but don't let it
        // re-record an override, cause that's what we just cleared. Recolor if this monitor
        // was the color source, since its effective wallpaper just changed back to global0.
        if (root.lastWallpaper !== "")
            root._apply(root.lastWallpaper, monitor, root.colorSourceMonitor === monitor, false);
    }

    // Picks which monitor's wallpaper drives the system color scheme, and immediately
    // recomputes colors from whatever that monitor is currently showing.
    function setColorSourceMonitor(monitor) {
        if (root.colorSourceMonitor === monitor)
            return;
        root.colorSourceMonitor = monitor;
        root._persistState();
        var path = root._effectiveWallpaper(monitor);
        if (path !== "")
            root._recolor(path);
    }

    function _recolor(path) {
        if (root.applying)
            return;
        root.applying = true;
        root.lastError = "";
        applyProcess._wallpaperPath = path;
        applyProcess._monitor = "";
        applyProcess._persistOverride = false;
        applyProcess.command = ["bash", "-c", "matugen image \"$1\" --source-color-index 0 --type \"$2\" --mode \"$3\"", "--", path, root.schemeType, root.palette];
        applyProcess.running = true;
    }

    function _apply(wallpaperPath, monitor, recolor, persistOverride = true) {
        if (root.applying)
            return;
        root.applying = true;
        root.lastError = "";
        applyProcess._wallpaperPath = wallpaperPath;
        applyProcess._monitor = monitor;
        applyProcess._persistOverride = persistOverride;
        var setCmd = root._wallpaperSetCmd(monitor);
        var parts = [];
        if (setCmd.length > 0)
            parts.push(setCmd);
        if (recolor)
            parts.push("matugen image \"$1\" --source-color-index 0 --type \"$3\" --mode \"$4\"");
        var script = parts.length > 0 ? parts.join(" && ") : "true";
        applyProcess.command = ["bash", "-c", script, "--", wallpaperPath, monitor, root.schemeType, root.palette];
        applyProcess.running = true;
    }

    function togglePalette() {
        root.palette = (root.palette === "dark" ? "light" : "dark");
        root._persistState();
        var path = root._effectiveWallpaper(root.colorSourceMonitor);
        if (path !== "")
            root._recolor(path);
    }

    Process {
        id: applyProcess
        property string _wallpaperPath: ""
        property string _monitor: ""
        property bool _persistOverride: true

        stderr: StdioCollector {
            id: applyStderr
        }

        onExited: (code, status) => { // qmllint disable signal-handler-parameters
            root.applying = false;
            if (code === 0) {
                if (applyProcess._persistOverride) {
                    if (applyProcess._monitor === "") {
                        root.lastWallpaper = applyProcess._wallpaperPath;
                        // A global apply just overwrote every output at the daemon level,
                        // so any per-monitor overrides we were tracking are stale now.
                        if (Object.keys(root.perMonitorWallpaper).length > 0)
                            root.perMonitorWallpaper = {};
                    } else {
                        var next = Object.assign({}, root.perMonitorWallpaper);
                        next[applyProcess._monitor] = applyProcess._wallpaperPath;
                        root.perMonitorWallpaper = next;
                    }
                }
                root._persistState();
                if (!hookProcess.running)
                    hookProcess.running = true;
            } else {
                root.lastError = applyStderr.text.trim() || ("Command exited with code " + code);
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
            schemeType: root.schemeType,
            wallpaperBackend: root.wallpaperBackend,
            customWallpaperCommand: root.customWallpaperCommand,
            perMonitorWallpaper: root.perMonitorWallpaper,
            colorSourceMonitor: root.colorSourceMonitor
        });
        saveProcess.command = ["bash", "-c", "printf '%s' \"$1\" > \"$2\"", "--", json, root._stateFile];
        saveProcess.running = true;
    }
}
