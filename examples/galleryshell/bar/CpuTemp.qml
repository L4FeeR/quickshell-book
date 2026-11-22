import Quickshell.Io
import QtQuick

Rectangle {
    id: root
    property string sensorPath: ""             // found automatically
    property real temp: 0

    // find the CPU sensor: coretemp (Intel) or k10temp (AMD)
    Process {
        running: true
        command: ["sh", "-c", "for d in /sys/class/hwmon/hwmon*; do n=$(cat $d/name); case $n in coretemp|k10temp|zenpower) echo $d/temp1_input; exit;; esac; done; echo /sys/class/thermal/thermal_zone0/temp"]
        stdout: StdioCollector { onStreamFinished: root.sensorPath = text.trim().split("\n")[0] }
    }
    FileView { id: sensor; path: root.sensorPath }
    Timer {
        interval: 2000; running: root.sensorPath !== ""; repeat: true; triggeredOnStart: true
        onTriggered: { sensor.reload(); root.temp = parseInt(sensor.text()) / 1000 }
    }

    readonly property color tint: temp >= 85 ? "#f38ba8" : temp >= 70 ? "#fab387" : "#a6e3a1"

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 26
    radius: height / 2
    color: "#313244"

    Text {
        id: label
        anchors.centerIn: parent
        text: "🌡 " + Math.round(root.temp) + "°C"
        color: root.tint
        font.pixelSize: 12; font.bold: true
        SequentialAnimation on opacity { running: root.temp >= 85; loops: Animation.Infinite
            NumberAnimation { to: 0.4; duration: 500 } NumberAnimation { to: 1; duration: 500 }
            onStopped: label.opacity = 1 }
    }
}
