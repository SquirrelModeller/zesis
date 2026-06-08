import QtQuick
import "../../"

Item {
    implicitWidth: 30
    implicitHeight: 30

    property string icon: ""
    property bool active: false
    signal clicked

    HoverHandler {
        id: hover
    }

    Text {
        anchors.centerIn: parent
        text: parent.icon
        font.pixelSize: 15
        color: (hover.hovered || active) ? Colors.accent : Colors.text
        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    TapHandler {
        onTapped: parent.clicked()
    }
}
