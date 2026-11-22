pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root
    readonly property MprisPlayer activePlayer: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    Timer {
        running: root.activePlayer?.isPlaying ?? false
        interval: 1000
        repeat: true
        onTriggered: root.activePlayer.positionChanged()
    }
}
