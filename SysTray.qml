import QtQuick 2.15
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import QtQuick.Controls 2.15
import Quickshell
import QtQuick.Controls.Fusion
import QtQuick.Window 2.15
import "visual/Theme.js" as Theme

Rectangle {
    id: rootrect
    color: Theme.transparentBackground
    radius: 100
    Layout.preferredHeight: 50
    Layout.preferredWidth: childrenRect.width + 20

    property point clickPos

    RowLayout {
        spacing: 5
        height: 40
        anchors.centerIn: parent

        Repeater {

            model: SystemTray.items.values

            delegate: Rectangle {
                width: parent.height * 0.6
                height: parent.height * 0.6
                Layout.leftMargin: 2
                Layout.rightMargin: 2
                color: "transparent"
                Image {
                    source: modelData.icon
                    width: parent.height
                    height: parent.height
                    anchors.centerIn: parent
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        rootrect.clickPos = mapToItem(null, mouseX, mouseY);
                        showContextMenu(modelData);
                    }
                }
            }
        }
        // SysInfo {}
        Clock {}
    }

    function showContextMenu(item) {
        if (item.hasMenu) {
            contextMenu.item = item;
            contextMenu.popup();
            popupMenu.x = rootrect.clickPos.x - 400;
            popupMenu.y = rootrect.clickPos.y;
            popupMenu.show();
        }
    }

    Window {
        id: popupMenu
        flags: Qt.Popup | Qt.FramelessWindowHint
        color: "transparent"
        width: 400
        height: 400

        property var item

        Menu {
            id: contextMenu
            property var item
            modal: false
            z: 1
            focus: false
            background: Rectangle {
                implicitWidth: 400
                color: Theme.transparentBackground
                border.color: "transparent"
                radius: 10
            }
            QsMenuOpener {
                id: menuOpener
                menu: contextMenu.item ? contextMenu.item.menu : null
            }
            Repeater {
                model: menuOpener.children

                delegate: MenuItem {
                    id: menuItem
                    text: modelData.text
                    onTriggered: {
                        popupMenu.hide();
                        modelData.triggered();
                    }
                    contentItem: Text {
                        text: modelData.text
                        color: menuItem.hovered ? "#ffffff" : "#cccccc"
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    background: Rectangle {
                        implicitWidth: 200
                        implicitHeight: 30
                        opacity: enabled ? 1 : 0.8
                        color: menuItem.hovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        radius: 10
                    }
                }
            }
        }
    }

    PopupWindow {

        // width: 100
        // height: 100
        color: "black"
        visible: false

        anchor {
            window: root
            rect.x: rootrect.clickPos.x
            rect.y: rootrect.clickPos.y
        }
    }

    //    PanelWindow {
    //	anchors {
    //	    top: true
    //	    left: true
    //	}
    //	margins {
    //	    top: 25
    //	    left: 25
    //	}
    //    }
}
