pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import "../../"
import "../Shared"

WlSessionLockSurface {
    id: surface

    required property WlSessionLock lock

    property string inputBuffer: ""
    property bool authError: false
    property bool unlocking: false

    Image {
        anchors.fill: parent
        source: "file:///home/squirrel/Desktop/Files/Pictures/Backgrounds/CableCars.jpg"
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1.0
            blurMax: 48
            autoPaddingEnabled: false
        }
    }

    // Dark scrim
    Rectangle {
        anchors.fill: parent
        color: Colors.bg
        opacity: 0.5
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (surface.unlocking || pam.active)
                return;
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (surface.inputBuffer.length > 0)
                    pam.start();
                return;
            }
            if (event.key === Qt.Key_Backspace) {
                if (event.modifiers & Qt.ControlModifier)
                    surface.inputBuffer = "";
                else
                    surface.inputBuffer = surface.inputBuffer.slice(0, -1);
                return;
            }
            if (event.text && event.text.length > 0)
                surface.inputBuffer += event.text;
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -100
        spacing: 28

        ClockDial {
            anchors.horizontalCenter: parent.horizontalCenter
            discRadius: 240
            alwaysExpanded: true
        }

        Rectangle {
            id: inputPill
            anchors.horizontalCenter: parent.horizontalCenter
            width: 260
            height: 44
            radius: 22
            color: surface.authError ? Colors.withAlpha("#d05555", 0.25) : pam.active ? Colors.withAlpha(Colors.accent, 0.12) : Colors.withAlpha(Colors.surface, 0.9)
            border.color: surface.authError ? "#d05555" : pam.active ? Colors.withAlpha(Colors.accent, 0.7) : Colors.withAlpha(Colors.accent, 0.35)
            border.width: 1.5

            Behavior on color {
                ColorAnimation {
                    duration: 180
                }
            }
            Behavior on border.color {
                ColorAnimation {
                    duration: 180
                }
            }

            transform: Translate {
                id: shakeOffset
            }

            SequentialAnimation {
                id: shakeAnim
                loops: 2
                NumberAnimation {
                    target: shakeOffset
                    property: "x"
                    to: -7
                    duration: 45
                }
                NumberAnimation {
                    target: shakeOffset
                    property: "x"
                    to: 7
                    duration: 45
                }
                NumberAnimation {
                    target: shakeOffset
                    property: "x"
                    to: 0
                    duration: 45
                }
            }

            Text {
                anchors.centerIn: parent
                text: surface.inputBuffer.length > 0 ? Array(Math.min(surface.inputBuffer.length, 14) + 1).join("●") : "type to unlock"
                color: surface.inputBuffer.length > 0 ? Colors.accent : Colors.muted
                font.pixelSize: surface.inputBuffer.length > 0 ? 11 : 13
                font.letterSpacing: surface.inputBuffer.length > 0 ? 4 : 0
                opacity: surface.unlocking ? 0 : 1
                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }
            }
        }
    }

    PamContext {
        id: pam
        config: "quickshell"

        onResponseRequiredChanged: {
            if (responseRequired) {
                respond(surface.inputBuffer);
                surface.inputBuffer = "";
            }
        }

        onCompleted: res => {
            if (res === PamResult.Success) {
                surface.unlocking = true;
                unlockTimer.start();
            } else {
                surface.authError = true;
                shakeAnim.start();
                errorTimer.start();
            }
        }
    }

    Timer {
        id: errorTimer
        interval: 1500
        onTriggered: {
            surface.authError = false;
            surface.inputBuffer = "";
        }
    }

    Timer {
        id: unlockTimer
        interval: 350
        onTriggered: surface.lock.locked = false
    }
}
