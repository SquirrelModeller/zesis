import QtQuick 2.15
import Quickshell.Hyprland
import "./visual/Theme.js" as Theme

Rectangle {
    color: "transparent"
    width: textElement.implicitWidth
    height: textElement.height

    Text {
        id: textElement
        property string lastEventText: ""

        anchors.centerIn: parent
        text: lastEventText
        color: "white"
        font.pixelSize: Theme.textSizeNormal
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
