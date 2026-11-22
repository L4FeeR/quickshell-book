import QtQuick

// The stretchy pill from the workspace indicators: it moves between targets
// with its two edges travelling at different speeds, so it stretches across
// and snaps back. Set `target` to any item in the same parent.
//   StretchPill { target: tabs.currentItem }
Rectangle {
    id: root

    property Item target: null
    property int fast: 140                 // the edge in front
    property int slow: 320                 // the edge behind
    property real padding: 0

    readonly property real goalLeft: target ? target.x - padding : 0
    readonly property real goalRight: target ? target.x + target.width + padding : 0
    property real leftEdge: goalLeft
    property real rightEdge: goalRight
    property int direction: 0

    x: leftEdge
    width: Math.max(0, rightEdge - leftEdge)
    radius: height / 2

    onGoalLeftChanged: direction = goalLeft > leftEdge ? 1 : -1
    // moving right: the right edge leads; moving left: the left edge leads
    Behavior on leftEdge { NumberAnimation { duration: root.direction < 0 ? root.fast : root.slow; easing.type: Easing.OutCubic } }
    Behavior on rightEdge { NumberAnimation { duration: root.direction > 0 ? root.fast : root.slow; easing.type: Easing.OutCubic } }
}
