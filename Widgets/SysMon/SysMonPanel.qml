pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../Shared"
import "../../"

Item {
    id: root

    Component.onCompleted: SysMonService.panelOpen = true
    Component.onDestruction: SysMonService.panelOpen = false

    property int activeTab: SysMonService.activeTab
    property int selectedCard: 0

    function procColor(name) {
        var h = 5381;
        for (var i = 0; i < name.length; i++)
            h = ((h << 5) + h ^ name.charCodeAt(i)) >>> 0;
        return Qt.hsla((h % 360) / 360, 0.68, 0.58, 1.0);
    }

    function fmtBytes(n) {
        if (n >= 1073741824)
            return (n / 1073741824).toFixed(1) + "G";
        if (n >= 1048576)
            return Math.round(n / 1048576) + "M";
        if (n >= 1024)
            return Math.round(n / 1024) + "K";
        return n + "B";
    }

    function fmtRate(n) {
        return root.fmtBytes(n) + "/s";
    }

    function flattenDisk(devs) {
        var out = [];
        for (var i = 0; i < devs.length; i++) {
            out.push({
                name: devs[i].name,
                read: devs[i].read_bytes_per_sec,
                write: devs[i].write_bytes_per_sec,
                depth: 0
            });
            var parts = devs[i].partitions || [];
            for (var j = 0; j < parts.length; j++)
                out.push({
                    name: parts[j].name,
                    read: parts[j].read_bytes_per_sec,
                    write: parts[j].write_bytes_per_sec,
                    depth: 1
                });
        }
        return out;
    }

    readonly property var _cpu: SysMonService.cpu
    readonly property var _mem: SysMonService.memory
    readonly property var _gpus: SysMonService.gpu
    readonly property var _card: _gpus.length > root.selectedCard ? _gpus[root.selectedCard] : null
    readonly property var _net: SysMonService.net
    readonly property var _disk: root.flattenDisk(SysMonService.disk)

    readonly property var _cpuSegments: (_cpu.procs || []).map(p => ({
                color: root.procColor(p.name),
                value: p.cpu
            }))
    readonly property var _memSegments: (_mem.procs || []).map(p => ({
                color: root.procColor(p.name),
                value: p.rss
            }))
    readonly property var _gpuComputeSegments: {
        if (!_card)
            return [];
        return (_card.procs || []).filter(p => p.gfx_pct > 0).map(p => ({
                    color: root.procColor(p.name),
                    value: p.gfx_pct
                }));
    }
    readonly property var _gpuVramSegments: {
        if (!_card)
            return [];
        return (_card.procs || []).filter(p => p.vram_kib > 0).map(p => ({
                    color: root.procColor(p.name),
                    value: p.vram_kib * 1024
                }));
    }

    property int sortField: 2   // 0=pid  1=name  2=value
    property bool sortAsc: false

    function setSortField(f) {
        if (sortField === f)
            sortAsc = !sortAsc;
        else {
            sortField = f;
            sortAsc = f !== 2;
        }
    }

    function sortIndicator(f) {
        return sortField === f ? (sortAsc ? " ↑" : " ↓") : "";
    }

    readonly property var _sortedCpuProcs: {
        var arr = (root._cpu.procs || []).slice();
        arr.sort(function (a, b) {
            var v = root.sortField === 0 ? a.pid - b.pid : root.sortField === 1 ? (a.name < b.name ? -1 : a.name > b.name ? 1 : 0) : a.cpu - b.cpu;
            return root.sortAsc ? v : -v;
        });
        return arr;
    }

    readonly property var _sortedMemProcs: {
        var arr = (root._mem.procs || []).slice();
        arr.sort(function (a, b) {
            var v = root.sortField === 0 ? a.pid - b.pid : root.sortField === 1 ? (a.name < b.name ? -1 : a.name > b.name ? 1 : 0) : a.rss - b.rss;
            return root.sortAsc ? v : -v;
        });
        return arr;
    }

    readonly property var _sortedGpuProcs: {
        var arr = (root._card ? (root._card.procs || []) : []).slice();
        arr.sort(function (a, b) {
            var v = root.sortField === 0 ? a.pid - b.pid : root.sortField === 1 ? (a.name < b.name ? -1 : a.name > b.name ? 1 : 0) : a.vram_kib - b.vram_kib;
            return root.sortAsc ? v : -v;
        });
        return arr;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: "SETTINGS / SYSTEM MONITOR"
            title: "System Monitor"
        }

        // Tab bar
        Item {
            Layout.fillWidth: true
            implicitHeight: Math.round(48 * UIScale.value)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: UIScale.panelPad
                anchors.rightMargin: UIScale.panelPad
                spacing: Math.round(4 * UIScale.value)

                Repeater {
                    model: ["CPU", "Memory", "GPU", "Net", "Disk"]
                    delegate: Rectangle {
                        id: tab
                        required property string modelData
                        required property int index

                        property bool active: root.activeTab === tab.index

                        implicitHeight: Math.round(32 * UIScale.value)
                        implicitWidth: tabLabel.implicitWidth + Math.round(24 * UIScale.value)
                        radius: UIScale.radiusSm
                        color: tab.active ? Colors.withAlpha(Colors.accent, 0.15) : tabHover.hovered ? Colors.withAlpha(Colors.text, 0.06) : "transparent"
                        border.color: tab.active ? Colors.withAlpha(Colors.accent, 0.4) : "transparent"
                        border.width: 1
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        Text {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: tab.modelData
                            color: tab.active ? Colors.accent : Colors.textDim
                            font.pixelSize: UIScale.fontSmall
                            font.weight: tab.active ? Font.DemiBold : Font.Normal
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }
                        }

                        HoverHandler {
                            id: tabHover
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SysMonService.activeTab = tab.index
                        }
                    }
                }

                Rectangle {
                    id: settingsTab
                    property bool active: root.activeTab === 5
                    implicitHeight: Math.round(32 * UIScale.value)
                    implicitWidth: Math.round(32 * UIScale.value)
                    radius: UIScale.radiusSm
                    color: settingsTab.active ? Colors.withAlpha(Colors.accent, 0.15) : settingsHover.hovered ? Colors.withAlpha(Colors.text, 0.06) : "transparent"
                    border.color: settingsTab.active ? Colors.withAlpha(Colors.accent, 0.4) : "transparent"
                    border.width: 1
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: "Material Icons"
                        font.pixelSize: Math.round(16 * UIScale.value)
                        color: settingsTab.active ? Colors.accent : Colors.textDim
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }
                    }

                    HoverHandler {
                        id: settingsHover
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SysMonService.activeTab = 5
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Colors.withAlpha(Colors.text, 0.05)
            }
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: tabContent.implicitHeight
            clip: true
            flickableDirection: Flickable.VerticalFlick

            Item {
                id: tabContent
                width: flick.width
                implicitHeight: cpuTab.visible ? cpuTab.implicitHeight : memTab.visible ? memTab.implicitHeight : gpuTab.visible ? gpuTab.implicitHeight : netTab.visible ? netTab.implicitHeight : diskTab.visible ? diskTab.implicitHeight : settingsTabContent.implicitHeight

                // CPU
                ColumnLayout {
                    id: cpuTab
                    width: parent.width
                    visible: root.activeTab === 0
                    spacing: Math.round(6 * UIScale.value)

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        spacing: UIScale.spacingLg

                        DonutChart {
                            Layout.preferredWidth: Math.round(200 * UIScale.value)
                            Layout.preferredHeight: Math.round(200 * UIScale.value)
                            Layout.alignment: Qt.AlignTop
                            segments: root._cpuSegments
                            total: 100
                            centerText: root._cpu.percent ? root._cpu.percent.toFixed(0) + "%" : "0%"
                            subText: "load " + (root._cpu.load ? root._cpu.load.toFixed(2) : "0")
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: Math.round(6 * UIScale.value)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Item {
                                    implicitWidth: Math.round(16 * UIScale.value)
                                }

                                Text {
                                    Layout.preferredWidth: Math.round(50 * UIScale.value)
                                    text: "PID" + root.sortIndicator(0)
                                    color: root.sortField === 0 ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    font.family: "monospace"
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSortField(0)
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Name" + root.sortIndicator(1)
                                    color: root.sortField === 1 ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSortField(1)
                                    }
                                }

                                Text {
                                    text: "CPU%" + root.sortIndicator(2)
                                    color: root.sortField === 2 ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    font.family: "monospace"
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSortField(2)
                                    }
                                }
                            }

                            Repeater {
                                model: root._sortedCpuProcs.length === 0 ? 8 : 0
                                delegate: Item {
                                    id: cpuSkel
                                    required property int index
                                    Layout.fillWidth: true
                                    implicitHeight: Math.round(24 * UIScale.value)

                                    Rectangle {
                                        width: Math.round(8 * UIScale.value)
                                        height: Math.round(8 * UIScale.value)
                                        radius: Math.round(2 * UIScale.value)
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: Qt.rgba(1, 1, 1, 0.08)
                                    }
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.leftMargin: Math.round(16 * UIScale.value)
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width * (0.35 + (cpuSkel.index % 4) * 0.07)
                                        height: Math.round(8 * UIScale.value)
                                        radius: Math.round(3 * UIScale.value)
                                        color: Qt.rgba(1, 1, 1, 0.07)
                                    }
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.round(36 * UIScale.value)
                                        height: Math.round(8 * UIScale.value)
                                        radius: Math.round(3 * UIScale.value)
                                        color: Qt.rgba(1, 1, 1, 0.07)
                                    }
                                }
                            }

                            Repeater {
                                model: root._sortedCpuProcs
                                delegate: Item {
                                    id: cpuProcItem
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: Math.round(24 * UIScale.value)

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 0

                                        Rectangle {
                                            implicitWidth: Math.round(8 * UIScale.value)
                                            implicitHeight: Math.round(8 * UIScale.value)
                                            radius: Math.round(2 * UIScale.value)
                                            color: root.procColor(cpuProcItem.modelData.name)
                                        }
                                        Item {
                                            implicitWidth: Math.round(8 * UIScale.value)
                                        }
                                        Text {
                                            Layout.preferredWidth: Math.round(50 * UIScale.value)
                                            text: cpuProcItem.modelData.pid
                                            color: Colors.textDim
                                            font.pixelSize: UIScale.fontSmall
                                            font.family: "monospace"
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: cpuProcItem.modelData.name
                                            color: Colors.text
                                            font.pixelSize: UIScale.fontSmall
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: cpuProcItem.modelData.cpu.toFixed(1) + "%"
                                            color: Colors.textDim
                                            font.pixelSize: UIScale.fontSmall
                                            font.family: "monospace"
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }
                }

                // Memory
                ColumnLayout {
                    id: memTab
                    width: parent.width
                    visible: root.activeTab === 1
                    spacing: Math.round(6 * UIScale.value)

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        spacing: UIScale.spacingLg

                        ColumnLayout {
                            Layout.alignment: Qt.AlignTop
                            spacing: Math.round(8 * UIScale.value)

                            DonutChart {
                                Layout.preferredWidth: Math.round(200 * UIScale.value)
                                Layout.preferredHeight: Math.round(200 * UIScale.value)
                                segments: root._memSegments
                                total: root._mem.total_bytes
                                centerText: root.fmtBytes(root._mem.used_bytes)
                                subText: root.fmtBytes(root._mem.total_bytes)
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: root._mem.swap_total_bytes > 0
                                spacing: Math.round(6 * UIScale.value)

                                Text {
                                    text: "Swap"
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: Math.round(4 * UIScale.value)
                                    radius: Math.round(2 * UIScale.value)
                                    color: Colors.surface

                                    Rectangle {
                                        width: parent.width * (root._mem.swap_total_bytes > 0 ? root._mem.swap_used_bytes / root._mem.swap_total_bytes : 0)
                                        height: parent.height
                                        radius: parent.radius
                                        color: Colors.accent
                                        opacity: 0.6
                                    }
                                }

                                Text {
                                    text: root.fmtBytes(root._mem.swap_used_bytes) + " / " + root.fmtBytes(root._mem.swap_total_bytes)
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.family: "monospace"
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: Math.round(6 * UIScale.value)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Item {
                                    implicitWidth: Math.round(16 * UIScale.value)
                                }

                                Text {
                                    Layout.preferredWidth: Math.round(50 * UIScale.value)
                                    text: "PID" + root.sortIndicator(0)
                                    color: root.sortField === 0 ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    font.family: "monospace"
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSortField(0)
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Name" + root.sortIndicator(1)
                                    color: root.sortField === 1 ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSortField(1)
                                    }
                                }

                                Text {
                                    text: "Memory" + root.sortIndicator(2)
                                    color: root.sortField === 2 ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    font.family: "monospace"
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSortField(2)
                                    }
                                }
                            }

                            Repeater {
                                model: root._sortedMemProcs.length === 0 ? 8 : 0
                                delegate: Item {
                                    id: memSkel
                                    required property int index
                                    Layout.fillWidth: true
                                    implicitHeight: Math.round(24 * UIScale.value)

                                    Rectangle {
                                        width: Math.round(8 * UIScale.value)
                                        height: Math.round(8 * UIScale.value)
                                        radius: Math.round(2 * UIScale.value)
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: Qt.rgba(1, 1, 1, 0.08)
                                    }
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.leftMargin: Math.round(16 * UIScale.value)
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width * (0.35 + (memSkel.index % 4) * 0.07)
                                        height: Math.round(8 * UIScale.value)
                                        radius: Math.round(3 * UIScale.value)
                                        color: Qt.rgba(1, 1, 1, 0.07)
                                    }
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.round(36 * UIScale.value)
                                        height: Math.round(8 * UIScale.value)
                                        radius: Math.round(3 * UIScale.value)
                                        color: Qt.rgba(1, 1, 1, 0.07)
                                    }
                                }
                            }

                            Repeater {
                                model: root._sortedMemProcs
                                delegate: Item {
                                    id: memProcItem
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: Math.round(24 * UIScale.value)

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 0

                                        Rectangle {
                                            implicitWidth: Math.round(8 * UIScale.value)
                                            implicitHeight: Math.round(8 * UIScale.value)
                                            radius: Math.round(2 * UIScale.value)
                                            color: root.procColor(memProcItem.modelData.name)
                                        }
                                        Item {
                                            implicitWidth: Math.round(8 * UIScale.value)
                                        }
                                        Text {
                                            Layout.preferredWidth: Math.round(50 * UIScale.value)
                                            text: memProcItem.modelData.pid
                                            color: Colors.textDim
                                            font.pixelSize: UIScale.fontSmall
                                            font.family: "monospace"
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: memProcItem.modelData.name
                                            color: Colors.text
                                            font.pixelSize: UIScale.fontSmall
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: root.fmtBytes(memProcItem.modelData.rss)
                                            color: Colors.textDim
                                            font.pixelSize: UIScale.fontSmall
                                            font.family: "monospace"
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }
                }

                // GPU
                ColumnLayout {
                    id: gpuTab
                    width: parent.width
                    visible: root.activeTab === 2
                    spacing: Math.round(8 * UIScale.value)

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        spacing: Math.round(6 * UIScale.value)
                        visible: root._gpus.length > 1

                        Repeater {
                            model: root._gpus
                            delegate: Rectangle {
                                id: chip
                                required property var modelData
                                required property int index

                                property bool active: root.selectedCard === chip.index

                                height: Math.round(28 * UIScale.value)
                                width: chipLabel.implicitWidth + Math.round(16 * UIScale.value)
                                radius: UIScale.radiusSm
                                color: chip.active ? Colors.withAlpha(Colors.accent, 0.15) : chipHover.hovered ? Colors.withAlpha(Colors.text, 0.06) : "transparent"
                                border.color: chip.active ? Colors.withAlpha(Colors.accent, 0.4) : "transparent"
                                border.width: 1
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Anim.fast
                                    }
                                }

                                Text {
                                    id: chipLabel
                                    anchors.centerIn: parent
                                    text: chip.modelData.card
                                    color: chip.active ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {
                                    id: chipHover
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectedCard = chip.index
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        spacing: UIScale.spacingLg

                        ColumnLayout {
                            Layout.alignment: Qt.AlignTop
                            spacing: Math.round(4 * UIScale.value)

                            DonutChart {
                                Layout.preferredWidth: Math.round(180 * UIScale.value)
                                Layout.preferredHeight: Math.round(180 * UIScale.value)
                                segments: root._gpuComputeSegments
                                total: 100
                                centerText: root._card ? root._card.busy + "%" : "0%"
                                subText: root._card ? root._card.temp_c.toFixed(0) + "°C · " + root._card.power_w.toFixed(0) + "W" : ""
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Compute"
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontCaption
                                font.weight: Font.Medium
                            }
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignTop
                            spacing: Math.round(4 * UIScale.value)

                            DonutChart {
                                Layout.preferredWidth: Math.round(180 * UIScale.value)
                                Layout.preferredHeight: Math.round(180 * UIScale.value)
                                segments: root._gpuVramSegments
                                total: root._card ? root._card.vram_total : 1
                                centerText: root._card ? root.fmtBytes(root._card.vram_used) : "0"
                                subText: root._card ? root.fmtBytes(root._card.vram_total) : ""
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "VRAM"
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontCaption
                                font.weight: Font.Medium
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: Math.round(6 * UIScale.value)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Item {
                                    implicitWidth: Math.round(16 * UIScale.value)
                                }

                                Text {
                                    Layout.preferredWidth: Math.round(50 * UIScale.value)
                                    text: "PID" + root.sortIndicator(0)
                                    color: root.sortField === 0 ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    font.family: "monospace"
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSortField(0)
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Name" + root.sortIndicator(1)
                                    color: root.sortField === 1 ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSortField(1)
                                    }
                                }

                                Text {
                                    Layout.preferredWidth: Math.round(52 * UIScale.value)
                                    text: "GFX%"
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    font.family: "monospace"
                                }

                                Text {
                                    text: "VRAM" + root.sortIndicator(2)
                                    color: root.sortField === 2 ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.weight: Font.Medium
                                    font.family: "monospace"
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSortField(2)
                                    }
                                }
                            }

                            Repeater {
                                model: root._sortedGpuProcs.length === 0 ? 8 : 0
                                delegate: Item {
                                    id: gpuSkel
                                    required property int index
                                    Layout.fillWidth: true
                                    implicitHeight: Math.round(24 * UIScale.value)

                                    Rectangle {
                                        width: Math.round(8 * UIScale.value)
                                        height: Math.round(8 * UIScale.value)
                                        radius: Math.round(2 * UIScale.value)
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: Qt.rgba(1, 1, 1, 0.08)
                                    }
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.leftMargin: Math.round(16 * UIScale.value)
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width * (0.35 + (gpuSkel.index % 4) * 0.07)
                                        height: Math.round(8 * UIScale.value)
                                        radius: Math.round(3 * UIScale.value)
                                        color: Qt.rgba(1, 1, 1, 0.07)
                                    }
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.round(36 * UIScale.value)
                                        height: Math.round(8 * UIScale.value)
                                        radius: Math.round(3 * UIScale.value)
                                        color: Qt.rgba(1, 1, 1, 0.07)
                                    }
                                }
                            }

                            Repeater {
                                model: root._sortedGpuProcs
                                delegate: Item {
                                    id: gpuProcItem
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: Math.round(24 * UIScale.value)

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 0

                                        Rectangle {
                                            implicitWidth: Math.round(8 * UIScale.value)
                                            implicitHeight: Math.round(8 * UIScale.value)
                                            radius: Math.round(2 * UIScale.value)
                                            color: root.procColor(gpuProcItem.modelData.name)
                                        }
                                        Item {
                                            implicitWidth: Math.round(8 * UIScale.value)
                                        }
                                        Text {
                                            Layout.preferredWidth: Math.round(50 * UIScale.value)
                                            text: gpuProcItem.modelData.pid
                                            color: Colors.textDim
                                            font.pixelSize: UIScale.fontSmall
                                            font.family: "monospace"
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: gpuProcItem.modelData.name
                                            color: Colors.text
                                            font.pixelSize: UIScale.fontSmall
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.preferredWidth: Math.round(52 * UIScale.value)
                                            text: gpuProcItem.modelData.gfx_pct > 0 ? gpuProcItem.modelData.gfx_pct.toFixed(1) + "%" : ""
                                            color: Colors.textDim
                                            font.pixelSize: UIScale.fontSmall
                                            font.family: "monospace"
                                        }
                                        Text {
                                            text: root.fmtBytes(gpuProcItem.modelData.vram_kib * 1024)
                                            color: Colors.textDim
                                            font.pixelSize: UIScale.fontSmall
                                            font.family: "monospace"
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                visible: root._gpus.length === 0
                                text: "No GPU detected"
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }
                        }
                    }

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }
                }

                // Network
                ColumnLayout {
                    id: netTab
                    width: parent.width
                    visible: root.activeTab === 3
                    spacing: Math.round(8 * UIScale.value)

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        spacing: UIScale.spacingSm

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(64 * UIScale.value)
                            radius: UIScale.radiusMd
                            color: Colors.surface

                            Column {
                                anchors.centerIn: parent
                                spacing: Math.round(2 * UIScale.value)

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.fmtRate(root._net.reduce((a, i) => a + i.rx_bytes_per_sec, 0))
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontHero
                                    font.weight: Font.Bold
                                    font.family: "monospace"
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "↓ Download"
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(64 * UIScale.value)
                            radius: UIScale.radiusMd
                            color: Colors.surface

                            Column {
                                anchors.centerIn: parent
                                spacing: Math.round(2 * UIScale.value)

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.fmtRate(root._net.reduce((a, i) => a + i.tx_bytes_per_sec, 0))
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontHero
                                    font.weight: Font.Bold
                                    font.family: "monospace"
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "↑ Upload"
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                }
                            }
                        }
                    }

                    SectionLabel {
                        text: "INTERFACES"
                        Layout.leftMargin: UIScale.panelPad + UIScale.spacingXs
                        visible: root._net.length > 0
                    }

                    Repeater {
                        model: root._net
                        delegate: Rectangle {
                            id: netItem
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.leftMargin: UIScale.panelPad
                            Layout.rightMargin: UIScale.panelPad
                            implicitHeight: Math.round(44 * UIScale.value)
                            radius: UIScale.radiusMd
                            color: Colors.surface

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: UIScale.spacingMd
                                anchors.rightMargin: UIScale.spacingMd

                                Text {
                                    text: netItem.modelData.name
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontSmall
                                    font.weight: Font.DemiBold
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: "↓ " + root.fmtRate(netItem.modelData.rx_bytes_per_sec)
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                    font.family: "monospace"
                                }

                                Text {
                                    text: "↑ " + root.fmtRate(netItem.modelData.tx_bytes_per_sec)
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                    font.family: "monospace"
                                    Layout.leftMargin: UIScale.spacingMd
                                }
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        visible: root._net.length === 0
                        text: "No interfaces"
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontSmall
                    }

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }
                }

                // Disk
                ColumnLayout {
                    id: diskTab
                    width: parent.width
                    visible: root.activeTab === 4
                    spacing: Math.round(8 * UIScale.value)

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        spacing: UIScale.spacingSm

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(64 * UIScale.value)
                            radius: UIScale.radiusMd
                            color: Colors.surface

                            Column {
                                anchors.centerIn: parent
                                spacing: Math.round(2 * UIScale.value)

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.fmtRate(SysMonService.disk.reduce((a, d) => a + d.read_bytes_per_sec, 0))
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontHero
                                    font.weight: Font.Bold
                                    font.family: "monospace"
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "R Read"
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(64 * UIScale.value)
                            radius: UIScale.radiusMd
                            color: Colors.surface

                            Column {
                                anchors.centerIn: parent
                                spacing: Math.round(2 * UIScale.value)

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.fmtRate(SysMonService.disk.reduce((a, d) => a + d.write_bytes_per_sec, 0))
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontHero
                                    font.weight: Font.Bold
                                    font.family: "monospace"
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "W Write"
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                }
                            }
                        }
                    }

                    SectionLabel {
                        text: "DEVICES"
                        Layout.leftMargin: UIScale.panelPad + UIScale.spacingXs
                        visible: root._disk.length > 0
                    }

                    Repeater {
                        model: root._disk
                        delegate: Rectangle {
                            id: diskItem
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.leftMargin: UIScale.panelPad + diskItem.modelData.depth * Math.round(16 * UIScale.value)
                            Layout.rightMargin: UIScale.panelPad
                            implicitHeight: Math.round(44 * UIScale.value)
                            radius: UIScale.radiusMd
                            color: diskItem.modelData.depth > 0 ? Colors.withAlpha(Colors.surface, 0.6) : Colors.surface

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: UIScale.spacingMd
                                anchors.rightMargin: UIScale.spacingMd

                                Text {
                                    text: (diskItem.modelData.depth > 0 ? "↳ " : "") + diskItem.modelData.name
                                    color: diskItem.modelData.depth > 0 ? Colors.textDim : Colors.text
                                    font.pixelSize: UIScale.fontSmall
                                    font.weight: diskItem.modelData.depth > 0 ? Font.Normal : Font.DemiBold
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: "R " + root.fmtRate(diskItem.modelData.read)
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                    font.family: "monospace"
                                }

                                Text {
                                    text: "W " + root.fmtRate(diskItem.modelData.write)
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                    font.family: "monospace"
                                    Layout.leftMargin: UIScale.spacingMd
                                }
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        visible: root._disk.length === 0
                        text: "No disks"
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontSmall
                    }

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }
                }

                // Settings
                ColumnLayout {
                    id: settingsTabContent
                    width: parent.width
                    visible: root.activeTab === 5
                    spacing: UIScale.spacingMd

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }

                    SectionLabel {
                        text: "PULL RATE"
                        Layout.leftMargin: UIScale.panelPad + UIScale.spacingXs
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        spacing: UIScale.spacingSm

                        Repeater {
                            model: [
                                {
                                    label: "0.5s",
                                    ms: 500
                                },
                                {
                                    label: "1s",
                                    ms: 1000
                                },
                                {
                                    label: "2s",
                                    ms: 2000
                                },
                                {
                                    label: "5s",
                                    ms: 5000
                                }
                            ]
                            delegate: Rectangle {
                                id: rateBtn
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: Math.round(40 * UIScale.value)
                                radius: UIScale.radiusMd
                                property bool selected: SysMonService.pullRateMs === rateBtn.modelData.ms
                                color: rateBtn.selected ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surface
                                border.color: rateBtn.selected ? Colors.withAlpha(Colors.accent, 0.4) : "transparent"
                                border.width: 1
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Anim.fast
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: rateBtn.modelData.label
                                    color: rateBtn.selected ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                    font.weight: rateBtn.selected ? Font.DemiBold : Font.Normal
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: SysMonService.pullRateMs = rateBtn.modelData.ms
                                }
                            }
                        }
                    }

                    SectionLabel {
                        text: "PROCESS LIMIT"
                        Layout.leftMargin: UIScale.panelPad + UIScale.spacingXs
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        spacing: UIScale.spacingSm

                        Repeater {
                            model: [
                                {
                                    label: "5",
                                    n: 5
                                },
                                {
                                    label: "10",
                                    n: 10
                                },
                                {
                                    label: "20",
                                    n: 20
                                },
                                {
                                    label: "50",
                                    n: 50
                                },
                                {
                                    label: "∞",
                                    n: 0
                                }
                            ]
                            delegate: Rectangle {
                                id: limitBtn
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: Math.round(40 * UIScale.value)
                                radius: UIScale.radiusMd
                                property bool selected: SysMonService.procLimit === limitBtn.modelData.n
                                color: limitBtn.selected ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surface
                                border.color: limitBtn.selected ? Colors.withAlpha(Colors.accent, 0.4) : "transparent"
                                border.width: 1
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Anim.fast
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: limitBtn.modelData.label
                                    color: limitBtn.selected ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                    font.weight: limitBtn.selected ? Font.DemiBold : Font.Normal
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: SysMonService.procLimit = limitBtn.modelData.n
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad

                        Text {
                            text: "Hide idle processes"
                            color: Colors.text
                            font.pixelSize: UIScale.fontSmall
                            Layout.fillWidth: true
                        }

                        ToggleSwitch {
                            checked: SysMonService.filterZero
                            onToggled: SysMonService.filterZero = !SysMonService.filterZero
                        }
                    }

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }
                }
            }
        }
    }
}
