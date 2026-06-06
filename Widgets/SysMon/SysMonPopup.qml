pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
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
        radius: 12
        color: Colors.bg
        border.color: Colors.outline
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        // Tab bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: ["CPU", "Memory", "GPU", "Net", "Disk"]
                delegate: Rectangle {
                    id: tab
                    required property string modelData
                    required property int index

                    property bool active: root.activeTab === tab.index

                    implicitHeight: 30
                    implicitWidth: tabLabel.implicitWidth + 20
                    radius: 8
                    color: tab.active ? Colors.surface : tabHover.hovered ? Colors.withAlpha(Colors.surface, 0.6) : "transparent"
                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    Text {
                        id: tabLabel
                        anchors.centerIn: parent
                        text: tab.modelData
                        color: tab.active ? Colors.text : Colors.textDim
                        font.pixelSize: 13
                        font.weight: tab.active ? Font.DemiBold : Font.Normal
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }

                    HoverHandler {
                        id: tabHover
                    }
                    TapHandler {
                        onTapped: SysMonService.activeTab = tab.index
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }

        // CPU
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6
            visible: root.activeTab === 0

            DonutChart {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 170
                Layout.preferredHeight: 170
                segments: root._cpuSegments
                total: 100
                centerText: root._cpu.percent ? root._cpu.percent.toFixed(0) + "%" : "0%"
                subText: "load " + (root._cpu.load ? root._cpu.load.toFixed(2) : "0")
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "CPU"
                color: Colors.textDim
                font.pixelSize: 11
                font.weight: Font.Medium
            }

            Item {
                Layout.preferredHeight: 4
            }

            Repeater {
                model: (root._cpu.procs || []).length === 0 ? 8 : 0
                delegate: Item {
                    id: cpuSkel
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: 20

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(1, 1, 1, 0.08)
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * (0.35 + (cpuSkel.index % 4) * 0.07)
                        height: 8
                        radius: 3
                        color: Qt.rgba(1, 1, 1, 0.07)
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36
                        height: 8
                        radius: 3
                        color: Qt.rgba(1, 1, 1, 0.07)
                    }
                }
            }

            Repeater {
                model: root._cpu.procs || []
                delegate: Item {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 20

                    Rectangle {
                        id: dot
                        width: 8
                        height: 8
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.procColor(modelData.name)
                    }

                    Text {
                        anchors.left: dot.right
                        anchors.leftMargin: 8
                        anchors.right: val.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        color: Colors.text
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    Text {
                        id: val
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.cpu.toFixed(1) + "%"
                        color: Colors.textDim
                        font.pixelSize: 12
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
            spacing: 6
            visible: root.activeTab === 1

            DonutChart {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 170
                Layout.preferredHeight: 170
                segments: root._memSegments
                total: root._mem.total_bytes
                centerText: root.fmtBytes(root._mem.used_bytes)
                subText: root.fmtBytes(root._mem.total_bytes)
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Memory"
                color: Colors.textDim
                font.pixelSize: 11
                font.weight: Font.Medium
            }

            Item {
                Layout.preferredHeight: 4
            }

            Repeater {
                model: (root._mem.procs || []).length === 0 ? 8 : 0
                delegate: Item {
                    id: memSkel
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: 20

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(1, 1, 1, 0.08)
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * (0.35 + (memSkel.index % 4) * 0.07)
                        height: 8
                        radius: 3
                        color: Qt.rgba(1, 1, 1, 0.07)
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36
                        height: 8
                        radius: 3
                        color: Qt.rgba(1, 1, 1, 0.07)
                    }
                }
            }

            Repeater {
                model: root._mem.procs || []
                delegate: Item {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 20

                    Rectangle {
                        id: memDot
                        width: 8
                        height: 8
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.procColor(modelData.name)
                    }

                    Text {
                        anchors.left: memDot.right
                        anchors.leftMargin: 8
                        anchors.right: memVal.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        color: Colors.text
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    Text {
                        id: memVal
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.fmtBytes(modelData.rss)
                        color: Colors.textDim
                        font.pixelSize: 12
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
            spacing: 6
            visible: root.activeTab === 2

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6
                visible: root._gpus.length > 1

                Repeater {
                    model: root._gpus
                    delegate: Rectangle {
                        id: chip
                        required property var modelData
                        required property int index

                        property bool active: root.selectedCard === chip.index

                        height: 24
                        width: chipLabel.implicitWidth + 16
                        radius: 6
                        color: chip.active ? Colors.surface : chipHover.hovered ? Colors.withAlpha(Colors.surface, 0.6) : "transparent"
                        border.color: chip.active ? Colors.outline : "transparent"
                        border.width: 1
                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }

                        Text {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: chip.modelData.card
                            color: chip.active ? Colors.text : Colors.textDim
                            font.pixelSize: 11
                        }

                        HoverHandler {
                            id: chipHover
                        }
                        TapHandler {
                            onTapped: root.selectedCard = chip.index
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    DonutChart {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 140
                        segments: root._gpuComputeSegments
                        total: 100
                        centerText: root._card ? root._card.busy + "%" : "0%"
                        subText: root._card ? root._card.temp_c.toFixed(0) + "°C" : ""
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Compute"
                        color: Colors.textDim
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    DonutChart {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 140
                        segments: root._gpuVramSegments
                        total: root._card ? root._card.vram_total : 1
                        centerText: root._card ? root.fmtBytes(root._card.vram_used) : "0"
                        subText: root._card ? root.fmtBytes(root._card.vram_total) : ""
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "VRAM"
                        color: Colors.textDim
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }
                }
            }

            Item {
                Layout.preferredHeight: 4
            }

            Repeater {
                model: (root._card && (root._card.procs || []).length === 0) ? 8 : 0
                delegate: Item {
                    id: gpuSkel
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: 20

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(1, 1, 1, 0.08)
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * (0.35 + (gpuSkel.index % 4) * 0.07)
                        height: 8
                        radius: 3
                        color: Qt.rgba(1, 1, 1, 0.07)
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36
                        height: 8
                        radius: 3
                        color: Qt.rgba(1, 1, 1, 0.07)
                    }
                }
            }

            Repeater {
                model: root._card ? root._card.procs || [] : []
                delegate: Item {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 20

                    Rectangle {
                        id: gpuDot
                        width: 8
                        height: 8
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.procColor(modelData.name)
                    }

                    Text {
                        anchors.left: gpuDot.right
                        anchors.leftMargin: 8
                        anchors.right: gfxVal.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        color: Colors.text
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    Text {
                        id: gfxVal
                        anchors.right: vramVal.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.gfx_pct.toFixed(1) + "%"
                        color: Colors.textDim
                        font.pixelSize: 11
                        font.family: "monospace"
                        visible: modelData.gfx_pct > 0
                    }

                    Text {
                        id: vramVal
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.fmtBytes(modelData.vram_kib * 1024)
                        color: Colors.textDim
                        font.pixelSize: 12
                        font.family: "monospace"
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: root._gpus.length === 0
                text: "No GPU detected"
                color: Colors.textDim
                font.pixelSize: 13
            }

            Item {
                Layout.fillHeight: true
            }
        }

        // Network
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6
            visible: root.activeTab === 3

            // rx / tx totals
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 8
                    color: Colors.surface

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.fmtRate(root._net.reduce((a, i) => a + i.rx_bytes_per_sec, 0))
                            color: Colors.text
                            font.pixelSize: 15
                            font.weight: 600
                            font.family: "monospace"
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "↓ RX"
                            color: Colors.textDim
                            font.pixelSize: 11
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 8
                    color: Colors.surface

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.fmtRate(root._net.reduce((a, i) => a + i.tx_bytes_per_sec, 0))
                            color: Colors.text
                            font.pixelSize: 15
                            font.weight: 600
                            font.family: "monospace"
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "↑ TX"
                            color: Colors.textDim
                            font.pixelSize: 11
                        }
                    }
                }
            }

            Item {
                Layout.preferredHeight: 4
            }

            Repeater {
                model: root._net
                delegate: Item {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 20

                    Text {
                        id: ifaceName
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        color: Colors.text
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }

                    Text {
                        id: txVal
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "↑ " + root.fmtRate(modelData.tx_bytes_per_sec)
                        color: Colors.textDim
                        font.pixelSize: 12
                        font.family: "monospace"
                    }

                    Text {
                        anchors.right: txVal.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: "↓ " + root.fmtRate(modelData.rx_bytes_per_sec)
                        color: Colors.textDim
                        font.pixelSize: 12
                        font.family: "monospace"
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: root._net.length === 0
                text: "No interfaces"
                color: Colors.textDim
                font.pixelSize: 13
            }

            Item {
                Layout.fillHeight: true
            }
        }

        // Disk
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6
            visible: root.activeTab === 4

            // read / write totals (top-level devices only)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 8
                    color: Colors.surface

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.fmtRate(SysMonService.disk.reduce((a, d) => a + d.read_bytes_per_sec, 0))
                            color: Colors.text
                            font.pixelSize: 15
                            font.weight: 600
                            font.family: "monospace"
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "R Read"
                            color: Colors.textDim
                            font.pixelSize: 11
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 8
                    color: Colors.surface

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.fmtRate(SysMonService.disk.reduce((a, d) => a + d.write_bytes_per_sec, 0))
                            color: Colors.text
                            font.pixelSize: 15
                            font.weight: 600
                            font.family: "monospace"
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "W Write"
                            color: Colors.textDim
                            font.pixelSize: 11
                        }
                    }
                }
            }

            Item {
                Layout.preferredHeight: 4
            }

            Repeater {
                model: root._disk
                delegate: Item {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 20

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: modelData.depth * 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: (modelData.depth > 0 ? "↳ " : "") + modelData.name
                        color: modelData.depth > 0 ? Colors.textDim : Colors.text
                        font.pixelSize: 12
                        font.weight: modelData.depth > 0 ? Font.Normal : Font.Medium
                    }

                    Text {
                        id: writeVal
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "W " + root.fmtRate(modelData.write)
                        color: Colors.textDim
                        font.pixelSize: 12
                        font.family: "monospace"
                    }

                    Text {
                        anchors.right: writeVal.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: "R " + root.fmtRate(modelData.read)
                        color: Colors.textDim
                        font.pixelSize: 12
                        font.family: "monospace"
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: root._disk.length === 0
                text: "No disks"
                color: Colors.textDim
                font.pixelSize: 13
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
