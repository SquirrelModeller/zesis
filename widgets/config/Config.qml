pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../"
import "../bar"
import "../shared"
import "../shared/inputs"

Item {
    id: root

    anchors.fill: parent

    Flickable {
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: layout.implicitHeight + UIScale.spacingLg * 2
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: layout
            x: UIScale.spacingLg
            y: UIScale.spacingLg
            width: parent.width - UIScale.spacingLg * 2
            spacing: UIScale.spacingMd

            // Bar side
            Text {
                text: I18n.t("bar.side")
                color: Colors.text
                font.bold: true
                font.pixelSize: UIScale.fontBody
            }
            OptionRow {
                Layout.fillWidth: true
                model: [I18n.t("bar.top"), I18n.t("bar.bottom"), I18n.t("bar.left"), I18n.t("bar.right")]
                currentIndex: ["top", "bottom", "left", "right"].indexOf(BarConfig.side)
                onActivated: index => BarConfig.patch({
                        side: ["top", "bottom", "left", "right"][index]
                    })
            }

            Divider {
                color: Colors.withAlpha(Colors.accent, 0.1)
            }

            // Edge gap
            SettingSliderRow {
                label: I18n.t("bar.edgeGap")
                valueText: BarConfig.edgeGap + "px"
                from: 0
                to: 40
                step: 1
                value: BarConfig.edgeGap
                onMoved: function (v) {
                    BarConfig.patch({
                        edgeGap: Math.round(v)
                    });
                }
            }

            Divider {
                color: Colors.withAlpha(Colors.accent, 0.1)
            }

            // End gap
            SettingSliderRow {
                label: I18n.t("bar.endGap")
                valueText: BarConfig.endGap + "px"
                from: 0
                to: 60
                step: 1
                value: BarConfig.endGap
                onMoved: function (v) {
                    BarConfig.patch({
                        endGap: Math.round(v)
                    });
                }
            }

            Divider {
                color: Colors.withAlpha(Colors.accent, 0.1)
            }

            // Bar items
            Text {
                text: I18n.t("bar.items")
                color: Colors.text
                font.bold: true
                font.pixelSize: UIScale.fontBody
            }

            Repeater {
                model: BarItemsService.orderedItems
                delegate: RowLayout {
                    id: itemRow
                    required property var modelData
                    Layout.fillWidth: true

                    Text {
                        text: itemRow.modelData.label
                        color: Colors.text
                        font.pixelSize: UIScale.fontBody
                        Layout.fillWidth: true
                    }
                    ToggleSwitch {
                        checked: BarItemsService.isEnabled(itemRow.modelData.id)
                        onToggled: BarItemsService.toggle(itemRow.modelData.id)
                    }
                }
            }
        }
    }
}
