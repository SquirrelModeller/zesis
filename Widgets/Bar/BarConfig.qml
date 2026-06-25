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

    readonly property bool isVertical: side === "left" || side === "right"

    function write(newSide) {
        _save(newSide, root.edgeGap, root.endGap, root.itemStates);
    }

    function writeEdgeGap(newGap) {
        _save(root.side, newGap, root.endGap, root.itemStates);
    }

    function writeEndGap(newGap) {
        _save(root.side, root.edgeGap, newGap, root.itemStates);
    }

    function writeItemStates(states) {
        _save(root.side, root.edgeGap, root.endGap, states);
    }

    function _save(s, eg, en, states) {
        const json = '{"side":"' + s + '","edgeGap":' + eg + ',"endGap":' + en + ',"itemStates":' + JSON.stringify(states) + '}';
        writeProc.command = ["sh", "-c", "mkdir -p '" + root._configDir + "' && printf '%s' '" + json + "' > '" + root._configPath + "'"];
        writeProc.running = true;
    }

    JsonAdapter {
        id: barData
        property string side: "top"
        property int edgeGap: 8
        property int endGap: 20
        property var itemStates: ({})
    }

    FileView {
        path: root._configPath
        watchChanges: true
        adapter: barData
        onFileChanged: reload()
    }

    Process {
        id: writeProc
        running: false
    }
}
