import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    // prefer a playing player, otherwise the first one
    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property string line: player ? (player.trackArtist ? player.trackArtist + " — " : "") + player.trackTitle : ""
    property int textWidth: 160                      // visible width of the scrolling text

    visible: player !== null && line !== ""
    implicitWidth: row.implicitWidth + 16
    implicitHeight: 26
    radius: height / 2
    color: "#313244"

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4
        Text {
            text: "skip_previous"; font.family: "Material Symbols Rounded"; font.pixelSize: 18
            color: root.player?.canGoPrevious ? "#cdd6f4" : "#585b70"
            TapHandler { onTapped: root.player.previous() }
        }
        Text {
            text: root.player?.isPlaying ? "pause" : "play_arrow"
            font.family: "Material Symbols Rounded"; font.pixelSize: 20; color: "#cba6f7"
            TapHandler { onTapped: root.player.togglePlaying() }
        }
        Text {
            text: "skip_next"; font.family: "Material Symbols Rounded"; font.pixelSize: 18
            color: root.player?.canGoNext ? "#cdd6f4" : "#585b70"
            TapHandler { onTapped: root.player.next() }
        }

        // the window the text scrolls through
        Item {
            id: viewport
            Layout.preferredWidth: Math.min(root.textWidth, label.implicitWidth)
            implicitHeight: 26
            clip: true
            readonly property bool overflow: label.implicitWidth > root.textWidth

            Row {
                id: strip
                anchors.verticalCenter: parent.verticalCenter
                spacing: 40
                Text { id: label; text: root.line; color: "#cdd6f4"; font.pixelSize: 12 }
                Text { visible: viewport.overflow; text: root.line; color: "#cdd6f4"; font.pixelSize: 12 }   // seamless loop copy

                NumberAnimation on x {
                    running: viewport.overflow && (root.player?.isPlaying ?? false)
                    from: 0; to: -(label.implicitWidth + strip.spacing)
                    duration: (label.implicitWidth + strip.spacing) * 30      // ~33 px per second
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) strip.x = 0
                }
            }
        }
    }
}
