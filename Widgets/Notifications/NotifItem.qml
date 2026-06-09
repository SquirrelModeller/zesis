pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../../"

Rectangle {
    id: root

    required property Notification notification

    radius: UIScale.radiusLg
    color: Colors.surface
    border.color: Colors.withAlpha(Colors.accent, 0.18)
    border.width: 1
    implicitWidth: 340
    implicitHeight: contentCol.implicitHeight + UIScale.spacingLg + 4
    clip: true

    opacity: 0
    transform: [
        Translate {
            id: slideIn
            y: -8
        },
        Translate {
            id: swipeTrans
            x: 0
        }
    ]

    Component.onCompleted: showAnim.start()

    SequentialAnimation {
        id: showAnim
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                to: 1
                duration: 200
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: slideIn
                property: "y"
                to: 0
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }

    function dismiss() {
        swipeDismissAnim.stop();
        swipeSnapBack.stop();
        hideAnim.start();
    }

    SequentialAnimation {
        id: hideAnim
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                to: 0
                duration: 160
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: root
                property: "implicitHeight"
                to: 0
                duration: 200
                easing.type: Easing.InCubic
            }
        }
        ScriptAction {
            script: root.notification.dismiss()
        }
    }

    // Swipe to dismiss
    DragHandler {
        id: swipeDrag
        target: null
        xAxis.enabled: true
        yAxis.enabled: false
        acceptedButtons: Qt.LeftButton
        onTranslationChanged: {
            if (active)
                swipeTrans.x = translation.x >= 0 ? translation.x : -Math.log(1 + Math.abs(translation.x)) * 10;
        }
        onActiveChanged: {
            if (!active) {
                if (swipeTrans.x > 100) {
                    swipeDismissAnim.targetX = 420;
                    swipeDismissAnim.start();
                } else {
                    swipeSnapBack.start();
                }
            }
        }
    }

    NumberAnimation {
        id: swipeSnapBack
        target: swipeTrans
        property: "x"
        to: 0
        duration: 250
        easing.type: Easing.OutBack
        easing.overshoot: 1.2
    }

    SequentialAnimation {
        id: swipeDismissAnim
        property real targetX: 420
        ParallelAnimation {
            NumberAnimation {
                target: swipeTrans
                property: "x"
                to: swipeDismissAnim.targetX
                duration: 220
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: root
                property: "opacity"
                to: 0
                duration: 180
                easing.type: Easing.InCubic
            }
        }
        NumberAnimation {
            target: root
            property: "implicitHeight"
            to: 0
            duration: 180
            easing.type: Easing.InCubic
        }
        ScriptAction {
            script: root.notification.dismiss()
        }
    }

    Timer {
        interval: 8000
        running: true
        onTriggered: root.dismiss()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onClicked: root.dismiss()
    }

    ColumnLayout {
        id: contentCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: UIScale.spacingMd
        }
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: UIScale.spacingSm

            Text {
                Layout.fillWidth: true
                text: root.notification?.summary ?? ""
                color: Colors.text
                font.bold: true
                font.pointSize: UIScale.fontMd
                elide: Text.ElideRight
            }

            Text {
                text: root.notification?.appName ?? ""
                color: Colors.muted
                font.pointSize: UIScale.fontXs
                opacity: 0.8
            }

            Text {
                text: "✕"
                color: closeHover.containsMouse ? Colors.accent : Colors.muted
                font.pointSize: UIScale.fontSm
                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }

                MouseArea {
                    id: closeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    onClicked: root.dismiss()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: (root.notification?.body ?? "") !== ""
            text: root.notification?.body ?? ""
            color: Colors.textDim
            font.pointSize: UIScale.fontSm
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            textFormat: Text.MarkdownText
        }

        RowLayout {
            Layout.fillWidth: true
            visible: (root.notification?.actions?.length ?? 0) > 0
            spacing: 6

            Repeater {
                model: root.notification?.actions ?? []
                delegate: Rectangle {
                    required property NotificationAction modelData
                    radius: 6
                    color: actionHover.containsMouse ? Colors.withAlpha(Colors.accent, 0.2) : Colors.surfaceHigh
                    implicitWidth: actionLabel.implicitWidth + 16
                    implicitHeight: actionLabel.implicitHeight + 8

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: parent.modelData.text
                        color: Colors.accent
                        font.pointSize: UIScale.fontXs
                    }

                    MouseArea {
                        id: actionHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            parent.modelData.invoke();
                            root.dismiss();
                        }
                    }
                }
            }
        }
    }
}
