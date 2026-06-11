pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../Music"
import "../Notifications"
import "../Sound"
import "../Config"
import "../../"

Item {
    id: root
    signal widgetRequested(int index, string title)

    property int selectedRow: -1
    property int selectedCol: -1
    readonly property bool anySelected: selectedRow !== -1

    readonly property real pad: 20
    readonly property real colGap: 10
    readonly property real rowGap: 10
    readonly property real collapsedH: 52
    readonly property real collapsedW: (root.width - 2 * pad - colGap) / 2
    readonly property real expandedW: root.width - 2 * pad
    readonly property real expandedH: contentArea.height

    // Each entry: [label, icon codepoint (Material Icons), widgetIndex]
    readonly property var layout: [[["Music", "", 0], ["Notifs", "", 1]], [["Sound", "", 2], ["Scale", "", 3]]]

    readonly property var widgetComponents: [musicComp, notifComp, soundComp, configComp]
    Component {
        id: musicComp
        MusicController {}
    }
    Component {
        id: notifComp
        NotifHistoryPopup {}
    }
    Component {
        id: soundComp
        SoundPopup {}
    }
    Component {
        id: configComp
        ConfigPopup {}
    }

    // Header
    RowLayout {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: UIScale.spacingMd
        anchors.leftMargin: UIScale.spacingMd
        anchors.rightMargin: UIScale.spacingMd
        height: 40
        opacity: root.anySelected ? 0 : 1
        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }

        Text {
            text: "Widget Home"
            color: Colors.text
            font.bold: true
            font.pointSize: UIScale.fontLg
        }

        Item {
            Layout.fillWidth: true
        }

        Item {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32

            HoverHandler {
                id: xHover
            }

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: xHover.hovered ? Colors.accent : Colors.muted
                font.pixelSize: xHover.hovered ? 20 : 16
                scale: xHover.hovered ? 1.15 : 1.0

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
                Behavior on font.pixelSize {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }
            }

            TapHandler {
                cursorShape: Qt.PointingHandCursor
                onTapped: WidgetHomeService.open = false
            }
        }
    }

    Rectangle {
        id: separator
        anchors.top: header.bottom
        anchors.topMargin: UIScale.spacingMd
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: UIScale.spacingMd
        anchors.rightMargin: UIScale.spacingMd
        height: 1
        color: Colors.withAlpha(Colors.accent, 0.12)
        opacity: root.anySelected ? 0 : 1
        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }
    }

    // Measures available height, expandedH binds to this
    Item {
        id: contentArea
        anchors.top: separator.bottom
        anchors.topMargin: UIScale.spacingMd
        anchors.bottom: parent.bottom
        anchors.bottomMargin: UIScale.spacingMd
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.expandedW

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.anySelected ? 0 : root.rowGap

            Behavior on spacing {
                NumberAnimation {
                    duration: 420
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.38, 1.21, 0.22, 1.00, 1, 1]
                }
            }

            Repeater {
                model: root.layout

                delegate: Item {
                    id: rowItem
                    required property var modelData
                    required property int index

                    readonly property bool isThisRowSelected: root.selectedRow === rowItem.index

                    width: root.expandedW
                    height: isThisRowSelected ? root.expandedH : (root.anySelected ? 0 : root.collapsedH)
                    opacity: root.anySelected && !isThisRowSelected ? 0 : 1

                    Behavior on height {
                        NumberAnimation {
                            duration: 420
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.38, 1.21, 0.22, 1.00, 1, 1]
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: root.anySelected ? 0 : root.colGap

                        Behavior on spacing {
                            NumberAnimation {
                                duration: 420
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: [0.38, 1.21, 0.22, 1.00, 1, 1]
                            }
                        }

                        Repeater {
                            model: rowItem.modelData

                            delegate: Item {
                                id: btn
                                required property var modelData
                                required property int index

                                readonly property string label: btn.modelData[0]
                                readonly property string icon: btn.modelData[1]
                                readonly property int widgetIndex: btn.modelData[2]
                                readonly property bool isSelected: root.selectedRow === rowItem.index && root.selectedCol === btn.index
                                readonly property bool siblingSelected: rowItem.isThisRowSelected && !isSelected

                                width: isSelected ? root.expandedW : (root.anySelected ? 0 : root.collapsedW)
                                height: isSelected ? root.expandedH : root.collapsedH
                                opacity: siblingSelected ? 0 : 1
                                clip: true

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 420
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: [0.38, 1.21, 0.22, 1.00, 1, 1]
                                    }
                                }
                                Behavior on height {
                                    NumberAnimation {
                                        duration: 420
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: [0.38, 1.21, 0.22, 1.00, 1, 1]
                                    }
                                }
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 150
                                    }
                                }

                                Rectangle {
                                    id: pill
                                    anchors.centerIn: parent
                                    width: btn.isSelected ? root.expandedW : (root.anySelected ? 0 : root.collapsedW)
                                    height: btn.isSelected ? root.expandedH : (root.anySelected ? 0 : root.collapsedH)
                                    radius: btn.isSelected ? 0 : root.collapsedH / 2
                                    // bg when expanded so rounded bottom corners blend into the panel
                                    color: btn.isSelected ? Colors.bg : Colors.accent
                                    clip: true

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 420
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: [0.38, 1.21, 0.22, 1.00, 1, 1]
                                        }
                                    }
                                    Behavior on height {
                                        NumberAnimation {
                                            duration: 420
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: [0.38, 1.21, 0.22, 1.00, 1, 1]
                                        }
                                    }
                                    Behavior on radius {
                                        NumberAnimation {
                                            duration: 420
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: [0.42, 1.67, 0.21, 0.90, 1, 1]
                                        }
                                    }

                                    HoverHandler {
                                        id: hov
                                    }

                                    // Expand (collapsed state)
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !btn.isSelected
                                        onClicked: {
                                            root.selectedRow = rowItem.index;
                                            root.selectedCol = btn.index;
                                        }
                                    }

                                    // Collapse (expanded state), border ring, sits under the Loader.
                                    // Must be MouseArea (not TapHandler) so child MouseAreas in the
                                    // widget content can consume interior events and block this.
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: btn.isSelected
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.selectedRow = -1;
                                            root.selectedCol = -1;
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: parent.radius
                                        color: "white"
                                        opacity: hov.hovered && !btn.isSelected ? 0.08 : 0.0
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 150
                                            }
                                        }
                                    }

                                    // Orange header strip, own radius rounds the top corners,
                                    // inner rect fills the bottom curves to keep the bottom edge flat.
                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 40
                                        radius: 16
                                        color: Colors.accent
                                        visible: btn.isSelected

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            height: 16
                                            color: Colors.accent
                                        }

                                        Row {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: 14
                                            spacing: 8

                                            Text {
                                                text: btn.icon
                                                color: Colors.bg
                                                font.family: "Material Icons"
                                                font.pixelSize: 19
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Text {
                                                text: btn.label
                                                color: Colors.bg
                                                font.pixelSize: 14
                                                font.weight: Font.Medium
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }

                                    // Icon + label, hidden once expanded
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 8
                                        opacity: btn.isSelected ? 0 : 1
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 120
                                            }
                                        }

                                        Text {
                                            text: btn.icon
                                            color: Colors.bg
                                            font.family: "Material Icons"
                                            font.pixelSize: 20
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: btn.label
                                            color: Colors.bg
                                            font.pixelSize: 14
                                            font.weight: Font.Medium
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    // Absorbs any interior clicks that fall through transparent
                                    // areas of the widget content, so the collapse MouseArea below
                                    // never fires inside the content region.
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.topMargin: 40
                                        enabled: btn.isSelected
                                    }

                                    // Widget content, declared last for highest event priority.
                                    // Only top margin exposes the collapse strip; left/right/bottom flush.
                                    Loader {
                                        anchors.fill: parent
                                        anchors.topMargin: 40
                                        active: btn.isSelected
                                        sourceComponent: btn.isSelected ? root.widgetComponents[btn.widgetIndex] : null
                                        opacity: btn.isSelected ? 1 : 0
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 200
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
