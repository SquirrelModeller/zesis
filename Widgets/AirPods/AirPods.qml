pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../"
import "../Shared"

Item {
    id: root

    visible: AirPodsService.connected
    implicitWidth: pill.implicitWidth
    implicitHeight: Math.round(30 * UIScale.value)

    // bar indicator

    Rectangle {
        id: pill
        anchors.centerIn: parent
        implicitWidth: pillRow.implicitWidth + UIScale.spacingMd
        implicitHeight: Math.round(22 * UIScale.value)
        radius: 100
        color: pillHover.hovered || apPopup.visible ? Colors.withAlpha(Colors.text, 0.1) : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: Math.round(5 * UIScale.value)

            Text {
                text: "󰋋"
                font.pixelSize: Math.round(14 * UIScale.value)
                color: Colors.accent
            }

            // Left pod %
            Text {
                text: AirPodsService.leftLevel + "%"
                font.pixelSize: UIScale.fontTiny
                font.weight: Font.DemiBold
                color: AirPodsService.leftCharging ? Colors.accent : Colors.text
                opacity: AirPodsService.leftEar ? 1.0 : 0.35
                Behavior on opacity {
                    NumberAnimation {
                        duration: Anim.fast
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
            }

            // Right pod %
            Text {
                text: AirPodsService.rightLevel + "%"
                font.pixelSize: UIScale.fontTiny
                font.weight: Font.DemiBold
                color: AirPodsService.rightCharging ? Colors.accent : Colors.text
                opacity: AirPodsService.rightEar ? 1.0 : 0.35
                Behavior on opacity {
                    NumberAnimation {
                        duration: Anim.fast
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
            }
        }

        HoverHandler {
            id: pillHover
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: apPopup.visible ? apPopup.close() : apPopup.open()
        }
    }

    // popup

    PopupWindow {
        id: apPopup
        anchor.item: root
        anchor.rect.x: root.width / 2 - apPopup.implicitWidth / 2
        anchor.rect.y: root.height
        grabFocus: true
        visible: false
        color: "transparent"
        implicitWidth: Math.round(260 * UIScale.value)
        implicitHeight: apContent.implicitHeight

        function open() {
            if (!visible) {
                apContent.scale = 0;
                apContent.opacity = 0;
                visible = true;
            }
            apShowAnim.start();
        }

        function close() {
            if (!visible)
                return;
            apShowAnim.stop();
            visible = false;
        }

        onVisibleChanged: {
            if (!visible) {
                apContent.scale = 0;
                apContent.opacity = 0;
            }
        }

        ParallelAnimation {
            id: apShowAnim
            NumberAnimation {
                target: apContent
                property: "scale"
                to: 1
                duration: Anim.slow
                easing.type: Easing.OutBack
                easing.overshoot: 1.4
            }
            NumberAnimation {
                target: apContent
                property: "opacity"
                to: 1
                duration: Anim.medium
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: apContent
            anchors.left: parent.left
            anchors.right: parent.right
            implicitHeight: popupCol.implicitHeight
            scale: 0
            opacity: 0
            transformOrigin: Item.Top

            Rectangle {
                anchors.fill: parent
                radius: UIScale.radiusLg
                topLeftRadius: 0
                topRightRadius: 0
                color: Colors.bg
                border.color: Colors.outline
                border.width: 1
            }

            ColumnLayout {
                id: popupCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: UIScale.spacingMd
                spacing: UIScale.spacingSm

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: UIScale.spacingSm

                    Text {
                        text: "󰋋"
                        font.pixelSize: Math.round(22 * UIScale.value)
                        color: Colors.accent
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: Math.round(2 * UIScale.value)

                        Text {
                            text: AirPodsService.deviceName || "AirPods"
                            color: Colors.text
                            font.pixelSize: UIScale.fontSmall
                            font.weight: Font.Bold
                        }

                        Text {
                            text: {
                                const l = AirPodsService.leftEar;
                                const r = AirPodsService.rightEar;
                                if (l && r)
                                    return "Both in ear";
                                if (l)
                                    return "Left in ear";
                                if (r)
                                    return "Right in ear";
                                return "Not in ear";
                            }
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontTiny
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Colors.outline
                }

                // Battery rows
                BatteryRow {
                    Layout.fillWidth: true
                    label: "Left"
                    level: AirPodsService.leftLevel
                    charging: AirPodsService.leftCharging
                    inEar: AirPodsService.leftEar
                }

                BatteryRow {
                    Layout.fillWidth: true
                    label: "Right"
                    level: AirPodsService.rightLevel
                    charging: AirPodsService.rightCharging
                    inEar: AirPodsService.rightEar
                }

                BatteryRow {
                    Layout.fillWidth: true
                    label: "Case"
                    level: AirPodsService.caseLevel
                    charging: AirPodsService.caseCharging
                    inEar: true
                    visible: AirPodsService.caseLevel > 0
                }

                Item {
                    implicitHeight: UIScale.spacingXs
                }
            }
        }
    }

    // battery row component

    component BatteryRow: ColumnLayout {
        property string label: ""
        property int level: 0
        property bool charging: false
        property bool inEar: true

        spacing: Math.round(3 * UIScale.value)

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: parent.parent.label
                color: parent.parent.inEar ? Colors.text : Colors.textDim
                font.pixelSize: UIScale.fontTiny
                font.weight: Font.Medium
                Layout.fillWidth: true
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
            }

            Text {
                text: parent.parent.charging ? "󱐋 " + parent.parent.level + "%" : parent.parent.level + "%"
                color: parent.parent.charging ? Colors.accent : Colors.text
                font.pixelSize: UIScale.fontTiny
                font.weight: Font.DemiBold
                font.family: "monospace"
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.round(4 * UIScale.value)
            radius: 2
            color: Colors.surfaceHigh

            Rectangle {
                width: parent.width * (parent.parent.level / 100)
                height: parent.height
                radius: parent.radius
                color: {
                    if (parent.parent.charging)
                        return Colors.accent;
                    if (parent.parent.level <= 15)
                        return "#e05c5c";
                    if (parent.parent.level <= 30)
                        return "#e0a85c";
                    return Colors.accent;
                }
                Behavior on width {
                    NumberAnimation {
                        duration: Anim.slow
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
            }
        }
    }
}
