pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "./"
import "../Shared"
import "../../"

Item {
    id: root

    readonly property var _colonOptions: ["Breathing", "Always on", "Always off", "Hidden"]
    readonly property var _colonModes: ["breathe", "on", "off", "hidden"]
    readonly property var _widthOptions: ["Fixed", "Fluid"]
    readonly property var _widthModes: ["fixed", "fluid"]
    readonly property var _showDateOptions: ["Off", "On"]
    readonly property var _showDateValues: [false, true]

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: "SETTINGS / CLOCK"
            title: "Clock"
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
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

                // Preview card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(110 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Colors.withAlpha(Colors.text, 0.03)
                    border.color: Colors.withAlpha(Colors.text, 0.06)
                    border.width: 1

                    Clock {
                        id: preview
                        anchors.centerIn: parent
                    }

                    Text {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.margins: UIScale.spacingSm
                        text: "PREVIEW"
                        color: Colors.withAlpha(Colors.muted, 0.4)
                        font.pixelSize: UIScale.fontTiny
                        font.letterSpacing: 1.5
                        font.weight: Font.Bold
                    }
                }

                Text {
                    text: "APPEARANCE"
                    color: Colors.muted
                    font.pixelSize: UIScale.fontTiny
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    Layout.leftMargin: UIScale.panelPad
                    Layout.topMargin: UIScale.spacingXs
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(56 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Colors.withAlpha(Colors.text, 0.03)
                    border.color: Colors.withAlpha(Colors.text, 0.06)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: UIScale.spacingMd
                        anchors.rightMargin: UIScale.spacingMd
                        spacing: UIScale.spacingSm

                        Column {
                            spacing: Math.round(2 * UIScale.value)
                            Text {
                                text: "Colon"
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: "Style of the : separator"
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledComboBox {
                            Layout.preferredWidth: Math.round(140 * UIScale.value)
                            model: root._colonOptions
                            currentIndex: root._colonModes.indexOf(ClockSettings.colonMode)
                            onActivated: idx => ClockSettings.writeColonMode(root._colonModes[idx])
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(56 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Colors.withAlpha(Colors.text, 0.03)
                    border.color: Colors.withAlpha(Colors.text, 0.06)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: UIScale.spacingMd
                        anchors.rightMargin: UIScale.spacingMd
                        spacing: UIScale.spacingSm

                        Column {
                            spacing: Math.round(2 * UIScale.value)
                            Text {
                                text: "Width"
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: "Pill resize during animation"
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledComboBox {
                            Layout.preferredWidth: Math.round(140 * UIScale.value)
                            model: root._widthOptions
                            currentIndex: root._widthModes.indexOf(ClockSettings.widthMode)
                            onActivated: idx => ClockSettings.writeWidthMode(root._widthModes[idx])
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(56 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Colors.withAlpha(Colors.text, 0.03)
                    border.color: Colors.withAlpha(Colors.text, 0.06)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: UIScale.spacingMd
                        anchors.rightMargin: UIScale.spacingMd
                        spacing: UIScale.spacingSm

                        Column {
                            spacing: Math.round(2 * UIScale.value)
                            Text {
                                text: "Show Date"
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: "Prefix with day and date"
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledComboBox {
                            Layout.preferredWidth: Math.round(140 * UIScale.value)
                            model: root._showDateOptions
                            currentIndex: ClockSettings.showDate ? 1 : 0
                            onActivated: idx => ClockSettings.writeShowDate(root._showDateValues[idx])
                        }
                    }
                }

                Text {
                    text: "ANIMATION TEST"
                    color: Colors.muted
                    font.pixelSize: UIScale.fontTiny
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    Layout.leftMargin: UIScale.panelPad
                    Layout.topMargin: UIScale.spacingXs
                }

                // Snap row, instantly set what the clock displays
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(56 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Colors.withAlpha(Colors.text, 0.03)
                    border.color: Colors.withAlpha(Colors.text, 0.06)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: UIScale.spacingMd
                        anchors.rightMargin: UIScale.spacingMd
                        spacing: UIScale.spacingSm

                        Column {
                            spacing: Math.round(2 * UIScale.value)
                            Layout.preferredWidth: Math.round(52 * UIScale.value)
                            Text {
                                text: "Snap to"
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: "No animation"
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        TimeSpinner {
                            id: snapH
                            maxVal: 23
                            value: 9
                        }

                        Text {
                            text: ":"
                            color: Colors.muted
                            font.pixelSize: UIScale.fontSubhead
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                        }

                        TimeSpinner {
                            id: snapM
                            maxVal: 59
                            value: 59
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        ActionButton {
                            label: "Snap"
                            onActivated: preview.snapTo(snapH.value, snapM.value)
                        }
                    }
                }

                // Animate row, trigger the typewriter animation
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(56 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Colors.withAlpha(Colors.text, 0.03)
                    border.color: Colors.withAlpha(Colors.text, 0.06)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: UIScale.spacingMd
                        anchors.rightMargin: UIScale.spacingMd
                        spacing: UIScale.spacingSm

                        Column {
                            spacing: Math.round(2 * UIScale.value)
                            Layout.preferredWidth: Math.round(52 * UIScale.value)
                            Text {
                                text: "Animate to"
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: "Typewriter"
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        TimeSpinner {
                            id: animH
                            maxVal: 23
                            value: 10
                        }

                        Text {
                            text: ":"
                            color: Colors.muted
                            font.pixelSize: UIScale.fontSubhead
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                        }

                        TimeSpinner {
                            id: animM
                            maxVal: 59
                            value: 0
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        ActionButton {
                            label: "Go"
                            onActivated: preview.simulateTo(animH.value, animM.value)
                        }
                    }
                }

                // Alt mode test card
                // Rectangle {
                //     Layout.fillWidth: true
                //     Layout.leftMargin: UIScale.panelPad
                //     Layout.rightMargin: UIScale.panelPad
                //     implicitHeight: Math.round(56 * UIScale.value)
                //     radius: UIScale.radiusMd
                //     color: Colors.withAlpha(Colors.accent, 0.04)
                //     border.color: Colors.withAlpha(Colors.accent, 0.14)
                //     border.width: 1

                //     RowLayout {
                //         anchors.fill: parent
                //         anchors.leftMargin: UIScale.spacingMd
                //         anchors.rightMargin: UIScale.spacingMd
                //         spacing: UIScale.spacingSm

                //         Column {
                //             spacing: Math.round(2 * UIScale.value)
                //             Text {
                //                 text: "Alt mode"
                //                 color: Colors.text
                //                 font.pixelSize: UIScale.fontSmall
                //                 font.weight: Font.DemiBold
                //             }
                //             Text {
                //                 text: "Alternate display"
                //                 color: Colors.textDim
                //                 font.pixelSize: UIScale.fontTiny
                //             }
                //         }

                //         Item {
                //             Layout.fillWidth: true
                //         }

                //         Item {
                //             Layout.preferredWidth: UIScale.spacingSm
                //         }

                //         ActionButton {
                //             label: "Trigger"
                //             onActivated: ClockSettings.altModeRequested()
                //         }
                //     }
                // }

                Item {
                    implicitHeight: UIScale.spacingXs
                }
            }
        }
    }

    // +/- spinner for a bounded integer value
    component TimeSpinner: RowLayout {
        id: ts
        property int value: 0
        property int maxVal: 23

        spacing: Math.round(3 * UIScale.value)

        Rectangle {
            implicitWidth: Math.round(26 * UIScale.value)
            implicitHeight: Math.round(28 * UIScale.value)
            radius: UIScale.radiusSm
            color: decHov.hovered ? Colors.withAlpha(Colors.text, 0.1) : Colors.surfaceHigh
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
            Text {
                anchors.centerIn: parent
                text: "−"
                color: Colors.textDim
                font.pixelSize: UIScale.fontBody
                font.bold: true
            }
            HoverHandler {
                id: decHov
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ts.value = (ts.value - 1 + ts.maxVal + 1) % (ts.maxVal + 1)
            }
        }

        Rectangle {
            implicitWidth: Math.round(34 * UIScale.value)
            implicitHeight: Math.round(28 * UIScale.value)
            radius: UIScale.radiusSm
            color: Colors.withAlpha(Colors.text, 0.05)
            Text {
                anchors.centerIn: parent
                text: ts.value.toString().padStart(2, "0")
                color: Colors.accent
                font.pixelSize: UIScale.fontSmall
                font.bold: true
                font.family: "monospace"
            }
        }

        Rectangle {
            implicitWidth: Math.round(26 * UIScale.value)
            implicitHeight: Math.round(28 * UIScale.value)
            radius: UIScale.radiusSm
            color: incHov.hovered ? Colors.withAlpha(Colors.text, 0.1) : Colors.surfaceHigh
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
            Text {
                anchors.centerIn: parent
                text: "+"
                color: Colors.textDim
                font.pixelSize: UIScale.fontBody
                font.bold: true
            }
            HoverHandler {
                id: incHov
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ts.value = (ts.value + 1) % (ts.maxVal + 1)
            }
        }
    }

    component StyledComboBox: ComboBox {
        id: cb

        implicitHeight: Math.round(34 * UIScale.value)

        background: Rectangle {
            radius: UIScale.radiusSm
            color: Colors.surfaceHigh
            border.color: cb.popup.visible ? Colors.accent : Colors.withAlpha(Colors.text, 0.12)
            border.width: 1
            Behavior on border.color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: Qt.PointingHandCursor
            }
        }

        contentItem: RowLayout {
            anchors.fill: parent
            anchors.leftMargin: UIScale.radiusMd
            anchors.rightMargin: UIScale.spacingSm
            spacing: UIScale.spacingSm
            Text {
                text: cb.displayText
                color: Colors.text
                font.pixelSize: UIScale.fontBody
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Text {
                text: cb.popup.visible ? "" : ""
                font.family: "Material Icons"
                font.pixelSize: Math.round(16 * UIScale.value)
                color: Colors.textDim
                verticalAlignment: Text.AlignVCenter
            }
        }

        delegate: ItemDelegate {
            id: cbItem
            required property string modelData
            required property int index
            width: ListView.view?.width ?? cb.width
            implicitHeight: Math.round(34 * UIScale.value)

            background: Rectangle {
                color: cb.currentIndex === cbItem.index ? Colors.withAlpha(Colors.accent, 0.15) : (cbItem.hovered ? Colors.withAlpha(Colors.text, 0.05) : "transparent")
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    cursorShape: Qt.PointingHandCursor
                }
            }

            contentItem: Text {
                text: cbItem.modelData
                color: Colors.text
                font.pixelSize: UIScale.fontBody
                verticalAlignment: Text.AlignVCenter
                leftPadding: UIScale.radiusMd
            }
        }

        popup: Popup {
            y: cb.height + UIScale.spacingXs
            width: cb.width
            padding: UIScale.spacingXs

            background: Rectangle {
                radius: UIScale.radiusSm
                color: Colors.surfaceHigh
                border.color: Colors.accent
                border.width: 1
            }

            contentItem: ListView {
                id: cbList
                clip: true
                implicitHeight: contentHeight
                model: cb.popup.visible ? cb.delegateModel : null
                currentIndex: cb.highlightedIndex
                ScrollBar.vertical: ScrollBar {}
            }
        }
    }

    // Small accent-colored action button
    component ActionButton: Item {
        id: ab
        signal activated

        property string label: ""

        implicitWidth: Math.round(58 * UIScale.value)
        implicitHeight: Math.round(32 * UIScale.value)

        Rectangle {
            anchors.fill: parent
            radius: UIScale.radiusSm
            color: abHov.hovered ? Colors.withAlpha(Colors.accent, 0.28) : Colors.withAlpha(Colors.accent, 0.14)
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }

            Text {
                anchors.centerIn: parent
                text: ab.label
                color: Colors.accent
                font.pixelSize: UIScale.fontSmall
                font.weight: Font.DemiBold
            }
        }

        HoverHandler {
            id: abHov
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ab.activated()
        }
    }
}
