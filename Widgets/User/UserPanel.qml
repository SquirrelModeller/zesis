import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import "../Shared"
import "../../"

Item {
    id: root
    focus: true

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: "SETTINGS / USER"
            title: "User"
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width

            TapHandler {
                onTapped: root.forceActiveFocus()
            }
            contentHeight: bodyCol.implicitHeight + UIScale.panelPad
            clip: true
            flickableDirection: Flickable.VerticalFlick

            ColumnLayout {
                id: bodyCol
                width: parent.width
                spacing: UIScale.spacingMd

                Item {
                    implicitHeight: UIScale.spacingXs
                }

                // Avatar preview card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(190 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Colors.withAlpha(Colors.text, 0.03)
                    border.color: Colors.withAlpha(Colors.text, 0.06)
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: UIScale.spacingMd

                        UserAvatar {
                            size: Math.round(90 * UIScale.value)
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: Math.round(130 * UIScale.value)
                            implicitHeight: Math.round(30 * UIScale.value)
                            radius: UIScale.radiusSm
                            color: changeHov.hovered ? Colors.withAlpha(Colors.accent, 0.28) : Colors.withAlpha(Colors.accent, 0.14)
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "Change avatar"
                                color: Colors.accent
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }

                            HoverHandler {
                                id: changeHov
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: filePicker.open()
                            }
                        }
                    }

                    Text {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.margins: UIScale.spacingSm
                        text: "AVATAR"
                        color: Colors.withAlpha(Colors.muted, 0.4)
                        font.pixelSize: UIScale.fontTiny
                        font.letterSpacing: 1.5
                        font.weight: Font.Bold
                    }
                }

                Text {
                    text: "IDENTITY"
                    color: Colors.muted
                    font.pixelSize: UIScale.fontTiny
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    Layout.leftMargin: UIScale.panelPad
                    Layout.topMargin: UIScale.spacingXs
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(56 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Colors.withAlpha(Colors.text, 0.03)
                    border.color: Colors.withAlpha(Colors.text, 0.06)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: UIScale.spacingMd
                        anchors.rightMargin: UIScale.spacingMd
                        spacing: UIScale.spacingSm

                        Column {
                            spacing: Math.round(2 * UIScale.value)

                            Text {
                                text: "Name"
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: "How the shell greets you"
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledTextInput {
                            Layout.fillWidth: false
                            Layout.preferredWidth: Math.round(160 * UIScale.value)
                            text: UserService.name
                            placeholder: "Your name"
                            onAccepted: {
                                UserService.setName(field.text);
                                root.forceActiveFocus();
                            }
                            field.onActiveFocusChanged: {
                                if (!field.activeFocus)
                                    UserService.setName(field.text);
                            }
                        }
                    }
                }

                Item {
                    implicitHeight: UIScale.spacingXs
                }
            }
        }
    }

    FileDialog {
        id: filePicker
        title: "Choose Avatar Image"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.svg *.webp *.bmp *.gif)", "All files (*)"]
        onAccepted: {
            var path = filePicker.selectedFile.toString();
            if (path.startsWith("file://"))
                path = path.slice(7);
            UserService.setAvatarPath(path);
        }
    }
}
