import Quickshell.Bluetooth
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// Bluetooth on/off and paired devices; click one to connect or disconnect.
ColumnLayout {
    implicitWidth: Tokens.sizes.popoutWidth
    spacing: Tokens.spacing.small

    RowLayout {
        StyledText {
            Layout.fillWidth: true
            text: "Bluetooth"
            font.pixelSize: Tokens.font.size.larger
            font.weight: 500
        }
        Switch {
            checked: Bluetooth.defaultAdapter?.enabled ?? false
            onToggled: if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = checked
        }
    }

    Repeater {
        model: Bluetooth.devices.values.filter(d => d.paired || d.connected)

        RowLayout {
            required property BluetoothDevice modelData
            Layout.fillWidth: true

            MaterialIcon {
                text: parent.modelData.connected ? "bluetooth_connected" : "bluetooth"
                color: parent.modelData.connected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }
            StyledText {
                Layout.fillWidth: true
                text: parent.modelData.name
                elide: Text.ElideRight
            }
            StyledText {
                visible: parent.modelData.batteryAvailable
                text: Math.round(parent.modelData.battery * 100) + "%"
                color: Colours.palette.m3outline
            }
            TapHandler { onTapped: parent.modelData.connected = !parent.modelData.connected }
        }
    }
}
