pragma ComponentBehavior: Bound

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
import "Widgets/AppSwitcher"
import "Widgets/Shared"
import "Widgets/WidgetHome"

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

    FullscreenOverlay {
        id: keybindOverlay
        maxContentWidth: 1100
        maxContentHeight: 820
        content: Component {
            KeybindPopup {}
        }

        property bool _kbOpen: KeybindService.popupOpen
        on_KbOpenChanged: _kbOpen ? open() : close()

        onVisibleChanged: if (!visible)
            KeybindService.popupOpen = false
        onDimmerTapped: KeybindService.popupOpen = false
        onContentLoaded: function (item) {
            item.focusSearch();
        }
    }

    IpcHandler {
        target: "keybinds"
        function toggle() {
            KeybindService.popupOpen = !KeybindService.popupOpen;
        }
    }

    FullscreenOverlay {
        id: appSwitcherOverlay
        dimmerOpacity: 0.60
        dimmerColor: "#0a0806"
        initialScale: 0.94
        showOvershoot: 1.1
        content: Component {
            AppSwitcherPopup {}
        }

        property bool _asOpen: AppSwitcherService.open
        on_AsOpenChanged: _asOpen ? open() : close()

        onVisibleChanged: if (!visible)
            AppSwitcherService.open = false
        onDimmerTapped: AppSwitcherService.confirm()
        onContentLoaded: function (item) {
            item.forceActiveFocus();
        }
    }

    IpcHandler {
        target: "appswitcher"
        function cycle() {
            AppSwitcherService.cycleForward();
        }
        function back() {
            AppSwitcherService.cycleBack();
        }
        function confirm() {
            AppSwitcherService.confirm();
        }
        function cancel() {
            AppSwitcherService.cancel();
        }
    }

    // Widget home sidebar
    PanelWindow {
        id: widgetHome

        readonly property real panelW: Math.round(360 * UIScale.value)

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        anchors {
            top: true
            right: true
            bottom: true
        }
        exclusiveZone: 0
        implicitWidth: panelW
        color: "transparent"
        visible: false

        property bool _whOpen: WidgetHomeService.open
        on_WhOpenChanged: {
            if (_whOpen) {
                sidebarRect.offsetScale = 1;
                visible = true;
                slideIn.start();
            } else {
                slideOut.start();
            }
        }

        // Open: ease into place (emphasizedDecel)
        NumberAnimation {
            id: slideIn
            target: sidebarRect; property: "offsetScale"
            to: 0; duration: 280
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
        }

        // Close: quick departure (emphasizedAccel)
        NumberAnimation {
            id: slideOut
            target: sidebarRect; property: "offsetScale"
            to: 1; duration: 220
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.3, 0, 0.8, 0.15, 1, 1]
            onFinished: widgetHome.visible = false
        }

        Rectangle {
            id: sidebarRect
            property real offsetScale: 1

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 60
            width: widgetHome.panelW
            x: widgetHome.panelW * offsetScale
            opacity: 1 - offsetScale
            color: Colors.bg
            border.color: Colors.outline
            border.width: 1

            WidgetHomePanel {
                anchors.fill: parent
            }
        }
    }

    // Notification toasts, top-right overlay, stacks below the bar
    PanelWindow {
        id: notifPanel
        readonly property real notifW: Math.round(340 * UIScale.value)

        WlrLayershell.layer: WlrLayer.Overlay
        anchors {
            top: true
            right: true
        }
        exclusiveZone: 0
        implicitWidth: notifW + 140
        implicitHeight: 600
        color: "transparent"
        visible: NotifServer.count > 0

        Column {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 70
            anchors.rightMargin: 16
            spacing: 8
            width: notifPanel.notifW

            Repeater {
                model: NotifServer.notifications
                delegate: NotifItem {
                    required property var modelData
                    notification: modelData
                    width: parent.width
                }
            }
        }
    }
}
