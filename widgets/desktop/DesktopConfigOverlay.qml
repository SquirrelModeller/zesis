pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Dialogs
import Quickshell
import Quickshell.Wayland
import "./"
import "../../"
import "../shared/inputs"
import "../globe2d"
import "../cava"

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "zesis:desktop:config"
    WlrLayershell.keyboardFocus: root._fileDialogOpen ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    exclusiveZone: -1
    color: "transparent"
    visible: DesktopWidgetStore.configMode
    onVisibleChanged: {
        if (!visible) {
            root.selectedKey = "";
            root._lastMovedKey = "";
            root._fileDialogOpen = false;
        }
    }

    property bool snapEnabled: true
    readonly property real snapThreshold: 20

    property bool skewSnapEnabled: true

    property string selectedKey: ""

    // Arrow key target
    property string _lastMovedKey: ""

    function _proxyForKey(key) {
        if (!key)
            return null;
        for (var i = 0; i < widgetRepeater.count; i++) {
            var o = widgetRepeater.itemAt(i);
            if (o && o.wKey === key)
                return o;
        }
        return null;
    }
    function _nudgeTarget() {
        return root._proxyForKey(root.selectedKey) || root._proxyForKey(root._lastMovedKey);
    }
    function _nudge(dx, dy) {
        var p = root._nudgeTarget();
        if (!p)
            return;
        var nx = Math.max(0, Math.min(1, p._nx + dx / Math.max(1, root.width - p.width)));
        var ny = Math.max(0, Math.min(1, p._ny + dy / Math.max(1, root.height - p.height)));
        DesktopWidgetStore.setPosCoalesced(p.wKey, nx, ny, "nudge:" + p.wKey);
        p._nx = nx;
        p._ny = ny;
        p.x = Qt.binding(() => p._nx * Math.max(1, root.width - p.width));
        p.y = Qt.binding(() => p._ny * Math.max(1, root.height - p.height));
        root._lastMovedKey = p.wKey;
    }

    component NudgeShortcut: Shortcut {
        property real dx: 0
        property real dy: 0
        autoRepeat: true
        enabled: !root._fileDialogOpen
        onActivated: root._nudge(dx, dy)
    }

    // Goes click-through while a portal file-picker is open so the native window
    // can receive pointer events (WlrLayer.Top would otherwise intercept them).
    property bool _fileDialogOpen: false
    Region {
        id: overlayInputRegion
        width: root._fileDialogOpen ? 0 : root.width
        height: root._fileDialogOpen ? 0 : root.height
    }
    mask: overlayInputRegion

    // Active alignment guides, set during drag, cleared on release.
    // undefined = hidden, a number = draw guide at that coordinate.
    property var _snapGuideX // vertical line (x snap)
    property var _snapGuideY // horizontal line (y snap)

    function _computeEdgeSnap(activeProxy, raw, axis) {
        var thr = root.snapThreshold;
        var extent = axis === "x" ? root.width : root.height;
        var candidates = [0, extent, extent / 2];

        for (var i = 0; i < widgetRepeater.count; i++) {
            var o = widgetRepeater.itemAt(i);
            if (o === null || o === activeProxy)
                continue;
            var start = axis === "x" ? o.x : o.y;
            var size = axis === "x" ? o.width : o.height;
            candidates.push(start, start + size, start + size / 2);
        }

        var best = raw, bestGuide = undefined, bestD = thr;
        for (var j = 0; j < candidates.length; j++) {
            var d = Math.abs(raw - candidates[j]);
            if (d < bestD) {
                bestD = d;
                best = candidates[j];
                bestGuide = candidates[j];
            }
        }

        return {
            value: best,
            guide: bestGuide
        };
    }

    // Returns { x, y, guideX, guideY } where guide* may be undefined.
    function _computeSnap(activeProxy, rawX, rawY) {
        var pW = activeProxy.width;
        var pH = activeProxy.height;
        var thr = root.snapThreshold;

        var xC = [
            {
                snapX: (root.width - pW) / 2,
                guideX: root.width / 2
            },
            {
                snapX: root.width / 2,
                guideX: root.width / 2
            },
            {
                snapX: root.width / 2 - pW,
                guideX: root.width / 2
            },
            {
                snapX: 0,
                guideX: 0
            },
            {
                snapX: root.width - pW,
                guideX: root.width
            },
        ];
        var yC = [
            {
                snapY: (root.height - pH) / 2,
                guideY: root.height / 2
            },
            {
                snapY: root.height / 2,
                guideY: root.height / 2
            },
            {
                snapY: root.height / 2 - pH,
                guideY: root.height / 2
            },
            {
                snapY: 0,
                guideY: 0
            },
            {
                snapY: root.height - pH,
                guideY: root.height
            },
        ];

        for (var i = 0; i < widgetRepeater.count; i++) {
            var o = widgetRepeater.itemAt(i);
            if (o === null || o === activeProxy)
                continue;
            var oX = o.x, oY = o.y, oW = o.width, oH = o.height;

            xC.push({
                snapX: oX,
                guideX: oX
            });
            xC.push({
                snapX: oX + oW - pW,
                guideX: oX + oW
            });
            xC.push({
                snapX: oX + oW / 2 - pW / 2,
                guideX: oX + oW / 2
            });
            xC.push({
                snapX: oX - pW,
                guideX: oX
            });
            xC.push({
                snapX: oX + oW,
                guideX: oX + oW
            });

            yC.push({
                snapY: oY,
                guideY: oY
            });
            yC.push({
                snapY: oY + oH - pH,
                guideY: oY + oH
            });
            yC.push({
                snapY: oY + oH / 2 - pH / 2,
                guideY: oY + oH / 2
            });
            yC.push({
                snapY: oY - pH,
                guideY: oY
            });
            yC.push({
                snapY: oY + oH,
                guideY: oY + oH
            });
        }

        var bX = rawX, bgX = undefined, bdX = thr;
        for (var j = 0; j < xC.length; j++) {
            var dx = Math.abs(rawX - xC[j].snapX);
            if (dx < bdX) {
                bdX = dx;
                bX = xC[j].snapX;
                bgX = xC[j].guideX;
            }
        }

        var bY = rawY, bgY = undefined, bdY = thr;
        for (var k = 0; k < yC.length; k++) {
            var dy = Math.abs(rawY - yC[k].snapY);
            if (dy < bdY) {
                bdY = dy;
                bY = yC[k].snapY;
                bgY = yC[k].guideY;
            }
        }

        return {
            x: bX,
            y: bY,
            guideX: bgX,
            guideY: bgY
        };
    }

    Shortcut {
        sequence: "Escape"
        enabled: !root._fileDialogOpen
        onActivated: DesktopWidgetStore.configMode = false
    }
    Shortcut {
        sequences: ["Ctrl+Z"]
        autoRepeat: false
        enabled: !root._fileDialogOpen
        onActivated: DesktopWidgetStore.undo()
    }
    Shortcut {
        sequences: ["Ctrl+Shift+Z", "Ctrl+Y"]
        autoRepeat: false
        enabled: !root._fileDialogOpen
        onActivated: DesktopWidgetStore.redo()
    }

    // Currently this is pixels, but we'll need them in factions later when
    // all widgets are fractional
    NudgeShortcut {
        sequence: "Left"
        dx: -1
    }
    NudgeShortcut {
        sequence: "Right"
        dx: 1
    }
    NudgeShortcut {
        sequence: "Up"
        dy: -1
    }
    NudgeShortcut {
        sequence: "Down"
        dy: 1
    }
    NudgeShortcut {
        sequence: "Shift+Left"
        dx: -10
    }
    NudgeShortcut {
        sequence: "Shift+Right"
        dx: 10
    }
    NudgeShortcut {
        sequence: "Shift+Up"
        dy: -10
    }
    NudgeShortcut {
        sequence: "Shift+Down"
        dy: 10
    }

    // Background dim
    Rectangle {
        anchors.fill: parent
        color: Colors.withAlpha(Colors.bg, 0.45)
    }

    // Widget proxies
    Repeater {
        id: widgetRepeater
        model: DesktopWidgetStore._widgets

        delegate: Item {
            id: proxy
            required property var modelData
            required property int index

            readonly property string wKey: modelData.key
            readonly property bool _selected: root.selectedKey === proxy.wKey

            readonly property bool _isCava: proxy.wKey === "cava" || proxy.wKey === "cava-left" || proxy.wKey === "cava-right"
            readonly property string _cavaChannel: proxy.wKey === "cava-left" ? "left" : proxy.wKey === "cava-right" ? "right" : "average"
            property real _nx: DesktopWidgetStore.getPos(wKey).nx
            property real _ny: DesktopWidgetStore.getPos(wKey).ny

            readonly property bool _skewEnabled: {
                var _ = DesktopWidgetStore._positions;
                return DesktopWidgetStore.getSkew(wKey).enabled;
            }
            property var _skewTL: DesktopWidgetStore.getSkew(wKey).tl
            property var _skewTR: DesktopWidgetStore.getSkew(wKey).tr
            property var _skewBR: DesktopWidgetStore.getSkew(wKey).br
            property var _skewBL: DesktopWidgetStore.getSkew(wKey).bl
            // Never cover corner you are currently skewing
            property string _skewDragEdge: ""
            function _rebindSkew() {
                proxy._skewTL = Qt.binding(() => DesktopWidgetStore.getSkew(proxy.wKey).tl);
                proxy._skewTR = Qt.binding(() => DesktopWidgetStore.getSkew(proxy.wKey).tr);
                proxy._skewBR = Qt.binding(() => DesktopWidgetStore.getSkew(proxy.wKey).br);
                proxy._skewBL = Qt.binding(() => DesktopWidgetStore.getSkew(proxy.wKey).bl);
            }
            function _skewLocal(name) {
                return name === "tl" ? proxy._skewTL : name === "tr" ? proxy._skewTR : name === "br" ? proxy._skewBR : proxy._skewBL;
            }
            function _setSkewLocal(name, x, y) {
                var v = {
                    x: Math.max(-1, Math.min(2, x)),
                    y: Math.max(-1, Math.min(2, y))
                };
                if (name === "tl")
                    proxy._skewTL = v;
                else if (name === "tr")
                    proxy._skewTR = v;
                else if (name === "br")
                    proxy._skewBR = v;
                else
                    proxy._skewBL = v;
            }

            function _edgeCorners(edge) {
                return edge === "t" ? ["tl", "tr"] : edge === "r" ? ["tr", "br"] : edge === "b" ? ["br", "bl"] : ["bl", "tl"];
            }

            function _skewPt(name, offs) {
                var W = proxy.width, H = proxy.height;
                var o = offs[name];
                if (name === "tl")
                    return Qt.point(o.x * W, o.y * H);
                if (name === "tr")
                    return Qt.point(W + o.x * W, o.y * H);
                if (name === "br")
                    return Qt.point(W + o.x * W, H + o.y * H);
                return Qt.point(o.x * W, H + o.y * H); // bl
            }

            function _skewSnap(moving) {
                if (!root.skewSnapEnabled)
                    return {
                        dx: 0,
                        dy: 0
                    };
                var W = Math.max(1, proxy.width), H = Math.max(1, proxy.height);
                var thrX = Math.round(7 * UIScale.value) / W;
                var thrY = Math.round(7 * UIScale.value) / H;
                var offs = {
                    tl: proxy._skewTL,
                    tr: proxy._skewTR,
                    br: proxy._skewBR,
                    bl: proxy._skewBL
                };
                var names = ["tl", "tr", "br", "bl"];
                var k;
                for (k in moving)
                    offs[k] = moving[k];
                var targetsX = [0, W], targetsY = [0, H];
                for (var i = 0; i < 4; i++) {
                    if (moving[names[i]] !== undefined)
                        continue;
                    var sp = proxy._skewPt(names[i], offs);
                    targetsX.push(sp.x);
                    targetsY.push(sp.y);
                }
                var bestDX = thrX, bestDY = thrY, gx, gy;
                for (k in moving) {
                    var p = proxy._skewPt(k, offs);
                    for (var x = 0; x < targetsX.length; x++) {
                        var df = (targetsX[x] - p.x) / W;
                        if (Math.abs(df) < Math.abs(bestDX)) {
                            bestDX = df;
                            gx = targetsX[x];
                        }
                    }
                    for (var y = 0; y < targetsY.length; y++) {
                        var dg = (targetsY[y] - p.y) / H;
                        if (Math.abs(dg) < Math.abs(bestDY)) {
                            bestDY = dg;
                            gy = targetsY[y];
                        }
                    }
                }
                return {
                    dx: gx !== undefined ? bestDX : 0,
                    dy: gy !== undefined ? bestDY : 0,
                    guideX: gx,
                    guideY: gy
                };
            }
            function _applySkewGuides(snap) {
                root._snapGuideX = snap.guideX !== undefined ? proxy.x + snap.guideX : undefined;
                root._snapGuideY = snap.guideY !== undefined ? proxy.y + snap.guideY : undefined;
            }

            function _reseed() {
                proxy._nx = Qt.binding(() => DesktopWidgetStore.getPos(proxy.wKey).nx);
                proxy._ny = Qt.binding(() => DesktopWidgetStore.getPos(proxy.wKey).ny);
                proxy._rebindSkew();
            }
            Connections {
                target: DesktopWidgetStore
                function onHistoryRestored() {
                    proxy._reseed();
                }
            }

            // Bezier baseline
            readonly property bool _curveEnabled: proxy._isCava && CavaSettings.bezierFor(proxy._cavaChannel).enabled
            property real _bezY0: CavaSettings.bezierFor(proxy._cavaChannel).y0
            property real _bezY1: CavaSettings.bezierFor(proxy._cavaChannel).y1
            property real _bezY2: CavaSettings.bezierFor(proxy._cavaChannel).y2
            property real _bezY3: CavaSettings.bezierFor(proxy._cavaChannel).y3
            function _rebindBez() {
                proxy._bezY0 = Qt.binding(() => CavaSettings.bezierFor(proxy._cavaChannel).y0);
                proxy._bezY1 = Qt.binding(() => CavaSettings.bezierFor(proxy._cavaChannel).y1);
                proxy._bezY2 = Qt.binding(() => CavaSettings.bezierFor(proxy._cavaChannel).y2);
                proxy._bezY3 = Qt.binding(() => CavaSettings.bezierFor(proxy._cavaChannel).y3);
            }
            function _bezValFor(name) {
                return name === "c0" ? proxy._bezY0 : name === "c1" ? proxy._bezY1 : name === "c2" ? proxy._bezY2 : proxy._bezY3;
            }
            function _setBezLocal(name, v) {
                v = Math.max(-1, Math.min(1, v));
                if (name === "c0")
                    proxy._bezY0 = v;
                else if (name === "c1")
                    proxy._bezY1 = v;
                else if (name === "c2")
                    proxy._bezY2 = v;
                else
                    proxy._bezY3 = v;
            }

            readonly property var _bgConfig: {
                var _ = DesktopWidgetStore._positions;
                return DesktopWidgetStore.getBgConfig(proxy.wKey);
            }
            readonly property bool _hasBg: _bgConfig.enabled
            readonly property real _bgPad: _hasBg ? Math.round(10 * UIScale.value) : 0
            readonly property real _dpr: Screen.devicePixelRatio

            // Mirrors DesktopWidget.qml's override logic so the proxy you drag around
            // here matches what actually renders once you hit Done.
            readonly property var _size: {
                var _ = DesktopWidgetStore._positions;
                return DesktopWidgetStore.getSize(proxy.wKey);
            }
            readonly property bool _overrideW: _size.w > 0
            readonly property bool _overrideH: _size.h > 0

            width: (proxy._overrideW ? proxy._size.w : proxyContent.implicitWidth) + _bgPad * 2
            height: (proxy._overrideH ? proxy._size.h : proxyContent.implicitHeight) + _bgPad * 2

            x: _nx * Math.max(1, root.width - width)
            y: _ny * Math.max(1, root.height - height)

            z: proxy._selected ? 10 : 0

            // Loaders create a fresh FileDialog each time to avoid a Qt 6.11 "bug" where
            // QQuickFileDialogImpl::setInitialCurrentFolderAndSelectedFile crashes on
            // the second open() call due to a stale internal QUrl pointer.
            // If this is *not* a bug, and I've just been using FileDialog incorrectly this whole time...
            // Please don't tell me I've been using it incorrectly.
            function openImageDialog() {
                imgDialogLoader.active = false;
                imgDialogLoader.active = true;
            }
            function openMaskDialog() {
                maskDialogLoader.active = false;
                maskDialogLoader.active = true;
            }
            Loader {
                id: imgDialogLoader
                active: false
                onActiveChanged: if (!active)
                    root._fileDialogOpen = false
                onLoaded: {
                    root._fileDialogOpen = true;
                    item.open();
                }
                sourceComponent: FileDialog {
                    title: I18n.t("desktop.chooseBackgroundImageDialogTitle")
                    nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.svg *.gif *.bmp)", "All files (*)"]
                    onAccepted: {
                        var path = selectedFile.toString();
                        if (path.startsWith("file://"))
                            path = path.slice(7);
                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                        c.imagePath = path;
                        DesktopWidgetStore.setBgConfig(proxy.wKey, c, Math.round(proxy.width * proxy._dpr), Math.round(proxy.height * proxy._dpr));
                        imgDialogLoader.active = false;
                    }
                    onRejected: {
                        imgDialogLoader.active = false;
                    }
                }
            }

            Loader {
                id: maskDialogLoader
                active: false
                onActiveChanged: if (!active)
                    root._fileDialogOpen = false
                onLoaded: {
                    root._fileDialogOpen = true;
                    item.open();
                }
                sourceComponent: FileDialog {
                    title: I18n.t("desktop.chooseMaskImageDialogTitle")
                    nameFilters: ["Images (*.png *.svg)", "All files (*)"]
                    onAccepted: {
                        var path = selectedFile.toString();
                        if (path.startsWith("file://"))
                            path = path.slice(7);
                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                        c.maskPath = path;
                        DesktopWidgetStore.setBgConfig(proxy.wKey, c);
                        maskDialogLoader.active = false;
                    }
                    onRejected: {
                        maskDialogLoader.active = false;
                    }
                }
            }

            // background, content warp together, handles stay outside
            Item {
                id: skewHost
                anchors.fill: parent

                transform: Matrix4x4 {
                    matrix: proxy._skewEnabled ? DesktopWidgetStore.cornerMatrixFrom(skewHost.width, skewHost.height, proxy._skewTL, proxy._skewTR, proxy._skewBR, proxy._skewBL) : Qt.matrix4x4()
                }

                DesktopWidgetBg {
                    anchors.fill: parent
                    bgConfig: proxy._bgConfig
                }

                // width/height stay bound always, see docs/qml-patterns.md #2 for why
                Loader {
                    id: proxyContent
                    anchors.centerIn: parent
                    sourceComponent: proxy.modelData.component
                    width: proxy._overrideW ? proxy._size.w : (item?.implicitWidth ?? 0)
                    height: proxy._overrideH ? proxy._size.h : (item?.implicitHeight ?? 0)
                }
            }

            // Quad outline through the 4 skewed corners
            Canvas {
                id: skewOutline
                anchors.fill: parent
                visible: proxy._selected && proxy._skewEnabled
                readonly property var cornerList: [proxy._skewTL, proxy._skewTR, proxy._skewBR, proxy._skewBL]
                onCornerListChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    var homes = [[0, 0], [width, 0], [width, height], [0, height]];
                    ctx.beginPath();
                    for (var i = 0; i < 4; i++) {
                        var px = homes[i][0] + skewOutline.cornerList[i].x * width;
                        var py = homes[i][1] + skewOutline.cornerList[i].y * height;
                        if (i === 0)
                            ctx.moveTo(px, py);
                        else
                            ctx.lineTo(px, py);
                    }
                    ctx.closePath();
                    ctx.strokeStyle = Colors.accent;
                    ctx.lineWidth = Math.max(1, Math.round(1 * UIScale.value));
                    ctx.setLineDash([Math.round(4 * UIScale.value), Math.round(3 * UIScale.value)]);
                    ctx.stroke();
                }
            }

            DragHandler {
                id: dragger
                target: null
                grabPermissions: PointerHandler.CanTakeOverFromAnything

                property point _startScene: Qt.point(0, 0)
                property point _startPos: Qt.point(0, 0)

                onActiveChanged: {
                    if (active) {
                        dragger._startScene = dragger.centroid.scenePosition;
                        dragger._startPos = Qt.point(proxy.x, proxy.y);
                    } else {
                        root._snapGuideX = undefined;
                        root._snapGuideY = undefined;
                        var rW = Math.max(1, root.width - proxy.width);
                        var rH = Math.max(1, root.height - proxy.height);
                        proxy._nx = Math.max(0.0, Math.min(1.0, proxy.x / rW));
                        proxy._ny = Math.max(0.0, Math.min(1.0, proxy.y / rH));
                        DesktopWidgetStore.setPos(proxy.wKey, proxy._nx, proxy._ny);
                        root._lastMovedKey = proxy.wKey;
                        proxy.x = Qt.binding(() => proxy._nx * Math.max(1, root.width - proxy.width));
                        proxy.y = Qt.binding(() => proxy._ny * Math.max(1, root.height - proxy.height));
                    }
                }

                onCentroidChanged: {
                    if (!dragger.active)
                        return;
                    var rawX = dragger._startPos.x + (dragger.centroid.scenePosition.x - dragger._startScene.x);
                    var rawY = dragger._startPos.y + (dragger.centroid.scenePosition.y - dragger._startScene.y);
                    if (root.snapEnabled) {
                        var s = root._computeSnap(proxy, rawX, rawY);
                        proxy.x = s.x;
                        proxy.y = s.y;
                        root._snapGuideX = s.guideX;
                        root._snapGuideY = s.guideY;
                    } else {
                        proxy.x = rawX;
                        proxy.y = rawY;
                        root._snapGuideX = undefined;
                        root._snapGuideY = undefined;
                    }
                }
            }

            TapHandler {
                onTapped: root.selectedKey = proxy._selected ? "" : proxy.wKey
            }

            HoverHandler {
                cursorShape: dragger.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: Colors.withAlpha(Colors.accent, proxy._selected ? 1.0 : (dragger.active ? 1.0 : 0.75))
                border.width: Math.round((proxy._selected ? 2 : 1.5) * UIScale.value)
                radius: UIScale.radiusSm

                Behavior on border.width {
                    NumberAnimation {
                        duration: 100
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: UIScale.spacingXs
                text: proxy.wKey
                color: proxy._selected ? Colors.accent : Colors.textDim
                font.pixelSize: UIScale.fontTiny
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1

                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }
            }

            // Resize handles: 4 corner grabs (width + height) + 4 edge grabs
            // (single axis).
            Repeater {
                model: proxy._selected ? (proxy._skewEnabled ? ["nw", "ne", "sw", "se"] : ["nw", "n", "ne", "w", "e", "sw", "s", "se"]) : []

                delegate: Rectangle {
                    id: handle
                    required property string modelData

                    readonly property bool _left: modelData.indexOf("w") >= 0
                    readonly property bool _right: modelData.indexOf("e") >= 0
                    readonly property bool _top: modelData.indexOf("n") >= 0
                    readonly property bool _bottom: modelData.indexOf("s") >= 0

                    width: Math.round(9 * UIScale.value)
                    height: width
                    radius: width / 2
                    color: Colors.bg
                    border.color: Colors.accent
                    border.width: Math.max(1, Math.round(1.5 * UIScale.value))
                    z: 20

                    x: (handle._left ? 0 : handle._right ? proxy.width : proxy.width / 2) - handle.width / 2
                    y: (handle._top ? 0 : handle._bottom ? proxy.height : proxy.height / 2) - handle.height / 2

                    property real _startX
                    property real _startY
                    property real _startW
                    property real _startH
                    property point _startScene

                    HoverHandler {
                        cursorShape: {
                            switch (handle.modelData) {
                            case "n":
                            case "s":
                                return Qt.SizeVerCursor;
                            case "e":
                            case "w":
                                return Qt.SizeHorCursor;
                            case "nw":
                            case "se":
                                return Qt.SizeFDiagCursor;
                            default:
                                // ne, sw
                                return Qt.SizeBDiagCursor;
                            }
                        }
                    }

                    DragHandler {
                        id: resizeDrag
                        target: null
                        grabPermissions: PointerHandler.CanTakeOverFromAnything

                        onActiveChanged: {
                            if (resizeDrag.active) {
                                handle._startScene = resizeDrag.centroid.scenePosition;
                                handle._startX = proxy.x;
                                handle._startY = proxy.y;
                                handle._startW = proxy.width;
                                handle._startH = proxy.height;
                            } else {
                                root._snapGuideX = undefined;
                                root._snapGuideY = undefined;
                                var w = Math.max(1, Math.round(proxy.width - proxy._bgPad * 2));
                                var h = Math.max(1, Math.round(proxy.height - proxy._bgPad * 2));
                                DesktopWidgetStore.setSize(proxy.wKey, w, h);

                                var rW = Math.max(1, root.width - proxy.width);
                                var rH = Math.max(1, root.height - proxy.height);
                                proxy._nx = Math.max(0.0, Math.min(1.0, proxy.x / rW));
                                proxy._ny = Math.max(0.0, Math.min(1.0, proxy.y / rH));
                                DesktopWidgetStore.setPos(proxy.wKey, proxy._nx, proxy._ny);
                                root._lastMovedKey = proxy.wKey;

                                proxy.x = Qt.binding(() => proxy._nx * Math.max(1, root.width - proxy.width));
                                proxy.y = Qt.binding(() => proxy._ny * Math.max(1, root.height - proxy.height));
                                proxy.width = Qt.binding(() => (proxy._overrideW ? proxy._size.w : proxyContent.implicitWidth) + proxy._bgPad * 2);
                                proxy.height = Qt.binding(() => (proxy._overrideH ? proxy._size.h : proxyContent.implicitHeight) + proxy._bgPad * 2);
                            }
                        }

                        onCentroidChanged: {
                            if (!resizeDrag.active)
                                return;

                            var dx = resizeDrag.centroid.scenePosition.x - handle._startScene.x;
                            var dy = resizeDrag.centroid.scenePosition.y - handle._startScene.y;
                            var minW = Math.round(40 * UIScale.value) + proxy._bgPad * 2;
                            var minH = Math.round(24 * UIScale.value) + proxy._bgPad * 2;

                            var newX = handle._startX;
                            var newY = handle._startY;
                            var newW = handle._startW;
                            var newH = handle._startH;
                            var guideX, guideY;

                            if (handle._right) {
                                var rawRight = handle._startX + handle._startW + dx;
                                if (root.snapEnabled) {
                                    var sr = root._computeEdgeSnap(proxy, rawRight, "x");
                                    rawRight = sr.value;
                                    guideX = sr.guide;
                                }
                                newW = Math.max(minW, rawRight - handle._startX);
                            } else if (handle._left) {
                                var rawLeft = handle._startX + dx;
                                if (root.snapEnabled) {
                                    var sl = root._computeEdgeSnap(proxy, rawLeft, "x");
                                    rawLeft = sl.value;
                                    guideX = sl.guide;
                                }
                                newW = Math.max(minW, handle._startX + handle._startW - rawLeft);
                                newX = handle._startX + handle._startW - newW;
                            }

                            if (handle._bottom) {
                                var rawBottom = handle._startY + handle._startH + dy;
                                if (root.snapEnabled) {
                                    var sb = root._computeEdgeSnap(proxy, rawBottom, "y");
                                    rawBottom = sb.value;
                                    guideY = sb.guide;
                                }
                                newH = Math.max(minH, rawBottom - handle._startY);
                            } else if (handle._top) {
                                var rawTop = handle._startY + dy;
                                if (root.snapEnabled) {
                                    var st = root._computeEdgeSnap(proxy, rawTop, "y");
                                    rawTop = st.value;
                                    guideY = st.guide;
                                }
                                newH = Math.max(minH, handle._startY + handle._startH - rawTop);
                                newY = handle._startY + handle._startH - newH;
                            }

                            root._snapGuideX = guideX;
                            root._snapGuideY = guideY;

                            proxy.width = newW;
                            proxy.height = newH;
                            proxy.x = newX;
                            proxy.y = newY;
                        }
                    }
                }
            }

            // Skew corner pucks. Drag, warp, persist on release
            Repeater {
                model: (proxy._selected && proxy._skewEnabled) ? ["tl", "tr", "br", "bl"] : []

                delegate: Rectangle {
                    id: corner
                    required property string modelData

                    readonly property bool _left: modelData === "tl" || modelData === "bl"
                    readonly property bool _top: modelData === "tl" || modelData === "tr"
                    readonly property var _off: proxy._skewLocal(modelData)

                    width: Math.round(13 * UIScale.value)
                    height: width
                    radius: Math.round(2 * UIScale.value)
                    rotation: 45
                    color: Colors.accent
                    border.color: Colors.bg
                    border.width: Math.max(1, Math.round(1.5 * UIScale.value))
                    z: 21

                    x: (corner._left ? 0 : proxy.width) + corner._off.x * proxy.width - width / 2
                    y: (corner._top ? 0 : proxy.height) + corner._off.y * proxy.height - height / 2

                    property point _startScene
                    property real _startX
                    property real _startY

                    HoverHandler {
                        cursorShape: Qt.SizeAllCursor
                    }

                    DragHandler {
                        id: cornerDrag
                        target: null
                        grabPermissions: PointerHandler.CanTakeOverFromAnything

                        onActiveChanged: {
                            if (cornerDrag.active) {
                                corner._startScene = cornerDrag.centroid.scenePosition;
                                corner._startX = corner._off.x;
                                corner._startY = corner._off.y;
                                proxy._skewDragEdge = corner._top ? "top" : "bottom";
                            } else {
                                var v = proxy._skewLocal(corner.modelData);
                                DesktopWidgetStore.setSkewCorner(proxy.wKey, corner.modelData, v.x, v.y);
                                proxy._rebindSkew();
                                root._snapGuideX = undefined;
                                root._snapGuideY = undefined;
                                proxy._skewDragEdge = "";
                            }
                        }
                        onCentroidChanged: {
                            if (!cornerDrag.active)
                                return;
                            var nx = corner._startX + (cornerDrag.centroid.scenePosition.x - corner._startScene.x) / Math.max(1, proxy.width);
                            var ny = corner._startY + (cornerDrag.centroid.scenePosition.y - corner._startScene.y) / Math.max(1, proxy.height);
                            var mv = {};
                            mv[corner.modelData] = {
                                x: nx,
                                y: ny
                            };
                            var snap = proxy._skewSnap(mv);
                            proxy._setSkewLocal(corner.modelData, nx + snap.dx, ny + snap.dy);
                            proxy._applySkewGuides(snap);
                        }
                    }
                }
            }

            // Skew edge handles. Drag both corners of one edge together
            Repeater {
                model: (proxy._selected && proxy._skewEnabled) ? ["t", "r", "b", "l"] : []

                delegate: Rectangle {
                    id: edge
                    required property string modelData

                    readonly property bool _horiz: modelData === "t" || modelData === "b"
                    readonly property var _cn: proxy._edgeCorners(modelData)
                    readonly property var _offs: ({
                            tl: proxy._skewTL,
                            tr: proxy._skewTR,
                            br: proxy._skewBR,
                            bl: proxy._skewBL
                        })
                    readonly property point _p0: proxy._skewPt(_cn[0], _offs)
                    readonly property point _p1: proxy._skewPt(_cn[1], _offs)

                    width: _horiz ? Math.round(20 * UIScale.value) : Math.round(8 * UIScale.value)
                    height: _horiz ? Math.round(8 * UIScale.value) : Math.round(20 * UIScale.value)
                    radius: Math.round(3 * UIScale.value)
                    color: Colors.accent
                    border.color: Colors.bg
                    border.width: Math.max(1, Math.round(1.5 * UIScale.value))
                    z: 21

                    x: (edge._p0.x + edge._p1.x) / 2 - width / 2
                    y: (edge._p0.y + edge._p1.y) / 2 - height / 2

                    property point _startScene
                    property var _s0
                    property var _s1

                    HoverHandler {
                        cursorShape: edge._horiz ? Qt.SizeVerCursor : Qt.SizeHorCursor
                    }

                    DragHandler {
                        id: edgeDrag
                        target: null
                        grabPermissions: PointerHandler.CanTakeOverFromAnything

                        onActiveChanged: {
                            if (edgeDrag.active) {
                                edge._startScene = edgeDrag.centroid.scenePosition;
                                edge._s0 = proxy._skewLocal(edge._cn[0]);
                                edge._s1 = proxy._skewLocal(edge._cn[1]);
                                proxy._skewDragEdge = edge.modelData === "t" ? "top" : edge.modelData === "b" ? "bottom" : "";
                            } else {
                                var v0 = proxy._skewLocal(edge._cn[0]);
                                var v1 = proxy._skewLocal(edge._cn[1]);
                                DesktopWidgetStore.setSkewCorner(proxy.wKey, edge._cn[0], v0.x, v0.y);
                                DesktopWidgetStore.setSkewCorner(proxy.wKey, edge._cn[1], v1.x, v1.y);
                                proxy._rebindSkew();
                                root._snapGuideX = undefined;
                                root._snapGuideY = undefined;
                                proxy._skewDragEdge = "";
                            }
                        }
                        onCentroidChanged: {
                            if (!edgeDrag.active)
                                return;
                            var dnx = (edgeDrag.centroid.scenePosition.x - edge._startScene.x) / Math.max(1, proxy.width);
                            var dny = (edgeDrag.centroid.scenePosition.y - edge._startScene.y) / Math.max(1, proxy.height);
                            var t0 = {
                                x: edge._s0.x + dnx,
                                y: edge._s0.y + dny
                            };
                            var t1 = {
                                x: edge._s1.x + dnx,
                                y: edge._s1.y + dny
                            };
                            var mv = {};
                            mv[edge._cn[0]] = t0;
                            mv[edge._cn[1]] = t1;
                            var snap = proxy._skewSnap(mv);
                            proxy._setSkewLocal(edge._cn[0], t0.x + snap.dx, t0.y + snap.dy);
                            proxy._setSkewLocal(edge._cn[1], t1.x + snap.dx, t1.y + snap.dy);
                            proxy._applySkewGuides(snap);
                        }
                    }
                }
            }

            // Bezier baseline handles (cava only): 4 control-point pucks at cross
            // 0, 1/3, 2/3, 1, draggable along the growth axis only.
            Repeater {
                model: (proxy._selected && proxy._curveEnabled) ? ["c0", "c1", "c2", "c3"] : []

                delegate: Rectangle {
                    id: bez
                    required property string modelData

                    readonly property string _orient: CavaSettings.orientationFor(proxy._cavaChannel)
                    readonly property bool _vertical: _orient === "left" || _orient === "right"
                    readonly property real _t: modelData === "c0" ? 0 : modelData === "c1" ? (1 / 3) : modelData === "c2" ? (2 / 3) : 1
                    readonly property real _val: proxy._bezValFor(modelData)
                    readonly property real _extent: _vertical ? proxy.width : proxy.height
                    readonly property real _px: _val * _extent

                    width: Math.round(12 * UIScale.value)
                    height: width
                    radius: width / 2
                    color: Colors.bg
                    border.color: Colors.accent
                    border.width: Math.max(1, Math.round(2 * UIScale.value))
                    z: 21

                    x: {
                        if (bez._vertical)
                            return (bez._orient === "left" ? bez._px : proxy.width - bez._px) - width / 2;
                        return bez._t * proxy.width - width / 2;
                    }
                    y: {
                        if (!bez._vertical)
                            return (bez._orient === "top" ? bez._px : proxy.height - bez._px) - height / 2;
                        return bez._t * proxy.height - height / 2;
                    }

                    property point _startScene
                    property real _startVal

                    HoverHandler {
                        cursorShape: bez._vertical ? Qt.SizeHorCursor : Qt.SizeVerCursor
                    }

                    DragHandler {
                        id: bezDrag
                        target: null
                        grabPermissions: PointerHandler.CanTakeOverFromAnything

                        onActiveChanged: {
                            if (bezDrag.active) {
                                bez._startScene = bezDrag.centroid.scenePosition;
                                bez._startVal = bez._val;
                            } else {
                                CavaSettings.writeBezierControl(proxy._cavaChannel, proxy._bezY0, proxy._bezY1, proxy._bezY2, proxy._bezY3);
                                proxy._rebindBez();
                            }
                        }
                        onCentroidChanged: {
                            if (!bezDrag.active)
                                return;
                            var delta;
                            if (bez._vertical)
                                delta = (bezDrag.centroid.scenePosition.x - bez._startScene.x) / Math.max(1, bez._extent) * (bez._orient === "left" ? 1 : -1);
                            else
                                delta = (bezDrag.centroid.scenePosition.y - bez._startScene.y) / Math.max(1, bez._extent) * (bez._orient === "top" ? 1 : -1);
                            proxy._setBezLocal(bez.modelData, bez._startVal + delta);
                        }
                    }
                }
            }

            // Default below widgets, flips to top. Always pushed within bounds
            Loader {
                id: cardLoader
                active: proxy._selected
                anchors.horizontalCenter: parent.horizontalCenter

                readonly property real _gap: Math.round(UIScale.spacingSm) + UIScale.fontTiny + UIScale.spacingXs
                readonly property real _cardHeight: item ? item.implicitHeight : 0
                readonly property bool _fitsBelow: proxy.y + proxy.height + _gap + _cardHeight <= root.height

                readonly property real _above: Math.max(-proxy.y, -_gap - _cardHeight)
                readonly property real _below: Math.min(proxy.height + _gap, root.height - proxy.y - _cardHeight)

                y: proxy._skewDragEdge === "bottom" ? _above : proxy._skewDragEdge === "top" ? _below : (_fitsBelow ? (proxy.height + _gap) : _above)

                Behavior on y {
                    NumberAnimation {
                        duration: 110
                        easing.type: Easing.OutCubic
                    }
                }

                sourceComponent: Rectangle {
                    radius: UIScale.radiusSm
                    color: Colors.surface
                    implicitWidth: cardContent.implicitWidth + Math.round(UIScale.spacingMd * 2)
                    implicitHeight: cardContent.implicitHeight + Math.round(UIScale.spacingSm * 2)

                    Column {
                        id: cardContent
                        anchors.centerIn: parent
                        spacing: Math.round(UIScale.spacingSm)

                        // Row 0: Fixed size, independent per axis. Empty/0 means "auto",
                        // falls back to the content's own natural size.
                        Row {
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.size")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: Math.round(52 * UIScale.value)
                                implicitHeight: widthInput.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                color: Colors.withAlpha(Colors.outline, 0.2)
                                radius: UIScale.radiusSm
                                clip: true

                                TextInput {
                                    id: widthInput
                                    anchors {
                                        fill: parent
                                        margins: Math.round(UIScale.spacingXs)
                                    }
                                    text: {
                                        var w = DesktopWidgetStore.getSize(proxy.wKey).w;
                                        return w > 0 ? String(w) : "";
                                    }
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontSmall
                                    selectByMouse: true
                                    validator: IntValidator {
                                        bottom: 0
                                    }
                                    onEditingFinished: {
                                        var s = DesktopWidgetStore.getSize(proxy.wKey);
                                        DesktopWidgetStore.setSize(proxy.wKey, parseInt(widthInput.text) || 0, s.h);
                                    }
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                // I am also conflicted on the usage of × because VSCodium
                                // keeps warning me about it, which is annoying.
                                // I could use X or x, but those don't look as good.
                                // Am I rambling? Yes. Is this the place to do it? No.
                                text: "×"
                                color: Colors.muted
                                font.pixelSize: UIScale.fontSmall
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: Math.round(52 * UIScale.value)
                                implicitHeight: heightInput.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                color: Colors.withAlpha(Colors.outline, 0.2)
                                radius: UIScale.radiusSm
                                clip: true

                                TextInput {
                                    id: heightInput
                                    anchors {
                                        fill: parent
                                        margins: Math.round(UIScale.spacingXs)
                                    }
                                    text: {
                                        var h = DesktopWidgetStore.getSize(proxy.wKey).h;
                                        return h > 0 ? String(h) : "";
                                    }
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontSmall
                                    selectByMouse: true
                                    validator: IntValidator {
                                        bottom: 0
                                    }
                                    onEditingFinished: {
                                        var s = DesktopWidgetStore.getSize(proxy.wKey);
                                        DesktopWidgetStore.setSize(proxy.wKey, s.w, parseInt(heightInput.text) || 0);
                                    }
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: proxy._overrideW || proxy._overrideH
                                implicitWidth: sizeAutoLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: sizeAutoLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: UIScale.radiusSm
                                color: sizeAutoHover.hovered ? Colors.withAlpha(Colors.outline, 0.4) : Colors.withAlpha(Colors.outline, 0.2)

                                Text {
                                    id: sizeAutoLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("common.auto")
                                    color: Colors.muted
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {
                                    id: sizeAutoHover
                                }
                                TapHandler {
                                    onTapped: {
                                        DesktopWidgetStore.setSize(proxy.wKey, 0, 0);
                                        widthInput.text = "";
                                        heightInput.text = "";
                                    }
                                }
                            }
                        }

                        // Row 1: Background enable toggle
                        Row {
                            spacing: Math.round(UIScale.spacingMd)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.background")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Rectangle {
                                id: bgToggle
                                anchors.verticalCenter: parent.verticalCenter

                                property bool _on: (DesktopWidgetStore._positions[proxy.wKey]?.bg?.enabled) ?? false

                                implicitWidth: bgToggleLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: bgToggleLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: height / 2
                                color: _on ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.outline, 0.3)

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 100
                                    }
                                }

                                Text {
                                    id: bgToggleLabel
                                    anchors.centerIn: parent
                                    text: bgToggle._on ? I18n.t("common.on") : I18n.t("common.off")
                                    color: bgToggle._on ? Colors.accent : Colors.muted
                                    font.pixelSize: UIScale.fontSmall
                                    font.weight: Font.Medium

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 100
                                        }
                                    }
                                }

                                HoverHandler {}
                                TapHandler {
                                    onTapped: {
                                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                                        c.enabled = !c.enabled;
                                        DesktopWidgetStore.setBgConfig(proxy.wKey, c);
                                    }
                                }
                            }
                        }

                        // Row 2: Type selector, Color / Image
                        Row {
                            visible: (DesktopWidgetStore._positions[proxy.wKey]?.bg?.enabled) ?? false
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.type")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                property bool _active: ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.type) ?? "color") === "color"
                                implicitWidth: colorTypeLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: colorTypeLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: height / 2
                                color: _active ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.outline, 0.15)
                                border.color: _active ? Colors.accent : "transparent"
                                border.width: 1

                                Text {
                                    id: colorTypeLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.color")
                                    color: parent._active ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {}
                                TapHandler {
                                    onTapped: {
                                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                                        c.type = "color";
                                        DesktopWidgetStore.setBgConfig(proxy.wKey, c);
                                    }
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                property bool _active: ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.type) ?? "color") === "image"
                                implicitWidth: imageTypeLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: imageTypeLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: height / 2
                                color: _active ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.outline, 0.15)
                                border.color: _active ? Colors.accent : "transparent"
                                border.width: 1

                                Text {
                                    id: imageTypeLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.image")
                                    color: parent._active ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {}
                                TapHandler {
                                    onTapped: {
                                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                                        c.type = "image";
                                        DesktopWidgetStore.setBgConfig(proxy.wKey, c);
                                    }
                                }
                            }
                        }

                        // Row 3: Inline color picker
                        Loader {
                            active: ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.enabled) ?? false) && ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.type) ?? "color") === "color"
                            sourceComponent: ColorPicker {
                                value: DesktopWidgetStore._positions[proxy.wKey]?.bg?.color ?? "#000000"
                                onPicked: function (hex) {
                                    var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                                    c.color = hex;
                                    DesktopWidgetStore.setBgConfig(proxy.wKey, c);
                                }
                            }
                        }

                        // Row 4: Image path
                        Row {
                            visible: ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.enabled) ?? false) && ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.type) ?? "color") === "image"
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.image")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: Math.round(180 * UIScale.value)
                                implicitHeight: imgPathInput.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                color: Colors.withAlpha(Colors.outline, 0.2)
                                radius: UIScale.radiusSm
                                clip: true

                                TextInput {
                                    id: imgPathInput
                                    anchors {
                                        fill: parent
                                        margins: Math.round(UIScale.spacingXs)
                                    }
                                    text: (DesktopWidgetStore._positions[proxy.wKey]?.bg?.imagePath) ?? ""
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontSmall
                                    selectByMouse: true
                                    onEditingFinished: {
                                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                                        c.imagePath = imgPathInput.text;
                                        DesktopWidgetStore.setBgConfig(proxy.wKey, c, Math.round(proxy.width * proxy._dpr), Math.round(proxy.height * proxy._dpr));
                                    }
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: imgBrowseLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: imgBrowseLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: UIScale.radiusSm
                                color: imgBrowseHover.hovered ? Colors.withAlpha(Colors.outline, 0.4) : Colors.withAlpha(Colors.outline, 0.2)

                                Text {
                                    id: imgBrowseLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.browse")
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {
                                    id: imgBrowseHover
                                }
                                TapHandler {
                                    onTapped: proxy.openImageDialog()
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.imagePath) ?? "") !== ""
                                implicitWidth: imgClearLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: imgClearLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: UIScale.radiusSm
                                color: imgClearHover.hovered ? Colors.withAlpha(Colors.outline, 0.4) : Colors.withAlpha(Colors.outline, 0.2)

                                Text {
                                    id: imgClearLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.clear")
                                    color: Colors.muted
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {
                                    id: imgClearHover
                                }
                                TapHandler {
                                    onTapped: {
                                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                                        c.imagePath = "";
                                        DesktopWidgetStore.setBgConfig(proxy.wKey, c, Math.round(proxy.width * proxy._dpr), Math.round(proxy.height * proxy._dpr));
                                    }
                                }
                            }
                        }

                        // Row 5: Overlay opacity
                        Row {
                            visible: ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.enabled) ?? false) && ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.type) ?? "color") === "image"
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.overlay")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Item {
                                id: overlaySlider
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: Math.round(120 * UIScale.value)
                                implicitHeight: Math.round(16 * UIScale.value)

                                readonly property real _val: (DesktopWidgetStore._positions[proxy.wKey]?.bg?.overlayOpacity) ?? 0.4

                                Rectangle {
                                    id: sliderTrack
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    height: Math.max(2, Math.round(3 * UIScale.value))
                                    radius: height / 2
                                    color: Colors.withAlpha(Colors.outline, 0.4)

                                    Rectangle {
                                        width: sliderTrack.width * overlaySlider._val
                                        height: parent.height
                                        radius: height / 2
                                        color: Colors.accent
                                    }
                                }

                                Rectangle {
                                    width: Math.round(12 * UIScale.value)
                                    height: width
                                    radius: width / 2
                                    color: Colors.accent
                                    x: (overlaySlider.implicitWidth - width) * overlaySlider._val
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    function _update(mx) {
                                        var ratio = Math.max(0.0, Math.min(1.0, mx / overlaySlider.implicitWidth));
                                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                                        c.overlayOpacity = Math.round(ratio * 100) / 100;
                                        DesktopWidgetStore.setBgConfig(proxy.wKey, c);
                                    }
                                    onPressed: _update(mouseX)
                                    onPositionChanged: if (pressed)
                                        _update(mouseX)
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Math.round(((DesktopWidgetStore._positions[proxy.wKey]?.bg?.overlayOpacity) ?? 0.4) * 100) + "%"
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }
                        }

                        // Row 6: Mask path
                        Row {
                            visible: ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.enabled) ?? false) && ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.type) ?? "color") === "image"
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.mask")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: Math.round(180 * UIScale.value)
                                implicitHeight: maskPathInput.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                color: Colors.withAlpha(Colors.outline, 0.2)
                                radius: UIScale.radiusSm
                                clip: true

                                TextInput {
                                    id: maskPathInput
                                    anchors {
                                        fill: parent
                                        margins: Math.round(UIScale.spacingXs)
                                    }
                                    text: (DesktopWidgetStore._positions[proxy.wKey]?.bg?.maskPath) ?? ""
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontSmall
                                    selectByMouse: true
                                    onEditingFinished: {
                                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                                        c.maskPath = maskPathInput.text;
                                        DesktopWidgetStore.setBgConfig(proxy.wKey, c);
                                    }
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: maskBrowseLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: maskBrowseLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: UIScale.radiusSm
                                color: maskBrowseHover.hovered ? Colors.withAlpha(Colors.outline, 0.4) : Colors.withAlpha(Colors.outline, 0.2)

                                Text {
                                    id: maskBrowseLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.browse")
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {
                                    id: maskBrowseHover
                                }
                                TapHandler {
                                    onTapped: proxy.openMaskDialog()
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.maskPath) ?? "") !== ""
                                implicitWidth: maskClearLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: maskClearLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: UIScale.radiusSm
                                color: maskClearHover.hovered ? Colors.withAlpha(Colors.outline, 0.4) : Colors.withAlpha(Colors.outline, 0.2)

                                Text {
                                    id: maskClearLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.clear")
                                    color: Colors.muted
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {
                                    id: maskClearHover
                                }
                                TapHandler {
                                    onTapped: {
                                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                                        c.maskPath = "";
                                        DesktopWidgetStore.setBgConfig(proxy.wKey, c);
                                    }
                                }
                            }
                        }

                        // Row 7: Globe-only rotation mode (auto-spin vs a
                        // single static frame)
                        Row {
                            visible: proxy.wKey === "globe2d"
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.rotation")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                property bool _active: Globe2DSettings.rotateMode === "auto"
                                implicitWidth: autoModeLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: autoModeLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: height / 2
                                color: _active ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.outline, 0.15)
                                border.color: _active ? Colors.accent : "transparent"
                                border.width: 1

                                Text {
                                    id: autoModeLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("common.auto")
                                    color: parent._active ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {}
                                TapHandler {
                                    onTapped: Globe2DSettings.setRotateMode("auto")
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                property bool _active: Globe2DSettings.rotateMode === "manual"
                                implicitWidth: manualModeLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: manualModeLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: height / 2
                                color: _active ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.outline, 0.15)
                                border.color: _active ? Colors.accent : "transparent"
                                border.width: 1

                                Text {
                                    id: manualModeLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.manual")
                                    color: parent._active ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {}
                                TapHandler {
                                    onTapped: Globe2DSettings.setRotateMode("manual")
                                }
                            }
                        }

                        // Row 7b: Skew, toggle and reset
                        Row {
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.skew")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Rectangle {
                                id: skewBtn
                                anchors.verticalCenter: parent.verticalCenter
                                property bool _active: proxy._skewEnabled
                                implicitWidth: skewLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: skewLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: height / 2
                                color: _active ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.outline, 0.15)
                                border.color: _active ? Colors.accent : "transparent"
                                border.width: 1

                                Text {
                                    id: skewLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.skew" + (skewBtn._active ? "On" : "Off"))
                                    color: skewBtn._active ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {}
                                TapHandler {
                                    onTapped: {
                                        DesktopWidgetStore.setSkewEnabled(proxy.wKey, !skewBtn._active);
                                        proxy._rebindSkew();
                                    }
                                }
                            }

                            Rectangle {
                                id: skewSnapBtn
                                anchors.verticalCenter: parent.verticalCenter
                                visible: proxy._skewEnabled
                                property bool _active: root.skewSnapEnabled
                                implicitWidth: skewSnapLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: skewSnapLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: height / 2
                                color: _active ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.outline, 0.15)
                                border.color: _active ? Colors.accent : "transparent"
                                border.width: 1

                                Text {
                                    id: skewSnapLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.snap")
                                    color: skewSnapBtn._active ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {}
                                TapHandler {
                                    onTapped: root.skewSnapEnabled = !root.skewSnapEnabled
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: proxy._skewEnabled
                                implicitWidth: skewResetLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: skewResetLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: height / 2
                                color: skewResetHover.hovered ? Colors.withAlpha(Colors.outline, 0.4) : Colors.withAlpha(Colors.outline, 0.2)

                                Text {
                                    id: skewResetLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.reset")
                                    color: Colors.muted
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {
                                    id: skewResetHover
                                }
                                TapHandler {
                                    onTapped: {
                                        DesktopWidgetStore.resetSkew(proxy.wKey);
                                        proxy._rebindSkew();
                                    }
                                }
                            }
                        }

                        // Row 8: Cava-only bar count
                        Row {
                            visible: proxy._isCava
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.barCount")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: Math.round(52 * UIScale.value)
                                implicitHeight: barCountInput.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                color: Colors.withAlpha(Colors.outline, 0.2)
                                radius: UIScale.radiusSm
                                clip: true

                                TextInput {
                                    id: barCountInput
                                    anchors {
                                        fill: parent
                                        margins: Math.round(UIScale.spacingXs)
                                    }
                                    text: String(CavaSettings.barCount)
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontSmall
                                    selectByMouse: true
                                    validator: IntValidator {
                                        bottom: 4
                                        top: 256
                                    }
                                    onEditingFinished: {
                                        CavaSettings.writeBarCount(parseInt(barCountInput.text) || CavaSettings.barCount);
                                    }
                                }
                            }
                        }

                        // Row 9: Cava-only orientation
                        Row {
                            visible: proxy._isCava
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.orientation")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Math.round(UIScale.spacingXs)

                                Repeater {
                                    model: ["bottom", "top", "left", "right"]

                                    delegate: Rectangle {
                                        id: orientBtn
                                        required property string modelData

                                        property bool _active: CavaSettings.orientationFor(proxy._cavaChannel) === modelData

                                        implicitWidth: orientLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                        implicitHeight: orientLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                        radius: height / 2
                                        color: _active ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.outline, 0.15)
                                        border.color: _active ? Colors.accent : "transparent"
                                        border.width: 1

                                        Text {
                                            id: orientLabel
                                            anchors.centerIn: parent
                                            text: I18n.t("bar." + orientBtn.modelData)
                                            color: orientBtn._active ? Colors.accent : Colors.textDim
                                            font.pixelSize: UIScale.fontSmall
                                        }

                                        HoverHandler {}
                                        TapHandler {
                                            onTapped: CavaSettings.writeOrientation(proxy._cavaChannel, orientBtn.modelData)
                                        }
                                    }
                                }
                            }
                        }

                        // Row 10: Cava-only style
                        Row {
                            visible: proxy._isCava
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.style")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Math.round(UIScale.spacingXs)

                                Repeater {
                                    model: ["bars", "area"]

                                    delegate: Rectangle {
                                        id: styleBtn
                                        required property string modelData

                                        property bool _active: CavaSettings.style === modelData

                                        implicitWidth: styleLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                        implicitHeight: styleLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                        radius: height / 2
                                        color: _active ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.outline, 0.15)
                                        border.color: _active ? Colors.accent : "transparent"
                                        border.width: 1

                                        Text {
                                            id: styleLabel
                                            anchors.centerIn: parent
                                            text: I18n.t("desktop.style" + (styleBtn.modelData === "area" ? "Area" : "Bars"))
                                            color: styleBtn._active ? Colors.accent : Colors.textDim
                                            font.pixelSize: UIScale.fontSmall
                                        }

                                        HoverHandler {}
                                        TapHandler {
                                            onTapped: CavaSettings.writeStyle(styleBtn.modelData)
                                        }
                                    }
                                }
                            }
                        }

                        // Row 11: Cava-only renderer
                        Row {
                            visible: proxy._isCava
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.renderer")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Math.round(UIScale.spacingXs)

                                Repeater {
                                    model: ["cpu", "gpu"]

                                    delegate: Rectangle {
                                        id: rendererBtn
                                        required property string modelData

                                        property bool _active: CavaSettings.renderer === modelData

                                        implicitWidth: rendererLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                        implicitHeight: rendererLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                        radius: height / 2
                                        color: _active ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.outline, 0.15)
                                        border.color: _active ? Colors.accent : "transparent"
                                        border.width: 1

                                        Text {
                                            id: rendererLabel
                                            anchors.centerIn: parent
                                            text: I18n.t("desktop.renderer" + (rendererBtn.modelData === "gpu" ? "Gpu" : "Cpu"))
                                            color: rendererBtn._active ? Colors.accent : Colors.textDim
                                            font.pixelSize: UIScale.fontSmall
                                        }

                                        HoverHandler {}
                                        TapHandler {
                                            onTapped: CavaSettings.writeRenderer(rendererBtn.modelData)
                                        }
                                    }
                                }
                            }
                        }

                        // Row 12: Cava-only flip, where bass is
                        Row {
                            visible: proxy._isCava
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.flip")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Rectangle {
                                id: flipBtn
                                anchors.verticalCenter: parent.verticalCenter

                                property bool _active: CavaSettings.flipFor(proxy._cavaChannel)

                                implicitWidth: flipLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: flipLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: height / 2
                                color: _active ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.outline, 0.15)
                                border.color: _active ? Colors.accent : "transparent"
                                border.width: 1

                                Text {
                                    id: flipLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.flip" + (flipBtn._active ? "On" : "Off"))
                                    color: flipBtn._active ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {}
                                TapHandler {
                                    onTapped: CavaSettings.writeFlip(proxy._cavaChannel, !flipBtn._active)
                                }
                            }
                        }

                        // Row 13: Cava-only auto-hide
                        Row {
                            visible: proxy._isCava
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.autoHide")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Rectangle {
                                id: autoHideBtn
                                anchors.verticalCenter: parent.verticalCenter

                                property bool _active: CavaSettings.autoHide

                                implicitWidth: autoHideLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: autoHideLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: height / 2
                                color: _active ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.outline, 0.15)
                                border.color: _active ? Colors.accent : "transparent"
                                border.width: 1

                                Text {
                                    id: autoHideLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.autoHide" + (autoHideBtn._active ? "On" : "Off"))
                                    color: autoHideBtn._active ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {}
                                TapHandler {
                                    onTapped: CavaSettings.writeAutoHide(!autoHideBtn._active)
                                }
                            }
                        }

                        // Row 14: Cava-only baseline curve, toggle and reset
                        Row {
                            visible: proxy._isCava
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.curve")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Rectangle {
                                id: curveBtn
                                anchors.verticalCenter: parent.verticalCenter
                                property bool _active: proxy._curveEnabled
                                implicitWidth: curveLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: curveLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: height / 2
                                color: _active ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.outline, 0.15)
                                border.color: _active ? Colors.accent : "transparent"
                                border.width: 1

                                Text {
                                    id: curveLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.curve" + (curveBtn._active ? "On" : "Off"))
                                    color: curveBtn._active ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {}
                                TapHandler {
                                    onTapped: {
                                        CavaSettings.writeBezierEnabled(proxy._cavaChannel, !curveBtn._active);
                                        proxy._rebindBez();
                                    }
                                }
                            }

                            Rectangle {
                                id: curveFitBtn
                                anchors.verticalCenter: parent.verticalCenter
                                visible: proxy._curveEnabled
                                property bool _fit: CavaSettings.bezierFor(proxy._cavaChannel).fit
                                implicitWidth: curveFitLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: curveFitLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: height / 2
                                color: Colors.withAlpha(Colors.accent, 0.2)
                                border.color: Colors.accent
                                border.width: 1

                                Text {
                                    id: curveFitLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.curveFit" + (curveFitBtn._fit ? "On" : "Off"))
                                    color: Colors.accent
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {}
                                TapHandler {
                                    onTapped: CavaSettings.writeBezierFit(proxy._cavaChannel, !curveFitBtn._fit)
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: proxy._curveEnabled
                                implicitWidth: curveResetLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: curveResetLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: height / 2
                                color: curveResetHover.hovered ? Colors.withAlpha(Colors.outline, 0.4) : Colors.withAlpha(Colors.outline, 0.2)

                                Text {
                                    id: curveResetLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.reset")
                                    color: Colors.muted
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {
                                    id: curveResetHover
                                }
                                TapHandler {
                                    onTapped: {
                                        CavaSettings.resetBezier(proxy._cavaChannel);
                                        proxy._rebindBez();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Alignment guides (drawn above proxies)
    Rectangle {
        visible: root._snapGuideX !== undefined
        x: root._snapGuideX !== undefined ? Math.round(root._snapGuideX) : 0
        y: 0
        width: Math.max(1, Math.round(UIScale.value))
        height: root.height
        color: Colors.accent
        opacity: 0.55
    }

    Rectangle {
        visible: root._snapGuideY !== undefined
        x: 0
        y: root._snapGuideY !== undefined ? Math.round(root._snapGuideY) : 0
        width: root.width
        height: Math.max(1, Math.round(UIScale.value))
        color: Colors.accent
        opacity: 0.55
    }

    // Widget catalog panel, left side
    Column {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: Math.round(UIScale.spacingLg)
        spacing: Math.round(UIScale.spacingXs)

        Repeater {
            model: DesktopWidgetCatalog.entries

            delegate: Rectangle {
                id: catalogRow
                required property var modelData
                required property int index

                property bool _on: DesktopWidgetStore.isEnabled(catalogRow.modelData.key)

                implicitWidth: catalogRowContent.implicitWidth + Math.round(UIScale.spacingMd * 2)
                implicitHeight: catalogRowContent.implicitHeight + Math.round(UIScale.spacingSm * 2)
                radius: height / 2
                color: catalogRow._on ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surface

                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }

                Row {
                    id: catalogRowContent
                    anchors.centerIn: parent
                    spacing: Math.round(UIScale.spacingSm)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: catalogRow.modelData.label
                        color: catalogRow._on ? Colors.accent : Colors.textDim
                        font.pixelSize: UIScale.fontSmall

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: catalogRow._on ? "x" : "+"
                        color: catalogRow._on ? Colors.accent : Colors.textDim
                        font.pixelSize: UIScale.fontSmall
                        font.bold: true

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }
                    }
                }

                HoverHandler {}
                TapHandler {
                    onTapped: {
                        if (catalogRow._on)
                            DesktopWidgetStore.disableWidget(catalogRow.modelData.key);
                        else
                            DesktopWidgetStore.enableWidget(catalogRow.modelData.key);
                    }
                }
            }
        }
    }

    // HUD mode label, top centre
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.round(UIScale.spacingLg)
        implicitWidth: modeLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
        implicitHeight: modeLabel.implicitHeight + Math.round(UIScale.spacingSm * 2)
        radius: height / 2
        color: Colors.surface

        Text {
            id: modeLabel
            anchors.centerIn: parent
            text: I18n.t("desktop.widgetConfigMode")
            color: Colors.textDim
            font.pixelSize: UIScale.fontSmall
        }
    }

    // Controls, top right
    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Math.round(UIScale.spacingLg)
        spacing: Math.round(UIScale.spacingSm)

        Repeater {
            model: [
                {
                    key: "undo",
                    label: "desktop.undo"
                },
                {
                    key: "redo",
                    label: "desktop.redo"
                }
            ]

            delegate: Rectangle {
                id: histBtn
                required property var modelData
                readonly property bool _enabled: modelData.key === "undo" ? DesktopWidgetStore.canUndo : DesktopWidgetStore.canRedo
                implicitWidth: histLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                implicitHeight: histLabel.implicitHeight + Math.round(UIScale.spacingSm * 2)
                radius: height / 2
                opacity: _enabled ? 1 : 0.4
                color: (histBtn._enabled && histHover.hovered) ? Colors.withAlpha(Colors.accent, 0.18) : Colors.surface

                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }

                Text {
                    id: histLabel
                    anchors.centerIn: parent
                    text: I18n.t(histBtn.modelData.label)
                    color: (histBtn._enabled && histHover.hovered) ? Colors.accent : Colors.textDim
                    font.pixelSize: UIScale.fontSmall
                }

                HoverHandler {
                    id: histHover
                }
                TapHandler {
                    enabled: histBtn._enabled
                    onTapped: histBtn.modelData.key === "undo" ? DesktopWidgetStore.undo() : DesktopWidgetStore.redo()
                }
            }
        }

        Rectangle {
            implicitWidth: snapLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
            implicitHeight: snapLabel.implicitHeight + Math.round(UIScale.spacingSm * 2)
            radius: height / 2
            color: root.snapEnabled ? Colors.withAlpha(Colors.accent, 0.18) : Colors.surface
            border.color: root.snapEnabled ? Colors.accent : "transparent"
            border.width: 1

            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }

            Text {
                id: snapLabel
                anchors.centerIn: parent
                text: I18n.t("desktop.snap")
                color: root.snapEnabled ? Colors.accent : Colors.textDim
                font.pixelSize: UIScale.fontSmall

                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }
            }

            HoverHandler {}
            TapHandler {
                onTapped: root.snapEnabled = !root.snapEnabled
            }
        }

        Rectangle {
            implicitWidth: doneLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
            implicitHeight: doneLabel.implicitHeight + Math.round(UIScale.spacingSm * 2)
            radius: height / 2
            color: doneHover.hovered ? Colors.accent : Colors.surface

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            Text {
                id: doneLabel
                anchors.centerIn: parent
                text: I18n.t("desktop.done")
                color: doneHover.hovered ? Colors.bg : Colors.text
                font.pixelSize: UIScale.fontSmall
                font.weight: Font.Medium

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
            }

            HoverHandler {
                id: doneHover
            }
            TapHandler {
                onTapped: DesktopWidgetStore.configMode = false
            }
        }
    }
}
