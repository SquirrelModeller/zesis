pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"

Rectangle {
    id: root

    anchors.fill: parent
    radius: UIScale.radiusMd
    color: Colors.bg
    border.color: Colors.outline
    border.width: 1

    Timer {
        id: writeTimer
        interval: 0
        onTriggered: UIScale.write(scaleSlider.value, fontSlider.value, spacingSlider.value, radiusSlider.value)
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
                text: "Interface Scale"
                color: Colors.text
                font.bold: true
                font.pointSize: UIScale.fontMd
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: scaleSlider.value.toFixed(2) + "x"
                color: Colors.accent
                font.bold: true
                font.pointSize: UIScale.fontMd
            }
        }

        ScaleSlider {
            id: scaleSlider
            Layout.fillWidth: true
            value: UIScale.value
            onMoved: writeTimer.restart()
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: UIScale.spacingSm

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.round(28 * UIScale.value)
                radius: UIScale.radiusSm
                color: Math.abs(scaleSlider.value - 0.85) < 0.01 ? Colors.withAlpha(Colors.accent, 0.2) : Colors.surfaceHigh
                border.color: Math.abs(scaleSlider.value - 0.85) < 0.01 ? Colors.accent : "transparent"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Small"
                    color: Colors.text
                    font.pointSize: UIScale.fontXs
                }
                TapHandler {
                    onTapped: {
                        scaleSlider.value = 0.85;
                        writeTimer.restart();
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.round(28 * UIScale.value)
                radius: UIScale.radiusSm
                color: Math.abs(scaleSlider.value - 1.0) < 0.01 ? Colors.withAlpha(Colors.accent, 0.2) : Colors.surfaceHigh
                border.color: Math.abs(scaleSlider.value - 1.0) < 0.01 ? Colors.accent : "transparent"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Normal"
                    color: Colors.text
                    font.pointSize: UIScale.fontXs
                }
                TapHandler {
                    onTapped: {
                        scaleSlider.value = 1.0;
                        writeTimer.restart();
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.round(28 * UIScale.value)
                radius: UIScale.radiusSm
                color: Math.abs(scaleSlider.value - 1.3) < 0.01 ? Colors.withAlpha(Colors.accent, 0.2) : Colors.surfaceHigh
                border.color: Math.abs(scaleSlider.value - 1.3) < 0.01 ? Colors.accent : "transparent"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Large"
                    color: Colors.text
                    font.pointSize: UIScale.fontXs
                }
                TapHandler {
                    onTapped: {
                        scaleSlider.value = 1.3;
                        writeTimer.restart();
                    }
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Colors.withAlpha(Colors.accent, 0.1)
        }

        // Setting: Font Size
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Font Size"
                color: Colors.text
                font.bold: true
                font.pointSize: UIScale.fontMd
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: fontSlider.value.toFixed(2) + "x"
                color: Colors.accent
                font.bold: true
                font.pointSize: UIScale.fontMd
            }
        }

        ScaleSlider {
            id: fontSlider
            Layout.fillWidth: true
            value: UIScale.fontScale
            onMoved: writeTimer.restart()
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Colors.withAlpha(Colors.accent, 0.1)
        }

        // Setting: Spacing
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Spacing"
                color: Colors.text
                font.bold: true
                font.pointSize: UIScale.fontMd
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: spacingSlider.value.toFixed(2) + "x"
                color: Colors.accent
                font.bold: true
                font.pointSize: UIScale.fontMd
            }
        }

        ScaleSlider {
            id: spacingSlider
            Layout.fillWidth: true
            value: UIScale.spacingScale
            onMoved: writeTimer.restart()
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Colors.withAlpha(Colors.accent, 0.1)
        }

        // Setting: Radius
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Radius"
                color: Colors.text
                font.bold: true
                font.pointSize: UIScale.fontMd
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: radiusSlider.value.toFixed(2) + "x"
                color: Colors.accent
                font.bold: true
                font.pointSize: UIScale.fontMd
            }
        }

        ScaleSlider {
            id: radiusSlider
            Layout.fillWidth: true
            value: UIScale.radiusScale
            onMoved: writeTimer.restart()
        }
    }

    component ScaleSlider: Item {
        id: sliderRoot

        implicitHeight: 32
        property real value: 1.0
        signal moved

        readonly property real _handleW: 18
        readonly property real _t: Math.max(0, Math.min(1, (value - 0.5) / 1.5))

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            height: 4
            radius: 2
            color: Colors.surfaceHigh

            Rectangle {
                width: parent.width * sliderRoot._t
                height: parent.height
                radius: parent.radius
                color: Colors.accent
            }
        }

        Rectangle {
            width: sliderRoot._handleW
            height: sliderRoot._handleW
            radius: sliderRoot._handleW / 2
            anchors.verticalCenter: parent.verticalCenter
            x: sliderRoot._t * (sliderRoot.width - sliderRoot._handleW)
            color: dragH.active ? Colors.accent : Colors.withAlpha(Colors.accent, 0.85)
            border.color: Colors.withAlpha(Colors.accent, 0.3)
            border.width: 1
        }

        DragHandler {
            id: dragH
            target: null
            yAxis.enabled: false
            onTranslationChanged: {
                if (active) {
                    var t = Math.max(0, Math.min(1, (centroid.position.x - sliderRoot._handleW * 0.5) / (sliderRoot.width - sliderRoot._handleW)));
                    sliderRoot.value = Math.round((0.5 + t * 1.5) / 0.05) * 0.05;
                    sliderRoot.moved();
                }
            }
        }
    }
}
