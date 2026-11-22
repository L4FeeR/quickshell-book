import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// The current track with a progress ring around a play/pause icon. Click to play/pause,
// middle-click for next, right-click for previous.
RowLayout {
    id: root

    readonly property var player: MprisController.activePlayer
    visible: player !== null
    spacing: 6

    CircularProgress {
        value: (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1)
        size: 24
        MaterialSymbol {
            anchors.centerIn: parent
            text: root.player?.isPlaying ? "pause" : "play_arrow"
            fill: 1
            iconSize: 14
            color: Appearance.colors.colOnSecondaryContainer
        }
    }
    StyledText {
        Layout.fillWidth: true
        text: (root.player?.trackTitle ?? "") + (root.player?.trackArtist ? " • " + root.player.trackArtist : "")
        elide: Text.ElideRight
        color: Appearance.colors.colOnLayer1
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onTapped: (eventPoint, button) => {
            if (button === Qt.MiddleButton) root.player.next();
            else if (button === Qt.RightButton) root.player.previous();
            else root.player.togglePlaying();
        }
    }
}
