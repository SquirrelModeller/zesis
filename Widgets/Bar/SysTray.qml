pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import "../../"
import "../Keybinds"

Rectangle {
    id: root

    property bool candleLit: false
    property bool wantsThemeSwitcher: false
    property real themeCenterX: 0
    property bool wantsSound: false
    property real soundCenterX: 0

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
                color: root.wantsThemeSwitcher ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15) : themeBtnHover.containsMouse ? Colors.surfaceHigh : "transparent"
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
                    root.themeCenterX = themeBtn.mapToItem(null, themeBtn.width / 2, 0).x
                    root.wantsThemeSwitcher = !root.wantsThemeSwitcher
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

            readonly property real _vol: Pipewire.defaultAudioSink?.audio?.volume ?? 0
            readonly property bool _muted: Pipewire.defaultAudioSink?.audio?.muted ?? false
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
                color: root.wantsSound ? Colors.withAlpha(Colors.accent, 0.15) : volHover.containsMouse ? Colors.surfaceHigh : "transparent"
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
                color: root.wantsSound ? Colors.accent : Colors.text
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
                    root.soundCenterX = volBtn.mapToItem(null, volBtn.width / 2, 0).x;
                    root.wantsSound = !root.wantsSound;
                }
                onWheel: function (w) {
                    var audio = Pipewire.defaultAudioSink?.audio;
                    if (!audio)
                        return;
                    audio.volume = Math.max(0, Math.min(1.5, audio.volume + w.angleDelta.y / 1200.0));
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
