pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    id: root

    readonly property int cellH: 32
    readonly property int cellW: 20
    readonly property int vPad: 5

    property var _date: new Date()

    readonly property int _h1: Math.floor(_date.getHours() / 10)
    readonly property int _h2: _date.getHours() % 10
    readonly property int _m1: Math.floor(_date.getMinutes() / 10)
    readonly property int _m2: _date.getMinutes() % 10

    property bool _colonOn: true

    Timer {
        running: true
        repeat: true
        interval: 1000
        onTriggered: {
            root._date = new Date();
            root._colonOn = !root._colonOn;
        }
    }

    implicitHeight: root.cellH + root.vPad * 2 + 2
    implicitWidth: drumRow.implicitWidth + 24

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Colors.bg
        border.color: Colors.withAlpha(Colors.accent, 0.22)
        border.width: 1.5
    }

    RowLayout {
        id: drumRow
        anchors.centerIn: parent
        spacing: 4

        DrumDigit {
            digit: root._h1
            base: 3
        }
        DrumDigit {
            digit: root._h2
            base: 10
        }

        Text {
            text: ":"
            font.pixelSize: Math.round(root.cellH * 0.72)
            font.bold: true
            color: Colors.accent
            opacity: root._colonOn ? 0.9 : 0.2
            bottomPadding: 2
            Layout.alignment: Qt.AlignVCenter
            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                }
            }
        }

        DrumDigit {
            digit: root._m1
            base: 6
        }
        DrumDigit {
            digit: root._m2
            base: 10
        }
    }

    // Inline component, one drum cylinder for a single digit place
    component DrumDigit: Item {
        id: drum

        property int digit: 0
        property int base: 10

        // Accumulator: tracks position in the extended column (never resets mid-animation)
        property int _acc: 0
        property bool _initialized: false

        width: root.cellW + 12
        height: root.cellH + root.vPad * 2
        clip: true

        // Drum body
        Rectangle {
            anchors.fill: parent
            radius: 4
            color: Colors.bg
            border.color: Qt.rgba(1, 0.725, 0.486, 0.2)
            border.width: 1
        }

        // Digit column, 3 cycles so wrap-snap always lands in-bounds
        Column {
            id: col
            width: drum.width

            Repeater {
                model: drum.base * 3
                delegate: Text {
                    required property int index
                    text: index % drum.base
                    width: col.width
                    height: root.cellH
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 21
                    font.bold: true
                    font.family: "monospace"
                    color: Colors.accent
                }
            }
        }

        // Top edge fade, hides the digit scrolling in from above
        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: root.vPad + 4
            z: 1
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Colors.bg
                }
                GradientStop {
                    position: 1.0
                    color: "transparent"
                }
            }
        }

        // Bottom edge fade
        Rectangle {
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            height: root.vPad + 4
            z: 1
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "transparent"
                }
                GradientStop {
                    position: 1.0
                    color: Colors.bg
                }
            }
        }

        NumberAnimation {
            id: rollAnim
            target: col
            property: "y"
            duration: 350
            easing.type: Easing.InOutCubic
            onStopped: {
                // Snap the column back one cycle without animating, same digit, no visual change
                if (drum._acc >= drum.base * 2) {
                    col.y += drum.base * root.cellH;
                    drum._acc -= drum.base;
                }
            }
        }

        function roll(newDigit) {
            var oldDigit = drum._acc % drum.base;
            var steps = newDigit >= oldDigit ? (newDigit - oldDigit) : (drum.base - oldDigit + newDigit);
            if (steps === 0)
                return;
            drum._acc += steps;
            rollAnim.to = -(drum._acc * root.cellH) + root.vPad;
            rollAnim.restart();
        }

        Component.onCompleted: {
            drum._acc = drum.digit;
            col.y = -(drum._acc * root.cellH) + root.vPad;
            drum._initialized = true;
        }

        onDigitChanged: {
            if (drum._initialized)
                drum.roll(digit);
        }
    }
}
