pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../../../"

// Search index, build by opening and scanning source for I18n.t() calls
// (text/navLabel/label).
Item {
    id: root

    required property var files // ["foo/Bar.qml", ...] relative to widgets/

    property bool ready: false
    property var entries: [] // [{key, file}]

    readonly property var _includedProps: ["text", "label", "navLabel"]
    readonly property var _excludedProps: ["breadcrumb", "title", "placeholder"]

    property int _loadedCount: 0
    property var _partial: ({})

    function labelFor(entry) {
        return I18n.t(entry.key);
    }

    Component.onCompleted: {
        if (root.files.length === 0)
            root.ready = true;
    }

    property var _activeFiles: root.files

    Instantiator {
        model: root._activeFiles
        delegate: FileView {
            id: scanView
            required property string modelData
            path: Quickshell.shellDir + "/widgets/" + modelData
            watchChanges: false

            onLoaded: {
                root._partial[modelData] = root._extract(scanView.text());
                root._advance();
            }
            onLoadFailed: {
                root._partial[modelData] = [];
                root._advance();
            }
        }
    }

    function _advance() {
        root._loadedCount++;
        if (root._loadedCount === root.files.length)
            root._finish();
    }

    function _extract(source) {
        var re = /\b(\w+)\s*:\s*I18n\.t\(\s*["']([\w.]+)["']/g;
        var found = [];
        var m;
        while ((m = re.exec(source)) !== null) {
            var prop = m[1];
            var key = m[2];
            if (root._excludedProps.indexOf(prop) !== -1)
                continue;
            if (root._includedProps.indexOf(prop) === -1)
                continue;
            // We don't want explanations indexed
            if (/(Hint|Description)$/.test(key))
                continue;
            found.push({
                key: key
            });
        }
        return found;
    }

    function _finish() {
        var all = [];
        var seen = {};
        for (var relPath in root._partial) {
            var found = root._partial[relPath];
            for (var i = 0; i < found.length; i++) {
                var dedupeKey = relPath + "::" + found[i].key;
                if (seen[dedupeKey])
                    continue;
                seen[dedupeKey] = true;
                all.push({
                    key: found[i].key,
                    file: relPath
                });
            }
        }
        root.entries = all;
        root.ready = true;
        root._activeFiles = [];
    }
}
