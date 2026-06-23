import "../Bar"

BarButton {
    icon: "󰌌"
    active: KeybindService.popupOpen
    onClicked: KeybindService.popupOpen = !KeybindService.popupOpen
}
