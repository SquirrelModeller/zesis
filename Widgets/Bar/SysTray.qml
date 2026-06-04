pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import "../../"

Rectangle {
    id: root

    property bool candleLit: false

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
