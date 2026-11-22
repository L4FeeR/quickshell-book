import QtQuick
import qs.config

// lyne's signature panel: it grows OUT of the bar. It is flush with the bar
// edge, the corners where it meets the bar are curved inward (fillets), and
// it slides in from behind the bar instead of fading in the middle of nowhere.
//
//      ═══════════ bar ═══════════
//           ◟ ┌────────┐ ◞      <- fillets join the panel to the bar
//             │ panel  │
//             └────────┘
//
// Give it a size and put content inside:
//   AttachedPanel { width: 300; height: 200; shown: open; edge: "top"; … }
Item {
    id: root

    property bool shown: false
    property string edge: "top"                        // the side the bar is on: "top" | "bottom"
    property color color: Config.backgroundTransparentColor
    property real radius: Config.radiusLarge
    property real filletSize: Config.radiusLarge

    default property alias content: body.data
    readonly property alias body: body
    readonly property bool onTop: edge === "top"

    // 0 = hidden behind the bar, 1 = fully out
    property real progress: 0
    // Start at 0 and only then follow `shown`, so the panel animates in even
    // when it is created already shown.
    property bool _ready: false
    Component.onCompleted: Qt.callLater(() => root._ready = true)
    on_ReadyChanged: progress = Qt.binding(() => root.shown && root._ready ? 1 : 0)
    Behavior on progress {
        NumberAnimation {
            duration: root.shown ? Config.animDurationLong : Config.animDuration
            easing.type: Easing.OutExpo
        }
    }

    // The clipper is the panel's area plus room for a fillet on each side.
    // Whatever slides past its edge (towards the bar) is cut off, so the
    // panel seems to come out from under the bar.
    Item {
        id: clipper
        x: -root.filletSize
        width: root.width + root.filletSize * 2
        height: root.height
        clip: true

        Item {
            id: slide
            x: root.filletSize
            width: root.width
            height: root.height
            y: (1 - root.progress) * (root.onTop ? -root.height : root.height)
            opacity: Math.min(1, root.progress * 2)

            // The body: rounded, except the two corners touching the bar.
            // A rounded rectangle taller than the panel, pushed past the bar
            // edge and clipped there, leaves square corners on that side.
            // (Two overlapping see-through rectangles would show a darker
            // strip where they overlap; this is one shape.)
            Item {
                anchors.fill: parent
                clip: true
                Rectangle {
                    width: parent.width
                    height: parent.height + root.radius
                    y: root.onTop ? -root.radius : 0
                    radius: root.radius
                    color: root.color
                }
            }

            // the fillets, at the bar edge, just outside the panel's sides
            ConcaveCorner {
                x: -root.filletSize
                y: root.onTop ? 0 : parent.height - root.filletSize
                size: root.filletSize
                color: root.color
                mirrored: true
                flipped: !root.onTop
            }
            ConcaveCorner {
                x: parent.width
                y: root.onTop ? 0 : parent.height - root.filletSize
                size: root.filletSize
                color: root.color
                flipped: !root.onTop
            }

            Item {
                id: body
                anchors.fill: parent
            }
        }
    }
}
