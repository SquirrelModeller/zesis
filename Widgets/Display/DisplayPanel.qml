pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../"
import "../Shared"

Item {
    id: root

    property int selWidth: DisplayService.currentWidth
    property int selHeight: DisplayService.currentHeight
    property real selRefresh: DisplayService.currentRefresh

    readonly property bool hasChange: selWidth !== DisplayService.currentWidth || selHeight !== DisplayService.currentHeight || Math.abs(selRefresh - DisplayService.currentRefresh) > 0.01

    readonly property string selModeStr: selWidth + "x" + selHeight + "@" + selRefresh.toFixed(2) + "Hz"

    onVisibleChanged: if (visible)
        resetSelection()
    function resetSelection() {
        selWidth = DisplayService.currentWidth;
        selHeight = DisplayService.currentHeight;
        selRefresh = DisplayService.currentRefresh;
    }

    component StyledComboBox: ComboBox {
        id: cb

        implicitHeight: Math.round(36 * UIScale.value)

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
                font.pixelSize: Math.round(18 * UIScale.value)
                color: Colors.textDim
                verticalAlignment: Text.AlignVCenter
            }
        }

        delegate: ItemDelegate {
            id: cbItem
            required property string modelData
            required property int index
            width: ListView.view?.width ?? cb.width
            implicitHeight: Math.round(36 * UIScale.value)

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
            height: Math.min(listView.contentHeight + topPadding + bottomPadding, Math.round(280 * UIScale.value))
            padding: UIScale.spacingXs

            background: Rectangle {
                radius: UIScale.radiusSm
                color: Colors.surfaceHigh
                border.color: Colors.accent
                border.width: 1
            }

            contentItem: ListView {
                id: listView
                clip: true
                implicitHeight: contentHeight
                model: cb.popup.visible ? cb.delegateModel : null
                currentIndex: cb.highlightedIndex
                ScrollBar.vertical: ScrollBar {}
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: "SETTINGS / DISPLAY & SCALE"
            title: "Display & Scale"
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

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(56 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Colors.withAlpha(Colors.text, 0.04)
                    border.color: Colors.withAlpha(Colors.text, 0.06)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(16 * UIScale.value)
                        anchors.rightMargin: Math.round(16 * UIScale.value)
                        spacing: UIScale.spacingMd

                        Text {
                            text: ""
                            font.family: "Material Icons"
                            font.pixelSize: Math.round(22 * UIScale.value)
                            color: Colors.accent
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: Math.round(2 * UIScale.value)

                            Text {
                                text: DisplayService.monitorModel || DisplayService.monitorName || "Monitor"
                                color: Colors.text
                                font.pixelSize: UIScale.fontBody
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: {
                                    var parts = [];
                                    if (DisplayService.monitorName)
                                        parts.push(DisplayService.monitorName);
                                    if (DisplayService.diagonalInches > 0)
                                        parts.push(DisplayService.diagonalInches + '"');
                                    if (DisplayService.currentWidth > 0)
                                        parts.push(DisplayService.currentWidth + " × " + DisplayService.currentHeight + " @ " + Math.round(DisplayService.currentRefresh) + " Hz");
                                    return parts.join("  ·  ");
                                }
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontCaption
                                font.family: "monospace"
                            }
                        }
                    }
                }

                Text {
                    text: "Resolution"
                    color: Colors.text
                    font.pixelSize: UIScale.fontBody
                    font.bold: true
                    Layout.leftMargin: UIScale.panelPad
                }

                StyledComboBox {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    model: DisplayService.uniqueResolutions.map(r => r.width + " × " + r.height)

                    currentIndex: {
                        var res = DisplayService.uniqueResolutions;
                        for (var i = 0; i < res.length; i++) {
                            if (res[i].width === root.selWidth && res[i].height === root.selHeight)
                                return i;
                        }
                        return 0;
                    }

                    onActivated: idx => {
                        var r = DisplayService.uniqueResolutions[idx];
                        root.selWidth = r.width;
                        root.selHeight = r.height;
                        var rates = DisplayService.refreshRatesFor(root.selWidth, root.selHeight);
                        root.selRefresh = rates.length > 0 ? rates[0] : 0;
                    }
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                Text {
                    text: "Refresh Rate"
                    color: Colors.text
                    font.pixelSize: UIScale.fontBody
                    font.bold: true
                    Layout.leftMargin: UIScale.panelPad
                }

                StyledComboBox {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    model: DisplayService.refreshRatesFor(root.selWidth, root.selHeight).map(r => {
                        var rounded = Math.round(r);
                        return (Math.abs(r - rounded) < 0.01 ? rounded : r.toFixed(2)) + " Hz";
                    })

                    currentIndex: {
                        var rates = DisplayService.refreshRatesFor(root.selWidth, root.selHeight);
                        for (var i = 0; i < rates.length; i++) {
                            if (Math.abs(rates[i] - root.selRefresh) < 0.01)
                                return i;
                        }
                        return 0;
                    }

                    onActivated: idx => {
                        var rates = DisplayService.refreshRatesFor(root.selWidth, root.selHeight);
                        root.selRefresh = rates[idx];
                    }
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(38 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: root.hasChange ? Colors.accent : Colors.surfaceHigh
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.hasChange ? "Apply" : "Active"
                        color: root.hasChange ? Colors.bg : Colors.muted
                        font.pixelSize: UIScale.fontBody
                        font.weight: Font.DemiBold
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: root.hasChange ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (root.hasChange)
                                DisplayService.apply(root.selModeStr);
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
