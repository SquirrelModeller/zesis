pragma Singleton
import QtQuick
import Quickshell

// Animation timing tokens, single source of truth for all durations.
// Use these instead of magic numbers. Pairs with Colors.qml (color) and UIScale.qml (space).
//
// drag   60   Direct-manipulation feedback (slider fill tracks input)
// micro  80   Icon/state flips, tiny reactions
// fast   150  Color transitions, hover feedback
// medium 200  Size and position changes
// slow   300  Overlay and panel transitions
// morph  420  Expand/contract layout morphs

Singleton {
    readonly property int drag: 60
    readonly property int micro: 80
    readonly property int fast: 150
    readonly property int medium: 200
    readonly property int slow: 300
    readonly property int morph: 420
}
