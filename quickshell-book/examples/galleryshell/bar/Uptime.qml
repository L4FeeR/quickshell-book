import Quickshell.Io
import QtQuick

Rectangle {
    id: root
    property int secs: 0
    readonly property string label: {
        const d = Math.floor(secs / 86400), h = Math.floor(secs % 86400 / 3600), m = Math.floor(secs % 3600 / 60)
        return (d ? d + "d " : "") + (d || h ? h + "h " : "") + m + "m"
    }
    FileView { id: up; path: "/proc/uptime" }
    Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: { up.reload(); root.secs = parseFloat(up.text().split(" ")[0]) } }

    implicitWidth: t.implicitWidth + 24; implicitHeight: 26; radius: 13; color: "#313244"
    Text { id: t; anchors.centerIn: parent; text: "⏱ " + root.label; color: "#cdd6f4"; font.pixelSize: 12 }
}
