import QtQuick
import Quickshell.Io

Rectangle {
    id: sysinfo
    width: parent.height * 0.8
    height: parent.height * 0.8
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
        property real arcLength: 0

        onPaint: {
            var ctx = canvas.getContext('2d');
            ctx.clearRect(0, 0, canvas.width, canvas.height);

            ctx.strokeStyle = "white";
            ctx.lineWidth = parent.height / 8;

            ctx.beginPath();
            ctx.arc(canvas.width / 2, canvas.height / 2, (parent.width / 2) - ctx.lineWidth / 2, 0, Math.PI * 2 * canvas.arcLength, false);
            ctx.stroke();
        }
    }

    Process {
        running: true
        command: ["systeminfo-cpu-ram-stats"]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(" ");
                if (parts.length === 2) {
                    let cpu = parseFloat(parts[0]);
                    let ram = parseFloat(parts[1]);

                    canvas.arcLength = Math.min(Math.max(cpu / 100, 0.0), 1.0);
                    canvas.requestPaint();
                }
            }
        }
    }
}
