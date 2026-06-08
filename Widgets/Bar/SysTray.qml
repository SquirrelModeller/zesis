pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../../"
import "../Keybinds"
import "../Sound"
import "../ThemeSwitcher"

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

        SysInfo {
            Layout.alignment: Qt.AlignVCenter
        }

        Repeater {
            model: SystemTray.items
            delegate: TrayIcon {
                required property SystemTrayItem modelData
                item: modelData
            }
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
