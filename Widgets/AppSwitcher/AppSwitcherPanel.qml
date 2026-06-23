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
            breadcrumb: "SETTINGS / APP SWITCHER"
            title: "App Switcher"
        }

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
                    implicitHeight: UIScale.spacingSm
                }

                Text {
                    text: "Default view"
                    color: Colors.text
                    font.pixelSize: UIScale.fontBody
                    font.bold: true
                    Layout.leftMargin: UIScale.panelPad
                }

                OptionRow {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    model: ["Window cards", "Workspace grid"]
                    currentIndex: AppSwitcherService.defaultMode
                    onActivated: index => AppSwitcherService.defaultMode = index
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    Text {
                        text: "Confirm on key release"
                        color: Colors.text
                        font.pixelSize: UIScale.fontBody
                        Layout.fillWidth: true
                    }

                    ToggleSwitch {
                        checked: AppSwitcherService.confirmOnRelease
                        onToggled: AppSwitcherService.confirmOnRelease = !AppSwitcherService.confirmOnRelease
                    }
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    Text {
                        text: "Remember last view this session"
                        color: Colors.text
                        font.pixelSize: UIScale.fontBody
                        Layout.fillWidth: true
                    }

                    ToggleSwitch {
                        checked: AppSwitcherService.rememberLastMode
                        onToggled: AppSwitcherService.rememberLastMode = !AppSwitcherService.rememberLastMode
                    }
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    Text {
                        text: "Follow moved window"
                        color: Colors.text
                        font.pixelSize: UIScale.fontBody
                        Layout.fillWidth: true
                    }

                    ToggleSwitch {
                        checked: AppSwitcherService.followMovedWindow
                        onToggled: AppSwitcherService.followMovedWindow = !AppSwitcherService.followMovedWindow
                    }
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                Text {
                    text: "New workspace"
                    color: Colors.text
                    font.pixelSize: UIScale.fontBody
                    font.bold: true
                    Layout.leftMargin: UIScale.panelPad
                }

                OptionRow {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    model: ["Fill gaps", "Append"]
                    currentIndex: AppSwitcherService.newWorkspaceStrategy === "fill" ? 0 : 1
                    onActivated: index => AppSwitcherService.newWorkspaceStrategy = index === 0 ? "fill" : "append"
                }

                Item {
                    implicitHeight: UIScale.spacingXs
                }
            }
        }
    }
}
