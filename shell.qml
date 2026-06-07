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

            // AnimPopupTest {
            //     anchors.left: parent.left
            //     anchors.leftMargin: 20
            //     anchors.top: parent.top
            //     anchors.bottom: parent.bottom
            // }

            // This casues 2% GPU usage, optimze
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

            Connections {
                target: trayWidget
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

                Loader {
                    anchors.fill: parent
                    active: Mpris.players.values.length > 0
                    sourceComponent: MusicController {}
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
        visible: false

        function open() {
            if (!visible) {
                keybindDimmer.opacity = 0;
                keybindContent.scale = 0;
                keybindContent.opacity = 0;
                visible = true;
            }
            keybindHideAnim.stop();
            keybindShowAnim.start();
        }

        function close() {
            if (!visible)
                return;
            keybindShowAnim.stop();
            keybindHideAnim.start();
        }

        // qmllint disable missing-property
        property bool _kbOpen: KeybindService.popupOpen
        on_KbOpenChanged: {
            if (_kbOpen)
                open();
            else
                close();
        }
        // qmllint enable missing-property

        onVisibleChanged: {
            if (!visible) {
                KeybindService.popupOpen = false; // qmllint disable missing-property
                keybindContent.scale = 0;
                keybindContent.opacity = 0;
            }
        }

        ParallelAnimation {
            id: keybindShowAnim
            NumberAnimation {
                target: keybindDimmer
                property: "opacity"
                to: 0.45
                duration: 200
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: keybindContent
                property: "scale"
                to: 1
                duration: 280
                easing.type: Easing.OutBack
                easing.overshoot: 1.4
            }
            NumberAnimation {
                target: keybindContent
                property: "opacity"
                to: 1
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            id: keybindHideAnim
            NumberAnimation {
                target: keybindDimmer
                property: "opacity"
                to: 0
                duration: 180
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: keybindContent
                property: "scale"
                to: 0
                duration: 180
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: keybindContent
                property: "opacity"
                to: 0
                duration: 150
                easing.type: Easing.InCubic
            }
            onStopped: keybindOverlay.visible = false
        }

        Rectangle {
            id: keybindDimmer
            anchors.fill: parent
            color: "black"
            opacity: 0
            TapHandler {
                onTapped: KeybindService.popupOpen = false // qmllint disable missing-property
            }
        }

        Item {
            id: keybindContent
            anchors.centerIn: parent
            width: Math.min(keybindOverlay.width - 80, 1100)
            height: Math.min(keybindOverlay.height - 80, 820)
            scale: 0
            opacity: 0

            Loader {
                id: keybindLoader
                active: keybindOverlay.visible
                anchors.fill: parent
                sourceComponent: KeybindPopup {}
                onLoaded: item.focusSearch() // qmllint disable missing-property
            }
        }
    }

    IpcHandler {
        target: "keybinds"
        function toggle() {
            KeybindService.popupOpen = !KeybindService.popupOpen; // qmllint disable missing-property
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
