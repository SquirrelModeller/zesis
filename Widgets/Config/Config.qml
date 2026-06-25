pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../"
import "../Bar"
import "../Shared"

Item {
    id: root

    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        radius: UIScale.radiusLg
        topLeftRadius:     (BarConfig.side === "top"    || BarConfig.side === "left")  ? 0 : UIScale.radiusLg
        topRightRadius:    (BarConfig.side === "top"    || BarConfig.side === "right") ? 0 : UIScale.radiusLg
        bottomLeftRadius:  (BarConfig.side === "bottom" || BarConfig.side === "left")  ? 0 : UIScale.radiusLg
        bottomRightRadius: (BarConfig.side === "bottom" || BarConfig.side === "right") ? 0 : UIScale.radiusLg
        color: Colors.bg
        border.color: Colors.outline
        border.width: 1
    }

    Flickable {
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: layout.implicitHeight + UIScale.spacingLg * 2
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: layout
            x: UIScale.spacingLg
            y: UIScale.spacingLg
            width: parent.width - UIScale.spacingLg * 2
            spacing: UIScale.spacingMd

            // Bar side
            Text {
                text: "Bar side"
                color: Colors.text
                font.bold: true
                font.pixelSize: UIScale.fontBody
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: UIScale.spacingSm
                Repeater {
                    model: ["Top", "Bottom", "Left", "Right"]
                    delegate: Rectangle {
                        id: sideBtn
                        required property string modelData
                        Layout.fillWidth: true
                        implicitHeight: Math.round(28 * UIScale.value)
                        radius: UIScale.radiusSm
                        color: BarConfig.side === sideBtn.modelData.toLowerCase() ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surfaceHigh
                        border.color: BarConfig.side === sideBtn.modelData.toLowerCase() ? Colors.accent : "transparent"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData
                            color: Colors.text
                            font.pixelSize: UIScale.fontCaption
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: BarConfig.write(sideBtn.modelData.toLowerCase())
                        }
                    }
                }
            }

            Divider { color: Colors.withAlpha(Colors.accent, 0.1) }

            // Edge gap
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Edge gap"
                    color: Colors.text
                    font.bold: true
                    font.pixelSize: UIScale.fontBody
                    Layout.fillWidth: true
                }
                Text {
                    text: BarConfig.edgeGap + "px"
                    color: Colors.accent
                    font.bold: true
                    font.pixelSize: UIScale.fontBody
                }
            }
            SettingSlider {
                Layout.fillWidth: true
                from: 0; to: 40; step: 1
                value: BarConfig.edgeGap
                onMoved: function(v) { BarConfig.writeEdgeGap(Math.round(v)); }
            }

            Divider { color: Colors.withAlpha(Colors.accent, 0.1) }

            // End gap
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "End gap"
                    color: Colors.text
                    font.bold: true
                    font.pixelSize: UIScale.fontBody
                    Layout.fillWidth: true
                }
                Text {
                    text: BarConfig.endGap + "px"
                    color: Colors.accent
                    font.bold: true
                    font.pixelSize: UIScale.fontBody
                }
            }
            SettingSlider {
                Layout.fillWidth: true
                from: 0; to: 60; step: 1
                value: BarConfig.endGap
                onMoved: function(v) { BarConfig.writeEndGap(Math.round(v)); }
            }

            Divider { color: Colors.withAlpha(Colors.accent, 0.1) }

            // Bar items
            Text {
                text: "Bar items"
                color: Colors.text
                font.bold: true
                font.pixelSize: UIScale.fontBody
            }

            Repeater {
                model: BarItemsService.items
                delegate: RowLayout {
                    id: itemRow
                    required property var modelData
                    Layout.fillWidth: true

                    Text {
                        text: itemRow.modelData.label
                        color: Colors.text
                        font.pixelSize: UIScale.fontBody
                        Layout.fillWidth: true
                    }
                    ToggleSwitch {
                        checked: BarItemsService.isEnabled(itemRow.modelData.id)
                        onToggled: BarItemsService.toggle(itemRow.modelData.id)
                    }
                }
            }
        }
    }
}
