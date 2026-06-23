pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"
import "../Shared"

Item {
    id: root

    anchors.fill: parent
    clip: true

    ColumnLayout {
        anchors {
            fill: parent
            margins: UIScale.spacingLg
        }
        spacing: 0

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Notifications"
                color: Colors.text
                font.bold: true
                font.pixelSize: UIScale.fontBody
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                visible: NotifServer.history.count > 0
                text: "Clear all"
                color: clearMouseArea.containsMouse ? Colors.accent : Colors.muted
                font.pixelSize: UIScale.fontCaption
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }

                MouseArea {
                    id: clearMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: NotifServer.clearHistory()
                }
            }
        }

        Divider {
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            color: Colors.withAlpha(Colors.accent, 0.1)
        }

        // Empty state
        Item {
            visible: NotifServer.history.count === 0
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                text: "No notifications"
                color: Colors.muted
                font.pixelSize: UIScale.fontSmall
            }
        }

        // History list
        ListView {
            id: listView
            visible: NotifServer.history.count > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: NotifServer.history
            spacing: 6
            clip: true

            delegate: Rectangle {
                id: histItem
                required property string appName
                required property string summary
                required property string body
                required property string time
                required property int index

                width: listView.width
                radius: UIScale.radiusMd
                color: Colors.surface
                implicitHeight: itemLayout.implicitHeight + UIScale.spacingMd + 2
                clip: true

                transform: Translate {
                    id: histSwipeTrans
                    x: 0
                }

                DragHandler {
                    id: histSwipeDrag
                    target: null
                    xAxis.enabled: true
                    yAxis.enabled: false
                    acceptedButtons: Qt.LeftButton
                    onTranslationChanged: if (active)
                        histSwipeTrans.x = translation.x
                    onActiveChanged: {
                        if (!active) {
                            if (Math.abs(histSwipeTrans.x) > 100) {
                                histSwipeOut.targetX = histSwipeTrans.x > 0 ? 420 : -420;
                                histSwipeOut.start();
                            } else {
                                histSnapBack.start();
                            }
                        }
                    }
                }

                NumberAnimation {
                    id: histSnapBack
                    target: histSwipeTrans
                    property: "x"
                    to: 0
                    duration: Anim.medium
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }

                SequentialAnimation {
                    id: histSwipeOut
                    property real targetX: 420
                    ParallelAnimation {
                        NumberAnimation {
                            target: histSwipeTrans
                            property: "x"
                            to: histSwipeOut.targetX
                            duration: Anim.medium
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: histItem
                            property: "opacity"
                            to: 0
                            duration: Anim.medium
                            easing.type: Easing.InCubic
                        }
                    }
                    NumberAnimation {
                        target: histItem
                        property: "implicitHeight"
                        to: 0
                        duration: Anim.medium
                        easing.type: Easing.InCubic
                    }
                    onFinished: NotifServer.history.remove(histItem.index)
                }

                ColumnLayout {
                    id: itemLayout
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: UIScale.spacingSm
                    }
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: histItem.appName
                            color: Colors.muted
                            font.pixelSize: UIScale.fontCaption
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: histItem.time
                            color: Colors.muted
                            font.pixelSize: UIScale.fontCaption
                            opacity: 0.7
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: histItem.summary
                        color: Colors.text
                        font.bold: true
                        font.pixelSize: UIScale.fontSmall
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: histItem.body !== ""
                        text: histItem.body
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        textFormat: Text.MarkdownText
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
