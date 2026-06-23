pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../"

Item {
    id: root

    readonly property string _wallpapersDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

    Component.onCompleted: scanner.running = true

    ListModel {
        id: wallpapers
    }
    ListModel {
        id: filteredWallpapers
    }

    function _updateFilter(search) {
        filteredWallpapers.clear();
        for (var i = 0; i < wallpapers.count; i++) {
            var p = wallpapers.get(i).path;
            if (search === "" || p.toLowerCase().includes(search.toLowerCase()))
                filteredWallpapers.append({
                    path: p
                });
        }
    }

    Process {
        id: scanner
        command: ["bash", "-c", "find \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null | sort > \"$2\"", "--", root._wallpapersDir, Quickshell.env("HOME") + "/.cache/zesis/wallpapers.txt"]
        stdout: StdioCollector {}
        onExited: () => listReader.reload()
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
            root._updateFilter("");
        }
    }

    component WallpaperCell: Item {
        id: cell
        required property string path
        readonly property bool selected: ThemeState.lastWallpaper === cell.path
        readonly property string _baseName: cell.path.substring(cell.path.lastIndexOf("/") + 1)
        readonly property string _displayName: cell._baseName.replace(/\.[^.]+$/, "")
        readonly property string _thumbPath: ThemeState.thumbsDir + "/" + cell._baseName + ".jpg"

        Rectangle {
            id: cellBg
            anchors.fill: parent
            anchors.margins: UIScale.spacingXs
            radius: UIScale.radiusSm
            color: cell.selected ? Colors.withAlpha(Colors.accent, 0.12) : (cellHover.hovered ? Colors.surfaceHigh : "transparent")
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }

            Rectangle {
                id: thumbRect
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: UIScale.spacingXs
                height: Math.round(width * 9 / 16)
                radius: UIScale.radiusSm
                color: Colors.surface
                clip: true

                Image {
                    id: thumbImg
                    anchors.fill: parent
                    source: "file://" + cell._thumbPath
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    onStatusChanged: {
                        if (status === Image.Error && !thumbGen.running)
                            thumbGen.running = true;
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Colors.surface
                    visible: thumbImg.status !== Image.Ready
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: Colors.accent
                    border.width: Math.round(2 * UIScale.value)
                    opacity: cell.selected ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Anim.fast
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Qt.rgba(0, 0, 0, 0.5)
                    visible: ThemeState.applying && cell.selected

                    Text {
                        anchors.centerIn: parent
                        text: "..."
                        color: "white"
                        font.pixelSize: UIScale.fontLead
                    }
                }
            }

            Text {
                anchors.top: thumbRect.bottom
                anchors.topMargin: UIScale.spacingXs
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: UIScale.spacingXs
                anchors.rightMargin: UIScale.spacingXs
                text: cell._displayName
                color: cell.selected ? Colors.accent : Colors.textDim
                font.pixelSize: UIScale.fontTiny
                font.weight: cell.selected ? Font.Medium : Font.Normal
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
            }
        }

        HoverHandler {
            id: cellHover
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ThemeState.apply(cell.path)
        }

        Process {
            id: thumbGen
            command: ["magick", cell.path, "-resize", "240x135^", "-gravity", "Center", "-extent", "240x135", cell._thumbPath]
            onExited: (code, status) => {
                if (code === 0) {
                    thumbImg.source = "";
                    thumbImg.source = "file://" + cell._thumbPath;
                } else {
                    thumbImg.source = "file://" + cell.path;
                }
            }
        }
    }

    readonly property var _darkSwatches: [
        {
            c: Colors.darkPalette.background,
            label: "bg"
        },
        {
            c: Colors.darkPalette.surface_container,
            label: "surface"
        },
        {
            c: Colors.darkPalette.surface_container_high,
            label: "surf+"
        },
        {
            c: Colors.darkPalette.outline_variant,
            label: "border"
        },
        {
            c: Colors.darkPalette.primary,
            label: "primary"
        },
        {
            c: Colors.darkPalette.primary_container,
            label: "p.cont"
        },
        {
            c: Colors.darkPalette.on_primary,
            label: "on-p"
        },
        {
            c: Colors.darkPalette.on_background,
            label: "text"
        },
        {
            c: Colors.darkPalette.on_surface_variant,
            label: "dim"
        },
    ]
    readonly property var _lightSwatches: [
        {
            c: Colors.lightPalette.background,
            label: "bg"
        },
        {
            c: Colors.lightPalette.surface_container,
            label: "surface"
        },
        {
            c: Colors.lightPalette.surface_container_high,
            label: "surf+"
        },
        {
            c: Colors.lightPalette.outline_variant,
            label: "border"
        },
        {
            c: Colors.lightPalette.primary,
            label: "primary"
        },
        {
            c: Colors.lightPalette.primary_container,
            label: "p.cont"
        },
        {
            c: Colors.lightPalette.on_primary,
            label: "on-p"
        },
        {
            c: Colors.lightPalette.on_background,
            label: "text"
        },
        {
            c: Colors.lightPalette.on_surface_variant,
            label: "dim"
        },
    ]

    component PaletteRow: Item {
        id: paletteRow
        required property string rowLabel
        required property var swatches
        implicitHeight: Math.round(62 * UIScale.value)

        RowLayout {
            anchors.fill: parent
            spacing: UIScale.spacingSm

            Text {
                text: paletteRow.rowLabel
                color: Colors.textDim
                font.pixelSize: UIScale.fontCaption
                font.weight: Font.Medium
                Layout.preferredWidth: Math.round(38 * UIScale.value)
                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                topPadding: UIScale.spacingXs
            }

            Repeater {
                model: paletteRow.swatches
                Item {
                    id: swatchDelegate
                    required property var modelData
                    implicitWidth: Math.round(42 * UIScale.value)
                    implicitHeight: Math.round(62 * UIScale.value)

                    Rectangle {
                        id: swatch
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.round(38 * UIScale.value)
                        height: Math.round(38 * UIScale.value)
                        radius: Math.round(9 * UIScale.value)
                        color: swatchDelegate.modelData.c
                        border.color: Colors.withAlpha(Colors.text, 0.08)
                        border.width: 1

                        HoverHandler {
                            id: swatchHover
                        }

                        ToolTip {
                            visible: swatchHover.hovered
                            delay: 600
                            text: swatchDelegate.modelData.c
                        }
                    }

                    Text {
                        anchors.top: swatch.bottom
                        anchors.topMargin: UIScale.spacingXs
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: swatchDelegate.modelData.label
                        color: Colors.textDim
                        font.pixelSize: Math.round(9 * UIScale.value)
                    }
                }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Left: wallpaper list
        ColumnLayout {
            Layout.preferredWidth: Math.round(340 * UIScale.value)
            Layout.fillHeight: true
            spacing: UIScale.spacingSm

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(36 * UIScale.value)
                Layout.topMargin: UIScale.spacingLg
                Layout.leftMargin: Math.round(16 * UIScale.value)
                Layout.rightMargin: Math.round(16 * UIScale.value)
                radius: UIScale.radiusSm
                color: Colors.surface
                border.color: searchField.activeFocus ? Colors.accent : Colors.outline
                border.width: 1
                Behavior on border.color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }

                TextInput {
                    id: searchField
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: UIScale.radiusMd
                        rightMargin: UIScale.radiusMd
                    }
                    color: Colors.text
                    font.pixelSize: UIScale.fontSmall
                    clip: true
                    selectionColor: Colors.withAlpha(Colors.accent, 0.35)
                    onTextChanged: root._updateFilter(text)

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Search wallpapers..."
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontSmall
                        visible: searchField.text === ""
                    }
                }
            }

            GridView {
                id: gridView
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: UIScale.spacingSm
                Layout.rightMargin: UIScale.spacingSm
                Layout.bottomMargin: UIScale.radiusMd
                clip: true
                model: filteredWallpapers
                cellWidth: Math.round(gridView.width / 3)
                cellHeight: Math.round(cellWidth * 9 / 16) + Math.round(28 * UIScale.value)

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                WheelHandler {
                    onWheel: event => {
                        gridView.contentY = Math.max(gridView.originY, Math.min(gridView.originY + gridView.contentHeight - gridView.height, gridView.contentY - event.angleDelta.y * 0.5));
                    }
                }

                delegate: WallpaperCell {
                    width: gridView.cellWidth
                    height: gridView.cellHeight
                }

                Text {
                    anchors.centerIn: parent
                    visible: filteredWallpapers.count === 0 && !scanner.running
                    text: wallpapers.count === 0 ? "No wallpapers found in\n~/Pictures/Wallpapers" : "No results"
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontSmall
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Rectangle {
            implicitWidth: 1
            Layout.fillHeight: true
            color: Colors.withAlpha(Colors.outline, 0.5)
        }

        // Right: preview + palette
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Math.round(28 * UIScale.value)
            spacing: 0

            Text {
                text: "SETTINGS / WALLPAPER"
                color: Colors.accent
                font.pixelSize: UIScale.fontCaption
                font.weight: Font.Bold
                font.letterSpacing: 2
                font.family: "monospace"
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: UIScale.spacingXs
                Layout.bottomMargin: UIScale.spacingLg
                spacing: UIScale.spacingSm

                Text {
                    text: "Wallpaper & Theme"
                    color: Colors.text
                    font.pixelSize: UIScale.fontTitle
                    font.weight: Font.ExtraBold
                }

                Item {
                    Layout.fillWidth: true
                }

                // Scheme type dropdown
                Rectangle {
                    id: schemeDropdownBtn
                    Layout.preferredHeight: Math.round(32 * UIScale.value)
                    implicitWidth: schemeRow.implicitWidth + Math.round(24 * UIScale.value)
                    radius: UIScale.spacingSm
                    color: schemePopup.opened ? Colors.withAlpha(Colors.accent, 0.15) : (schemeHover.hovered ? Colors.surfaceHigh : Colors.surface)
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }

                    readonly property var _schemes: [
                        {
                            value: "scheme-tonal-spot",
                            label: "Tonal Spot"
                        },
                        {
                            value: "scheme-vibrant",
                            label: "Vibrant"
                        },
                        {
                            value: "scheme-expressive",
                            label: "Expressive"
                        },
                        {
                            value: "scheme-fidelity",
                            label: "Fidelity"
                        },
                        {
                            value: "scheme-content",
                            label: "Content"
                        },
                        {
                            value: "scheme-neutral",
                            label: "Neutral"
                        },
                        {
                            value: "scheme-monochrome",
                            label: "Monochrome"
                        },
                        {
                            value: "scheme-rainbow",
                            label: "Rainbow"
                        },
                        {
                            value: "scheme-fruit-salad",
                            label: "Fruit Salad"
                        },
                    ]

                    readonly property string _currentLabel: {
                        for (var i = 0; i < _schemes.length; i++) {
                            if (_schemes[i].value === ThemeState.schemeType)
                                return _schemes[i].label;
                        }
                        return ThemeState.schemeType;
                    }

                    Row {
                        id: schemeRow
                        anchors.centerIn: parent
                        spacing: UIScale.spacingXs

                        Text {
                            text: schemeDropdownBtn._currentLabel
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: schemePopup.opened ? "▴" : "▾"
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontTiny
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    HoverHandler {
                        id: schemeHover
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: schemePopup.opened ? schemePopup.close() : schemePopup.open()
                    }

                    Popup {
                        id: schemePopup
                        y: parent.height + UIScale.spacingXs
                        x: parent.width - width
                        width: Math.round(160 * UIScale.value)
                        padding: UIScale.spacingXs
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                        background: Rectangle {
                            radius: UIScale.radiusMd
                            color: Colors.surface
                            border.color: Colors.withAlpha(Colors.outline, 0.6)
                            border.width: 1
                        }

                        contentItem: Column {
                            spacing: Math.round(2 * UIScale.value)

                            Repeater {
                                model: schemeDropdownBtn._schemes
                                Rectangle {
                                    id: schemeOption
                                    required property var modelData
                                    width: schemePopup.width - UIScale.radiusMd
                                    implicitHeight: Math.round(32 * UIScale.value)
                                    radius: UIScale.spacingSm
                                    color: modelData.value === ThemeState.schemeType ? Colors.withAlpha(Colors.accent, 0.15) : (optHover.hovered ? Colors.surfaceHigh : "transparent")
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Anim.fast
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: UIScale.spacingSm
                                        text: schemeOption.modelData.label
                                        color: schemeOption.modelData.value === ThemeState.schemeType ? Colors.accent : Colors.text
                                        font.pixelSize: UIScale.fontBody
                                        font.weight: schemeOption.modelData.value === ThemeState.schemeType ? Font.Medium : Font.Normal
                                    }

                                    HoverHandler {
                                        id: optHover
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            ThemeState.schemeType = schemeOption.modelData.value;
                                            schemePopup.close();
                                            if (ThemeState.lastWallpaper !== "")
                                                ThemeState.apply(ThemeState.lastWallpaper);
                                            else
                                                ThemeState._persistState();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Dark / Light toggle
                Rectangle {
                    Layout.preferredWidth: Math.round(120 * UIScale.value)
                    Layout.preferredHeight: Math.round(32 * UIScale.value)
                    radius: Math.round(16 * UIScale.value)
                    color: Colors.surface

                    Rectangle {
                        width: Math.round(56 * UIScale.value)
                        height: Math.round(26 * UIScale.value)
                        radius: Math.round(13 * UIScale.value)
                        anchors.verticalCenter: parent.verticalCenter
                        x: ThemeState.palette === "dark" ? Math.round(3 * UIScale.value) : Math.round(61 * UIScale.value)
                        color: Colors.accent
                        Behavior on x {
                            NumberAnimation {
                                duration: Anim.medium
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
                            font.pixelSize: UIScale.fontTiny
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.medium
                                }
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Light"
                            color: ThemeState.palette === "light" ? Colors.bg : Colors.textDim
                            font.pixelSize: UIScale.fontTiny
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.medium
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ThemeState.togglePalette()
                    }
                }
            }

            // Current wallpaper preview
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(180 * UIScale.value)
                Layout.bottomMargin: Math.round(24 * UIScale.value)
                radius: UIScale.radiusMd
                color: Colors.surface
                clip: true
                visible: ThemeState.lastWallpaper !== ""

                Image {
                    anchors.fill: parent
                    source: ThemeState.lastWallpaper !== "" ? ("file://" + ThemeState.lastWallpaper) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Qt.rgba(0, 0, 0, 0.45)
                    visible: ThemeState.applying

                    Text {
                        anchors.centerIn: parent
                        text: "Applying..."
                        color: "white"
                        font.pixelSize: UIScale.fontSmall
                        font.weight: Font.Medium
                    }
                }
            }

            Text {
                text: "Color Palette"
                color: Colors.text
                font.pixelSize: UIScale.fontLead
                font.weight: Font.DemiBold
                Layout.bottomMargin: Math.round(16 * UIScale.value)
            }

            PaletteRow {
                Layout.fillWidth: true
                rowLabel: "Dark"
                swatches: root._darkSwatches
            }
            PaletteRow {
                Layout.fillWidth: true
                Layout.topMargin: UIScale.radiusMd
                rowLabel: "Light"
                swatches: root._lightSwatches
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
