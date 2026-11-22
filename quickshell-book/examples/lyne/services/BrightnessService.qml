pragma Singleton
import QtQuick
import Quickshell
import qs.services
import Quickshell.Io

// Laptop screen brightness through brightnessctl.
Singleton {
    id: root

    property real brightness: 0           // 0..1
    property bool available: false        // false on desktops without a backlight
    readonly property real step: 0.05

    function setBrightness(v) {
        brightness = Math.max(0.01, Math.min(1, v));
        Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(brightness * 100) + "%"]);
    }
    function increaseBrightness() { setBrightness(brightness + step); }
    function decreaseBrightness() { setBrightness(brightness - step); }

    // `brightnessctl -m` prints "name,class,current,percent,max"
    Process {
        id: reader
        running: true
        command: ["brightnessctl", "-m", "-c", "backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                root.available = f.length >= 5;
                if (root.available)
                    root.brightness = Number(f[2]) / Number(f[4]);
            }
        }
    }
    Timer { interval: 10000; running: root.available; repeat: true; onTriggered: reader.running = true }
}
