pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../../"
import "../shared"
import "../shared/audio"

Item {
    id: root

    readonly property PwNode source: MicService.source
    readonly property real vol: MicService.vol
    readonly property bool muted: MicService.muted
    property bool sourceListOpen: false

    Connections {
        target: Pipewire
        function onDefaultAudioSourceChanged() {
            root.sourceListOpen = false;
        }
    }

    function micIcon(v, m) {
        if (m || v === 0)
            return "󰍭";
        return "󰍬";
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("mic.breadcrumb")
            title: I18n.t("mic.title")
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: col.implicitHeight
            clip: true
            flickableDirection: Flickable.VerticalFlick

            ColumnLayout {
                id: col
                width: flick.width
                spacing: UIScale.spacingSm

                Item {
                    implicitHeight: UIScale.spacingXs
                }

                // Master mic card
                AudioMasterCard {
                    icon: root.micIcon(root.vol, root.muted)
                    label: I18n.t("mic.input")
                    vol: root.vol
                    muted: root.muted
                    onMuteToggled: {
                        var a = root.source?.audio;
                        if (a)
                            a.muted = !a.muted;
                    }
                    onVolumeMoved: function (v) {
                        var a = root.source?.audio;
                        if (a)
                            a.volume = v / 100;
                    }
                    onVolumeWheeled: function (delta) {
                        var a = root.source?.audio;
                        if (a)
                            a.volume = Math.max(0, Math.min(1.0, root.vol + delta / 1200.0));
                    }
                }

                // Per-app capture streams
                AudioStreamMixer {
                    isSource: true
                    mutedGlyph: "󰍭"
                    unmutedGlyph: "󰍬"
                    mutedLabel: I18n.t("mic.muted")
                }

                Item {
                    implicitHeight: UIScale.spacingXs
                }

                // Input device selector
                Column {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.spacingMd
                    Layout.rightMargin: UIScale.spacingMd
                    Layout.bottomMargin: UIScale.spacingMd
                    spacing: Math.round(2 * UIScale.value)

                    Rectangle {
                        width: parent.width
                        height: Math.round(44 * UIScale.value)
                        radius: UIScale.radiusMd
                        color: sourceHeaderHover.hovered ? Colors.surfaceHigh : Colors.surface
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: UIScale.spacingMd
                            anchors.rightMargin: UIScale.spacingMd
                            spacing: UIScale.spacingSm

                            Text {
                                text: "󰍬"
                                font.pixelSize: Math.round(16 * UIScale.value)
                                color: Colors.accent
                            }

                            Text {
                                text: I18n.t("mic.inputWithName", [root.source?.description || root.source?.name || I18n.t("mic.noInput")])
                                color: Colors.text
                                font.pixelSize: UIScale.fontTiny
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: root.sourceListOpen ? "⌄" : "⌃"
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                            }
                        }

                        HoverHandler {
                            id: sourceHeaderHover
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.sourceListOpen = !root.sourceListOpen
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: sourceCol.implicitHeight + UIScale.spacingSm
                        radius: UIScale.radiusMd
                        color: Colors.surface
                        visible: root.sourceListOpen
                        clip: true

                        Column {
                            id: sourceCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: UIScale.spacingXs
                            spacing: 0

                            Repeater {
                                model: ScriptModel {
                                    values: Pipewire.ready ? Pipewire.nodes.values.filter(n => n.isSource && !n.isStream) : []
                                }

                                delegate: Item {
                                    id: sourceRow
                                    required property PwNode modelData
                                    width: parent.width
                                    height: Math.round(36 * UIScale.value)

                                    readonly property bool active: Pipewire.defaultAudioSource === sourceRow.modelData

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: Math.round(2 * UIScale.value)
                                        radius: UIScale.radiusSm
                                        color: sourceRow.active ? Colors.withAlpha(Colors.accent, 0.15) : (sourceMa.pressed ? Colors.surfaceHigh : "transparent")
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Anim.micro
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: Math.round(6 * UIScale.value)
                                        height: Math.round(6 * UIScale.value)
                                        radius: UIScale.radiusSm / 2
                                        anchors.left: parent.left
                                        anchors.leftMargin: UIScale.spacingSm
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: sourceRow.active ? Colors.accent : Colors.withAlpha(Colors.text, 0.22)
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Anim.fast
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: Math.round(26 * UIScale.value)
                                        anchors.right: parent.right
                                        anchors.rightMargin: UIScale.spacingSm
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: sourceRow.modelData.description || sourceRow.modelData.name || ""
                                        color: sourceRow.active ? Colors.text : Colors.textDim
                                        font.pixelSize: UIScale.fontTiny
                                        font.weight: sourceRow.active ? Font.DemiBold : Font.Normal
                                        elide: Text.ElideRight
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Anim.fast
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: sourceMa
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Pipewire.preferredDefaultAudioSource = sourceRow.modelData
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
