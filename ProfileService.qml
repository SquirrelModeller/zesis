pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

// Named snapshots of the whole visual setup (WELCOME TO THE RICE FIELDS)
Singleton {
    id: root

    readonly property string _cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _themeColorsPath: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/theme/zesis/colors.json"
    readonly property string _profilesDir: _cacheDir + "/profiles"
    readonly property string _indexPath: _cacheDir + "/profiles.json"

    // These can break very easily if we ever switch their names. So we should
    // probably include this in the CI pipeline whenever one is made.
    readonly property var _layoutFiles: ["barconfig.json", "desktop-widgets.json", "workspaceindicator.json", "clocksettings.json", "cava-widget-settings.json", "globe2d-widget.json", "globe3d.json", "assemblytestsettings.json", "uiscale.json", "skinstate.json", "appswitcher.json"]

    readonly property var _themeFiles: [
        {
            src: _cacheDir + "/state.json",
            name: "state.json"
        },
        {
            src: _cacheDir + "/coloroverrides.json",
            name: "coloroverrides.json"
        },
        {
            src: _themeColorsPath,
            name: "colors.json"
        }
    ]

    // [{slug, name, created, updated, includesTheme, wallpaper}]
    property var profiles: []
    property string activeSlug: ""
    // Things can go wrong, disable buttons
    property bool busy: false

    function _slugify(name) {
        return (name || "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
    }

    function _indexOfSlug(slug) {
        for (var i = 0; i < root.profiles.length; i++) {
            if (root.profiles[i].slug === slug)
                return i;
        }
        return -1;
    }

    function exists(name) {
        var s = root._slugify(name);
        return s.length > 0 && root._indexOfSlug(s) >= 0;
    }

    function entryForSlug(slug) {
        var i = root._indexOfSlug(slug);
        return i >= 0 ? root.profiles[i] : null;
    }

    function _sh(str) {
        return "'" + String(str).replace(/'/g, "'\\''") + "'";
    }

    function _copyLines(profileDir, includeTheme, restore) {
        var lines = [];
        for (var i = 0; i < root._layoutFiles.length; i++) {
            var live = root._cacheDir + "/" + root._layoutFiles[i];
            var stored = profileDir + "/" + root._layoutFiles[i];
            var from = restore ? stored : live;
            var to = restore ? live : stored;
            lines.push("[ -f " + root._sh(from) + " ] && cp -f " + root._sh(from) + " " + root._sh(to) + " || true");
        }
        if (includeTheme) {
            lines.push("mkdir -p " + root._sh(profileDir + "/theme"));
            lines.push("mkdir -p " + root._sh(root._themeColorsPath.substring(0, root._themeColorsPath.lastIndexOf("/"))));
            for (var j = 0; j < root._themeFiles.length; j++) {
                var tf = root._themeFiles[j];
                var storedT = profileDir + "/theme/" + tf.name;
                var fromT = restore ? storedT : tf.src;
                var toT = restore ? tf.src : storedT;
                lines.push("[ -f " + root._sh(fromT) + " ] && cp -f " + root._sh(fromT) + " " + root._sh(toT) + " || true");
            }
        } else if (!restore) {
            lines.push("rm -rf " + root._sh(profileDir + "/theme"));
        }
        return lines;
    }

    // Snapshots everything on disk right now under `name`
    // This also means any preferences on hiden stuff...
    function save(name, includeTheme) {
        if (root.busy)
            return;
        var trimmed = (name || "").trim();
        var slug = root._slugify(trimmed);
        if (slug.length === 0)
            return;
        var profileDir = root._profilesDir + "/" + slug;
        var existing = root.entryForSlug(slug);
        var now = Date.now();
        var pending = {
            slug: slug,
            name: trimmed,
            created: existing ? existing.created : now,
            updated: now,
            includesTheme: !!includeTheme,
            wallpaper: includeTheme ? (ThemeState.lastWallpaper || "") : ""
        };

        var script = "set -e; mkdir -p " + root._sh(profileDir) + "; " + root._copyLines(profileDir, !!includeTheme, false).join("; ");
        root._run("save", script, function () {
            var list = root.profiles.slice();
            var at = root._indexOfSlug(slug);
            if (at >= 0)
                list[at] = pending;
            else
                list.push(pending);
            root._saveIndex(list);
        });
    }

    function update(slug) {
        var e = root.entryForSlug(slug);
        if (e)
            root.save(e.name, e.includesTheme);
    }

    // Apply files from save, andd also wallpaper+mutagen if they are available
    function apply(slug) {
        if (root.busy)
            return;
        var e = root.entryForSlug(slug);
        if (!e)
            return;
        var profileDir = root._profilesDir + "/" + slug;
        var script = root._copyLines(profileDir, !!e.includesTheme, true).join("; ");
        root._run("apply", script, function () {
            root.activeSlug = slug;
            if (e.includesTheme)
                ThemeState.reloadAndReapply();
        });
    }

    function rename(slug, newName) {
        var trimmed = (newName || "").trim();
        var idx = root._indexOfSlug(slug);
        if (trimmed.length === 0 || idx < 0)
            return false;
        var list = root.profiles.slice();
        list[idx] = Object.assign({}, list[idx], {
            name: trimmed
        });
        root._saveIndex(list);
        return true;
    }

    function remove(slug) {
        if (root.busy)
            return;
        if (root._indexOfSlug(slug) < 0)
            return;
        var profileDir = root._profilesDir + "/" + slug;
        root._run("remove", "rm -rf " + root._sh(profileDir), function () {
            var at = root._indexOfSlug(slug);
            if (at < 0)
                return;
            var list = root.profiles.slice();
            list.splice(at, 1);
            if (root.activeSlug === slug)
                root.activeSlug = "";
            root._saveIndex(list);
        });
    }

    property var _onDone: null
    property string lastError: ""

    function _run(op, script, onDone) {
        root.busy = true;
        root.lastError = "";
        root._onDone = onDone;
        proc.command = ["bash", "-c", script];
        proc.running = true;
    }

    Process {
        id: proc
        stderr: StdioCollector {
            id: procErr
        }
        onExited: code => {
            root.busy = false;
            var cb = root._onDone;
            root._onDone = null;
            if (code === 0) {
                if (cb)
                    cb();
            } else {
                root.lastError = (procErr.text || "").trim() || ("exit " + code);
            }
        }
    }

    function _saveIndex(list) {
        root.profiles = list;
        indexFile.setText(JSON.stringify(list, null, 2));
    }

    function _loadIndex(text) {
        if (!text)
            return;
        try {
            var arr = JSON.parse(text);
            if (Array.isArray(arr) && JSON.stringify(arr) !== JSON.stringify(root.profiles))
                root.profiles = arr;
        } catch (_) {}
    }

    Process {
        command: ["mkdir", "-p", root._profilesDir]
        running: true
    }

    FileView {
        id: indexFile
        path: root._indexPath
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root._loadIndex(indexFile.text())
    }

    Component.onCompleted: indexFile.text()
}
