pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "."
import "../desktop"
import "../../"

// Desktop background widget: macOS-style battery rings for the currently
// connected earbuds (left / right / case).
Item {
    id: root

    readonly property bool available: AudioDevicesService.connected
    readonly property bool _configMode: DesktopWidgetStore.configMode
    readonly property bool _show: available || _configMode

    readonly property string _name: available ? AudioDevicesService.deviceName : I18n.t("desktop.devicesLabel")
    readonly property int _left: available ? AudioDevicesService.leftLevel : 80
    readonly property int _right: available ? AudioDevicesService.rightLevel : 75
    readonly property int _caseLevel: available ? AudioDevicesService.caseLevel : 100
    readonly property bool _hasCase: available ? AudioDevicesService.hasCase : true

    visible: _show
    implicitWidth: _show ? layout.implicitWidth : 1
    implicitHeight: _show ? layout.implicitHeight : 1

    ColumnLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Math.round(12 * UIScale.value)

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: UIScale.spacingSm

            Text {
                text: "󱡏"
                font.pixelSize: Math.round(18 * UIScale.value)
                color: Colors.accent
            }

            Text {
                text: root._name
                color: Colors.text
                font.pixelSize: UIScale.fontSmall
                font.weight: Font.Bold
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Math.round(18 * UIScale.value)

            BatteryRing {
                level: root._left
                charging: root.available && AudioDevicesService.leftCharging
                dim: root.available && !AudioDevicesService.leftEar
                caption: I18n.t("desktop.left")
            }

            BatteryRing {
                level: root._right
                charging: root.available && AudioDevicesService.rightCharging
                dim: root.available && !AudioDevicesService.rightEar
                caption: I18n.t("desktop.right")
            }

            BatteryRing {
                visible: root._hasCase
                level: root._caseLevel
                charging: root.available && AudioDevicesService.caseCharging
                caption: I18n.t("desktop.case")
            }
        }
    }
}
