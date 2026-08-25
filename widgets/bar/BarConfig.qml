pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/barconfig.json"

    property string side: barData.side
    property int edgeGap: barData.edgeGap
    property int endGap: barData.endGap
    property real islandRoundness: barData.islandRoundness
    property bool showStrip: barData.showStrip
    property bool showIslands: barData.showIslands
    property int stripMargin: barData.stripMargin
    property var itemStates: barData.itemStates

    property var zones: barData.zones

    property var pinnedIds: barData.pinnedIds

    // Legacy migration step
    readonly property var _legacyItemIslands: barData.itemIslands
    // Names of screens (ShellScreen.name) the bar should appear on
    property var monitors: barData.monitors

    readonly property bool isVertical: side === "left" || side === "right"

    readonly property bool flushToBarEdge: root.showStrip

    readonly property real islandRadius: root.showIslands ? Math.round(30 * UIScale.value * root.islandRoundness) : 0

    readonly property real islandThickness: Math.round(50 * UIScale.value)
    readonly property real barThickness: root.islandThickness + (root.showStrip ? 2 * root.stripMargin : 0)

    // True when FileView completes loading
    property bool ready: false

    function _snapshot() {
        return {
            side: root.side,
            edgeGap: root.edgeGap,
            endGap: root.endGap,
            islandRoundness: root.islandRoundness,
            showStrip: root.showStrip,
            showIslands: root.showIslands,
            stripMargin: root.stripMargin,
            itemStates: root.itemStates,
            zones: root.zones,
            monitors: root.monitors,
            pinnedIds: root.pinnedIds
        };
    }

    function write(newSide) {
        _save(Object.assign(root._snapshot(), {
            side: newSide
        }));
    }

    function writeEdgeGap(newGap) {
        _save(Object.assign(root._snapshot(), {
            edgeGap: newGap
        }));
    }

    function writeEndGap(newGap) {
        _save(Object.assign(root._snapshot(), {
            endGap: newGap
        }));
    }

    function writeIslandRoundness(newRoundness) {
        _save(Object.assign(root._snapshot(), {
            islandRoundness: newRoundness
        }));
    }

    function writeStripMargin(newMargin) {
        _save(Object.assign(root._snapshot(), {
            stripMargin: newMargin
        }));
    }

    function setShowStrip(show) {
        _save(Object.assign(root._snapshot(), {
            showStrip: show
        }));
    }

    function setShowIslands(show) {
        _save(Object.assign(root._snapshot(), {
            showIslands: show
        }));
    }

    function writeItemStates(states) {
        _save(Object.assign(root._snapshot(), {
            itemStates: states
        }));
    }

    function writeZones(zones) {
        _save(Object.assign(root._snapshot(), {
            zones: zones
        }));
    }

    function writeMonitors(monitors) {
        _save(Object.assign(root._snapshot(), {
            monitors: monitors
        }));
    }

    function writePinnedIds(pinnedIds) {
        _save(Object.assign(root._snapshot(), {
            pinnedIds: pinnedIds
        }));
    }

    function _save(s) {
        const json = JSON.stringify(s);
        writeProc.command = ["sh", "-c", "mkdir -p '" + root._configDir + "' && printf '%s' '" + json + "' > '" + root._configPath + "'"];
        writeProc.running = true;
    }

    JsonAdapter {
        id: barData
        property string side: "top"
        property int edgeGap: 20
        property int endGap: 20
        property real islandRoundness: 1.0
        property bool showStrip: false
        property bool showIslands: true
        property int stripMargin: 0
        // Only overrides need listing - _merge() in BarItemsService fills
        // in every other catalog item as enabled.
        property var itemStates: ({
                "mic": false,
                "wifi": false
            })
        property var zones: [[["workspace"]], [["music"], ["taskbar"]], [["systray"], ["sysmon", "theme", "keybinds", "bluetooth", "wifi", "airpods", "weather", "brightness", "sound", "mic", "notifications", "config", "battery", "record", "gitupdate"], ["settings", "home", "lock", "clock"]]]
        // Legacy variable
        property var itemIslands: []
        property var monitors: []
        property var pinnedIds: ["workspace"]
    }

    FileView {
        id: barConfigFile
        path: root._configPath
        watchChanges: true
        printErrors: false
        blockLoading: true
        adapter: barData
        onFileChanged: reload()
        onLoaded: root.ready = true
        onLoadFailed: root.ready = true
    }

    Component.onCompleted: {
        barConfigFile.text();
    }

    Process {
        id: writeProc
        running: false
    }
}
