pragma ComponentBehavior: Bound

import QtQuick
import "../../"

Item {
    id: root

    // Toggle between 12 and 24 hour mode
    property bool use24Hour: false
    readonly property int hourCount: use24Hour ? 24 : 12

    // Geometry
    property int discRadius: 120
    readonly property int pad: 20

    // When true, disc stays expanded and hover collapse is suppressed
    property bool alwaysExpanded: false
    readonly property int peekOffset: 16
    readonly property real minuteRadius: discRadius * 0.815
    readonly property real hourRadius: discRadius * 0.500
    readonly property real _scale: discRadius / 120.0

    implicitWidth: (discRadius + pad) * 2
    implicitHeight: (discRadius + pad) * 2

    // Hover expand / collapse
    property bool expanded: false

    Timer {
        id: collapseTimer
        interval: 300
        onTriggered: root.expanded = false
    }

    HoverHandler {
        onHoveredChanged: {
            if (root.alwaysExpanded)
                return;
            if (hovered) {
                collapseTimer.stop();
                root.expanded = true;
            } else
                collapseTimer.restart();
        }
    }

    // Disc position, peeks from top-right corner when collapsed
    readonly property real discCX: (alwaysExpanded || expanded) ? (discRadius + pad) : (implicitWidth - peekOffset)
    readonly property real discCY: (alwaysExpanded || expanded) ? (discRadius + pad) : peekOffset

    // Animated center, drives the PanelWindow ellipse mask
    readonly property real visualDiscCX: dial.x + discRadius
    readonly property real visualDiscCY: dial.y + discRadius

    // Time
    property var _date: new Date()
    readonly property int currentMinute: _date.getMinutes()
    readonly property int currentHour: {
        var h = _date.getHours();
        return use24Hour ? h : (h % 12);
    }

    // Rotation accumulators, always decrease (counterclockwise), never jump
    property real _minAccum: 0
    property real _hrAccum: 0
    property bool _initialized: false

    Timer {
        running: true
        repeat: true
        interval: 1000
        onTriggered: root._date = new Date()
    }

    Item {
        id: dial
        width: root.discRadius * 2
        height: root.discRadius * 2
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

        // Disc body
        Rectangle {
            anchors.fill: parent
            radius: root.discRadius
            color: Colors.surface
            border.color: Colors.withAlpha(Colors.accent, 0.35)
            border.width: 1.5
        }

        // Groove separator between minute and hour zones
        Rectangle {
            anchors.centerIn: parent
            property real r: (root.minuteRadius + root.hourRadius) / 2
            width: r * 2
            height: r * 2
            radius: r
            color: "transparent"
            border.color: Qt.rgba(1, 0.725, 0.486, 0.18)
            border.width: 1
        }

        Item {
            id: minuteRing
            anchors.centerIn: parent
            width: 0
            height: 0
            rotation: 0  // set in Component.onCompleted; driven by minuteAnim

            NumberAnimation {
                id: minuteAnim
                target: minuteRing
                property: "rotation"
                duration: 420
                easing.type: Easing.OutCubic
                onStopped: {
                    // Snap back one full revolution once past -360° - no visual change
                    while (minuteRing.rotation <= -360) {
                        minuteRing.rotation += 360;
                        root._minAccum += 360;
                    }
                }
            }

            Repeater {
                model: 60
                delegate: Item {
                    required property int index

                    readonly property real _angle: index * Math.PI / 30

                    // Center the label's bounding box on the ring arc
                    width: Math.round(14 * root._scale)
                    height: Math.round(10 * root._scale)
                    x: Math.sin(_angle) * root.minuteRadius - width / 2
                    y: -Math.cos(_angle) * root.minuteRadius - height / 2

                    // Rotate WITH ring position so the label at the top is always upright
                    rotation: index * 6

                    Text {
                        anchors.centerIn: parent
                        text: parent.index
                        font.pixelSize: Math.round((parent.index % 5 === 0 ? 8 : 7) * root._scale)
                        font.bold: parent.index % 5 === 0
                        // Quarter-hour marks bright, others dim
                        color: parent.index % 5 === 0 ? Colors.muted : Colors.withAlpha(Colors.muted, 0.38)
                    }
                }
            }
        }

        Item {
            id: hourRing
            anchors.centerIn: parent
            width: 0
            height: 0
            rotation: 0

            NumberAnimation {
                id: hourAnim
                target: hourRing
                property: "rotation"
                duration: 600
                easing.type: Easing.OutCubic
                onStopped: {
                    while (hourRing.rotation <= -360) {
                        hourRing.rotation += 360;
                        root._hrAccum += 360;
                    }
                }
            }

            Repeater {
                model: root.hourCount
                delegate: Item {
                    required property int index

                    readonly property real _step: 360.0 / root.hourCount
                    readonly property real _angle: index * 2 * Math.PI / root.hourCount

                    width: Math.round(20 * root._scale)
                    height: Math.round(14 * root._scale)
                    x: Math.sin(_angle) * root.hourRadius - width / 2
                    y: -Math.cos(_angle) * root.hourRadius - height / 2
                    rotation: index * _step

                    Text {
                        anchors.centerIn: parent
                        // 12h: index 0 → "12", 1 → "1", … | 24h: index 0 → "0", …
                        text: root.use24Hour ? parent.index : (parent.index === 0 ? 12 : parent.index)
                        font.pixelSize: Math.round((root.use24Hour ? 9 : 11) * root._scale)
                        font.bold: true
                        color: Colors.text
                    }
                }
            }
        }

        // Fixed reading hairline at the top of the disc
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 5
            width: Math.round(2 * root._scale)
            height: Math.round(10 * root._scale)
            radius: 1
            color: Colors.accent
            opacity: 0.9
        }

        // Center pin
        Rectangle {
            anchors.centerIn: parent
            width: Math.round(10 * root._scale)
            height: Math.round(10 * root._scale)
            radius: Math.round(5 * root._scale)
            color: Colors.accent
            opacity: 0.85
        }
    }

    // Snap rings to correct position on load
    Component.onCompleted: {
        _minAccum = -(currentMinute * 6.0);
        _hrAccum = -(currentHour * (360.0 / hourCount));
        minuteRing.rotation = _minAccum;
        hourRing.rotation = _hrAccum;
        _initialized = true;
    }

    // Animate minute ring forward by 6° on each minute tick
    onCurrentMinuteChanged: {
        if (!_initialized)
            return;
        _minAccum -= 6;
        minuteAnim.to = _minAccum;
        minuteAnim.restart();
    }

    // Animate hour ring forward by one hour-step on each hour change
    onCurrentHourChanged: {
        if (!_initialized)
            return;
        _hrAccum -= 360.0 / hourCount;
        hourAnim.to = _hrAccum;
        hourAnim.restart();
    }

    // Re-snap hour ring when switching 12 <-> 24 mode
    onUse24HourChanged: {
        if (!_initialized)
            return;
        _hrAccum = -(currentHour * (360.0 / hourCount));
        hourRing.rotation = _hrAccum;
    }
}
