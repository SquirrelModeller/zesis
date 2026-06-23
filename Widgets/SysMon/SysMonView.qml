pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../Shared"
import "../../"

Item {
    id: root

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
    readonly property var _disk: {
        return root.flattenDisk(SysMonService.disk);
    }

    readonly property var _cpuSegments: {
        return (_cpu.procs || []).map(p => ({
                    color: root.procColor(p.name),
                    value: p.cpu
                }));
    }
    readonly property var _memSegments: {
        return (_mem.procs || []).map(p => ({
                    color: root.procColor(p.name),
                    value: p.rss
                }));
    }
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

    Rectangle {
        anchors.fill: parent
        radius: Math.round(12 * UIScale.value)
        color: Colors.bg
        border.color: Colors.outline
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.round(16 * UIScale.value)
        spacing: Math.round(10 * UIScale.value)

        // Tab bar
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Math.round(4 * UIScale.value)

            Repeater {
                model: ["CPU", "Memory", "GPU", "Net", "Disk"]
                delegate: Rectangle {
                    id: tab
                    required property string modelData
                    required property int index

                    property bool active: root.activeTab === tab.index

                    implicitHeight: Math.round(30 * UIScale.value)
                    implicitWidth: tabLabel.implicitWidth + Math.round(20 * UIScale.value)
                    radius: Math.round(8 * UIScale.value)
                    color: tab.active ? Colors.surface : tabMouseArea.containsMouse ? Colors.withAlpha(Colors.surface, 0.6) : "transparent"
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }

                    Text {
                        id: tabLabel
                        anchors.centerIn: parent
                        text: tab.modelData
                        color: tab.active ? Colors.text : Colors.textDim
                        font.pixelSize: UIScale.fontSmall
                        font.weight: tab.active ? Font.DemiBold : Font.Normal
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }
                    }

                    MouseArea {
                        id: tabMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SysMonService.activeTab = tab.index
                    }
                }
            }

            Rectangle {
                id: settingsTab
                property bool active: root.activeTab === 5
                implicitHeight: Math.round(30 * UIScale.value)
                implicitWidth: Math.round(30 * UIScale.value)
                radius: Math.round(8 * UIScale.value)
                color: settingsTab.active ? Colors.surface : settingsHover.containsMouse ? Colors.withAlpha(Colors.surface, 0.6) : "transparent"
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

                MouseArea {
                    id: settingsHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SysMonService.activeTab = 5
                }
            }
        }

        // CPU
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Math.round(6 * UIScale.value)
            visible: root.activeTab === 0

            DonutChart {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.round(170 * UIScale.value)
                Layout.preferredHeight: Math.round(170 * UIScale.value)
                segments: root._cpuSegments
                total: 100
                centerText: root._cpu.percent ? root._cpu.percent.toFixed(0) + "%" : "0%"
                subText: "load " + (root._cpu.load ? root._cpu.load.toFixed(2) : "0")
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "CPU"
                color: Colors.textDim
                font.pixelSize: UIScale.fontCaption
                font.weight: Font.Medium
            }

            Item {
                Layout.preferredHeight: Math.round(4 * UIScale.value)
            }

            Repeater {
                model: (root._cpu.procs || []).length === 0 ? 8 : 0
                delegate: Item {
                    id: cpuSkel
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: Math.round(20 * UIScale.value)

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
                model: root._cpu.procs || []
                delegate: Item {
                    id: procItem
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: Math.round(20 * UIScale.value)

                    Rectangle {
                        id: dot
                        width: Math.round(8 * UIScale.value)
                        height: Math.round(8 * UIScale.value)
                        radius: Math.round(2 * UIScale.value)
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.procColor(procItem.modelData.name)
                    }

                    Text {
                        anchors.left: dot.right
                        anchors.leftMargin: Math.round(8 * UIScale.value)
                        anchors.right: val.left
                        anchors.rightMargin: Math.round(8 * UIScale.value)
                        anchors.verticalCenter: parent.verticalCenter
                        text: procItem.modelData.name
                        color: Colors.text
                        font.pixelSize: UIScale.fontCaption
                        elide: Text.ElideRight
                    }

                    Text {
                        id: val
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: procItem.modelData.cpu.toFixed(1) + "%"
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                        font.family: "monospace"
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }

        // Memory
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Math.round(6 * UIScale.value)
            visible: root.activeTab === 1

            DonutChart {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.round(170 * UIScale.value)
                Layout.preferredHeight: Math.round(170 * UIScale.value)
                segments: root._memSegments
                total: root._mem.total_bytes
                centerText: root.fmtBytes(root._mem.used_bytes)
                subText: root.fmtBytes(root._mem.total_bytes)
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Memory"
                color: Colors.textDim
                font.pixelSize: UIScale.fontCaption
                font.weight: Font.Medium
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

            Item {
                Layout.preferredHeight: Math.round(4 * UIScale.value)
            }

            Repeater {
                model: (root._mem.procs || []).length === 0 ? 8 : 0
                delegate: Item {
                    id: memSkel
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: Math.round(20 * UIScale.value)

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
                model: root._mem.procs || []
                delegate: Item {
                    id: memProcItem
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: Math.round(20 * UIScale.value)

                    Rectangle {
                        id: memDot
                        width: Math.round(8 * UIScale.value)
                        height: Math.round(8 * UIScale.value)
                        radius: Math.round(2 * UIScale.value)
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.procColor(memProcItem.modelData.name)
                    }

                    Text {
                        anchors.left: memDot.right
                        anchors.leftMargin: Math.round(8 * UIScale.value)
                        anchors.right: memVal.left
                        anchors.rightMargin: Math.round(8 * UIScale.value)
                        anchors.verticalCenter: parent.verticalCenter
                        text: memProcItem.modelData.name
                        color: Colors.text
                        font.pixelSize: UIScale.fontCaption
                        elide: Text.ElideRight
                    }

                    Text {
                        id: memVal
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.fmtBytes(memProcItem.modelData.rss)
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                        font.family: "monospace"
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }

        // GPU
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Math.round(6 * UIScale.value)
            visible: root.activeTab === 2

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: Math.round(6 * UIScale.value)
                visible: root._gpus.length > 1

                Repeater {
                    model: root._gpus
                    delegate: Rectangle {
                        id: chip
                        required property var modelData
                        required property int index

                        property bool active: root.selectedCard === chip.index

                        height: Math.round(24 * UIScale.value)
                        width: chipLabel.implicitWidth + Math.round(16 * UIScale.value)
                        radius: Math.round(6 * UIScale.value)
                        color: chip.active ? Colors.surface : chipMouseArea.containsMouse ? Colors.withAlpha(Colors.surface, 0.6) : "transparent"
                        border.color: chip.active ? Colors.outline : "transparent"
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
                            color: chip.active ? Colors.text : Colors.textDim
                            font.pixelSize: UIScale.fontCaption
                        }

                        MouseArea {
                            id: chipMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedCard = chip.index
                        }
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: UIScale.spacingLg

                ColumnLayout {
                    spacing: Math.round(4 * UIScale.value)

                    DonutChart {
                        Layout.preferredWidth: Math.round(140 * UIScale.value)
                        Layout.preferredHeight: Math.round(140 * UIScale.value)
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
                    spacing: Math.round(4 * UIScale.value)

                    DonutChart {
                        Layout.preferredWidth: Math.round(140 * UIScale.value)
                        Layout.preferredHeight: Math.round(140 * UIScale.value)
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
            }

            Item {
                Layout.preferredHeight: Math.round(4 * UIScale.value)
            }

            Repeater {
                model: (root._card && (root._card.procs || []).length === 0) ? 8 : 0
                delegate: Item {
                    id: gpuSkel
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: Math.round(20 * UIScale.value)

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
                model: root._card ? root._card.procs || [] : []
                delegate: Item {
                    id: gpuProcItem
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: Math.round(20 * UIScale.value)

                    Rectangle {
                        id: gpuDot
                        width: Math.round(8 * UIScale.value)
                        height: Math.round(8 * UIScale.value)
                        radius: Math.round(2 * UIScale.value)
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.procColor(gpuProcItem.modelData.name)
                    }

                    Text {
                        anchors.left: gpuDot.right
                        anchors.leftMargin: Math.round(8 * UIScale.value)
                        anchors.right: gfxVal.left
                        anchors.rightMargin: Math.round(8 * UIScale.value)
                        anchors.verticalCenter: parent.verticalCenter
                        text: gpuProcItem.modelData.name
                        color: Colors.text
                        font.pixelSize: UIScale.fontCaption
                        elide: Text.ElideRight
                    }

                    Text {
                        id: gfxVal
                        anchors.right: vramVal.left
                        anchors.rightMargin: Math.round(10 * UIScale.value)
                        anchors.verticalCenter: parent.verticalCenter
                        text: gpuProcItem.modelData.gfx_pct.toFixed(1) + "%"
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                        font.family: "monospace"
                        visible: gpuProcItem.modelData.gfx_pct > 0
                    }

                    Text {
                        id: vramVal
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.fmtBytes(gpuProcItem.modelData.vram_kib * 1024)
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                        font.family: "monospace"
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

            Item {
                Layout.fillHeight: true
            }
        }

        // Network
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Math.round(6 * UIScale.value)
            visible: root.activeTab === 3

            RowLayout {
                Layout.fillWidth: true
                spacing: UIScale.spacingSm

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(52 * UIScale.value)
                    radius: UIScale.radiusSm
                    color: Colors.surface

                    Column {
                        anchors.centerIn: parent
                        spacing: Math.round(2 * UIScale.value)

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.fmtRate(root._net.reduce((a, i) => a + i.rx_bytes_per_sec, 0))
                            color: Colors.text
                            font.pixelSize: UIScale.fontLead
                            font.weight: 600
                            font.family: "monospace"
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "↓ RX"
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontCaption
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(52 * UIScale.value)
                    radius: UIScale.radiusSm
                    color: Colors.surface

                    Column {
                        anchors.centerIn: parent
                        spacing: Math.round(2 * UIScale.value)

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.fmtRate(root._net.reduce((a, i) => a + i.tx_bytes_per_sec, 0))
                            color: Colors.text
                            font.pixelSize: UIScale.fontLead
                            font.weight: 600
                            font.family: "monospace"
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "↑ TX"
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontCaption
                        }
                    }
                }
            }

            Item {
                Layout.preferredHeight: Math.round(4 * UIScale.value)
            }

            Repeater {
                model: root._net
                delegate: Item {
                    id: netItem
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: Math.round(20 * UIScale.value)

                    Text {
                        id: ifaceName
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: netItem.modelData.name
                        color: Colors.text
                        font.pixelSize: UIScale.fontCaption
                        font.weight: Font.Medium
                    }

                    Text {
                        id: txVal
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "↑ " + root.fmtRate(netItem.modelData.tx_bytes_per_sec)
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                        font.family: "monospace"
                    }

                    Text {
                        anchors.right: txVal.left
                        anchors.rightMargin: Math.round(12 * UIScale.value)
                        anchors.verticalCenter: parent.verticalCenter
                        text: "↓ " + root.fmtRate(netItem.modelData.rx_bytes_per_sec)
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                        font.family: "monospace"
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
                Layout.fillHeight: true
            }
        }

        // Disk
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Math.round(6 * UIScale.value)
            visible: root.activeTab === 4

            RowLayout {
                Layout.fillWidth: true
                spacing: UIScale.spacingSm

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(52 * UIScale.value)
                    radius: UIScale.radiusSm
                    color: Colors.surface

                    Column {
                        anchors.centerIn: parent
                        spacing: Math.round(2 * UIScale.value)

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.fmtRate(SysMonService.disk.reduce((a, d) => a + d.read_bytes_per_sec, 0))
                            color: Colors.text
                            font.pixelSize: UIScale.fontLead
                            font.weight: 600
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
                    Layout.preferredHeight: Math.round(52 * UIScale.value)
                    radius: UIScale.radiusSm
                    color: Colors.surface

                    Column {
                        anchors.centerIn: parent
                        spacing: Math.round(2 * UIScale.value)

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.fmtRate(SysMonService.disk.reduce((a, d) => a + d.write_bytes_per_sec, 0))
                            color: Colors.text
                            font.pixelSize: UIScale.fontLead
                            font.weight: 600
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

            Item {
                Layout.preferredHeight: Math.round(4 * UIScale.value)
            }

            Repeater {
                model: root._disk
                delegate: Item {
                    id: diskItem
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: Math.round(20 * UIScale.value)

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: diskItem.modelData.depth * Math.round(14 * UIScale.value)
                        anchors.verticalCenter: parent.verticalCenter
                        text: (diskItem.modelData.depth > 0 ? "↳ " : "") + diskItem.modelData.name
                        color: diskItem.modelData.depth > 0 ? Colors.textDim : Colors.text
                        font.pixelSize: UIScale.fontCaption
                        font.weight: diskItem.modelData.depth > 0 ? Font.Normal : Font.Medium
                    }

                    Text {
                        id: writeVal
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "W " + root.fmtRate(diskItem.modelData.write)
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                        font.family: "monospace"
                    }

                    Text {
                        anchors.right: writeVal.left
                        anchors.rightMargin: Math.round(12 * UIScale.value)
                        anchors.verticalCenter: parent.verticalCenter
                        text: "R " + root.fmtRate(diskItem.modelData.read)
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                        font.family: "monospace"
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
                Layout.fillHeight: true
            }
        }

        // Settings
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Math.round(10 * UIScale.value)
            visible: root.activeTab === 5

            Text {
                text: "Pull rate"
                color: Colors.text
                font.pixelSize: UIScale.fontSmall
                font.weight: Font.Bold
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * UIScale.value)

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
                        implicitHeight: Math.round(32 * UIScale.value)
                        radius: UIScale.radiusSm
                        property bool selected: SysMonService.pullRateMs === rateBtn.modelData.ms
                        color: rateBtn.selected ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surfaceHigh
                        border.color: rateBtn.selected ? Colors.accent : "transparent"
                        border.width: 1
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: rateBtn.modelData.label
                            color: Colors.text
                            font.pixelSize: UIScale.fontCaption
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SysMonService.pullRateMs = rateBtn.modelData.ms
                        }
                    }
                }
            }

            Text {
                text: "Process limit"
                color: Colors.text
                font.pixelSize: UIScale.fontSmall
                font.weight: Font.Bold
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * UIScale.value)

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
                        implicitHeight: Math.round(32 * UIScale.value)
                        radius: UIScale.radiusSm
                        property bool selected: SysMonService.procLimit === limitBtn.modelData.n
                        color: limitBtn.selected ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surfaceHigh
                        border.color: limitBtn.selected ? Colors.accent : "transparent"
                        border.width: 1
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: limitBtn.modelData.label
                            color: Colors.text
                            font.pixelSize: UIScale.fontCaption
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
                Layout.fillHeight: true
            }
        }
    }
}
