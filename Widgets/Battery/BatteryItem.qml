import QtQuick
import "../../"
import "../Bar"
import "../Shared"

BarButton {
    id: root
    icon: BatteryService.icon
    active: popup.visible
    visible: BatteryService.available
    onClicked: popup.visible ? popup.close() : popup.open()

    AnimatedPopup {
        id: popup
        anchorItem: root
        implicitWidth: Math.round(280 * UIScale.value)
        implicitHeight: Math.round(300 * UIScale.value)
        content: Component { Battery {} }
    }
}
