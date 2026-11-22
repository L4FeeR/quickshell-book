pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// The "active" media player: the one you picked, else the first playing one, else the first one.
Singleton {
    id: root

    readonly property list<MprisPlayer> list: Mpris.players.values
    property MprisPlayer manual: null
    readonly property MprisPlayer active: (manual && list.includes(manual)) ? manual
                                        : list.find(p => p.isPlaying) ?? list[0] ?? null

    // MPRIS doesn't push position updates; poke the player once a second while playing.
    Timer {
        running: root.active?.isPlaying ?? false
        interval: 1000
        repeat: true
        onTriggered: root.active.positionChanged()
    }
}
