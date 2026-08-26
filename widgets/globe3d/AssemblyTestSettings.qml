pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/assemblytestsettings.json"

    property string aaMode: settingsData.aaMode // "Off" | "Medium" | "High" | "VeryHigh"
    property bool useImageCache: settingsData.useImageCache

    function write(am, uic) {
        settingsData.aaMode = am;
        settingsData.useImageCache = uic;
        settingsFile.writeAdapter();
    }

    function writeAaMode(mode) {
        write(mode, root.useImageCache);
    }
    function writeUseImageCache(val) {
        write(root.aaMode, val);
    }

    JsonAdapter {
        id: settingsData
        property string aaMode: "High"
        property bool useImageCache: true
    }

    FileView {
        id: settingsFile
        path: root._configPath
        watchChanges: true
        adapter: settingsData
        onFileChanged: reload()
    }
}
