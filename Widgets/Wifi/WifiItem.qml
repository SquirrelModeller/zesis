import QtQuick
import "../../"
import "../Bar"
import "../Shared"

BarButton {
    id: root
    icon: WifiService.barIcon()
    active: popup.visible
    visible: WifiService.showInBar
    onClicked: popup.visible ? popup.close() : popup.open()

    AnimatedPopup {
        id: popup
        anchorItem: root
        implicitWidth: Math.round(320 * UIScale.value)
        implicitHeight: Math.round(440 * UIScale.value)
        content: Component {
            Wifi {}
        }
    }
}
