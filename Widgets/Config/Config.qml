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

    property real _scaleVal: UIScale.value
    property real _fontVal: UIScale.fontScale
    property real _spacingVal: UIScale.spacingScale
    property real _radiusVal: UIScale.radiusScale

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

    Timer {
        id: writeTimer
        interval: 0
        onTriggered: UIScale.write(root._scaleVal, root._fontVal, root._spacingVal, root._radiusVal)
    }

    Flickable {
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: layout.implicitHeight + UIScale.spacingLg * 2
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: layout
            x: UIScale.spacingLg
            y: UIScale.spacingLg
            width: parent.width - UIScale.spacingLg * 2
            spacing: UIScale.spacingMd

            // Setting: Interface Scale
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Interface scale"
                    color: Colors.text
                    font.bold: true
                    font.pixelSize: UIScale.fontBody
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: root._scaleVal.toFixed(2) + "x"
                    color: Colors.accent
                    font.bold: true
                    font.pixelSize: UIScale.fontBody
                }
            }

            SettingSlider {
                id: scaleSlider
                Layout.fillWidth: true
                from: 0.5
                to: 2.0
                step: 0.05
                value: root._scaleVal
                onMoved: function (v) {
                    root._scaleVal = v;
                    writeTimer.restart();
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: UIScale.spacingSm

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(28 * UIScale.value)
                    radius: UIScale.radiusSm
                    color: Math.abs(root._scaleVal - 0.85) < 0.01 ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surfaceHigh
                    border.color: Math.abs(root._scaleVal - 0.85) < 0.01 ? Colors.accent : "transparent"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "Small"
                        color: Colors.text
                        font.pixelSize: UIScale.fontCaption
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root._scaleVal = 0.85;
                            writeTimer.restart();
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(28 * UIScale.value)
                    radius: UIScale.radiusSm
                    color: Math.abs(root._scaleVal - 1.0) < 0.01 ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surfaceHigh
                    border.color: Math.abs(root._scaleVal - 1.0) < 0.01 ? Colors.accent : "transparent"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "Normal"
                        color: Colors.text
                        font.pixelSize: UIScale.fontCaption
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root._scaleVal = 1.0;
                            writeTimer.restart();
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(28 * UIScale.value)
                    radius: UIScale.radiusSm
                    color: Math.abs(root._scaleVal - 1.3) < 0.01 ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surfaceHigh
                    border.color: Math.abs(root._scaleVal - 1.3) < 0.01 ? Colors.accent : "transparent"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "Large"
                        color: Colors.text
                        font.pixelSize: UIScale.fontCaption
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root._scaleVal = 1.3;
                            writeTimer.restart();
                        }
                    }
                }
            }

            Divider {
                color: Colors.withAlpha(Colors.accent, 0.1)
            }

            // Setting: Font Size
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Font size"
                    color: Colors.text
                    font.bold: true
                    font.pixelSize: UIScale.fontBody
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: fontSlider.value.toFixed(2) + "x"
                    color: Colors.accent
                    font.bold: true
                    font.pixelSize: UIScale.fontBody
                }
            }

            SettingSlider {
                id: fontSlider
                Layout.fillWidth: true
                from: 0.5
                to: 2.0
                step: 0.05
                value: root._fontVal
                onMoved: function (v) {
                    root._fontVal = v;
                    writeTimer.restart();
                }
            }

            Divider {
                color: Colors.withAlpha(Colors.accent, 0.1)
            }

            // Setting: Spacing
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Spacing"
                    color: Colors.text
                    font.bold: true
                    font.pixelSize: UIScale.fontBody
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: spacingSlider.value.toFixed(2) + "x"
                    color: Colors.accent
                    font.bold: true
                    font.pixelSize: UIScale.fontBody
                }
            }

            SettingSlider {
                id: spacingSlider
                Layout.fillWidth: true
                from: 0.5
                to: 2.0
                step: 0.05
                value: root._spacingVal
                onMoved: function (v) {
                    root._spacingVal = v;
                    writeTimer.restart();
                }
            }

            Divider {
                color: Colors.withAlpha(Colors.accent, 0.1)
            }

            // Setting: Radius
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Radius"
                    color: Colors.text
                    font.bold: true
                    font.pixelSize: UIScale.fontBody
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: radiusSlider.value.toFixed(2) + "x"
                    color: Colors.accent
                    font.bold: true
                    font.pixelSize: UIScale.fontBody
                }
            }

            SettingSlider {
                id: radiusSlider
                Layout.fillWidth: true
                from: 0.5
                to: 2.0
                step: 0.05
                value: root._radiusVal
                onMoved: function (v) {
                    root._radiusVal = v;
                    writeTimer.restart();
                }
            }

            Divider {
                color: Colors.withAlpha(Colors.accent, 0.1)
            }

            // Setting: Bar side
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
                        required property string modelData
                        Layout.fillWidth: true
                        implicitHeight: Math.round(28 * UIScale.value)
                        radius: UIScale.radiusSm
                        color: BarConfig.side === modelData.toLowerCase() ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surfaceHigh
                        border.color: BarConfig.side === modelData.toLowerCase() ? Colors.accent : "transparent"
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
                            onClicked: BarConfig.write(parent.modelData.toLowerCase())
                        }
                    }
                }
            }

            Divider {
                color: Colors.withAlpha(Colors.accent, 0.1)
            }

            // Setting: Edge gap
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Edge gap"
                    color: Colors.text
                    font.bold: true
                    font.pixelSize: UIScale.fontBody
                }

                Item {
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
                from: 0
                to: 40
                step: 1
                value: BarConfig.edgeGap
                onMoved: function (v) {
                    BarConfig.writeEdgeGap(Math.round(v));
                }
            }

            Divider {
                color: Colors.withAlpha(Colors.accent, 0.1)
            }

            // Setting: End gap
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "End gap"
                    color: Colors.text
                    font.bold: true
                    font.pixelSize: UIScale.fontBody
                }

                Item {
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
                from: 0
                to: 60
                step: 1
                value: BarConfig.endGap
                onMoved: function (v) {
                    BarConfig.writeEndGap(Math.round(v));
                }
            }
        }
    }
}
