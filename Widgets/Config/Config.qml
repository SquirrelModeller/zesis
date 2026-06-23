pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"
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
        radius: Math.round(12 * UIScale.value)
        topLeftRadius: 0
        topRightRadius: 0
        color: Colors.bg
        border.color: Colors.outline
        border.width: 1
    }

    Timer {
        id: writeTimer
        interval: 0
        onTriggered: UIScale.write(root._scaleVal, root._fontVal, root._spacingVal, root._radiusVal)
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: UIScale.spacingLg
        }
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
    }
}
