import QtQuick
import "../../"

Item {
    id: root
    property bool checked: false
    property color knobColor: Colors.bg
    signal toggled

    implicitWidth: Math.round(42 * UIScale.value)
    implicitHeight: Math.round(24 * UIScale.value)

    readonly property real _margin: Math.round(3 * UIScale.value)
    readonly property real _knobSize: height - 2 * _margin

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Colors.accent : Colors.surfaceHigh
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }
    }

    Rectangle {
        width: root._knobSize
        height: root._knobSize
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - root._margin : root._margin
        color: root.knobColor
        Behavior on x {
            NumberAnimation {
                duration: Anim.fast
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
