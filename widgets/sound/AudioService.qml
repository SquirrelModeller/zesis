pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real vol: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/sound.json"

    readonly property var positions: ["top", "left", "right", "bottom"]

    property bool osdEnabled: true
    property string osdPosition: "top"

    function _validPosition(value) {
        return root.positions.indexOf(value) === -1 ? "top" : value;
    }

    function setOsdEnabled(value) {
        root.osdEnabled = value;
        root._save();
    }

    function setOsdPosition(value) {
        root.osdPosition = root._validPosition(value);
        root._save();
    }

    function _save() {
        soundData.osdEnabled = root.osdEnabled;
        soundData.osdPosition = root.osdPosition;
        soundFile.writeAdapter();
    }

    JsonAdapter {
        id: soundData
        property bool osdEnabled: true
        property string osdPosition: "top"
    }

    FileView {
        id: soundFile
        path: root._configPath
        watchChanges: true
        adapter: soundData // qmllint disable missing-type
        onLoaded: {
            root.osdEnabled = soundData.osdEnabled;
            root.osdPosition = root._validPosition(soundData.osdPosition);
        }
        onFileChanged: reload()
    }

    PwObjectTracker {
        objects: [root.sink]
    }
}
