pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Laptop backlight via /sys/class/backlight (read) and brightnessctl (write).
Singleton {
    id: root

    property string device: ""
    property real max: 1
    property real current: 0
    readonly property bool available: device !== ""
    readonly property real value: max > 0 ? current / max : 0

    function set(v: real): void {
        const pct = Math.round(Math.max(0.01, Math.min(1, v)) * 100);
        Quickshell.execDetached(["brightnessctl", "set", pct + "%"]);
    }
    function increment(): void { set(value + Config.services.brightnessStep) }
    function decrement(): void { set(value - Config.services.brightnessStep) }

    Process {
        running: true
        command: ["sh", "-c", "ls /sys/class/backlight | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: root.device = text.trim()
        }
    }

    FileView {
        path: root.available ? `/sys/class/backlight/${root.device}/max_brightness` : ""
        onLoaded: root.max = parseInt(text())
    }

    FileView {
        path: root.available ? `/sys/class/backlight/${root.device}/brightness` : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.current = parseInt(text())
    }
}
