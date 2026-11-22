import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import QtQuick
import qs.config
import qs.services
import qs.components

// Audio, network, Bluetooth and battery icons. Hovering one opens its popout (see Bar.checkPopout).
StyledRect {
    id: root

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi)?.networks.values.find(n => n.connected) ?? null

    function iconAt(y: real): Item {
        const item = column.childAt(column.width / 2, y - column.y);
        return item?.name ? item : null;
    }

    implicitWidth: Tokens.sizes.barInnerWidth
    implicitHeight: column.implicitHeight + Tokens.padding.medium * 2
    radius: Tokens.rounding.full
    color: Colours.palette.m3surfaceContainer

    Column {
        id: column
        anchors.horizontalCenter: parent.horizontalCenter
        y: Tokens.padding.medium
        spacing: Tokens.spacing.small

        Icon {
            name: "audio"
            text: Audio.icon
        }
        Icon {
            name: "network"
            text: !Networking.wifiEnabled ? "wifi_off" : root.wifi === null ? "signal_wifi_bad"
                : root.wifi.signalStrength > 0.75 ? "signal_wifi_4_bar" : root.wifi.signalStrength > 0.5 ? "network_wifi_3_bar"
                : root.wifi.signalStrength > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
        }
        Icon {
            name: "bluetooth"
            visible: Bluetooth.defaultAdapter !== null
            text: !(Bluetooth.defaultAdapter?.enabled ?? false) ? "bluetooth_disabled"
                : Bluetooth.devices.values.some(d => d.connected) ? "bluetooth_connected" : "bluetooth"
        }
        Icon {
            readonly property UPowerDevice bat: UPower.displayDevice
            name: "battery"
            visible: bat.isLaptopBattery
            text: bat.state === UPowerDeviceState.Charging ? "battery_charging_full"
                : ["battery_0_bar", "battery_1_bar", "battery_2_bar", "battery_3_bar", "battery_4_bar", "battery_5_bar", "battery_6_bar", "battery_full"][Math.round(bat.percentage * 7)]
            color: bat.percentage < 0.15 && bat.state !== UPowerDeviceState.Charging ? Colours.palette.m3error : Colours.palette.m3onSurface
        }
    }

    component Icon: MaterialIcon {
        required property string name
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
