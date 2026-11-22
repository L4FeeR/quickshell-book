import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property real totalKb: 1
    property real usedKb: 0
    property real swapTotalKb: 0
    property real swapUsedKb: 0
    readonly property real ratio: usedKb / totalKb

    function field(text, key) {
        const m = text.match(new RegExp("^" + key + ":\\s+(\\d+)", "m"))
        return m ? parseInt(m[1]) : 0
    }

    FileView { id: mem; path: "/proc/meminfo" }
    Timer {
        interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            mem.reload()
            const t = mem.text()
            root.totalKb = root.field(t, "MemTotal") || 1
            root.usedKb = root.totalKb - root.field(t, "MemAvailable")      // "available" counts reclaimable cache
            root.swapTotalKb = root.field(t, "SwapTotal")
            root.swapUsedKb = root.swapTotalKb - root.field(t, "SwapFree")
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
        Text { text: "RAM"; color: "#94e2d5"; font.pixelSize: 11; font.bold: true }
        Rectangle {
            implicitWidth: 60; implicitHeight: 6; radius: 3; color: "#45475a"
            Rectangle {
                width: parent.width * root.ratio; height: parent.height; radius: 3
                color: root.ratio > 0.9 ? "#f38ba8" : root.ratio > 0.75 ? "#f9e2af" : "#94e2d5"
                Behavior on width { NumberAnimation { duration: 400 } }
            }
        }
        Text {
            text: hover.hovered && root.swapTotalKb > 0
                  ? "swap " + (root.swapUsedKb / 1048576).toFixed(1) + "G"
                  : (root.usedKb / 1048576).toFixed(1) + "/" + Math.round(root.totalKb / 1048576) + "G"
            color: "#cdd6f4"; font.pixelSize: 12; font.features: ({ "tnum": 1 })
        }
    }
    HoverHandler { id: hover }
}
