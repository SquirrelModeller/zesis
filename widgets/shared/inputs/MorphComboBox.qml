pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../../../"

// Dropdown
ComboBox {
    id: root

    property var selectedValue
    property real popupWidth: 0
    signal chosen(var value)

    textRole: "label"
    valueRole: "value"

    function _syncIndex() {
        for (var i = 0; i < root.model.length; i++) {
            if (root.model[i].value === root.selectedValue) {
                root.currentIndex = i;
                return;
            }
        }
        root.currentIndex = -1;
    }

    Component.onCompleted: _syncIndex()
    onModelChanged: _syncIndex()
    onSelectedValueChanged: _syncIndex()

    onActivated: index => root.chosen(root.model[index].value)

    padding: 0

    implicitHeight: Math.round(32 * UIScale.value)
    // Size of the biggest option
    implicitWidth: Math.max(labelMetrics.width, root._maxLabelWidth) + indicator.implicitWidth + UIScale.spacingSm * 3

    TextMetrics {
        id: labelMetrics
        font.pixelSize: UIScale.fontBody
        text: root.displayText
    }

    property real _maxLabelWidth: 0

    function _recomputeMaxLabelWidth() {
        var max = 0;
        for (var i = 0; i < labelMeasurer.count; i++) {
            var item = labelMeasurer.itemAt(i);
            if (item && item.implicitWidth > max)
                max = item.implicitWidth;
        }
        root._maxLabelWidth = max;
    }

    Repeater {
        id: labelMeasurer
        model: root.model
        onItemAdded: root._recomputeMaxLabelWidth()
        onItemRemoved: root._recomputeMaxLabelWidth()

        delegate: Text {
            required property var modelData
            visible: false
            text: modelData.label
            font.pixelSize: UIScale.fontBody
        }
    }

    background: Rectangle {
        topLeftRadius: UIScale.radiusMd
        topRightRadius: UIScale.radiusMd
        bottomLeftRadius: root.popup.visible ? 0 : UIScale.radiusMd
        bottomRightRadius: root.popup.visible ? 0 : UIScale.radiusMd

        Behavior on bottomLeftRadius {
            enabled: !root.popup.visible
            NumberAnimation {
                duration: Anim.medium
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anim.standard
            }
        }
        Behavior on bottomRightRadius {
            enabled: !root.popup.visible
            NumberAnimation {
                duration: Anim.medium
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anim.standard
            }
        }
        color: Colors.surfaceHigh

        Rectangle {
            anchors.fill: parent
            topLeftRadius: parent.topLeftRadius
            topRightRadius: parent.topRightRadius
            bottomLeftRadius: parent.bottomLeftRadius
            bottomRightRadius: parent.bottomRightRadius
            color: Colors.accent
            opacity: root.down ? 0.12 : (root.hovered ? 0.08 : 0)
            Behavior on opacity {
                NumberAnimation {
                    duration: Anim.fast
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Anim.standard
                }
            }
        }
    }

    indicator: Text {
        x: root.width - width - UIScale.spacingSm
        y: root.height / 2 - height / 2
        text: "▾"
        color: Colors.textDim
        font.pixelSize: UIScale.fontTiny
        rotation: root.popup.visible ? 180 : 0
        Behavior on rotation {
            NumberAnimation {
                duration: Anim.fast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anim.standard
            }
        }
    }

    contentItem: Text {
        leftPadding: UIScale.spacingSm
        rightPadding: root.indicator.width + UIScale.spacingSm
        text: root.displayText
        color: Colors.text
        font.pixelSize: UIScale.fontBody
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    delegate: ItemDelegate {
        id: itemDelegate
        required property var modelData
        required property int index

        readonly property bool isLast: itemDelegate.index === root.model.length - 1

        width: ListView.view ? ListView.view.width : root.width
        implicitHeight: Math.round(32 * UIScale.value)

        padding: 0

        highlighted: root.highlightedIndex === itemDelegate.index

        background: Rectangle {
            bottomLeftRadius: itemDelegate.isLast ? UIScale.radiusMd : 0
            bottomRightRadius: itemDelegate.isLast ? UIScale.radiusMd : 0
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                bottomLeftRadius: parent.bottomLeftRadius
                bottomRightRadius: parent.bottomRightRadius
                color: Colors.accent
                opacity: root.currentIndex === itemDelegate.index ? 0.15 : (itemDelegate.hovered ? 0.08 : 0)
                Behavior on opacity {
                    NumberAnimation {
                        duration: Anim.fast
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Anim.standard
                    }
                }
            }
        }

        contentItem: Text {
            leftPadding: UIScale.spacingSm
            rightPadding: UIScale.spacingSm
            text: itemDelegate.modelData.label
            color: root.currentIndex === itemDelegate.index ? Colors.accent : Colors.text
            font.pixelSize: UIScale.fontBody
            font.weight: root.currentIndex === itemDelegate.index ? Font.Medium : Font.Normal
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    popup: Popup {
        id: comboPopup
        // Make the popup's top flush with the trigger (button bottom)
        y: root.height
        width: Math.max(root.width, root.popupWidth, root._maxLabelWidth + UIScale.spacingSm * 2)
        padding: 0
        clip: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Anim.fast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anim.standard
            }
        }
        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: Anim.fast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anim.standard
            }
        }

        background: Rectangle {
            // Flush top, it lines up with triggers bottom
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: UIScale.radiusMd
            bottomRightRadius: UIScale.radiusMd
            color: Colors.surfaceHighest
        }

        contentItem: ListView {
            clip: true
            width: root.popup.availableWidth
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
        }
    }
}
