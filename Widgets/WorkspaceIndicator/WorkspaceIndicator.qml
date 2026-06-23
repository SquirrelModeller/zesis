pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland._Screencopy
import "../Wm"
import "../../"

Item {
    id: root

    readonly property int discRadius: Math.round(WorkspaceIndicatorService.discRadius * UIScale.value)
    readonly property int chamberRadius: Math.round(WorkspaceIndicatorService.chamberRadius * UIScale.value)
    readonly property int chamberSize: Math.round(WorkspaceIndicatorService.chamberSize * UIScale.value)
    readonly property int pad: Math.round(16 * UIScale.value)
    readonly property int workSpaceAmount: WorkspaceIndicatorService.workSpaceAmount
    readonly property int peekOffset: Math.round(WorkspaceIndicatorService.peekOffset * UIScale.value)

    implicitWidth: (discRadius + pad) * 2
    implicitHeight: (discRadius + pad) * 2

    readonly property var sortedWsIds: {
        var ids = WmService.workspaces.map(w => parseInt(w.name)).filter(n => !isNaN(n) && n > 0);
        ids.sort((a, b) => a - b);
        return ids;
    }

    readonly property int effectiveN: WorkspaceIndicatorService.expressive ? Math.max(WorkspaceIndicatorService.minWorkSpaceAmount, root.sortedWsIds.length) : root.workSpaceAmount

    readonly property int activeIndex: {
        var active = WmService.focusedMonitor?.activeWorkspace;
        if (!active)
            return 0;
        var id = parseInt(active.name);
        if (isNaN(id))
            return 0;
        if (WorkspaceIndicatorService.expressive) {
            var idx = root.sortedWsIds.indexOf(id);
            return idx >= 0 ? idx : 0;
        }
        return Math.max(0, Math.min(root.effectiveN - 1, id - 1));
    }

    property bool forceExpanded: false
    property bool _hoveredExpanded: false
    readonly property bool expanded: root.forceExpanded || root._hoveredExpanded

    readonly property real discRotation: disc.rotation

    readonly property real discCX: expanded ? discRadius + pad : peekOffset
    readonly property real discCY: expanded ? discRadius + pad : peekOffset

    // Animated center, tracks the disc's actual visual position during transitions
    readonly property real visualDiscCX: disc.x + discRadius
    readonly property real visualDiscCY: disc.y + discRadius

    Timer {
        id: collapseTimer
        interval: Anim.slow
        onTriggered: root._hoveredExpanded = false
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                collapseTimer.stop();
                root._hoveredExpanded = true;
            } else {
                collapseTimer.restart();
            }
        }
    }

    Item {
        id: disc
        width: root.discRadius * 2
        height: root.discRadius * 2

        // Center at (0,0) when collapsed -> only bottom-right quadrant peeks from corner
        // Center at (discRadius+pad, discRadius+pad) when expanded -> full disc visible
        x: root.discCX - root.discRadius
        y: root.discCY - root.discRadius

        Behavior on x {
            NumberAnimation {
                duration: Anim.slow
                easing.type: Easing.InOutCubic
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: Anim.slow
                easing.type: Easing.InOutCubic
            }
        }

        // Rotate so the active chamber always sits at 45 degree (deepest visible corner point)
        rotation: 45 + root.activeIndex * (360 / root.effectiveN)

        Behavior on rotation {
            RotationAnimation {
                duration: Anim.slow
                direction: RotationAnimation.Shortest
                easing.type: Easing.InOutCubic
            }
        }

        // Gear body, drawn once, rotated cheaply via disc's RotationAnimation
        // Without canvas: 42064
        Canvas {
            id: gearCanvas
            anchors.fill: parent
            rotation: (WorkspaceIndicatorService.toothWidth / 200) * (360 / root.effectiveN)

            readonly property color _surface: Colors.surface
            readonly property color _accent: Colors.accent
            readonly property int _n: root.effectiveN
            readonly property int _discRadius: root.discRadius
            readonly property int _toothWidth: WorkspaceIndicatorService.toothWidth
            readonly property int _valleyDepth: WorkspaceIndicatorService.valleyDepth
            on_SurfaceChanged: requestPaint()
            on_AccentChanged: requestPaint()
            on_NChanged: requestPaint()
            on_DiscRadiusChanged: requestPaint()
            on_ToothWidthChanged: requestPaint()
            on_ValleyDepthChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var W = WorkspaceIndicatorService.toothWidth / 100, D = WorkspaceIndicatorService.valleyDepth / 100, N = root.effectiveN;
                var rOut = root.discRadius;
                var rIn = rOut * (1 - D);
                var cx = root.discRadius;
                var cy = root.discRadius;
                var steps = N * 64;

                ctx.beginPath();
                for (var i = 0; i <= steps; i++) {
                    var angle = -(i / steps) * 2 * Math.PI;
                    var t = ((-angle * N) / (2 * Math.PI) % 1 + 1) % 1;
                    var blend = (t < W) ? 1.0 : Math.pow(Math.cos(Math.PI * (t - W) / (1 - W)), 4);
                    var r = rIn + (rOut - rIn) * blend;
                    var x = cx + r * Math.cos(angle);
                    var y = cy + r * Math.sin(angle);
                    if (i === 0)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }
                ctx.closePath();
                ctx.fillStyle = Colors.surface;
                ctx.fill();
                ctx.strokeStyle = Colors.withAlpha(Colors.accent, 0.4);
                ctx.lineWidth = 1.5 * UIScale.value;
                ctx.lineJoin = "round";
                ctx.stroke();
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.round(10 * UIScale.value)
            height: Math.round(10 * UIScale.value)
            radius: Math.round(5 * UIScale.value)
            color: Colors.accent
            opacity: 0.85
        }

        Repeater {
            model: root.effectiveN
            delegate: Item {
                id: wsItem
                required property int index

                property int wsIndex: WorkspaceIndicatorService.expressive ? (root.sortedWsIds[wsItem.index] ?? wsItem.index + 1) : wsItem.index + 1
                property bool isActive: wsItem.index === root.activeIndex
                property bool hasWindows: WmService.toplevels.some(t => t.workspace && parseInt(t.workspace.name) === wsItem.wsIndex)

                width: root.chamberSize
                height: root.chamberSize
                x: root.discRadius + Math.cos(wsItem.index * 2 * Math.PI / root.effectiveN) * root.chamberRadius - root.chamberSize / 2
                y: root.discRadius - Math.sin(wsItem.index * 2 * Math.PI / root.effectiveN) * root.chamberRadius - root.chamberSize / 2

                Rectangle {
                    anchors.fill: parent
                    radius: parent.width / 2
                    color: wsItem.isActive ? Colors.accent : (wsItem.hasWindows ? Colors.withAlpha(Colors.accent, 0.4) : Colors.surfaceHigh)
                    border.color: wsItem.isActive ? Colors.withAlpha(Colors.onAccent, 0.6) : Colors.withAlpha(Colors.accent, 0.2)
                    border.width: 1
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: wsItem.wsIndex
                    font.pixelSize: UIScale.fontTiny
                    font.bold: wsItem.isActive
                    color: wsItem.isActive ? Colors.surface : Colors.text
                    // Counter-rotate to stay upright as the disc spins
                    rotation: -root.discRotation
                }

                MouseArea {
                    id: chamberMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (root.expanded)
                            WmService.focusWorkspace(wsItem.wsIndex);
                    }
                }

                PopupWindow {
                    id: wsPopup
                    visible: chamberMouseArea.containsMouse && root.expanded && wsItem.hasWindows
                    color: "transparent"

                    anchor.item: wsItem
                    anchor.edges: Edges.Right | Edges.Top
                    anchor.gravity: Edges.Right | Edges.Bottom
                    anchor.adjustment: PopupAdjustment.All
                    anchor.margins.left: 8

                    property var wsMonitor: {
                        var ws = WmService.workspaces.find(w => parseInt(w.name) === wsItem.wsIndex);
                        return (ws && ws.monitor) ? ws.monitor : WmService.focusedMonitor;
                    }

                    readonly property int thumbW: 420
                    readonly property int thumbH: wsMonitor ? Math.round(thumbW * wsMonitor.height / wsMonitor.width) : 158
                    readonly property real thumbScale: wsMonitor ? thumbW / wsMonitor.width : 1
                    readonly property real monOffX: wsMonitor ? wsMonitor.x : 0
                    readonly property real monOffY: wsMonitor ? wsMonitor.y : 0

                    implicitWidth: thumbW + 2
                    implicitHeight: thumbH + 2

                    onVisibleChanged: if (visible)
                        WmService.refreshToplevels()

                    Loader {
                        active: wsPopup.visible
                        anchors.fill: parent
                        sourceComponent: Rectangle {
                            color: Colors.bg
                            border.color: Colors.withAlpha(Colors.accent, 0.35)
                            border.width: 1
                            radius: 6
                            clip: true

                            Item {
                                x: 1
                                y: 1
                                width: wsPopup.thumbW
                                height: wsPopup.thumbH
                                clip: true

                                Repeater {
                                    model: WmService.toplevels.filter(t => t.workspace && parseInt(t.workspace.name) === wsItem.wsIndex)
                                    delegate: Item {
                                        id: winItem
                                        required property var modelData

                                        x: {
                                            var at = winItem.modelData.lastIpcObject["at"];
                                            return at ? (at[0] - wsPopup.monOffX) * wsPopup.thumbScale : 0;
                                        }
                                        y: {
                                            var at = winItem.modelData.lastIpcObject["at"];
                                            return at ? (at[1] - wsPopup.monOffY) * wsPopup.thumbScale : 0;
                                        }
                                        width: {
                                            var sz = winItem.modelData.lastIpcObject["size"];
                                            return sz ? sz[0] * wsPopup.thumbScale : 50;
                                        }
                                        height: {
                                            var sz = winItem.modelData.lastIpcObject["size"];
                                            return sz ? sz[1] * wsPopup.thumbScale : 50;
                                        }

                                        ScreencopyView {
                                            anchors.fill: parent
                                            captureSource: winItem.modelData.wayland
                                            live: true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
