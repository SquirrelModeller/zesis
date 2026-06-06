//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "Widgets/Bar"
import "Widgets/Music"
import "Widgets/Notifications"
import "Widgets/LockScreen"
import "Widgets/ThemeSwitcher"
import "Widgets/SysMon"
import "Widgets/Keybinds"

Scope {
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: root

            required property ShellScreen modelData

            WlrLayershell.layer: WlrLayer.Top
            screen: modelData

            implicitHeight: 60

            anchors {
                top: true
                left: true
                right: true
            }

            color: "transparent"

            property bool wantsMusic: false

            RowLayout {
                id: sysTray

                anchors {
                    rightMargin: 20
                    topMargin: 10
                }
                spacing: 0
                layoutDirection: Qt.RightToLeft
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                SysTray {
                    id: trayWidget
                }

                IdleInhibitor {
                    enabled: trayWidget.candleLit
                    window: root
                }
            }

            Item {
                id: centerHoverZone
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 300

                HoverHandler {
                    id: barCenter
                    onHoveredChanged: {
                        if (hovered) {
                            root.wantsMusic = true;
                        } else if (!popupHover.hovered) {
                            musicHideTimer.restart();
                        }
                    }
                }
            }

            Timer {
                id: musicHideTimer
                interval: 300
                onTriggered: root.wantsMusic = false
            }

            PopupWindow {
                id: themePopup
                grabFocus: true
                color: "transparent"
                implicitWidth: 380
                implicitHeight: 520

                anchor {
                    window: root
                    rect.x: root.width - 396
                    rect.y: root.height
                }

                // Sync back to button state when closed by clicking outside
                onVisibleChanged: {
                    if (!visible)
                        trayWidget.wantsThemeSwitcher = false;
                }

                ThemeSwitcherPopup {
                    anchors.fill: parent
                    active: themePopup.visible
                }
            }

            PopupWindow {
                id: sysMonPopup
                grabFocus: true
                color: "transparent"
                implicitWidth: 380
                implicitHeight: 520

                anchor {
                    window: root
                    rect.x: root.width - 396
                    rect.y: root.height
                }

                onVisibleChanged: {
                    if (!visible)
                        SysMonService.popupOpen = false;
                }

                SysMonPopup {
                    anchors.fill: parent
                }
            }

            Connections {
                target: SysMonService
                function onPopupOpenChanged() {
                    sysMonPopup.visible = SysMonService.popupOpen;
                }
            }

            Connections {
                target: trayWidget
                function onWantsThemeSwitcherChanged() {
                    themePopup.visible = trayWidget.wantsThemeSwitcher;
                }
                function onLockRequested() {
                    lockScreen.triggerLock();
                }
            }

            PopupWindow {
                id: musicPopup
                visible: root.wantsMusic && Mpris.players.values.length > 0
                grabFocus: false
                color: "transparent"
                implicitWidth: 400
                implicitHeight: 260

                anchor {
                    window: root
                    rect.x: root.width / 2 - 200
                    rect.y: root.height
                }

                HoverHandler {
                    id: popupHover
                    onHoveredChanged: {
                        if (hovered) {
                            musicHideTimer.stop();
                        } else if (!barCenter.hovered) {
                            musicHideTimer.restart();
                        }
                    }
                }

                MusicController {
                    anchors.fill: parent
                }
            }
        }
    }

    PanelWindow {
        WlrLayershell.layer: WlrLayer.Top
        anchors {
            top: true
            left: true
        }
        exclusiveZone: -1
        implicitWidth: 202
        implicitHeight: 202
        color: "transparent"

        mask: Region {
            shape: RegionShape.Ellipse
            x: indicator.visualDiscCX - indicator.discRadius
            y: indicator.visualDiscCY - indicator.discRadius
            width: indicator.discRadius * 2
            height: indicator.discRadius * 2
        }

        WorkspaceIndicator {
            id: indicator
            anchors.fill: parent
        }
    }

    LockScreen {
        id: lockScreen
    }

    PanelWindow {
        id: keybindOverlay
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusiveZone: -1
        color: "transparent"
        visible: KeybindService.popupOpen

        onVisibleChanged: if (visible)
            keybindContent.focusSearch()

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
            TapHandler {
                onTapped: KeybindService.popupOpen = false
            }
        }

        KeybindPopup {
            id: keybindContent
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 1100)
            height: Math.min(parent.height - 80, 820)
        }
    }

    IpcHandler {
        target: "keybinds"
        function toggle() {
            KeybindService.popupOpen = !KeybindService.popupOpen;
        }
    }

    // Notification toasts, top-right overlay, stacks below the bar
    PanelWindow {
        WlrLayershell.layer: WlrLayer.Overlay
        anchors {
            top: true
            right: true
        }
        exclusiveZone: 0
        implicitWidth: 360
        implicitHeight: 600
        color: "transparent"
        visible: NotifServer.count > 0

        Column {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 70
            anchors.rightMargin: 16
            spacing: 8
            width: 340

            Repeater {
                model: NotifServer.notifications
                delegate: NotifItem {
                    required property var modelData
                    notification: modelData
                    width: 340
                }
            }
        }
    }
}
