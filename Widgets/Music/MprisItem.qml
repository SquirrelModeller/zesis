import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell.Services.Mpris
import "../../"

Rectangle {
    id: mprisroot

    required property MprisPlayer player
    required property real discScale
    readonly property real rotationStep: 3

    readonly property color colOverlay: Qt.rgba(0.07, 0.05, 0.03, 0.70)
    readonly property color colSeekKnob: "#FCCD94"

    // Cache art URL per-track: clear on title change (shows fallback vinyl
    // while the new thumbnail downloads), latch on non-empty URL so Firefox's
    // habit of immediately clearing artUrl doesn't drop the disc.
    property string _artUrl: ""

    Component.onCompleted: {
        if (player.trackArtUrl !== "")
            _artUrl = player.trackArtUrl;
    }

    Connections {
        target: mprisroot.player
        function onTrackTitleChanged() {
            mprisroot._artUrl = "";
        }
        function onTrackArtUrlChanged() {
            if (mprisroot.player.trackArtUrl !== "")
                mprisroot._artUrl = mprisroot.player.trackArtUrl;
        }
    }

    radius: 20
    width: 400
    height: 260
    clip: true
    color: Colors.bg

    // Blurred album art background
    Image {
        anchors.fill: parent
        source: mprisroot._artUrl
        fillMode: Image.PreserveAspectCrop
        retainWhileLoading: true
        opacity: 0.75
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1.0
            blurMax: 48
            saturation: 0.15
        }
    }

    // Dark warm overlay
    Rectangle {
        anchors.fill: parent
        color: mprisroot.colOverlay
        radius: 20
    }

    // Fallback vinyl, always underneath as base
    Item {
        id: vinylBase
        anchors.verticalCenter: mprisroot.bottom
        anchors.horizontalCenter: mprisroot.horizontalCenter
        width: parent.width * mprisroot.discScale
        height: width

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Colors.surface
        }
        Repeater {
            model: [0.88, 0.76, 0.63, 0.50]
            Rectangle {
                required property real modelData
                anchors.centerIn: parent
                width: parent.width * modelData
                height: width
                radius: width / 2
                color: "transparent"
                border.color: Qt.rgba(1, 0.72, 0.48, 0.10)
                border.width: 2
            }
        }
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.22
            height: width
            radius: width / 2
            color: "#0d0a07"
        }
    }

    // Spinning album art, layered on top of vinyl
    Image {
        id: albumArt
        anchors.verticalCenter: mprisroot.bottom
        anchors.horizontalCenter: mprisroot.horizontalCenter
        fillMode: Image.PreserveAspectCrop
        source: mprisroot._artUrl
        retainWhileLoading: true
        width: parent.width * mprisroot.discScale
        height: width
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

    // Circular seeker
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
                strokeWidth: 10
                strokeColor: Colors.withAlpha(Colors.accent, 0.22)
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
                strokeWidth: 10
                strokeColor: Colors.accent
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
            width: 14
            height: 14
            radius: 7
            color: mprisroot.colSeekKnob
            x: circularSeeker.width / 2 + circularSeeker.radius * Math.cos((circularSeeker.startAngle + circularSeeker.displayedAngle) * Math.PI / 180) - width / 2
            y: circularSeeker.height / 2 + circularSeeker.radius * Math.sin((circularSeeker.startAngle + circularSeeker.displayedAngle) * Math.PI / 180) - height / 2
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onPressed: mevent => {
                if (!circularSeeker.userIsDragging) {
                    const dx = mevent.x - width / 2;
                    const dy = mevent.y - height / 2;
                    const distance = Math.sqrt(dx ** 2 + dy ** 2);
                    const innerRadius = circularSeeker.radius - 12;
                    const outerRadius = circularSeeker.radius + 12;
                    if (distance >= innerRadius && distance <= outerRadius) {
                        circularSeeker.userIsDragging = true;
                        updateAngle(mevent.x, mevent.y);
                    }
                    if (distance <= innerRadius)
                        mprisroot.player.togglePlaying();
                }
            }
            onReleased: {
                Qt.callLater(() => circularSeeker.userIsDragging = false);
            }
            onPositionChanged: mevent => {
                if (circularSeeker.userIsDragging)
                    updateAngle(mevent.x, mevent.y);
            }

            function updateAngle(x, y) {
                const dx = x - width / 2;
                const dy = y - height / 2;
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

    // Track info, lives in the top zone above the disc
    Column {
        anchors.top: parent.top
        anchors.topMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 100
        spacing: 5

        Text {
            text: mprisroot.player.trackTitle
            width: parent.width
            color: Colors.text
            font.bold: true
            font.pointSize: 12
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
        Text {
            text: mprisroot.player.trackArtist
            width: parent.width
            color: Colors.muted
            font.bold: true
            font.pointSize: 9
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // Previous
    Item {
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -22
        width: 36
        height: 36

        Text {
            anchors.centerIn: parent
            text: "⏮"
            font.pixelSize: 22
            color: prevArea.containsMouse ? Colors.accent : Colors.muted
            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }
        MouseArea {
            id: prevArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: mprisroot.player.previous()
        }
    }

    // Next
    Item {
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -22
        width: 36
        height: 36

        Text {
            anchors.centerIn: parent
            text: "⏭"
            font.pixelSize: 22
            color: nextArea.containsMouse ? Colors.accent : Colors.muted
            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }
        MouseArea {
            id: nextArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: mprisroot.player.next()
        }
    }

    Timer {
        id: rotateTimer
        interval: 500
        repeat: true
        running: mprisroot.player.playbackState === MprisPlaybackState.Playing
        onRunningChanged: albumArt.rotation += rotateTimer.running ? mprisroot.rotationStep : 0
        onTriggered: albumArt.rotation += mprisroot.rotationStep
    }

    FrameAnimation {
        running: mprisroot.player.playbackState === MprisPlaybackState.Playing
        onTriggered: mprisroot.player.positionChanged()
    }
}
