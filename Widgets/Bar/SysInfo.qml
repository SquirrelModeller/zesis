import QtQuick
import Quickshell
import "../SysMon"
import "../../"

Item {
    id: sysinfo

    implicitWidth: 40
    implicitHeight: 40

    readonly property bool active: sysMonPopup.visible

    HoverHandler {
        id: hover
    }

    Text {
        anchors.centerIn: parent
        text: "󰍛"
        font.pointSize: 15
        color: (hover.hovered || sysinfo.active) ? Colors.accent : Colors.text
        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        readonly property real arcLength: SysMonService.cpu.percent / 100
        readonly property color strokeColor: (hover.hovered || sysinfo.active) ? Colors.accent : Colors.text

        onArcLengthChanged: requestPaint()
        onStrokeColorChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = Qt.rgba(strokeColor.r, strokeColor.g, strokeColor.b, strokeColor.a);
            ctx.lineWidth = height / 8;
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, width / 2 - ctx.lineWidth / 2, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * arcLength, false);
            ctx.stroke();
        }
    }

    TapHandler {
        onTapped: sysMonPopup.visible ? sysMonPopup.close() : sysMonPopup.open()
    }

    PopupWindow {
        id: sysMonPopup
        anchor.item: sysinfo
        anchor.rect.x: sysinfo.width / 2 - sysMonPopup.implicitWidth / 2
        anchor.rect.y: sysinfo.height
        grabFocus: true
        visible: false
        color: "transparent"
        implicitWidth: 380
        implicitHeight: 520

        function open() {
            if (!visible) {
                sysMonContent.scale = 0;
                sysMonContent.opacity = 0;
                visible = true;
            }
            sysMonShowAnim.start();
        }

        function close() {
            if (!visible)
                return;
            sysMonShowAnim.stop();
        }

        onVisibleChanged: {
            if (!visible) {
                SysMonService.popupOpen = false;
                sysMonContent.scale = 0;
                sysMonContent.opacity = 0;
            } else {
                SysMonService.popupOpen = true;
            }
        }

        ParallelAnimation {
            id: sysMonShowAnim
            NumberAnimation {
                target: sysMonContent
                property: "scale"
                to: 1
                duration: 280
                easing.type: Easing.OutBack
                easing.overshoot: 1.4
            }
            NumberAnimation {
                target: sysMonContent
                property: "opacity"
                to: 1
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: sysMonContent
            anchors.fill: parent
            scale: 0
            opacity: 0
            transformOrigin: Item.Top

            Loader {
                anchors.fill: parent
                active: sysMonPopup.visible
                sourceComponent: SysMonPopup {}
            }
        }
    }
}
