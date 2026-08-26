import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

QtObject {
    id: root

    property bool _hasHyprshutdown: false

    property QtObject _hyprshutdownCheck: Process {
        command: ["sh", "-c", "which hyprshutdown >/dev/null 2>&1"]
        running: true
        onExited: code => root._hasHyprshutdown = (code === 0)
    }

    readonly property var workspaces: Hyprland.workspaces.values
    readonly property var toplevels: Hyprland.toplevels.values
    readonly property var focusedMonitor: Hyprland.focusedMonitor

    function activeWorkspaceFor(screen) {
        return Hyprland.monitorFor(screen)?.activeWorkspace ?? null;
    }

    // Better safe than sorry, we don't allow any calls to escape
    function _esc(s) {
        return String(s).replace(/\\/g, "\\\\").replace(/"/g, "\\\"");
    }

    function focusWorkspace(id) {
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + Number(id) + " })");
    }

    function focusWindow(addr) {
        Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + root._esc(addr) + "\" })");
    }

    function moveWindow(addr, wsId) {
        Hyprland.dispatch("hl.dsp.window.move({ workspace = " + Number(wsId) + ", window = \"address:" + root._esc(addr) + "\" })");
    }

    function moveWindowSilent(addr, wsId) {
        Hyprland.dispatch("hl.dsp.window.move({ workspace = " + Number(wsId) + ", window = \"address:" + root._esc(addr) + "\", follow = false })");
    }

    function moveWindowToName(addr, name) {
        Hyprland.dispatch("hl.dsp.window.move({ workspace = \"name:" + root._esc(name) + "\", window = \"address:" + root._esc(addr) + "\", follow = false })");
    }

    function focusWindowByPid(pid) {
        var toplevels = Hyprland.toplevels.values;
        var best = null;
        var bestScore = -1;
        for (var i = 0; i < toplevels.length; i++) {
            var obj = toplevels[i].lastIpcObject;
            if (obj && obj["pid"] == pid) {
                var score = obj["focusHistoryID"] ?? 0;
                if (score > bestScore) {
                    bestScore = score;
                    best = obj;
                }
            }
        }
        if (best)
            Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + root._esc(best["address"]) + "\" })");
    }

    function focusWindowByClass(cls) {
        var toplevels = Hyprland.toplevels.values;
        for (var i = 0; i < toplevels.length; i++) {
            var obj = toplevels[i].lastIpcObject;
            if (obj && (obj["class"] ?? "").toLowerCase() === cls.toLowerCase()) {
                Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + root._esc(obj["address"]) + "\" })");
                return;
            }
        }
    }

    function preselect(dir) {
        Hyprland.dispatch("hl.dsp.layout(\"preselect " + root._esc(dir) + "\")");
    }

    function refreshToplevels() {
        Hyprland.refreshToplevels();
    }

    function refreshWorkspaces() {
        Hyprland.refreshWorkspaces();
    }

    function refreshMonitors() {
        Hyprland.refreshMonitors();
    }

    function logout() {
        if (root._hasHyprshutdown)
            Quickshell.execDetached(["hyprshutdown"]);
        else
            Hyprland.dispatch("hl.dsp.exit()");
    }

    function closeAppsThen(cmd) {
        if (root._hasHyprshutdown)
            Quickshell.execDetached(["hyprshutdown", "--post-cmd", cmd]);
        else
            Quickshell.execDetached(["bash", "-c", cmd]);
    }
}
