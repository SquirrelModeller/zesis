pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/quickshell"
    readonly property string _configPath: _configDir + "/uiscale.json"

    property real value: scaleData.value
    property real fontScale: scaleData.fontScale
    property real spacingScale: scaleData.spacingScale
    property real radiusScale: scaleData.radiusScale

    readonly property real fontXs: 8 * value * fontScale
    readonly property real fontSm: 9 * value * fontScale
    readonly property real fontMd: 10 * value * fontScale
    readonly property real fontLg: 11 * value * fontScale

    readonly property real spacingSm: 8 * value * spacingScale
    readonly property real spacingMd: 14 * value * spacingScale
    readonly property real spacingLg: 20 * value * spacingScale

    readonly property real radiusSm: 6 * value * radiusScale
    readonly property real radiusMd: 10 * value * radiusScale
    readonly property real radiusLg: 14 * value * radiusScale

    function write(scaleV, fontV, spacingV, radiusV) {
        writeProc.command = ["sh", "-c", "mkdir -p '" + root._configDir + "' && echo '{" + "\"value\":" + scaleV.toFixed(2) + "," + "\"fontScale\":" + fontV.toFixed(2) + "," + "\"spacingScale\":" + spacingV.toFixed(2) + "," + "\"radiusScale\":" + radiusV.toFixed(2) + "}' > '" + root._configPath + "'"];
        writeProc.running = true;
    }

    JsonAdapter {
        id: scaleData
        property real value: 1.0
        property real fontScale: 1.0
        property real spacingScale: 1.0
        property real radiusScale: 1.0
    }

    FileView {
        path: root._configPath
        watchChanges: true
        adapter: scaleData
        onFileChanged: reload()
    }

    Process {
        id: writeProc
        running: false
    }
}
