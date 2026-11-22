import Quickshell
import QtQuick

Rectangle {
    id: root
    readonly property bool expanded: hover.hovered

    SystemClock { id: clock; precision: SystemClock.Minutes }

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 26
    radius: height / 2
    color: "#313244"
    clip: true
    Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    Text {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, root.expanded ? "ddd d MMM  ·  hh:mm" : "hh:mm")
        color: "#cdd6f4"
        font.pixelSize: 13
        font.bold: !root.expanded
        font.features: ({ "tnum": 1 })          // digits don't jiggle
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
}
