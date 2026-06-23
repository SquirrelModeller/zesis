pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/display.json"

    property string monitorName: _backend.monitorName
    property string monitorModel: _backend.monitorModel
    property string monitorMake: _backend.monitorMake
    property int currentWidth: _backend.currentWidth
    property int currentHeight: _backend.currentHeight
    property real currentScale: _backend.currentScale
    property real currentRefresh: _backend.currentRefresh
    property int physicalWidthMm: _backend.physicalWidthMm
    property int physicalHeightMm: _backend.physicalHeightMm
    property var availableModes: _backend.availableModes

    readonly property real diagonalInches: {
        if (physicalWidthMm <= 0 || physicalHeightMm <= 0)
            return 0;
        var diagMm = Math.sqrt(physicalWidthMm * physicalWidthMm + physicalHeightMm * physicalHeightMm);
        return Math.round(diagMm / 25.4 * 10) / 10;
    }

    readonly property var parsedModes: {
        var modes = [];
        for (var i = 0; i < availableModes.length; i++) {
            var str = availableModes[i];
            var atIdx = str.lastIndexOf("@");
            var xIdx = str.indexOf("x");
            if (atIdx < 0 || xIdx < 0)
                continue;
            var w = parseInt(str.substring(0, xIdx));
            var h = parseInt(str.substring(xIdx + 1, atIdx));
            var r = parseFloat(str.substring(atIdx + 1).replace("Hz", ""));
            if (!isNaN(w) && !isNaN(h) && !isNaN(r))
                modes.push({
                    mode: str,
                    width: w,
                    height: h,
                    refresh: r
                });
        }
        return modes;
    }

    readonly property var uniqueResolutions: {
        var seen = {};
        var res = [];
        for (var i = 0; i < parsedModes.length; i++) {
            var key = parsedModes[i].width + "x" + parsedModes[i].height;
            if (!seen[key]) {
                seen[key] = true;
                res.push({
                    width: parsedModes[i].width,
                    height: parsedModes[i].height
                });
            }
        }
        return res;
    }

    function refreshRatesFor(w, h) {
        var rates = [];
        for (var i = 0; i < parsedModes.length; i++) {
            if (parsedModes[i].width !== w || parsedModes[i].height !== h)
                continue;
            var r = parsedModes[i].refresh;
            var dupe = false;
            for (var j = 0; j < rates.length; j++) {
                if (Math.abs(rates[j] - r) < 0.01) {
                    dupe = true;
                    break;
                }
            }
            if (!dupe)
                rates.push(r);
        }
        return rates;
    }

    function _refresh() {
        _backend.refresh();
    }

    function apply(modeStr) {
        _backend.apply(modeStr);
        saveProc.command = ["sh", "-c", "mkdir -p '" + root._configDir + "' && echo '" + JSON.stringify({
                monitor: root.monitorName,
                mode: modeStr
            }) + "' > '" + root._configPath + "'"];
        saveProc.running = true;
    }

    Component.onCompleted: {
        _refresh();
        startupTimer.start();
    }

    Timer {
        id: startupTimer
        interval: 400
        onTriggered: {
            if (savedAdapter.monitor && savedAdapter.mode)
                root.apply(savedAdapter.mode);
        }
    }

    property QtObject _backend: DisplayHyprlandBackend {}

    Process {
        id: saveProc
        running: false
    }

    JsonAdapter {
        id: savedAdapter
        property string monitor: ""
        property string mode: ""
    }

    FileView {
        path: root._configPath
        adapter: savedAdapter // qmllint disable missing-type
    }
}
