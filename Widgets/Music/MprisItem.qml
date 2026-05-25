import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell.Services.Mpris

// Credit of idea / Spinning disc code
// https://github.com/Rexcrazy804/Zaphkiel

Rectangle {
    id: mprisroot

    required property MprisPlayer player
    required property real discScale
    readonly property real rotationStep: 3

    readonly property color backgroundColor: "#80000000"
    readonly property color seekerTrackColor: "#6d665b"
    readonly property color seekerProgressColor: "#e8bcb4"
    readonly property color seekerKnobColor: "#FCCD94"
    readonly property color titleTextColor: "#FCCD94"
    readonly property color artistTextColor: "#FFCF95"
    readonly property color controlButtonColor: "white"

    color: backgroundColor
    radius: 30

    width: 400
    height: 240

    clip: true

    Image {
        id: albumArt

        anchors.verticalCenter: mprisroot.bottom
        anchors.horizontalCenter: mprisroot.horizontalCenter
        fillMode: Image.PreserveAspectCrop

        source: mprisroot.player.trackArtUrl
        retainWhileLoading: true
        width: parent.width * mprisroot.discScale
        height: parent.width * mprisroot.discScale

        layer.enabled: true
        layer.smooth: true

        rotation: 0

        layer.effect: MultiEffect {
            antialiasing: true
            maskEnabled: true
            maskSpreadAtMin: 1.0
            maskThresholdMax: 1.0
            maskThresholdMin: 0.5

            maskSource: Image {
                layer.smooth: true
                mipmap: true
                smooth: true
                source: "../../Assets/AlbumCover.svg"
            }
        }
        Behavior on rotation {
            NumberAnimation {
                duration: rotateTimer.interval
                easing.type: Easing.Linear
            }
        }
    }

    Item {
        id: circularSeeker
        width: parent.width
        height: parent.width
        anchors.verticalCenter: mprisroot.bottom
        anchors.horizontalCenter: mprisroot.horizontalCenter

        readonly property real startAngle: 190
        readonly property real sweepAngle: 160
        readonly property real radius: (parent.width / 2) * mprisroot.discScale

        readonly property real internalAngle: (mprisroot.player.position / mprisroot.player.length) * sweepAngle
        property bool userIsDragging: false
        property real _manualAngle: 0
        property real displayedAngle: userIsDragging ? _manualAngle : internalAngle

        Shape {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            layer.enabled: true

            layer.samples: 3
            ShapePath {
                strokeWidth: 12
                strokeColor: mprisroot.seekerTrackColor
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: circularSeeker.width / 2
                    centerY: circularSeeker.height / 2
                    radiusX: circularSeeker.radius
                    radiusY: circularSeeker.radius
                    startAngle: circularSeeker.startAngle
                    sweepAngle: circularSeeker.sweepAngle
                }
            }
            ShapePath {
                strokeWidth: 12
                strokeColor: mprisroot.seekerProgressColor
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: circularSeeker.width / 2
                    centerY: circularSeeker.height / 2
                    radiusX: circularSeeker.radius
                    radiusY: circularSeeker.radius
                    startAngle: circularSeeker.startAngle
                    sweepAngle: circularSeeker.displayedAngle
                }
            }
        }

        Rectangle {
            width: 16
            height: 16
            radius: (parent.width / 2) * mprisroot.discScale
            color: mprisroot.seekerKnobColor
            x: circularSeeker.width / 2 + radius * Math.cos((circularSeeker.startAngle + circularSeeker.displayedAngle) * Math.PI / 180) - width / 2
            y: circularSeeker.height / 2 + radius * Math.sin((circularSeeker.startAngle + circularSeeker.displayedAngle) * Math.PI / 180) - height / 2
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onPressed: mevent => {
                if (!circularSeeker.userIsDragging) {
                    const dx = mevent.x - width / 2;
                    const dy = mevent.y - height / 2;
                    const distance = Math.sqrt(dx ** 2 + dy ** 2);

                    const innerRadius = circularSeeker.radius - 10;
                    const outerRadius = circularSeeker.radius + 10;

                    if (distance >= innerRadius && distance <= outerRadius) {
                        circularSeeker.userIsDragging = true;
                        updateAngle(mevent.x, mevent.y);
                    }

                    if (distance <= innerRadius) {
                        mprisroot.player.togglePlaying();
                    }
                }
            }

            onReleased: {
                Qt.callLater(() => circularSeeker.userIsDragging = false);
            }

            onPositionChanged: mevent => {
                if (circularSeeker.userIsDragging) {
                    updateAngle(mevent.x, mevent.y);
                }
            }

            function updateAngle(x, y) {
                const dx = x - width / 2;
                const dy = y - height / 2;

                const distance = Math.sqrt(dx ** 2 + dy ** 2);

                let theta = Math.atan2(dy, dx) * 180 / Math.PI;
                if (theta < 0)
                    theta += 360;

                const start = circularSeeker.startAngle;
                const end = (start + circularSeeker.sweepAngle) % 360;
                const inArc = (start < end) ? (theta >= start && theta <= end) : (theta >= start || theta <= end);

                if (inArc) {
                    let newAngle = theta - start;
                    if (newAngle < 0)
                        newAngle += 360;

                    circularSeeker._manualAngle = newAngle;
                    mprisroot.player.position = mprisroot.player.length * (newAngle / circularSeeker.sweepAngle);
                }
            }
        }
    }

    Timer {
        id: rotateTimer
        interval: 500
        repeat: true

        onRunningChanged: {
            albumArt.rotation += (rotateTimer.running) ? mprisroot.rotationStep : 0;
        }

        running: mprisroot.player.playbackState == MprisPlaybackState.Playing
        onTriggered: {
            albumArt.rotation += mprisroot.rotationStep;
        }
    }

    FrameAnimation {
        running: mprisroot.player.playbackState == MprisPlaybackState.Playing
        onTriggered: mprisroot.player.positionChanged()
    }

    Rectangle {
        id: rectroot

        color: "transparent"

        anchors.bottom: albumArt.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        anchors.topMargin: 10
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        ColumnLayout {
            id: songInformation
            anchors.margins: 0
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 6

            Text {
                text: mprisroot.player.trackTitle
                Layout.alignment: Qt.AlignHCenter
                font.bold: true
                elide: Text.ElideRight
                Layout.maximumWidth: parent.width
                color: mprisroot.titleTextColor
            }
            Text {
                text: mprisroot.player.trackArtist
                Layout.alignment: Qt.AlignHCenter
                font.bold: true
                elide: Text.ElideRight
                Layout.maximumWidth: parent.width
                color: mprisroot.artistTextColor
            }
        }

        RowLayout {
            anchors.top: songInformation.bottom
            anchors.topMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter

            spacing: 200

            Text {
                font.pointSize: 16
                color: mprisroot.controlButtonColor
                text: '󰒮'

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        mprisroot.player.previous();
                    }
                }
            }
            Text {
                font.pointSize: 16
                color: mprisroot.controlButtonColor
                text: "󰒭"

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        mprisroot.player.next();
                    }
                }
            }
        }
    }
}
