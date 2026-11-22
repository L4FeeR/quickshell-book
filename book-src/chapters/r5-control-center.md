# Ricing the Control Center, Module by Module

The control center (quick settings plus notification history) is where many rices show off. Done well, it looks like a polished phone UI. This guide builds it from modules: header, toggle tiles, big sliders, a media card, a calendar strip and notification history, then arranges them as a right sidebar, a top dropdown, or a two-column dashboard.

**Services:** `Audio`, `Brightness`, `Network`, `Media`, `Notifs`, `GlobalStates` ([[ch:55-proj-control-center]] has the full logic, including the Wi-Fi and Bluetooth pages).

## Anatomy

<div class="preview"><svg width="380" height="460" viewBox="0 0 380 460"><rect x="20" y="10" width="340" height="440" rx="26" fill="#1e1e2e"/><circle cx="56" cy="46" r="18" fill="#cba6f7"/><text x="84" y="44" fill="#cdd6f4" font-size="13" font-weight="700">Good evening</text><text x="84" y="60" fill="#a6adc8" font-size="10">up 3h 12m · 81%</text><circle cx="306" cy="46" r="14" fill="#313244"/><circle cx="336" cy="46" r="0" fill="#313244"/><g font-size="11"><rect x="40" y="80" width="146" height="54" rx="16" fill="#cba6f7"/><text x="60" y="112" fill="#1e1e2e" font-weight="700">📶  Home-5G</text><rect x="194" y="80" width="146" height="54" rx="27" fill="#313244"/><text x="214" y="112" fill="#cdd6f4">ᛒ  Bluetooth</text><rect x="40" y="142" width="146" height="54" rx="27" fill="#313244"/><text x="60" y="174" fill="#cdd6f4">🌙  Do not disturb</text><rect x="194" y="142" width="146" height="54" rx="16" fill="#cba6f7"/><text x="214" y="174" fill="#1e1e2e" font-weight="700">☕  Caffeine</text></g><rect x="40" y="208" width="300" height="34" rx="17" fill="#313244"/><rect x="40" y="208" width="200" height="34" rx="17" fill="#cba6f7"/><text x="56" y="230" font-size="13">🔊</text><rect x="40" y="250" width="300" height="34" rx="17" fill="#313244"/><rect x="40" y="250" width="140" height="34" rx="17" fill="#f9e2af"/><text x="56" y="272" font-size="13">☀</text><rect x="40" y="296" width="300" height="70" rx="18" fill="#313244"/><rect x="50" y="306" width="50" height="50" rx="12" fill="#f5c2e7"/><text x="112" y="326" fill="#cdd6f4" font-size="12" font-weight="700">Midnight City</text><text x="112" y="342" fill="#a6adc8" font-size="10">M83</text><text x="300" y="338" fill="#cdd6f4" font-size="14">⏸</text><text x="40" y="390" fill="#cdd6f4" font-size="12" font-weight="700">Notifications</text><rect x="40" y="398" width="300" height="40" rx="12" fill="#313244"/></svg></div>

| Module | File | Job |
|---|---|---|
| Header | `CCHeader.qml` | avatar, greeting, uptime, settings and power buttons |
| Tile | `CCTile.qml` | toggle tile (icon, label, sublabel, details arrow) |
| Tile grid | `CCTiles.qml` | the set of tiles |
| Big slider | `CCSlider.qml` | thick slider with an icon inside |
| Media card | `CCMedia.qml` | art, title, controls, progress |
| Calendar strip | `CCWeek.qml` | the current week with today highlighted |
| History | `CCHistory.qml` | notification list grouped by app |
| Window | `ControlCenter.qml` | position, slide animation, layouts |

## Module 1: Header

```qml file="rice/controlcenter/CCHeader.qml"
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

RowLayout {
    spacing: 12
    property string uptime: ""
    Process { running: GlobalStates.controlCenterOpen; command: ["uptime", "-p"]
              stdout: StdioCollector { onStreamFinished: uptime = text.trim().replace(/^up /, "").replace(/ hours?/, "h").replace(/ minutes?/, "m") } }
    SystemClock { id: clock; precision: SystemClock.Minutes }

    ClippingRectangle {
        implicitWidth: 44; implicitHeight: 44; radius: Theme.style === "neon" ? 0 : 22; color: Theme.accent
        Image { anchors.fill: parent; source: "file://" + Quickshell.env("HOME") + "/.face"; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(88, 88) }
    }
    ColumnLayout {
        Layout.fillWidth: true; spacing: 0
        TText { text: (clock.hours < 12 ? "Good morning" : clock.hours < 18 ? "Good afternoon" : "Good evening"); font.bold: true; font.pixelSize: Theme.textLarge }
        TText { text: "up " + parent.parent.uptime + (Battery.available ? " · " + Math.round(Battery.percent * 100) + "%" : ""); color: Theme.fgDim; font.pixelSize: Theme.textSmall }
    }
    TButton { icon: "settings"; size: 34 }
    TButton { icon: "power_settings_new"; size: 34; onClicked: GlobalStates.open("session") }
}
```

<!-- ex:## Module 1 -->
::: exercise warm | Weather in the header
Add the current temperature next to the uptime using the Weather service from [[ch:62-proj-desktop]].
:::


## Module 2: Toggle tile

<div class="preview"><svg width="360" height="90" viewBox="0 0 360 90"><rect x="20" y="18" width="150" height="54" rx="27" fill="#313244"><animate attributeName="rx" values="27;16;16;27" keyTimes="0;.2;.7;.9" dur="3s" repeatCount="indefinite"/><animate attributeName="fill" values="#313244;#cba6f7;#cba6f7;#313244" keyTimes="0;.2;.7;.9" dur="3s" repeatCount="indefinite"/></rect><text x="40" y="50" font-size="12" fill="#cdd6f4">ᛒ Bluetooth</text><rect x="190" y="18" width="150" height="54" rx="16" fill="#cba6f7"/><text x="210" y="42" font-size="12" fill="#1e1e2e" font-weight="700">📶 Wi-Fi</text><text x="210" y="58" font-size="10" fill="#1e1e2e">Home-5G</text><text x="320" y="50" font-size="12" fill="#1e1e2e">›</text></svg></div>

```qml file="rice/controlcenter/CCTile.qml"
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Rectangle {
    id: tile
    property string icon
    property string label
    property string sublabel: ""
    property bool active: false
    property bool hasDetails: false
    signal toggled()
    signal details()

    Layout.fillWidth: true
    implicitHeight: 58
    radius: Theme.style === "neon" ? 0 : active ? Theme.radius : height / 2     // M3 shape morph
    color: active ? Theme.accent : hover.hovered ? Theme.surfaceHi : Theme.surface
    border.width: Theme.border
    border.color: active ? Theme.accent : Theme.borderColor
    Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: Theme.normal } }

    RowLayout {
        anchors { fill: parent; leftMargin: 16; rightMargin: 8 }
        spacing: 10
        TIcon { icon: tile.icon; size: 20; fill: tile.active ? 1 : 0; color: tile.active ? Theme.onAccent : Theme.fg }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 0
            TText { Layout.fillWidth: true; text: tile.label; font.bold: tile.active; color: tile.active ? Theme.onAccent : Theme.fg }
            TText { Layout.fillWidth: true; visible: text !== ""; text: tile.sublabel; font.pixelSize: Theme.textSmall
                    color: tile.active ? Theme.alpha(Theme.onAccent, 0.75) : Theme.fgDim }
        }
        TIcon { visible: tile.hasDetails; icon: "chevron_right"; size: 18; color: tile.active ? Theme.onAccent : Theme.fgDim
                TapHandler { onTapped: tile.details() } }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: tile.toggled() }
    TapHandler { acceptedButtons: Qt.RightButton; onTapped: tile.details() }
    scale: press.pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 100 } }
    TapHandler { id: press }
}
```

```qml file="rice/controlcenter/CCTiles.qml"
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import qs.services

GridLayout {
    signal openPage(string name)
    columns: 2; rowSpacing: 8; columnSpacing: 8
    CCTile { icon: Network.icon; label: "Wi-Fi"; sublabel: Network.ssid || (Network.wifiEnabled ? "Not connected" : "Off")
             active: Network.wifiEnabled; hasDetails: true; onToggled: Network.toggleWifi(); onDetails: parent.openPage("wifi") }
    CCTile { icon: "bluetooth"; label: "Bluetooth"; sublabel: Bluetooth.devices.values.find(d => d.connected)?.name ?? ""
             active: Bluetooth.defaultAdapter?.enabled ?? false; hasDetails: true
             onToggled: Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled; onDetails: parent.openPage("bt") }
    CCTile { icon: GlobalStates.dnd ? "do_not_disturb_on" : "do_not_disturb_off"; label: "Do not disturb"
             active: GlobalStates.dnd; onToggled: GlobalStates.dnd = !GlobalStates.dnd }
    CCTile { icon: "coffee"; label: "Caffeine"; active: GlobalStates.caffeine; onToggled: GlobalStates.caffeine = !GlobalStates.caffeine }
}
```

<!-- ex:## Module 2 -->
::: exercise practice | Night light tile
Add a "Night light" tile that runs `hyprsunset -t 4000` when on and kills it when off.
--- solution
```qml
CCTile { icon: "nightlight"; label: "Night light"; active: night.running; onToggled: night.running = !night.running }
Process { id: night; command: ["hyprsunset", "-t", "4000"] }
```
Setting `running: false` stops the process, which restores normal colors.
:::


## Module 3: Big slider

<div class="preview"><svg width="340" height="70" viewBox="0 0 340 70"><rect x="20" y="15" width="300" height="40" rx="20" fill="#313244"/><rect x="20" y="15" height="40" rx="20" fill="#cba6f7"><animate attributeName="width" values="80;240;160;80" dur="4s" repeatCount="indefinite"/></rect><text x="38" y="41" font-size="16" fill="#1e1e2e">🔊</text></svg></div>

The icon sits inside the fill, a phone-style "thick" slider. The icon flips color depending on whether the fill reaches it.

```qml file="rice/controlcenter/CCSlider.qml"
import QtQuick
import QtQuick.Controls
import qs.services
import qs.widgets

Slider {
    id: s
    property string icon: "volume_up"
    property color tint: Theme.accent
    signal iconClicked()
    from: 0; to: 1
    implicitHeight: 42
    background: Rectangle {
        anchors.fill: parent
        radius: Theme.style === "neon" ? 0 : height / 2
        color: Theme.surface
        border.width: Theme.border; border.color: Theme.borderColor
        Rectangle {
            width: Math.max(parent.height, s.visualPosition * parent.width)
            height: parent.height
            radius: parent.radius
            color: s.tint
            Behavior on width { enabled: !s.pressed; NumberAnimation { duration: Theme.fast } }
        }
        TIcon {
            x: 13; anchors.verticalCenter: parent.verticalCenter
            icon: s.icon; size: 20; fill: 1
            color: s.visualPosition * parent.width > 34 ? Theme.onAccent : Theme.fg
            TapHandler { onTapped: s.iconClicked() }
        }
        TText {
            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
            text: Math.round(s.value * 100); font.pixelSize: Theme.textSmall
            color: s.visualPosition > 0.9 ? Theme.onAccent : Theme.fgDim
            font.features: ({ "tnum": 1 })
        }
    }
    handle: Item {}
}
```

<!-- ex:## Module 3 -->
::: exercise practice | Click the icon to mute
`CCSlider` already emits `iconClicked`. Make the volume slider's icon mute, and show the fill in `Theme.fgDim` while muted.
--- solution
```qml
CCSlider { icon: Audio.icon; tint: Audio.muted ? Theme.fgDim : Theme.accent
           value: Audio.volume; onMoved: Audio.setVolume(value); onIconClicked: Audio.toggleMute() }
```
:::


## Module 4: Media card

```qml file="rice/controlcenter/CCMedia.qml"
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.widgets

ClippingRectangle {
    id: card
    readonly property var p: Media.active
    visible: p !== null
    implicitHeight: 92
    radius: Theme.radius
    color: Theme.surface

    // album art as a blurred, tinted background
    Image { id: art; anchors.fill: parent; source: card.p?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(200, 100); visible: false }
    MultiEffect { anchors.fill: art; source: art; blurEnabled: true; blur: 1; blurMax: 40; brightness: -0.35; saturation: 0.2; visible: art.status === Image.Ready }

    RowLayout {
        anchors { fill: parent; margins: 12 }
        spacing: 12
        ClippingRectangle { implicitWidth: 68; implicitHeight: 68; radius: Theme.radiusSmall + 2; color: Theme.accent
            Image { anchors.fill: parent; source: card.p?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(136, 136) } }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 2
            TText { Layout.fillWidth: true; text: card.p?.trackTitle ?? ""; font.bold: true; color: "white" }
            TText { Layout.fillWidth: true; text: card.p?.trackArtist ?? ""; color: "#ffffffbb"; font.pixelSize: Theme.textSmall }
            Rectangle { Layout.fillWidth: true; Layout.topMargin: 6; implicitHeight: 3; radius: 1.5; color: "#ffffff33"
                Rectangle { width: parent.width * (card.p?.position ?? 0) / Math.max(1, card.p?.length ?? 1); height: parent.height; radius: 1.5; color: "white" } }
        }
        TButton { icon: "skip_previous"; size: 30; onClicked: card.p.previous() }
        TButton { icon: card.p?.isPlaying ? "pause" : "play_arrow"; size: 38; toggled: true; onClicked: card.p.togglePlaying() }
        TButton { icon: "skip_next"; size: 30; onClicked: card.p.next() }
    }
}
```

<!-- ex:## Module 4 -->
::: exercise practice | Seek by clicking
Click on the progress line to seek to that position.
--- solution
```qml
TapHandler { onTapped: ev => card.p.position = card.p.length * ev.position.x / parent.width }
```
Only works when `card.p.canSeek` is true; hide the handler otherwise.
:::


## Module 5: Week strip

```qml file="rice/controlcenter/CCWeek.qml"
import Quickshell
import QtQuick
import qs.services
import qs.widgets

Row {
    spacing: 6
    SystemClock { id: clock; precision: SystemClock.Hours }
    readonly property date monday: { const d = new Date(clock.date); d.setDate(d.getDate() - (d.getDay() + 6) % 7); return d }
    Repeater {
        model: 7
        Rectangle {
            required property int index
            readonly property date day: new Date(parent.monday.getFullYear(), parent.monday.getMonth(), parent.monday.getDate() + index)
            readonly property bool today: day.toDateString() === clock.date.toDateString()
            width: 38; height: 52; radius: Theme.style === "neon" ? 0 : 19
            color: today ? Theme.accent : Theme.surface
            Column {
                anchors.centerIn: parent
                TText { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(parent.parent.day, "ddd").slice(0, 2)
                        font.pixelSize: 10; color: parent.parent.today ? Theme.onAccent : Theme.fgDim }
                TText { anchors.horizontalCenter: parent.horizontalCenter; text: parent.parent.day.getDate()
                        font.bold: true; color: parent.parent.today ? Theme.onAccent : Theme.fg }
            }
        }
    }
}
```

<!-- ex:## Module 5 -->
::: exercise practice | Click a day
Clicking a day of the week strip opens your calendar app (`gnome-calendar`, `khal` in a terminal…) on that date.
:::


## Module 6: Notification history (grouped by app)

```qml file="rice/controlcenter/CCHistory.qml"
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets
import qs.rice.notifications

ColumnLayout {
    id: hist
    spacing: 8
    readonly property var groups: {
        const g = {}
        for (const n of [...Notifs.list].reverse()) (g[n.appName] = g[n.appName] ?? []).push(n)
        return Object.keys(g).map(k => ({ app: k, items: g[k] }))
    }
    RowLayout {
        TText { text: "Notifications"; font.bold: true; Layout.fillWidth: true }
        TButton { icon: "clear_all"; size: 30; onClicked: Notifs.clearAll() }
    }
    Flickable {
        Layout.fillWidth: true; Layout.fillHeight: true
        clip: true
        contentHeight: groupCol.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: groupCol
            width: parent.width
            spacing: 12
            Repeater {
                model: hist.groups
                Column {
                    required property var modelData
                    width: groupCol.width
                    spacing: 6
                    property bool open: modelData.items.length <= 2
                    RowLayout {
                        width: parent.width
                        TText { text: modelData.app + "  (" + modelData.items.length + ")"; color: Theme.fgDim; font.pixelSize: Theme.textSmall; Layout.fillWidth: true }
                        TIcon { icon: parent.parent.open ? "expand_less" : "expand_more"; size: 18; color: Theme.fgDim
                                TapHandler { onTapped: parent.parent.parent.open = !parent.parent.parent.open } }
                    }
                    Repeater {
                        model: parent.open ? modelData.items : modelData.items.slice(0, 1)   // collapsed: show newest only
                        NotifCard { required property var modelData; notif: modelData; popup: false; width: groupCol.width }
                    }
                }
            }
        }
        TText { anchors.centerIn: parent; visible: Notifs.count === 0; text: "All caught up ✨"; color: Theme.fgDim }
    }
}
```

<!-- ex:## Module 6 -->
::: exercise practice | Swipe a group away
Add a ✕ to each group header that dismisses every notification of that app.
--- solution
```qml
TIcon { icon: "close"; size: 16; TapHandler { onTapped: modelData.items.forEach(n => n.dismiss()) } }
```
:::


## Assembly: three layouts

```qml file="rice/controlcenter/ControlCenter.qml"
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Scope {
    id: root
    property string layout: "sidebar"          // "sidebar" | "dropdown" | "dashboard"

    PanelWindow {
        id: win
        readonly property bool open: GlobalStates.controlCenterOpen
        screen: Quickshell.screens.find(s => s.name === GlobalStates.activeScreen) ?? null
        visible: open || slide.running
        anchors {
            top: true
            right: root.layout !== "dashboard"
            bottom: root.layout === "sidebar"
        }
        margins { top: Theme.barHeight + 14; right: 8; bottom: 8 }
        implicitWidth: root.layout === "dashboard" ? 760 : 400
        implicitHeight: root.layout === "dropdown" ? 520 : root.layout === "dashboard" ? 460 : 0
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:controlcenter"
        HyprlandFocusGrab { windows: [win]; active: win.open; onCleared: GlobalStates.controlCenterOpen = false }

        TSurface {
            id: panel
            width: parent.width; height: parent.height
            color: Theme.bg
            radius: Theme.radius + 6
            raised: true
            // sidebar slides from the right, dropdown/dashboard drop from the top
            x: root.layout === "sidebar" && !win.open ? width + 20 : 0
            y: root.layout !== "sidebar" && !win.open ? -height - 20 : 0
            opacity: win.open ? 1 : 0
            Behavior on x { NumberAnimation { id: slide; duration: Theme.slow; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: Theme.normal } }

            // one column (sidebar / dropdown)
            ColumnLayout {
                visible: root.layout !== "dashboard"
                anchors { fill: parent; margins: 16 }
                spacing: 14
                CCHeader { Layout.fillWidth: true }
                CCTiles { Layout.fillWidth: true }
                CCSlider { Layout.fillWidth: true; icon: Audio.icon; value: Audio.volume; onMoved: Audio.setVolume(value); onIconClicked: Audio.toggleMute() }
                CCSlider { Layout.fillWidth: true; icon: "light_mode"; tint: Theme.warn; visible: Brightness.available; value: Brightness.value; onMoved: Brightness.set(value) }
                CCMedia { Layout.fillWidth: true }
                CCHistory { Layout.fillWidth: true; Layout.fillHeight: true; visible: root.layout === "sidebar" }
            }

            // two columns (dashboard)
            RowLayout {
                visible: root.layout === "dashboard"
                anchors { fill: parent; margins: 18 }
                spacing: 18
                ColumnLayout {
                    Layout.preferredWidth: 340; Layout.fillHeight: true; spacing: 14
                    CCHeader { Layout.fillWidth: true }
                    CCWeek {}
                    CCTiles { Layout.fillWidth: true }
                    CCSlider { Layout.fillWidth: true; icon: Audio.icon; value: Audio.volume; onMoved: Audio.setVolume(value) }
                    Item { Layout.fillHeight: true }
                }
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true; spacing: 14
                    CCMedia { Layout.fillWidth: true }
                    CCHistory { Layout.fillWidth: true; Layout.fillHeight: true }
                }
            }
        }
    }
}
```

<div class="preview"><svg width="660" height="200" viewBox="0 0 660 200"><g font-size="10"><g transform="translate(5 5)"><rect width="210" height="170" rx="8" fill="#26233a"/><rect x="120" y="8" width="84" height="156" rx="12" fill="#1e1e2e"/><rect x="128" y="20" width="32" height="18" rx="8" fill="#cba6f7"/><rect x="164" y="20" width="32" height="18" rx="9" fill="#313244"/><rect x="128" y="46" width="68" height="10" rx="5" fill="#cba6f7"/><rect x="128" y="62" width="68" height="24" rx="8" fill="#313244"/><rect x="128" y="94" width="68" height="60" rx="8" fill="#313244" opacity=".6"/><text x="105" y="190" fill="#a6adc8" text-anchor="middle">sidebar</text></g><g transform="translate(225 5)"><rect width="210" height="170" rx="8" fill="#26233a"/><rect x="110" y="8" width="94" height="110" rx="12" fill="#1e1e2e"/><rect x="118" y="20" width="36" height="18" rx="8" fill="#cba6f7"/><rect x="158" y="20" width="36" height="18" rx="9" fill="#313244"/><rect x="118" y="46" width="76" height="10" rx="5" fill="#cba6f7"/><rect x="118" y="64" width="76" height="40" rx="8" fill="#313244"/><text x="105" y="190" fill="#a6adc8" text-anchor="middle">dropdown</text></g><g transform="translate(445 5)"><rect width="210" height="170" rx="8" fill="#26233a"/><rect x="15" y="8" width="180" height="120" rx="12" fill="#1e1e2e"/><rect x="24" y="18" width="72" height="18" rx="8" fill="#cba6f7"/><rect x="24" y="42" width="72" height="18" rx="9" fill="#313244"/><rect x="24" y="66" width="72" height="10" rx="5" fill="#cba6f7"/><rect x="104" y="18" width="82" height="36" rx="8" fill="#313244"/><rect x="104" y="60" width="82" height="58" rx="8" fill="#313244" opacity=".6"/><text x="105" y="190" fill="#a6adc8" text-anchor="middle">dashboard</text></g></g></svg></div>

<!-- ex:## Assembly -->
::: exercise challenge | Pages
Add a page system: tapping the Wi-Fi tile's arrow slides the content left to a Wi-Fi list page with a back button.
--- hint
Wrap the column in a `StackView`, or put both pages in a `Row` inside a clipped `Item` and animate the row's `x` between `0` and `-width`.
:::


## Polish checklist

- [ ] Tiles show **state** in their sublabel (network name, connected device), not just on/off.
- [ ] Active tiles change both color **and** shape (accessible to color-blind users).
- [ ] Sliders follow external changes (media keys) smoothly but stick to the cursor while dragging.
- [ ] Media card hides when nothing plays.
- [ ] Opening the panel doesn't steal focus from your app unless you click in a text field (`OnDemand` focus).
- [ ] Notification groups collapse when an app sends many.
- [ ] Closing: Esc, click outside, or the bar button again.

<!-- ex:## Polish checklist -->
## Practice

::: exercise project | Tile editor
Store the list of tiles in `Config` (`["wifi", "bt", "dnd", "caffeine"]`) and build them with a `Repeater` and a lookup table, so users can reorder and remove tiles in `config.json`.
:::

