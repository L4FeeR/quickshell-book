//@ pragma UseQApplication
import QtQuick
import Quickshell
import qs.services
import qs.modules

// The eye-candy demo: a music desktop, floating lyrics, a weather card and a
// small top bar with the music chip. Each module also works on its own:
// copy the module, the widgets it uses and the services into your shell.
ShellRoot {
    MusicDesktop {}
    LyricsOverlay {}
    WeatherCard {}

    // a minimal bar, just to show the chip in context
    PanelWindow {
        anchors { top: true; left: true; right: true }
        implicitHeight: 40
        color: "transparent"
        Rectangle {
            anchors.fill: parent
            anchors.margins: 6
            radius: 14
            color: Qt.alpha("#1a1b26", 0.9)
            MusicChip { anchors.centerIn: parent }
        }
    }

    // video wallpaper: uncomment and point it at a video
    // AnimatedWallpaper { source: Quickshell.env("HOME") + "/Videos/wallpaper.mp4" }
}
