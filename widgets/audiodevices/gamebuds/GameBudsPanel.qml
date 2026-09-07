pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../"
import "../../shared"
import "../../shared/inputs"
import "../../../"

Item {
    id: root

    readonly property var _noiseModes: ["off", "transparency", "anc"]
    readonly property var _radioModes: ["2.4g", "bt"]

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("gamebuds.breadcrumb")
            title: I18n.t("gamebuds.title")
        }

        // Not connected

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !GameBudsService.connected

            Text {
                anchors.centerIn: parent
                text: I18n.t("gamebuds.notConnected")
                color: Colors.textDim
                font.pixelSize: UIScale.fontBody
            }
        }

        // Connected

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: GameBudsService.connected
            contentWidth: width
            contentHeight: bodyCol.implicitHeight + UIScale.panelPad
            clip: true
            flickableDirection: Flickable.VerticalFlick

            ColumnLayout {
                id: bodyCol
                width: parent.width
                spacing: UIScale.spacingMd

                Item {
                    implicitHeight: UIScale.spacingXs
                }

                // Device

                SectionLabel {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.topMargin: UIScale.spacingXs
                    text: I18n.t("gamebuds.deviceSection")
                }

                SettingCard {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    Text {
                        Layout.fillWidth: true
                        text: GameBudsService.deviceName
                        color: Colors.text
                        font.pixelSize: UIScale.fontSmall
                        font.weight: Font.DemiBold
                    }
                }

                // Battery

                SectionLabel {
                    Layout.leftMargin: UIScale.panelPad
                    text: I18n.t("gamebuds.batterySection")
                }

                SettingCard {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    BatteryRow {
                        Layout.fillWidth: true
                        label: I18n.t("gamebuds.left")
                        level: GameBudsService.leftLevel
                        charging: false
                        inEar: GameBudsService.wearSenseStatus === true
                    }
                    BatteryRow {
                        Layout.fillWidth: true
                        label: I18n.t("gamebuds.right")
                        level: GameBudsService.rightLevel
                        charging: false
                        inEar: GameBudsService.wearSenseStatus === true
                    }
                }

                // Noise control

                SectionLabel {
                    Layout.leftMargin: UIScale.panelPad
                    text: I18n.t("gamebuds.noiseSection")
                }

                SettingCard {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    SegmentedToggle {
                        Layout.fillWidth: true
                        model: [I18n.t("gamebuds.noiseOff"), I18n.t("gamebuds.noiseTransparency"), I18n.t("gamebuds.noiseAnc")]
                        currentIndex: root._noiseModes.indexOf(GameBudsService.noiseMode)
                        onActivated: idx => GameBudsService.setNoiseMode(root._noiseModes[idx])
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: UIScale.spacingSm
                        visible: GameBudsService.noiseMode === "anc"

                        Text {
                            Layout.fillWidth: true
                            text: I18n.t("gamebuds.ancLevel")
                            color: Colors.text
                            font.pixelSize: UIScale.fontSmall
                            font.weight: Font.DemiBold
                        }
                        Stepper {
                            value: GameBudsService.ancLevel
                            min: 1
                            max: 3
                            step: 1
                            onStepped: v => GameBudsService.setAncLevel(v)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: UIScale.spacingSm
                        visible: GameBudsService.noiseMode === "transparency"

                        Text {
                            Layout.fillWidth: true
                            text: I18n.t("gamebuds.transparentLevel")
                            color: Colors.text
                            font.pixelSize: UIScale.fontSmall
                            font.weight: Font.DemiBold
                        }
                        Stepper {
                            value: GameBudsService.transparentLevel
                            min: 1
                            max: 3
                            step: 1
                            onStepped: v => GameBudsService.setTransparentLevel(v)
                        }
                    }
                }

                // Radio mode

                SectionLabel {
                    Layout.leftMargin: UIScale.panelPad
                    text: I18n.t("gamebuds.radioSection")
                }

                SettingCard {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    LabeledSegment {
                        label: I18n.t("gamebuds.radioLabel")
                        options: [I18n.t("gamebuds.radio24g"), I18n.t("gamebuds.radioBt")]
                        currentIndex: root._radioModes.indexOf(GameBudsService.audioMode)
                        onActivated: i => GameBudsService.setAudioMode(root._radioModes[i])
                    }
                }

                // Mic

                SectionLabel {
                    Layout.leftMargin: UIScale.panelPad
                    text: I18n.t("gamebuds.micSection")
                }

                SettingCard {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    ToggleRow {
                        label: I18n.t("gamebuds.micMuted")
                        checked: GameBudsService.micMuted === true
                        onToggled: GameBudsService.setMicMuted(GameBudsService.micMuted !== true)
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: UIScale.spacingSm

                        Text {
                            Layout.fillWidth: true
                            text: I18n.t("gamebuds.micLevel")
                            color: Colors.text
                            font.pixelSize: UIScale.fontSmall
                            font.weight: Font.DemiBold
                        }
                        Stepper {
                            value: GameBudsSettings.micLevel
                            min: 1
                            max: 10
                            step: 1
                            onStepped: v => GameBudsService.setMicLevel(v)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: UIScale.spacingSm

                        Text {
                            Layout.fillWidth: true
                            text: I18n.t("gamebuds.sidetoneLevel")
                            color: Colors.text
                            font.pixelSize: UIScale.fontSmall
                            font.weight: Font.DemiBold
                        }
                        Stepper {
                            value: GameBudsSettings.sidetoneLevel
                            min: 0
                            max: 3
                            step: 1
                            onStepped: v => GameBudsService.setSidetoneLevel(v)
                        }
                    }
                }

                // WearSense

                SectionLabel {
                    Layout.leftMargin: UIScale.panelPad
                    text: I18n.t("gamebuds.wearSenseSection")
                }

                SettingCard {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    ToggleRow {
                        label: I18n.t("gamebuds.wearSenseEnabled")
                        checked: GameBudsSettings.wearSenseEnabled
                        onToggled: GameBudsService.setWearSenseConfig(!GameBudsSettings.wearSenseEnabled)
                    }
                    ToggleRow {
                        label: I18n.t("gamebuds.autoPause")
                        hint: I18n.t("gamebuds.autoPauseHint")
                        checked: GameBudsSettings.autoPauseEnabled
                        onToggled: GameBudsSettings.set("autoPauseEnabled", !GameBudsSettings.autoPauseEnabled)
                    }
                }

                // Sound

                SectionLabel {
                    Layout.leftMargin: UIScale.panelPad
                    text: I18n.t("gamebuds.soundSection")
                }

                SettingCard {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: UIScale.spacingSm

                        Text {
                            Layout.fillWidth: true
                            text: I18n.t("gamebuds.bluetoothVolume")
                            color: Colors.text
                            font.pixelSize: UIScale.fontSmall
                            font.weight: Font.DemiBold
                        }
                        Stepper {
                            value: GameBudsService.bluetoothVolume
                            min: 0
                            max: 15
                            step: 1
                            onStepped: v => GameBudsService.setBluetoothVolume(v)
                        }
                    }
                    ToggleRow {
                        label: I18n.t("gamebuds.volumeLimiter")
                        checked: GameBudsSettings.volumeLimiter
                        onToggled: GameBudsService.setVolumeLimiter(!GameBudsSettings.volumeLimiter)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: UIScale.spacingSm

                        Text {
                            Layout.fillWidth: true
                            text: I18n.t("gamebuds.autoOffTimer")
                            color: Colors.text
                            font.pixelSize: UIScale.fontSmall
                            font.weight: Font.DemiBold
                        }

                        Stepper {
                            value: GameBudsSettings.autoOffTimer
                            min: 0
                            // 90 is the highest value the app's own QA debug
                            // menu exercises. So that is the limit?
                            max: 90
                            step: 5
                            onStepped: v => GameBudsService.setAutoOffTimer(v)
                        }
                    }
                }

                // Diagnostics

                SectionLabel {
                    Layout.leftMargin: UIScale.panelPad
                    text: I18n.t("gamebuds.diagnosticsSection")
                }

                SettingCard {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    Text {
                        Layout.fillWidth: true
                        text: GameBudsService.lastRawEvent ? (GameBudsService.lastRawEvent.name + " (" + GameBudsService.lastRawEvent.opcode + ") " + GameBudsService.lastRawEvent.raw) : I18n.t("gamebuds.lastEvent")
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontTiny
                        font.family: "monospace"
                        wrapMode: Text.WrapAnywhere
                    }
                }

                Item {
                    implicitHeight: UIScale.spacingXs
                }
            }
        }
    }
}
