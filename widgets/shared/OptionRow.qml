pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    id: root
    property var model: []
    property int currentIndex: -1
    signal activated(int index)

    implicitHeight: Math.round(32 * UIScale.value)

    RowLayout {
        anchors.fill: parent
        spacing: UIScale.spacingSm

        Repeater {
            model: root.model
            delegate: Item {
                id: optBtn
                required property string modelData
                required property int index

                readonly property bool selected: root.currentIndex === optBtn.index

                Layout.fillWidth: true
                implicitHeight: Math.round(32 * UIScale.value)

                Surface {
                    anchors.fill: parent
                    level: 2
                    cornerRadius: UIScale.radiusSm
                }

                Rectangle {
                    anchors.fill: parent
                    radius: UIScale.radiusSm
                    color: Colors.withAlpha(Colors.accent, 0.15)
                    border.color: Colors.accent
                    border.width: 1
                    opacity: optBtn.selected ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Anim.fast
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: optBtn.modelData
                    color: Colors.text
                    font.pixelSize: UIScale.fontSmall
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activated(optBtn.index)
                }
            }
        }
    }
}
