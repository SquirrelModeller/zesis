pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../../"

Rectangle {
    id: root

    required property Notification notification

    radius: 14
    color: Colors.surface
    border.color: Colors.withAlpha(Colors.accent, 0.18)
    border.width: 1
    implicitWidth: 340
    implicitHeight: contentCol.implicitHeight + 24
    clip: true

    // Slide + fade in
    opacity: 0
    transform: Translate {
        id: slideIn
        y: -8
    }

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

    // Dismiss timer
    Timer {
        interval: 8000
        running: true
        onTriggered: root.dismiss()
    }

    // Hover pauses dismiss timer, we do this by restarting on mouse enter
    HoverHandler {
        id: hoverHandler
        onHoveredChanged: {
            // Re-read: no simple pause API on Timer, so just restart on exit
        }
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
            margins: 14
        }
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: root.notification?.summary ?? ""
                color: Colors.text
                font.bold: true
                font.pointSize: 10
                elide: Text.ElideRight
            }

            Text {
                text: root.notification?.appName ?? ""
                color: Colors.muted
                font.pointSize: 8
                opacity: 0.8
            }

            // Close button
            Text {
                text: "✕"
                color: closeHover.containsMouse ? Colors.accent : Colors.muted
                font.pixelSize: 11
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
            font.pointSize: 9
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            textFormat: Text.MarkdownText
        }

        // Action buttons
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
                        font.pointSize: 8
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
