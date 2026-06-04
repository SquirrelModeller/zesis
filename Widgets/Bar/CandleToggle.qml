import QtQuick
import "../../"

Item {
    id: root

    property bool lit: false

    implicitWidth: 22
    implicitHeight: 38

    // Ambient glow behind flame when lit
    Rectangle {
        visible: root.lit
        anchors.horizontalCenter: parent.horizontalCenter
        y: -2
        width: 22
        height: 22
        radius: 11
        color: Qt.rgba(1.0, 0.73, 0.49, 0.14)
    }

    // Flame (lit state)
    Item {
        id: flame
        visible: root.lit
        anchors.horizontalCenter: parent.horizontalCenter
        y: 1
        width: 10
        height: 14
        transformOrigin: Item.Bottom

        // Outer warm body of flame
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 4
            width: 10
            height: 10
            radius: 5
            color: "#E87322"
            opacity: 0.88
        }
        // Mid flame tongue
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 1
            width: 6
            height: 10
            radius: 3
            color: Colors.accent
        }
        // Bright inner core
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 5
            width: 3
            height: 6
            radius: 2
            color: "#FFF2CC"
        }
    }

    // Smoke wisp (unlit state)
    Rectangle {
        id: smokeWisp
        visible: !root.lit
        anchors.horizontalCenter: parent.horizontalCenter
        y: 3
        width: 2
        height: 12
        radius: 1
        color: Colors.muted
        opacity: 0.35

        SequentialAnimation on opacity {
            running: !root.lit
            loops: Animation.Infinite
            NumberAnimation {
                to: 0.5
                duration: 1600
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                to: 0.2
                duration: 1800
                easing.type: Easing.InOutSine
            }
        }
    }

    // Wick
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 13
        width: 2
        height: 7
        radius: 1
        color: "#3d2b1f"
    }

    // Candle body
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 18
        width: 14
        height: 20
        radius: 3
        color: "#F0D9B5"

        // Subtle left highlight stripe (beeswax sheen)
        Rectangle {
            x: 2
            y: 3
            width: 2
            height: parent.height - 7
            radius: 1
            color: Qt.rgba(1, 1, 1, 0.38)
        }
    }

    // Hover highlight ring
    Rectangle {
        anchors.fill: parent
        radius: 6
        color: hoverArea.containsMouse ? Qt.rgba(1, 0.73, 0.49, 0.09) : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.lit = !root.lit
    }

    // Flicker: rotation
    SequentialAnimation {
        running: root.lit
        loops: Animation.Infinite
        NumberAnimation {
            target: flame
            property: "rotation"
            to: 5
            duration: 210
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: flame
            property: "rotation"
            to: -6
            duration: 260
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: flame
            property: "rotation"
            to: 3
            duration: 170
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: flame
            property: "rotation"
            to: -1
            duration: 230
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: flame
            property: "rotation"
            to: 0
            duration: 160
            easing.type: Easing.InOutSine
        }
    }

    // Flicker: scale (offset timing so it feels independent)
    SequentialAnimation {
        running: root.lit
        loops: Animation.Infinite
        NumberAnimation {
            target: flame
            property: "scale"
            to: 1.10
            duration: 390
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: flame
            property: "scale"
            to: 0.92
            duration: 290
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: flame
            property: "scale"
            to: 1.04
            duration: 330
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: flame
            property: "scale"
            to: 0.97
            duration: 240
            easing.type: Easing.InOutSine
        }
    }
}
