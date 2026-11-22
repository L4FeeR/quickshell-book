pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property string time: Qt.formatDateTime(clock.date, "hh:mm")
    readonly property string date: Qt.formatDateTime(clock.date, "dddd, dd/MM")
    readonly property date now: clock.date
    property string uptime: ""

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Timer {
        running: true; interval: 60000; repeat: true; triggeredOnStart: true
        onTriggered: { up.reload(); const s = parseFloat(up.text()); root.uptime = (s >= 86400 ? Math.floor(s / 86400) + "d, " : "") + Math.floor(s % 86400 / 3600) + "h, " + Math.floor(s % 3600 / 60) + "m" }
    }
    FileView { id: up; path: "/proc/uptime" }
}
