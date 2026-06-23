pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "Widgets/Bar"
import "Widgets/WorkspaceIndicator"
import "Widgets/Music"
import "Widgets/Notifications"
import "Widgets/LockScreen"
import "Widgets/Keybinds"
import "Widgets/AppSwitcher"
import "Widgets/Shared"
import "Widgets/WidgetHome"
import "Widgets/Polkit"
import "Widgets/Display"
import "Widgets/Calendar"
import "Widgets/Home"
import "Widgets/Sound"
import "Widgets/AirPods"

Scope {
    // Singletons instantiated at startup for startup-apply logic
    property string _displayInit: DisplayService.monitorName
    property var _calInit: CalendarService.events

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
                anchors {
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    rightMargin: 20
                    topMargin: 10
                }
                spacing: 0
                layoutDirection: Qt.RightToLeft

                SysTray {
                    id: trayWidget
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

    PolkitAuth {}

    FullscreenOverlay {
        id: keybindOverlay
        maxContentWidth: 1100
        maxContentHeight: 820
        content: Component {
            Keybinds {}
        }

        property bool _kbOpen: KeybindService.popupOpen
        on_KbOpenChanged: _kbOpen ? open() : close()

        onVisibleChanged: if (!visible)
            KeybindService.popupOpen = false
        onDimmerTapped: KeybindService.popupOpen = false
        onContentLoaded: item => item.focusSearch()
    }

    IpcHandler {
        target: "keybinds"
        function toggle() {
            KeybindService.popupOpen = !KeybindService.popupOpen;
        }
    }

    PanelWindow {
        id: homeOverlay

        readonly property int panelWidth: Math.round(1200 * UIScale.value)
        readonly property int panelHeight: Math.round(760 * UIScale.value)

        WlrLayershell.namespace: "zesis:homePanel"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        exclusiveZone: -1
        color: "transparent"

        anchors {
            top: true
            left: true
        }
        margins {
            top: Math.round((screen.height - panelHeight) / 2)
            left: Math.round((screen.width - panelWidth) / 2)
        }

        implicitWidth: panelWidth
        implicitHeight: panelHeight

        visible: HomePanelService.open
        onVisibleChanged: if (visible)
            homePanel.forceActiveFocus()

        HomePanel {
            id: homePanel
            anchors.fill: parent
        }
    }

    IpcHandler {
        target: "home"
        function toggle() {
            HomePanelService.open = !HomePanelService.open;
        }
    }

    FullscreenOverlay {
        id: appSwitcherOverlay
        dimmerOpacity: 0.60
        dimmerColor: "#0a0806"
        initialScale: 0.94
        showOvershoot: 1.1
        content: Component {
            AppSwitcher {}
        }

        property bool _asOpen: AppSwitcherService.open
        on_AsOpenChanged: _asOpen ? open() : close()

        onVisibleChanged: if (!visible)
            AppSwitcherService.open = false
        onDimmerTapped: AppSwitcherService.confirm()
        onContentLoaded: item => item.forceActiveFocus()
    }

    IpcHandler {
        target: "appswitcher"
        function cycle() {
            AppSwitcherService.mode === 1 ? AppSwitcherService.cycleWorkspaceForward() : AppSwitcherService.cycleForward();
        }
        function back() {
            AppSwitcherService.mode === 1 ? AppSwitcherService.cycleWorkspaceBack() : AppSwitcherService.cycleBack();
        }
        function confirm() {
            AppSwitcherService.mode === 1 ? AppSwitcherService.confirmWorkspace() : AppSwitcherService.confirm();
        }
        function cancel() {
            AppSwitcherService.cancel();
        }
    }

    WidgetHomeSidebar {}

    VolumeOsd {}

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
