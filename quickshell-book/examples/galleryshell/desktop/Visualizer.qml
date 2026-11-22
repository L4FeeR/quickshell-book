import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick

PanelWindow {
    id: root
    anchors { bottom: true; left: true; right: true }
    implicitHeight: 160
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Bottom

    property int bars: 32
    property var values: []
    readonly property bool playing: Mpris.players.values.some(p => p.isPlaying)

    // write a tiny raw-output config to the runtime dir, then run cava with it
    Process {
        running: root.playing
        command: ["sh", "-c", `conf="$XDG_RUNTIME_DIR/qs-cava.conf"
printf '[general]\\nbars = %s\\nframerate = 50\\n[output]\\nmethod = raw\\nraw_target = /dev/stdout\\ndata_format = ascii\\nascii_max_range = 100\\nbar_delimiter = 59\\n' "${root.bars}" > "$conf"
exec cava -p "$conf"`]
        stdout: SplitParser { onRead: line => root.values = line.split(";").filter(s => s !== "").map(Number) }
        onRunningChanged: if (!running) root.values = []
    }

    Row {
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 10 }
        spacing: 6
        Repeater {
            model: root.bars
            Rectangle {
                required property int index
                anchors.bottom: parent.bottom
                width: 12; radius: 5
                height: Math.max(4, 140 * (root.values[index] ?? 0) / 100)
                // gradient from mauve to teal across the bars
                color: Qt.hsla(0.75 - 0.27 * index / root.bars, 0.75, 0.78, 0.9)
                Behavior on height { NumberAnimation { duration: 60 } }
            }
        }
    }
}
