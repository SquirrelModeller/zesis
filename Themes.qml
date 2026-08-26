pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

// Named, portable snapshots of a full theme - colors AND, optionally, the
// wallpaper(s) that go with them. Saving a theme captures whatever colors
// are effectively showing right now (matugen's own generation for the
// current wallpaper, or a hand-tweaked override, doesn't matter which) plus
// ThemeState's current wallpaper assignment: either the single global
// wallpaper, or a per-monitor split (ThemeState.perMonitorWallpaper) if
// that's what was last applied.
//
// Applying a theme replays the colors through ColorOverrides.set() (lands in
// whichever scope - per-wallpaper or global - is currently active there) and,
// if the theme has a wallpaper, re-applies it per currently connected
// monitor: a monitor with an explicit entry gets that path via
// ThemeState.applyToMonitor(), any other connected monitor gets `fallback`
// (the single path if the theme was saved with one, otherwise whatever was
// last applied globally) - so a theme saved on a 3-monitor dock still
// applies cleanly when reconnected with just one.
//
// `pinned` marks a theme for the ThemeCycler's alt-tab-style quick switch
// (widgets/themecycler/) - only pinned themes that actually have a wallpaper
// show up there, since cycling into a color-only theme would leave whatever
// wallpaper was already showing looking mismatched.
Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/colorthemes.json"

    property var themes: [] // [{name, pinned, wallpaper: {all, byMonitor, fallback}, dark: {role: hex}, light: {role: hex}}]

    // Name of the last theme applied via apply()
    property string activeThemeName: ""

    function _indexOf(name) {
        for (var i = 0; i < root.themes.length; i++) {
            if (root.themes[i].name === name)
                return i;
        }
        return -1;
    }

    function exists(name) {
        return root._indexOf(name) >= 0;
    }

    function isDirty(name) {
        var idx = root._indexOf(name);
        if (idx < 0)
            return false;
        var entry = root.themes[idx];
        return !root._paletteMatches(entry.dark, Colors.darkPalette, "dark") || !root._paletteMatches(entry.light, Colors.lightPalette, "light");
    }

    function _paletteMatches(saved, live, palette) {
        for (var i = 0; i < ColorOverrides.paletteRoles.length; i++) {
            var id = ColorOverrides.paletteRoles[i].id;
            if ((saved[id] || "").toLowerCase() !== (live[id] || "").toLowerCase())
                return false;
        }
        var savedBar = saved.bar || "";
        var liveBar = ColorOverrides.get(palette, "bar");
        return savedBar.toLowerCase() === liveBar.toLowerCase();
    }

    readonly property bool activeIsDirty: ColorOverrides.enabled && root.activeThemeName !== "" && root.isDirty(root.activeThemeName)

    function hasWallpaper(entry) {
        var wp = entry && entry.wallpaper;
        return !!(wp && (wp.all || wp.fallback || Object.keys(wp.byMonitor || {}).length > 0));
    }

    // Single representative wallpaper path for an entry, for previews
    function primaryWallpaper(entry) {
        var wp = entry && entry.wallpaper;
        if (!wp)
            return "";
        return wp.all || wp.fallback || Object.values(wp.byMonitor || {})[0] || "";
    }

    readonly property var pinned: root.themes.filter(t => t.pinned && root.hasWallpaper(t))

    // Snapshots the colors and wallpaper currently in effect under `name`,
    // overwriting any theme already saved under that exact name. `pinned`
    // defaults to whatever it already was (false for a brand new theme).
    function save(name) {
        var trimmed = (name || "").trim();
        if (trimmed.length === 0)
            return;
        var idx = root._indexOf(trimmed);
        var entry = {
            name: trimmed,
            pinned: idx >= 0 ? !!root.themes[idx].pinned : false,
            wallpaper: root._snapshotWallpaper(),
            dark: root._snapshotColors("dark"),
            light: root._snapshotColors("light")
        };
        var list = root.themes.slice();
        if (idx >= 0)
            list[idx] = entry;
        else
            list.push(entry);
        root._save(list);
    }

    function _snapshotWallpaper() {
        var perMonitor = ThemeState.perMonitorWallpaper || ({});
        var hasPerMonitor = Object.keys(perMonitor).length > 0;
        return {
            all: hasPerMonitor ? "" : ThemeState.lastWallpaper,
            byMonitor: hasPerMonitor ? JSON.parse(JSON.stringify(perMonitor)) : ({}),
            fallback: ThemeState.lastWallpaper
        };
    }

    function _snapshotColors(palette) {
        var src = palette === "dark" ? Colors.darkPalette : Colors.lightPalette;
        var out = {};
        for (var i = 0; i < ColorOverrides.paletteRoles.length; i++) {
            var id = ColorOverrides.paletteRoles[i].id;
            out[id] = src[id];
        }
        var bar = ColorOverrides.get(palette, "bar");
        if (bar.length > 0)
            out.bar = bar;
        return out;
    }

    // Renames in place, keeping pinned/wallpaper/colors untouched. No-ops
    // (returns false) on an empty name, no real change, or a collision with
    // another saved theme.
    function rename(oldName, newName) {
        var trimmed = (newName || "").trim();
        if (trimmed.length === 0 || trimmed === oldName)
            return false;
        var idx = root._indexOf(oldName);
        if (idx < 0 || root.exists(trimmed))
            return false;
        var list = root.themes.slice();
        list[idx] = Object.assign({}, list[idx], {
            name: trimmed
        });
        if (root.activeThemeName === oldName)
            root.activeThemeName = trimmed;
        root._save(list);
        return true;
    }

    function togglePinned(name) {
        var idx = root._indexOf(name);
        if (idx < 0)
            return;
        var list = root.themes.slice();
        list[idx] = Object.assign({}, list[idx], {
            pinned: !list[idx].pinned
        });
        root._save(list);
    }

    // Writes every role of the theme into ColorOverrides (whatever scope is
    // currently active there), then re-applies its wallpaper per connected
    // monitor if it has one.
    function apply(name) {
        var idx = root._indexOf(name);
        if (idx < 0)
            return;
        var entry = root.themes[idx];
        root._applyPalette("dark", entry.dark);
        root._applyPalette("light", entry.light);
        if (root.hasWallpaper(entry))
            root._applyWallpaper(entry.wallpaper);
        root.activeThemeName = name;
        root._save(root.themes);
    }

    function _applyPalette(palette, roleMap) {
        for (var role in roleMap)
            ColorOverrides.set(palette, role, roleMap[role]);
    }

    // No per-monitor entries at all: one path for everything, simplest case -
    // ThemeState.apply() sets it globally (and recolors, since this is the
    // theme's own wallpaper). Otherwise: each connected monitor gets its own
    // entry if it has one, falling back to `fallback`/`all` so a monitor the
    // theme never saw (different dock, different day) still gets a sane
    // wallpaper instead of being left untouched.
    function _applyWallpaper(wp) {
        var screens = Quickshell.screens;
        if (screens.length === 0)
            return;
        var byMonitor = wp.byMonitor || {};
        if (Object.keys(byMonitor).length === 0) {
            var single = wp.all || wp.fallback;
            if (single)
                ThemeState.apply(single);
            return;
        }
        for (var i = 0; i < screens.length; i++) {
            var mon = screens[i].name;
            var path = byMonitor[mon] || wp.fallback || wp.all;
            if (path)
                ThemeState.applyToMonitor(path, mon);
        }
    }

    function remove(name) {
        var idx = root._indexOf(name);
        if (idx < 0)
            return;
        var list = root.themes.slice();
        list.splice(idx, 1);
        if (root.activeThemeName === name)
            root.activeThemeName = "";
        root._save(list);
    }

    // Adapter writes below are our own, not an external file change - guard
    // _adopt() (wired to the adapter's changed signals for that external
    // case) so it doesn't re-derive root state from a write still in
    // progress across these two property assignments.
    property bool _writingFromRoot: false

    function _save(list) {
        root.themes = list;
        root._writingFromRoot = true;
        themeData.themes = list;
        themeData.activeThemeName = root.activeThemeName;
        root._writingFromRoot = false;
        themeFile.writeAdapter();
    }

    // Migrates pre-wallpaper theme entries (just {name, dark, light}) the
    // first time they're loaded, so themes saved before this feature existed
    // don't vanish - they just show up with no wallpaper (unpinned, colors
    // only) until saved again.
    function _adopt() {
        if (root._writingFromRoot)
            return;
        var raw = themeData.themes ? JSON.parse(JSON.stringify(themeData.themes)) : [];

        // background and on_background are identical to surface and on_surface.
        // We will no longer use background or on_background.
        var changed = false;
        var migrated = raw.map(t => {
            var dark = t.dark || {};
            var light = t.light || {};
            changed = root._renameRole(dark, "background", "surface") || changed;
            changed = root._renameRole(dark, "on_background", "on_surface") || changed;
            changed = root._renameRole(light, "background", "surface") || changed;
            changed = root._renameRole(light, "on_background", "on_surface") || changed;
            return {
                name: t.name,
                pinned: !!t.pinned,
                wallpaper: t.wallpaper || {
                    all: "",
                    byMonitor: {},
                    fallback: ""
                },
                dark: dark,
                light: light
            };
        });
        root.themes = migrated;
        root.activeThemeName = themeData.activeThemeName || "";
        if (changed)
            root._save(migrated);
    }

    function _renameRole(map, oldId, newId) {
        if (!map || map[oldId] === undefined)
            return false;
        if (map[newId] === undefined)
            map[newId] = map[oldId];
        delete map[oldId];
        return true;
    }

    JsonAdapter {
        id: themeData
        property var themes: []
        property string activeThemeName: ""
    }

    Connections {
        target: themeData
        function onThemesChanged() {
            root._adopt();
        }
        function onActiveThemeNameChanged() {
            root._adopt();
        }
    }

    FileView {
        id: themeFile
        path: root._configPath
        watchChanges: true
        adapter: themeData // qmllint disable missing-type
        onFileChanged: reload()
        onLoaded: root._adopt()
    }
}
