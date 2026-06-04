// qmllint disable import
pragma Singleton
// qmllint enable import
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _themeDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/theme/quickshell"

    property color bg: colorData.bg
    property color text: colorData.text
    property color accent: colorData.accent

    // Perceptual luminance of bg, drives all light/dark adaptations
    readonly property real _luma: 0.2126 * bg.r + 0.7152 * bg.g + 0.0722 * bg.b
    readonly property bool _isDark: _luma < 0.5

    // Derived colors: computed to stay coherent in any palette
    property color surface: _isDark ? Qt.rgba(Math.min(1, bg.r + 0.10), Math.min(1, bg.g + 0.10), Math.min(1, bg.b + 0.10), 1) : Qt.darker(bg, 1.08)
    property color surfaceHigh: _isDark ? Qt.rgba(Math.min(1, bg.r + 0.22), Math.min(1, bg.g + 0.22), Math.min(1, bg.b + 0.22), 1) : Qt.darker(bg, 1.20)
    property color outline: _isDark ? Qt.rgba(Math.min(1, bg.r + 0.06), Math.min(1, bg.g + 0.06), Math.min(1, bg.b + 0.06), 1) : Qt.darker(bg, 1.06)
    property color muted: Qt.darker(accent, 1.3)
    property color textDim: withAlpha(text, 0.50)
    property color barBg: withAlpha(bg, 0.85)

    function withAlpha(col, alpha) {
        var c = Qt.color(col);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }

    JsonAdapter {
        id: colorData
        property color bg: "#120d08"
        property color text: "#F5E6CE"
        property color accent: "#FFB97C"
    }

    FileView {
        id: jsonView
        path: root._themeDir + "/colors.json"
        watchChanges: true
        adapter: colorData // qmllint disable missing-type
        onFileChanged: reload()
    }
}
