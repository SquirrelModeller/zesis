pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persisted GameBuds settings.
Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/gamebudssettings.json"

    property bool wearSenseEnabled: settingsData.wearSenseEnabled
    property bool autoPauseEnabled: settingsData.autoPauseEnabled
    // 1..10, confirmed range - GameBudsBTService: minMicVolume=1, maxMicVolume=10
    property int micLevel: settingsData.micLevel
    // 0..3 UI level (device-mapped), confirmed range - GameBudsBTService.setSidetoneVolume()
    property int sidetoneLevel: settingsData.sidetoneLevel
    property bool volumeLimiter: settingsData.volumeLimiter
    // minutes, confirmed via the QA debug menu's setAutoOffTimerDelay() calls (0..90)
    property int autoOffTimer: settingsData.autoOffTimer

    // Set once the first GameBuds device is ever detected. Gates the Settings tab
    property bool everSeen: settingsData.everSeen

    // generic writer for the settings above
    function set(key, value) {
        settingsData[key] = value;
        settingsFile.writeAdapter();
    }

    JsonAdapter {
        id: settingsData
        property bool wearSenseEnabled: true
        property bool autoPauseEnabled: false
        property int micLevel: 5
        property int sidetoneLevel: 0
        property bool volumeLimiter: false
        property int autoOffTimer: 0
        property bool everSeen: false
    }

    FileView {
        id: settingsFile
        path: root._configPath
        watchChanges: true
        printErrors: false
        adapter: settingsData
        onFileChanged: reload()
    }
}
