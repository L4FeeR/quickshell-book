import QtQuick
import qs.config
import qs.services

// Round icon button. With `toggle: true`, `checked` fills it with the primary colour and morphs
// its shape from a circle to a rounded square (Material 3 expressive style). The button never
// changes `checked` itself: bind it to real state and change that state in onClicked.
StyledRect {
    id: root

    property alias icon: label.text
    property bool toggle: false
    property bool checked: false
    property int size: 40
    property color activeColour: Colours.palette.m3primary
    property color activeOnColour: Colours.palette.m3onPrimary
    property color inactiveColour: Colours.palette.m3surfaceContainerHigh
    property color inactiveOnColour: Colours.palette.m3onSurfaceVariant

    signal clicked()

    implicitWidth: size
    implicitHeight: size
    radius: toggle && checked ? Tokens.rounding.medium : size / 2
    color: toggle && checked ? activeColour : inactiveColour

    Behavior on radius {
        Anim { type: Anim.FastSpatial }
    }

    MaterialIcon {
        id: label

        anchors.centerIn: parent
        color: root.toggle && root.checked ? root.activeOnColour : root.inactiveOnColour
        fill: root.toggle && root.checked ? 1 : 0
    }

    StateLayer {
        color: label.color
        onClicked: root.clicked()
    }
}
