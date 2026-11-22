import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

// For your bar: tiny live bars and the current lyric (or the song title when
// there are no lyrics). Click to play/pause, scroll to skip.
//   in any bar's RowLayout:  MusicChip {}
Rectangle {
    id: root

    visible: Player.active !== null
    implicitWidth: row.implicitWidth + 20
    implicitHeight: 28
    radius: height / 2
    color: Qt.alpha(ArtColors.accent, 0.18)
    Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8
        VisualizerBars {
            implicitWidth: 34
            implicitHeight: 16
            Layout.preferredWidth: 34
            Layout.preferredHeight: 16
            mirrored: true
            spacing: 2
            colorFrom: ArtColors.accent
            colorTo: Qt.lighter(ArtColors.accent, 1.4)
        }
        LyricsLine {
            Layout.preferredWidth: Math.min(360, implicitWidth)
            visible: Lyrics.currentText !== ""
        }
        Text {
            visible: Lyrics.currentText === ""
            text: Player.title + (Player.artist ? "  ·  " + Player.artist : "")
            color: "white"
            font.pixelSize: 13
            elide: Text.ElideRight
            Layout.maximumWidth: 300
        }
    }
    TapHandler { onTapped: Player.active.togglePlaying() }
    WheelHandler { onWheel: e => e.angleDelta.y > 0 ? Player.active.previous() : Player.active.next() }
}
