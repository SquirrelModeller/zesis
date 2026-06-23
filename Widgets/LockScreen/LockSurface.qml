pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
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
    property real _vx: 0
    property real _vy: 0
    property string _roastMessage: ""

    Image {
        anchors.fill: parent
        source: ThemeState.lastWallpaper !== "" ? ("file://" + ThemeState.lastWallpaper) : ""
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
                if (surface.inputBuffer === "please") {
                    surface._roastMessage = "no.";
                    surface.inputBuffer = "";
                    roastTimer.restart();
                    return;
                }
                if (surface.inputBuffer === "password") {
                    surface._roastMessage = "...seriously?";
                    surface.inputBuffer = "";
                    roastTimer.restart();
                    return;
                }
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

    ClockDial {
        id: clockDial
        x: (parent.width - width) / 2
        y: parent.height / 2 - Math.round(396 * UIScale.value)
        discRadius: Math.round(240 * UIScale.value)
        alwaysExpanded: true
        unlocking: surface.unlocking

        onSpinClicksChanged: {
            if (spinClicks === 7) {
                surface._vx = (Math.random() > 0.5 ? 1 : -1) * (6 + Math.random() * 4);
                surface._vy = -(14 + Math.random() * 6);
                clockDial._spinStep *= 3;
            }
        }
    }

    Rectangle {
        id: inputPill
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 + Math.round(152 * UIScale.value)
        width: Math.round(260 * UIScale.value)
        height: Math.round(44 * UIScale.value)
        radius: height / 2
        color: surface.authError ? Colors.withAlpha("#d05555", 0.25) : pam.active ? Colors.withAlpha(Colors.accent, 0.12) : Colors.withAlpha(Colors.surface, 0.9)
        border.color: surface.authError ? "#d05555" : pam.active ? Colors.withAlpha(Colors.accent, 0.7) : Colors.withAlpha(Colors.accent, 0.35)
        border.width: 1.5

        Behavior on color {
            ColorAnimation {
                duration: Anim.medium
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: Anim.medium
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
            text: surface._roastMessage !== "" ? surface._roastMessage : surface.inputBuffer.length > 0 ? Array(Math.min(surface.inputBuffer.length, 14) + 1).join("●") : "type to unlock"
            color: surface._roastMessage !== "" ? Colors.muted : surface.inputBuffer.length > 0 ? Colors.accent : Colors.muted
            font.pixelSize: surface._roastMessage !== "" || surface.inputBuffer.length === 0 ? UIScale.fontBody : Math.round(11 * UIScale.value * UIScale.fontScale)
            font.letterSpacing: surface._roastMessage !== "" || surface.inputBuffer.length === 0 ? 0 : Math.round(4 * UIScale.value)
            opacity: surface.unlocking ? 0 : 1
            Behavior on opacity {
                NumberAnimation {
                    duration: Anim.medium
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
        id: roastTimer
        interval: 2000
        onTriggered: surface._roastMessage = ""
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
        interval: 1300
        onTriggered: surface.lock.locked = false
    }

    Timer {
        id: beybladeTimer
        interval: 16
        repeat: true
        running: clockDial.spinClicks >= 7 && !surface.unlocking
        onTriggered: {
            var r = clockDial.discRadius;
            var grip = 0.7;
            var restitution = 0.82;
            // omega snapped once per tick; contact velocity = linear + spin tangential
            var omega = clockDial._spinStep * Math.PI / 180;
            var J, vc;

            surface._vy += 0.5;
            clockDial.x += surface._vx;
            clockDial.y += surface._vy;

            var maxX = surface.width - clockDial.width;
            var maxY = surface.height - clockDial.height;

            // floor: contact at bottom (0,+r), tangential = x
            // spin: CW bottom moves left  -> v_spin_x = -omega*r
            // torque from J_x at bottom:  Δω = -2*J/r  (rightward J -> CCW)
            if (clockDial.y > maxY) {
                clockDial.y = maxY;
                surface._vy = -Math.abs(surface._vy) * restitution;
                vc = surface._vx - omega * r;
                J = -grip * vc / 3;
                surface._vx += J;
                clockDial._spinStep -= 2 * J / r * (180 / Math.PI);
            }
            // ceiling: contact at top (0,-r), tangential = x
            // spin: CW top moves right    -> v_spin_x = +omega*r
            // torque from J_x at top:     Δω = +2*J/r
            if (clockDial.y < 0) {
                clockDial.y = 0;
                surface._vy = Math.abs(surface._vy) * restitution;
                vc = surface._vx + omega * r;
                J = -grip * vc / 3;
                surface._vx += J;
                clockDial._spinStep += 2 * J / r * (180 / Math.PI);
            }
            // right wall: contact at right (+r,0), tangential = y
            // spin: CW right moves down   -> v_spin_y = +omega*r
            // torque from J_y at right:   Δω = +2*J/r  (upward J -> CCW)
            if (clockDial.x > maxX) {
                clockDial.x = maxX;
                surface._vx = -Math.abs(surface._vx);
                vc = surface._vy + omega * r;
                J = -grip * vc / 3;
                surface._vy += J;
                clockDial._spinStep += 2 * J / r * (180 / Math.PI);
            }
            // left wall: contact at left (-r,0), tangential = y
            // spin: CW left moves up      -> v_spin_y = -omega*r
            // torque from J_y at left:    Δω = -2*J/r
            if (clockDial.x < 0) {
                clockDial.x = 0;
                surface._vx = Math.abs(surface._vx);
                vc = surface._vy - omega * r;
                J = -grip * vc / 3;
                surface._vy += J;
                clockDial._spinStep -= 2 * J / r * (180 / Math.PI);
            }
        }
    }
}
