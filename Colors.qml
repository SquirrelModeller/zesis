pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _themeDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/theme/zesis"

    readonly property var _p: ThemeState.palette === "dark" ? colorData.colors.dark : colorData.colors.light
    readonly property var darkPalette: colorData.colors.dark
    readonly property var lightPalette: colorData.colors.light

    // Named tokens, mapped from MD3 semantic roles
    property color bg: _p.background
    property color surface: _p.surface_container
    property color surfaceHigh: _p.surface_container_high
    property color outline: _p.outline_variant
    property color accent: _p.primary
    property color onAccent: _p.on_primary
    property color muted: _p.on_surface_variant
    property color text: _p.on_background
    property color textDim: _p.on_surface_variant
    property color barBg: withAlpha(bg, 0.85)

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
                property string background: "#120d08"
                property string surface_container: "#1e1510"
                property string surface_container_high: "#2a1e15"
                property string outline_variant: "#3d2c1e"
                property string primary: "#FFB97C"
                property string primary_fixed_dim: "#FFB97C"
                property string on_primary: "#1A100A"
                property string primary_container: "#8B6240"
                property string on_background: "#F5E6CE"
                property string on_surface_variant: "#A09080"
            }
            property JsonObject light: JsonObject {
                property string background: "#fdf6ee"
                property string surface_container: "#f0e8de"
                property string surface_container_high: "#e3d9cc"
                property string outline_variant: "#c5b8a8"
                property string primary: "#8B5A2B"
                property string primary_fixed_dim: "#FFB97C"
                property string on_primary: "#FFFFFF"
                property string primary_container: "#d4aa80"
                property string on_background: "#1a1008"
                property string on_surface_variant: "#4a3828"
            }
        }
    }
}
