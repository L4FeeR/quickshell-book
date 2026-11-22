pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// CPU, memory, temperature and disk usage, read from /proc and /sys (no extra programs).
Singleton {
    id: root

    property real cpu: 0          // 0..1
    property real mem: 0          // 0..1
    property real memUsedGb: 0
    property real memTotalGb: 0
    property real temp: 0         // °C
    property real disk: 0         // 0..1 for /
    property int users: 0
    property string uptime: ""
    property var last: null

    // Only poll while something shows the numbers (the dashboard sets this).
    property int refCount: 0

    Timer {
        running: root.refCount > 0
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload(); meminfo.reload(); up.reload();
            const f = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0);
            if (root.last)
                root.cpu = 1 - (idle - root.last.idle) / Math.max(1, total - root.last.total);
            root.last = { idle, total };

            const m = meminfo.text();
            const get = k => parseInt((m.match(new RegExp(k + ":\\s+(\\d+)")) ?? [0, 0])[1]);
            const tot = get("MemTotal"), avail = get("MemAvailable");
            root.mem = 1 - avail / Math.max(1, tot);
            root.memUsedGb = (tot - avail) / 1048576;
            root.memTotalGb = tot / 1048576;

            const s = parseFloat(up.text().split(" ")[0]);
            const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), mi = Math.floor(s % 3600 / 60);
            root.uptime = (d ? d + "d " : "") + (h ? h + "h " : "") + mi + "m";

            if (tempFile.path) {
                tempFile.reload();
                root.temp = parseInt(tempFile.text()) / 1000;
            }
            df.running = true;
        }
    }

    FileView { id: stat; path: "/proc/stat" }
    FileView { id: meminfo; path: "/proc/meminfo" }
    FileView { id: up; path: "/proc/uptime" }
    FileView { id: tempFile; path: "" }

    Process {
        running: true
        command: ["sh", "-c", "for d in /sys/class/hwmon/hwmon*; do case $(cat $d/name) in coretemp|k10temp|zenpower) echo $d/temp1_input; exit;; esac; done"]
        stdout: StdioCollector {
            onStreamFinished: tempFile.path = text.trim()
        }
    }

    Process {
        id: df
        command: ["df", "--output=pcent", "/"]
        stdout: StdioCollector {
            onStreamFinished: root.disk = parseInt(text.split("\n")[1]) / 100
        }
    }
}
