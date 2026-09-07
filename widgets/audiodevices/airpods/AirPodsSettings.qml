pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persisted AirPods settings.
Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/airpodssettings.json"

    // subset of "off" | "anc" | "transparency" | "adaptive"
    property var pressHoldModes: settingsData.pressHoldModes
    property bool earDetection: settingsData.earDetection
    property bool oneBudAnc: settingsData.oneBudAnc
    property int adaptiveLevel: settingsData.adaptiveLevel
    property bool caEnabled: settingsData.caEnabled
    property bool caseSounds: settingsData.caseSounds
    property bool autoPauseEnabled: settingsData.autoPauseEnabled

    // "auto" | "left" | "right"
    property string micMode: settingsData.micMode
    property bool volumeSwipe: settingsData.volumeSwipe
    property bool adaptiveVolume: settingsData.adaptiveVolume
    property bool sleepDetection: settingsData.sleepDetection
    property int caseToneVolume: settingsData.caseToneVolume
    property int chimeVolume: settingsData.chimeVolume

    // Set once the first AirPods device is ever detected. Gates the Settings tab
    property bool everSeen: settingsData.everSeen

    // generic writer for the settings above
    function set(key, value) {
        settingsData[key] = value;
        settingsFile.writeAdapter();
    }

    function writePressHoldModes(v) {
        settingsData.pressHoldModes = v;
        settingsFile.writeAdapter();
    }
    function writeEarDetection(v) {
        settingsData.earDetection = v;
        settingsFile.writeAdapter();
    }
    function writeOneBudAnc(v) {
        settingsData.oneBudAnc = v;
        settingsFile.writeAdapter();
    }
    function writeAdaptiveLevel(v) {
        settingsData.adaptiveLevel = v;
        settingsFile.writeAdapter();
    }
    function writeCaEnabled(v) {
        settingsData.caEnabled = v;
        settingsFile.writeAdapter();
    }
    function writeCaseSounds(v) {
        settingsData.caseSounds = v;
        settingsFile.writeAdapter();
    }
    function writeAutoPauseEnabled(v) {
        settingsData.autoPauseEnabled = v;
        settingsFile.writeAdapter();
    }

    JsonAdapter {
        id: settingsData
        property var pressHoldModes: ["anc", "transparency"]
        property bool earDetection: true
        property bool oneBudAnc: true
        property int adaptiveLevel: 50
        property bool caEnabled: true
        property bool caseSounds: true
        property bool autoPauseEnabled: true
        property string micMode: "auto"
        property bool volumeSwipe: true
        property bool adaptiveVolume: false
        property bool sleepDetection: false
        property int caseToneVolume: 100
        property int chimeVolume: 100
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
