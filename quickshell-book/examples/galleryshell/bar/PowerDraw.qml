import Quickshell.Services.UPower
import QtQuick

Rectangle {
    id: root
    readonly property UPowerDevice bat: UPower.displayDevice
    readonly property real watts: bat.changeRate                 // + charging, − discharging (sign depends on driver)
    readonly property bool charging: bat.state === UPowerDeviceState.Charging
    readonly property int secs: charging ? bat.timeToFull : bat.timeToEmpty
    visible: bat.isLaptopBattery

    implicitWidth: t.implicitWidth + 24; implicitHeight: 26; radius: 13; color: "#313244"
    Text {
        id: t
        anchors.centerIn: parent
        text: "⚡ " + (root.charging ? "+" : "−") + Math.abs(root.watts).toFixed(1) + " W"
              + (root.secs > 0 ? " · " + Math.floor(root.secs / 3600) + "h " + Math.round(root.secs % 3600 / 60) + "m" + (root.charging ? " to full" : " left") : "")
        color: Math.abs(root.watts) > 20 && !root.charging ? "#fab387" : "#cdd6f4"
        font.pixelSize: 12
        font.features: ({ "tnum": 1 })
    }
}
