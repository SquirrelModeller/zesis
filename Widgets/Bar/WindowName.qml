import QtQuick
import Quickshell.Hyprland
import "../../"

Rectangle {
    color: "transparent"
    width: textElement.implicitWidth
    height: textElement.height

    Text {
        id: textElement
        property string lastEventText: ""

        anchors.centerIn: parent
        text: lastEventText
        color: Colors.text
        font.pixelSize: 20
        font.bold: true

        function updateEventText(newText) {
            lastEventText = newText;
        }

        Connections {
            target: Hyprland

            function onRawEvent(event) {
                if (event.name.toString() === "activewindow") {
                    textElement.updateEventText(event.data.toString().replace(/^[^,]*,/, ""));
                }
            }
        }
    }
}
