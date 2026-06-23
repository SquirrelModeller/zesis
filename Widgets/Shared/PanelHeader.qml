import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    id: root
    property string breadcrumb: ""
    property string title: ""
    property Component rightActions: null

    implicitHeight: Math.round(72 * UIScale.value)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: UIScale.panelPad
        anchors.rightMargin: UIScale.panelPad
        anchors.topMargin: UIScale.spacingMd
        anchors.bottomMargin: UIScale.spacingMd

        Column {
            spacing: Math.round(5 * UIScale.value)
            Layout.fillWidth: true

            Text {
                text: root.breadcrumb
                color: Colors.accent
                font.pixelSize: UIScale.fontCaption
                font.weight: Font.Bold
                font.letterSpacing: 2
                font.family: "monospace"
            }
            Text {
                text: root.title
                color: Colors.text
                font.pixelSize: UIScale.fontHero
                font.weight: Font.ExtraBold
            }
        }

        Loader {
            sourceComponent: root.rightActions
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Colors.withAlpha(Colors.text, 0.05)
    }
}
