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
import "../Home"
import "../Clock"

Rectangle {
    id: root

    property bool candleLit: false

    signal lockRequested

    radius: 100
    color: Colors.barBg
    implicitWidth: BarConfig.isVertical ? Math.round(50 * UIScale.value) : (layout.implicitWidth + Math.round(24 * UIScale.value))
    implicitHeight: BarConfig.isVertical ? (layout.implicitHeight + Math.round(24 * UIScale.value)) : Math.round(50 * UIScale.value)

    GridLayout {
        id: layout
        anchors.centerIn: parent
        rowSpacing: 4
        columnSpacing: 4
        rows: BarConfig.isVertical ? -1 : 1
        columns: BarConfig.isVertical ? 1 : -1

        Repeater {
            model: SystemTray.items
            delegate: TrayIcon {
                required property SystemTrayItem modelData
                item: modelData
            }
        }

        SysMonItem {
            Layout.alignment: Qt.AlignCenter
        }

        ThemeSwitcherItem {
            Layout.alignment: Qt.AlignCenter
        }

        KeybindsItem {
            Layout.alignment: Qt.AlignCenter
        }

        BluetoothItem {
            Layout.alignment: Qt.AlignCenter
        }

        AirPods {
            Layout.alignment: Qt.AlignCenter
        }

        WifiItem {
            Layout.alignment: Qt.AlignCenter
        }

        BrightnessItem {
            Layout.alignment: Qt.AlignCenter
        }

        SoundItem {
            Layout.alignment: Qt.AlignCenter
        }

        MicItem {
            Layout.alignment: Qt.AlignCenter
        }

        NotificationsItem {
            Layout.alignment: Qt.AlignCenter
        }

        ConfigItem {
            Layout.alignment: Qt.AlignCenter
        }

        BatteryItem {
            Layout.alignment: Qt.AlignCenter
        }

        RecordItem {
            Layout.alignment: Qt.AlignCenter
        }

        // Widget home
        BarButton {
            icon: ""
            active: HomePanelService.open
            Layout.alignment: Qt.AlignCenter
            onClicked: HomePanelService.open = !HomePanelService.open
        }

        // Lock button
        BarButton {
            icon: "󰌾"
            Layout.alignment: Qt.AlignCenter
            onClicked: root.lockRequested()
        }

        Clock {
            Layout.alignment: Qt.AlignCenter
        }
    }
}
