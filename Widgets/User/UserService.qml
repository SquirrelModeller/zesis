pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/user.json"

    property string name: userData.name
    property string avatarPath: userData.avatarPath

    function setName(n) {
        _write(n, root.avatarPath);
    }

    function setAvatarPath(p) {
        _write(root.name, p);
    }

    function _write(n, p) {
        writeProc.command = ["sh", "-c", "mkdir -p '" + root._configDir + "' && " + "printf '%s' '{\"name\":\"" + n + "\",\"avatarPath\":\"" + p + "\"}' > '" + root._configPath + "'"];
        writeProc.running = true;
    }

    JsonAdapter {
        id: userData
        property string name: ""
        property string avatarPath: ""
    }

    FileView {
        path: root._configPath
        watchChanges: true
        adapter: userData
        onFileChanged: reload()
    }

    Process {
        id: writeProc
        running: false
    }
}
