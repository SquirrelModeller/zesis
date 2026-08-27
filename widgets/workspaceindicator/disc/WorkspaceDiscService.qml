pragma ComponentBehavior: Bound
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
    property bool expressive: settingsData.expressive
    property string skin: settingsData.skin
    property var monitors: settingsData.monitors
    property bool tuckEnabled: settingsData.tuckEnabled
    property bool showIslandBackground: settingsData.showIslandBackground
    property bool animateTransition: settingsData.animateTransition

    function setWorkSpaceAmount(v) {
        settingsData.workSpaceAmount = v;
        _writeDebounce.restart();
    }
    function setMinWorkSpaceAmount(v) {
        settingsData.minWorkSpaceAmount = v;
        _writeDebounce.restart();
    }
    function setDiscRadius(v) {
        settingsData.discRadius = v;
        _writeDebounce.restart();
    }
    function setToothWidth(v) {
        settingsData.toothWidth = v;
        _writeDebounce.restart();
    }
    function setValleyDepth(v) {
        settingsData.valleyDepth = v;
        _writeDebounce.restart();
    }
    function setChamberRadius(v) {
        settingsData.chamberRadius = v;
        _writeDebounce.restart();
    }
    function setChamberSize(v) {
        settingsData.chamberSize = v;
        _writeDebounce.restart();
    }
    function setExpressive(v) {
        settingsData.expressive = v;
        _writeDebounce.restart();
    }
    function setSkin(v) {
        settingsData.skin = v;
        _writeDebounce.restart();
    }
    function setMonitors(v) {
        settingsData.monitors = v;
        _writeDebounce.restart();
    }
    function setTuckEnabled(v) {
        settingsData.tuckEnabled = v;
        _writeDebounce.restart();
    }
    function setShowIslandBackground(v) {
        settingsData.showIslandBackground = v;
        _writeDebounce.restart();
    }
    function setAnimateTransition(v) {
        settingsData.animateTransition = v;
        _writeDebounce.restart();
    }

    // Because it's on a timer, if the caller makes burst calls, it resets until
    // it's been idle for N interval.
    Timer {
        id: _writeDebounce
        interval: 250
        onTriggered: settingsFile.writeAdapter()
    }

    JsonAdapter {
        id: settingsData
        property int workSpaceAmount: 6
        property int minWorkSpaceAmount: 1
        property int discRadius: 55
        property int toothWidth: 40
        property int valleyDepth: 28
        property int chamberRadius: 30
        property int chamberSize: 20
        property bool expressive: false
        property string skin: "default"
        property var monitors: []
        property bool tuckEnabled: true
        property bool showIslandBackground: false
        property bool animateTransition: true
    }

    FileView {
        id: settingsFile
        path: root._configPath
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        adapter: settingsData // qmllint disable missing-type
    }

    Component.onCompleted: {
        settingsFile.text();
    }
}
