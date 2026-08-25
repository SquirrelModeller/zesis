pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import "../shared"
import "../shared/inputs"
import "../../"

Item {
    id: root
    focus: true

    readonly property var _languageOptions: {
        var opts = [
            {
                label: I18n.t("user.languageAuto"),
                value: "system"
            }
        ];
        for (var i = 0; i < I18n.languages.length; i++)
            opts.push({
                label: I18n.languages[i].nativeName,
                value: I18n.languages[i].code
            });
        return opts;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("user.breadcrumb")
            title: I18n.t("user.title")
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
                                text: I18n.t("user.changeAvatar")
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
                        text: I18n.t("user.avatarLabel")
                        color: Colors.withAlpha(Colors.muted, 0.4)
                        font.pixelSize: UIScale.fontTiny
                        font.letterSpacing: 1.5
                        font.weight: Font.Bold
                    }
                }

                SectionLabel {
                    text: I18n.t("user.identitySection")
                    Layout.leftMargin: UIScale.panelPad
                    Layout.topMargin: UIScale.spacingXs
                }

                SettingCard {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: UIScale.spacingSm

                        Column {
                            spacing: Math.round(2 * UIScale.value)

                            Text {
                                text: I18n.t("user.nameLabel")
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: I18n.t("user.nameHint")
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
                            placeholder: I18n.t("user.namePlaceholder")
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

                SectionLabel {
                    text: I18n.t("user.heroCardSection")
                    Layout.leftMargin: UIScale.panelPad
                    Layout.topMargin: UIScale.spacingXs
                }

                SettingCard {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: UIScale.spacingSm

                        Column {
                            spacing: Math.round(2 * UIScale.value)

                            Text {
                                text: I18n.t("user.followWallpaper")
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: I18n.t("user.followWallpaperHint")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        ToggleSwitch {
                            checked: UserService.heroFollowWallpaper
                            onToggled: UserService.setHeroFollowWallpaper(!UserService.heroFollowWallpaper)
                        }
                    }
                }

                SettingCard {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    visible: !UserService.heroFollowWallpaper

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: UIScale.spacingSm

                        Column {
                            Layout.fillWidth: true
                            spacing: Math.round(2 * UIScale.value)

                            Text {
                                text: I18n.t("user.customImage")
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                            Text {
                                width: parent.width
                                text: UserService.heroImage !== "" ? UserService.heroImage.split("/").pop() : I18n.t("user.noImageSelected")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            implicitWidth: Math.round(110 * UIScale.value)
                            implicitHeight: Math.round(30 * UIScale.value)
                            radius: UIScale.radiusSm
                            color: heroPickHov.hovered ? Colors.withAlpha(Colors.accent, 0.28) : Colors.withAlpha(Colors.accent, 0.14)
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: I18n.t("user.chooseImage")
                                color: Colors.accent
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }

                            HoverHandler {
                                id: heroPickHov
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: heroPicker.open()
                            }
                        }
                    }
                }

                SectionLabel {
                    text: I18n.t("user.languageSection")
                    Layout.leftMargin: UIScale.panelPad
                    Layout.topMargin: UIScale.spacingXs
                }

                SettingCard {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: UIScale.spacingSm

                        Column {
                            spacing: Math.round(2 * UIScale.value)

                            Text {
                                text: I18n.t("user.languageLabel")
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: I18n.t("user.languageHint")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        MorphComboBox {
                            id: languageCombo
                            model: root._languageOptions
                            selectedValue: I18n.selection
                            onChosen: value => I18n.setLanguage(value)
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
        id: heroPicker
        title: I18n.t("user.chooseHeroImageDialogTitle")
        nameFilters: ["Images (*.png *.jpg *.jpeg *.svg *.webp *.bmp *.gif)", "All files (*)"]
        onAccepted: {
            var path = heroPicker.selectedFile.toString();
            if (path.startsWith("file://"))
                path = path.slice(7);
            UserService.setHeroImage(path);
        }
    }

    FileDialog {
        id: filePicker
        title: I18n.t("user.chooseAvatarDialogTitle")
        nameFilters: ["Images (*.png *.jpg *.jpeg *.svg *.webp *.bmp *.gif)", "All files (*)"]
        onAccepted: {
            var path = filePicker.selectedFile.toString();
            if (path.startsWith("file://"))
                path = path.slice(7);
            UserService.setAvatarPath(path);
        }
    }
}
