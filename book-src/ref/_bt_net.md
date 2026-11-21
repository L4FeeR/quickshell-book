=== Bluetooth
@@@ intro
Bluetooth through **BlueZ**: adapters (your Bluetooth chips) and devices (headphones, mice, phones).

@@@ example Example: every property
```qml
import Quickshell.Bluetooth
import QtQuick

Column {
    Text { text: "default adapter: " + (Bluetooth.defaultAdapter?.name ?? "none") }
    Text { text: "adapters: " + Bluetooth.adapters.values.length }
    Text { text: "connected devices: " + Bluetooth.devices.values.filter(d => d.connected).map(d => d.name).join(", ") }
}
```

@@@ notes
Requires `bluez` running (`systemctl enable --now bluetooth`).

@@@ see
[[BluetoothAdapter]] · [[BluetoothDevice]] · [[ch:55-proj-control-center]]

=== BluetoothAdapter
@@@ intro
A Bluetooth controller. Turn it on and off, scan for devices, and make the computer discoverable.

@@@ example Example: every property
```qml
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    readonly property BluetoothAdapter a: Bluetooth.defaultAdapter
    Text { text: `${a?.name} (${a?.adapterId}) at ${a?.dbusPath}` }
    Text { text: "state: " + BluetoothAdapterState.toString(a?.state) }   // Enabling, Blocked (rfkill)…
    Switch { text: "enabled"; checked: a?.enabled ?? false; onToggled: a.enabled = checked }
    Switch { text: "scanning"; checked: a?.discovering ?? false; onToggled: a.discovering = checked }
    Switch { text: "discoverable"; checked: a?.discoverable ?? false; onToggled: a.discoverable = checked }
    SpinBox { from: 0; to: 600; value: a?.discoverableTimeout ?? 0; onValueModified: a.discoverableTimeout = value }   // 0 = forever
    Switch { text: "pairable"; checked: a?.pairable ?? false; onToggled: a.pairable = checked }
    SpinBox { from: 0; to: 600; value: a?.pairableTimeout ?? 0; onValueModified: a.pairableTimeout = value }
    Text { text: (a?.devices.values.length ?? 0) + " known devices" }
}
```

@@@ member discovering
Set `true` to scan; new devices appear in `devices`. Turn it off when your panel closes, since scanning uses power.

=== BluetoothDevice
@@@ intro
A Bluetooth device known to an adapter. Connect, pair, trust, forget, rename, and read its battery.

@@@ example Example: every property and function
```qml
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls

Repeater {
    model: Bluetooth.defaultAdapter?.devices ?? []
    Row {
        required property BluetoothDevice modelData
        readonly property BluetoothDevice d: modelData
        spacing: 6
        IconImage { implicitSize: 20; source: Quickshell.iconPath(d.icon, "bluetooth") }
        Text { text: `${d.name} [${d.deviceName}] ${d.address}` }
        Text { text: BluetoothDeviceState.toString(d.state) }          // Connecting / Connected …
        Text { text: d.batteryAvailable ? Math.round(d.battery * 100) + "%" : "" }
        Text { text: `paired ${d.paired} bonded ${d.bonded} pairing ${d.pairing} trusted ${d.trusted} blocked ${d.blocked} wake ${d.wakeAllowed}` }
        Button { text: d.connected ? "Disconnect" : "Connect"; onClicked: d.connected ? d.disconnect() : d.connect() }   // or d.connected = !d.connected
        Button { text: d.pairing ? "Cancel" : "Pair"; visible: !d.paired; onClicked: d.pairing ? d.cancelPair() : d.pair() }
        Button { text: d.trusted ? "Untrust" : "Trust"; onClicked: d.trusted = !d.trusted }
        Button { text: "Forget"; onClicked: d.forget() }
        TextField { placeholderText: "rename"; onAccepted: d.name = text }   // "" resets the alias
        Text { text: "via " + d.adapter?.name + " " + d.dbusPath; color: "grey" }
    }
}
```

@@@ member battery
0.0–1.0, valid only when `batteryAvailable` is true.

@@@ member pair
Pairing that needs a PIN or confirmation requires a BlueZ agent; many devices (headphones, mice) pair without one.

=== Networking
@@@ intro
Network management (currently through **NetworkManager**): devices, Wi-Fi on/off, and internet connectivity. Networks are found on each device.

@@@ example Example: every property and function
```qml
import Quickshell.Networking
import QtQuick
import QtQuick.Controls

Column {
    Text { text: "backend: " + NetworkBackendType.toString(Networking.backend) }
    Switch { text: "Wi-Fi"; checked: Networking.wifiEnabled; onToggled: Networking.wifiEnabled = checked }
    Text { text: "hardware switch on: " + Networking.wifiHardwareEnabled }
    Text { text: "connectivity: " + NetworkConnectivity.toString(Networking.connectivity) }   // None/Portal/Limited/Full
    Text { text: "can check: " + Networking.canCheckConnectivity + " · enabled " + Networking.connectivityCheckEnabled }
    Button { text: "check now"; onClicked: Networking.checkConnectivity() }
    Repeater {
        model: Networking.devices
        Text { required property NetworkDevice modelData; text: DeviceType.toString(modelData.type) + " " + modelData.name + (modelData.connected ? " ✓" : "") }
    }
}
```

@@@ member connectivity
`Portal` means a captive portal (hotel Wi-Fi login page): you can open a browser to log in.

@@@ see
[[NetworkDevice]] · [[WifiDevice]] · [[WifiNetwork]] · [[ch:55-proj-control-center]]

=== NetworkDevice
@@@ intro
A network interface (Wi-Fi card, Ethernet port). When `type` is `Wifi` it's a [[WifiDevice]]; when `Wired`, a [[WiredDevice]].

@@@ example Example: every property
```qml
Repeater {
    model: Networking.devices
    Text {
        required property NetworkDevice modelData
        readonly property NetworkDevice d: modelData
        text: `${d.name} ${DeviceType.toString(d.type)} ${d.address} · ${ConnectionState.toString(d.state)}`
            + ` · connected ${d.connected} · managed ${d.nmManaged} · autoconnect ${d.autoconnect}`
            + ` · networks ${d.networks.values.length}`
        TapHandler { onTapped: d.disconnect() }      // disconnect and stop autoconnecting
    }
}
```

=== WifiDevice
@@@ intro
A Wi-Fi network device. Turn on `scannerEnabled` to discover networks; they appear in `networks` as [[WifiNetwork]]s.

@@@ example Example
```qml
import Quickshell.Networking
import QtQuick

Column {
    readonly property WifiDevice wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    Component.onCompleted: if (wifi) wifi.scannerEnabled = true
    Component.onDestruction: if (wifi) wifi.scannerEnabled = false
    Text { text: "mode: " + WifiDeviceMode.toString(wifi?.mode) }
    Repeater {
        model: wifi?.networks ?? []
        Text { required property WifiNetwork modelData; text: modelData.name + " " + Math.round(modelData.signalStrength * 100) + "%" }
    }
}
```

=== WiredDevice
@@@ intro
An Ethernet device. `hasLink` tells you if a cable is plugged in; `network` is the wired connection.

@@@ example Example
```qml
Text {
    readonly property WiredDevice eth: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    visible: eth !== null
    text: eth?.hasLink ? `Ethernet ${eth.linkSpeed} Mb/s` + (eth.network?.connected ? " (connected)" : "") : "cable unplugged"
}
```

=== Network
@@@ intro
A network you can connect to (a Wi-Fi network, or a wired connection). Wi-Fi networks are the subtype [[WifiNetwork]].

@@@ example Example: every property, function and signal
```qml
Repeater {
    model: device.networks
    Row {
        required property Network modelData
        readonly property Network n: modelData
        spacing: 6
        Text { text: n.name + " · " + ConnectionState.toString(n.state) + (n.stateChanging ? "…" : "") }
        Text { text: n.known ? "saved" : "new" }
        Text { text: "[" + (n.connected ? "disconnect" : "connect") + "]"
               TapHandler { onTapped: n.connected ? n.disconnect() : n.connect() } }
        Text { text: "[forget]"; visible: n.known; TapHandler { onTapped: n.forget() } }
        Text { text: n.nmSettings.length + " profiles" }      // NetworkManager only
        Connections { target: n; function onConnectionFailed(r) { console.warn("failed:", ConnectionFailReason.toString(r)) } }
    }
}
```

@@@ member connect
For a Wi-Fi network that needs a password and isn't saved yet, this fails with `ConnectionFailReason.NoSecrets`; use [[WifiNetwork.connectWithPsk()]].

=== WifiNetwork
@@@ intro
A Wi-Fi network, with signal strength and security type, plus `connectWithPsk()` for password-protected networks.

@@@ example Example
```qml
Row {
    required property WifiNetwork net
    Text { text: net.name + " " + Math.round(net.signalStrength * 100) + "% " + WifiSecurityType.toString(net.security) }
    TextField {
        visible: !net.known && net.security !== WifiSecurityType.Open
        echoMode: TextInput.Password
        placeholderText: "password"
        onAccepted: net.connectWithPsk(text)       // wrong password → connectionFailed signal
    }
}
```

=== NMSettings
@@@ intro
A saved NetworkManager **connection profile** for a network, from [[Network.nmSettings]]. Read or update its settings, clear saved secrets, or delete it.

@@@ example Example
```qml
Repeater {
    model: network.nmSettings
    Row {
        required property NMSettings modelData
        Text { text: modelData.id + " (" + modelData.uuid + ")" }
        Text { text: "[dump]"; TapHandler { onTapped: console.log(JSON.stringify(modelData.read(), null, 2)) } }   // secrets excluded
        Text { text: "[no autoconnect]"; TapHandler { onTapped: modelData.write({ connection: { autoconnect: false } }) } }
        Text { text: "[clear password]"; TapHandler { onTapped: modelData.clearSecrets() } }
        Text { text: "[delete]"; TapHandler { onTapped: modelData.forget() } }
    }
}
```
