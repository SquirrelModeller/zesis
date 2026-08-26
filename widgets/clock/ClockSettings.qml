pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/clocksettings.json"

    // "breathe" | "on" | "off" | "hidden"
    property string colonMode: settingsData.colonMode
    // "fixed" | "fluid"
    property string widthMode: settingsData.widthMode
    property bool showDate: settingsData.showDate
    property bool use12Hour: settingsData.use12Hour

    signal altModeRequested

    function write(cm, wm, sd, h12) {
        settingsData.colonMode = cm;
        settingsData.widthMode = wm;
        settingsData.showDate = sd;
        settingsData.use12Hour = h12;
        settingsFile.writeAdapter();
    }

    function writeColonMode(mode) {
        write(mode, root.widthMode, root.showDate, root.use12Hour);
    }
    function writeWidthMode(mode) {
        write(root.colonMode, mode, root.showDate, root.use12Hour);
    }
    function writeShowDate(val) {
        write(root.colonMode, root.widthMode, val, root.use12Hour);
    }
    function writeUse12Hour(val) {
        write(root.colonMode, root.widthMode, root.showDate, val);
    }

    JsonAdapter {
        id: settingsData
        property string colonMode: "on"
        property string widthMode: "fixed"
        property bool showDate: false
        property bool use12Hour: false
    }

    FileView {
        id: settingsFile
        path: root._configPath
        watchChanges: true
        adapter: settingsData
        onFileChanged: reload()
    }
}
