pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import "../About"
import "../AppSwitcher"
import "../Bluetooth"
import "../Calendar"
import "../Clock"
import "../WorkspaceIndicator"
import "../Display"
import "../Network"
import "../Notifications"
import "../Sound"
import "../SysMon"
import "../ThemeSwitcher"
import "../NixPurity"
import "../Wifi"
import "../../"

Item {
    id: root
    focus: true

    Keys.onEscapePressed: HomePanelService.open = false

    property string section: "network"

    property bool _panelOpen: HomePanelService.open
    on_PanelOpenChanged: {
        if (_panelOpen && HomePanelService.requestedSection !== "") {
            root.section = HomePanelService.requestedSection;
            HomePanelService.requestedSection = "";
        }
    }
    property string searchText: ""
    property string _hostname: ""

    Process {
        command: ["hostname"]
        running: true
        stdout: SplitParser {
            onRead: data => root._hostname = data.trim()
        }
    }

    readonly property bool panelOpen: HomePanelService.open
    onPanelOpenChanged: if (!panelOpen)
        searchInput.text = ""

    component NavItem: Rectangle {
        id: navItem
        property string navId: ""
        property string navLabel: ""
        property string navIcon: ""
        property bool isNavSelected: false

        implicitHeight: Math.round(38 * UIScale.value)
        radius: UIScale.radiusMd
        color: isNavSelected ? Colors.withAlpha(Colors.accent, 0.15) : (navHover.hovered ? Colors.withAlpha(Colors.text, 0.06) : "transparent")
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }

        Rectangle {
            visible: navItem.isNavSelected
            width: Math.round(3 * UIScale.value)
            radius: Math.round(2 * UIScale.value)
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: Math.round(7 * UIScale.value)
            anchors.bottomMargin: Math.round(7 * UIScale.value)
            color: Colors.accent
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: UIScale.radiusMd
            anchors.rightMargin: UIScale.spacingSm
            spacing: UIScale.spacingSm

            Text {
                text: navItem.navIcon
                font.family: "Material Icons"
                font.pixelSize: Math.round(18 * UIScale.value)
                color: navItem.isNavSelected ? Colors.accent : Colors.textDim
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
            }
            Text {
                text: navItem.navLabel
                color: navItem.isNavSelected ? Colors.text : Colors.textDim
                font.pixelSize: UIScale.fontLead
                font.weight: navItem.isNavSelected ? Font.DemiBold : Font.Normal
                Layout.fillWidth: true
                elide: Text.ElideRight
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
            }
        }

        HoverHandler {
            id: navHover
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.section = navItem.navId
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Math.round(16 * UIScale.value)
        color: Colors.bg
        border.color: Colors.withAlpha(Colors.outline, 0.6)
        border.width: 1

        MouseArea {
            anchors.fill: parent
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar
        Item {
            Layout.preferredWidth: Math.round(220 * UIScale.value)
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                topLeftRadius: Math.round(16 * UIScale.value)
                bottomLeftRadius: Math.round(16 * UIScale.value)
                color: Colors.withAlpha(Colors.surface, 0.6)

                MouseArea {
                    anchors.fill: parent
                }
            }

            Rectangle {
                id: sidebarDivider
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: 1
                color: Colors.withAlpha(Colors.outline, 0.5)
            }

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: sidebarDivider.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: UIScale.spacingMd
                spacing: 0

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: UIScale.spacingMd
                    Layout.topMargin: UIScale.spacingXs
                    spacing: UIScale.spacingSm

                    Rectangle {
                        implicitWidth: Math.round(34 * UIScale.value)
                        implicitHeight: Math.round(34 * UIScale.value)
                        radius: UIScale.spacingSm
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: Qt.lighter(Colors.accent, 1.1)
                            }
                            GradientStop {
                                position: 1
                                color: Qt.darker(Colors.accent, 1.4)
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.family: "Material Icons"
                            font.pixelSize: Math.round(18 * UIScale.value)
                            color: Colors.bg
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "Settings"
                            color: Colors.text
                            font.pixelSize: UIScale.fontSubhead
                            font.weight: Font.ExtraBold
                        }
                        Text {
                            text: "zesis"
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontCaption
                            font.family: "monospace"
                        }
                    }

                    Rectangle {
                        implicitWidth: Math.round(30 * UIScale.value)
                        implicitHeight: Math.round(30 * UIScale.value)
                        radius: UIScale.radiusMd
                        color: closeHover.hovered ? Colors.withAlpha(Colors.text, 0.08) : "transparent"
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: Math.round(14 * UIScale.value)
                            color: closeHover.hovered ? Colors.text : Colors.textDim
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }
                        }

                        HoverHandler {
                            id: closeHover
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: HomePanelService.open = false
                        }
                    }
                }

                // Search bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.bottomMargin: UIScale.radiusMd
                    implicitHeight: Math.round(32 * UIScale.value)
                    radius: Math.round(9 * UIScale.value)
                    color: searchInput.activeFocus ? Colors.withAlpha(Colors.accent, 0.08) : Colors.withAlpha(Colors.text, 0.04)
                    border.color: searchInput.activeFocus ? Colors.withAlpha(Colors.accent, 0.4) : Colors.withAlpha(Colors.text, 0.06)
                    border.width: 1
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                    Behavior on border.color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: searchInput.forceActiveFocus()
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: UIScale.spacingSm
                        anchors.rightMargin: UIScale.spacingSm
                        spacing: Math.round(7 * UIScale.value)

                        Text {
                            text: ""
                            font.family: "Material Icons"
                            font.pixelSize: UIScale.fontLead
                            color: searchInput.activeFocus ? Colors.accent : Colors.muted
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: Math.round(20 * UIScale.value)

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                visible: searchInput.text === ""
                                text: "Search settings"
                                color: Colors.muted
                                font.pixelSize: UIScale.fontBody
                            }

                            TextInput {
                                id: searchInput
                                anchors.fill: parent
                                verticalAlignment: TextInput.AlignVCenter
                                color: Colors.text
                                font.pixelSize: UIScale.fontBody
                                clip: true
                                onTextChanged: root.searchText = text
                                Keys.onEscapePressed: {
                                    if (text !== "")
                                        text = "";
                                    else
                                        HomePanelService.open = false;
                                }
                            }
                        }

                        Text {
                            visible: root.searchText !== ""
                            text: ""
                            font.family: "Material Icons"
                            font.pixelSize: UIScale.fontLead
                            color: Colors.muted
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: searchInput.text = ""
                            }
                        }
                    }
                }

                // Scrollable nav list
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: navColumn.implicitHeight
                    clip: true
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    ColumnLayout {
                        id: navColumn
                        width: parent.width
                        spacing: 0

                        // WIDGETS section
                        Text {
                            text: "WIDGETS"
                            color: Colors.muted
                            font.pixelSize: UIScale.fontTiny
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5
                            leftPadding: UIScale.spacingSm
                            Layout.bottomMargin: UIScale.spacingXs
                            visible: root.searchText === "" || ["wallpaper", "sound", "notifications", "display & scale", "app switcher"].some(s => s.includes(root.searchText.toLowerCase()))
                        }

                        NavItem {
                            navId: "wallpaper"
                            navLabel: "Wallpaper"
                            navIcon: ""
                            isNavSelected: root.section === "wallpaper"
                            visible: root.searchText === "" || "wallpaper".includes(root.searchText.toLowerCase())
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            navId: "sound"
                            navLabel: "Sound"
                            navIcon: ""
                            isNavSelected: root.section === "sound"
                            visible: root.searchText === "" || "sound".includes(root.searchText.toLowerCase())
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            navId: "appswitcher"
                            navLabel: "App Switcher"
                            navIcon: ""
                            isNavSelected: root.section === "appswitcher"
                            visible: root.searchText === "" || "app switcher".includes(root.searchText.toLowerCase())
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            navId: "workspace"
                            navLabel: "Workspace"
                            navIcon: ""
                            isNavSelected: root.section === "workspace"
                            visible: root.searchText === "" || "workspace".includes(root.searchText.toLowerCase())
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            navId: "notifs"
                            navLabel: "Notifications"
                            navIcon: ""
                            isNavSelected: root.section === "notifs"
                            visible: root.searchText === "" || "notifications".includes(root.searchText.toLowerCase())
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            navId: "display"
                            navLabel: "Display & Scale"
                            navIcon: ""
                            isNavSelected: root.section === "display"
                            visible: root.searchText === "" || "display & scale".includes(root.searchText.toLowerCase())
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }

                        NavItem {
                            navId: "clock"
                            navLabel: "Clock"
                            navIcon: ""
                            isNavSelected: root.section === "clock"
                            visible: root.searchText === "" || "clock".includes(root.searchText.toLowerCase())
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            navId: "calendar"
                            navLabel: "Calendar"
                            navIcon: "󰺻"
                            isNavSelected: root.section === "calendar"
                            visible: root.searchText === "" || "calendar".includes(root.searchText.toLowerCase())
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }

                        // SYSTEM section
                        Text {
                            text: "SYSTEM"
                            color: Colors.muted
                            font.pixelSize: UIScale.fontTiny
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5
                            leftPadding: UIScale.spacingSm
                            Layout.topMargin: UIScale.radiusMd
                            Layout.bottomMargin: UIScale.spacingXs
                            visible: root.searchText === "" || ["bluetooth", "wi-fi", "network", "system monitor", "about"].concat(NixPurityService.isNixOS ? ["nix purity"] : []).some(s => s.includes(root.searchText.toLowerCase()))
                        }

                        NavItem {
                            navId: "bluetooth"
                            navLabel: "Bluetooth"
                            navIcon: "󰂯"
                            isNavSelected: root.section === "bluetooth"
                            visible: BluetoothService.available && (root.searchText === "" || "bluetooth".includes(root.searchText.toLowerCase()))
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            navId: "wifi"
                            navLabel: "Wi-Fi"
                            navIcon: "󰤨"
                            isNavSelected: root.section === "wifi"
                            visible: WifiService.available && (root.searchText === "" || "wi-fi".includes(root.searchText.toLowerCase()))
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            navId: "network"
                            navLabel: "Network"
                            navIcon: ""
                            isNavSelected: root.section === "network"
                            visible: root.searchText === "" || "network".includes(root.searchText.toLowerCase())
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            navId: "sysmon"
                            navLabel: "System Monitor"
                            navIcon: ""
                            isNavSelected: root.section === "sysmon"
                            visible: root.searchText === "" || "system monitor".includes(root.searchText.toLowerCase())
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            navId: "nixpurity"
                            navLabel: "Nix Purity"
                            navIcon: "󱄅"
                            isNavSelected: root.section === "nixpurity"
                            visible: NixPurityService.isNixOS && (root.searchText === "" || "nix purity".includes(root.searchText.toLowerCase()))
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            navId: "about"
                            navLabel: "About"
                            navIcon: ""
                            isNavSelected: root.section === "about"
                            visible: root.searchText === "" || "about".includes(root.searchText.toLowerCase())
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                    } // ColumnLayout navColumn
                } // Flickable

                // Machine footer
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: UIScale.spacingSm
                    implicitHeight: Math.round(46 * UIScale.value)
                    radius: UIScale.spacingSm
                    color: Colors.withAlpha(Colors.text, 0.03)
                    border.color: Colors.withAlpha(Colors.text, 0.05)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: UIScale.spacingSm
                        anchors.rightMargin: UIScale.spacingSm
                        spacing: UIScale.spacingSm

                        Rectangle {
                            implicitWidth: Math.round(30 * UIScale.value)
                            implicitHeight: Math.round(30 * UIScale.value)
                            radius: Math.round(9 * UIScale.value)
                            color: Colors.withAlpha(Colors.text, 0.1)

                            Text {
                                anchors.centerIn: parent
                                text: root._hostname.charAt(0).toUpperCase()
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontBody
                                font.weight: Font.Bold
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: root._hostname
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.Bold
                            }
                            Text {
                                text: "local"
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                                font.family: "monospace"
                            }
                        }
                    }
                }
            }
        }

        // Content area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Loader {
                anchors.fill: parent
                sourceComponent: {
                    if (root.section === "bluetooth")
                        return bluetoothPanelComp;
                    if (root.section === "wifi")
                        return wifiPanelComp;
                    if (root.section === "network")
                        return networkExpandedComp;
                    if (root.section === "wallpaper")
                        return wallpaperPanelComp;
                    if (root.section === "sound")
                        return soundComp;
                    if (root.section === "appswitcher")
                        return appSwitcherPanelComp;
                    if (root.section === "workspace")
                        return workspacePanelComp;
                    if (root.section === "display")
                        return displayPanelComp;
                    if (root.section === "sysmon")
                        return sysMonPanelComp;
                    if (root.section === "nixpurity")
                        return nixPurityComp;
                    if (root.section === "about")
                        return aboutComp;
                    if (root.section === "notifs")
                        return notifHistComp;
                    if (root.section === "clock")
                        return clockPanelComp;
                    if (root.section === "calendar")
                        return calendarPanelComp;
                    return placeholderComp;
                }
            }

            Component {
                id: bluetoothPanelComp
                BluetoothPanel {}
            }
            Component {
                id: wifiPanelComp
                WifiPanel {}
            }
            Component {
                id: networkExpandedComp
                NetworkPanel {}
            }
            Component {
                id: wallpaperPanelComp
                WallpaperPanel {}
            }
            Component {
                id: soundComp
                Sound {}
            }
            Component {
                id: appSwitcherPanelComp
                AppSwitcherPanel {}
            }
            Component {
                id: workspacePanelComp
                WorkspaceIndicatorPanel {}
            }
            Component {
                id: displayPanelComp
                DisplayPanel {}
            }

            Component {
                id: sysMonPanelComp
                SysMonPanel {}
            }
            Component {
                id: nixPurityComp
                NixPurity {}
            }
            Component {
                id: aboutComp
                About {}
            }
            Component {
                id: clockPanelComp
                ClockPanel {}
            }
            Component {
                id: calendarPanelComp
                CalendarPanel {}
            }

            Component {
                id: notifHistComp
                NotifHistory {}
            }

            Component {
                id: placeholderComp
                Item {
                    Text {
                        anchors.centerIn: parent
                        text: "Coming soon"
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontLead
                    }
                }
            }
        }
    }
}
