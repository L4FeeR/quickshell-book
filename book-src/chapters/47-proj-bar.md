# Project: The Bar

Time to build a complete, daily-driver bar on top of the design system from Part V. It's floating and rounded, appears on every monitor, and contains:

- **left:** launcher button, workspaces, active window title
- **center:** clock (truly centered) with a calendar popup
- **right:** media chip, system tray, status icons (network, bluetooth, volume, battery), control-center button

Prerequisites: `services/{Colors,Appearance,Config,GlobalStates,Audio}.qml` and `widgets/*` from [[ch:42-project-layout]] to [[ch:46-state]].

## Services this bar needs

### Battery
```qml file="services/Battery.qml"
pragma Singleton
import Quickshell
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root
    readonly property UPowerDevice dev: UPower.displayDevice
    readonly property bool available: dev?.isLaptopBattery ?? false
    readonly property real percent: dev?.percentage ?? 0                 // 0..1
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
                                  || dev?.state === UPowerDeviceState.PendingCharge
    readonly property bool full: dev?.state === UPowerDeviceState.FullyCharged
    readonly property bool low: available && !charging && percent <= 0.15
    readonly property int secondsLeft: charging ? (dev?.timeToFull ?? 0) : (dev?.timeToEmpty ?? 0)
    readonly property string icon: charging ? "battery_charging_full"
                                 : full ? "battery_full"
                                 : "battery_" + Math.min(6, Math.floor(percent * 7)) + "_bar"
}
```

### Media
```qml file="services/Media.qml"
pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root
    readonly property list<MprisPlayer> players: Mpris.players.values
    property MprisPlayer manualPlayer: null                      // user-picked player, if any
    readonly property MprisPlayer active: (manualPlayer && players.includes(manualPlayer)) ? manualPlayer
                                        : players.find(p => p.isPlaying) ?? players[0] ?? null

    // MPRIS position is not pushed continuously: refresh it while playing
    Timer {
        running: root.active?.isPlaying ?? false
        interval: 1000; repeat: true
        onTriggered: root.active.positionChanged()
    }
}
```

### Network (using the Networking module)
```qml file="services/Network.qml"
pragma Singleton
import Quickshell
import Quickshell.Networking
import QtQuick

Singleton {
    id: root
    readonly property NetworkDevice wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property NetworkDevice wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    readonly property Network activeWifi: wifiDevice?.networks.values.find(n => n.connected) ?? null
    readonly property bool wired: wiredDevice?.connected ?? false
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property string ssid: activeWifi?.name ?? ""
    readonly property real strength: activeWifi?.signalStrength ?? 0      // 0..1
    readonly property bool online: wired || activeWifi !== null
    readonly property string icon: wired ? "lan"
                                 : !wifiEnabled ? "wifi_off"
                                 : !activeWifi ? "signal_wifi_0_bar"
                                 : strength > 0.66 ? "wifi" : strength > 0.33 ? "wifi_2_bar" : "wifi_1_bar"
    function toggleWifi(): void { Networking.wifiEnabled = !Networking.wifiEnabled }
}
```

> [!NOTE] No NetworkManager?
> If `Networking.backend` is `NetworkBackendType.None`, use the `nmcli` or `iwctl` approach with [[Process]] from [[ch:37-processes]], keeping the same public properties so the bar doesn't change.

## The bar entry point

```qml file="modules/bar/Bar.qml"
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Scope {
    Variants {
        model: Config.bar.screens.length
               ? Quickshell.screens.filter(s => Config.bar.screens.includes(s.name))
               : Quickshell.screens

        PanelWindow {
            id: bar
            required property ShellScreen modelData
            screen: modelData
            visible: !GlobalStates.barHidden

            anchors {
                top: !Config.bar.bottom
                bottom: Config.bar.bottom
                left: true
                right: true
            }
            margins { top: 6; bottom: 6; left: 8; right: 8 }
            implicitHeight: Appearance.sizes.barHeight
            color: "transparent"
            WlrLayershell.namespace: "quickshell:bar"

            StyledRect {
                id: bg
                anchors.fill: parent
                level: 1
                radius: Appearance.rounding.large
                color: Colors.barBackground
                border.width: 1
                border.color: Colors.alpha(Colors.outlineVariant, 0.5)

                // ---------------- LEFT ----------------
                RowLayout {
                    anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                    spacing: Appearance.spacing.normal

                    IconButton {
                        icon: "apps"
                        toggled: GlobalStates.launcherOpen
                        onClicked: GlobalStates.toggle("launcher")
                    }
                    Workspaces { screen: bar.modelData }
                    ActiveWindow { Layout.maximumWidth: 260 }
                }

                // ---------------- CENTER ----------------
                Clock {
                    anchors.centerIn: parent
                    bar: bar
                }

                // ---------------- RIGHT ----------------
                RowLayout {
                    anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    spacing: Appearance.spacing.small

                    MediaChip { bar: bar }
                    Tray { bar: bar }
                    StatusIcons {}
                    IconButton {
                        icon: GlobalStates.dnd ? "notifications_off"
                            : Notifs.count > 0 ? "notifications_unread" : "notifications"
                        toggled: GlobalStates.controlCenterOpen
                        onClicked: GlobalStates.toggle("controlCenter")
                        onRightClicked: GlobalStates.dnd = !GlobalStates.dnd
                    }
                }
            }
        }
    }
}
```

`Notifs.count` comes from the notification service in [[ch:51-proj-notifications]]. Until then, replace it with `0`.

## Active window title

```qml file="modules/bar/ActiveWindow.qml"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.widgets

RowLayout {
    id: root
    readonly property Toplevel win: ToplevelManager.activeToplevel       // works on any compositor
    visible: win !== null
    spacing: 6

    IconImage {
        implicitSize: 18
        source: Quickshell.iconPath(DesktopEntries.heuristicLookup(root.win?.appId ?? "")?.icon ?? "", true)
        visible: status === Image.Ready
    }
    StyledText {
        Layout.fillWidth: true
        text: root.win?.title ?? ""
        color: Colors.onSurfaceVariant
    }
}
```

## Status icons

```qml file="modules/bar/StatusIcons.qml"
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.services
import qs.widgets

Rectangle {
    id: root
    implicitWidth: row.implicitWidth + 18
    implicitHeight: 28
    radius: height / 2
    color: hover.hovered ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
    Behavior on color { CAnim {} }
    HoverHandler { id: hover }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        MaterialIcon {                                   // network
            icon: Network.icon
            size: 17
            fill: Network.online ? 1 : 0
        }
        MaterialIcon {                                   // bluetooth
            readonly property bool on: Bluetooth.defaultAdapter?.enabled ?? false
            readonly property bool connected: Bluetooth.devices.values.some(d => d.connected)
            visible: on
            icon: connected ? "bluetooth_connected" : "bluetooth"
            size: 17
        }
        MaterialIcon {                                   // volume: scroll to change, click to mute
            icon: Audio.icon
            size: 17
            WheelHandler { onWheel: e => Audio.setVolume(Audio.volume + (e.angleDelta.y > 0 ? 0.05 : -0.05)) }
            TapHandler { onTapped: Audio.toggleMute() }
        }
        RowLayout {                                      // battery
            visible: Battery.available
            spacing: 2
            MaterialIcon {
                icon: Battery.icon
                size: 17
                rotation: 90                             // Material battery icons are vertical
                color: Battery.low ? Colors.error : Colors.onSurface
            }
            StyledText {
                text: Math.round(Battery.percent * 100) + "%"
                font.pixelSize: Appearance.font.size.small
                font.features: ({ "tnum": 1 })
            }
        }
    }
    TapHandler { onTapped: GlobalStates.toggle("controlCenter") }
}
```

## Media chip

```qml file="modules/bar/MediaChip.qml"
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.widgets

Rectangle {
    id: root
    required property var bar
    readonly property var p: Media.active
    visible: p !== null && (p.trackTitle !== "")

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 28
    radius: height / 2
    color: Colors.secondaryContainer
    clip: true
    Behavior on implicitWidth { Anim {} }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
        ClippingRectangle {
            implicitWidth: 20; implicitHeight: 20; radius: 10
            color: Colors.surfaceContainerHighest
            Image { anchors.fill: parent; source: root.p?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(40, 40); asynchronous: true }
        }
        StyledText {
            Layout.maximumWidth: hover.hovered ? 320 : 160
            text: (root.p?.trackTitle ?? "") + (hover.hovered && root.p?.trackArtist ? " — " + root.p.trackArtist : "")
            color: Colors.onSecondaryContainer
            font.pixelSize: Appearance.font.size.small
            Behavior on Layout.maximumWidth { Anim {} }
        }
        MaterialIcon {
            icon: root.p?.isPlaying ? "pause" : "play_arrow"
            size: 16
            fill: 1
            color: Colors.onSecondaryContainer
        }
    }
    HoverHandler { id: hover }
    TapHandler { onTapped: root.p.togglePlaying() }
    TapHandler { acceptedButtons: Qt.RightButton; onTapped: root.p.next() }
    TapHandler { acceptedButtons: Qt.MiddleButton; onTapped: root.p.previous() }
}
```

## The remaining pieces

`Workspaces.qml`, `Clock.qml` and `Tray.qml` each get their own chapter next:

- [[ch:48-proj-workspaces]]: workspaces for Hyprland, Sway, niri and generic compositors
- [[ch:49-proj-clock-calendar]]: clock plus calendar popup
- [[ch:50-proj-tray]]: tray plus custom menus

Add `Bar {}` to `shell.qml` and you have a complete bar.

## Making it yours

- **Vertical bar:** anchor `left`, `top`, `bottom`; swap `RowLayout` for `ColumnLayout`; rotate or stack text.
- **Hide on fullscreen:** `visible: !(Hyprland.monitorFor(modelData)?.activeWorkspace?.hasFullscreen ?? false)`.
- **Per-monitor modules:** `Tray { visible: bar.modelData.name === Config.bar.trayScreen }`.
- **Island bar:** three separate `StyledRect`s (left, center, right) instead of one background.
- **Auto-hide:** a 2 px trigger strip plus `exclusiveZone` animation, as the dock does in [[ch:59-proj-dock]].

> [!TRY] Exercises
> 1. Add a CPU/RAM chip using the `SystemUsage` service from [[ch:37-processes]].
> 2. Add a keyboard-layout indicator (Hyprland `activelayout` event).
> 3. Add hover tooltips to the status icons ([[ch:32-popups-menus]]).
