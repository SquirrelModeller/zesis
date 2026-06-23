pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../"
import "../Shared"

Item {
    id: root

    property real _bootSeconds: 0
    property real _displaySeconds: 0
    property string _kernel: ""
    property string _osVersion: ""
    property int _quoteIndex: 0

    readonly property var _quotes: ["made with questionable life choices", "it works on my machine", "we test in prod", "marvin was here", "check out my blog", "we are not finishing this storyline.\nwe are doing the side quests.", "because pain builds character"]

    Component.onCompleted: _quoteIndex = Math.floor(Math.random() * _quotes.length)

    Process {
        command: ["sh", "-c", "awk '{print $1}' /proc/uptime"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root._bootSeconds = parseFloat(data.trim());
                root._displaySeconds = root._bootSeconds;
                uptimeTicker.running = true;
            }
        }
    }

    Process {
        command: ["uname", "-r"]
        running: true
        stdout: SplitParser {
            onRead: data => root._kernel = data.trim()
        }
    }

    Process {
        command: ["sh", "-c", "nixos-version 2>/dev/null | sed 's/\\([0-9]*\\.[0-9]*\\)\\.[0-9]*\\.[a-f0-9]*/\\1/' || grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '\"'"]
        running: true
        stdout: SplitParser {
            onRead: data => root._osVersion = data.trim()
        }
    }

    Timer {
        id: uptimeTicker
        interval: 1000
        repeat: true
        running: false
        onTriggered: root._displaySeconds += 1
    }

    function formatUptime(secs) {
        var s = Math.floor(secs);
        var d = Math.floor(s / 86400);
        var h = Math.floor((s % 86400) / 3600);
        var m = Math.floor((s % 3600) / 60);
        var sc = s % 60;
        var parts = [];
        if (d > 0)
            parts.push(d + "d");
        if (h > 0)
            parts.push(h + "h");
        if (m > 0)
            parts.push(m + "m");
        parts.push((sc < 10 ? "0" : "") + sc + "s");
        return parts.join(" ");
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: "SYSTEM / ABOUT"
            title: "About"
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent
                spacing: UIScale.spacingLg

                Canvas {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 72

                    NumberAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 9000
                        loops: Animation.Infinite
                        running: true
                    }

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var W = 0.4, D = 0.28, N = 6;
                        var rOut = 32, rIn = rOut * (1 - D);
                        var cx = 36, cy = 36;
                        var steps = N * 48;
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
                        ctx.fillStyle = Colors.withAlpha(Colors.accent, 0.15);
                        ctx.fill();
                        ctx.strokeStyle = Colors.accent;
                        ctx.lineWidth = 1.5;
                        ctx.lineJoin = "round";
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.arc(cx, cy, 5, 0, 2 * Math.PI);
                        ctx.fillStyle = Colors.accent;
                        ctx.fill();
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "zesis"
                    color: Colors.text
                    font.pixelSize: UIScale.fontHero
                    font.weight: Font.ExtraBold
                    font.family: "monospace"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root._quotes[root._quoteIndex]
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontBody
                    font.italic: true

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root._quoteIndex = (root._quoteIndex + 1) % root._quotes.length
                    }
                }

                Divider {}

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: UIScale.spacingXs

                    Text {
                        text: "TIME WASTED THIS SESSION"
                        color: Colors.muted
                        font.pixelSize: UIScale.fontTiny
                        font.weight: Font.Bold
                        font.letterSpacing: 1.5
                    }

                    Text {
                        text: root.formatUptime(root._displaySeconds)
                        color: Colors.accent
                        font.pixelSize: UIScale.fontSubhead
                        font.family: "monospace"
                        font.weight: Font.DemiBold
                    }
                }

                Divider {}

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: UIScale.spacingXs

                    Text {
                        text: "SYSTEM"
                        color: Colors.muted
                        font.pixelSize: UIScale.fontTiny
                        font.weight: Font.Bold
                        font.letterSpacing: 1.5
                    }

                    InfoRow {
                        label: "Kernel"
                        value: root._kernel
                    }
                    InfoRow {
                        label: "OS"
                        value: root._osVersion
                    }

                    Text {
                        visible: root._osVersion.toLowerCase().includes("arch")
                        text: "have you considered nixos"
                        color: Colors.withAlpha(Colors.textDim, 0.4)
                        font.pixelSize: UIScale.fontTiny
                        font.italic: true
                        Layout.topMargin: UIScale.spacingXs
                    }
                }
            }
        }
    }

    component InfoRow: RowLayout {
        id: infoRowRoot
        property string label: ""
        property string value: ""
        Layout.fillWidth: true
        spacing: UIScale.spacingSm

        Text {
            text: infoRowRoot.label
            color: Colors.textDim
            font.pixelSize: UIScale.fontBody
            Layout.preferredWidth: Math.round(80 * UIScale.value)
        }

        Text {
            text: infoRowRoot.value || "-"
            color: Colors.text
            font.pixelSize: UIScale.fontBody
            font.family: "monospace"
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }
}
