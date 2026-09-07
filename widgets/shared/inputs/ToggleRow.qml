pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../../"

// label + hint + switch row
RowLayout {
    id: root
    property string label: ""
    property string hint: ""
    property bool checked: false
    signal toggled

    Layout.fillWidth: true
    spacing: UIScale.spacingSm

    Column {
        Layout.fillWidth: true
        spacing: Math.round(2 * UIScale.value)
        Text {
            text: root.label
            color: Colors.text
            font.pixelSize: UIScale.fontSmall
            font.weight: Font.DemiBold
        }
        Text {
            text: root.hint
            color: Colors.textDim
            font.pixelSize: UIScale.fontTiny
            visible: text.length > 0
        }
    }

    ToggleSwitch {
        checked: root.checked
        onToggled: root.toggled()
    }
}
