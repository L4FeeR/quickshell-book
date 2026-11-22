import QtQuick
import QtQuick.Effects

// Click ripples for any item, clipped to its rounded shape. Put it inside the
// item as the last child:
//   Rectangle { radius: 14; …; ClickRipple { radius: 14; onClicked: … } }
// It takes the clicks itself (and passes them on through `clicked`), and adds
// a soft hover highlight.
Item {
    id: root

    property real radius: 0
    property color tint: "white"
    property bool hoverHighlight: true
    signal clicked(var mouse)

    anchors.fill: parent

    // the ripples live in a layer masked by a rounded rectangle, so they
    // never spill past the corners (plain `clip` would only cut a square)
    Item {
        id: content
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
        }
        Rectangle {                        // hover highlight
            anchors.fill: parent
            color: root.tint
            opacity: root.hoverHighlight && area.containsMouse ? 0.06 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
        RippleLayer {
            id: ripples
            anchors.fill: parent
            tint: root.tint
            endSize: Math.hypot(root.width, root.height) * 2.2   // always reaches the far corner
        }
    }
    Rectangle {                            // the mask's shape
        id: mask
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: m => ripples.burst(m.x, m.y)
        onClicked: m => root.clicked(m)
    }
}
