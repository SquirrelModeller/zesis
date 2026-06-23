pragma Singleton

import QtQuick
import Quickshell

// Compositor-agnostic window-manager service.
// Swap the backend property to support a different compositor.
// Should probably make this a setting in the future.
Singleton {
    id: root

    property QtObject _backend: HyprlandWmBackend {}

    // Live data, object shapes are backend-defined
    // live list of workspace objects ({ name, monitor, toplevels, ... })
    readonly property var workspaces: _backend.workspaces
    // live list of toplevel objects ({ lastIpcObject, workspace, wayland, ... })
    readonly property var toplevels: _backend.toplevels
    //current monitor ({ width, height, scale, x, y, activeWorkspace })
    readonly property var focusedMonitor: _backend.focusedMonitor

    // switch to workspace by numeric id
    function focusWorkspace(id) {
        _backend.focusWorkspace(id);
    }
    // focus window by address string
    function focusWindow(addr) {
        _backend.focusWindow(addr);
    }
    // move window to workspace (takes focus)
    function moveWindow(addr, wsId) {
        _backend.moveWindow(addr, wsId);
    }
    // move window to workspace (no focus change)
    function moveWindowSilent(addr, wsId) {
        _backend.moveWindowSilent(addr, wsId);
    }
    // move window to named workspace, silently
    function moveWindowToName(addr, name) {
        _backend.moveWindowToName(addr, name);
    }
    // dwindle layout preselect (u/d/l/r)
    function preselect(dir) {
        _backend.preselect(dir);
    }
    function refreshToplevels() {
        _backend.refreshToplevels();
    }
    function refreshWorkspaces() {
        _backend.refreshWorkspaces();
    }
}
