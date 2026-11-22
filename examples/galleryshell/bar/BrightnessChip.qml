import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property real level: 0                          // 0..1
    property string device: ""                      // "" = brightnessctl's default backlight

    function args(extra: list<string>): list<string> {
        return device ? ["brightnessctl", "-d", device].concat(extra) : ["brightnessctl"].concat(extra)
    }
    function set(v: real): void {
        level = Math.max(0.01, Math.min(1, v))
        Quickshell.execDetached(args(["-q", "set", Math.round(level * 100) + "%"]))
    }

    // brightnessctl -m prints: name,class,current,percent,max  e.g. "intel_backlight,backlight,400,42%,960"
    Process {
        id: read
        command: root.args(["-m"])
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",")
                if (f.length >= 5) root.level = Number(f[2]) / Number(f[4])
            }
        }
    }
    // other tools (keys, other widgets) may change it too: re-read now and then
    Timer { interval: 5000; running: true; repeat: true; onTriggered: read.running = true }

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26
    radius: height / 2
    color: hover.hovered ? "#45475a" : "#313244"

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Text {
            text: root.level > 0.66 ? "brightness_high" : root.level > 0.33 ? "brightness_medium" : "brightness_low"
            font.family: "Material Symbols Rounded"; font.pixelSize: 18
            color: "#f9e2af"
        }
        Text {
            text: Math.round(root.level * 100) + "%"
            color: "#cdd6f4"; font.pixelSize: 12
            font.features: ({ "tnum": 1 })
        }
    }

    HoverHandler { id: hover }
    WheelHandler { onWheel: e => root.set(root.level + e.angleDelta.y / 120 * 0.05) }
    TapHandler { onTapped: root.set(root.level > 0.5 ? 0.2 : 1) }
}
