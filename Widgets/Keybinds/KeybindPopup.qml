pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../"

Item {
    id: root

    function focusSearch() {
        searchField.forceActiveFocus();
    }

    property var _filtered: {
        var q = searchField.text.trim().toLowerCase();
        if (!q)
            return KeybindService.sections;
        return KeybindService.sections.map(sec => ({
                    name: sec.name,
                    icon: sec.icon,
                    binds: sec.binds.filter(b => b.label.toLowerCase().includes(q) || b.keys.join(" ").toLowerCase().includes(q))
                })).filter(sec => sec.binds.length > 0);
    }

    // Card background
    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Colors.bg
        border.color: Colors.outline
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // Search bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: 10
                color: Colors.surface
                border.color: searchField.activeFocus ? Colors.accent : Colors.outline
                border.width: 1
                Behavior on border.color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: "󰍉"
                        color: Colors.textDim
                        font.pixelSize: 16
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 2
                            text: "Search keybinds…"
                            color: Colors.textDim
                            font.pixelSize: 14
                            verticalAlignment: Text.AlignVCenter
                            visible: searchField.text.length === 0
                        }

                        TextInput {
                            id: searchField
                            anchors.fill: parent
                            color: Colors.text
                            font.pixelSize: 14
                            verticalAlignment: TextInput.AlignVCenter
                            Keys.onEscapePressed: {
                                if (text.length > 0)
                                    clear();
                                else
                                    KeybindService.popupOpen = false;
                            }
                        }
                    }
                }
            }

            // Section cards
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: cardsFlow.implicitHeight
                clip: true

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Flow {
                    id: cardsFlow
                    width: parent.width
                    spacing: 10

                    Repeater {
                        model: root._filtered

                        delegate: Rectangle {
                            id: sectionCard
                            required property var modelData

                            width: 270
                            height: cardCol.height + 24
                            radius: 12
                            color: Colors.surface

                            Column {
                                id: cardCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 12
                                spacing: 6

                                // Header
                                Row {
                                    spacing: 7

                                    Text {
                                        text: sectionCard.modelData.icon
                                        color: Colors.accent
                                        font.pixelSize: 15
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: sectionCard.modelData.name
                                        color: Colors.text
                                        font.pixelSize: 13
                                        font.weight: Font.SemiBold
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                // Divider
                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: Colors.outline
                                }

                                // Bind rows
                                Repeater {
                                    model: sectionCard.modelData.binds

                                    delegate: Item {
                                        id: brow
                                        required property var modelData

                                        width: cardCol.width
                                        height: 22

                                        Row {
                                            id: chips
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 2

                                            Repeater {
                                                model: {
                                                    var flat = [];
                                                    var ks = brow.modelData.keys;
                                                    for (var ki = 0; ki < ks.length; ki++) {
                                                        if (ki > 0)
                                                            flat.push("+");
                                                        flat.push(ks[ki]);
                                                    }
                                                    return flat;
                                                }

                                                delegate: Rectangle {
                                                    required property string modelData
                                                    required property int index

                                                    property bool isSep: modelData === "+"

                                                    radius: 3
                                                    color: isSep ? "transparent" : Colors.withAlpha(Colors.text, 0.07)
                                                    border.color: isSep ? "transparent" : Colors.outline
                                                    border.width: 1
                                                    implicitWidth: chipTxt.implicitWidth + (isSep ? 2 : 10)
                                                    height: 18

                                                    Text {
                                                        id: chipTxt
                                                        anchors.centerIn: parent
                                                        text: parent.modelData
                                                        color: parent.isSep ? Colors.textDim : Colors.text
                                                        font.pixelSize: 10
                                                        font.weight: Font.Medium
                                                        font.family: "monospace"
                                                    }
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.left: chips.right
                                            anchors.leftMargin: 8
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: brow.modelData.label
                                            color: Colors.textDim
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root._filtered.length === 0 && KeybindService.sections.length > 0

                Text {
                    anchors.centerIn: parent
                    text: "No keybinds match"
                    color: Colors.textDim
                    font.pixelSize: 14
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: KeybindService.sections.length === 0

                Text {
                    anchors.centerIn: parent
                    text: "No Hyprland config found"
                    color: Colors.textDim
                    font.pixelSize: 14
                }
            }
        }
    }
}
