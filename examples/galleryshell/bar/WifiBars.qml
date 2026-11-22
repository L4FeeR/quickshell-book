import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    readonly property var dev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var net: dev?.networks.values.find(n => n.connected) ?? null
    readonly property real strength: net?.signalStrength ?? 0      // 0..1
    readonly property int bars: net ? Math.max(1, Math.ceil(strength * 4)) : 0

    implicitWidth: row.implicitWidth + 24; implicitHeight: 26; radius: 13; color: "#313244"
    RowLayout {
        id: row; anchors.centerIn: parent; spacing: 8
        Row {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    width: 3; height: 4 + index * 3; radius: 1
                    anchors.bottom: parent.bottom
                    color: index < root.bars ? "#cdd6f4" : "#585b70"
                }
            }
        }
        Text {
            text: !Networking.wifiEnabled ? "Wi-Fi off" : root.net?.name ?? "disconnected"
            color: root.net ? "#cdd6f4" : "#a6adc8"; font.pixelSize: 12
        }
    }
    TapHandler { onTapped: Networking.wifiEnabled = !Networking.wifiEnabled }
}
