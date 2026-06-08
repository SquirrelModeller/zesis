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
        Item {
            id: themeBtn
            implicitWidth: 30
            implicitHeight: 30
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: themePopup.visible ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15) : themeBtnHover.containsMouse ? Colors.surfaceHigh : "transparent"
                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
            }

            // Half-filled circle icon representing theme switching
            Item {
                anchors.centerIn: parent
                width: 16
                height: 16

                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: Colors.text
                    opacity: 0.9
                }
                Rectangle {
                    anchors.right: parent.right
                    width: 8
                    height: 16
                    color: Colors.bg
                }
            }

            MouseArea {
                id: themeBtnHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (themePopup.visible)
                        themePopup.close();
                    else
                        themePopup.open();
                }
            }

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
        Item {
            implicitWidth: 30
            implicitHeight: 30
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: KeybindService.popupOpen ? Colors.withAlpha(Colors.accent, 0.15) : kbHover.containsMouse ? Colors.surfaceHigh : "transparent"
                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "󰌌"
                font.pixelSize: 15
                color: KeybindService.popupOpen ? Colors.accent : Colors.text
                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
            }

            MouseArea {
                id: kbHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: KeybindService.popupOpen = !KeybindService.popupOpen
            }
        }

        // Volume button
        Item {
            id: volBtn
            implicitWidth: 30
            implicitHeight: 30
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4

            readonly property real _vol: AudioService.vol
            readonly property bool _muted: AudioService.muted
            readonly property string _icon: {
                if (_muted || _vol === 0)
                    return "󰝟";
                if (_vol < 0.33)
                    return "󰕿";
                if (_vol < 0.67)
                    return "󰖀";
                return "󰕾";
            }

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: soundPopup.visible ? Colors.withAlpha(Colors.accent, 0.15) : volHover.containsMouse ? Colors.surfaceHigh : "transparent"
                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: volBtn._icon
                font.pixelSize: 15
                color: soundPopup.visible ? Colors.accent : Colors.text
                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
            }

            MouseArea {
                id: volHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (soundPopup.visible)
                        soundPopup.close();
                    else
                        soundPopup.open();
                }
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
        Item {
            implicitWidth: 30
            implicitHeight: 30
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: lockHover.containsMouse ? Colors.surfaceHigh : "transparent"
                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "🔓"
                font.pixelSize: 15
                opacity: lockHover.containsMouse ? 0 : 1
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "🔒"
                font.pixelSize: 15
                opacity: lockHover.containsMouse ? 1 : 0
                scale: lockHover.containsMouse ? 1.0 : 0.7
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutBack
                    }
                }
            }

            MouseArea {
                id: lockHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.lockRequested()
            }
        }

        // 0.7% CPU usage
        Clock {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
        }
    }
}
