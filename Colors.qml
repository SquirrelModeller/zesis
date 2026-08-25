pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _themeDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/theme/zesis"

    // Generated theme with the user's per-role overrides applied on top
    readonly property var darkPalette: ColorOverrides.enabled ? _merge(colorData.colors.dark, ColorOverrides.dark) : colorData.colors.dark
    readonly property var lightPalette: ColorOverrides.enabled ? _merge(colorData.colors.light, ColorOverrides.light) : colorData.colors.light
    readonly property var _p: ThemeState.palette === "dark" ? darkPalette : lightPalette

    // The wallpaper's matugen output
    readonly property var rawDarkPalette: colorData.colors.dark
    readonly property var rawLightPalette: colorData.colors.light

    function _merge(base, overrides) {
        var roles = ColorOverrides.paletteRoles;
        var out = {};
        for (var i = 0; i < roles.length; i++) {
            var key = roles[i].id;
            var ov = overrides ? overrides[key] : "";
            out[key] = (ov && ColorOverrides.isValid(ov)) ? ov : base[key];
        }
        return out;
    }

    // Named tokens, mapped from MD3 semantic roles
    property color bg: _p.surface
    property color surface: _p.surface_container
    property color surfaceHigh: _p.surface_container_high
    property color surfaceHighest: _p.surface_container_highest
    property color outline: _p.outline_variant
    property color accent: _p.primary
    property color onAccent: _p.on_primary
    property color muted: _p.on_surface_variant
    property color text: _p.on_surface
    property color textDim: _p.on_surface_variant
    property color error: _p.error
    property color onError: _p.on_error
    readonly property string _barOverride: ColorOverrides.enabled ? ColorOverrides.get(ThemeState.palette, "bar") : ""
    property color barBg: _barOverride.length > 0 ? Qt.color(_barOverride) : bg

    function withAlpha(col, alpha) {
        var c = Qt.color(col);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }

    FileView {
        path: root._themeDir + "/colors.json"
        watchChanges: true
        adapter: colorData // qmllint disable missing-type
        onFileChanged: reload()
    }

    JsonAdapter {
        id: colorData
        property JsonObject colors: JsonObject {
            property JsonObject dark: JsonObject {
                property string surface: "#120d08"
                property string surface_dim: "#120d08"
                property string surface_bright: "#413732"
                property string surface_container_lowest: "#0c0805"
                property string surface_container_low: "#1a120d"
                property string surface_container: "#1e1510"
                property string surface_container_high: "#2a1e15"
                property string surface_container_highest: "#352a1f"
                property string surface_variant: "#52443c"
                property string on_surface: "#F5E6CE"
                property string on_surface_variant: "#A09080"
                property string outline: "#9f8d84"
                property string outline_variant: "#3d2c1e"
                property string primary: "#FFB97C"
                property string primary_container: "#8B6240"
                property string primary_fixed: "#ffdbca"
                property string primary_fixed_dim: "#FFB97C"
                property string on_primary: "#1A100A"
                property string on_primary_container: "#ffdbca"
                property string secondary: "#e6beab"
                property string secondary_container: "#5c4132"
                property string on_secondary: "#432b1d"
                property string on_secondary_container: "#ffdbca"
                property string tertiary: "#cec991"
                property string tertiary_container: "#4b481d"
                property string on_tertiary: "#343208"
                property string on_tertiary_container: "#eae5ab"
                property string error: "#ffb4ab"
                property string error_container: "#93000a"
                property string on_error: "#690005"
                property string on_error_container: "#ffdad6"
                property string inverse_surface: "#F5E6CE"
                property string inverse_on_surface: "#382e29"
                property string inverse_primary: "#8c4e29"
                property string scrim: "#000000"
                property string shadow: "#000000"
            }
            property JsonObject light: JsonObject {
                property string surface: "#fdf6ee"
                property string surface_dim: "#e8d7cf"
                property string surface_bright: "#fdf6ee"
                property string surface_container_lowest: "#ffffff"
                property string surface_container_low: "#fff1eb"
                property string surface_container: "#f0e8de"
                property string surface_container_high: "#e3d9cc"
                property string surface_container_highest: "#d6c8b6"
                property string surface_variant: "#f4ded4"
                property string on_surface: "#1a1008"
                property string on_surface_variant: "#4a3828"
                property string outline: "#85746b"
                property string outline_variant: "#c5b8a8"
                property string primary: "#8B5A2B"
                property string primary_container: "#d4aa80"
                property string primary_fixed: "#ffdbca"
                property string primary_fixed_dim: "#FFB97C"
                property string on_primary: "#FFFFFF"
                property string on_primary_container: "#331200"
                property string secondary: "#765848"
                property string secondary_container: "#ffdbca"
                property string on_secondary: "#ffffff"
                property string on_secondary_container: "#2b160a"
                property string tertiary: "#636032"
                property string tertiary_container: "#eae5ab"
                property string on_tertiary: "#ffffff"
                property string on_tertiary_container: "#1e1c00"
                property string error: "#ba1a1a"
                property string error_container: "#ffdad6"
                property string on_error: "#ffffff"
                property string on_error_container: "#410002"
                property string inverse_surface: "#382e29"
                property string inverse_on_surface: "#ffede5"
                property string inverse_primary: "#FFB97C"
                property string scrim: "#000000"
                property string shadow: "#000000"
            }
        }
    }
}
