pragma ComponentBehavior: Bound

import QtQuick
import "./"
import "../../"

Item {
    id: root

    required property var bars
    required property string channel

    readonly property int _orientationIndex: {
        var o = CavaSettings.orientationFor(root.channel);
        return o === "top" ? 1 : o === "left" ? 2 : o === "right" ? 3 : 0;
    }
    readonly property int _styleIndex: CavaSettings.style === "area" ? 1 : 0
    readonly property int _flip: CavaSettings.flipFor(root.channel) ? 1 : 0

    Canvas {
        id: dataCanvas
        width: Math.max(1, root.bars.length)
        height: 1
        visible: false

        property var barsData: root.bars
        onBarsDataChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            var bars = root.bars;
            var n = bars.length;
            for (var i = 0; i < n; i++) {
                var v = Math.max(0, Math.min(1, bars[i]));
                ctx.fillStyle = Qt.rgba(v, v, v, 1);
                ctx.fillRect(i, 0, 1, 1);
            }
            dataTexSource.scheduleUpdate();
        }
    }

    ShaderEffectSource {
        id: dataTexSource
        sourceItem: dataCanvas
        hideSource: true
        smooth: false
        live: false
    }

    ShaderEffect {
        id: shaderItem
        anchors.fill: parent

        property variant dataTex: dataTexSource
        property real itemWidth: width
        property real itemHeight: height
        property int barCount: root.bars.length
        property int styleMode: root._styleIndex
        property int orientation: root._orientationIndex
        property int flip: root._flip
        property real gapPx: Math.max(1, Math.round(2 * UIScale.value))
        property real lineWidthPx: Math.max(1, Math.round(1.5 * UIScale.value))
        property color accentColor: Colors.accent

        fragmentShader: "cavashader/cava.qsb"
    }

    // Warning for missing .qsb shader
    Rectangle {
        anchors.centerIn: parent
        visible: shaderItem.status === ShaderEffect.Error
        width: Math.min(parent.width - 16, 280)
        height: warningColumn.implicitHeight + 16
        radius: 6
        color: Colors.withAlpha(Colors.error, 0.12)
        border.color: Colors.error
        border.width: 1

        Column {
            id: warningColumn
            anchors.centerIn: parent
            width: parent.width - 16
            spacing: 4

            Text {
                width: parent.width
                text: I18n.t("desktop.cavaShaderFailedTitle")
                color: Colors.error
                font.bold: true
                font.pixelSize: UIScale.fontSmall
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
            Text {
                width: parent.width
                text: I18n.t("desktop.cavaShaderFailedDetail", [shaderItem.log !== "" ? "\n" + shaderItem.log : ""])
                color: Colors.withAlpha(Colors.error, 0.8)
                font.pixelSize: UIScale.fontTiny
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }
}
