pragma ComponentBehavior: Bound

import QtQuick
import "./"
import "../../"
import "../Bar"

Item {
    id: root

    readonly property real cellH: Math.round(30 * UIScale.value)
    readonly property real cellW: Math.round(14 * UIScale.value)
    readonly property real colonW: Math.round(14 * UIScale.value)
    readonly property real hPad: Math.round(14 * UIScale.value)
    readonly property real vPad: Math.round(5 * UIScale.value)
    readonly property real charGap: Math.round(1 * UIScale.value)

    // "breathe" | "on" | "off" | "hidden"
    property string colonMode: ClockSettings.colonMode
    // "fixed" | "fluid"
    property string widthMode: ClockSettings.widthMode
    property bool _colonOn: true

    property var _date: new Date()
    property bool _altLatch: false  // consumed on first fire, resets after 5 AM
    property int _state: 0     // 0=IDLE  1=DELETING  2=TYPING
    property var _target: []
    property int _from: 0
    property int _cursor: 0
    property bool _cursorOn: true

    // Minimum content width for standard HH:MM display (respects colon visibility)
    readonly property real _minContentW: {
        if (colonMode === "hidden")
            return 4 * cellW + 3 * charGap;
        return 4 * cellW + colonW + 4 * charGap;
    }

    // Pill resizes with content, in fixed mode it never shrinks below HH:MM width
    implicitWidth: BarConfig.isVertical ? (2 * cellW + charGap + hPad * 2) : ((widthMode === "fixed" ? Math.max(charsRow.implicitWidth, _minContentW) : charsRow.implicitWidth) + hPad * 2)
    implicitHeight: BarConfig.isVertical ? (2 * cellH + vPad * 3) : (cellH + vPad * 2)

    ListModel {
        id: slotsModel
    }

    // Second tick: colon blink + minute change detection
    Timer {
        running: true
        repeat: true
        interval: 1000
        onTriggered: {
            root._colonOn = !root._colonOn;
            var now = new Date();
            if (now.getMinutes() === root._date.getMinutes() && now.getHours() === root._date.getHours()) {
                root._date = now;
                return;
            }
            root._date = now;
            var h = now.getHours();
            if (h < 2 || h >= 5)
                root._altLatch = false;
            root._animateTo(root._resolveTarget(now));
        }
    }

    // Cursor blink, only active during TYPING
    Timer {
        interval: 450
        repeat: true
        running: root._state === 2
        onTriggered: root._cursorOn = !root._cursorOn
        onRunningChanged: if (!running)
            root._cursorOn = true
    }

    // Keystroke stepping
    Timer {
        interval: 100
        repeat: true
        running: root._state !== 0
        onTriggered: root._step()
    }

    function _timeChars(h, m) {
        return [Math.floor(h / 10).toString(), (h % 10).toString(), ":", Math.floor(m / 10).toString(), (m % 10).toString()];
    }

    function _resolveTarget(date) {
        var h = date.getHours();
        if (h >= 2 && h < 5 && !root._altLatch) {
            root._altLatch = true;
            return ["U", " ", "U", "P", " ", "L", "8", "?"];
        }
        return _timeChars(h, date.getMinutes());
    }

    function _currentChars() {
        var arr = [];
        for (var i = 0; i < slotsModel.count; i++)
            arr.push(slotsModel.get(i).ch);
        return arr;
    }

    function _animateTo(newTarget) {
        if (_state !== 0) {
            // Snap to in-progress target so we compare from a clean slate
            _state = 0;
            slotsModel.clear();
            for (var j = 0; j < _target.length; j++)
                slotsModel.append({
                    ch: _target[j]
                });
        }
        var old = _currentChars();
        var minLen = Math.min(old.length, newTarget.length);
        var from = minLen;
        for (var i = 0; i < minLen; i++) {
            if (old[i] !== newTarget[i]) {
                from = i;
                break;
            }
        }
        if (from === old.length && old.length === newTarget.length)
            // identical, nothing to do
            return;
        _target = newTarget;
        _from = from;
        if (slotsModel.count > from) {
            _state = 1;  // delete excess from the right first
        } else {
            _cursor = from;
            _state = 2;  // nothing to delete, go straight to typing
        }
    }

    function _step() {
        if (_state === 1) {
            slotsModel.remove(slotsModel.count - 1);
            if (slotsModel.count <= _from) {
                _cursor = _from;
                _state = 2;
            }
        } else if (_state === 2) {
            if (_cursor < _target.length) {
                slotsModel.append({
                    ch: _target[_cursor]
                });
                _cursor++;
            } else {
                _state = 0;
            }
        }
    }

    Component.onCompleted: {
        ClockSettings.altModeRequested.connect(root.triggerAltMode);
        var chars = _resolveTarget(new Date());
        for (var i = 0; i < chars.length; i++)
            slotsModel.append({
                ch: chars[i]
            });
        _target = chars;
    }

    // Instantly display a given time (used by test panel)
    function snapTo(h, m) {
        _state = 0;
        slotsModel.clear();
        var chars = _timeChars(h, m);
        for (var i = 0; i < chars.length; i++)
            slotsModel.append({
                ch: chars[i]
            });
        _target = chars;
    }

    // Trigger typewriter animation to the given time (used by test panel)
    function simulateTo(h, m) {
        _animateTo(_timeChars(h, m));
    }

    function triggerAltMode() {
        _animateTo(["U", " ", "U", "P", " ", "L", "8", "?"]);
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Colors.bg
        border.color: Colors.withAlpha(Colors.accent, 0.22)
        border.width: 1.5
    }

    // Horizontal layout
    Row {
        id: charsRow
        visible: !BarConfig.isVertical
        anchors.left: parent.left
        anchors.leftMargin: root.hPad
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.charGap

        Repeater {
            model: slotsModel
            delegate: SlotItem {}
        }

        // Blinking cursor at the typing frontier
        Item {
            visible: root._state === 2 && root._cursor < root._target.length
            width: root.cellW
            height: root.cellH
            Text {
                anchors.centerIn: parent
                text: "_"
                font.pixelSize: Math.round(21 * UIScale.value)
                font.bold: true
                font.family: "monospace"
                color: root._cursorOn ? Colors.accent : Colors.withAlpha(Colors.accent, 0.12)
            }
        }
    }

    // Vertical stacked layout, same slotsModel, two filtered views
    Column {
        visible: BarConfig.isVertical
        anchors.centerIn: parent
        spacing: root.vPad

        // Hours row: indices 0–1
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.charGap

            Repeater {
                model: slotsModel
                delegate: Item {
                    required property string ch
                    required property int index
                    visible: index < 2
                    width: root.cellW
                    height: root.cellH
                    Text {
                        anchors.centerIn: parent
                        text: parent.ch
                        font.pixelSize: Math.round(21 * UIScale.value)
                        font.bold: true
                        font.family: "monospace"
                        color: Colors.accent
                    }
                }
            }
            Item {
                visible: root._state === 2 && root._cursor < 2
                width: root.cellW
                height: root.cellH
                Text {
                    anchors.centerIn: parent
                    text: "_"
                    font.pixelSize: Math.round(21 * UIScale.value)
                    font.bold: true
                    font.family: "monospace"
                    color: root._cursorOn ? Colors.accent : Colors.withAlpha(Colors.accent, 0.12)
                }
            }
        }

        // Minutes row: indices > 2 (colon at index 2 is skipped)
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.charGap

            Repeater {
                model: slotsModel
                delegate: Item {
                    required property string ch
                    required property int index
                    visible: index > 2
                    width: root.cellW
                    height: root.cellH
                    Text {
                        anchors.centerIn: parent
                        text: parent.ch
                        font.pixelSize: Math.round(21 * UIScale.value)
                        font.bold: true
                        font.family: "monospace"
                        color: Colors.accent
                    }
                }
            }
            Item {
                visible: root._state === 2 && root._cursor > 2
                width: root.cellW
                height: root.cellH
                Text {
                    anchors.centerIn: parent
                    text: "_"
                    font.pixelSize: Math.round(21 * UIScale.value)
                    font.bold: true
                    font.family: "monospace"
                    color: root._cursorOn ? Colors.accent : Colors.withAlpha(Colors.accent, 0.12)
                }
            }
        }
    }

    component SlotItem: Item {
        required property string ch

        readonly property bool _isColon: ch === ":"

        // Hidden colon takes no space so the pill tightens
        visible: !(_isColon && root.colonMode === "hidden")
        width: _isColon ? root.colonW : root.cellW
        height: root.cellH

        Text {
            anchors.centerIn: parent
            text: parent.ch
            font.pixelSize: Math.round(21 * UIScale.value)
            font.bold: true
            font.family: "monospace"
            color: Colors.accent
            opacity: {
                if (!parent._isColon)
                    return 1;
                if (root.colonMode === "on")
                    return 0.85;
                if (root.colonMode === "off")
                    return 0.18;
                return root._colonOn ? 0.85 : 0.18;
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Anim.fast
                }
            }
        }
    }
}
