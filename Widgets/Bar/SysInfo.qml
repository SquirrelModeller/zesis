import QtQuick
import "../SysMon"

Rectangle {
    id: sysinfo

    implicitWidth: 40
    implicitHeight: 40
    color: "transparent"

    Text {
        text: "󰍛"
        font.pointSize: 15
        color: "white"
        anchors.centerIn: parent
    }

    Canvas {
        id: canvas
        width: parent.width
        height: parent.height

        readonly property real arcLength: SysMonService.cpu.percent / 100

        onArcLengthChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = canvas.getContext("2d");
            ctx.clearRect(0, 0, canvas.width, canvas.height);

            ctx.strokeStyle = "white";
            ctx.lineWidth = parent.height / 8;

            ctx.beginPath();
            ctx.arc(canvas.width / 2, canvas.height / 2, (parent.width / 2) - ctx.lineWidth / 2, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * canvas.arcLength, false);
            ctx.stroke();
        }
    }

    HoverHandler {
        id: hover
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: hover.hovered || SysMonService.popupOpen ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    TapHandler {
        onTapped: {
            SysMonService.popupCenterX = sysinfo.mapToItem(null, sysinfo.width / 2, 0).x
            SysMonService.popupOpen = !SysMonService.popupOpen
        }
    }
}
