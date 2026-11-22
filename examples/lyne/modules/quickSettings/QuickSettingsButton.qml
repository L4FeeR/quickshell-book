import QtQuick
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.components

// The status icons at the right of the bar (lyne's "icons" style): network,
// Bluetooth, volume, microphone (only when muted) and battery. One button:
// a click opens the Quick Settings panel on this bar's screen.
BarButton {
    id: root

    required property string screenName

    active: QuickSettingsService.visible && QuickSettingsService.screenName === screenName
    onClicked: QuickSettingsService.toggle(screenName)
    onScrolled: d => { d > 0 ? AudioService.increaseVolume() : AudioService.decreaseVolume(); OsdService.show("volume"); }

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var network: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property bool wired: Networking.devices.values.some(d => d.type !== DeviceType.Wifi && d.connected && d.name !== "lo")
    readonly property var battery: UPower.displayDevice

    Glyph {
        text: root.wired ? Icons.ethernet
            : !Networking.wifiEnabled ? Icons.wifiOff
            : Icons.wifi[root.network ? Math.ceil(root.network.signalStrength * 4) : 0]
        color: root.network || root.wired ? Config.textColor : Config.mutedColor
    }
    Glyph {
        visible: Bluetooth.defaultAdapter !== null
        text: Bluetooth.defaultAdapter?.enabled ? Icons.bluetooth : Icons.bluetoothOff
        color: Bluetooth.devices.values.some(d => d.connected) ? Config.accentColor : Bluetooth.defaultAdapter?.enabled ? Config.textColor : Config.mutedColor
    }
    Glyph {
        text: AudioService.volumeIcon(AudioService.volume, AudioService.muted)
        color: AudioService.muted ? Config.mutedColor : Config.textColor
    }
    Glyph {
        visible: AudioService.micMuted
        text: Icons.micOff
        color: Config.errorColor
    }
    Row {
        visible: root.battery?.isLaptopBattery ?? false
        spacing: 2
        anchors.verticalCenter: parent.verticalCenter
        readonly property bool charging: root.battery?.state === UPowerDeviceState.Charging
        readonly property real pct: root.battery?.percentage ?? 0
        Glyph {
            text: parent.charging ? Icons.batteryCharging : parent.pct > 0.6 ? Icons.battery : parent.pct > 0.25 ? Icons.batteryHalf : Icons.batteryAlert
            color: parent.charging ? Config.successColor : parent.pct <= 0.15 ? Config.errorColor : Config.textColor
        }
        StyledText {
            text: Math.round(parent.pct * 100) + "%"
            font.pixelSize: Config.fontSizeSmall
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
