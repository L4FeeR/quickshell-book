import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property real down: 0              // bytes per second
    property real up: 0
    property real totalDown: 0
    property real totalUp: 0
    property string iface: ""
    property var last: null            // previous sample { rx, tx, t }

    function fmt(bps: real): string {
        const units = ["B/s", "KB/s", "MB/s", "GB/s"]
        let i = 0
        while (bps >= 1024 && i < units.length - 1) { bps /= 1024; i++ }
        return (bps >= 100 || i === 0 ? Math.round(bps) : bps.toFixed(1)) + " " + units[i]
    }
    function fmtBytes(b: real): string {
        const u = ["B", "KB", "MB", "GB", "TB"]; let i = 0
        while (b >= 1024 && i < u.length - 1) { b /= 1024; i++ }
        return b.toFixed(1) + " " + u[i]
    }

    FileView { id: netdev; path: "/proc/net/dev" }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            netdev.reload()
            // lines look like: "  wlan0: 123456 789 0 0 0 0 0 0 654321 ..."
            let rx = 0, tx = 0, names = []
            for (const line of netdev.text().split("\n").slice(2)) {
                const m = line.trim().match(/^([^:]+):\s*(.*)$/)
                if (!m) continue
                const name = m[1]
                if (name === "lo" || name.startsWith("veth") || name.startsWith("docker") || name.startsWith("br-") || name.startsWith("virbr")) continue
                const f = m[2].split(/\s+/).map(Number)
                rx += f[0]; tx += f[8]               // field 0 = received bytes, field 8 = sent bytes
                if (f[0] > 0) names.push(name)
            }
            const now = Date.now()
            if (root.last) {
                const dt = (now - root.last.t) / 1000
                root.down = Math.max(0, (rx - root.last.rx) / dt)
                root.up = Math.max(0, (tx - root.last.tx) / dt)
            }
            root.last = { rx, tx, t: now }
            root.totalDown = rx; root.totalUp = tx
            root.iface = names.join(", ")
        }
    }

    implicitWidth: row.implicitWidth + 24
    implicitHeight: 26
    radius: height / 2
    color: "#313244"

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 10
        RowLayout {
            spacing: 3
            Text { text: "↓"; color: "#89b4fa"; font.pixelSize: 13; font.bold: true }
            Text { text: root.fmt(root.down); color: "#cdd6f4"; font.pixelSize: 12; font.features: ({ "tnum": 1 })
                   Layout.preferredWidth: 64 }            // fixed width: the bar doesn't jump around
        }
        RowLayout {
            spacing: 3
            Text { text: "↑"; color: "#a6e3a1"; font.pixelSize: 13; font.bold: true }
            Text { text: root.fmt(root.up); color: "#cdd6f4"; font.pixelSize: 12; font.features: ({ "tnum": 1 })
                   Layout.preferredWidth: 64 }
        }
        Text {
            visible: hover.hovered
            text: root.iface + " · ↓" + root.fmtBytes(root.totalDown) + " ↑" + root.fmtBytes(root.totalUp)
            color: "#a6adc8"; font.pixelSize: 11
        }
    }
    HoverHandler { id: hover }
}
