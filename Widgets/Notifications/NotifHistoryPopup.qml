pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"

Rectangle {
    id: root

    anchors.fill: parent
    radius: UIScale.radiusMd
    color: Colors.bg
    border.color: Colors.outline
    border.width: 1
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
                font.pointSize: UIScale.fontMd
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                visible: NotifServer.history.count > 0
                text: "Clear all"
                color: clearHover.hovered ? Colors.accent : Colors.muted
                font.pointSize: UIScale.fontXs
                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }

                HoverHandler {
                    id: clearHover
                }
                TapHandler {
                    onTapped: NotifServer.clearHistory()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            implicitHeight: 1
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
                font.pointSize: UIScale.fontSm
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
                color: Colors.surfaceHigh
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
                    duration: 250
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
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: histItem
                            property: "opacity"
                            to: 0
                            duration: 180
                            easing.type: Easing.InCubic
                        }
                    }
                    NumberAnimation {
                        target: histItem
                        property: "implicitHeight"
                        to: 0
                        duration: 180
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
                            font.pointSize: UIScale.fontXs
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: histItem.time
                            color: Colors.muted
                            font.pointSize: UIScale.fontXs
                            opacity: 0.7
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: histItem.summary
                        color: Colors.text
                        font.bold: true
                        font.pointSize: UIScale.fontSm
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: histItem.body !== ""
                        text: histItem.body
                        color: Colors.textDim
                        font.pointSize: UIScale.fontXs
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
