import QtQuick
import "../bar"

// Bar atom
BarButton {
    icon: ""
    active: HomeWindowService.windowOpen
    onClicked: HomeWindowService.windowOpen ? HomeWindowService.requestClose() : HomeWindowService.openPage("home")
}
