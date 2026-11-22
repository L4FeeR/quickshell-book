import QtQuick
import qs.config

// A Material Symbols glyph. `text` is the icon name, e.g. "wifi". `fill` 0..1 animates outlined -> filled.
StyledText {
    property real fill: 0

    font.family: Tokens.font.material
    font.pixelSize: Tokens.font.size.larger
    font.variableAxes: ({ "FILL": fill })

    Behavior on fill {
        Anim { type: Anim.Effects }
    }
}
