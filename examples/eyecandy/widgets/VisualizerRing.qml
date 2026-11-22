import QtQuick
import qs.services

// Bars arranged in a circle, pointing outwards: put album art in the middle
// and the music pulses around it.
//   VisualizerRing { width: 300; height: 300; radius: 100 }
Item {
    id: root

    property real radius: Math.min(width, height) / 2 * 0.62   // inner circle where bars start
    property real maxLength: Math.min(width, height) / 2 - radius
    property real barWidth: 4
    property color colorFrom: "#7dcfff"
    property color colorTo: "#bb9af7"
    // cava's bars once around the circle, then mirrored, so the ring is symmetric
    readonly property int count: Cava.bars * 2

    Component.onCompleted: Cava.acquire()
    Component.onDestruction: Cava.release()

    Repeater {
        model: root.count
        Item {
            required property int index
            // which cava bar: 0 … bars-1, then back down, mirrored
            readonly property int source: index < Cava.bars ? index : root.count - 1 - index
            readonly property real value: Cava.values[source] ?? 0

            // an item at the centre, rotated to this bar's angle; the bar sits on it
            x: root.width / 2
            y: root.height / 2
            rotation: index / root.count * 360

            Rectangle {
                x: -root.barWidth / 2
                y: -root.radius - height               // outward from the inner circle
                width: root.barWidth
                height: Math.max(2, parent.value * root.maxLength)
                radius: width / 2
                color: Qt.tint(root.colorFrom, Qt.alpha(root.colorTo, parent.source / Math.max(1, Cava.bars - 1)))
                Behavior on height { NumberAnimation { duration: 50 } }
            }
        }
    }
}
