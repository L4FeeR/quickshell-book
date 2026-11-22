import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root
    anchors { top: true; right: true }
    margins { top: 380; right: 80 }
    implicitWidth: 360; implicitHeight: 150
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Bottom

    property var points: []          // last 60 samples, 0..1
    property var last: null
    FileView { id: stat; path: "/proc/stat" }
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            stat.reload()
            const f = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
            const idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0)
            if (root.last) root.points = [...root.points, 1 - (idle - root.last.idle) / Math.max(1, total - root.last.total)].slice(-60)
            root.last = { idle, total }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 20; color: "#cc1e1e2e"
        Text { x: 18; y: 14; text: "CPU · 60s"; color: "#cba6f7"; font.pixelSize: 12; font.bold: true }
        Text { anchors.right: parent.right; anchors.rightMargin: 18; y: 14
               text: Math.round((root.points[root.points.length - 1] ?? 0) * 100) + "%"; color: "#cdd6f4"; font.pixelSize: 12 }
        Canvas {
            id: c
            anchors { fill: parent; margins: 18; topMargin: 40 }
            onPaint: {
                const ctx = getContext("2d"); ctx.reset()
                ctx.strokeStyle = "#313244"; ctx.lineWidth = 1
                for (const g of [0.33, 0.66]) { ctx.beginPath(); ctx.moveTo(0, height * g); ctx.lineTo(width, height * g); ctx.stroke() }
                const p = root.points; if (p.length < 2) return
                const step = width / 59, x0 = width - (p.length - 1) * step
                const xy = i => [x0 + i * step, height - p[i] * height]
                ctx.beginPath(); ctx.moveTo(...xy(0))
                for (let i = 1; i < p.length; i++) {                    // smooth curve through midpoints
                    const [x1, y1] = xy(i - 1), [x2, y2] = xy(i)
                    ctx.quadraticCurveTo(x1, y1, (x1 + x2) / 2, (y1 + y2) / 2)
                }
                ctx.lineTo(...xy(p.length - 1))
                ctx.strokeStyle = "#cba6f7"; ctx.lineWidth = 2.5; ctx.lineJoin = "round"; ctx.stroke()
                ctx.lineTo(width, height); ctx.lineTo(x0, height); ctx.closePath()
                const grad = ctx.createLinearGradient(0, 0, 0, height)
                grad.addColorStop(0, "#66cba6f7"); grad.addColorStop(1, "#00cba6f7")
                ctx.fillStyle = grad; ctx.fill()
            }
            Connections { target: root; function onPointsChanged() { c.requestPaint() } }
        }
    }
}
