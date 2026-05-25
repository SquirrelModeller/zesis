import QtQuick 2.15
import QtQuick.Controls 2.15
import Quickshell.Hyprland
import "./visual/Theme.js" as Theme
import QtQuick.Controls.Basic
import QtQml

Rectangle {
    id: workspace
    width: childrenRect.width
    height: childrenRect.height

    color: Theme.transparentBackground
    radius: 100

    Row {
        Repeater {
            id: workspacerepeater
            model: 10
            delegate: Button {
                id: workspaceIndicator
                property int workspaceIndex: index + 1
                property var jp: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
                property var workspace: Hyprland.workspaces.values.find(ws => parseInt(ws.name) === workspaceIndex)
                text: jp[workspaceIndex - 1]
                font.pixelSize: Theme.textSizeWorkspaceIndicator

                contentItem: Text {
                    text: workspaceIndicator.text
                    font: workspaceIndicator.font
                    color: workspaceIndicator.workspace ? (workspaceIndicator.workspace === Hyprland.focusedMonitor.activeWorkspace ? Theme.focusedWorkspace : Theme.unfocusedWorkspace) : Theme.notWorkspace
                    anchors.margins: 2
                    elide: Text.ElideRight
                }

                background: Rectangle {
                    color: workspaceIndicator.hovered ? Qt.rgba(0, 0, 0, 0.4) : "transparent"
                    radius: 100
                }

                onClicked: Hyprland.dispatch("workspace " + workspaceIndex)
            }
        }
    }
}
