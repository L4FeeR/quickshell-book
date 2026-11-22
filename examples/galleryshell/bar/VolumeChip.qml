import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real vol: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    PwObjectTracker { objects: [root.sink] }          // REQUIRED to read/write audio

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26
    radius: height / 2
    color: hover.hovered ? "#45475a" : "#313244"

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Text {
            text: root.muted ? "volume_off" : root.vol > 0.6 ? "volume_up" : root.vol > 0 ? "volume_down" : "volume_mute"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 18
            color: root.muted ? "#f38ba8" : "#cdd6f4"
        }
        Rectangle {
            implicitWidth: 60; implicitHeight: 4; radius: 2
            color: "#45475a"
            Rectangle {
                width: parent.width * Math.min(1, root.muted ? 0 : root.vol)
                height: parent.height; radius: 2
                color: root.vol > 1 ? "#f38ba8" : "#89b4fa"
                Behavior on width { NumberAnimation { duration: 120 } }
            }
        }
        Text {
            text: Math.round(root.vol * 100) + "%"
            color: "#cdd6f4"; font.pixelSize: 12
            font.features: ({ "tnum": 1 })
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: if (root.sink?.ready) root.sink.audio.muted = !root.muted }
    TapHandler { acceptedButtons: Qt.RightButton; onTapped: Quickshell.execDetached(["pavucontrol"]) }
    WheelHandler {
        onWheel: e => {
            if (!root.sink?.ready) return
            root.sink.audio.volume = Math.max(0, Math.min(1.5, root.vol + e.angleDelta.y / 120 * 0.05))
        }
    }
}
