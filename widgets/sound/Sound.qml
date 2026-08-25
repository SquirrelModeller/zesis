pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire
import "../../"
import "../shared"
import "../shared/audio"
import "../shared/inputs"

Item {
    id: root

    readonly property PwNode sink: AudioService.sink
    readonly property real vol: AudioService.vol
    readonly property bool muted: AudioService.muted

    function volIcon(v, m) {
        if (m || v === 0)
            return "󰝟";
        if (v < 0.33)
            return "󰕿";
        if (v < 0.67)
            return "󰖀";
        return "󰕾";
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("sound.breadcrumb")
            title: I18n.t("sound.title")
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

                // Master card
                AudioMasterCard {
                    icon: root.volIcon(root.vol, root.muted)
                    label: I18n.t("sound.master")
                    vol: root.vol
                    muted: root.muted
                    onMuteToggled: {
                        var a = root.sink?.audio;
                        if (a)
                            a.muted = !a.muted;
                    }
                    onVolumeMoved: function (v) {
                        var a = root.sink?.audio;
                        if (a)
                            a.volume = v / 100;
                    }
                    onVolumeWheeled: function (delta) {
                        var a = root.sink?.audio;
                        if (a)
                            a.volume = Math.max(0, Math.min(1.0, root.vol + delta / 1200.0));
                    }
                }

                // Per-app streams
                AudioStreamMixer {
                    isSource: false
                    mutedGlyph: "󰝟"
                    unmutedGlyph: "󰓃"
                    mutedLabel: I18n.t("sound.muted")
                }

                Item {
                    implicitHeight: UIScale.spacingXs
                }

                // OSD toggle
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.spacingMd
                    Layout.rightMargin: UIScale.spacingMd
                    radius: UIScale.radiusMd
                    color: Colors.surface
                    implicitHeight: Math.round(44 * UIScale.value)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: UIScale.spacingMd
                        anchors.rightMargin: UIScale.spacingMd

                        Text {
                            text: I18n.t("sound.volumeOsdLabel")
                            color: Colors.text
                            font.pixelSize: UIScale.fontTiny
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                        }

                        ToggleSwitch {
                            implicitWidth: Math.round(36 * UIScale.value)
                            implicitHeight: Math.round(20 * UIScale.value)
                            knobColor: "white"
                            checked: AudioService.osdEnabled
                            onToggled: AudioService.osdEnabled = !AudioService.osdEnabled
                        }
                    }
                }

                Item {
                    implicitHeight: UIScale.spacingXs
                }

                // Output device
                MorphComboBox {
                    id: sinkCombo
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.spacingMd
                    Layout.rightMargin: UIScale.spacingMd
                    Layout.bottomMargin: UIScale.spacingMd
                    implicitHeight: Math.round(44 * UIScale.value)

                    model: Pipewire.ready ? Pipewire.nodes.values.filter(n => n.isSink && !n.isStream).map(n => ({
                                value: n.id,
                                label: n.description || n.name || ""
                            })) : []
                    selectedValue: root.sink?.id

                    onChosen: value => {
                        var node = Pipewire.nodes.values.find(n => n.id === value);
                        if (node)
                            Pipewire.preferredDefaultAudioSink = node;
                    }

                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: UIScale.spacingMd
                        anchors.rightMargin: sinkCombo.indicator.width + UIScale.spacingMd
                        spacing: UIScale.spacingSm

                        Text {
                            text: "󰋋"
                            font.pixelSize: Math.round(16 * UIScale.value)
                            color: Colors.accent
                        }

                        Text {
                            Layout.fillWidth: true
                            text: I18n.t("sound.outputWithName", [root.sink?.description || root.sink?.name || I18n.t("sound.noOutput")])
                            color: Colors.text
                            font.pixelSize: UIScale.fontTiny
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                    }

                    delegate: ItemDelegate {
                        id: sinkItem
                        required property var modelData
                        required property int index
                        width: ListView.view ? ListView.view.width : sinkCombo.width
                        implicitHeight: Math.round(36 * UIScale.value)
                        padding: 0

                        readonly property bool active: sinkCombo.currentIndex === sinkItem.index

                        background: Rectangle {
                            radius: UIScale.spacingSm
                            color: "transparent"

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: Colors.accent
                                opacity: sinkItem.active ? 0 : (sinkItem.hovered ? 0.08 : 0)
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Anim.fast
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Anim.standard
                                    }
                                }
                            }
                        }

                        contentItem: Item {
                            Rectangle {
                                width: Math.round(6 * UIScale.value)
                                height: Math.round(6 * UIScale.value)
                                radius: UIScale.radiusSm / 2
                                anchors.left: parent.left
                                anchors.leftMargin: UIScale.spacingSm
                                anchors.verticalCenter: parent.verticalCenter
                                color: sinkItem.active ? Colors.accent : Colors.withAlpha(Colors.text, 0.22)
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Anim.fast
                                    }
                                }
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: Math.round(22 * UIScale.value)
                                anchors.right: parent.right
                                anchors.rightMargin: UIScale.spacingSm
                                anchors.verticalCenter: parent.verticalCenter
                                text: sinkItem.modelData.label
                                color: sinkItem.active ? Colors.text : Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                                font.weight: sinkItem.active ? Font.DemiBold : Font.Normal
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
        }
    }
}
