import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.services
import qs.components

// Wallpaper (crossfading when it changes) and a desktop clock, on the Background layer.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData
        property bool showA: true

        screen: modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: Colours.palette.m3surfaceContainerLowest
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "cae-background"

        Connections {
            target: Wallpapers
            function onCurrentChanged(): void { (win.showA ? b : a).source = win.target }
        }

        component Wall: Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(win.width * win.modelData.devicePixelRatio, win.height * win.modelData.devicePixelRatio)
            Behavior on opacity { Anim { type: Anim.Effects; duration: 800 } }
        }
        readonly property string target: Wallpapers.current ? "file://" + Wallpapers.current : ""
        // whichever image finishes loading the current wallpaper becomes the visible one
        Wall { id: a; opacity: win.showA ? 1 : 0; onStatusChanged: if (status === Image.Ready && source.toString() === win.target) win.showA = true }
        Wall { id: b; opacity: win.showA ? 0 : 1; onStatusChanged: if (status === Image.Ready && source.toString() === win.target) win.showA = false }
        Component.onCompleted: a.source = target

        // desktop clock, bottom-left inside the frame
        Column {
            x: Tokens.sizes.barInnerWidth + Config.border.thickness * 4
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Config.border.thickness * 4
            StyledText {
                text: Time.format("hh:mm")
                font.pixelSize: 96
                font.weight: 700
                color: Colours.palette.m3primary
            }
            StyledText {
                text: Time.format("dddd, d MMMM")
                font.pixelSize: Tokens.font.size.large
                color: Colours.palette.m3onSurface
            }
        }
    }
}
