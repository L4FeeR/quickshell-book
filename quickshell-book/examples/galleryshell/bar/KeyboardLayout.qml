import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Rectangle {
    id: root
    property string layout: "??"

    function shortName(full: string): string {        // "English (US)" → "US"
        const m = full.match(/\(([^)]+)\)/)
        return (m ? m[1] : full.slice(0, 2)).toUpperCase().slice(0, 3)
    }

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 26
    radius: height / 2
    color: "#313244"

    Text { id: label; anchors.centerIn: parent; text: "⌨  " + root.layout; color: "#cdd6f4"; font.pixelSize: 12; font.bold: true }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout") root.layout = root.shortName(event.parse(2)[1])
        }
    }
    // read the initial layout once
    Process {
        running: true
        command: ["sh", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main) | .active_keymap'"]
        stdout: StdioCollector { onStreamFinished: if (text.trim()) root.layout = root.shortName(text.trim()) }
    }
    TapHandler { onTapped: Hyprland.dispatch("switchxkblayout all next") }
}
