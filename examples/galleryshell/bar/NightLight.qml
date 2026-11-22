import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Warm screen colours with hyprsunset. Click: on/off. Scroll: colour temperature.
Rectangle {
    id: root
    property int temperature: 4000          // Kelvin; lower = warmer
    readonly property bool on: proc.running

    Process {
        id: proc
        command: ["hyprsunset", "-t", String(root.temperature)]
    }
    // changing the temperature while on restarts hyprsunset with the new value
    Timer { id: restart; interval: 300; onTriggered: { proc.running = false; proc.running = true } }
    onTemperatureChanged: if (on) restart.restart()

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26
    radius: height / 2
    color: on ? "#fab387" : hover.hovered ? "#45475a" : "#313244"
    Behavior on color { ColorAnimation { duration: 200 } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Text {
            text: root.on ? "nightlight" : "light_mode"
            font.family: "Material Symbols Rounded"; font.pixelSize: 18
            color: root.on ? "#1e1e2e" : "#cdd6f4"
        }
        Text {
            visible: root.on || hover.hovered
            text: root.temperature + "K"
            color: root.on ? "#1e1e2e" : "#cdd6f4"; font.pixelSize: 12
        }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: proc.running = !proc.running }
    WheelHandler { onWheel: e => root.temperature = Math.max(2500, Math.min(6500, root.temperature + (e.angleDelta.y > 0 ? 250 : -250))) }
}
