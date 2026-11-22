import QtQuick
import qs.config

// Text in the shell's font and colour. Every label in the shell uses it.
Text {
    color: Config.textColor
    font.family: Config.font
    font.pixelSize: Config.fontSizeNormal
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
