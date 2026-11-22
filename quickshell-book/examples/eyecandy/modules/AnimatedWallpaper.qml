import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower

// A video as your wallpaper, looping and silent, drawn by the shell on the
// background layer. To save power and GPU time it pauses when a window is
// fullscreen (you can't see it anyway) and while on battery.
//   AnimatedWallpaper { source: "/home/you/Videos/wall.mp4" }
Variants {
    id: root

    property string source: Quickshell.env("HOME") + "/Videos/wallpaper.mp4"
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "black"
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "eyecandy_wallpaper"

        // is the workspace shown on this monitor in fullscreen?
        readonly property bool covered: Hyprland.monitorFor(modelData)?.activeWorkspace?.hasFullscreen ?? false
        readonly property bool paused: covered || UPower.onBattery

        Video {
            id: video
            anchors.fill: parent
            source: "file://" + root.source
            fillMode: VideoOutput.PreserveAspectCrop
            loops: MediaPlayer.Infinite
            muted: true
            autoPlay: true
        }
        onPausedChanged: paused ? video.pause() : video.play()
    }
}
