import QtQuick
import Quickshell
import "./Disc"

Item {
    id: root

    property string corner: "topLeft"
    property bool forceExpanded: false
    property var screen: null

    implicitWidth: disc.implicitWidth
    implicitHeight: disc.implicitHeight

    readonly property real maskX: disc.visualDiscCX - disc.discRadius
    readonly property real maskY: disc.visualDiscCY - disc.discRadius
    readonly property real maskWidth: disc.discRadius * 2
    readonly property real maskHeight: disc.discRadius * 2
    readonly property int maskShape: RegionShape.Ellipse

    WorkspaceDisc {
        id: disc
        anchors.fill: parent
        corner: root.corner
        forceExpanded: root.forceExpanded
        screen: root.screen
    }
}
