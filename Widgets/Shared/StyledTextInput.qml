import QtQuick
import QtQuick.Layouts
import "../../"

Rectangle {
    id: root

    property string placeholder: ""
    property alias text: field.text
    property alias echoMode: field.echoMode
    property alias field: field

    signal accepted
    signal tabPressed
    signal escapePressed

    Layout.fillWidth: true
    implicitHeight: Math.round(34 * UIScale.value)
    radius: UIScale.radiusSm
    color: Colors.surfaceHigh
    border.color: field.activeFocus ? Colors.withAlpha(Colors.accent, 0.6) : "transparent"
    border.width: 1
    Behavior on border.color {
        ColorAnimation {
            duration: Anim.fast
        }
    }

    Text {
        visible: field.text.length === 0 && !field.activeFocus && root.placeholder.length > 0
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Math.round(10 * UIScale.value)
        text: root.placeholder
        color: Colors.textDim
        font.pixelSize: UIScale.fontCaption
    }

    TextInput {
        id: field
        anchors.fill: parent
        anchors.leftMargin: Math.round(10 * UIScale.value)
        anchors.rightMargin: Math.round(10 * UIScale.value)
        verticalAlignment: TextInput.AlignVCenter
        color: Colors.text
        selectionColor: Colors.withAlpha(Colors.accent, 0.35)
        font.pixelSize: UIScale.fontSmall
        Keys.onReturnPressed: root.accepted()
        Keys.onTabPressed: root.tabPressed()
        Keys.onEscapePressed: root.escapePressed()
    }
}
