pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

// IPC persisted settings state. These are for top level app windows.
Singleton {
    id: root

    required property string configName

    property string requestedPageId: ""
    property string requestedSubTabId: ""
    property string requestedSearch: ""
    property bool windowOpen: false

    property int requestSeq: 0
    property int closeSeq: 0
    property int toggleSeq: 0

    function openPage(pageId) {
        root.requestedPageId = pageId;
        root.requestedSubTabId = "";
        root.requestedSearch = "";
        root.requestSeq++;
    }

    function openPageTab(pageId, subTabId) {
        root.requestedPageId = pageId;
        root.requestedSubTabId = subTabId;
        root.requestedSearch = "";
        root.requestSeq++;
    }

    function openSearch(query) {
        root.requestedSearch = query;
        root.requestedPageId = "";
        root.requestedSubTabId = "";
        root.requestSeq++;
    }

    function requestClose() {
        root.closeSeq++;
    }

    function requestToggle() {
        root.toggleSeq++;
    }

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: root._configDir + "/" + root.configName + ".json"
    property bool expandAllSubTabs: settingsData.expandAllSubTabs

    function writeExpandAllSubTabs(val) {
        writeProc.command = ["sh", "-c", "mkdir -p '" + root._configDir + "' && printf '%s' '{\"expandAllSubTabs\":" + (val ? "true" : "false") + "}' > '" + root._configPath + "'"];
        writeProc.running = true;
    }

    JsonAdapter {
        id: settingsData
        property bool expandAllSubTabs: false
    }

    FileView {
        id: settingsFile
        path: root._configPath
        watchChanges: true
        printErrors: false
        blockLoading: true
        adapter: settingsData
        onFileChanged: reload()
    }

    Component.onCompleted: settingsFile.text()

    Process {
        id: writeProc
        running: false
    }
}
