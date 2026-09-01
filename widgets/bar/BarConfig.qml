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

    // Names of screens (ShellScreen.name) the bar should appear on
    property var monitors: barData.monitors

    readonly property bool isVertical: side === "left" || side === "right"

    readonly property bool flushToBarEdge: root.showStrip

    readonly property real islandRadius: root.showIslands ? Math.round(30 * UIScale.value * root.islandRoundness) : 0

    readonly property real islandThickness: Math.round(50 * UIScale.value)
    readonly property real barThickness: root.islandThickness + (root.showStrip ? 2 * root.stripMargin : 0)

    // True when FileView completes loading
    property bool ready: false

    function patch(fields) {
        for (var k in fields)
            barData[k] = fields[k];
        _writeDebounce.restart();
    }

    // Coalesces bursts of writes (e.g. a slider dragged across many
    // onMoved events) into a single disk write.
    Timer {
        id: _writeDebounce
        interval: 250
        onTriggered: barConfigFile.writeAdapter()
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
}
