import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string host: "1.1.1.1"
    property real ms: -1                         // -1 = unreachable

    Process {
        id: ping
        command: ["ping", "-c", "1", "-W", "2", root.host]
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/time=([\d.]+)/)
                root.ms = m ? parseFloat(m[1]) : -1
            }
        }
        onExited: code => { if (code !== 0) root.ms = -1 }
    }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: ping.running = true }

    readonly property color tint: ms < 0 ? "#f38ba8" : ms < 60 ? "#a6e3a1" : ms < 150 ? "#f9e2af" : "#fab387"

    implicitWidth: row.implicitWidth + 24; implicitHeight: 26; radius: 13; color: "#313244"
    RowLayout {
        id: row; anchors.centerIn: parent; spacing: 6
        Rectangle { implicitWidth: 8; implicitHeight: 8; radius: 4; color: root.tint
                    Behavior on color { ColorAnimation { duration: 300 } } }
        Text { text: root.ms < 0 ? "offline" : Math.round(root.ms) + " ms"; color: "#cdd6f4"; font.pixelSize: 12
               font.features: ({ "tnum": 1 }) }
    }
}
