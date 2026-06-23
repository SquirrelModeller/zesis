import QtQuick
import "../../"

Item {
    id: root
    implicitWidth: Math.round(30 * UIScale.value)
    implicitHeight: Math.round(30 * UIScale.value)

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton)
                RecordService.startRegion();
            else
                RecordService.toggle();
        }
    }

    Text {
        id: icon
        anchors.centerIn: parent
        text: RecordService.recording ? "󰑈" : "󰻃"
        font.pixelSize: Math.round(15 * UIScale.value)
        color: RecordService.recording ? "#e05555" : (ma.containsMouse ? Colors.accent : Colors.text)
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }
    }

    SequentialAnimation {
        running: RecordService.recording
        loops: Animation.Infinite
        onStopped: icon.opacity = 1.0
        NumberAnimation {
            target: icon
            property: "opacity"
            to: 0.35
            duration: 700
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: icon
            property: "opacity"
            to: 1.0
            duration: 700
            easing.type: Easing.InOutSine
        }
    }
}
