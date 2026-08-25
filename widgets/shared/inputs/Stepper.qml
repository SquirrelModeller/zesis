pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../../"
import "../"

RowLayout {
    id: root
    property int value: 0
    property int min: 0
    property int max: 99
    property int step: 1
    signal stepped(int value)

    spacing: UIScale.spacingSm

    component StepButton: Item {
        id: btn
        required property string glyph
        required property bool atLimit
        signal clicked

        implicitWidth: Math.round(36 * UIScale.value)
        implicitHeight: Math.round(36 * UIScale.value)

        Surface {
            anchors.fill: parent
            level: 2
            cornerRadius: UIScale.radiusSm
        }
        Rectangle {
            anchors.fill: parent
            radius: UIScale.radiusSm
            color: Colors.withAlpha(Colors.accent, 0.15)
            opacity: hoverHandler.hovered ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Anim.fast
                }
            }
        }
        Text {
            anchors.centerIn: parent
            text: btn.glyph
            color: btn.atLimit ? Colors.muted : Colors.text
            font.pixelSize: UIScale.fontSubhead
        }
        HoverHandler {
            id: hoverHandler
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    StepButton {
        glyph: "-"
        atLimit: root.value <= root.min
        onClicked: if (root.value > root.min)
            root.stepped(root.value - root.step)
    }

    Text {
        text: root.value
        color: Colors.accent
        font.pixelSize: UIScale.fontSubhead
        font.weight: Font.Bold
        font.family: "monospace"
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
    }

    StepButton {
        glyph: "+"
        atLimit: root.value >= root.max
        onClicked: if (root.value < root.max)
            root.stepped(root.value + root.step)
    }
}
