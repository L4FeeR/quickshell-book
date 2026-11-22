import QtQuick
import qs.config
import qs.services

Text {
    color: Colours.palette.m3onSurface
    font.family: Tokens.font.sans
    font.pixelSize: Tokens.font.size.normal
    renderType: Text.NativeRendering

    Behavior on color {
        CAnim {}
    }
}
