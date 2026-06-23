// qmllint disable import
pragma Singleton
// qmllint enable import
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/sysmon.json"

    property bool popupOpen: false
    property bool panelOpen: false
    property int activeTab: 0  // 0=CPU, 1=Memory, 2=GPU, 3=Net, 4=Disk, 5=Settings
    property int pullRateMs: sysmonData.pullRateMs
    property int procLimit: sysmonData.procLimit
    property bool filterZero: sysmonData.filterZero

    property var cpu: ({
            percent: 0,
            load: 0,
            procs: []
        })
    property var memory: ({
            used_bytes: 0,
            total_bytes: 1,
            swap_used_bytes: 0,
            swap_total_bytes: 0,
            procs: []
        })
    property var gpu: []
    property var net: []
    property var disk: []

    onPopupOpenChanged: sendRequest()
    onPanelOpenChanged: sendRequest()
    onActiveTabChanged: sendRequest()
    onPullRateMsChanged: {
        proc.write("interval " + pullRateMs + "\n");
        _save();
    }
    onProcLimitChanged: {
        sendRequest();
        _save();
    }
    onFilterZeroChanged: {
        sendRequest();
        _save();
    }

    function _save() {
        saveProc.command = ["sh", "-c", "mkdir -p '" + _configDir + "' && printf '%s' '{\"pullRateMs\":" + pullRateMs + ",\"procLimit\":" + procLimit + ",\"filterZero\":" + (filterZero ? "true" : "false") + "}' > '" + _configPath + "'"];
        saveProc.running = true;
    }

    JsonAdapter {
        id: sysmonData
        property int pullRateMs: 1000
        property int procLimit: 10
        property bool filterZero: true
    }

    FileView {
        path: root._configPath
        watchChanges: true
        adapter: sysmonData
        onFileChanged: reload()
    }

    Process {
        id: saveProc
        running: false
    }

    function sendRequest() {
        var tokens = ["cpu"];
        if (popupOpen || panelOpen) {
            if (activeTab === 0) {
                tokens.push("procs");
                if (filterZero)
                    tokens.push("nozero");
                tokens.push("limit", String(procLimit));
            }
            if (activeTab === 1) {
                tokens.push("mem", "procs");
                if (filterZero)
                    tokens.push("nozero");
                tokens.push("limit", String(procLimit));
            }
            if (activeTab === 2) {
                tokens.push("gpu", "procs");
                if (filterZero)
                    tokens.push("nozero");
                tokens.push("limit", String(procLimit));
            }
            if (activeTab === 3)
                tokens.push("net");
            if (activeTab === 4)
                tokens.push("disk");
        }
        proc.write(tokens.join(" ") + "\n");
    }

    Process {
        id: proc
        running: true
        stdinEnabled: true
        command: ["athroisma"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var s = JSON.parse(data);
                    if (s.cpu !== undefined)
                        root.cpu = s.cpu;
                    if (s.memory !== undefined)
                        root.memory = s.memory;
                    if (s.gpu !== undefined)
                        root.gpu = s.gpu;
                    if (s.net !== undefined)
                        root.net = s.net;
                    if (s.disk !== undefined)
                        root.disk = s.disk;
                } catch (_) {}
            }
        }
    }
}
