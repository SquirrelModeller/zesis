pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/cava-widget-settings.json"

    property int barCount: settingsData.barCount

    // Independent to each channel, average left and right
    readonly property var orientations: settingsData.orientations

    readonly property string style: settingsData.style === "area" ? "area" : "bars"

    readonly property string renderer: settingsData.renderer === "gpu" ? "gpu" : "cpu"

    function writeRenderer(val) {
        if (val !== "cpu" && val !== "gpu")
            return;
        settingsData.renderer = val;
        settingsFile.writeAdapter();
    }

    function writeBarCount(val) {
        settingsData.barCount = Math.max(4, Math.min(256, Math.round(val)));
        settingsFile.writeAdapter();
    }

    function writeStyle(val) {
        if (val !== "bars" && val !== "area")
            return;
        settingsData.style = val;
        settingsFile.writeAdapter();
    }

    // edge the bars align to
    function orientationFor(channel) {
        var v = settingsData.orientations[channel];
        return (v === "bottom" || v === "top" || v === "left" || v === "right") ? v : "bottom";
    }

    function writeOrientation(channel, val) {
        if (val !== "bottom" && val !== "top" && val !== "left" && val !== "right")
            return;
        var copy = Object.assign({}, settingsData.orientations);
        copy[channel] = val;
        settingsData.orientations = copy;
        settingsFile.writeAdapter();
    }

    // Show low frequencies at start or end
    readonly property var flips: settingsData.flips

    function flipFor(channel) {
        return !!settingsData.flips[channel];
    }

    function writeFlip(channel, val) {
        var copy = Object.assign({}, settingsData.flips);
        copy[channel] = !!val;
        settingsData.flips = copy;
        settingsFile.writeAdapter();
    }

    readonly property bool autoHide: settingsData.autoHide

    function writeAutoHide(val) {
        settingsData.autoHide = !!val;
        settingsFile.writeAdapter();
    }

    JsonAdapter {
        id: settingsData
        property int barCount: 32
        property var orientations: ({})
        property string style: "bars"
        property string renderer: "cpu"
        property var flips: ({})
        property bool autoHide: true
    }

    FileView {
        id: settingsFile
        path: root._configPath
        watchChanges: true
        adapter: settingsData
        onFileChanged: reload()
    }
}
