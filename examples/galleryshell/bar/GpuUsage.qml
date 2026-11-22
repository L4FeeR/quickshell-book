import Quickshell.Io
import QtQuick

Rectangle {
    id: root
    property int usage: 0            // %
    property real vramGb: 0
    property string vendor: ""       // "nvidia" or "amd", detected

    Process {                        // detect vendor once
        running: true
        command: ["sh", "-c", "command -v nvidia-smi >/dev/null && echo nvidia || (ls /sys/class/drm/card*/device/gpu_busy_percent >/dev/null 2>&1 && echo amd)"]
        stdout: StdioCollector { onStreamFinished: root.vendor = text.trim() }
    }
    // NVIDIA: nvidia-smi prints a line every 2 s by itself (-l 2): one long-running process
    Process {
        running: root.vendor === "nvidia"
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,memory.used", "--format=csv,noheader,nounits", "-l", "2"]
        stdout: SplitParser {
            onRead: line => { const [u, m] = line.split(",").map(s => parseFloat(s)); root.usage = u; root.vramGb = m / 1024 }
        }
    }
    // AMD: read sysfs
    FileView { id: busy; path: root.vendor === "amd" ? "/sys/class/drm/card1/device/gpu_busy_percent" : "" }
    FileView { id: vram; path: root.vendor === "amd" ? "/sys/class/drm/card1/device/mem_info_vram_used" : "" }
    Timer {
        interval: 2000; repeat: true; running: root.vendor === "amd"
        onTriggered: { busy.reload(); vram.reload(); root.usage = parseInt(busy.text()); root.vramGb = parseInt(vram.text()) / 1073741824 }
    }

    visible: vendor !== ""
    implicitWidth: label.implicitWidth + 24
    implicitHeight: 26
    radius: height / 2
    color: "#313244"
    Text {
        id: label
        anchors.centerIn: parent
        text: "GPU " + root.usage + "%  " + root.vramGb.toFixed(1) + "G"
        color: "#cdd6f4"; font.pixelSize: 12
        font.features: ({ "tnum": 1 })
    }
}
