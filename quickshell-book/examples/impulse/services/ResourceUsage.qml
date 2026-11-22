pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real cpuUsage: 0
    property real memoryUsedPercentage: 0
    property real swapUsedPercentage: 0
    property var last: null

    Timer {
        running: true
        interval: 3000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload(); mem.reload();
            const f = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0);
            if (root.last) root.cpuUsage = 1 - (idle - root.last.idle) / Math.max(1, total - root.last.total);
            root.last = { idle, total };
            const t = mem.text();
            const get = k => parseInt((t.match(new RegExp(k + ":\\s+(\\d+)")) ?? [0, 0])[1]);
            root.memoryUsedPercentage = 1 - get("MemAvailable") / Math.max(1, get("MemTotal"));
            root.swapUsedPercentage = get("SwapTotal") > 0 ? 1 - get("SwapFree") / get("SwapTotal") : 0;
        }
    }
    FileView { id: stat; path: "/proc/stat" }
    FileView { id: mem; path: "/proc/meminfo" }
}
