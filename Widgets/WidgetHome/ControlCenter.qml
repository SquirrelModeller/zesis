pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Music"
import "../Notifications"
import "../Sound"
import "../Config"
import "../../"

Item {
    id: root

    property string currentTitle: ""

    function widgetComponent(index) {
        return [musicComp, notifComp, soundComp, configComp][index];
    }

    // Back header, floats over the stack, fades in when a widget is open
    RowLayout {
        id: backHeader
        z: 1
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 8
        anchors.leftMargin: UIScale.spacingMd
        anchors.rightMargin: UIScale.spacingMd
        height: 40
        opacity: stack.depth > 1 ? 1 : 0
        enabled: stack.depth > 1
        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }

        Text {
            text: "‹"
            color: backHover.containsMouse ? Colors.accent : Colors.muted
            font.pixelSize: 22
            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }
            MouseArea {
                id: backHover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: stack.pop()
            }
        }

        Text {
            text: root.currentTitle
            color: Colors.text
            font.bold: true
            font.pointSize: UIScale.fontMd
            leftPadding: UIScale.spacingSm
        }
    }

    StackView {
        id: stack
        anchors.fill: parent
        clip: true

        // Push: new view slides in from right + fades up
        pushEnter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: 40
                    to: 0
                    duration: 220
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
                }
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 120
                }
            }
        }
        // Push: old view exits to the left
        pushExit: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: 0
                    to: -40
                    duration: 180
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.3, 0, 0.8, 0.15, 1, 1]
                }
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 120
                }
            }
        }
        // Pop: tile grid slides back in from the left
        popEnter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: -40
                    to: 0
                    duration: 220
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
                }
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 120
                }
            }
        }
        // Pop: widget exits to the right
        popExit: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: 0
                    to: 40
                    duration: 180
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.3, 0, 0.8, 0.15, 1, 1]
                }
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 120
                }
            }
        }

        initialItem: TileGrid {
            onWidgetRequested: function (index, title) {
                root.currentTitle = title;
                stack.push(widgetPage, {
                    "widgetComp": root.widgetComponent(index)
                });
            }
        }
    }

    // Wrapper that offsets widget content below the back header.
    // Outer Item has NO anchors so StackView can animate its x freely.
    Component {
        id: widgetPage
        Item {
            id: pageRoot
            required property Component widgetComp

            Loader {
                anchors.fill: parent
                anchors.topMargin: 48
                sourceComponent: pageRoot.widgetComp
            }
        }
    }

    Component {
        id: musicComp
        MusicController {}
    }
    Component {
        id: notifComp
        NotifHistoryPopup {}
    }
    Component {
        id: soundComp
        SoundPopup {}
    }
    Component {
        id: configComp
        ConfigPopup {}
    }
}
