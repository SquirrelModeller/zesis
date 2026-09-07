pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../../"

// label above a segmented choice
ColumnLayout {
    id: root
    property string label: ""
    property var options: []
    property int currentIndex: -1
    signal activated(int index)

    Layout.fillWidth: true
    spacing: Math.round(6 * UIScale.value)

    Text {
        text: root.label
        color: Colors.text
        font.pixelSize: UIScale.fontSmall
        font.weight: Font.DemiBold
    }

    SegmentedToggle {
        Layout.fillWidth: true
        model: root.options
        currentIndex: root.currentIndex
        onActivated: i => root.activated(i)
    }
}
