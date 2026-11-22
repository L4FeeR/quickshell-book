# Ricing the Bar, Module by Module

The bar is the part of your rice you look at most. This guide builds it from small, independent modules that all follow the [[ch:r0-theme-system|Theme]], then assembles them into three layouts (full, floating, islands) chosen by one theme value.

**Services used:** `Audio`, `Battery`, `Network`, `Media`, `Notifs`, `GlobalStates` from earlier chapters ([[ch:33-singletons]], [[ch:47-proj-bar]], [[ch:51-proj-notifications]]).

## Anatomy

<div class="preview"><svg width="640" height="120" viewBox="0 0 640 120"><rect x="10" y="20" width="620" height="40" rx="14" fill="#1e1e2e"/><g font-size="10" fill="#1e1e2e" font-weight="700"><rect x="18" y="26" width="28" height="28" rx="14" fill="#cba6f7"/><rect x="54" y="28" width="110" height="24" rx="12" fill="#313244"/><rect x="62" y="35" width="26" height="10" rx="5" fill="#cba6f7"/><g fill="#a6adc8"><circle cx="100" cy="40" r="3.5"/><circle cx="114" cy="40" r="3.5"/><circle cx="128" cy="40" r="3.5"/><circle cx="142" cy="40" r="3.5"/></g><rect x="172" y="28" width="120" height="24" rx="12" fill="#313244" opacity=".6"/><rect x="280" y="28" width="80" height="24" rx="12" fill="#313244"/><rect x="420" y="28" width="70" height="24" rx="12" fill="#45365e"/><rect x="496" y="28" width="40" height="24" rx="12" fill="#313244"/><rect x="542" y="28" width="56" height="24" rx="12" fill="#313244"/><rect x="602" y="26" width="24" height="28" rx="12" fill="#313244"/></g><g fill="#a6adc8" font-size="10" text-anchor="middle"><text x="32" y="80">Logo</text><text x="109" y="80">Workspaces</text><text x="232" y="80">Window title</text><text x="320" y="96">Clock</text><text x="455" y="80">Media</text><text x="516" y="96">Tray</text><text x="570" y="80">Status</text><text x="614" y="96">Bell</text></g><g stroke="#585b70"><path d="M320 52v32M516 52v32M614 54v30"/></g></svg></div>

| Module | File | Job |
|---|---|---|
| Container | `BarWindow.qml` | the window: per screen, position, layout style, reserves space |
| Island | `Island.qml` | a themed group background (used by every module group) |
| Logo | `Logo.qml` | distro/launcher button |
| Workspaces | `Workspaces.qml` | workspace indicator |
| Window title | `WindowTitle.qml` | focused app icon + title |
| Clock | `Clock.qml` | time, date on hover, calendar on click |
| Media | `MediaModule.qml` | current song, controls on hover |
| Tray | `Tray.qml` | system tray icons |
| Status | `Status.qml` | network, Bluetooth, volume, battery |
| Bell | `Bell.qml` | notifications / control center button |

## Module 1: Island (the group background)

Every group of modules sits on an `Island`. In **full** and **floating** layouts islands are transparent (the bar itself is the background); in the **islands** layout each island gets its own surface. One component, three looks.

```qml file="rice/bar/Island.qml"
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

TSurface {
    id: root
    default property alias content: row.data
    readonly property bool standalone: Theme.layout === "islands"

    implicitWidth: row.implicitWidth + (standalone ? 14 : 4)
    implicitHeight: Theme.barHeight - (standalone ? 0 : 8)
    color: standalone ? Theme.bg : "transparent"
    border.width: standalone ? Theme.border : 0
    radius: standalone ? Theme.radius : 0
    layer.enabled: standalone && Theme.glow

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.gap
    }
}
```

**Why:** the layout decision lives in one place. Modules never know whether they're in a full bar, a floating bar or on an island.

<!-- ex:## Module 1 -->
::: exercise warm | Island padding
Make island padding a property (`property int pad: 6`) and give the right-hand island more padding than the others.
--- hint
Island's implicit size comes from its row plus padding; replace the hard-coded padding with `pad`.
:::


## Module 2: Logo / Launcher Button

<div class="preview"><svg width="200" height="70" viewBox="0 0 200 70"><rect x="80" y="17" width="36" height="36" rx="18" fill="#cba6f7"><animate attributeName="rx" values="18;10;18" dur="3s" repeatCount="indefinite"/></rect><text x="98" y="41" font-size="18" text-anchor="middle" fill="#1e1e2e">❄</text></svg></div>

```qml file="rice/bar/Logo.qml"
import Quickshell
import QtQuick
import qs.services
import qs.widgets

Rectangle {
    id: root
    implicitWidth: Theme.barHeight - 10
    implicitHeight: implicitWidth
    radius: hover.hovered || GlobalStates.launcherOpen ? Theme.radiusSmall : width / 2
    color: Theme.accent
    Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

    // distro logo from a Nerd Font, or an icon-theme logo, or a Material Symbol
    TText {
        anchors.centerIn: parent
        text: ""                                   // nf-linux-archlinux (needs a Nerd Font)
        font.family: "Symbols Nerd Font"
        font.pixelSize: parent.width * 0.55
        color: Theme.onAccent
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: GlobalStates.toggle("launcher") }
    TapHandler { acceptedButtons: Qt.RightButton; onTapped: GlobalStates.toggle("session") }
}
```

**Ricing choices**
- **Logo source:** a Nerd Font glyph (`` Arch, `` NixOS, `` Debian, `` Fedora), a Material Symbol (`apps`, `grid_view`), or an image: `IconImage { source: Quickshell.iconPath("distributor-logo-archlinux") }`.
- **Shape:** circle → rounded square on hover (M3 style); for neon, keep it square with a glowing border.

<!-- ex:## Module 2 -->
::: exercise practice | Distro logo
Make the logo show your distro's icon from the icon theme (for example `archlinux-logo` or `distributor-logo`) instead of a font glyph.
--- solution
```qml
IconImage { implicitSize: 18; source: Quickshell.iconPath("distributor-logo", "start-here") }
```
:::


## Module 3: Workspaces

<div class="preview"><svg width="320" height="70" viewBox="0 0 320 70"><rect x="40" y="20" width="240" height="30" rx="15" fill="#313244"/><rect y="28" height="14" rx="7" fill="#cba6f7"><animate attributeName="x" values="52;52;92;92;132;132;52" keyTimes="0;.2;.3;.5;.6;.85;1" dur="5s" repeatCount="indefinite"/><animate attributeName="width" values="30;30;30;30;30;30;30" dur="5s" repeatCount="indefinite"/></rect><g fill="#cdd6f4" font-size="11" text-anchor="middle" font-weight="700"><text x="67" y="39">1</text><text x="107" y="39">2</text><text x="147" y="39">3</text><text x="187" y="39" fill="#6c7086">4</text><text x="227" y="39" fill="#6c7086">5</text><text x="262" y="39" fill="#f38ba8">6</text></g></svg></div>

Three display styles from one file, selected with a property: `"dots"`, `"numbers"` or `"icons"` (app icons of each workspace).

```qml file="rice/bar/Workspaces.qml"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import qs.services
import qs.widgets

Item {
    id: root
    required property ShellScreen screen
    property string display: Theme.style === "neon" ? "numbers" : "dots"   // "dots" | "numbers" | "icons"
    property int count: 8
    readonly property int active: Hyprland.monitorFor(screen)?.activeWorkspace?.id ?? 1
    readonly property int slot: display === "dots" ? 18 : 26

    implicitWidth: row.implicitWidth + 12
    implicitHeight: Theme.barHeight - 12

    Rectangle {                                           // track
        anchors.fill: parent
        radius: Theme.radiusSmall + 4
        color: Theme.surface
        visible: Theme.layout !== "islands"
    }
    Rectangle {                                           // sliding active indicator
        readonly property Item t: rep.itemAt(root.active - 1)
        x: row.x + (t?.x ?? 0) - 2
        width: (t?.width ?? 0) + 4
        height: root.display === "dots" ? 12 : root.height - 6
        anchors.verticalCenter: parent.verticalCenter
        radius: Math.min(height / 2, Theme.radiusSmall + 2)
        color: Theme.accent
        Behavior on x { NumberAnimation { duration: Theme.normal + 50; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
        Behavior on width { NumberAnimation { duration: Theme.normal } }
    }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4
        Repeater {
            id: rep
            model: root.count
            Item {
                id: cell
                required property int index
                readonly property int wsId: index + 1
                readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                readonly property bool isActive: wsId === root.active
                readonly property bool occupied: (ws?.toplevels.values.length ?? 0) > 0
                width: root.display === "dots" ? (isActive ? 26 : root.slot) : root.slot
                height: root.height
                Behavior on width { NumberAnimation { duration: Theme.normal } }

                Rectangle {                                // dots
                    visible: root.display === "dots" && !cell.isActive
                    anchors.centerIn: parent
                    width: 7; height: 7; radius: 3.5
                    color: cell.ws?.urgent ? Theme.bad : cell.occupied ? Theme.fgDim : Theme.alpha(Theme.fgDim, 0.3)
                }
                TText {                                    // numbers
                    visible: root.display === "numbers"
                    anchors.centerIn: parent
                    text: cell.wsId
                    font.family: Theme.mono; font.bold: true; font.pixelSize: Theme.textSmall
                    color: cell.isActive ? Theme.onAccent : cell.ws?.urgent ? Theme.bad : cell.occupied ? Theme.fg : Theme.alpha(Theme.fgDim, 0.5)
                }
                IconImage {                                // icons: first app on that workspace
                    visible: root.display === "icons"
                    anchors.centerIn: parent
                    implicitSize: 16
                    opacity: cell.occupied ? 1 : 0.3
                    source: cell.occupied
                        ? Quickshell.iconPath(DesktopEntries.heuristicLookup(cell.ws.toplevels.values[0]?.wayland?.appId ?? "")?.icon ?? "", "application-x-executable")
                        : ""
                }
                MouseArea { anchors.fill: parent; onClicked: Hyprland.dispatch("workspace " + cell.wsId) }
            }
        }
    }
    WheelHandler { onWheel: e => Hyprland.dispatch(e.angleDelta.y > 0 ? "workspace r-1" : "workspace r+1") }
}
```

**Ricing choices**
- **Indicator shape:** pill (catppuccin), full-height block (neon/nord), underline (put a 3 px rectangle at the bottom instead).
- **Motion:** `OutBack` bounce for playful styles; plain `OutCubic` for calm ones. See [[ch:a5-morphs|stretchy indicators]] for the liquid look.
- **Empty workspaces:** faint (30% alpha) rather than hidden, so positions stay stable.

<!-- ex:## Module 3 -->
::: exercise practice | Occupied counts
In `numbers` mode, show a tiny dot under each workspace number that has windows.
--- hint
`Hyprland.workspaces.values.find(w => w.id === index + 1)?.toplevels.values.length > 0`
:::

::: exercise challenge | Scroll to switch
Scroll over the workspaces module to go to the next/previous workspace.
--- solution
```qml
WheelHandler {
    onWheel: e => Hyprland.dispatch(e.angleDelta.y < 0 ? "workspace e+1" : "workspace e-1")
}
```
If you configure Hyprland in Lua, use the Lua dispatch form from [[ch:40-compositors]].
:::


## Module 4: Window Title

```qml file="rice/bar/WindowTitle.qml"
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

RowLayout {
    id: root
    property int maxWidth: 300
    readonly property Toplevel win: ToplevelManager.activeToplevel
    readonly property var entry: DesktopEntries.heuristicLookup(win?.appId ?? "")
    visible: win !== null
    spacing: 6

    IconImage {
        implicitSize: 16
        source: Quickshell.iconPath(root.entry?.icon ?? "", "application-x-executable")
    }
    ColumnLayout {
        spacing: -2
        Layout.maximumWidth: root.maxWidth
        TText {                                   // app name, small and dim
            text: root.entry?.name ?? root.win?.appId ?? ""
            font.pixelSize: Theme.textSmall - 1
            color: Theme.fgDim
            Layout.fillWidth: true
        }
        TText {                                   // window title
            text: root.win?.title ?? ""
            font.pixelSize: Theme.textSmall + 1
            Layout.fillWidth: true
        }
    }
}
```

**Ricing choices:** two-line "app name over title" (as above) looks refined in tall bars; a single line fits slim bars. For minimal rices, show only the app name.

<!-- ex:## Module 4 -->
::: exercise practice | Class instead of title
Add `property bool showClass: false` that shows the app's name (from its desktop entry) instead of the window title.
--- solution
```qml
text: showClass ? (entry?.name ?? win?.appId ?? "") : (win?.title ?? "")
```
:::


## Module 5: Clock

<div class="preview"><svg width="300" height="70" viewBox="0 0 300 70"><rect x="80" y="20" width="140" height="30" rx="15" fill="#313244"/><text x="150" y="40" fill="#cdd6f4" font-size="13" text-anchor="middle"><tspan fill="#a6adc8">Fri 21</tspan>  <tspan font-weight="800">14:32</tspan></text></svg></div>

```qml file="rice/bar/Clock.qml"
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Rectangle {
    id: root
    property bool showDate: true
    property bool use24h: true
    SystemClock { id: clock; precision: SystemClock.Minutes }

    implicitWidth: row.implicitWidth + 20
    implicitHeight: Theme.barHeight - 12
    radius: Theme.radiusSmall + 4
    color: hover.hovered ? Theme.surfaceHi : (Theme.layout === "islands" ? "transparent" : Theme.surface)
    Behavior on color { ColorAnimation { duration: Theme.fast } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8
        TText {
            visible: root.showDate
            text: Qt.formatDateTime(clock.date, hover.hovered ? "dddd, d MMMM" : "ddd d")
            color: Theme.fgDim
        }
        TText {
            text: Qt.formatDateTime(clock.date, root.use24h ? "hh:mm" : "h:mm AP")
            font.bold: true
            font.family: Theme.style === "neon" ? Theme.mono : Theme.font
            font.features: ({ "tnum": 1 })
        }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    // click → calendar popup: see Chapter 49
}
```

**Ricing choices**
- **Typography is the whole design here:** bold time + dim date is the classic hierarchy; for neon, monospace and uppercase (`font.capitalization: Font.AllUppercase`).
- Truly center it: anchor it to the bar's center, not inside the left/right layouts.

<!-- ex:## Module 5 -->
::: exercise practice | Seconds on hover
Show seconds only while the clock is hovered.
--- hint
`SystemClock.precision` can be bound: `precision: hover.hovered ? SystemClock.Seconds : SystemClock.Minutes`.
:::


## Module 6: Media

```qml file="rice/bar/MediaModule.qml"
import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Rectangle {
    id: root
    readonly property MprisPlayer p: Mpris.players.values.find(pl => pl.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property bool open: hover.hovered
    visible: p !== null && p.trackTitle !== ""

    implicitWidth: row.implicitWidth + 16
    implicitHeight: Theme.barHeight - 12
    radius: height / 2
    color: Theme.alpha(Theme.accent, 0.18)
    clip: true
    Behavior on implicitWidth { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

    RowLayout {
        id: row
        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
        spacing: 8
        ClippingRectangle {
            implicitWidth: root.height - 8; implicitHeight: implicitWidth; radius: implicitWidth / 2
            color: Theme.accent
            Image { anchors.fill: parent; source: root.p?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(48, 48) }
            RotationAnimator on rotation { running: root.p?.isPlaying ?? false; from: 0; to: 360; duration: 8000; loops: Animation.Infinite }
        }
        TText { text: root.p?.trackTitle ?? ""; Layout.maximumWidth: root.open ? 240 : 140; color: Theme.fg }
        Repeater {
            model: root.open ? ["skip_previous", root.p?.isPlaying ? "pause" : "play_arrow", "skip_next"] : []
            TIcon {
                required property string modelData
                required property int index
                icon: modelData; size: 18; fill: 1; color: Theme.accent
                TapHandler { onTapped: [() => root.p.previous(), () => root.p.togglePlaying(), () => root.p.next()][parent.index]() }
            }
        }
        Item { implicitWidth: 2 }
    }
    HoverHandler { id: hover }
    TapHandler { acceptedButtons: Qt.MiddleButton; onTapped: root.p.togglePlaying() }
}
```

**Ricing choices:** a tinted accent background (18% alpha) separates media from neutral status modules. The spinning cover art is a small delight; disable it for calm styles.

<!-- ex:## Module 6 -->
::: exercise practice | Progress underline
Draw a 2 px progress line under the media module showing `p.position / p.length`.
--- solution
```qml
Rectangle { anchors { left: parent.left; bottom: parent.bottom }; height: 2; color: Theme.accent
    width: parent.width * ((p?.position ?? 0) / Math.max(1, p?.length ?? 1)) }
```
Position only updates when you ask for it: add `Timer { running: p?.isPlaying ?? false; interval: 1000; repeat: true; onTriggered: p.positionChanged() }`.
:::


## Module 7: Tray

```qml file="rice/bar/Tray.qml"
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import qs.services

Row {
    id: root
    spacing: Theme.gap - 2
    visible: SystemTray.items.values.length > 0
    Repeater {
        model: SystemTray.items
        IconImage {
            id: ic
            required property SystemTrayItem modelData
            implicitSize: 16
            source: modelData.icon
            opacity: hover.hovered ? 1 : 0.8
            scale: hover.hovered ? 1.15 : 1
            Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutBack } }
            HoverHandler { id: hover }
            QsMenuAnchor { id: menu; menu: ic.modelData.menu; anchor.item: ic; anchor.edges: Edges.Bottom; anchor.gravity: Edges.Bottom }
            TapHandler { onTapped: ic.modelData.onlyMenu ? menu.open() : ic.modelData.activate() }
            TapHandler { acceptedButtons: Qt.RightButton; onTapped: if (ic.modelData.hasMenu) menu.open() }
        }
    }
}
```

**Ricing choices:** tray icons are full-color app icons and often clash with a themed bar. Options: lower their opacity (as here), desaturate them with `MultiEffect { saturation: -1 }`, or tuck them into an overflow popup. Custom-drawn menus: [[ch:50-proj-tray]].

<!-- ex:## Module 7 -->
::: exercise practice | Hide passive icons
Hide tray items whose `status` is `Status.Passive`.
--- solution
```qml
model: ScriptModel { values: SystemTray.items.values.filter(i => i.status !== Status.Passive) }
```
:::


## Module 8: Status

<div class="preview"><svg width="260" height="70" viewBox="0 0 260 70"><rect x="50" y="20" width="160" height="30" rx="15" fill="#313244"/><g fill="#cdd6f4" font-size="13"><text x="66" y="40">📶</text><text x="92" y="40">ᛒ</text><text x="110" y="40">🔊</text><text x="140" y="40">🔋</text><text x="160" y="39" font-size="11">81%</text></g></svg></div>

```qml file="rice/bar/Status.qml"
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Rectangle {
    id: root
    implicitWidth: row.implicitWidth + 20
    implicitHeight: Theme.barHeight - 12
    radius: Theme.radiusSmall + 4
    color: hover.hovered ? Theme.surfaceHi : (Theme.layout === "islands" ? "transparent" : Theme.surface)
    Behavior on color { ColorAnimation { duration: Theme.fast } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 10
        TIcon { icon: Network.icon; size: 16; fill: Network.online ? 1 : 0 }
        TIcon {
            visible: Bluetooth.defaultAdapter?.enabled ?? false
            icon: Bluetooth.devices.values.some(d => d.connected) ? "bluetooth_connected" : "bluetooth"
            size: 16
        }
        TIcon {
            icon: Audio.icon; size: 16
            WheelHandler { onWheel: e => Audio.setVolume(Audio.volume + e.angleDelta.y / 120 * 0.05) }
            TapHandler { onTapped: Audio.toggleMute() }
        }
        RowLayout {
            visible: Battery.available
            spacing: 3
            TIcon { icon: Battery.icon; size: 16; rotation: 90; color: Battery.low ? Theme.bad : Battery.charging ? Theme.ok : Theme.fg }
            TText { text: Math.round(Battery.percent * 100) + "%"; font.pixelSize: Theme.textSmall; font.features: ({ "tnum": 1 }) }
        }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: GlobalStates.toggle("controlCenter") }
}
```

**Ricing choices:** group status icons into **one** chip that opens the control center; separate chips for each item make bars feel cluttered. Use color only for problems (low battery red, muted red), not decoration.

<!-- ex:## Module 8 -->
::: exercise practice | Battery color
Color the battery icon `Theme.bad` under 15%, `Theme.warn` under 30% and `Theme.ok` while charging.
--- solution
```qml
color: Battery.charging ? Theme.ok : Battery.percent < 0.15 ? Theme.bad : Battery.percent < 0.3 ? Theme.warn : Theme.fg
```
:::


## Module 9: Bell

```qml file="rice/bar/Bell.qml"
import QtQuick
import qs.services
import qs.widgets

TButton {
    icon: GlobalStates.dnd ? "notifications_off" : Notifs.count > 0 ? "notifications_unread" : "notifications"
    toggled: GlobalStates.controlCenterOpen
    size: Theme.barHeight - 10
    onClicked: GlobalStates.toggle("controlCenter")
    onRightClicked: GlobalStates.dnd = !GlobalStates.dnd
    Rectangle {
        visible: Notifs.count > 0 && !GlobalStates.dnd
        anchors { top: parent.top; right: parent.right }
        width: 8; height: 8; radius: 4; color: Theme.bad
    }
}
```

<!-- ex:## Module 9 -->
::: exercise practice | Count badge
Show the number of notifications on the bell (instead of a dot), hidden at 0, `9+` above 9.
--- solution
```qml
Rectangle { visible: Notifs.count > 0; anchors { right: parent.right; top: parent.top }
    width: Math.max(14, n.implicitWidth + 6); height: 14; radius: 7; color: Theme.bad
    TText { id: n; anchors.centerIn: parent; text: Notifs.count > 9 ? "9+" : Notifs.count; font.pixelSize: 9; color: "white" } }
```
:::


## Assembly: the bar window

The container reads `Theme.layout` and becomes a full-width bar, a floating bar, or a transparent strip holding separate islands.

```qml file="rice/bar/BarWindow.qml"
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: bar
            required property ShellScreen modelData
            screen: modelData
            readonly property string layout: Theme.layout
            readonly property int m: layout === "full" ? 0 : 8            // outer margin

            anchors { top: true; left: true; right: true }
            margins { top: m; left: m; right: m }
            implicitHeight: Theme.barHeight
            exclusiveZone: Theme.barHeight + m
            color: "transparent"
            WlrLayershell.namespace: "quickshell:bar"

            TSurface {                                         // the bar background (not used for islands)
                anchors.fill: parent
                visible: bar.layout !== "islands"
                color: Theme.barBg
                radius: bar.layout === "full" ? 0 : Theme.radius
                border.width: bar.layout === "full" ? 0 : Theme.border
            }
            Rectangle {                                        // full layout: hairline under the bar
                visible: bar.layout === "full" && (Theme.border > 0 || Theme.glow)
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1; color: Theme.borderColor
            }

            RowLayout {                                        // LEFT
                anchors { left: parent.left; leftMargin: bar.layout === "islands" ? 0 : 6; verticalCenter: parent.verticalCenter }
                spacing: Theme.gap
                Island { Logo {} Workspaces { screen: bar.modelData } }
                Island { WindowTitle { maxWidth: 280 } }
            }
            Island {                                           // CENTER (true center)
                anchors.centerIn: parent
                Clock {}
            }
            RowLayout {                                        // RIGHT
                anchors { right: parent.right; rightMargin: bar.layout === "islands" ? 0 : 6; verticalCenter: parent.verticalCenter }
                spacing: Theme.gap
                Island { MediaModule {} }
                Island { Tray {} Status {} Bell {} }
            }
        }
    }
}
```

<!-- ex:## Assembly -->
::: exercise challenge | Bottom bar
Add `property bool bottom: false` to `BarWindow` that moves the bar to the bottom edge (margins swap too).
--- hint
`anchors { top: !bottom; bottom: bottom; left: true; right: true }` and swap `margins.top`/`margins.bottom`.
:::


## Style variants

The same files, switched with `qs ipc call theme set <name>`:

<div class="preview"><svg width="660" height="250" viewBox="0 0 660 250"><g font-size="10"><text x="10" y="16" fill="#a6adc8">catppuccin: floating</text><rect x="10" y="22" width="640" height="34" rx="14" fill="#1e1e2e"/><circle cx="30" cy="39" r="11" fill="#cba6f7"/><rect x="48" y="30" width="90" height="18" rx="9" fill="#313244"/><rect x="56" y="34" width="22" height="10" rx="5" fill="#cba6f7"/><rect x="290" y="30" width="80" height="18" rx="9" fill="#313244"/><rect x="530" y="30" width="110" height="18" rx="9" fill="#313244"/><text x="10" y="80" fill="#a6adc8">material: full width</text><rect x="10" y="86" width="640" height="34" fill="#141218"/><rect x="18" y="92" width="22" height="22" rx="8" fill="#d0bcff"/><rect x="48" y="94" width="90" height="18" rx="9" fill="#211f26"/><rect x="54" y="96" width="30" height="14" rx="7" fill="#d0bcff"/><rect x="290" y="94" width="80" height="18" rx="9" fill="#211f26"/><rect x="530" y="94" width="110" height="18" rx="9" fill="#211f26"/><text x="10" y="144" fill="#a6adc8">neon: full, sharp, glowing</text><rect x="10" y="150" width="640" height="34" fill="#0a0a12"/><line x1="10" y1="184" x2="650" y2="184" stroke="#00f0ff" stroke-opacity=".7"/><rect x="18" y="156" width="22" height="22" fill="#00f0ff"/><rect x="48" y="158" width="90" height="18" fill="#14142a" stroke="#00f0ff" stroke-opacity=".4"/><rect x="50" y="160" width="18" height="14" fill="#00f0ff"/><text x="330" y="171" fill="#00f0ff" font-family="monospace" text-anchor="middle">14:32</text><rect x="530" y="158" width="110" height="18" fill="#14142a" stroke="#00f0ff" stroke-opacity=".4"/><text x="10" y="208" fill="#a6adc8">gruvbox: islands</text><rect x="10" y="214" width="150" height="32" rx="10" fill="#282828" stroke="#504945" stroke-width="2"/><circle cx="28" cy="230" r="10" fill="#fe8019"/><rect x="170" y="214" width="120" height="32" rx="10" fill="#282828" stroke="#504945" stroke-width="2"/><rect x="290" y="214" width="80" height="32" rx="10" fill="#282828" stroke="#504945" stroke-width="2"/><rect x="470" y="214" width="70" height="32" rx="10" fill="#282828" stroke="#504945" stroke-width="2"/><rect x="550" y="214" width="100" height="32" rx="10" fill="#282828" stroke="#504945" stroke-width="2"/></g></svg></div>

**More variations to try**
- **Vertical bar:** anchor `left, top, bottom`, swap `RowLayout`s for `ColumnLayout`s, and use the Clock's two-line `"hh\nmm"` format.
- **Bottom bar:** `anchors.bottom: true` instead of `top`; popups open upward ([[ch:32-popups-menus]]).
- **Minimal bar:** only Workspaces + Clock + Status; everything else lives in the control center.
- **Pill bar:** floating layout with `radius: height / 2` and generous side margins (e.g. `margins.left: 300`).

## Polish checklist

- [ ] All colors come from `Theme` (search your files for `"#`).
- [ ] Text baseline alignment: icons and text vertically centered; numbers use tabular figures.
- [ ] Consistent heights: every chip is `barHeight - 12`.
- [ ] Hover feedback on everything clickable, plus a pointer cursor.
- [ ] Scroll actions where natural: workspaces, volume.
- [ ] Nothing jumps: fixed widths on changing numbers, animated widths elsewhere.
- [ ] Popups line up with the bar edge and use the same radius.
- [ ] The bar hides or adapts in fullscreen ([[ch:g6-effects]]).
- [ ] Looks right in all your styles (`qs ipc call theme next`).

<!-- ex:## Polish checklist -->
## Practice

::: exercise project | A new module
Write a CPU module (`rice/bar/Cpu.qml`) in the same style: `TIcon` + `TText`, a tooltip on hover, `Theme.warn` color above 80%. Add it to the right island.
:::

::: exercise challenge | Vertical bar mode
Make `BarWindow` support a vertical layout on the left edge: switch the `RowLayout`s to `ColumnLayout`s with a `property bool vertical`.
--- hint
A `GridLayout` with `flow: vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight` lets one layout do both.
:::

