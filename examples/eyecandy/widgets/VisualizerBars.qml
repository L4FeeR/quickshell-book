import QtQuick
import qs.services

// Spectrum bars. Each bar's height follows one value from cava.
//   VisualizerBars { width: 300; height: 60; mirrored: true }
// mirrored: bars grow up and down from the middle (a "waveform" look)
// gradient: colours from the left bar to the right bar
Item {
    id: root

    property bool mirrored: false
    property real spacing: 3
    property color colorFrom: "#7dcfff"
    property color colorTo: "#bb9af7"
    property real minHeight: 2              // silent bars stay visible as dots
    readonly property int count: Cava.bars

    Component.onCompleted: Cava.acquire()
    Component.onDestruction: Cava.release()

    Repeater {
        model: root.count
        Rectangle {
            required property int index
            readonly property real value: Cava.values[index] ?? 0
            readonly property real barWidth: (root.width - root.spacing * (root.count - 1)) / root.count

            x: index * (barWidth + root.spacing)
            width: barWidth
            height: Math.max(root.minHeight, value * root.height)
            y: root.mirrored ? (root.height - height) / 2 : root.height - height
            radius: width / 2
            // blend the two colours by the bar's place in the row
            color: Qt.tint(root.colorFrom, Qt.alpha(root.colorTo, index / Math.max(1, root.count - 1)))
            // cava already smooths; a short animation hides the frame steps
            Behavior on height { NumberAnimation { duration: 50 } }
        }
    }
}
