import QtQuick
import qs.config

// An icon: one Nerd Font glyph, sized like the other icons.
//   Glyph { text: Icons.bell }
StyledText {
    font.pixelSize: Config.fontSizeIconSmall
    horizontalAlignment: Text.AlignHCenter
    elide: Text.ElideNone
}
