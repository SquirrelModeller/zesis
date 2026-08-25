pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../../"

ColumnLayout {
    id: root

    property string label: ""
    property string valueText: ""
    property real from: 0
    property real to: 100
    property real step: 1
    property real value: 0
    signal moved(real value)

    Layout.fillWidth: true
    spacing: UIScale.spacingSm

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: root.label
            color: Colors.text
            font.pixelSize: UIScale.fontBody
            font.bold: true
            Layout.fillWidth: true
        }
        Text {
            text: root.valueText
            color: Colors.accent
            font.pixelSize: UIScale.fontBody
            font.weight: Font.Bold
            font.family: "monospace"
        }
    }

    SettingSlider {
        Layout.fillWidth: true
        from: root.from
        to: root.to
        step: root.step
        value: root.value
        onMoved: function (v) {
            root.moved(v);
        }
    }
}
