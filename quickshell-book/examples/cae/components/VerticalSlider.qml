import QtQuick
import QtQuick.Controls
import qs.config
import qs.services

// A thick vertical slider with an icon at the bottom, filled from the bottom (used by the OSD).
Slider {
    id: root

    property string icon

    orientation: Qt.Vertical
    implicitWidth: 44
    implicitHeight: Tokens.sizes.osdSliderHeight
    from: 0
    to: 1

    background: StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.full
        color: Colours.palette.m3surfaceContainerHigh

        StyledRect {
            anchors.bottom: parent.bottom
            width: parent.width
            height: Math.max(width, parent.height * root.position)
            radius: parent.radius
            color: Colours.palette.m3primary

            Behavior on height {
                enabled: !root.pressed
                Anim { type: Anim.FastSpatial }
            }
        }
    }

    handle: Item {}

    MaterialIcon {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.padding.small + 2
        text: root.icon
        fill: 1
        color: Colours.palette.m3onPrimary
    }
}
