import QtQuick
import "../bar"

// Bar atom
BarButton {
    icon: "󰘮"
    active: SettingsWindowService.windowOpen
    onClicked: SettingsWindowService.windowOpen ? SettingsWindowService.requestClose() : SettingsWindowService.openPage("appearance")
}
