pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../"

Item {
    id: root

    property bool showSettings: false

    Component.onCompleted: scanner.running = true

    readonly property string _wallpapersDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

    readonly property var presets: [
        {
            name: "Harmonious",
            desc: "Blends similar colors - great for atmospheric images",
            args: "-b fastresize -c labmixed -k"
        },
        {
            name: "Vivid",
            desc: "Picks colors that visually pop from the background",
            args: "-b thumb -c salience -k"
        },
        {
            name: "Balanced",
            desc: "Perceptual LCH colorspace, good middle ground",
            args: "-b resized -c lch -k"
        },
        {
            name: "Soft",
            desc: "LCH with color mixing for softer palettes",
            args: "-b thumb -c lchmixed -k"
        },
    ]

    ListModel {
        id: wallpapers
    }

    Process {
        id: scanner
        command: ["bash", "-c", "find \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null | sort > \"$2\"", "--", root._wallpapersDir, Quickshell.env("HOME") + "/.cache/zesis/wallpapers.txt"]
        stdout: StdioCollector {}
        onExited: listReader.reload()
    }

    FileView {
        id: listReader
        path: Quickshell.env("HOME") + "/.cache/zesis/wallpapers.txt"
        onLoaded: {
            var lines = text().split("\n");
            wallpapers.clear();
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line !== "")
                    wallpapers.append({
                        path: line
                    });
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Colors.bg
        border.color: Colors.outline
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header row
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Themes"
                color: Colors.text
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }

            Item {
                Layout.fillWidth: true
            }

            // Dark / Light pill toggle
            Rectangle {
                Layout.preferredWidth: 120
                Layout.preferredHeight: 32
                radius: 16
                color: Colors.surface

                Rectangle {
                    id: pillSlider
                    width: 56
                    height: 26
                    radius: 13
                    anchors.verticalCenter: parent.verticalCenter
                    x: ThemeState.palette === "dark" ? 3 : 61
                    color: Colors.accent
                    Behavior on x {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: "Dark"
                        color: ThemeState.palette === "dark" ? Colors.bg : Colors.textDim
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        Behavior on color {
                            ColorAnimation {
                                duration: 180
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Light"
                        color: ThemeState.palette === "light" ? Colors.bg : Colors.textDim
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        Behavior on color {
                            ColorAnimation {
                                duration: 180
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        ThemeState.palette = ThemeState.palette === "dark" ? "light" : "dark";
                        if (ThemeState.lastWallpaper !== "")
                            ThemeState.apply(ThemeState.lastWallpaper);
                    }
                }
            }

            // Gear button
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 8
                color: root.showSettings ? Colors.withAlpha(Colors.accent, 0.15) : "transparent"
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "⚙"
                    font.pixelSize: 16
                    color: root.showSettings ? Colors.accent : Colors.textDim
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showSettings = !root.showSettings
                }
            }
        }

        // Content area, switches between wallpaper list and settings panel
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Wallpaper section
            ColumnLayout {
                anchors.fill: parent
                spacing: 12
                visible: !root.showSettings

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 8
                    color: Colors.surface
                    border.color: searchField.activeFocus ? Colors.accent : Colors.outline
                    border.width: 1
                    Behavior on border.color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    TextInput {
                        id: searchField
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 12
                            rightMargin: 12
                        }
                        color: Colors.text
                        font.pixelSize: 13
                        clip: true
                        selectionColor: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.35)

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Search wallpapers..."
                            color: Colors.textDim
                            font.pixelSize: 13
                            visible: searchField.text === ""
                        }
                    }
                }

                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4
                    clip: true
                    model: wallpapers

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    WheelHandler {
                        onWheel: event => {
                            listView.contentY = Math.max(listView.originY, Math.min(listView.originY + listView.contentHeight - listView.height, listView.contentY - event.angleDelta.y * 0.5));
                        }
                    }

                    delegate: WallpaperItem {
                        required property string path
                        wallpaperPath: path
                        width: listView.width - 8
                        visible: searchField.text === "" || path.toLowerCase().includes(searchField.text.toLowerCase())
                        height: visible ? implicitHeight : 0
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: wallpapers.count === 0 && !scanner.running
                        text: "No wallpapers found in\n~/Pictures/Wallpapers"
                        color: Colors.textDim
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // Settings panel
            Column {
                anchors.fill: parent
                spacing: 6
                visible: root.showSettings

                Repeater {
                    model: root.presets
                    delegate: Rectangle {
                        id: presetItem
                        required property var modelData
                        required property int index

                        width: parent.width
                        height: 64
                        radius: 8
                        color: ThemeState.wallustArgs === presetItem.modelData.args ? Colors.withAlpha(Colors.accent, 0.12) : presetHover.hovered ? Colors.surface : Colors.withAlpha(Colors.surface, 0.5)
                        border.color: ThemeState.wallustArgs === presetItem.modelData.args ? Colors.withAlpha(Colors.accent, 0.5) : "transparent"
                        border.width: 1
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        Column {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 12
                                rightMargin: 12
                            }
                            spacing: 3

                            Text {
                                text: presetItem.modelData.name
                                color: ThemeState.wallustArgs === presetItem.modelData.args ? Colors.accent : Colors.text
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                text: presetItem.modelData.desc
                                color: Colors.textDim
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                            }
                        }

                        HoverHandler {
                            id: presetHover
                        }

                        TapHandler {
                            onTapped: {
                                ThemeState.wallustArgs = presetItem.modelData.args;
                                if (ThemeState.lastWallpaper !== "")
                                    ThemeState.apply(ThemeState.lastWallpaper);
                            }
                        }
                    }
                }
            }
        }
    }
}
