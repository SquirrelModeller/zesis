pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland._Screencopy
import "../../"

Item {
    id: root
    focus: true

    readonly property var windows: AppSwitcherService.windows
    readonly property int selectedIndex: AppSwitcherService.selectedIndex

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Tab:
            AppSwitcherService.cycleForward();
            event.accepted = true;
            break;
        case Qt.Key_Backtab:
            AppSwitcherService.cycleBack();
            event.accepted = true;
            break;
        case Qt.Key_Right:
            AppSwitcherService.cycleForward();
            event.accepted = true;
            break;
        case Qt.Key_Left:
            AppSwitcherService.cycleBack();
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            AppSwitcherService.confirm();
            event.accepted = true;
            break;
        case Qt.Key_Escape:
            AppSwitcherService.cancel();
            event.accepted = true;
            break;
        }
    }

    Keys.onReleased: event => {
        if (event.key === Qt.Key_Alt) {
            AppSwitcherService.confirm();
            event.accepted = true;
        }
    }

    property point _lastCursorPos: Qt.point(-1, -1)

    // Height-driven sizing: all cards share the same thumbnail height, width varies per window aspect ratio
    readonly property int cardThumbH_sel: Math.round(root.height * 0.13)
    readonly property int cardThumbH: Math.round(cardThumbH_sel * 0.78)
    readonly property int labelH: 34
    readonly property int cardSpacing: Math.round(root.width * 0.007)
    readonly property int cardSelH: cardThumbH_sel + labelH

    function windowAspect(win) {
        var sz = win.lastIpcObject && win.lastIpcObject["size"];
        return (sz && sz.length >= 2 && sz[1] > 0) ? sz[0] / sz[1] : 16 / 9;
    }

    readonly property int selectedCardW: {
        var idx = root.selectedIndex;
        if (idx < 0 || idx >= root.windows.length)
            return root.cardThumbH_sel;
        return Math.round(root.cardThumbH_sel * root.windowAspect(root.windows[idx]));
    }

    readonly property int listW: {
        var total = 0;
        for (var i = 0; i < root.windows.length; i++) {
            var h = (i === root.selectedIndex) ? root.cardThumbH_sel : root.cardThumbH;
            total += Math.round(h * root.windowAspect(root.windows[i]));
        }
        total += root.cardSpacing * Math.max(0, root.windows.length - 1) + 20;
        return Math.min(root.width - 80, Math.max(root.selectedCardW + 40, total));
    }

    ListView {
        id: cardList
        orientation: ListView.Horizontal
        model: root.windows
        currentIndex: root.selectedIndex

        width: root.listW
        height: root.cardSelH + 20
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -10

        clip: false
        spacing: root.cardSpacing

        preferredHighlightBegin: (width - root.selectedCardW) / 2
        preferredHighlightEnd: (width - root.selectedCardW) / 2 + root.selectedCardW
        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: 220
        highlightMoveVelocity: -1
        highlight: null

        displaced: Transition {
            NumberAnimation {
                properties: "x"
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        delegate: Item {
            id: cardDelegate
            required property var modelData
            required property int index

            readonly property bool isSelected: cardDelegate.index === root.selectedIndex
            readonly property var ipcObj: cardDelegate.modelData.lastIpcObject ?? {}
            readonly property string winTitle: cardDelegate.ipcObj["title"] ?? ""
            readonly property string winClass: cardDelegate.ipcObj["class"] ?? ""
            readonly property int wsNum: {
                var ws = cardDelegate.modelData.workspace;
                return ws ? (parseInt(ws.name) || 0) : 0;
            }
            readonly property real thumbAspect: {
                var sz = cardDelegate.ipcObj["size"];
                return (sz && sz.length >= 2 && sz[1] > 0) ? sz[0] / sz[1] : 16 / 9;
            }
            readonly property int thumbH: cardDelegate.isSelected ? root.cardThumbH_sel : root.cardThumbH

            width: Math.round(cardDelegate.thumbH * cardDelegate.thumbAspect)
            height: cardList.height
            Behavior on width {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Item {
                id: inner
                width: parent.width
                height: Math.round(parent.width / cardDelegate.thumbAspect) + root.labelH
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter

                opacity: cardDelegate.isSelected ? 1.0 : 0.58
                Behavior on opacity {
                    NumberAnimation {
                        duration: 160
                    }
                }

                // Card background (behind thumbnail)
                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: Colors.surface
                }

                // Thumbnail, sized to window's natural aspect ratio, no dead space
                Item {
                    id: thumbItem
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 1
                    height: Math.round(inner.width / cardDelegate.thumbAspect)

                    ScreencopyView {
                        anchors.fill: parent
                        captureSource: cardDelegate.modelData.wayland
                        live: true
                    }
                }

                // Border overlay on top of thumbnail
                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: "transparent"
                    border.color: cardDelegate.isSelected ? Colors.accent : Colors.outline
                    border.width: cardDelegate.isSelected ? 2 : 1
                    Behavior on border.color {
                        ColorAnimation {
                            duration: 160
                        }
                    }
                }

                // App class label
                Text {
                    id: classLabel
                    anchors.left: parent.left
                    anchors.right: wsBadge.left
                    anchors.top: thumbItem.bottom
                    anchors.topMargin: 4
                    anchors.leftMargin: 8
                    anchors.rightMargin: 4
                    height: 14
                    text: cardDelegate.winClass
                    color: cardDelegate.isSelected ? Colors.muted : Colors.withAlpha(Colors.muted, 0.6)
                    font.pixelSize: 9
                    font.letterSpacing: 0.8
                    font.capitalization: Font.AllUppercase
                    elide: Text.ElideRight
                    Behavior on color {
                        ColorAnimation {
                            duration: 160
                        }
                    }
                }

                // Window title
                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: classLabel.bottom
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    text: cardDelegate.winTitle
                    color: cardDelegate.isSelected ? Colors.text : Colors.textDim
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    Behavior on color {
                        ColorAnimation {
                            duration: 160
                        }
                    }
                }

                // Workspace badge
                Rectangle {
                    id: wsBadge
                    anchors.top: thumbItem.bottom
                    anchors.right: parent.right
                    anchors.topMargin: 8
                    anchors.rightMargin: 7
                    width: 20
                    height: 20
                    radius: 10
                    visible: cardDelegate.wsNum > 0
                    color: cardDelegate.isSelected ? Colors.accent : Colors.withAlpha(Colors.accent, 0.30)
                    Behavior on color {
                        ColorAnimation {
                            duration: 160
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: cardDelegate.wsNum
                        font.pixelSize: 10
                        font.bold: true
                        color: cardDelegate.isSelected ? Colors.surface : Colors.text
                    }
                }

                // Only update selection when the cursor physically moves in screen space.
                // Cards shifting under a stationary cursor (from keyboard-driven animation)
                // changes point.position (local) but not point.scenePosition, so we ignore it.
                HoverHandler {
                    onPointChanged: {
                        if (!hovered)
                            return;
                        var sp = point.scenePosition;
                        if (sp.x === root._lastCursorPos.x && sp.y === root._lastCursorPos.y)
                            return;
                        root._lastCursorPos = sp;
                        AppSwitcherService.selectedIndex = cardDelegate.index;
                    }
                }

                TapHandler {
                    onTapped: {
                        AppSwitcherService.selectedIndex = cardDelegate.index;
                        AppSwitcherService.confirm();
                    }
                }
            }
        }
    }

    // Selected window subtitle
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: cardList.bottom
        anchors.topMargin: 16
        text: {
            var idx = root.selectedIndex;
            var wins = root.windows;
            if (idx >= 0 && idx < wins.length && wins[idx].lastIpcObject) {
                var cls = wins[idx].lastIpcObject["class"] ?? "";
                var title = wins[idx].lastIpcObject["title"] ?? "";
                return cls ? cls + (title ? "  -  " + title : "") : title;
            }
            return "";
        }
        color: Colors.muted
        font.pixelSize: 13
        font.letterSpacing: 0.5
    }
}
