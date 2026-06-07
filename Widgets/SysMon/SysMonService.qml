// qmllint disable import
pragma Singleton
// qmllint enable import
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool popupOpen: false
    property real popupCenterX: 0
    property int activeTab: 0  // 0=CPU, 1=Memory, 2=GPU, 3=Net, 4=Disk

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
    onActiveTabChanged: sendRequest()

    function sendRequest() {
        var tokens = ["cpu"];
        if (popupOpen) {
            if (activeTab === 0)
                tokens.push("procs");
            if (activeTab === 1) {
                tokens.push("mem");
                tokens.push("procs");
            }
            if (activeTab === 2) {
                tokens.push("gpu");
                tokens.push("procs");
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
