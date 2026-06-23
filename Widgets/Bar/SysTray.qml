pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import "../../"
import "../ThemeSwitcher"
import "../Keybinds"
import "../Bluetooth"
import "../AirPods"
import "../Wifi"
import "../Brightness"
import "../Sound"
import "../Mic"
import "../Notifications"
import "../Config"
import "../Battery"
import "../Record"
import "../SysMon"
import "../WidgetHome"
import "../Clock"

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

        SysMon {
            Layout.alignment: Qt.AlignVCenter
        }

        ThemeSwitcherItem {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
        }

        KeybindsItem {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
        }

        BluetoothItem {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
        }

        AirPods {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
        }

        WifiItem {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
        }

        BrightnessItem {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
        }

        SoundItem {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
        }

        MicItem {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
        }

        NotificationsItem {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
        }

        ConfigItem {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
        }

        BatteryItem {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
        }

        RecordItem {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
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

        Clock {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
        }
    }
}
