import QtQuick
import "../../"

Item {
    implicitWidth: visible ? Math.round(30 * UIScale.value) : 0
    implicitHeight: visible ? Math.round(30 * UIScale.value) : 0

    property string icon: ""
    property bool active: false
    signal clicked

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: parent.clicked()
    }

    Text {
        anchors.centerIn: parent
        text: parent.icon
        font.pixelSize: Math.round(15 * UIScale.value)
        color: (mouseArea.containsMouse || active) ? Colors.accent : Colors.text
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }
    }
}
