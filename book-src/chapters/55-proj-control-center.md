# Project: Control Center

A sidebar that slides in from the right: header with avatar, uptime and power button; a grid of quick toggles (Wi-Fi, Bluetooth, DND, caffeine, night light, power profile); volume, mic and brightness sliders with output-device picker; Wi-Fi and Bluetooth sub-pages; and the notification history.

## Structure

```text
modules/controlcenter/
├── ControlCenter.qml     ← window + slide animation + page stack
├── Header.qml
├── QuickToggle.qml
├── SliderRow.qml
├── WifiPage.qml
├── BluetoothPage.qml
└── NotificationHistory.qml
```

## The window

```qml file="modules/controlcenter/ControlCenter.qml"
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.widgets

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            screen: modelData
            readonly property bool open: GlobalStates.controlCenterOpen && GlobalStates.activeScreen === modelData.name

            visible: open || slide.running
            anchors { top: true; bottom: true; right: true }
            margins { top: Appearance.sizes.barHeight + 16; bottom: 10; right: 8 }
            implicitWidth: 400
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            WlrLayershell.namespace: "quickshell:controlcenter"

            HyprlandFocusGrab { windows: [win]; active: win.open; onCleared: GlobalStates.controlCenterOpen = false }

            StyledRect {
                id: panel
                width: parent.width
                height: parent.height
                level: 2
                color: Colors.surface
                radius: Appearance.rounding.large
                x: win.open ? 0 : width + 20
                Behavior on x { NumberAnimation { id: slide; duration: 380; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.anim.emphasized } }

                Keys.onEscapePressed: GlobalStates.controlCenterOpen = false
                focus: win.open

                StackView {
                    id: pages
                    anchors { fill: parent; margins: 16 }
                    clip: true
                    initialItem: mainPage
                    // reset to the main page whenever the panel closes
                    Connections { target: win; function onOpenChanged() { if (!win.open) pages.pop(null) } }
                }

                Component {
                    id: mainPage
                    ColumnLayout {
                        spacing: 14

                        Header {}

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: 8; columnSpacing: 8

                            QuickToggle {
                                icon: Network.icon
                                label: Network.wired ? "Ethernet" : (Network.ssid || "Wi-Fi")
                                active: Network.wifiEnabled && Network.online
                                hasDetails: true
                                onToggled: Network.toggleWifi()
                                onDetails: pages.push(wifiPage)
                            }
                            QuickToggle {
                                readonly property var bt: Bluetooth.defaultAdapter
                                icon: "bluetooth"
                                label: Bluetooth.devices.values.find(d => d.connected)?.name ?? "Bluetooth"
                                active: bt?.enabled ?? false
                                hasDetails: true
                                onToggled: if (bt) bt.enabled = !bt.enabled
                                onDetails: pages.push(btPage)
                            }
                            QuickToggle {
                                icon: GlobalStates.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
                                label: "Do not disturb"
                                active: GlobalStates.dnd
                                onToggled: GlobalStates.dnd = !GlobalStates.dnd
                            }
                            QuickToggle {
                                icon: "coffee"
                                label: "Caffeine"
                                active: GlobalStates.caffeine
                                onToggled: GlobalStates.caffeine = !GlobalStates.caffeine
                            }
                            QuickToggle {
                                icon: "nightlight"
                                label: "Night light"
                                active: nightLight.running
                                onToggled: nightLight.running = !nightLight.running
                                Process { id: nightLight; command: ["hyprsunset", "-t", "4200"] }
                            }
                            QuickToggle {
                                icon: PowerProfiles.profile === PowerProfile.Performance ? "bolt"
                                    : PowerProfiles.profile === PowerProfile.PowerSaver ? "eco" : "balance"
                                label: PowerProfile.toString(PowerProfiles.profile)
                                active: PowerProfiles.profile !== PowerProfile.Balanced
                                onToggled: {
                                    const order = PowerProfiles.hasPerformanceProfile
                                        ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
                                        : [PowerProfile.PowerSaver, PowerProfile.Balanced]
                                    PowerProfiles.profile = order[(order.indexOf(PowerProfiles.profile) + 1) % order.length]
                                }
                            }
                        }

                        SliderRow {
                            icon: Audio.icon
                            value: Audio.muted ? 0 : Audio.volume
                            onMoved: v => Audio.setVolume(v)
                            onIconClicked: Audio.toggleMute()
                        }
                        SliderRow {
                            visible: Brightness.available
                            icon: "brightness_6"
                            value: Brightness.value
                            onMoved: v => Brightness.set(v)
                        }

                        NotificationHistory { Layout.fillWidth: true; Layout.fillHeight: true }
                    }
                }
                Component { id: wifiPage; WifiPage { onBack: pages.pop() } }
                Component { id: btPage; BluetoothPage { onBack: pages.pop() } }
            }
        }
    }
}
```

## Header

```qml file="modules/controlcenter/Header.qml"
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

RowLayout {
    Layout.fillWidth: true
    spacing: 12
    property string uptime: ""

    ClippingRectangle {
        implicitWidth: 48; implicitHeight: 48; radius: 24
        color: Colors.primaryContainer
        Image { anchors.fill: parent; source: "file://" + Quickshell.env("HOME") + "/.face"
                fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(96, 96) }
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        StyledText { text: Time.greeting + ", " + Quickshell.env("USER"); font.bold: true; font.pixelSize: Appearance.font.size.large }
        StyledText { text: "up " + parent.parent.uptime; color: Colors.onSurfaceVariant; font.pixelSize: Appearance.font.size.small }
    }
    IconButton { icon: "settings"; onClicked: GlobalStates.open("settings") }
    IconButton { icon: "power_settings_new"; onClicked: GlobalStates.open("session") }

    Process {
        command: ["uptime", "-p"]
        running: GlobalStates.controlCenterOpen
        stdout: StdioCollector { onStreamFinished: uptime = text.trim().replace(/^up /, "") }
    }
}
```

## Quick toggle tile

```qml file="modules/controlcenter/QuickToggle.qml"
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Rectangle {
    id: root
    property string icon
    property string label
    property bool active
    property bool hasDetails: false
    signal toggled()
    signal details()

    Layout.fillWidth: true
    implicitHeight: 60
    radius: active ? Appearance.rounding.large : height / 2
    color: active ? Colors.primary : Colors.surfaceContainerHigh
    Behavior on color { CAnim {} }
    Behavior on radius { Anim {} }

    RowLayout {
        anchors { fill: parent; leftMargin: 16; rightMargin: 8 }
        spacing: 10
        MaterialIcon { icon: root.icon; fill: root.active ? 1 : 0; color: root.active ? Colors.onPrimary : Colors.onSurface }
        StyledText {
            Layout.fillWidth: true
            text: root.label
            color: root.active ? Colors.onPrimary : Colors.onSurface
        }
        IconButton {
            visible: root.hasDetails
            icon: "chevron_right"; size: 28
            onClicked: root.details()
        }
    }
    StateLayer {
        z: -1
        tint: root.active ? Colors.onPrimary : Colors.onSurface
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => m.button === Qt.RightButton && root.hasDetails ? root.details() : root.toggled()
    }
}
```

## Slider row

```qml file="modules/controlcenter/SliderRow.qml"
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

RowLayout {
    id: root
    property string icon
    property real value
    signal moved(real v)
    signal iconClicked()
    Layout.fillWidth: true
    spacing: 10

    IconButton { icon: root.icon; onClicked: root.iconClicked() }
    StyledSlider {
        Layout.fillWidth: true
        value: root.value
        onMoved: root.moved(value)
    }
    StyledText {
        text: Math.round(root.value * 100)
        Layout.preferredWidth: 30
        horizontalAlignment: Text.AlignRight
        font.features: ({ "tnum": 1 })
    }
}
```

## Wi-Fi page (Networking module)

```qml file="modules/controlcenter/WifiPage.qml"
import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.widgets

ColumnLayout {
    id: root
    signal back()
    spacing: 10
    readonly property var dev: Network.wifiDevice
    property var pending: null                 // network waiting for a password

    Component.onCompleted: if (dev) dev.scannerEnabled = true
    Component.onDestruction: if (dev) dev.scannerEnabled = false

    RowLayout {
        IconButton { icon: "arrow_back"; onClicked: root.back() }
        StyledText { text: "Wi-Fi"; font.bold: true; font.pixelSize: Appearance.font.size.title; Layout.fillWidth: true }
        StyledSwitch { checked: Networking.wifiEnabled; onToggled: Networking.wifiEnabled = checked }
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 4
        model: ScriptModel {
            values: (root.dev?.networks.values ?? []).slice().sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
        }
        delegate: Rectangle {
            required property WifiNetwork modelData
            width: ListView.view.width
            implicitHeight: 52
            radius: Appearance.rounding.normal
            color: modelData.connected ? Colors.secondaryContainer : Colors.surfaceContainer

            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 10 }
                spacing: 10
                MaterialIcon {
                    icon: modelData.signalStrength > 0.66 ? "signal_wifi_4_bar"
                        : modelData.signalStrength > 0.33 ? "network_wifi_2_bar" : "network_wifi_1_bar"
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    StyledText { text: modelData.name; font.bold: modelData.connected; Layout.fillWidth: true }
                    StyledText {
                        text: modelData.stateChanging ? "Connecting…"
                            : modelData.connected ? "Connected"
                            : modelData.known ? "Saved" : WifiSecurityType.toString(modelData.security)
                        color: Colors.onSurfaceVariant; font.pixelSize: Appearance.font.size.small
                    }
                }
                MaterialIcon { visible: modelData.security !== WifiSecurityType.Open; icon: "lock"; size: 16 }
            }
            StateLayer {
                onClicked: {
                    if (modelData.connected) modelData.disconnect()
                    else if (modelData.known || modelData.security === WifiSecurityType.Open) modelData.connect()
                    else root.pending = modelData
                }
            }
            Connections {
                target: modelData
                function onConnectionFailed(reason) { root.pending = modelData; err.text = ConnectionFailReason.toString(reason) }
            }
        }
    }

    // password prompt
    ColumnLayout {
        visible: root.pending !== null
        Layout.fillWidth: true
        StyledText { text: "Password for " + (root.pending?.name ?? "") }
        StyledText { id: err; color: Colors.error; visible: text !== "" }
        TextField {
            id: psk
            Layout.fillWidth: true
            echoMode: TextInput.Password
            focus: visible
            onAccepted: { root.pending.connectWithPsk(text); text = ""; err.text = ""; root.pending = null }
            Keys.onEscapePressed: root.pending = null
        }
    }
}
```

## Bluetooth page

```qml file="modules/controlcenter/BluetoothPage.qml"
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

ColumnLayout {
    id: root
    signal back()
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    spacing: 10

    Component.onCompleted: if (adapter?.enabled) adapter.discovering = true
    Component.onDestruction: if (adapter) adapter.discovering = false

    RowLayout {
        IconButton { icon: "arrow_back"; onClicked: root.back() }
        StyledText { text: "Bluetooth"; font.bold: true; font.pixelSize: Appearance.font.size.title; Layout.fillWidth: true }
        MaterialIcon {                                       // scanning spinner
            visible: root.adapter?.discovering ?? false
            icon: "progress_activity"
            RotationAnimation on rotation { running: parent.visible; from: 0; to: 360; duration: 1000; loops: Animation.Infinite }
        }
        StyledSwitch { checked: root.adapter?.enabled ?? false; onToggled: root.adapter.enabled = checked }
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 4
        model: ScriptModel {
            values: (root.adapter?.devices.values ?? []).slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired))
        }
        delegate: Rectangle {
            required property BluetoothDevice modelData
            width: ListView.view.width
            implicitHeight: 52
            radius: Appearance.rounding.normal
            color: modelData.connected ? Colors.secondaryContainer : Colors.surfaceContainer
            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 10 }
                spacing: 10
                IconImage { implicitSize: 22; source: Quickshell.iconPath(modelData.icon, "bluetooth") }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    StyledText { text: modelData.name || modelData.address; Layout.fillWidth: true }
                    StyledText {
                        text: modelData.pairing ? "Pairing…"
                            : modelData.state === BluetoothDeviceState.Connecting ? "Connecting…"
                            : modelData.connected ? "Connected" + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "%" : "")
                            : modelData.paired ? "Paired" : "Available"
                        color: Colors.onSurfaceVariant; font.pixelSize: Appearance.font.size.small
                    }
                }
                IconButton { visible: modelData.paired; icon: "delete"; size: 28; onClicked: modelData.forget() }
            }
            StateLayer {
                onClicked: modelData.connected ? modelData.disconnect()
                         : modelData.paired ? modelData.connect()
                         : modelData.pair()
            }
        }
    }
}
```


## Notification history

```qml file="modules/controlcenter/NotificationHistory.qml"
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets
import qs.modules.notifications

ColumnLayout {
    spacing: 8
    RowLayout {
        StyledText { text: "Notifications"; font.bold: true; Layout.fillWidth: true }
        StyledText { text: Notifs.count; color: Colors.onSurfaceVariant }
        IconButton { icon: "clear_all"; enabled: Notifs.count > 0; onClicked: Notifs.clearAll() }
    }
    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 8
        model: ScriptModel { values: [...Notifs.list].reverse() }
        delegate: NotificationCard { required property var modelData; notif: modelData; width: ListView.view.width }
        remove: Transition { NumberAnimation { property: "x"; to: 420; duration: 250; easing.type: Easing.InCubic } }
        displaced: Transition { NumberAnimation { property: "y"; duration: 250; easing.type: Easing.OutCubic } }
        Column {
            anchors.centerIn: parent
            visible: parent.count === 0
            spacing: 6
            MaterialIcon { anchors.horizontalCenter: parent.horizontalCenter; icon: "notifications_paused"; size: 40; color: Colors.outline }
            StyledText { text: "All caught up"; color: Colors.outline }
        }
    }
}
```

## Audio output picker (extra)

```qml
ComboBox {
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    model: sinks.map(n => n.description || n.nickname || n.name)
    currentIndex: sinks.indexOf(Pipewire.defaultAudioSink)
    onActivated: i => Pipewire.preferredDefaultAudioSink = sinks[i]
}
```

> [!TRY] Exercises
> 1. Add a microphone slider for `Pipewire.defaultAudioSource` (remember the tracker).
> 2. Add a per-app volume mixer page.
> 3. Add a media card at the top using [[ch:54-proj-media]].
