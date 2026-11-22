import QtQuick
import Quickshell.Wayland
import qs.config

// The focused window's title, shortened to fit. Hidden on an empty desktop.
StyledText {
    id: root

    readonly property var win: ToplevelManager.activeToplevel
    property int maxWidth: 300

    visible: text !== ""
    text: win?.activated ? (win.title || win.appId) : ""
    color: Config.subtextColor
    font.pixelSize: Config.fontSizeSmall
    width: Math.min(implicitWidth, maxWidth)
}
