pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "widgets/bar"
import "widgets/notifications"
import "widgets/lockscreen"
import "widgets/keybinds"
import "widgets/appswitcher"
import "widgets/themecycler"
import "widgets/power"
import "widgets/shared"
import "widgets/shared/panels"
import "widgets/widgethome"
import "widgets/polkit"
import "widgets/display"
import "widgets/calendar"
import "widgets/diaspora"
import "widgets/home"
import "widgets/settings"
import "widgets/sound"
import "widgets/pumppanel"
import "widgets/clock"
import "widgets/desktop"
// These imports are needed for BarItemsService to function correctly
import "widgets/brightness"
import "widgets/mic"
import "widgets/battery"
import "widgets/record"
import "widgets/taskbar"
import "widgets/music"

Scope {
    // Singletons instantiated at startup for startup-apply logic
    property string _displayInit: DisplayService.monitorName
    property var _calInit: CalendarService.events
    property bool _locationSharingInit: LocationSharingService.ready

    Variants {
        // empty = all monitors
        model: BarConfig.monitors.length === 0 ? Quickshell.screens : Quickshell.screens.filter(s => BarConfig.monitors.includes(s.name))
        delegate: PanelWindow {
            id: root

            required property ShellScreen modelData

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.margins {
                top: BarConfig.side === "top" ? BarConfig.edgeGap : 0
                bottom: BarConfig.side === "bottom" ? BarConfig.edgeGap : 0
                left: BarConfig.side === "left" ? BarConfig.edgeGap : 0
                right: BarConfig.side === "right" ? BarConfig.edgeGap : 0
            }
            screen: modelData

            // Strip = pill thickness on the short axis, full-edge span on the long axis.
            // This avoids any centering math, edgeGap is the only outer-gap knob.
            implicitHeight: BarConfig.isVertical ? 0 : BarConfig.barThickness
            implicitWidth: BarConfig.isVertical ? BarConfig.barThickness : 0

            anchors {
                top: BarConfig.side !== "bottom"
                bottom: BarConfig.side !== "top"
                left: BarConfig.side !== "right"
                right: BarConfig.side !== "left"
            }

            color: "transparent"

            BarZoneRow {
                anchors.fill: parent
                screenName: root.modelData.name
            }

            Connections {
                target: LockService
                function onLockRequested() {
                    lockScreen.triggerLock();
                }
            }
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

    // PumpPanel {}
    // ValvePanel {}
    // WheelTest {}

    RequestableAppWindow {
        id: homeWindow
        windowService: HomeWindowService
        windowTitle: I18n.t("home.title") + " - zesis"
        content: Component {
            HomeShell {}
        }
    }

    IpcHandler {
        target: "home"
        function toggle() {
            HomeWindowService.requestToggle();
        }
        function open() {
            homeWindow.active = true;
        }
        function close() {
            HomeWindowService.requestClose();
        }
        function openPage(pageId: string) {
            HomeWindowService.openPage(pageId);
        }
        function openPageTab(pageId: string, subTabId: string) {
            HomeWindowService.openPageTab(pageId, subTabId);
        }
        function search(query: string) {
            HomeWindowService.openSearch(query);
        }
    }

    RequestableAppWindow {
        id: settingsWindow
        windowService: SettingsWindowService
        windowTitle: I18n.t("settings_chrome.title") + " - zesis"
        content: Component {
            SettingsShell {}
        }
    }

    IpcHandler {
        target: "settingswindow"
        function toggle() {
            SettingsWindowService.requestToggle();
        }
        function open() {
            settingsWindow.active = true;
        }
        function close() {
            SettingsWindowService.requestClose();
        }
        function openPage(pageId: string) {
            SettingsWindowService.openPage(pageId);
        }
        function openPageTab(pageId: string, subTabId: string) {
            SettingsWindowService.openPageTab(pageId, subTabId);
        }
        function search(query: string) {
            SettingsWindowService.openSearch(query);
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

    FullscreenOverlay {
        id: themeCyclerOverlay
        dimmerOpacity: 0.60
        dimmerColor: "#0a0806"
        initialScale: 0.94
        showOvershoot: 1.1
        content: Component {
            ThemeCycler {}
        }

        property bool _tcOpen: ThemeCyclerService.open
        on_TcOpenChanged: _tcOpen ? open() : close()

        onVisibleChanged: if (!visible)
            ThemeCyclerService.open = false
        onDimmerTapped: ThemeCyclerService.confirm()
        onContentLoaded: item => item.forceActiveFocus()
    }

    IpcHandler {
        target: "themecycler"
        function cycle() {
            ThemeCyclerService.cycleForward();
        }
        function back() {
            ThemeCyclerService.cycleBack();
        }
        function confirm() {
            ThemeCyclerService.confirm();
        }
        function cancel() {
            ThemeCyclerService.cancel();
        }
    }

    FullscreenOverlay {
        id: powerOverlay
        maxContentWidth: 520
        maxContentHeight: 200
        content: Component {
            PowerMenu {
                onCloseRequested: powerOverlay.close()
            }
        }

        onDimmerTapped: powerOverlay.close()
        onContentLoaded: item => item.focusMenu()
    }

    IpcHandler {
        target: "power"
        function toggle() {
            powerOverlay.visible ? powerOverlay.close() : powerOverlay.open();
        }
    }

    WidgetHomeSidebar {}

    VolumeOsd {}

    MicOsd {}

    // Desktop widgets
    IpcHandler {
        target: "desktop"
        function toggleConfig() {
            DesktopWidgetStore.configMode = !DesktopWidgetStore.configMode;
        }
    }

    DesktopConfigOverlay {}

    Instantiator {
        model: DesktopWidgetStore.enabledKeys
        delegate: DesktopWidget {
            required property string modelData
            storeKey: modelData
            content: DesktopWidgetCatalog.componentFor(modelData)
        }
    }

    // Notification toasts, top-right overlay, stacks below the bar
    PanelWindow {
        id: notifPanel
        readonly property real notifW: Math.round(340 * UIScale.value)

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: NotifServer.replyActive ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        anchors {
            top: true
            right: true
        }
        exclusiveZone: 0
        implicitWidth: notifW + 140
        implicitHeight: 600
        color: "transparent"
        visible: NotifServer.count > 0 && !NotifServer.muted

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
