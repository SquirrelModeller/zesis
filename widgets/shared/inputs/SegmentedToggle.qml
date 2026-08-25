pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../../"
import "../"

// N labels with a sliding knob on the active label
Item {
    id: root
    property var model: []
    property int currentIndex: -1
    signal activated(int index)

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Math.round(32 * UIScale.value)

    readonly property real _knobMargin: Math.round(3 * UIScale.value)

    // Indexed by segment: [{x, width}, ...]
    // This is never mutated in place.
    property var _segmentRects: []

    function _reportRect(index, x, width) {
        var next = root._segmentRects.slice();
        next[index] = {
            x: x,
            width: width
        };
        root._segmentRects = next;
    }

    readonly property var _currentRect: (root.currentIndex >= 0 && root._segmentRects[root.currentIndex]) ? root._segmentRects[root.currentIndex] : null

    Surface {
        anchors.fill: parent
        level: 2
        cornerRadius: root.height / 2
    }

    Rectangle {
        visible: root._currentRect !== null
        width: root._currentRect ? root._currentRect.width - root._knobMargin * 2 : 0
        height: root.height - root._knobMargin * 2
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root._currentRect ? root._currentRect.x + root._knobMargin : 0
        color: Colors.accent
        Behavior on x {
            NumberAnimation {
                duration: Anim.medium
                easing.type: Easing.InOutQuad
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: Anim.medium
                easing.type: Easing.InOutQuad
            }
        }
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: root.model
            delegate: Item {
                id: segItem
                required property string modelData
                required property int index

                Layout.fillWidth: true
                Layout.preferredWidth: label.implicitWidth + UIScale.spacingMd * 2
                Layout.fillHeight: true

                onXChanged: root._reportRect(index, x, width)
                onWidthChanged: root._reportRect(index, x, width)
                Component.onCompleted: root._reportRect(index, x, width)

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: segItem.modelData
                    elide: Text.ElideRight
                    color: root.currentIndex === segItem.index ? Colors.bg : Colors.textDim
                    font.pixelSize: UIScale.fontCaption
                    font.weight: Font.Medium
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.medium
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activated(segItem.index)
                }
            }
        }
    }
}
