import QtQuick
import Quickshell
import "../../"

PopupWindow {
    id: root

    required property Item anchorItem
    property Component content
    property bool hasBackground: true
    signal opened

    anchor.item: anchorItem
    anchor.rect.x: anchorItem.width / 2 - root.implicitWidth / 2
    anchor.rect.y: anchorItem.height
    grabFocus: true
    visible: false
    color: "transparent"

    function open() {
        if (!visible) {
            frame.scale = 0;
            frame.opacity = 0;
            visible = true;
        }
        showAnim.start();
        root.opened();
    }

    function close() {
        if (!visible)
            return;
        showAnim.stop();
        visible = false;
    }

    onVisibleChanged: {
        if (!visible) {
            frame.scale = 0;
            frame.opacity = 0;
        }
    }

    ParallelAnimation {
        id: showAnim
        NumberAnimation {
            target: frame
            property: "scale"
            to: 1
            duration: Anim.slow
            easing.type: Easing.OutBack
            easing.overshoot: 1.4
        }
        NumberAnimation {
            target: frame
            property: "opacity"
            to: 1
            duration: Anim.medium
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: frame
        anchors.fill: parent
        scale: 0
        opacity: 0
        transformOrigin: Item.Top

        Rectangle {
            anchors.fill: parent
            radius: UIScale.radiusLg
            topLeftRadius: 0
            topRightRadius: 0
            color: Colors.bg
            border.color: Colors.outline
            border.width: 1
            visible: root.hasBackground
        }

        Loader {
            anchors.fill: parent
            active: root.visible
            sourceComponent: root.content
        }
    }
}
