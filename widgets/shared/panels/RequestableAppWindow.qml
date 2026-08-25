pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../"

// Top-level app window
Loader {
    id: root

    required property RequestableWindowState windowService
    required property Component content
    property string windowTitle: ""
    property size minimumWindowSize: Qt.size(880, 560)
    property int baseWidth: 1200
    property int baseHeight: 760

    active: false

    sourceComponent: FloatingWindow {
        id: floatingWin
        title: root.windowTitle
        minimumSize: root.minimumWindowSize
        implicitWidth: Math.round(root.baseWidth * UIScale.value)
        implicitHeight: Math.round(root.baseHeight * UIScale.value)
        color: "transparent"
        visible: true

        // Can never be too safe
        onClosed: root.active = false
        onVisibleChanged: if (!visible)
            root.active = false

        Loader {
            id: contentLoader
            anchors.fill: parent
            sourceComponent: root.content
            onLoaded: item.forceActiveFocus()
        }
    }

    Binding {
        target: root.windowService
        property: "windowOpen"
        value: root.active
    }

    Connections {
        target: root.windowService
        function onRequestSeqChanged() {
            root.active = true;
        }
        function onToggleSeqChanged() {
            root.active = !root.active;
        }
        function onCloseSeqChanged() {
            root.active = false;
        }
    }
}
