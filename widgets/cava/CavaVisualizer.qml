pragma ComponentBehavior: Bound

import QtQuick
import "./"
import "../../"
import "../desktop"

// Desktop widget
// Live audio using cava. Adjusts automatically based on width and height.
Item {
    id: root

    // Single mono mix on left and right channels
    property string channel: "average"

    readonly property var _bars: channel === "left" ? CavaService.barsLeft : channel === "right" ? CavaService.barsRight : CavaService.bars

    implicitWidth: Math.round(240 * UIScale.value)
    implicitHeight: Math.round(80 * UIScale.value)

    // Start hidden
    opacity: 0

    Component.onCompleted: {
        CavaService.acquire(root.channel);
        root._checkActivity();
    }
    Component.onDestruction: CavaService.release(root.channel)

    // Fades out the widget when no audio is playing
    Timer {
        id: hideTimer
        interval: 5000
        repeat: false
        onTriggered: root._hide()
    }

    NumberAnimation {
        id: revealAnim
        target: root
        property: "opacity"
        to: 1
        duration: Anim.slow
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Anim.emphasizedDecel
    }

    NumberAnimation {
        id: hideAnim
        target: root
        property: "opacity"
        to: 0
        duration: Anim.slow
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Anim.emphasizedAccel
        onStopped: if (root._autoHidden)
            root._loadersActive = false
    }

    property bool _autoHidden: true
    // Teardown canvas or shadereffect once fade-out is complete
    property bool _loadersActive: false

    // Once teardown is complete, we can downsize to a 1x1 to save on VRAM
    readonly property bool wantsMinimalSize: root._autoHidden && !root._loadersActive

    function _reveal() {
        root._autoHidden = false;
        root._loadersActive = true;
        hideAnim.stop();
        revealAnim.start();
    }

    function _hide() {
        root._autoHidden = true;
        revealAnim.stop();
        hideAnim.start();
    }

    function _checkActivity() {
        if (!CavaService.cavaAvailable) {
            hideTimer.stop();
            root._reveal();
            return;
        }
        if (!CavaSettings.autoHide || DesktopWidgetStore.configMode) {
            hideTimer.stop();
            root._reveal();
            return;
        }
        var bars = root._bars;
        var loud = false;
        for (var i = 0; i < bars.length; i++) {
            if (bars[i] > 0.02) {
                loud = true;
                break;
            }
        }
        if (loud) {
            root._reveal();
            hideTimer.restart();
        } else if (!root._autoHidden && !hideTimer.running) {
            // Hide after overlay toggle
            hideTimer.restart();
        }
    }

    Connections {
        target: DesktopWidgetStore
        function onConfigModeChanged() {
            root._checkActivity();
        }
    }

    onWidthChanged: if (cpuLoader.item)
        cpuLoader.item.requestPaint()
    onHeightChanged: if (cpuLoader.item)
        cpuLoader.item.requestPaint()

    Connections {
        target: CavaService
        function onCavaAvailableChanged() {
            root._checkActivity();
        }
        function onBarsChanged() {
            if (root.channel === "average") {
                if (cpuLoader.item)
                    cpuLoader.item.requestPaint();
                root._checkActivity();
            }
        }
        function onBarsLeftChanged() {
            if (root.channel === "left") {
                if (cpuLoader.item)
                    cpuLoader.item.requestPaint();
                root._checkActivity();
            }
        }
        function onBarsRightChanged() {
            if (root.channel === "right") {
                if (cpuLoader.item)
                    cpuLoader.item.requestPaint();
                root._checkActivity();
            }
        }
    }
    Connections {
        target: CavaSettings
        function onOrientationsChanged() {
            if (cpuLoader.item)
                cpuLoader.item.requestPaint();
        }
        function onStyleChanged() {
            if (cpuLoader.item)
                cpuLoader.item.requestPaint();
        }
        function onFlipsChanged() {
            if (cpuLoader.item)
                cpuLoader.item.requestPaint();
        }
        function onBeziersChanged() {
            if (cpuLoader.item)
                cpuLoader.item.requestPaint();
        }
        function onAutoHideChanged() {
            root._checkActivity();
        }
    }

    Loader {
        id: cpuLoader
        anchors.fill: parent
        active: root._loadersActive && CavaSettings.renderer !== "gpu"
        sourceComponent: canvasComponent
        onLoaded: item.requestPaint()
    }

    Loader {
        anchors.fill: parent
        active: root._loadersActive && CavaSettings.renderer === "gpu"
        sourceComponent: gpuComponent
    }

    Component {
        id: gpuComponent
        CavaGpuVisualizer {
            bars: root._bars
            channel: root.channel
        }
    }

    // Cava binary not found
    Rectangle {
        anchors.centerIn: parent
        visible: !CavaService.cavaAvailable
        width: Math.min(parent.width - 16, 280)
        height: missingColumn.implicitHeight + 16
        radius: 6
        color: Colors.withAlpha(Colors.error, 0.12)
        border.color: Colors.error
        border.width: 1

        Column {
            id: missingColumn
            anchors.centerIn: parent
            width: parent.width - 16
            spacing: 4

            Text {
                width: parent.width
                text: I18n.t("desktop.cavaMissingTitle")
                color: Colors.error
                font.bold: true
                font.pixelSize: UIScale.fontSmall
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
            Text {
                width: parent.width
                text: I18n.t("desktop.cavaMissingDetail")
                color: Colors.withAlpha(Colors.error, 0.8)
                font.pixelSize: UIScale.fontTiny
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }

    Component {
        id: canvasComponent
        Canvas {
            id: canvas

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                var bars = root._bars;
                var n = bars.length;
                if (n === 0)
                    return;
                if (CavaSettings.flipFor(root.channel))
                    bars = bars.slice().reverse();

                var gap = Math.max(1, Math.round(2 * UIScale.value));
                var orientation = CavaSettings.orientationFor(root.channel);
                var vertical = orientation === "left" || orientation === "right";
                var pitch = Math.max(1, ((vertical ? height : width) - gap * (n - 1)) / n);

                if (CavaSettings.style === "area")
                    canvas._paintArea(ctx, bars, n, orientation, vertical);
                else
                    canvas._paintBars(ctx, bars, n, orientation, vertical, pitch, gap);
            }

            function _bezOff(t) {
                var b = CavaSettings.bezierFor(root.channel);
                if (!b.enabled)
                    return 0;
                var omt = 1 - t;
                return omt * omt * omt * b.y0 + 3 * omt * omt * t * b.y1 + 3 * omt * t * t * b.y2 + t * t * t * b.y3;
            }

            function _bezFit() {
                var b = CavaSettings.bezierFor(root.channel);
                return b.enabled && b.fit;
            }

            function _paintBars(ctx, bars, n, orientation, vertical, pitch, gap) {
                ctx.fillStyle = Colors.accent;
                var barExtent = vertical ? width : height;
                var fit = canvas._bezFit();
                for (var i = 0; i < n; i++) {
                    var off = canvas._bezOff(n > 1 ? i / (n - 1) : 0) * barExtent;
                    var base = fit ? Math.max(0, Math.min(barExtent, off)) : off;
                    var avail = fit ? (barExtent - base) : barExtent;
                    var len = Math.max(1, bars[i] * avail);
                    switch (orientation) {
                    case "top":
                        ctx.fillRect(i * (pitch + gap), base, pitch, len);
                        break;
                    case "left":
                        ctx.fillRect(base, i * (pitch + gap), len, pitch);
                        break;
                    case "right":
                        ctx.fillRect(width - base - len, i * (pitch + gap), len, pitch);
                        break;
                    default:
                        // "bottom"
                        ctx.fillRect(i * (pitch + gap), height - base - len, pitch, len);
                    }
                }
            }

            function _paintArea(ctx, bars, n, orientation, vertical) {
                var pts = new Array(n);
                var baseline;
                var extent = vertical ? height : width;
                var step = n > 1 ? extent / (n - 1) : 0;
                var barExtent = vertical ? width : height;
                var fit = canvas._bezFit();
                function _room(o) {
                    return fit ? Math.max(0, Math.min(barExtent, o)) : o;
                }
                for (var i = 0; i < n; i++) {
                    var cross = i * step;
                    var off = _room(canvas._bezOff(n > 1 ? i / (n - 1) : 0) * barExtent);
                    var len = Math.max(0, bars[i] * (fit ? (barExtent - off) : barExtent));
                    var along;
                    switch (orientation) {
                    case "top":
                        along = len + off;
                        baseline = 0;
                        break;
                    case "left":
                        along = len + off;
                        baseline = 0;
                        break;
                    case "right":
                        along = width - off - len;
                        baseline = width;
                        break;
                    default:
                        // "bottom"
                        along = height - off - len;
                        baseline = height;
                    }
                    pts[i] = vertical ? {
                        x: along,
                        y: cross
                    } : {
                        x: cross,
                        y: along
                    };
                }

                var off0 = _room(canvas._bezOff(0) * barExtent);
                var offN = _room(canvas._bezOff(1) * barExtent);
                var edge0 = orientation === "top" || orientation === "left" ? off0 : baseline - off0;
                var edgeN = orientation === "top" || orientation === "left" ? offN : baseline - offN;
                var baseStart = vertical ? {
                    x: edge0,
                    y: pts[0].y
                } : {
                    x: pts[0].x,
                    y: edge0
                };
                var baseEnd = vertical ? {
                    x: edgeN,
                    y: pts[n - 1].y
                } : {
                    x: pts[n - 1].x,
                    y: edgeN
                };

                var gradient = vertical ? ctx.createLinearGradient(baseline, 0, (orientation === "right" ? 0 : width), 0) : ctx.createLinearGradient(0, baseline, 0, (orientation === "top" ? height : 0));
                gradient.addColorStop(0, Colors.withAlpha(Colors.accent, 0.08));
                gradient.addColorStop(1, Colors.withAlpha(Colors.accent, 0.75));

                ctx.beginPath();
                ctx.moveTo(baseStart.x, baseStart.y);
                ctx.lineTo(pts[0].x, pts[0].y);
                for (var j = 1; j < n; j++) {
                    var mid = {
                        x: (pts[j - 1].x + pts[j].x) / 2,
                        y: (pts[j - 1].y + pts[j].y) / 2
                    };
                    ctx.quadraticCurveTo(pts[j - 1].x, pts[j - 1].y, mid.x, mid.y);
                }
                ctx.lineTo(pts[n - 1].x, pts[n - 1].y);
                ctx.lineTo(baseEnd.x, baseEnd.y);
                ctx.closePath();
                ctx.fillStyle = gradient;
                ctx.fill();

                ctx.beginPath();
                ctx.moveTo(pts[0].x, pts[0].y);
                for (var k = 1; k < n; k++) {
                    var m = {
                        x: (pts[k - 1].x + pts[k].x) / 2,
                        y: (pts[k - 1].y + pts[k].y) / 2
                    };
                    ctx.quadraticCurveTo(pts[k - 1].x, pts[k - 1].y, m.x, m.y);
                }
                ctx.lineTo(pts[n - 1].x, pts[n - 1].y);
                ctx.strokeStyle = Colors.accent;
                ctx.lineWidth = Math.max(1, Math.round(1.5 * UIScale.value));
                ctx.lineJoin = "round";
                ctx.stroke();
            }
        }
    }
}
