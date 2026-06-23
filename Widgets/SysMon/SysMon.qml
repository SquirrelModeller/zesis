import QtQuick
import Quickshell
import "../../"

Item {
    id: sysinfo

    implicitWidth: Math.round(40 * UIScale.value)
    implicitHeight: Math.round(40 * UIScale.value)

    readonly property bool active: sysMonPopup.visible

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: sysMonPopup.visible ? sysMonPopup.close() : sysMonPopup.open()
    }

    Text {
        anchors.centerIn: parent
        text: "󰍛"
        font.pixelSize: 20
        color: (mouseArea.containsMouse || sysinfo.active) ? Colors.accent : Colors.text
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        readonly property real arcLength: SysMonService.cpu.percent / 100
        readonly property color strokeColor: (mouseArea.containsMouse || sysinfo.active) ? Colors.accent : Colors.text

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

    PopupWindow {
        id: sysMonPopup
        anchor.item: sysinfo
        anchor.rect.x: sysinfo.width / 2 - sysMonPopup.implicitWidth / 2
        anchor.rect.y: sysinfo.height
        grabFocus: true
        visible: false
        color: "transparent"
        implicitWidth: Math.round(380 * UIScale.value)
        implicitHeight: Math.round(520 * UIScale.value)

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
                duration: Anim.slow
                easing.type: Easing.OutBack
                easing.overshoot: 1.4
            }
            NumberAnimation {
                target: sysMonContent
                property: "opacity"
                to: 1
                duration: Anim.medium
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
                sourceComponent: SysMonView {}
            }
        }
    }
}
