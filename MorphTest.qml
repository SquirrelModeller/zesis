pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

ShellRoot {
    FloatingWindow {
        id: win
        width: 640
        height: 260

        property int selectedRow: -1
        property int selectedCol: -1

        property real collapsedW: 120
        property real collapsedH: 44
        property real expandedW: width - 48
        property real expandedH: 88
        property real colGap: 12
        property real rowGap: 12

        readonly property var layout: [["Wifi", "Bluetooth"], ["Music", "System", "Network"], ["Brightness", "Volume"]]

        readonly property bool anySelected: selectedRow !== -1

        // This file is a sort of playground and for research.

        // Animation notes for myself / observations:
        // - Pill must shrink to 0 alongside its container Item. If the container clips a
        //   fixed-size pill, the rounded ends get cut first, leaving a rectangle mid-animation.
        // - Row items must NOT use clip:true for the same reason vertically. Opacity (150ms)
        //   fades them out fast enough that no overflow is visible before they collapse.
        // - Column uses anchors.centerIn, so its top edge drifts as total height changes.
        //   For the middle row, this drift cancels the outward push on the rows above/below,
        //   making them appear to shrink in place rather than push away. Fixed positions (no
        //   Column) would give a cleaner directional push at the cost of manual layout.

        Rectangle {
            color: "#1a1208"
            anchors.fill: parent
        }

        Column {
            anchors.centerIn: parent
            spacing: win.anySelected ? 0 : win.rowGap

            Behavior on spacing {
                NumberAnimation {
                    duration: 420
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.38, 1.21, 0.22, 1.00, 1, 1]
                }
            }

            Repeater {
                model: win.layout

                delegate: Item {
                    id: rowItem
                    required property var modelData
                    required property int index

                    readonly property bool isThisRowSelected: win.selectedRow === rowItem.index

                    width: win.expandedW
                    height: isThisRowSelected ? win.expandedH : (win.anySelected ? 0 : win.collapsedH)
                    opacity: win.anySelected && !isThisRowSelected ? 0 : 1

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
                        spacing: win.anySelected ? 0 : win.colGap

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
                                required property string modelData
                                required property int index

                                readonly property bool isSelected: win.selectedRow === rowItem.index && win.selectedCol === btn.index
                                readonly property bool siblingSelected: rowItem.isThisRowSelected && !isSelected

                                width: isSelected ? win.expandedW : (win.anySelected ? 0 : win.collapsedW)
                                height: isSelected ? win.expandedH : win.collapsedH
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
                                    anchors.centerIn: parent
                                    width: btn.isSelected ? win.expandedW : (win.anySelected ? 0 : win.collapsedW)
                                    height: btn.isSelected ? win.expandedH : (win.anySelected ? 0 : win.collapsedH)
                                    radius: btn.isSelected ? 20 : 22
                                    color: Colors.accent

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

                                    Text {
                                        anchors.centerIn: parent
                                        text: btn.modelData
                                        color: Colors.bg
                                        font.pixelSize: 15
                                        font.weight: Font.Medium
                                    }

                                    HoverHandler {
                                        id: hov
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (btn.isSelected) {
                                                win.selectedRow = -1;
                                                win.selectedCol = -1;
                                            } else {
                                                win.selectedRow = rowItem.index;
                                                win.selectedCol = btn.index;
                                            }
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: parent.radius
                                        color: "white"
                                        opacity: hov.hovered ? 0.08 : 0.0
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 150
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
