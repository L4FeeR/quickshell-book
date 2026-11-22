import QtQuick
import QtQuick.Layouts

// Click: start/pause. Right-click: reset. Shows mm:ss (and h: once past an hour).
Rectangle {
    id: root
    property bool running: false
    property real elapsed: 0          // ms counted before the current run
    property real startedAt: 0        // Date.now() when the current run started
    property real now: Date.now()

    readonly property real total: elapsed + (running ? now - startedAt : 0)

    function fmt(ms: real): string {
        const s = Math.floor(ms / 1000), h = Math.floor(s / 3600), m = Math.floor(s / 60) % 60
        const pad = n => String(n).padStart(2, "0")
        return (h > 0 ? h + ":" : "") + pad(m) + ":" + pad(s % 60)
    }
    function toggle(): void {
        if (running) { elapsed += Date.now() - startedAt; running = false }
        else { startedAt = Date.now(); now = startedAt; running = true }
    }

    // only ticks while running: a stopped stopwatch costs nothing
    Timer { interval: 200; running: root.running; repeat: true; onTriggered: root.now = Date.now() }

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26
    radius: height / 2
    color: root.running ? "#a6e3a1" : hover.hovered ? "#45475a" : "#313244"
    Behavior on color { ColorAnimation { duration: 150 } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Text {
            text: root.running ? "pause" : "timer"
            font.family: "Material Symbols Rounded"; font.pixelSize: 18
            color: root.running ? "#1e1e2e" : "#cdd6f4"
        }
        Text {
            text: root.fmt(root.total)
            color: root.running ? "#1e1e2e" : "#cdd6f4"; font.pixelSize: 12
            font.features: ({ "tnum": 1 })
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.toggle() }
    TapHandler { acceptedButtons: Qt.RightButton; onTapped: { root.running = false; root.elapsed = 0 } }
}
