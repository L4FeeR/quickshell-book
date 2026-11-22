import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    readonly property var devices: Bluetooth.devices.values.filter(d => d.connected && d.batteryAvailable)
    visible: devices.length > 0

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26
    radius: height / 2
    color: "#313244"

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 10
        Repeater {
            model: root.devices
            RowLayout {
                required property BluetoothDevice modelData
                spacing: 4
                IconImage { implicitSize: 16; source: Quickshell.iconPath(modelData.icon, "bluetooth") }
                Text {
                    text: (hover.hovered ? modelData.name + " · " : "") + Math.round(modelData.battery * 100) + "%"
                    color: modelData.battery < 0.2 ? "#f38ba8" : "#cdd6f4"
                    font.pixelSize: 12
                }
            }
        }
    }
    HoverHandler { id: hover }
}
