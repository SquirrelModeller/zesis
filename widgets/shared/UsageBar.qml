pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"

Rectangle {
    id: root
    property real value: 0.0

    Layout.fillWidth: true
    implicitHeight: Math.round(4 * UIScale.value)
    radius: Math.round(2 * UIScale.value)
    color: Colors.surfaceHigh

    // Smoothly handle updating the position of the slider on resize
    property real _animValue: value
    Behavior on _animValue {
        NumberAnimation {
            duration: Anim.fast
            easing.type: Easing.OutQuad
        }
    }

    Rectangle {
        width: parent.width * root._animValue
        height: parent.height
        radius: parent.radius
        color: root.value > 0.9 ? Qt.rgba(1, 0.35, 0.2, 1) : Colors.accent
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }
    }
}
