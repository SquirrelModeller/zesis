pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../../"

// Sidebar navigation row
Rectangle {
    id: root
    property string navId: ""
    property string navLabel: ""
    property string navIcon: ""
    property bool isNavSelected: false
    signal activated

    implicitHeight: Math.round(38 * UIScale.value)
    radius: UIScale.radiusMd
    color: isNavSelected ? Colors.withAlpha(Colors.accent, 0.15) : (navHover.hovered ? Colors.withAlpha(Colors.text, 0.06) : "transparent")
    Behavior on color {
        ColorAnimation {
            duration: Anim.fast
        }
    }

    Rectangle {
        visible: root.isNavSelected
        width: Math.round(3 * UIScale.value)
        radius: Math.round(2 * UIScale.value)
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: Math.round(7 * UIScale.value)
        anchors.bottomMargin: Math.round(7 * UIScale.value)
        color: Colors.accent
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: UIScale.spacingMd
        anchors.rightMargin: UIScale.spacingSm
        spacing: UIScale.spacingSm

        Text {
            text: root.navIcon
            font.family: "Material Icons"
            font.pixelSize: Math.round(18 * UIScale.value)
            color: root.isNavSelected ? Colors.accent : Colors.textDim
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
        }
        Text {
            text: root.navLabel
            color: root.isNavSelected ? Colors.text : Colors.textDim
            font.pixelSize: UIScale.fontLead
            font.weight: root.isNavSelected ? Font.DemiBold : Font.Normal
            Layout.fillWidth: true
            elide: Text.ElideRight
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
        }
    }

    HoverHandler {
        id: navHover
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
