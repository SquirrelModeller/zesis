pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland._Screencopy
import "../../"

Item {
    id: root

    readonly property int discRadius: 55
    readonly property int chamberRadius: 36
    readonly property int chamberSize: 26
    readonly property int pad: 16

    implicitWidth: (discRadius + pad) * 2
    implicitHeight: (discRadius + pad) * 2

    readonly property int activeIndex: {
        var active = Hyprland.focusedMonitor?.activeWorkspace;
        if (!active)
            return 0;
        var id = parseInt(active.name);
        return isNaN(id) ? 0 : Math.max(0, Math.min(5, id - 1));
    }

    property bool expanded: false
    property int peekOffset: 16

    readonly property real discRotation: disc.rotation

    readonly property real discCX: expanded ? discRadius + pad : peekOffset
    readonly property real discCY: expanded ? discRadius + pad : peekOffset

    // Animated center, tracks the disc's actual visual position during transitions
    readonly property real visualDiscCX: disc.x + discRadius
    readonly property real visualDiscCY: disc.y + discRadius

    Timer {
        id: collapseTimer
        interval: 300
        onTriggered: root.expanded = false
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                collapseTimer.stop();
                root.expanded = true;
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
                duration: 350
                easing.type: Easing.InOutCubic
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: 350
                easing.type: Easing.InOutCubic
            }
        }

        // Rotate so the active chamber always sits at 45 degree (deepest visible corner point)
        rotation: 45 + root.activeIndex * 60

        Behavior on rotation {
            RotationAnimation {
                duration: 320
                direction: RotationAnimation.Shortest
                easing.type: Easing.InOutCubic
            }
        }

        // Disc body
        Rectangle {
            anchors.fill: parent
            radius: root.discRadius
            color: Colors.surface
            border.color: Colors.withAlpha(Colors.accent, 0.4)
            border.width: 1.5
        }

        // Groove rings (vinyl / revolver cylinder aesthetic)
        Rectangle {
            anchors.centerIn: parent
            width: root.chamberRadius * 2 + root.chamberSize + 12
            height: width
            radius: width / 2
            color: "transparent"
            border.color: Colors.withAlpha(Colors.accent, 0.12)
            border.width: 1
        }
        Rectangle {
            anchors.centerIn: parent
            width: root.chamberRadius * 2 - root.chamberSize - 8
            height: width
            radius: width / 2
            color: "transparent"
            border.color: Colors.withAlpha(Colors.accent, 0.12)
            border.width: 1
        }

        // Center pin
        Rectangle {
            anchors.centerIn: parent
            width: 10
            height: 10
            radius: 5
            color: Colors.accent
            opacity: 0.85
        }

        Repeater {
            model: 6
            delegate: Item {
                id: wsItem
                required property int index

                property int wsIndex: wsItem.index + 1
                property bool isActive: wsItem.index === root.activeIndex
                property bool hasWindows: Hyprland.workspaces.values.find(w => parseInt(w.name) === wsItem.wsIndex) !== undefined

                width: root.chamberSize
                height: root.chamberSize
                x: root.discRadius + Math.cos(wsItem.index * Math.PI / 3) * root.chamberRadius - root.chamberSize / 2
                y: root.discRadius - Math.sin(wsItem.index * Math.PI / 3) * root.chamberRadius - root.chamberSize / 2

                Rectangle {
                    anchors.fill: parent
                    radius: parent.width / 2
                    color: wsItem.isActive ? Colors.accent : (wsItem.hasWindows ? Colors.withAlpha(Colors.accent, 0.4) : Colors.surfaceHigh)
                    border.color: wsItem.isActive ? "#FCCD94" : Colors.withAlpha(Colors.accent, 0.2)
                    border.width: 1
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: wsItem.wsIndex
                    font.pixelSize: 11
                    font.bold: wsItem.isActive
                    color: wsItem.isActive ? Colors.surface : Colors.text
                    // Counter-rotate to stay upright as the disc spins
                    rotation: -root.discRotation
                }

                TapHandler {
                    enabled: root.expanded
                    onTapped: Hyprland.dispatch("hl.dsp.focus({ workspace = \"" + wsItem.wsIndex + "\"})")
                }

                HoverHandler {
                    id: chamberHover
                }

                PopupWindow {
                    id: wsPopup
                    visible: chamberHover.hovered && root.expanded && wsItem.hasWindows
                    color: "transparent"

                    anchor.item: wsItem
                    anchor.edges: Edges.Right | Edges.Top
                    anchor.gravity: Edges.Right | Edges.Bottom
                    anchor.adjustment: PopupAdjustment.All
                    anchor.margins.left: 8

                    property var wsMonitor: {
                        var ws = Hyprland.workspaces.values.find(w => parseInt(w.name) === wsItem.wsIndex);
                        return (ws && ws.monitor) ? ws.monitor : Hyprland.focusedMonitor;
                    }

                    readonly property int thumbW: 420
                    readonly property int thumbH: wsMonitor ? Math.round(thumbW * wsMonitor.height / wsMonitor.width) : 158
                    readonly property real thumbScale: wsMonitor ? thumbW / wsMonitor.width : 1
                    readonly property real monOffX: wsMonitor ? wsMonitor.x : 0
                    readonly property real monOffY: wsMonitor ? wsMonitor.y : 0

                    implicitWidth: thumbW + 2
                    implicitHeight: thumbH + 2

                    onVisibleChanged: if (visible)
                        Hyprland.refreshToplevels()

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
                                    model: Hyprland.toplevels.values.filter(t => t.workspace && parseInt(t.workspace.name) === wsItem.wsIndex)
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
