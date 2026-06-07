pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../../"

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

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Colors.bg
        border.color: Colors.outline
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Header: icon + sink name
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: root.volIcon(root.vol, root.muted)
                font.pixelSize: 16
                color: root.muted ? Colors.muted : Colors.accent
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.sink?.description || root.sink?.name || "No output"
                color: Colors.text
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }

        // Horizontal bar + % + mute on one row
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Bar track
            Item {
                Layout.fillWidth: true
                implicitHeight: 28

                Rectangle {
                    id: track
                    anchors.fill: parent
                    radius: 14
                    color: Colors.surface
                    border.color: Colors.outline
                    border.width: 1
                    clip: true

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.min(root.vol, 1.0)
                        color: root.muted ? Colors.muted : Colors.accent
                        opacity: root.muted ? 0.45 : 0.80

                        Behavior on width {
                            NumberAnimation {
                                duration: 60
                                easing.type: Easing.OutQuad
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        preventStealing: true
                        cursorShape: Qt.SizeHorCursor

                        onPressed: function (m) {
                            setVolFromX(m.x);
                        }
                        onPositionChanged: function (m) {
                            if (pressed)
                                setVolFromX(m.x);
                        }
                        onWheel: function (w) {
                            var audio = root.sink?.audio;
                            if (!audio)
                                return;
                            audio.volume = Math.max(0, Math.min(1.5, root.vol + w.angleDelta.y / 1200.0));
                        }

                        function setVolFromX(x) {
                            var audio = root.sink?.audio;
                            if (!audio)
                                return;
                            audio.volume = Math.max(0, Math.min(1.0, x / width));
                        }
                    }
                }
            }

            // Volume %
            Text {
                text: Math.round(root.vol * 100) + "%"
                color: Colors.text
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.family: "monospace"
                Layout.minimumWidth: 40
            }

            // Mute button
            Item {
                implicitWidth: 30
                implicitHeight: 30

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: root.muted ? Colors.withAlpha(Colors.accent, muteArea.containsMouse ? 0.30 : 0.18) : muteArea.containsMouse ? Colors.surfaceHigh : "transparent"
                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.muted ? "󰝟" : "󰕾"
                    font.pixelSize: 14
                    color: root.muted ? Colors.accent : Colors.textDim
                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                }

                MouseArea {
                    id: muteArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var audio = root.sink?.audio;
                        if (audio)
                            audio.muted = !audio.muted;
                    }
                }
            }
        }

        // Sink list
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Colors.outline
                Layout.topMargin: 4
            }

            Text {
                text: "OUTPUTS"
                color: Colors.textDim
                font.pixelSize: 9
                font.weight: Font.Medium
                font.letterSpacing: 1.2
                Layout.topMargin: 6
            }

            Repeater {
                model: ScriptModel {
                    values: Pipewire.ready ? Pipewire.nodes.values.filter(n => n.isSink && !n.isStream) : []
                }

                delegate: Item {
                    id: sinkRow
                    required property PwNode modelData
                    Layout.fillWidth: true
                    implicitHeight: 28

                    readonly property bool active: Pipewire.defaultAudioSink === sinkRow.modelData

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: sinkHover.containsMouse ? Colors.surface : "transparent"
                        Behavior on color {
                            ColorAnimation {
                                duration: 80
                            }
                        }
                    }

                    Rectangle {
                        id: activeDot
                        width: 6
                        height: 6
                        radius: 3
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: sinkRow.active ? Colors.accent : Colors.withAlpha(Colors.text, 0.22)
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }

                    Text {
                        anchors.left: activeDot.right
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        text: sinkRow.modelData.description || sinkRow.modelData.name || ""
                        color: sinkRow.active ? Colors.text : Colors.textDim
                        font.pixelSize: 12
                        font.weight: sinkRow.active ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }

                    MouseArea {
                        id: sinkHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Pipewire.preferredDefaultAudioSink = sinkRow.modelData
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
