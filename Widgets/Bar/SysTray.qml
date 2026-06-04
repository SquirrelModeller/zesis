pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import "../../"
Rectangle {
    id: root

    property bool candleLit: false
    property bool wantsThemeSwitcher: false

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

        // Theme switcher button
        Item {
            implicitWidth: 30
            implicitHeight: 30
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: root.wantsThemeSwitcher
                    ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15)
                    : themeBtnHover.containsMouse ? Colors.surfaceHigh : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            // Half-filled circle icon representing theme switching
            Item {
                anchors.centerIn: parent
                width: 16; height: 16

                Rectangle {
                    width: 16; height: 16; radius: 8
                    color: Colors.text
                    opacity: 0.9
                }
                Rectangle {
                    anchors.right: parent.right
                    width: 8; height: 16
                    color: Colors.bg
                }
            }

            MouseArea {
                id: themeBtnHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.wantsThemeSwitcher = !root.wantsThemeSwitcher
            }
        }

        CandleToggle {
            id: candle
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
            onLitChanged: root.candleLit = lit
        }

        Clock {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
        }

    }
}
