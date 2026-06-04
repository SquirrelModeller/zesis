// qmllint disable import
pragma Singleton
// qmllint enable import
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Priority: ~/.cache/theme/quickshell/colors.json (wallust) > Palette.qml > hardcoded defaults
    readonly property string _themeDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/theme/quickshell"

    property bool _jsonLoaded: false
    property bool _paletteLoaded: false
    property color _palBg: "black"
    property color _palFg: "white"
    property color _palAccent: "white"

    readonly property bool _usePalette: !_jsonLoaded && _paletteLoaded

    property color bg: _usePalette ? _palBg : colorData.bg
    property color surface: _usePalette ? Qt.lighter(_palBg, 1.2) : colorData.surface
    property color surfaceHigh: _usePalette ? Qt.lighter(_palBg, 1.4) : colorData.surfaceHigh
    property color accent: _usePalette ? _palAccent : colorData.accent
    property color muted: _usePalette ? Qt.darker(_palAccent, 1.3) : colorData.muted
    property color text: _usePalette ? _palFg : colorData.text
    property color textDim: _usePalette ? withAlpha(_palFg, 0.6) : colorData.textDim
    property color barBg: _usePalette ? withAlpha(_palBg, 0.8) : colorData.barBg
    property color outline: _usePalette ? Qt.lighter(_palBg, 1.1) : colorData.outline

    function withAlpha(col, alpha) {
        var c = Qt.color(col);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }

    function _onPaletteLoaded() {
        var t = paletteView.text();
        var bgM = t.match(/property color bg:\s*"(#[0-9a-fA-F]+)"/);
        var fgM = t.match(/property color fg:\s*"(#[0-9a-fA-F]+)"/);
        var accentM = t.match(/property color accent:\s*"(#[0-9a-fA-F]+)"/);
        if (bgM && fgM && accentM) {
            _palBg = bgM[1];
            _palFg = fgM[1];
            _palAccent = accentM[1];
            _paletteLoaded = true;
        } else {
            _paletteLoaded = false;
        }
    }

    FileView {
        id: paletteView
        path: root._themeDir + "/Palette.qml"
        watchChanges: true
        onLoaded: root._onPaletteLoaded()
        onLoadFailed: root._paletteLoaded = false
        onFileChanged: reload()
    }

    JsonAdapter {
        id: colorData

        property color bg: "#120d08"
        property color surface: "#1e1510"
        property color surfaceHigh: "#2a1e15"
        property color accent: "#FFB97C"
        property color muted: "#C59265"
        property color text: "#F5E6CE"
        property color textDim: "#9CA3AF"
        property color barBg: "#CC1C1C1C"
        property color outline: "#3d2c1e"
    }

    FileView {
        id: jsonView
        path: root._themeDir + "/colors.json"
        watchChanges: true
        adapter: colorData // qmllint disable missing-type
        onLoaded: root._jsonLoaded = true
        onFileChanged: reload()
        onLoadFailed: root._jsonLoaded = false
    }
}
