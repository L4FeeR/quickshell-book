import QtQuick
import qs.services

// Text in the theme's text colour (fading on theme changes).
Text {
    color: Theme.colors.text
    font.family: "Rubik"
    font.pixelSize: 13
    Behavior on color {
        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
    }
}
