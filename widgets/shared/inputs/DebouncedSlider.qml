pragma ComponentBehavior: Bound
import QtQuick

// 0-100 slider that only commits 250ms after the drag settles
SettingSliderRow {
    id: root
    property int committed: 0
    property string suffix: "%"
    signal commit(int value)

    property int _pending: committed

    from: 0
    to: 100
    step: 1
    value: commitTimer.running ? _pending : committed
    valueText: (commitTimer.running ? _pending : committed) + suffix
    onMoved: v => {
        root._pending = Math.round(v);
        commitTimer.restart();
    }

    Timer {
        id: commitTimer
        interval: 250
        repeat: false
        onTriggered: root.commit(root._pending)
    }
}
