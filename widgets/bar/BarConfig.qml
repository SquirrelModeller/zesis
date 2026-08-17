pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/barconfig.json"

    property string side: barData.side
    property int edgeGap: barData.edgeGap
    property int endGap: barData.endGap
    property var itemStates: barData.itemStates

    property var zones: barData.zones

    // Legacy migration step
    readonly property var _legacyItemIslands: barData.itemIslands
    // Names of screens (ShellScreen.name) the bar should appear on
    property var monitors: barData.monitors

    readonly property bool isVertical: side === "left" || side === "right"

    // True when FileView completes loading
    property bool ready: false

    function write(newSide) {
        _save(newSide, root.edgeGap, root.endGap, root.itemStates, root.zones, root.monitors);
    }

    function writeEdgeGap(newGap) {
        _save(root.side, newGap, root.endGap, root.itemStates, root.zones, root.monitors);
    }

    function writeEndGap(newGap) {
        _save(root.side, root.edgeGap, newGap, root.itemStates, root.zones, root.monitors);
    }

    function writeItemStates(states) {
        _save(root.side, root.edgeGap, root.endGap, states, root.zones, root.monitors);
    }

    function writeZones(zones) {
        _save(root.side, root.edgeGap, root.endGap, root.itemStates, zones, root.monitors);
    }

    function writeMonitors(monitors) {
        _save(root.side, root.edgeGap, root.endGap, root.itemStates, root.zones, monitors);
    }

    function _save(s, eg, en, states, zones, monitors) {
        const json = '{"side":"' + s + '","edgeGap":' + eg + ',"endGap":' + en + ',"itemStates":' + JSON.stringify(states) + ',"zones":' + JSON.stringify(zones) + ',"monitors":' + JSON.stringify(monitors) + '}';
        writeProc.command = ["sh", "-c", "mkdir -p '" + root._configDir + "' && printf '%s' '" + json + "' > '" + root._configPath + "'"];
        writeProc.running = true;
    }

    JsonAdapter {
        id: barData
        property string side: "top"
        property int edgeGap: 8
        property int endGap: 20
        property var itemStates: ({})
        property var zones: []
        // Legacy variable
        property var itemIslands: []
        property var monitors: []
    }

    FileView {
        path: root._configPath
        watchChanges: true
        printErrors: false
        adapter: barData
        onFileChanged: reload()
        onLoaded: root.ready = true
        onLoadFailed: root.ready = true
    }

    Process {
        id: writeProc
        running: false
    }
}
