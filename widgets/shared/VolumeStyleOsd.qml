import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../"
import "../sound"

// Shared pill-style OSD for volume-like controls (output volume, mic gain).
// Host supplies the live value/mute state, the audio node to drag against, an
// icon-selection function, and the i18n key for the muted label - everything
// else (show/hide timing, drag handling, animations) is identical between
// VolumeOsd and MicOsd and lives here once.
PanelWindow {
    id: root

    property real vol: 0
    property bool muted: false
    property QtObject audioTarget: null
    required property var iconFor
    required property string mutedTextKey

    readonly property string osdPosition: AudioService.osdPosition
    // Docked to a side edge the pill stands on end, so it runs along the edge
    // it hugs rather than jutting out into the screen.
    readonly property bool vertical: osdPosition === "left" || osdPosition === "right"
    // Gap between the screen edge the pill docks to and the pill itself.
    readonly property real edgeGap: Math.round(70 * UIScale.value)
    // Slack around the pill so the show animation's scale overshoot has room
    // inside the surface bounds.
    readonly property real _pad: Math.round(8 * UIScale.value)
    readonly property real _dockMargin: Math.round(root.edgeGap - root._pad)

    WlrLayershell.layer: WlrLayer.Overlay
    // Named so the compositor can target the surface, e.g. to opt its map
    // animation out with Hyprland's `layerrule = noanim, zesis:osd`.
    WlrLayershell.namespace: "zesis:osd"
    // Anchored to the single edge the pill docks to: the compositor centers a
    // layer surface along the axis it is not anchored on, and plays its map
    // animation out of the edge it is anchored to. Anchoring elsewhere and
    // pushing the surface over with margins makes it fly in from the wrong
    // side. Margins on unanchored edges are ignored, so all four can carry the
    // same gap.
    anchors {
        top: root.osdPosition === "top"
        bottom: root.osdPosition === "bottom"
        left: root.osdPosition === "left"
        right: root.osdPosition === "right"
    }
    margins {
        top: root._dockMargin
        bottom: root._dockMargin
        left: root._dockMargin
        right: root._dockMargin
    }
    exclusiveZone: -1
    implicitWidth: osdRect.implicitWidth + root._pad * 2
    implicitHeight: osdRect.implicitHeight + root._pad * 2
    color: "transparent"
    visible: false

    property bool _ready: false
    property bool _dragging: false
    property bool _hovered: false

    Timer {
        interval: 500
        running: true
        onTriggered: root._ready = true
    }

    function _show() {
        if (!_ready || !AudioService.osdEnabled)
            return;
        if (!visible) {
            osdPill.opacity = 0;
            osdPill.scale = 0.88;
            visible = true;
        }
        osdShowAnim.restart();
        osdDismissTimer.restart();
    }

    onVolChanged: _show()
    onMutedChanged: _show()

    Timer {
        id: osdDismissTimer
        interval: 1500
        onTriggered: {
            if (!root._hovered && !root._dragging)
                osdHideAnim.start();
        }
    }

    ParallelAnimation {
        id: osdShowAnim
        NumberAnimation {
            target: osdPill
            property: "opacity"
            to: 1
            duration: Anim.fast
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: osdPill
            property: "scale"
            to: 1
            duration: Anim.medium
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
    }

    SequentialAnimation {
        id: osdHideAnim
        NumberAnimation {
            target: osdPill
            property: "opacity"
            to: 0
            duration: Anim.medium
            easing.type: Easing.InCubic
        }
        ScriptAction {
            script: root.visible = false
        }
    }

    Item {
        id: osdPill

        anchors.centerIn: parent
        width: osdRect.implicitWidth
        height: osdRect.implicitHeight
        opacity: 0
        scale: 0.88
        transformOrigin: {
            switch (root.osdPosition) {
            case "bottom":
                return Item.Bottom;
            case "left":
                return Item.Left;
            case "right":
                return Item.Right;
            default:
                return Item.Top;
            }
        }

        HoverHandler {
            onHoveredChanged: {
                root._hovered = hovered;
                if (!hovered && !root._dragging)
                    osdDismissTimer.restart();
                else
                    osdDismissTimer.stop();
            }
        }

        Rectangle {
            id: osdRect
            implicitWidth: Math.round((root.vertical ? 64 : 280) * UIScale.value)
            implicitHeight: Math.round((root.vertical ? 280 : 52) * UIScale.value)
            radius: Math.min(implicitWidth, implicitHeight) / 2
            color: Colors.surface
            border.color: Colors.withAlpha(Colors.outline, 0.8)
            border.width: 1

            // One layout for both orientations: the icon, the track and the
            // readout keep their identity (and their state) across a flip
            // instead of being duplicated into a row and a column variant.
            GridLayout {
                id: osdContent

                readonly property real padX: Math.round((root.vertical ? 8 : 16) * UIScale.value)
                readonly property real padY: Math.round((root.vertical ? 16 : 0) * UIScale.value)

                anchors.fill: parent
                anchors.leftMargin: osdContent.padX
                anchors.rightMargin: osdContent.padX
                anchors.topMargin: osdContent.padY
                anchors.bottomMargin: osdContent.padY
                flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                rows: 3
                columns: 3
                rowSpacing: Math.round(10 * UIScale.value)
                columnSpacing: osdContent.rowSpacing

                Text {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    text: root.iconFor(root.vol, root.muted)
                    font.pixelSize: Math.round(20 * UIScale.value)
                    color: root.muted ? Colors.muted : Colors.accent
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                }

                Item {
                    id: osdSlider
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    Layout.fillWidth: !root.vertical
                    Layout.fillHeight: root.vertical
                    implicitWidth: root.vertical ? Math.round(8 * UIScale.value) : 0
                    implicitHeight: root.vertical ? 0 : Math.round(8 * UIScale.value)

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.min(width, height) / 2
                        color: Colors.surfaceHigh

                        Rectangle {
                            // A vertical track fills upwards from its floor.
                            width: root.vertical ? parent.width : parent.width * Math.min(root.vol, 1.0)
                            height: root.vertical ? parent.height * Math.min(root.vol, 1.0) : parent.height
                            y: root.vertical ? parent.height - height : 0
                            radius: parent.radius
                            color: root.muted ? Colors.muted : Colors.accent
                            opacity: root.muted ? 0.45 : 1.0
                            Behavior on width {
                                NumberAnimation {
                                    duration: Anim.drag
                                    easing.type: Easing.OutQuad
                                }
                            }
                            Behavior on height {
                                NumberAnimation {
                                    duration: Anim.drag
                                    easing.type: Easing.OutQuad
                                }
                            }
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: osdSliderArea
                        anchors.centerIn: parent
                        width: root.vertical ? Math.round(44 * UIScale.value) : parent.width
                        height: root.vertical ? parent.height : Math.round(44 * UIScale.value)
                        cursorShape: root.vertical ? Qt.SizeVerCursor : Qt.SizeHorCursor
                        preventStealing: true
                        function setVol(m) {
                            var a = root.audioTarget;
                            if (!a)
                                return;
                            var f = root.vertical ? 1 - m.y / osdSliderArea.height : m.x / osdSliderArea.width;
                            a.volume = Math.max(0, Math.min(1.0, f));
                        }
                        onPressed: function (m) {
                            setVol(m);
                        }
                        onPositionChanged: function (m) {
                            if (pressed) {
                                setVol(m);
                                root._dragging = true;
                                osdDismissTimer.stop();
                            }
                        }
                        onReleased: {
                            root._dragging = false;
                            if (!root._hovered)
                                osdDismissTimer.restart();
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    Layout.fillWidth: root.vertical
                    text: root.muted ? I18n.t(root.mutedTextKey) : (Math.round(root.vol * 100) + "%")
                    color: root.muted ? Colors.muted : Colors.text
                    font.pixelSize: Math.round(13 * UIScale.value)
                    font.family: "monospace"
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                }
            }
        }
    }
}
