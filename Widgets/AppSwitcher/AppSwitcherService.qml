pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property bool open: false
    property int selectedIndex: 0

    // Sorted by focusHistoryID ascending: index 0 = current window, 1 = most recently used, etc.
    readonly property var windows: {
        var tops = Hyprland.toplevels.values.slice();
        tops.sort((a, b) => {
            var fa = (a.lastIpcObject && "focusHistoryID" in a.lastIpcObject) ? a.lastIpcObject["focusHistoryID"] : 9999;
            var fb = (b.lastIpcObject && "focusHistoryID" in b.lastIpcObject) ? b.lastIpcObject["focusHistoryID"] : 9999;
            return fa - fb;
        });
        return tops;
    }

    onWindowsChanged: {
        if (selectedIndex >= windows.length)
            selectedIndex = Math.max(0, windows.length - 1);
    }

    function show() {
        if (windows.length === 0)
            return;
        Hyprland.refreshToplevels();
        // Start at 1: skip current window, land on last-used
        selectedIndex = windows.length > 1 ? 1 : 0;
        open = true;
    }

    function cycleForward() {
        if (!open) {
            show();
            return;
        }
        if (windows.length === 0)
            return;
        selectedIndex = (selectedIndex + 1) % windows.length;
    }

    function cycleBack() {
        if (!open) {
            show();
            // show() lands on index 1, step to last window instead
            if (windows.length > 2)
                selectedIndex = windows.length - 1;
            return;
        }
        if (windows.length === 0)
            return;
        selectedIndex = (selectedIndex - 1 + windows.length) % windows.length;
    }

    function confirm() {
        if (!open)
            return;
        var idx = selectedIndex;
        var wins = windows;
        open = false;
        if (idx >= 0 && idx < wins.length) {
            var win = wins[idx];
            if (win && win.lastIpcObject) {
                var addr = win.lastIpcObject["address"];
                if (addr)
                    Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + addr + "\" })");
            }
        }
    }

    function cancel() {
        open = false;
    }
}
