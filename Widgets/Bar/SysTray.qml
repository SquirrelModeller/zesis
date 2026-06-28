pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"
import "../Home"
import "../LockScreen"

Rectangle {
    id: root

    radius: 100
    color: Colors.barBg
    visible: BarItemsService.anyEnabled
    implicitWidth: BarConfig.isVertical ? Math.round(50 * UIScale.value) : (layout.implicitWidth + Math.round(24 * UIScale.value))
    implicitHeight: BarConfig.isVertical ? (layout.implicitHeight + Math.round(24 * UIScale.value)) : Math.round(50 * UIScale.value)

    Component {
        id: simpleButton
        BarButton {}
    }

    GridLayout {
        id: layout
        anchors.centerIn: parent
        rowSpacing: 4
        columnSpacing: 4
        rows: BarConfig.isVertical ? -1 : 1
        columns: BarConfig.isVertical ? 1 : -1

        Repeater {
            model: BarItemsService.items
            delegate: Loader {
                id: trayDelegate
                required property var modelData
                Layout.alignment: Qt.AlignCenter
                active: BarItemsService.isEnabled(trayDelegate.modelData.id)
                visible: BarItemsService.isEnabled(trayDelegate.modelData.id)

                Component.onCompleted: {
                    if (trayDelegate.modelData.src)
                        source = trayDelegate.modelData.src;
                    else
                        sourceComponent = simpleButton;
                }

                onLoaded: {
                    if (!trayDelegate.modelData.src) {
                        item.icon = trayDelegate.modelData.icon ?? "";
                        if (trayDelegate.modelData.id === "home") {
                            item.active = Qt.binding(() => HomePanelService.open);
                            item.clicked.connect(() => {
                                HomePanelService.open = !HomePanelService.open;
                            });
                        } else if (trayDelegate.modelData.id === "lock") {
                            item.clicked.connect(() => {
                                LockService.triggerLock();
                            });
                        }
                    }
                }
            }
        }
    }
}
