pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "./"
import "../"
import "../../shared"
import "../../shared/inputs"
import "../../../"

Item {
    id: root

    readonly property var _noiseModes: ["off", "anc", "transparency", "adaptive"]
    readonly property var _phModes: ["off", "anc", "transparency", "adaptive"]
    readonly property var _micModes: ["auto", "left", "right"]

    function _phHas(mode) {
        var arr = AirPodsSettings.pressHoldModes || [];
        return arr.indexOf(mode) !== -1;
    }
    function _phToggle(mode) {
        var cur = (AirPodsSettings.pressHoldModes || []).slice();
        var i = cur.indexOf(mode);
        if (i === -1)
            cur.push(mode);
        else
            cur.splice(i, 1);
        AirPodsService.setPressHoldModes(cur);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("airpods.breadcrumb")
            title: I18n.t("airpods.title")
        }

        // Not connected

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !AirPodsService.connected

            Text {
                anchors.centerIn: parent
                text: I18n.t("airpods.notConnected")
                color: Colors.textDim
                font.pixelSize: UIScale.fontBody
            }
        }

        // Connected

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: AirPodsService.connected
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
                    text: I18n.t("airpods.deviceSection")
                }

                SettingCard {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: UIScale.spacingSm

                        Column {
                            spacing: Math.round(2 * UIScale.value)
                            Text {
                                text: I18n.t("airpods.nameLabel")
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: {
                                    var m = AirPodsService.model;
                                    var f = AirPodsService.firmware;
                                    if (m && f)
                                        return m + " · " + I18n.t("airpods.firmware") + " " + f;
                                    if (m)
                                        return m;
                                    return I18n.t("airpods.model") + " -";
                                }
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledTextInput {
                            id: nameField
                            Layout.preferredWidth: Math.round(180 * UIScale.value)
                            text: AirPodsService.deviceName
                            onAccepted: {
                                if (text.length > 0)
                                    AirPodsService.rename(text);
                                field.focus = false;
                            }
                        }
                    }
                }

                // Battery

                SectionLabel {
                    Layout.leftMargin: UIScale.panelPad
                    text: I18n.t("airpods.batterySection")
                }

                SettingCard {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    BatteryRow {
                        Layout.fillWidth: true
                        label: I18n.t("airpods.left")
                        level: AirPodsService.leftLevel
                        charging: AirPodsService.leftCharging
                        inEar: AirPodsService.leftEar
                    }
                    BatteryRow {
                        Layout.fillWidth: true
                        label: I18n.t("airpods.right")
                        level: AirPodsService.rightLevel
                        charging: AirPodsService.rightCharging
                        inEar: AirPodsService.rightEar
                    }
                    BatteryRow {
                        Layout.fillWidth: true
                        label: I18n.t("airpods.case")
                        level: AirPodsService.caseLevel
                        charging: AirPodsService.caseCharging
                        inEar: true
                        visible: AirPodsService.caseLevel > 0
                    }
                }

                // Noise control

                SectionLabel {
                    Layout.leftMargin: UIScale.panelPad
                    text: I18n.t("airpods.noiseSection")
                }

                SettingCard {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    SegmentedToggle {
                        Layout.fillWidth: true
                        model: [I18n.t("airpods.noiseOff"), I18n.t("airpods.noiseAnc"), I18n.t("airpods.noiseTransparency"), I18n.t("airpods.noiseAdaptive")]
                        currentIndex: root._noiseModes.indexOf(AirPodsService.noiseMode)
                        onActivated: idx => AirPodsService.setNoiseMode(root._noiseModes[idx])
                    }

                    DebouncedSlider {
                        Layout.fillWidth: true
                        visible: AirPodsService.noiseMode === "adaptive"
                        label: I18n.t("airpods.adaptiveLevel")
                        committed: AirPodsSettings.adaptiveLevel
                        onCommit: v => AirPodsService.setAdaptiveLevel(v)
                    }
                }

                // Stem

                SectionLabel {
                    Layout.leftMargin: UIScale.panelPad
                    text: I18n.t("airpods.stemSection")
                }

                SettingCard {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    LabeledSegment {
                        label: I18n.t("airpods.micLabel")
                        options: [I18n.t("airpods.micAuto"), I18n.t("airpods.micLeft"), I18n.t("airpods.micRight")]
                        currentIndex: root._micModes.indexOf(AirPodsSettings.micMode)
                        onActivated: i => AirPodsService.setMicMode(root._micModes[i])
                    }

                    ToggleRow {
                        label: I18n.t("airpods.volumeSwipe")
                        hint: I18n.t("airpods.volumeSwipeHint")
                        checked: AirPodsSettings.volumeSwipe
                        onToggled: AirPodsService.setVolumeSwipe(!AirPodsSettings.volumeSwipe)
                    }
                }

                // Behaviour

                SectionLabel {
                    Layout.leftMargin: UIScale.panelPad
                    text: I18n.t("airpods.behaviourSection")
                }

                SettingCard {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    ToggleRow {
                        label: I18n.t("airpods.conversationalAwareness")
                        hint: I18n.t("airpods.conversationalAwarenessHint")
                        checked: AirPodsService.caEnabled === true
                        onToggled: AirPodsService.setConversationalAwareness(AirPodsService.caEnabled !== true)
                    }
                    ToggleRow {
                        label: I18n.t("airpods.earDetection")
                        hint: I18n.t("airpods.earDetectionHint")
                        checked: AirPodsSettings.earDetection
                        onToggled: AirPodsService.setEarDetection(!AirPodsSettings.earDetection)
                    }
                    ToggleRow {
                        label: I18n.t("airpods.oneBudAnc")
                        hint: I18n.t("airpods.oneBudAncHint")
                        checked: AirPodsSettings.oneBudAnc
                        onToggled: AirPodsService.setOneBudAnc(!AirPodsSettings.oneBudAnc)
                    }
                    ToggleRow {
                        label: I18n.t("airpods.adaptiveVolume")
                        hint: I18n.t("airpods.adaptiveVolumeHint")
                        checked: AirPodsSettings.adaptiveVolume
                        onToggled: AirPodsService.setAdaptiveVolume(!AirPodsSettings.adaptiveVolume)
                    }
                    ToggleRow {
                        label: I18n.t("airpods.sleepDetection")
                        hint: I18n.t("airpods.sleepDetectionHint")
                        checked: AirPodsSettings.sleepDetection
                        onToggled: AirPodsService.setSleepDetection(!AirPodsSettings.sleepDetection)
                    }
                    ToggleRow {
                        label: I18n.t("airpods.autoPause")
                        hint: I18n.t("airpods.autoPauseHint")
                        checked: AirPodsSettings.autoPauseEnabled
                        onToggled: AirPodsSettings.writeAutoPauseEnabled(!AirPodsSettings.autoPauseEnabled)
                    }
                }

                // Sounds

                SectionLabel {
                    Layout.leftMargin: UIScale.panelPad
                    text: I18n.t("airpods.soundsSection")
                }

                SettingCard {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    ToggleRow {
                        label: I18n.t("airpods.caseSounds")
                        hint: I18n.t("airpods.caseSoundsHint")
                        checked: AirPodsSettings.caseSounds
                        onToggled: AirPodsService.setCaseSounds(!AirPodsSettings.caseSounds)
                    }
                    DebouncedSlider {
                        Layout.fillWidth: true
                        visible: AirPodsSettings.caseSounds
                        label: I18n.t("airpods.caseToneVolume")
                        committed: AirPodsSettings.caseToneVolume
                        onCommit: v => AirPodsService.setCaseToneVolume(v)
                    }
                    DebouncedSlider {
                        Layout.fillWidth: true
                        label: I18n.t("airpods.chimeVolume")
                        committed: AirPodsSettings.chimeVolume
                        onCommit: v => AirPodsService.setChimeVolume(v)
                    }
                }

                // Press & hold

                SectionLabel {
                    Layout.leftMargin: UIScale.panelPad
                    text: I18n.t("airpods.pressHold")
                }

                SettingCard {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    Text {
                        Layout.fillWidth: true
                        text: I18n.t("airpods.pressHoldHint")
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontTiny
                        wrapMode: Text.WordWrap
                    }

                    Repeater {
                        model: root._phModes
                        delegate: RowLayout {
                            id: phRow
                            required property string modelData
                            Layout.fillWidth: true

                            Text {
                                text: I18n.t("airpods.noise" + phRow.modelData.charAt(0).toUpperCase() + phRow.modelData.slice(1))
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                Layout.fillWidth: true
                            }

                            ToggleSwitch {
                                checked: root._phHas(phRow.modelData)
                                onToggled: root._phToggle(phRow.modelData)
                            }
                        }
                    }
                }

                Item {
                    implicitHeight: UIScale.spacingXs
                }
            }
        }
    }
}
