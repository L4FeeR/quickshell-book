import QtQuick
import qs.services

// Material "state layer": a tinted overlay that shows hover (8%) and press (12%).
// Put it inside any rounded item; it fills it and reports clicks.
MouseArea {
    id: root

    property color color: Colours.palette.m3onSurface
    property real radius: parent?.radius ?? 0
    property bool disabled: false

    anchors.fill: parent
    enabled: !disabled
    hoverEnabled: true
    cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor

    StyledRect {
        anchors.fill: parent
        radius: root.radius
        color: Qt.alpha(root.color, root.pressed ? 0.12 : root.containsMouse ? 0.08 : 0)
    }
}
