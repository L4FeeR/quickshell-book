import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool muted: source?.audio?.muted ?? true
    readonly property real vol: source?.audio?.volume ?? 0
    // any app currently recording from a microphone?
    readonly property bool inUse: Pipewire.nodes.values.some(n => n.isStream && !n.isSink && n.audio)

    PwObjectTracker { objects: [root.source] }

    visible: source !== null
    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26
    radius: height / 2
    color: root.muted ? "#45475a" : root.inUse ? "#f38ba8" : hover.hovered ? "#45475a" : "#313244"
    Behavior on color { ColorAnimation { duration: 150 } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Text {
            text: root.muted ? "mic_off" : "mic"
            font.family: "Material Symbols Rounded"; font.pixelSize: 18
            color: root.inUse && !root.muted ? "#1e1e2e" : root.muted ? "#6c7086" : "#cdd6f4"
        }
        Text {
            visible: hover.hovered
            text: Math.round(root.vol * 100) + "%"
            color: root.inUse && !root.muted ? "#1e1e2e" : "#cdd6f4"; font.pixelSize: 12
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: if (root.source?.ready) root.source.audio.muted = !root.muted }
    WheelHandler {
        onWheel: e => { if (root.source?.ready) root.source.audio.volume = Math.max(0, Math.min(1, root.vol + e.angleDelta.y / 120 * 0.05)) }
    }
}
