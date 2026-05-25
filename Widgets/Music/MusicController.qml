import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Mpris

Rectangle {
    id: rootplayer
    width: 100
    height: 100
    color: "transparent"
    // SwipeView {
    //     id: list

    //     anchors.fill: parent
    //     orientation: Qt.Vertical
    Repeater {

        model: ScriptModel {
            values: [...Mpris.players.values]
        }

        MprisItem {
            id: rect
            required property MprisPlayer modelData
            player: modelData
            discScale: 0.7
        }
    }
}
//}
