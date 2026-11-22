import QtQuick
import QtQuick.Particles

// Falling snow over whatever this item covers. Qt's particle system does the
// work: an emitter along the top edge creates flakes, gravity pulls them
// down, and a random "wander" makes them drift like real snow.
//   Snow { anchors.fill: parent; intensity: 1; wind: 20 }
// burst(x, y) throws a puff of flakes from a point (for clicks and keys).
Item {
    id: root

    property real intensity: 1             // 0 = none, 1 = steady, 3 = blizzard
    property real wind: 15                 // sideways drift, pixels per second (negative = left)
    property color tint: "white"
    property bool running: true

    ParticleSystem {
        id: system
        anchors.fill: parent
        running: root.running

        // what a flake looks like: a soft round dot, drawn by the GPU
        ItemParticle {
            groups: ["flake", "puff"]
            delegate: Rectangle {
                readonly property real size: 3 + Math.random() * 5
                width: size
                height: size
                radius: size / 2
                color: root.tint
                opacity: 0.4 + Math.random() * 0.5
            }
        }

        // steady snow: born along the top edge, falling
        Emitter {
            group: "flake"
            width: parent.width
            height: 1
            y: -10
            emitRate: 40 * root.intensity * (parent.width / 1920)   // the same density on any width
            lifeSpan: 12000
            lifeSpanVariation: 3000
            velocity: AngleDirection { angle: 90; angleVariation: 12; magnitude: 45; magnitudeVariation: 25 }
            enabled: root.intensity > 0
        }

        // the puff for burst(): a short blast in every direction
        Emitter {
            id: puffs
            group: "puff"
            enabled: false
            emitRate: 0
            lifeSpan: 1600
            lifeSpanVariation: 400
            velocity: AngleDirection { angle: 0; angleVariation: 180; magnitude: 140; magnitudeVariation: 80 }
        }

        // wind pushes everything sideways; gravity pulls the puffs back down
        Gravity { groups: ["flake", "puff"]; angle: 0; magnitude: root.wind }
        Gravity { groups: ["puff"]; angle: 90; magnitude: 160 }
        // drifting: each flake wanders a little left and right
        Wander { groups: ["flake"]; xVariance: 40; pace: 40 }
    }

    // a puff of flakes from a point
    function burst(x, y, count) {
        puffs.burst(count ?? 18, x, y);
    }
}
