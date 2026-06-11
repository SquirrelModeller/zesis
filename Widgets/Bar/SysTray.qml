pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../../"
import "../Keybinds"
import "../Sound"
import "../ThemeSwitcher"
import "../Notifications"
import "../Config"
import "../WidgetHome"

Rectangle {
    id: root

    property bool candleLit: false

    signal lockRequested

    radius: 100
    color: Colors.barBg
    implicitWidth: row.implicitWidth + 24
    implicitHeight: 50

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: SystemTray.items
            delegate: TrayIcon {
                required property SystemTrayItem modelData
                item: modelData
            }
        }

        SysInfo {
            Layout.alignment: Qt.AlignVCenter
        }

        // Theme switcher button
        BarButton {
            id: themeBtn
            icon: "󰔯"
            active: themePopup.visible
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
            onClicked: themePopup.visible ? themePopup.close() : themePopup.open()

            PopupWindow {
                id: themePopup
                anchor.item: themeBtn
                anchor.rect.x: themeBtn.width / 2 - themePopup.implicitWidth / 2
                anchor.rect.y: themeBtn.height
                grabFocus: true
                visible: false
                color: "transparent"
                implicitWidth: 380
                implicitHeight: 520

                function open() {
                    if (!visible) {
                        themeContent.scale = 0;
                        themeContent.opacity = 0;
                        visible = true;
                    }
                    themeShowAnim.start();
                }

                function close() {
                    if (!visible)
                        return;
                    themeShowAnim.stop();
                    visible = false;
                }

                onVisibleChanged: {
                    if (!visible) {
                        themeContent.scale = 0;
                        themeContent.opacity = 0;
                    }
                }

                ParallelAnimation {
                    id: themeShowAnim
                    NumberAnimation {
                        target: themeContent
                        property: "scale"
                        to: 1
                        duration: 280
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.4
                    }
                    NumberAnimation {
                        target: themeContent
                        property: "opacity"
                        to: 1
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                Item {
                    id: themeContent
                    anchors.fill: parent
                    scale: 0
                    opacity: 0
                    transformOrigin: Item.Top

                    Loader {
                        anchors.fill: parent
                        active: themePopup.visible
                        sourceComponent: ThemeSwitcherPopup {}
                    }
                }
            }
        }

        // Keybind cheatsheet button
        BarButton {
            icon: "󰌌"
            active: KeybindService.popupOpen
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
            onClicked: KeybindService.popupOpen = !KeybindService.popupOpen
        }

        // Volume button
        BarButton {
            id: volBtn
            active: soundPopup.visible
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
            onClicked: soundPopup.visible ? soundPopup.close() : soundPopup.open()

            readonly property real _vol: AudioService.vol
            readonly property bool _muted: AudioService.muted
            icon: {
                if (_muted || _vol === 0)
                    return "󰝟";
                if (_vol < 0.33)
                    return "󰕿";
                if (_vol < 0.67)
                    return "󰖀";
                return "󰕾";
            }

            WheelHandler {
                onWheel: function (w) {
                    var audio = AudioService.sink?.audio;
                    if (!audio)
                        return;
                    audio.volume = Math.max(0, Math.min(1.5, audio.volume + w.angleDelta.y / 1200.0));
                }
            }

            PopupWindow {
                id: soundPopup
                anchor.item: volBtn
                anchor.rect.x: volBtn.width / 2 - soundPopup.implicitWidth / 2
                anchor.rect.y: volBtn.height
                grabFocus: true
                visible: false
                color: "transparent"
                implicitWidth: 300
                implicitHeight: 320

                function open() {
                    if (!visible) {
                        soundContent.scale = 0;
                        soundContent.opacity = 0;
                        visible = true;
                    }
                    soundShowAnim.start();
                }

                function close() {
                    if (!visible)
                        return;
                    soundShowAnim.stop();
                    visible = false;
                }

                onVisibleChanged: {
                    if (!visible) {
                        soundContent.scale = 0;
                        soundContent.opacity = 0;
                    }
                }

                ParallelAnimation {
                    id: soundShowAnim
                    NumberAnimation {
                        target: soundContent
                        property: "scale"
                        to: 1
                        duration: 280
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.4
                    }
                    NumberAnimation {
                        target: soundContent
                        property: "opacity"
                        to: 1
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                Item {
                    id: soundContent
                    anchors.fill: parent
                    scale: 0
                    opacity: 0
                    transformOrigin: Item.Top

                    Loader {
                        anchors.fill: parent
                        active: soundPopup.visible
                        sourceComponent: SoundPopup {}
                    }
                }
            }
        }

        // 1.3 - 2% CPU usage
        // CandleToggle {
        //     id: candle
        //     Layout.alignment: Qt.AlignVCenter
        //     Layout.leftMargin: 4
        //     onLitChanged: root.candleLit = lit
        // }

        // Notification history button
        BarButton {
            id: notifBtn
            icon: NotifServer.unreadCount > 0 ? "󰂜" : "󰂚"
            active: notifPopup.visible
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
            onClicked: notifPopup.visible ? notifPopup.close() : notifPopup.open()

            PopupWindow {
                id: notifPopup
                anchor.item: notifBtn
                anchor.rect.x: notifBtn.width / 2 - notifPopup.implicitWidth / 2
                anchor.rect.y: notifBtn.height
                grabFocus: true
                visible: false
                color: "transparent"
                implicitWidth: Math.round(340 * UIScale.value)
                implicitHeight: Math.round(480 * UIScale.value)

                function open() {
                    if (!visible) {
                        notifContent.scale = 0;
                        notifContent.opacity = 0;
                        visible = true;
                    }
                    notifShowAnim.start();
                    NotifServer.markRead();
                }

                function close() {
                    if (!visible)
                        return;
                    notifShowAnim.stop();
                    visible = false;
                }

                onVisibleChanged: {
                    if (!visible) {
                        notifContent.scale = 0;
                        notifContent.opacity = 0;
                    }
                }

                ParallelAnimation {
                    id: notifShowAnim
                    NumberAnimation {
                        target: notifContent
                        property: "scale"
                        to: 1
                        duration: 280
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.4
                    }
                    NumberAnimation {
                        target: notifContent
                        property: "opacity"
                        to: 1
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                Item {
                    id: notifContent
                    anchors.fill: parent
                    scale: 0
                    opacity: 0
                    transformOrigin: Item.Top

                    Loader {
                        anchors.fill: parent
                        active: notifPopup.visible
                        sourceComponent: NotifHistoryPopup {}
                    }
                }
            }
        }

        // Config button
        BarButton {
            id: configBtn
            icon: "󰒓"
            active: configPopup.visible
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
            onClicked: configPopup.visible ? configPopup.close() : configPopup.open()

            PopupWindow {
                id: configPopup
                anchor.item: configBtn
                anchor.rect.x: configBtn.width / 2 - configPopup.implicitWidth / 2
                anchor.rect.y: configBtn.height
                grabFocus: true
                visible: false
                color: "transparent"
                implicitWidth: Math.round(280 * UIScale.value)
                implicitHeight: Math.round(500 * UIScale.value)

                function open() {
                    if (!visible) {
                        configContent.scale = 0;
                        configContent.opacity = 0;
                        visible = true;
                    }
                    configShowAnim.start();
                }

                function close() {
                    if (!visible)
                        return;
                    configShowAnim.stop();
                    visible = false;
                }

                onVisibleChanged: {
                    if (!visible) {
                        configContent.scale = 0;
                        configContent.opacity = 0;
                    }
                }

                ParallelAnimation {
                    id: configShowAnim
                    NumberAnimation {
                        target: configContent
                        property: "scale"
                        to: 1
                        duration: 280
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.4
                    }
                    NumberAnimation {
                        target: configContent
                        property: "opacity"
                        to: 1
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                Item {
                    id: configContent
                    anchors.fill: parent
                    scale: 0
                    opacity: 0
                    transformOrigin: Item.Top

                    Loader {
                        anchors.fill: parent
                        active: configPopup.visible
                        sourceComponent: ConfigPopup {}
                    }
                }
            }
        }

        // Widget home
        BarButton {
            icon: ""
            active: WidgetHomeService.open
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
            onClicked: WidgetHomeService.open = !WidgetHomeService.open
        }

        // Lock button
        BarButton {
            icon: "󰌾"
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
            onClicked: root.lockRequested()
        }

        // 0.7% CPU usage
        Clock {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
        }
    }
}
