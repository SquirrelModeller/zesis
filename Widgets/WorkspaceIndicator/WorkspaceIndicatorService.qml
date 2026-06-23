pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/workspaceindicator.json"

    property int workSpaceAmount: settingsData.workSpaceAmount
    property int minWorkSpaceAmount: settingsData.minWorkSpaceAmount
    property int discRadius: settingsData.discRadius
    property int toothWidth: settingsData.toothWidth
    property int valleyDepth: settingsData.valleyDepth
    property int chamberRadius: settingsData.chamberRadius
    property int chamberSize: settingsData.chamberSize
    property int peekOffset: settingsData.peekOffset
    property bool expressive: settingsData.expressive

    property bool _loaded: false
    Component.onCompleted: Qt.callLater(function () {
        root._loaded = true;
    })

    onWorkSpaceAmountChanged: if (_loaded)
        _write()
    onMinWorkSpaceAmountChanged: if (_loaded)
        _write()
    onDiscRadiusChanged: if (_loaded)
        _write()
    onToothWidthChanged: if (_loaded)
        _write()
    onValleyDepthChanged: if (_loaded)
        _write()
    onChamberRadiusChanged: if (_loaded)
        _write()
    onChamberSizeChanged: if (_loaded)
        _write()
    onPeekOffsetChanged: if (_loaded)
        _write()
    onExpressiveChanged: if (_loaded)
        _write()

    function _write() {
        writeProc.command = ["sh", "-c", "mkdir -p '" + root._configDir + "' && echo '" + JSON.stringify({
                workSpaceAmount: root.workSpaceAmount,
                minWorkSpaceAmount: root.minWorkSpaceAmount,
                discRadius: root.discRadius,
                toothWidth: root.toothWidth,
                valleyDepth: root.valleyDepth,
                chamberRadius: root.chamberRadius,
                chamberSize: root.chamberSize,
                peekOffset: root.peekOffset,
                expressive: root.expressive
            }) + "' > '" + root._configPath + "'"];
        writeProc.running = true;
    }

    JsonAdapter {
        id: settingsData
        property int workSpaceAmount: 6
        property int minWorkSpaceAmount: 1
        property int discRadius: 55
        property int toothWidth: 40
        property int valleyDepth: 28
        property int chamberRadius: 30
        property int chamberSize: 26
        property int peekOffset: 16
        property bool expressive: false
    }

    FileView {
        path: root._configPath
        adapter: settingsData // qmllint disable missing-type
    }

    Process {
        id: writeProc
        running: false
    }
}
