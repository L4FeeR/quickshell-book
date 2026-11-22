# A Tour of the System Services

This chapter walks through every system service module with a short working example for each. Each section links to the full API reference, where **every** property, function and signal is documented with a complete example.

| Module | Singleton(s) | Replaces |
|---|---|---|
| `Quickshell.Services.Pipewire` | [[Pipewire]] | `wpctl`/`pactl` polling |
| `Quickshell.Services.Mpris` | [[Mpris]] | `playerctl` |
| `Quickshell.Services.UPower` | [[UPower]], [[PowerProfiles]] | `acpi`, `powerprofilesctl` |
| `Quickshell.Services.SystemTray` | [[SystemTray]] | Waybar tray, `snixembed` |
| `Quickshell.Services.Notifications` | (you create [[NotificationServer]]) | dunst, mako, swaync |
| `Quickshell.Bluetooth` | [[Bluetooth]] | `bluetoothctl` |
| `Quickshell.Networking` | [[Networking]] | `nmcli` |
| `Quickshell.Services.Pam` | (you create [[PamContext]]) | swaylock/hyprlock auth |
| `Quickshell.Services.Polkit` | (you create [[PolkitAgent]]) | polkit-gnome, hyprpolkitagent |
| `Quickshell.Services.Greetd` | [[Greetd]] | tuigreet, regreet |
| `Quickshell` | [[DesktopEntries]] | rofi's app list |

## Audio: Pipewire

```qml
import Quickshell.Services.Pipewire

Item {
    readonly property PwNode sink: Pipewire.defaultAudioSink        // speakers / headphones
    readonly property PwNode source: Pipewire.defaultAudioSource    // microphone

    // REQUIRED: bind the nodes, or their audio properties stay invalid
    PwObjectTracker { objects: [sink, source] }

    Text {
        text: sink?.audio ? Math.round(sink.audio.volume * 100) + "%" + (sink.audio.muted ? " (muted)" : "") : "…"
        WheelHandler { onWheel: e => sink.audio.volume = Math.max(0, Math.min(1.5, sink.audio.volume + (e.angleDelta.y > 0 ? 0.05 : -0.05))) }
        TapHandler { onTapped: sink.audio.muted = !sink.audio.muted }
    }
}
```

Key facts:

- [[PwNode]] is any node: devices (`isStream: false`) or app streams (`isStream: true`); `isSink` tells direction. `description` and `nickname` are human names.
- [[PwNodeAudio]] (`node.audio`): `volume` (0–1, can exceed 1), `muted`, `volumes` (per channel), `channels`.
- **[[PwObjectTracker]] is mandatory** for any node whose audio you read or write.
- Switch the output device: `Pipewire.preferredDefaultAudioSink = node`.
- Per-app mixer: `Pipewire.nodes.values.filter(n => n.isStream && n.audio)`.
- Live level meters: [[PwNodePeakMonitor]] gives `peak`/`peaks` (0–1) for a node.
- `Pipewire.ready` becomes true after the initial sync.

## Media: Mpris

```qml
import Quickshell.Services.Mpris

Item {
    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    Column {
        visible: player !== null
        Text { text: player?.trackTitle || "Unknown title" }
        Text { text: player?.trackArtist || "Unknown artist" }
        Row {
            Text { text: "⏮"; TapHandler { onTapped: player.previous() } }
            Text { text: player?.isPlaying ? "⏸" : "▶"; TapHandler { onTapped: player.togglePlaying() } }
            Text { text: "⏭"; TapHandler { onTapped: player.next() } }
        }
    }
    // position doesn't update on its own; poke it while playing
    Timer { running: player?.isPlaying ?? false; interval: 1000; repeat: true; onTriggered: player.positionChanged() }
}
```

[[MprisPlayer]] has `trackTitle`, `trackArtist`, `trackAlbum`, `trackArtUrl`, `length`, `position` (settable to seek), `isPlaying`, `playbackState`, `loopState`, `shuffle`, `volume`, `rate`, the `can*` capability flags, and `play()`, `pause()`, `togglePlaying()`, `next()`, `previous()`, `seek(offset)`, `raise()`, `quit()`.

## Battery and power: UPower and PowerProfiles

```qml
import Quickshell.Services.UPower

Text {
    readonly property UPowerDevice bat: UPower.displayDevice
    visible: bat.isLaptopBattery
    text: Math.round(bat.percentage * 100) + "% " + UPowerDeviceState.toString(bat.state)
}
Text { text: "Profile: " + PowerProfile.toString(PowerProfiles.profile)
       TapHandler { onTapped: PowerProfiles.profile = PowerProfile.PowerSaver } }
```

- [[UPowerDevice]]: `percentage` (**0–1**), `state`, `timeToEmpty`/`timeToFull` (seconds), `energy`, `energyCapacity`, `changeRate`, `healthPercentage` (0–100), `isLaptopBattery`, `iconName`, `type`, `model`.
- [[UPower]]: `displayDevice`, `devices` (mice, headsets…), `onBattery`.
- [[PowerProfiles]]: `profile` (settable), `hasPerformanceProfile`, `degradationReason`, `holds`.

## System tray: SystemTray

```qml
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Row {
    Repeater {
        model: SystemTray.items
        IconImage {
            id: icon
            required property SystemTrayItem modelData
            implicitSize: 18
            source: modelData.icon
            TapHandler { onTapped: modelData.onlyMenu ? menu.open() : modelData.activate() }
            TapHandler { acceptedButtons: Qt.RightButton; onTapped: menu.open() }
            TapHandler { acceptedButtons: Qt.MiddleButton; onTapped: modelData.secondaryActivate() }
            QsMenuAnchor { id: menu; menu: icon.modelData.menu; anchor.item: icon; anchor.edges: Edges.Bottom; anchor.gravity: Edges.Bottom }
        }
    }
}
```

[[SystemTrayItem]] has `id`, `title`, `icon`, `tooltipTitle`, `tooltipDescription`, `status`, `category`, `hasMenu`, `onlyMenu`, `menu`, `activate()`, `secondaryActivate()`, `scroll(delta, horizontal)` and `display(window, x, y)`. A custom-styled tray menu is built in [[ch:50-proj-tray]].

## Notifications: NotificationServer

You **become** the notification daemon (stop dunst/mako first):

```qml
import Quickshell.Services.Notifications

NotificationServer {
    id: server
    actionsSupported: true
    imageSupported: true
    bodyMarkupSupported: true
    keepOnReload: true
    onNotification: n => {
        n.tracked = true                    // REQUIRED, or it's discarded immediately
        console.log(n.appName, ":", n.summary, "-", n.body)
    }
}
// all current notifications: server.trackedNotifications (ObjectModel<Notification>)
```

[[Notification]] has `summary`, `body`, `appName`, `appIcon`, `image`, `urgency`, `actions` (each with `text`, `identifier`, `invoke()`), `expireTimeout` (**seconds**), `resident`, `transient`, `hints`, `hasInlineReply`, `dismiss()`, `expire()`, `sendInlineReply(text)` and the `closed(reason)` signal. By default the server advertises few capabilities: turn on what your UI supports. The full popup UI is [[ch:51-proj-notifications]].

## Bluetooth

```qml
import Quickshell.Bluetooth

Column {
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    Switch { checked: adapter?.enabled ?? false; onToggled: adapter.enabled = checked }
    Repeater {
        model: adapter?.devices ?? []
        Text {
            required property BluetoothDevice modelData
            text: modelData.name + (modelData.connected ? " ✓" : "")
                  + (modelData.batteryAvailable ? `  ${Math.round(modelData.battery * 100)}%` : "")
            TapHandler { onTapped: modelData.connected ? modelData.disconnect() : modelData.connect() }
        }
    }
}
```

[[BluetoothAdapter]]: `enabled`, `discovering` (set true to scan), `discoverable`, `pairable`, `devices`, `state`. [[BluetoothDevice]]: `name`, `address`, `icon`, `connected`, `paired`, `trusted`, `blocked`, `battery` (0–1), `connect()`, `disconnect()`, `pair()`, `cancelPair()`, `forget()`.

## Network: Networking

```qml
import Quickshell.Networking

Column {
    readonly property WifiDevice wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    Switch { checked: Networking.wifiEnabled; onToggled: Networking.wifiEnabled = checked }
    Repeater {
        model: wifi?.networks ?? []
        Text {
            required property WifiNetwork modelData
            text: (modelData.connected ? "● " : "  ") + modelData.name + "  " + Math.round(modelData.signalStrength * 100) + "%"
            TapHandler { onTapped: modelData.known ? modelData.connect() : passwordDialog.ask(modelData) }
        }
    }
    Component.onCompleted: if (wifi) wifi.scannerEnabled = true     // scan for networks
}
```

- [[Networking]]: `devices`, `wifiEnabled`, `wifiHardwareEnabled`, `connectivity`, `checkConnectivity()`, `backend`.
- [[NetworkDevice]] / [[WifiDevice]] / [[WiredDevice]]: `type`, `name`, `connected`, `state`, `networks`, `scannerEnabled` (Wi-Fi), `hasLink` and `linkSpeed` (wired).
- [[Network]] / [[WifiNetwork]]: `name`, `connected`, `known`, `state`, `signalStrength` (0–1), `security`, `connect()`, `connectWithPsk(password)`, `disconnect()`, `forget()`, `connectionFailed(reason)`.

Requires NetworkManager. On setups without it, use `nmcli`/`iwctl` through Process.

## Authentication: PamContext

```qml
import Quickshell.Services.Pam

PamContext {
    id: pam
    config: "login"                         // /etc/pam.d/login
    onPamMessage: if (responseRequired) respond(passwordField.text)
    onCompleted: result => {
        if (result === PamResult.Success) unlock()
        else showError()
    }
}
// start: pam.start()
```

[[PamContext]]: `config`, `configDirectory`, `user`, `active`, `message`, `messageIsError`, `responseRequired`, `responseVisible`, `start()`, `abort()`, `respond(text)`, signals `pamMessage`, `completed(result)`, `error(err)`. Used for lock screens ([[ch:57-proj-lock]]).

## Polkit agent: PolkitAgent

When an app asks "authenticate to continue", a **polkit agent** shows the dialog. Quickshell can be that agent:

```qml
import Quickshell.Services.Polkit

PolkitAgent {
    id: agent
    onAuthenticationRequestStarted: console.log("auth needed:", flow.message)
}
// agent.flow: AuthFlow (message, iconName, inputPrompt, isResponseRequired, submit(pw), cancelAuthenticationRequest() …)
```

Full dialog: [[ch:63-proj-polkit]].

## Login greeter: Greetd

[[Greetd]] lets a Quickshell config run as a graphical login screen under greetd: `createSession(user)`, `respond(password)`, `launch(command)`, signals `authMessage`, `authFailure`, `readyToLaunch`. See [[ch:64-proj-greeter]].

## Applications: DesktopEntries

```qml
ListView {
    model: DesktopEntries.applications          // every visible installed app
    delegate: Text {
        required property DesktopEntry modelData
        text: modelData.name
        TapHandler { onTapped: modelData.execute() }
    }
}
```

[[DesktopEntry]]: `id`, `name`, `genericName`, `comment`, `icon`, `categories`, `keywords`, `command`, `execString`, `runInTerminal`, `noDisplay`, `startupClass`, `actions`, `execute()`. [[DesktopEntries]]: `applications`, `byId(id)`, `heuristicLookup(name)` (match a window's app id to its entry).

## Things without a module

| Need | Approach |
|---|---|
| Brightness | `FileView` on `/sys/class/backlight/*/brightness` + `brightnessctl` to set |
| CPU, RAM, temperature | `FileView` on `/proc` and `/sys` |
| Disk usage | `Process` running `df` |
| Weather | `Process` running `curl` against an API, `JSON.parse` |
| Clipboard history | `cliphist` via Process |
| Keyboard layout | compositor events |
| Night light | `hyprsunset` / `wlsunset` via Process |
| Screenshots | `grim` + `slurp` via `execDetached` |
| Idle and lock timing | [[IdleMonitor]], [[IdleInhibitor]] |
| Clipboard text | [[Quickshell.clipboardText]] (needs a focused Quickshell window on Wayland) |

## Practice

::: exercise warm | Volume chip
Show the volume and a mute icon, scrollable.
--- solution
```qml
PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
Row {
    readonly property var audio: Pipewire.defaultAudioSink?.audio
    Text { text: parent.audio?.muted ? "volume_off" : "volume_up"; font.family: "Material Symbols Rounded"; color: "white" }
    Text { text: Math.round((parent.audio?.volume ?? 0) * 100) + "%"; color: "white" }
    WheelHandler { onWheel: e => parent.audio.volume = Math.max(0, Math.min(1, parent.audio.volume + e.angleDelta.y / 120 * 0.05)) }
    TapHandler { onTapped: parent.audio.muted = !parent.audio.muted } }
```
:::

::: exercise practice | Now playing
Show the current song title and a play/pause button.
--- solution
```qml
Row { readonly property MprisPlayer p: Mpris.players.values[0] ?? null
    visible: p !== null
    Text { text: parent.p?.trackTitle ?? ""; color: "white" }
    Text { text: parent.p?.isPlaying ? "pause" : "play_arrow"; font.family: "Material Symbols Rounded"; color: "white"
        TapHandler { onTapped: parent.parent.p.togglePlaying() } } }
```
:::

::: exercise practice | Battery
Show battery percentage and charging state, hidden on desktops.
--- solution
```qml
Text { readonly property var dev: UPower.displayDevice
    visible: dev.isLaptopBattery
    text: Math.round(dev.percentage * 100) + "%" + (dev.state === UPowerDeviceState.Charging ? " ⚡" : "")
    color: "white" }
```
`percentage` is 0–1 here (see [[UPowerDevice.percentage]]).
:::

::: exercise challenge | Bluetooth count
Count connected Bluetooth devices.
--- solution
```qml
Text { text: Bluetooth.devices.values.filter(d => d.connected).length + " connected"; color: "white" }
```
:::
