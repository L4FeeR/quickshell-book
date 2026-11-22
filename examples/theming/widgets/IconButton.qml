import QtQuick
import qs.services

// A round button with an icon. `active` fills it with the theme's primary colour.
TRect {
    id: root

    property alias icon: label.text
    property bool active: false
    property string tooltip: ""
    signal clicked()

    implicitWidth: 30
    implicitHeight: 30
    radius: height / 2
    color: active ? Theme.colors.primary : hover.hovered ? Theme.colors.surfaceHigh : "transparent"

    Icon {
        id: label
        anchors.centerIn: parent
        fill: root.active ? 1 : 0
        color: root.active ? Theme.colors.onPrimary : Theme.colors.text
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.clicked() }
}
