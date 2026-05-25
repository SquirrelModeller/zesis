import QtQuick

Rectangle {
    id: sim
    width: parent.width
    height: parent.height

    property real box_x: 20
    property real box_y: 0

    property real vy: 0
    property real vx: 140
    property real ay: 0

    property real box_size: 50

    property real gravity: 981

    property real drag_coefficient_box: 0.1
    property real box_mass: 1
    property real friction_coefficient: 0.4

    Rectangle {
        id: box
        color: "black"
        width: sim.box_size
        height: sim.box_size
        y: sim.box_y
        x: sim.box_x
    }

    Timer {
        id: stepTimer
        interval: 10
        repeat: true
        running: false

        onTriggered: {
            var dt = interval / 1000.0;

            // Gravity
            sim.vy += sim.gravity * dt;

            // Air drag, linear
            var dragFactor = sim.drag_coefficient_box / sim.box_mass;
            sim.vx -= dragFactor * sim.vx * dt;
            sim.vy -= dragFactor * sim.vy * dt;

            if (sim.box_y + sim.box_size >= sim.height) {
                var normal = sim.box_mass * sim.gravity;
                var friction_impulse = sim.friction_coefficient * normal * dt;

                if (Math.abs(sim.vx) <= friction_impulse) {
                    sim.vx = 0;
                } else {
                    sim.vx -= friction_impulse * Math.sign(sim.vx);
                }
            }

            // Integrate Position
            sim.box_y += sim.vy * dt;
            sim.box_x += sim.vx * dt;

            // Collision with ground
            if (sim.box_y + sim.box_size > sim.height) {
                sim.box_y = sim.height - sim.box_size;
                sim.vy *= -0.5;

                if (Math.abs(sim.vy) < 0.1) {
                    sim.vy = 0;
                }
            }
        }
    }

    MouseArea {
        id: ms
        property bool isDragging: false
        anchors.fill: parent
        hoverEnabled: true
        onPressed: {
            isDragging = true;
        }

        onReleased: {
            isDragging = false;
            sim.vy = 0;
        }

        onPositionChanged: mevent => {
            if (isDragging) {
                sim.box_y = mevent.y;
                sim.box_x = mevent.x;
            }
        }
    }

    Text {
        anchors.right: parent.right

        text: stepTimer.running ? "running" : "stopped"

        MouseArea {
            anchors.fill: parent
            onClicked: {
                stepTimer.running = !stepTimer.running;
            }
        }
    }
}
