import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Caps Lock and Num Lock indicators, read from the keyboard LEDs in /sys.
RowLayout {
    id: root
    spacing: 4
    property string capsPath: ""
    property string numPath: ""

    // find the LED files once: /sys/class/leds/input3::capslock/brightness etc.
    Process {
        running: true
        command: ["sh", "-c", "ls -d /sys/class/leds/*::capslock | head -1; ls -d /sys/class/leds/*::numlock | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n")
                root.capsPath = l[0] ? l[0] + "/brightness" : ""
                root.numPath = l[1] ? l[1] + "/brightness" : ""
            }
        }
    }
    FileView { id: caps; path: root.capsPath }
    FileView { id: num; path: root.numPath }
    // sysfs files don't send change notifications, so re-read them often (cheap: no process is started)
    Timer { interval: 250; running: root.capsPath !== ""; repeat: true; onTriggered: { caps.reload(); num.reload() } }

    component Key: Rectangle {
        id: key
        property string label
        property bool on
        visible: on
        implicitWidth: t.implicitWidth + 14; implicitHeight: 22; radius: 6
        color: "#fab387"
        Text { id: t; anchors.centerIn: parent; text: key.label; color: "#1e1e2e"; font.pixelSize: 11; font.bold: true }
    }
    Key { label: "CAPS"; on: caps.text().trim() === "1" }
    Key { label: "NUM"; on: num.text().trim() === "1" }
}
