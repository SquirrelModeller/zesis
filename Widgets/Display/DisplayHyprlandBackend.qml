import QtQuick
import Quickshell.Io

// Hyprland-specific display backend.
// Reads monitor info via `hyprctl monitors -j` and applies settings via `hyprctl eval`.
//
// Interface (shared with any future compositor backend):
//   property string monitorName
//   property string monitorModel
//   property string monitorMake
//   property int    currentWidth
//   property int    currentHeight
//   property real   currentScale
//   property real   currentRefresh
//   property int    physicalWidthMm
//   property int    physicalHeightMm
//   property var    availableModes   - list of "WxH@RHz" strings
//
//   function refresh()           - re-fetch monitor state
//   function apply(modeStr)      - apply mode string, then refresh

QtObject {
    id: root

    property string monitorName: ""
    property string monitorModel: ""
    property string monitorMake: ""
    property int currentWidth: 0
    property int currentHeight: 0
    property real currentScale: 1.0
    property real currentRefresh: 0
    property int physicalWidthMm: 0
    property int physicalHeightMm: 0
    property var availableModes: []

    function refresh() {
        refreshProc.running = true;
    }

    function apply(modeStr) {
        var pos = root.currentWidth > 0 ? "0x0" : "auto";
        applyProc.command = ["hyprctl", "eval", 'hl.monitor({output="' + root.monitorName + '", mode="' + modeStr + '", position="' + pos + '", scale=' + root.currentScale + '})'];
        applyProc.running = true;
    }

    property string _monitorJson: ""

    property QtObject _refreshProc: Process {
        id: refreshProc
        command: ["hyprctl", "monitors", "-j"]
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root._monitorJson += data
        }
        onRunningChanged: {
            if (!running && root._monitorJson !== "") {
                try {
                    var monitors = JSON.parse(root._monitorJson);
                    var m = monitors[0];
                    for (var i = 0; i < monitors.length; i++) {
                        if (monitors[i].focused) {
                            m = monitors[i];
                            break;
                        }
                    }
                    root.monitorName = m.name ?? "";
                    root.monitorModel = m.model ?? "";
                    root.monitorMake = m.make ?? "";
                    root.currentWidth = m.width ?? 0;
                    root.currentHeight = m.height ?? 0;
                    root.currentScale = m.scale ?? 1.0;
                    root.currentRefresh = m.refreshRate ?? 0;
                    root.physicalWidthMm = m.physicalWidth ?? 0;
                    root.physicalHeightMm = m.physicalHeight ?? 0;
                    root.availableModes = m.availableModes ?? [];
                } catch (e) {
                    console.warn("[DisplayHyprlandBackend] failed to parse hyprctl output:", e);
                }
                root._monitorJson = "";
            }
        }
    }

    property QtObject _applyProc: Process {
        id: applyProc
        running: false
        onRunningChanged: {
            if (!running)
                root.refresh();
        }
    }
}
