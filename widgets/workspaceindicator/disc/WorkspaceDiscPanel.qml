pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import "../../../"
import "../../shared"
import "../../shared/inputs"

Item {
    id: root

    FolderListModel {
        id: skinFiles
        folder: Qt.resolvedUrl("skins/")
        nameFilters: ["WorkspaceDiscSkin*.qml"]
        showDirs: false
    }

    function _skinId(fileName) {
        return fileName.replace("WorkspaceDiscSkin", "").replace(".qml", "").toLowerCase();
    }
    function _skinLabel(fileName) {
        return fileName.replace("WorkspaceDiscSkin", "").replace(".qml", "");
    }

    readonly property var _skinLabels: {
        var arr = [];
        for (var i = 0; i < skinFiles.count; i++)
            arr.push(root._skinLabel(skinFiles.get(i, "fileName")));
        return arr;
    }

    readonly property int _currentSkinIndex: {
        for (var i = 0; i < skinFiles.count; i++) {
            if (root._skinId(skinFiles.get(i, "fileName")) === WorkspaceDiscService.skin)
                return i;
        }
        return 0;
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Settings
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: settingsCol.implicitHeight + UIScale.panelPad
            clip: true
            flickableDirection: Flickable.VerticalFlick

            ColumnLayout {
                id: settingsCol
                width: parent.width
                spacing: UIScale.spacingMd

                Item {
                    implicitHeight: UIScale.spacingXs
                }

                // Workspace count
                Text {
                    text: I18n.t("workspaceindicator.workspaces")
                    color: WorkspaceDiscService.expressive ? Colors.muted : Colors.text
                    font.pixelSize: UIScale.fontBody
                    font.bold: true
                    Layout.leftMargin: UIScale.panelPad
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                }

                Stepper {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    opacity: WorkspaceDiscService.expressive ? 0.35 : 1.0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Anim.fast
                        }
                    }
                    enabled: !WorkspaceDiscService.expressive

                    value: WorkspaceDiscService.workSpaceAmount
                    min: 1
                    max: 10
                    onStepped: v => WorkspaceDiscService.setWorkSpaceAmount(v)
                }

                // Expressive toggle
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    Column {
                        Layout.fillWidth: true
                        spacing: Math.round(2 * UIScale.value)

                        Text {
                            text: I18n.t("workspaceindicator.expressive")
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.bold: true
                        }
                        Text {
                            text: I18n.t("workspaceindicator.expressiveHint")
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontCaption
                        }
                    }

                    ToggleSwitch {
                        checked: WorkspaceDiscService.expressive
                        onToggled: WorkspaceDiscService.setExpressive(!WorkspaceDiscService.expressive)
                    }
                }

                // Minimum (expressive only)
                Text {
                    text: I18n.t("workspaceindicator.minimum")
                    color: WorkspaceDiscService.expressive ? Colors.text : Colors.muted
                    font.pixelSize: UIScale.fontBody
                    font.bold: true
                    Layout.leftMargin: UIScale.panelPad
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                }

                Stepper {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    opacity: WorkspaceDiscService.expressive ? 1.0 : 0.35
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Anim.fast
                        }
                    }
                    enabled: WorkspaceDiscService.expressive

                    value: WorkspaceDiscService.minWorkSpaceAmount
                    min: 1
                    max: 10
                    onStepped: v => WorkspaceDiscService.setMinWorkSpaceAmount(v)
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                // Disc radius
                SettingSliderRow {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    label: I18n.t("workspaceindicator.discRadius")
                    valueText: WorkspaceDiscService.discRadius + " px"
                    from: 35
                    to: 80
                    value: WorkspaceDiscService.discRadius
                    onMoved: v => WorkspaceDiscService.setDiscRadius(v)
                }

                // Tooth width
                SettingSliderRow {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    label: I18n.t("workspaceindicator.toothWidth")
                    valueText: WorkspaceDiscService.toothWidth + " %"
                    from: 5
                    to: 80
                    value: WorkspaceDiscService.toothWidth
                    onMoved: v => WorkspaceDiscService.setToothWidth(v)
                }

                // Valley depth
                SettingSliderRow {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    label: I18n.t("workspaceindicator.valleyDepth")
                    valueText: WorkspaceDiscService.valleyDepth + " %"
                    from: 0
                    to: 55
                    value: WorkspaceDiscService.valleyDepth
                    onMoved: v => WorkspaceDiscService.setValleyDepth(v)
                }

                // Dot size
                SettingSliderRow {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    label: I18n.t("workspaceindicator.dotSize")
                    valueText: WorkspaceDiscService.chamberSize + " px"
                    from: 14
                    to: 34
                    value: WorkspaceDiscService.chamberSize
                    onMoved: v => WorkspaceDiscService.setChamberSize(v)
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                // Dot orbit
                SettingSliderRow {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    label: I18n.t("workspaceindicator.dotOrbit")
                    valueText: WorkspaceDiscService.chamberRadius + " px"
                    from: 15
                    to: 45
                    value: WorkspaceDiscService.chamberRadius
                    onMoved: v => WorkspaceDiscService.setChamberRadius(v)
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                // Skin
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    Column {
                        Layout.fillWidth: true
                        spacing: Math.round(2 * UIScale.value)

                        Text {
                            text: I18n.t("workspaceindicator.skin")
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.bold: true
                        }
                        Text {
                            text: I18n.t("workspaceindicator.skinHint")
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontCaption
                        }
                    }
                }

                OptionRow {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    model: root._skinLabels
                    currentIndex: root._currentSkinIndex
                    onActivated: index => WorkspaceDiscService.setSkin(root._skinId(skinFiles.get(index, "fileName")))
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                // Tuck to edge
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    Column {
                        Layout.fillWidth: true
                        spacing: Math.round(2 * UIScale.value)

                        Text {
                            text: I18n.t("workspaceindicator.tuckEnabled")
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            text: I18n.t("workspaceindicator.tuckEnabledHint")
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontCaption
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: WorkspaceDiscService.tuckEnabled
                        onToggled: WorkspaceDiscService.setTuckEnabled(!WorkspaceDiscService.tuckEnabled)
                    }
                }

                // Show island background
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    visible: !WorkspaceDiscService.tuckEnabled

                    Column {
                        Layout.fillWidth: true
                        spacing: Math.round(2 * UIScale.value)

                        Text {
                            text: I18n.t("workspaceindicator.showIslandBackground")
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            text: I18n.t("workspaceindicator.showIslandBackgroundHint")
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontCaption
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: WorkspaceDiscService.showIslandBackground
                        onToggled: WorkspaceDiscService.setShowIslandBackground(!WorkspaceDiscService.showIslandBackground)
                    }
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                // Animate on hover
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    Column {
                        Layout.fillWidth: true
                        spacing: Math.round(2 * UIScale.value)

                        Text {
                            text: I18n.t("workspaceindicator.animateTransition")
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            text: I18n.t("workspaceindicator.animateTransitionHint")
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontCaption
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: WorkspaceDiscService.animateTransition
                        onToggled: WorkspaceDiscService.setAnimateTransition(!WorkspaceDiscService.animateTransition)
                    }
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    visible: Quickshell.screens.length > 1
                }

                // Monitors
                Text {
                    visible: Quickshell.screens.length > 1
                    text: I18n.t("workspaceindicator.monitors")
                    color: Colors.text
                    font.pixelSize: UIScale.fontBody
                    font.bold: true
                    Layout.leftMargin: UIScale.panelPad
                }
                Text {
                    visible: Quickshell.screens.length > 1
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    text: I18n.t("workspaceindicator.monitorsDescription")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontCaption
                    wrapMode: Text.WordWrap
                }

                Repeater {
                    model: Quickshell.screens
                    delegate: RowLayout {
                        id: monitorRow
                        required property var modelData
                        readonly property string _name: monitorRow.modelData.name
                        visible: Quickshell.screens.length > 1
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad

                        Text {
                            text: monitorRow._name + " (" + monitorRow.modelData.width + "×" + monitorRow.modelData.height + ")"
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            Layout.fillWidth: true
                        }
                        ToggleSwitch {
                            checked: WorkspaceDiscService.monitors.length === 0 || WorkspaceDiscService.monitors.includes(monitorRow._name)
                            onToggled: {
                                var current = WorkspaceDiscService.monitors.length === 0 ? Quickshell.screens.map(s => s.name) : WorkspaceDiscService.monitors.slice();
                                var idx = current.indexOf(monitorRow._name);
                                if (idx >= 0) {
                                    // TODO: We need a seperate option to generally disable the workspace indicator
                                    if (current.length <= 1)
                                        return;
                                    current.splice(idx, 1);
                                } else {
                                    current.push(monitorRow._name);
                                }
                                if (current.length === Quickshell.screens.length)
                                    current = [];
                                WorkspaceDiscService.setMonitors(current);
                            }
                        }
                    }
                }

                Item {
                    implicitHeight: UIScale.spacingXs
                }
            }
        }

        // Preview
        Item {
            Layout.preferredWidth: Math.round(280 * UIScale.value)
            Layout.fillHeight: true

            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: 1
                color: Colors.withAlpha(Colors.outline, 0.5)
            }

            Text {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: UIScale.spacingMd
                text: I18n.t("workspaceindicator.preview")
                color: Colors.muted
                font.pixelSize: UIScale.fontTiny
                font.letterSpacing: 1.5
                font.weight: Font.Medium
            }

            WorkspaceDisc {
                anchors.centerIn: parent
                forceExpanded: true
            }
        }
    }
}
