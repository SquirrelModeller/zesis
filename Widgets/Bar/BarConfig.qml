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

    readonly property bool isVertical: side === "left" || side === "right"

    function write(newSide) {
        _save(newSide, root.edgeGap, root.endGap);
    }

    function writeEdgeGap(newGap) {
        _save(root.side, newGap, root.endGap);
    }

    function writeEndGap(newGap) {
        _save(root.side, root.edgeGap, newGap);
    }

    function _save(s, eg, en) {
        writeProc.command = ["sh", "-c", "mkdir -p '" + root._configDir + "' && " + "printf '%s' '{\"side\":\"" + s + "\",\"edgeGap\":" + eg + ",\"endGap\":" + en + "}' > '" + root._configPath + "'"];
        writeProc.running = true;
    }

    JsonAdapter {
        id: barData
        property string side: "top"
        property int edgeGap: 8
        property int endGap: 20
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
