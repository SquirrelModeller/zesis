pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/skinstate.json"

    property string material: skinData.material

    function setMaterial(mat) {
        root._save(mat);
    }

    function _save(mat) {
        skinData.material = mat;
        skinFile.writeAdapter();
    }

    JsonAdapter {
        id: skinData
        property string material: "flat"
    }

    FileView {
        id: skinFile
        path: root._configPath
        watchChanges: true
        printErrors: false
        adapter: skinData
        onFileChanged: reload()
    }
}
