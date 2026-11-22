import QtQuick
import qs.modules.common

// A Material Symbols icon. `iconSize` sets the size, `fill` animates outlined -> filled.
StyledText {
    property real iconSize: Appearance.font.pixelSize.normal
    property real fill: 0

    font.family: Appearance.font.family.iconMaterial
    font.pixelSize: iconSize
    font.variableAxes: ({ "FILL": fill })

    Behavior on fill {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
}
