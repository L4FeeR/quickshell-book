import QtQuick

// One ripple: a circle that grows from a point and fades out, then removes
// itself. RippleLayer creates these; you rarely use it directly.
Rectangle {
    id: root

    property real centerX: 0
    property real centerY: 0
    property real endSize: 200            // diameter at the end
    property int duration: 600
    property real startOpacity: 0.35
    property bool ring: false             // true: an outline that expands, false: a filled circle
    property color tint: "white"

    width: endSize
    height: endSize
    radius: endSize / 2
    x: centerX - endSize / 2
    y: centerY - endSize / 2
    color: ring ? "transparent" : tint
    border.width: ring ? 3 : 0
    border.color: tint
    scale: 0
    opacity: startOpacity

    // grow and fade at the same time; when both are done, destroy the ripple
    ParallelAnimation {
        running: true
        NumberAnimation { target: root; property: "scale"; from: 0; to: 1; duration: root.duration; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "opacity"; from: root.startOpacity; to: 0; duration: root.duration; easing.type: Easing.InQuad }
        onFinished: root.destroy()
    }
}
