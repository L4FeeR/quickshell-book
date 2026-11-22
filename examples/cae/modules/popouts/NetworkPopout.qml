import Quickshell.Networking
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// Wi-Fi on/off and nearby networks; click a known network to connect.
ColumnLayout {
    id: root

    readonly property var dev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null

    implicitWidth: Tokens.sizes.popoutWidth
    spacing: Tokens.spacing.small
    Component.onCompleted: if (dev) dev.scannerEnabled = true
    Component.onDestruction: if (dev) dev.scannerEnabled = false

    RowLayout {
        StyledText {
            Layout.fillWidth: true
            text: "Wi-Fi"
            font.pixelSize: Tokens.font.size.larger
            font.weight: 500
        }
        Switch {
            checked: Networking.wifiEnabled
            onToggled: Networking.wifiEnabled = checked
        }
    }

    Repeater {
        model: (root.dev?.networks.values ?? []).slice().sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength)).slice(0, 8)

        RowLayout {
            required property WifiNetwork modelData
            Layout.fillWidth: true

            MaterialIcon {
                text: parent.modelData.signalStrength > 0.5 ? "signal_wifi_4_bar" : "network_wifi_2_bar"
                color: parent.modelData.connected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }
            StyledText {
                Layout.fillWidth: true
                text: parent.modelData.name
                elide: Text.ElideRight
                font.weight: parent.modelData.connected ? 600 : 400
            }
            MaterialIcon {
                visible: parent.modelData.security !== WifiSecurityType.Open
                text: "lock"
                font.pixelSize: Tokens.font.size.normal
                color: Colours.palette.m3outline
            }
            TapHandler {
                onTapped: {
                    const n = parent.modelData;
                    if (n.connected) n.disconnect();
                    else if (n.known || n.security === WifiSecurityType.Open) n.connect();
                }
            }
        }
    }
}
