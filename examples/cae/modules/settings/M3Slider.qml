import QtQuick
import QtQuick.Controls
import qs.config
import qs.services
import qs.components
import qs.modules.settings

// A Material 3 slider: a thick active track, a gap, the inactive track, and a thin handle.
Slider {
    id: root

    implicitWidth: 220
    implicitHeight: 32

    background: Item {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: 16

        StyledRect {
            width: Math.max(0, root.visualPosition * parent.width - 6)
            height: parent.height
            radius: 8
            color: Colours.palette.m3primary
        }
        StyledRect {
            x: root.visualPosition * parent.width + 6
            width: Math.max(0, parent.width - x)
            height: parent.height
            radius: 8
            color: Colours.palette.m3secondaryContainer
        }
    }

    handle: StyledRect {
        x: root.leftPadding + root.visualPosition * root.availableWidth - width / 2
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: 4
        height: 32
        radius: 2
        color: Colours.palette.m3primary
    }
}
