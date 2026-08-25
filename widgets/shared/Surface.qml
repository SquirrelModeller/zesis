pragma ComponentBehavior: Bound
import QtQuick
import "../../"

Rectangle {
    id: root

    property real cornerRadius: 0
    property real topLeftCornerRadius: root.cornerRadius
    property real topRightCornerRadius: root.cornerRadius
    property real bottomLeftCornerRadius: root.cornerRadius
    property real bottomRightCornerRadius: root.cornerRadius

    property int level: 0
    property bool opaque: false

    property bool overrideFill: false
    property color fillColor: "transparent"

    readonly property bool _outline: SkinState.material === "outline"
    readonly property bool _glass: SkinState.material === "glass"

    radius: root.cornerRadius
    topLeftRadius: root.topLeftCornerRadius
    topRightRadius: root.topRightCornerRadius
    bottomLeftRadius: root.bottomLeftCornerRadius
    bottomRightRadius: root.bottomRightCornerRadius

    color: {
        if (root.overrideFill)
            return root.fillColor;
        if (root.level === 0) {
            if (root._glass)
                return Colors.withAlpha(Colors.bg, 0.03);
            return root._outline ? "transparent" : (root.opaque ? Colors.bg : Colors.barBg);
        }
        if (root.level === 1)
            return root._outline ? "transparent" : Colors.withAlpha(Colors.surface, 0.6);
        if (root.level === 2) {
            if (root._glass)
                return Colors.withAlpha(Colors.bg, 0.14);
            return Colors.withAlpha(Colors.text, 0.03);
        }
        return Colors.surfaceHigh;
    }
    border.width: {
        if (root.level === 0)
            return (root._outline || root._glass) ? 1 : 0;
        if (root.level === 1)
            return 0;
        return 1;
    }
    border.color: {
        if (root.level === 0)
            return root._glass ? Colors.withAlpha(Colors.text, 0.0) : Colors.accent;
        if (root.level === 3)
            return root._outline ? Colors.accent : Colors.withAlpha(Colors.text, 0.1);
        return Colors.withAlpha(Colors.text, 0.08);
    }
}
