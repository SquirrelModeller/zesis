import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "Widgets/Music"
import "Widgets/Simulation"

Scope {
    Variants {
        model: Quickshell.screens
        delegate: WlrLayershell {
            id: root

            required property ShellScreen modelData

            layer: WlrLayer.Top
            screen: modelData

            implicitHeight: 60

            anchors {
                top: true
                left: true
                right: true
            }

            color: "transparent"

            RowLayout {
                id: workspacePicker
                anchors {
                    leftMargin: 20
                    topMargin: 10
                }
                spacing: 0
                layoutDirection: Qt.LeftToRight
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                WorkspaceIndicator {}
            }

            RowLayout {
                id: sysTray

                anchors {
                    rightMargin: 20
                    topMargin: 10
                }
                spacing: 0
                layoutDirection: Qt.RightToLeft
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                SysTray {}
            }
        }
    }

    // PanelWindow {
    //     exclusionMode: ExclusionMode.Ignore
    //     anchors {
    //         top: true
    //     }

    //     implicitWidth: 400
    //     implicitHeight: 240

    //     color: "transparent"

    //     //MusicController {}
    // }

    // PanelWindow {
    //     implicitHeight: 600
    //     implicitWidth: 600
    //     anchors {
    //         bottom: true
    //         right: true
    //     }

    //     Simulation {}
    // }

    // function dub(x: int): int {
    //     for (var i = 0; i < 10; i += 1) {
    //         console.log("hi");
    //     }
    //     return x * 2;
    // }
}
