import Quickshell.Services.UPower
import QtQuick

Rectangle {
    id: root
    readonly property UPowerDevice bat: UPower.displayDevice
    readonly property real pct: bat.percentage                       // 0..1
    readonly property bool charging: bat.state === UPowerDeviceState.Charging
                                  || bat.state === UPowerDeviceState.FullyCharged
    readonly property color fill: charging ? "#a6e3a1" : pct < 0.15 ? "#f38ba8" : pct < 0.3 ? "#f9e2af" : "#cba6f7"

    visible: bat.isLaptopBattery
    implicitWidth: 76
    implicitHeight: 26
    radius: height / 2
    color: "#313244"
    clip: true

    Rectangle {                                                      // the fill
        width: parent.width * root.pct
        height: parent.height
        radius: parent.radius
        color: root.fill
        opacity: 0.85
        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 300 } }
    }
    Text {
        anchors.centerIn: parent
        text: (root.charging ? "⚡ " : "") + Math.round(root.pct * 100) + "%"
        color: root.pct > 0.45 ? "#1e1e2e" : "#cdd6f4"               // readable on fill or track
        font.pixelSize: 12
        font.bold: true
    }
    HoverHandler { id: hover }
    // time remaining tooltip text, e.g. for a Tooltip component
    readonly property string timeLeft: {
        const s = charging ? bat.timeToFull : bat.timeToEmpty
        return s > 0 ? Math.floor(s / 3600) + "h " + Math.round(s % 3600 / 60) + "m" : ""
    }
}
