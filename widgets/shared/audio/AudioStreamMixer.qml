pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import "../../../"
import "../"
import "../inputs"

// Volume mixer, per-app
ColumnLayout {
    id: root

    property bool isSource: true
    property string mutedGlyph: ""
    property string unmutedGlyph: ""
    property string mutedLabel: ""

    Layout.fillWidth: true
    spacing: UIScale.spacingSm

    SectionLabel {
        text: I18n.t("common.apps")
        color: Colors.textDim
        font.weight: Font.Medium
        Layout.leftMargin: UIScale.spacingMd + UIScale.spacingXs
        Layout.topMargin: UIScale.spacingXs
        visible: Pipewire.ready
    }

    Repeater {
        model: ScriptModel {
            values: (() => {
                    if (!Pipewire.ready)
                        return [];
                    const streams = Pipewire.nodes.values.filter(n => n.isStream && (root.isSource ? n.isSource : n.isSink));
                    return [...new Set(streams.map(n => n.name))];
                })()
        }

        delegate: Item {
            id: appGroup
            required property string modelData

            Layout.fillWidth: true
            Layout.leftMargin: UIScale.spacingMd
            Layout.rightMargin: UIScale.spacingMd
            implicitHeight: groupCard.implicitHeight

            readonly property var groupStreams: Pipewire.ready ? Pipewire.nodes.values.filter(n => n.isStream && (root.isSource ? n.isSource : n.isSink) && n.name === appGroup.modelData) : []
            readonly property string appIconName: groupStreams.length > 0 ? (groupStreams[0].properties["application.icon-name"] ?? "") : ""
            readonly property bool groupAllMuted: groupStreams.length > 0 && groupStreams.every(n => n.audio?.muted ?? false)

            PwObjectTracker {
                objects: appGroup.groupStreams
            }

            Rectangle {
                id: groupCard
                anchors.left: parent.left
                anchors.right: parent.right
                radius: UIScale.radiusMd
                color: Colors.surface
                implicitHeight: groupInner.implicitHeight + Math.round(20 * UIScale.value)

                ColumnLayout {
                    id: groupInner
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: UIScale.spacingSm
                    }
                    spacing: UIScale.spacingSm

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: UIScale.spacingSm

                        Rectangle {
                            implicitWidth: Math.round(32 * UIScale.value)
                            implicitHeight: Math.round(32 * UIScale.value)
                            radius: UIScale.spacingSm
                            color: appGroup.groupAllMuted ? Colors.surfaceHigh : (badgeHover.hovered ? Colors.withAlpha(Colors.accent, 0.28) : Colors.withAlpha(Colors.accent, 0.15))
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: Math.round(18 * UIScale.value)
                                source: (!appGroup.groupAllMuted && appGroup.appIconName) ? "image://icon/" + appGroup.appIconName : ""
                                smooth: true
                                mipmap: true
                                visible: !appGroup.groupAllMuted && appGroup.appIconName !== ""
                            }

                            Text {
                                anchors.centerIn: parent
                                text: appGroup.groupAllMuted ? root.mutedGlyph : root.unmutedGlyph
                                font.pixelSize: Math.round(16 * UIScale.value)
                                color: appGroup.groupAllMuted ? Colors.muted : Colors.accent
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Anim.fast
                                    }
                                }
                                visible: appGroup.groupAllMuted || appGroup.appIconName === ""
                            }

                            HoverHandler {
                                id: badgeHover
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const mute = !appGroup.groupAllMuted;
                                    for (const n of appGroup.groupStreams) {
                                        if (n.audio)
                                            n.audio.muted = mute;
                                    }
                                }
                            }
                        }

                        Text {
                            text: appGroup.modelData
                            color: Colors.text
                            font.pixelSize: UIScale.fontSmall
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    Repeater {
                        model: ScriptModel {
                            values: appGroup.groupStreams
                        }

                        delegate: ColumnLayout {
                            id: streamItem
                            required property PwNode modelData
                            Layout.fillWidth: true
                            spacing: UIScale.spacingXs

                            readonly property real streamVol: streamItem.modelData.audio?.volume ?? 0
                            readonly property bool streamMuted: streamItem.modelData.audio?.muted ?? false
                            readonly property string streamLabel: streamItem.modelData.properties["media.name"] || ""

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: streamItem.streamLabel
                                    color: streamItem.streamMuted ? Colors.textDim : Colors.text
                                    font.pixelSize: UIScale.fontTiny
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Anim.fast
                                        }
                                    }
                                }

                                Text {
                                    text: streamItem.streamMuted ? root.mutedLabel : (Math.round(streamItem.streamVol * 100) + "%")
                                    color: streamItem.streamMuted ? Colors.textDim : Colors.accent
                                    font.pixelSize: UIScale.fontTiny
                                    font.family: "monospace"
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Anim.fast
                                        }
                                    }
                                }
                            }

                            SettingSlider {
                                Layout.fillWidth: true
                                implicitHeight: Math.round(16 * UIScale.value)
                                handleSize: Math.round(13 * UIScale.value)
                                from: 0
                                to: 100
                                step: 1
                                value: Math.round(Math.min(streamItem.streamVol, 1.0) * 100)
                                muted: streamItem.streamMuted
                                onMoved: function (v) {
                                    var a = streamItem.modelData.audio;
                                    if (a)
                                        a.volume = v / 100;
                                }
                                onWheeled: function (delta) {
                                    var a = streamItem.modelData.audio;
                                    if (a)
                                        a.volume = Math.max(0, Math.min(1.0, streamItem.streamVol + delta / 1200.0));
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
