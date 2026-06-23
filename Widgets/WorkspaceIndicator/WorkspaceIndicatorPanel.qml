pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../"
import "../Shared"

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: "SETTINGS / WORKSPACE INDICATOR"
            title: "Workspace Indicator"
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Settings
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: settingsCol.implicitHeight + UIScale.panelPad
                clip: true
                flickableDirection: Flickable.VerticalFlick

                ColumnLayout {
                    id: settingsCol
                    width: parent.width
                    spacing: UIScale.spacingMd

                    Item {
                        implicitHeight: UIScale.spacingXs
                    }

                    // Workspace count
                    Text {
                        text: "Workspaces"
                        color: WorkspaceIndicatorService.expressive ? Colors.muted : Colors.text
                        font.pixelSize: UIScale.fontBody
                        font.bold: true
                        Layout.leftMargin: UIScale.panelPad
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        implicitHeight: Math.round(36 * UIScale.value)
                        opacity: WorkspaceIndicatorService.expressive ? 0.35 : 1.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: Anim.fast
                            }
                        }
                        enabled: !WorkspaceIndicatorService.expressive

                        RowLayout {
                            anchors.fill: parent
                            spacing: UIScale.spacingSm

                            Rectangle {
                                implicitWidth: Math.round(36 * UIScale.value)
                                implicitHeight: Math.round(36 * UIScale.value)
                                radius: UIScale.radiusSm
                                color: minusHover.hovered ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surfaceHigh
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Anim.fast
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "-"
                                    color: WorkspaceIndicatorService.workSpaceAmount <= 1 ? Colors.muted : Colors.text
                                    font.pixelSize: UIScale.fontSubhead
                                }
                                HoverHandler {
                                    id: minusHover
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (WorkspaceIndicatorService.workSpaceAmount > 1)
                                        WorkspaceIndicatorService.workSpaceAmount -= 1
                                }
                            }

                            Text {
                                text: WorkspaceIndicatorService.workSpaceAmount
                                color: Colors.accent
                                font.pixelSize: UIScale.fontSubhead
                                font.weight: Font.Bold
                                font.family: "monospace"
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Rectangle {
                                implicitWidth: Math.round(36 * UIScale.value)
                                implicitHeight: Math.round(36 * UIScale.value)
                                radius: UIScale.radiusSm
                                color: plusHover.hovered ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surfaceHigh
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Anim.fast
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: WorkspaceIndicatorService.workSpaceAmount >= 10 ? Colors.muted : Colors.text
                                    font.pixelSize: UIScale.fontSubhead
                                }
                                HoverHandler {
                                    id: plusHover
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (WorkspaceIndicatorService.workSpaceAmount < 10)
                                        WorkspaceIndicatorService.workSpaceAmount += 1
                                }
                            }
                        }
                    }

                    // Expressive toggle
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad

                        Column {
                            Layout.fillWidth: true
                            spacing: Math.round(2 * UIScale.value)

                            Text {
                                text: "Expressive"
                                color: Colors.text
                                font.pixelSize: UIScale.fontBody
                                font.bold: true
                            }
                            Text {
                                text: "Teeth follow active workspace count"
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontCaption
                            }
                        }

                        ToggleSwitch {
                            checked: WorkspaceIndicatorService.expressive
                            onToggled: WorkspaceIndicatorService.expressive = !WorkspaceIndicatorService.expressive
                        }
                    }

                    // Minimum (expressive only)
                    Text {
                        text: "Minimum"
                        color: WorkspaceIndicatorService.expressive ? Colors.text : Colors.muted
                        font.pixelSize: UIScale.fontBody
                        font.bold: true
                        Layout.leftMargin: UIScale.panelPad
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        implicitHeight: Math.round(36 * UIScale.value)
                        opacity: WorkspaceIndicatorService.expressive ? 1.0 : 0.35
                        Behavior on opacity {
                            NumberAnimation {
                                duration: Anim.fast
                            }
                        }
                        enabled: WorkspaceIndicatorService.expressive

                        RowLayout {
                            anchors.fill: parent
                            spacing: UIScale.spacingSm

                            Rectangle {
                                implicitWidth: Math.round(36 * UIScale.value)
                                implicitHeight: Math.round(36 * UIScale.value)
                                radius: UIScale.radiusSm
                                color: minMinusHover.hovered ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surfaceHigh
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Anim.fast
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "-"
                                    color: WorkspaceIndicatorService.minWorkSpaceAmount <= 1 ? Colors.muted : Colors.text
                                    font.pixelSize: UIScale.fontSubhead
                                }
                                HoverHandler {
                                    id: minMinusHover
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (WorkspaceIndicatorService.minWorkSpaceAmount > 1)
                                        WorkspaceIndicatorService.minWorkSpaceAmount -= 1
                                }
                            }

                            Text {
                                text: WorkspaceIndicatorService.minWorkSpaceAmount
                                color: Colors.accent
                                font.pixelSize: UIScale.fontSubhead
                                font.weight: Font.Bold
                                font.family: "monospace"
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Rectangle {
                                implicitWidth: Math.round(36 * UIScale.value)
                                implicitHeight: Math.round(36 * UIScale.value)
                                radius: UIScale.radiusSm
                                color: minPlusHover.hovered ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surfaceHigh
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Anim.fast
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: WorkspaceIndicatorService.minWorkSpaceAmount >= 10 ? Colors.muted : Colors.text
                                    font.pixelSize: UIScale.fontSubhead
                                }
                                HoverHandler {
                                    id: minPlusHover
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (WorkspaceIndicatorService.minWorkSpaceAmount < 10)
                                        WorkspaceIndicatorService.minWorkSpaceAmount += 1
                                }
                            }
                        }
                    }

                    Divider {
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                    }

                    // Disc radius
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad

                        Text {
                            text: "Disc radius"
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Text {
                            text: WorkspaceIndicatorService.discRadius + " px"
                            color: Colors.accent
                            font.pixelSize: UIScale.fontBody
                            font.weight: Font.Bold
                            font.family: "monospace"
                        }
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        from: 35
                        to: 80
                        value: WorkspaceIndicatorService.discRadius
                        onMoved: v => WorkspaceIndicatorService.discRadius = v
                    }

                    // Tooth width
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad

                        Text {
                            text: "Tooth width"
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Text {
                            text: WorkspaceIndicatorService.toothWidth + " %"
                            color: Colors.accent
                            font.pixelSize: UIScale.fontBody
                            font.weight: Font.Bold
                            font.family: "monospace"
                        }
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        from: 5
                        to: 80
                        value: WorkspaceIndicatorService.toothWidth
                        onMoved: v => WorkspaceIndicatorService.toothWidth = v
                    }

                    // Valley depth
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad

                        Text {
                            text: "Valley depth"
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Text {
                            text: WorkspaceIndicatorService.valleyDepth + " %"
                            color: Colors.accent
                            font.pixelSize: UIScale.fontBody
                            font.weight: Font.Bold
                            font.family: "monospace"
                        }
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        from: 0
                        to: 55
                        value: WorkspaceIndicatorService.valleyDepth
                        onMoved: v => WorkspaceIndicatorService.valleyDepth = v
                    }

                    // Dot size
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad

                        Text {
                            text: "Dot size"
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Text {
                            text: WorkspaceIndicatorService.chamberSize + " px"
                            color: Colors.accent
                            font.pixelSize: UIScale.fontBody
                            font.weight: Font.Bold
                            font.family: "monospace"
                        }
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        from: 14
                        to: 34
                        value: WorkspaceIndicatorService.chamberSize
                        onMoved: v => WorkspaceIndicatorService.chamberSize = v
                    }

                    Divider {
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                    }

                    // Dot orbit
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad

                        Text {
                            text: "Dot orbit"
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Text {
                            text: WorkspaceIndicatorService.chamberRadius + " px"
                            color: Colors.accent
                            font.pixelSize: UIScale.fontBody
                            font.weight: Font.Bold
                            font.family: "monospace"
                        }
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        from: 15
                        to: 45
                        value: WorkspaceIndicatorService.chamberRadius
                        onMoved: v => WorkspaceIndicatorService.chamberRadius = v
                    }

                    // Corner peek
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad

                        Text {
                            text: "Corner peek"
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Text {
                            text: WorkspaceIndicatorService.peekOffset + " px"
                            color: Colors.accent
                            font.pixelSize: UIScale.fontBody
                            font.weight: Font.Bold
                            font.family: "monospace"
                        }
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        from: 4
                        to: 28
                        value: WorkspaceIndicatorService.peekOffset
                        onMoved: v => WorkspaceIndicatorService.peekOffset = v
                    }

                    Item {
                        implicitHeight: UIScale.spacingXs
                    }
                }
            }

            // Preview
            Item {
                Layout.preferredWidth: Math.round(280 * UIScale.value)
                Layout.fillHeight: true

                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    width: 1
                    color: Colors.withAlpha(Colors.outline, 0.5)
                }

                Text {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: UIScale.spacingMd
                    text: "PREVIEW"
                    color: Colors.muted
                    font.pixelSize: UIScale.fontTiny
                    font.letterSpacing: 1.5
                    font.weight: Font.Medium
                }

                WorkspaceIndicator {
                    anchors.centerIn: parent
                    forceExpanded: true
                }
            }
        }
    }
}
