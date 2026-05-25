import QtQuick
import QtQuick.Controls.Fusion

Label {
    id: clock
    property var date: new Date()

    renderType: Text.NativeRendering
    font.pointSize: 20
    color: "white"

    Timer {
        running: true
        repeat: true
        interval: 1000

        onTriggered: clock.date = new Date()
    }

    text: {
        const hours = this.date.getHours().toString().padStart(2, '0');
        const minutes = this.date.getMinutes().toString().padStart(2, '0');
        return `${hours}:${minutes}`;
    }
}
