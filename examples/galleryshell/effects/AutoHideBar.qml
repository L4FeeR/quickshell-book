import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: bar
    property int barHeight: 40
    readonly property bool revealed: hover.hovered || ToplevelManager.activeToplevel === null || pinned
    property bool pinned: false                      // e.g. while a popup from the bar is open

    anchors { top: true; left: true; right: true }
    implicitHeight: barHeight + 10
    exclusiveZone: 0                                 // never pushes windows: it overlays
    color: "transparent"

    // when hidden, only a 3 px strip at the very top catches the mouse
    mask: Region { item: bar.revealed ? content : trigger }
    Item { id: trigger; width: parent.width; height: 3 }
    HoverHandler { id: hover }

    // a short delay before hiding avoids flicker when the pointer briefly leaves
    property bool shown: revealed
    onRevealedChanged: revealed ? (shown = true) : hideDelay.restart()
    Timer { id: hideDelay; interval: 400; onTriggered: if (!bar.revealed) bar.shown = false }

    Rectangle {
        id: content
        x: 10; width: parent.width - 20; height: bar.barHeight
        y: bar.shown ? 6 : -height - 4
        Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        radius: 14
        color: "#1e1e2e"; border.color: "#313244"
        Text { anchors.centerIn: parent; text: "auto-hide bar"; color: "#cdd6f4" }
    }
}
