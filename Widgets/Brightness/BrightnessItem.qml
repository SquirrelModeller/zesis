import QtQuick
import "../../"
import "../Bar"
import "../Shared"

BarButton {
    id: root
    icon: {
        var p = BrightnessService.percent;
        if (p >= 80)
            return "󰃠";
        if (p >= 40)
            return "󰃟";
        return "󰃞";
    }
    active: popup.visible
    visible: BrightnessService.available
    onClicked: popup.visible ? popup.close() : popup.open()

    WheelHandler {
        onWheel: function (w) {
            BrightnessService.adjust(w.angleDelta.y > 0 ? 5 : -5);
        }
    }

    AnimatedPopup {
        id: popup
        anchorItem: root
        implicitWidth: Math.round(280 * UIScale.value)
        implicitHeight: Math.round(200 * UIScale.value)
        content: Component {
            Brightness {}
        }
    }
}
