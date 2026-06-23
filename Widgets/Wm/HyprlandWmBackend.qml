import QtQuick
import Quickshell.Hyprland

QtObject {
    id: root

    readonly property var workspaces: Hyprland.workspaces.values
    readonly property var toplevels: Hyprland.toplevels.values
    readonly property var focusedMonitor: Hyprland.focusedMonitor

    function focusWorkspace(id) {
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })");
    }

    function focusWindow(addr) {
        Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + addr + "\" })");
    }

    function moveWindow(addr, wsId) {
        Hyprland.dispatch("hl.dsp.window.move({ workspace = " + wsId + ", window = \"address:" + addr + "\" })");
    }

    function moveWindowSilent(addr, wsId) {
        Hyprland.dispatch("hl.dsp.window.move({ workspace = " + wsId + ", window = \"address:" + addr + "\", follow = false })");
    }

    function moveWindowToName(addr, name) {
        Hyprland.dispatch("hl.dsp.window.move({ workspace = \"name:" + name + "\", window = \"address:" + addr + "\", follow = false })");
    }

    function preselect(dir) {
        Hyprland.dispatch("hl.dsp.layout(\"preselect " + dir + "\")");
    }

    function refreshToplevels() {
        Hyprland.refreshToplevels();
    }

    function refreshWorkspaces() {
        Hyprland.refreshWorkspaces();
    }
}
