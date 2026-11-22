import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property real usage: 0             // 0..1
    property var history: []           // last N samples
    property var last: null
    property int samples: 30

    FileView { id: stat; path: "/proc/stat" }
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            stat.reload()
            // first line: "cpu  user nice system idle iowait irq softirq steal ..."
            const f = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
            const idle = f[3] + f[4]
            const total = f.reduce((a, b) => a + b, 0)
            if (root.last) {
                const dTotal = total - root.last.total
                root.usage = dTotal > 0 ? 1 - (idle - root.last.idle) / dTotal : 0
                root.history = [...root.history, root.usage].slice(-root.samples)
            }
            root.last = { total, idle }
        }
    }

    implicitWidth: row.implicitWidth + 24
    implicitHeight: 26
    radius: height / 2
    color: "#313244"

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Text { text: "CPU"; color: "#cba6f7"; font.pixelSize: 11; font.bold: true }
        Text { text: Math.round(root.usage * 100) + "%"; color: root.usage > 0.85 ? "#f38ba8" : "#cdd6f4"
               font.pixelSize: 12; font.bold: true; font.features: ({ "tnum": 1 }); Layout.preferredWidth: 32 }
        Canvas {
            id: spark
            implicitWidth: 70; implicitHeight: 16
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const h = root.history
                if (h.length < 2) return
                const step = width / (root.samples - 1)
                const x0 = width - (h.length - 1) * step
                ctx.beginPath()
                h.forEach((v, i) => { const x = x0 + i * step, y = height - v * height; i ? ctx.lineTo(x, y) : ctx.moveTo(x, y) })
                ctx.strokeStyle = "#cba6f7"; ctx.lineWidth = 1.5; ctx.lineJoin = "round"
                ctx.stroke()
                ctx.lineTo(width, height); ctx.lineTo(x0, height); ctx.closePath()
                ctx.fillStyle = "#33cba6f7"; ctx.fill()
            }
            Connections { target: root; function onHistoryChanged() { spark.requestPaint() } }
        }
    }
}
