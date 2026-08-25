pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../../"
import "../inputs"

// Master volume
// Mute toggle, title, volume slider
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property real vol: 0
    property bool muted: false

    signal muteToggled
    signal volumeMoved(real value)
    signal volumeWheeled(real angleDelta)

    Layout.fillWidth: true
    Layout.leftMargin: UIScale.spacingMd
    Layout.rightMargin: UIScale.spacingMd
    radius: UIScale.radiusMd
    color: Colors.surface
    implicitHeight: masterInner.implicitHeight + Math.round(24 * UIScale.value)

    ColumnLayout {
        id: masterInner
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: UIScale.spacingMd
        }
        spacing: UIScale.spacingSm

        RowLayout {
            Layout.fillWidth: true

            Item {
                implicitWidth: iconText.implicitWidth + UIScale.spacingSm
                implicitHeight: Math.round(28 * UIScale.value)

                Rectangle {
                    anchors.fill: parent
                    radius: UIScale.radiusSm
                    color: iconHover.hovered ? Colors.withAlpha(Colors.accent, 0.12) : "transparent"
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                }

                Text {
                    id: iconText
                    anchors.centerIn: parent
                    text: root.icon
                    font.pixelSize: Math.round(20 * UIScale.value)
                    color: root.muted ? Colors.muted : Colors.accent
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                }

                HoverHandler {
                    id: iconHover
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.muteToggled()
                }
            }

            Text {
                text: root.label
                color: Colors.text
                font.pixelSize: UIScale.fontBody
                font.weight: Font.Bold
                Layout.fillWidth: true
            }

            Text {
                text: Math.round(root.vol * 100) + "%"
                color: Colors.accent
                font.pixelSize: UIScale.fontBody
                font.weight: Font.Bold
                font.family: "monospace"
            }
        }

        SettingSlider {
            Layout.fillWidth: true
            from: 0
            to: 100
            step: 1
            value: Math.round(Math.min(root.vol, 1.0) * 100)
            muted: root.muted
            onMoved: function (v) {
                root.volumeMoved(v);
            }
            onWheeled: function (delta) {
                root.volumeWheeled(delta);
            }
        }
    }
}
