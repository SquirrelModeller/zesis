import QtQuick
import "../bar"

// Bar atom
BarButton {
    icon: "󰌾"
    onClicked: LockService.triggerLock()
}
