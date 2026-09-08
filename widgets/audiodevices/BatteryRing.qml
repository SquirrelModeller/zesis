pragma ComponentBehavior: Bound
import QtQuick
import "../../"

// Circular battery gauge
Item {
    id: root

    property int level: 0
    property bool charging: false
    property bool dim: false
    property string caption: ""
    property real diameter: Math.round(58 * UIScale.value)
    property real ringWidth: Math.max(3, Math.round(root.diameter * 0.11))

    readonly property color fillColor: {
        if (root.charging)
            return Colors.accent;
        if (root.level <= 15)
            return "#e05c5c";
        if (root.level <= 30)
            return "#e0a85c";
        return Colors.accent;
    }
    property color trackColor: Colors.surfaceHigh

    implicitWidth: root.diameter
    implicitHeight: root.diameter + (root.caption !== "" ? captionText.implicitHeight + Math.round(4 * UIScale.value) : 0)

    opacity: root.dim ? 0.4 : 1.0
    Behavior on opacity {
        NumberAnimation {
            duration: Anim.fast
        }
    }

    property real _shown: 0
    Component.onCompleted: root._shown = root.level
    onLevelChanged: root._shown = root.level
    Behavior on _shown {
        NumberAnimation {
            duration: Anim.slow
            easing.type: Easing.OutCubic
        }
    }

    onFillColorChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()
    on_ShownChanged: canvas.requestPaint()
    onDiameterChanged: canvas.requestPaint()
    onRingWidthChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        width: root.diameter
        height: root.diameter
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            var cx = width / 2;
            var cy = height / 2;
            var r = Math.min(width, height) / 2 - root.ringWidth / 2 - 1;
            ctx.lineWidth = root.ringWidth;
            ctx.lineCap = "round";

            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.strokeStyle = root.trackColor;
            ctx.stroke();

            var frac = Math.max(0, Math.min(100, root._shown)) / 100;
            if (frac <= 0)
                return;
            var start = -Math.PI / 2;
            ctx.beginPath();
            ctx.arc(cx, cy, r, start, start + frac * 2 * Math.PI);
            ctx.strokeStyle = root.fillColor;
            ctx.stroke();
        }
    }

    Text {
        anchors.centerIn: canvas
        text: root.charging ? "󱐋" : root.level
        color: root.charging ? Colors.accent : Colors.text
        font.pixelSize: root.charging ? Math.round(root.diameter * 0.4) : Math.round(root.diameter * 0.32)
        font.weight: Font.DemiBold
    }

    Text {
        id: captionText
        visible: root.caption !== ""
        text: root.caption
        anchors.top: canvas.bottom
        anchors.topMargin: Math.round(4 * UIScale.value)
        anchors.horizontalCenter: parent.horizontalCenter
        color: Colors.textDim
        font.pixelSize: UIScale.fontTiny
        font.weight: Font.Medium
    }
}
