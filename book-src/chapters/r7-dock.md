# Ricing the Dock, Module by Module

A dock is one row of icons, but small details decide whether it feels like a toy or like macOS: smooth magnification, honest running indicators, a gentle auto-hide, and icons that bounce when you launch something. This guide builds the dock from modules and arranges it as a floating pill, a full-width shelf, or a vertical side dock.

**Logic** (pinning, matching windows to apps, the right-click menu) is explained in [[ch:59-proj-dock]]. Here we focus on the look and feel.

## Anatomy

<div class="preview"><svg width="520" height="150" viewBox="0 0 520 150"><rect x="70" y="60" width="380" height="64" rx="22" fill="#1e1e2e" stroke="#313244"/><g><rect x="86" y="72" width="40" height="40" rx="10" fill="#fab387"/><rect x="134" y="72" width="40" height="40" rx="10" fill="#89b4fa"/><rect x="180" y="50" width="56" height="56" rx="14" fill="#a6e3a1"/><rect x="244" y="62" width="46" height="46" rx="12" fill="#f5c2e7"/><rect x="298" y="72" width="40" height="40" rx="10" fill="#94e2d5"/><line x1="350" y1="74" x2="350" y2="110" stroke="#45475a" stroke-width="2"/><rect x="362" y="72" width="40" height="40" rx="10" fill="#585b70"/><rect x="410" y="78" width="28" height="28" rx="8" fill="#313244"/></g><g fill="#cba6f7"><circle cx="106" cy="118" r="2"/><rect x="200" y="116" width="16" height="4" rx="2"/><circle cx="263" cy="118" r="2"/><circle cx="271" cy="118" r="2"/></g><rect x="174" y="20" width="68" height="22" rx="6" fill="#313244"/><text x="208" y="35" fill="#cdd6f4" font-size="10" text-anchor="middle">Spotify</text><g fill="#585b70" font-size="9"><text x="380" y="140">separator · trash</text><text x="90" y="140">dots = windows, bar = focused</text></g></svg></div>

| Module | File | Job |
|---|---|---|
| Model | `DockModel.qml` | pinned + running apps, windows per app |
| Indicator | `DockIndicator.qml` | dots (one per window) or a bar when focused |
| Item | `DockItem.qml` | icon, magnification, launch bounce, tooltip, click behavior |
| Separator | `DockSeparator.qml` | divider between pinned and running-only apps |
| Window | `DockWindow.qml` | auto-hide, magnification math, three layouts |

## Module 1: Model

Gather the data once and give every item what it needs.

```qml file="rice/dock/DockModel.qml"
pragma Singleton
import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

Singleton {
    id: root
    property list<string> pinned: ["firefox", "kitty", "org.gnome.Nautilus", "spotify", "code"]

    function idOf(w) { return (w.appId ?? "").toLowerCase() }
    function windowsFor(appId) {
        const e = DesktopEntries.heuristicLookup(appId)
        const ids = [appId.toLowerCase(), (e?.startupClass ?? "").toLowerCase()]
        return ToplevelManager.toplevels.values.filter(w => ids.includes(idOf(w)))
    }

    // [{ id, pinned, separator }]: pinned apps, then a separator, then running apps that aren't pinned
    readonly property var items: {
        const lower = pinned.map(p => p.toLowerCase())
        const running = []
        for (const w of ToplevelManager.toplevels.values) {
            const id = idOf(w)
            if (id && !lower.includes(id) && !running.includes(id)
                && !lower.includes((DesktopEntries.heuristicLookup(id)?.id ?? "").toLowerCase())) running.push(id)
        }
        const out = pinned.map(id => ({ id, pinned: true, separator: false }))
        if (running.length) out.push({ id: "--sep--", pinned: false, separator: true })
        return out.concat(running.map(id => ({ id, pinned: false, separator: false })))
    }

    function togglePin(id) { pinned = pinned.includes(id) ? pinned.filter(p => p !== id) : [...pinned, id] }
}
```

<!-- ex:## Module 1 -->
::: exercise warm | Pin from the launcher
Add an IPC function `pin(id: string)` to `DockModel` that pins an app, and call it from a terminal.
--- solution
```qml
IpcHandler { target: "dock"; function pin(id: string): void { if (!root.pinned.includes(id)) root.pinned = [...root.pinned, id] } }
```
:::


## Module 2: Running indicator

<div class="preview"><svg width="420" height="70" viewBox="0 0 420 70"><g fill="#cba6f7"><circle cx="50" cy="35" r="3"/><text x="50" y="60" font-size="9" fill="#a6adc8" text-anchor="middle">1 window</text><circle cx="140" cy="35" r="3"/><circle cx="150" cy="35" r="3"/><circle cx="160" cy="35" r="3"/><text x="150" y="60" font-size="9" fill="#a6adc8" text-anchor="middle">3 windows</text><rect x="238" y="33" width="24" height="4" rx="2"/><text x="250" y="60" font-size="9" fill="#a6adc8" text-anchor="middle">focused</text><rect x="340" y="33" width="20" height="4" rx="2"><animate attributeName="width" values="4;20;4" dur="2s" repeatCount="indefinite"/></rect><text x="350" y="60" font-size="9" fill="#a6adc8" text-anchor="middle">animated</text></g></svg></div>

```qml file="rice/dock/DockIndicator.qml"
import QtQuick
import qs.services

Row {
    id: ind
    property int count: 0
    property bool focused: false
    property bool vertical: false
    spacing: 3
    visible: count > 0
    Repeater {
        model: ind.focused ? 1 : Math.min(ind.count, 3)
        Rectangle {
            // focused: a pill; otherwise one dot per window (max 3)
            width: ind.focused ? 18 : 5
            height: 4
            radius: 2
            color: ind.focused ? Theme.accent : Theme.alpha(Theme.fg, 0.6)
            Behavior on width { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.normal } }
        }
    }
    rotation: vertical ? 90 : 0
}
```

<!-- ex:## Module 2 -->
::: exercise practice | Urgent indicator
Turn the indicator red and make it pulse when one of the app's windows is urgent.
--- hint
`Toplevel` doesn't expose urgency on every compositor; on Hyprland, listen for the `urgent` raw event and keep a set of urgent window addresses.
:::


## Module 3: Dock item

The item doesn't compute its own size. The window passes a `zoom` factor (1.0 to ~1.6) based on how close the mouse is, so magnification is smooth across neighbors.

```qml file="rice/dock/DockItem.qml"
import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.services
import qs.widgets

Item {
    id: item
    required property string appId
    property real zoom: 1                         // set by DockWindow
    property int baseSize: 44
    property bool vertical: false
    property string edge: "bottom"                // which screen edge the dock is on; icons grow away from it

    readonly property DesktopEntry entry: DesktopEntries.heuristicLookup(appId)
    readonly property var windows: DockModel.windowsFor(appId)
    readonly property bool focused: windows.some(w => w.activated)

    implicitWidth: vertical ? baseSize * 1.7 : baseSize * zoom + 6
    implicitHeight: vertical ? baseSize * zoom + 6 : baseSize * 1.7

    IconImage {
        id: icon
        implicitSize: item.baseSize * item.zoom
        source: Quickshell.iconPath(item.entry?.icon ?? item.appId, "application-x-executable")
        asynchronous: true
        // stick to the dock edge and grow away from it
        x: item.edge === "left" ? 8 : item.edge === "right" ? parent.width - width - 8 : (parent.width - width) / 2
        y: item.edge === "bottom" ? parent.height - height - 12 : item.edge === "top" ? 12 : (parent.height - height) / 2
        transform: Translate { id: lift }
        opacity: press.pressed ? 0.7 : 1
    }

    // launch bounce: two hops away from the edge
    SequentialAnimation {
        id: bounce
        loops: 2
        NumberAnimation { target: lift; property: item.vertical ? "x" : "y"; to: item.edge === "bottom" || item.edge === "right" ? -14 : 14; duration: 220; easing.type: Easing.OutQuad }
        NumberAnimation { target: lift; property: item.vertical ? "x" : "y"; to: 0; duration: 260; easing.type: Easing.OutBounce }
    }

    DockIndicator {
        count: item.windows.length
        focused: item.focused
        vertical: item.vertical
        x: item.vertical ? (item.edge === "left" ? 0 : parent.width - 6) : (parent.width - width) / 2
        y: item.vertical ? (parent.height - height) / 2 : item.edge === "bottom" ? parent.height - 7 : 2
    }

    // tooltip
    Rectangle {
        visible: hover.hovered
        opacity: hover.hovered ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
        width: tip.implicitWidth + 16; height: 24
        radius: Theme.radiusSmall
        color: Theme.surface; border.width: Theme.border; border.color: Theme.borderColor
        x: item.vertical ? (item.edge === "left" ? icon.x + icon.width + 10 : icon.x - width - 10) : (parent.width - width) / 2
        y: item.vertical ? icon.y + (icon.height - height) / 2 : item.edge === "bottom" ? icon.y - height - 8 : icon.y + icon.height + 8
        TText { id: tip; anchors.centerIn: parent; text: item.entry?.name ?? item.appId; font.pixelSize: Theme.textSmall }
    }

    HoverHandler { id: hover }
    TapHandler {
        id: press
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onTapped: (ev, button) => {
            if (button === Qt.MiddleButton || item.windows.length === 0) {         // launch (new instance)
                item.entry?.execute(); bounce.restart(); return
            }
            const i = item.windows.findIndex(w => w.activated)                  // focus, or cycle through windows
            item.windows[(i + 1) % item.windows.length].activate()
        }
    }
    TapHandler { acceptedButtons: Qt.RightButton; onTapped: DockModel.togglePin(item.appId) }   // see ch. 59 for a full menu
}
```

**Ricing choices**
- Icons grow **away from the edge**, like macOS, and stay glued to it.
- Launch bounce plays only when you actually start an app.
- The indicator turns from dots into a pill for the focused app, which shows both "running" and "focused" at a glance.

<!-- ex:## Module 3 -->
::: exercise practice | Window count badge
Show a small number badge on the icon when the app has more than one window.
:::


## Module 4: Separator

```qml file="rice/dock/DockSeparator.qml"
import QtQuick
import qs.services

Item {
    property bool vertical: false
    implicitWidth: vertical ? 40 : 14
    implicitHeight: vertical ? 14 : 40
    Rectangle {
        anchors.centerIn: parent
        width: parent.vertical ? 28 : 2; height: parent.vertical ? 2 : 28
        radius: 1
        color: Theme.alpha(Theme.fg, 0.2)
    }
}
```

<!-- ex:## Module 4 -->
::: exercise practice | Trash
Add a trash icon after the separator that opens `trash://` in your file manager.
--- solution
```qml
TButton { icon: "delete"; onClicked: Quickshell.execDetached(["xdg-open", "trash://"]) }
```
:::


## Assembly: auto-hide, magnification, three layouts

**Magnification math.** For each icon, measure the distance from the mouse to the icon's center. Within `range` pixels, the zoom rises along a cosine curve to `maxZoom`. Neighbors get partial zoom, so the dock forms a smooth wave.

```text
zoom(d) = 1 + (maxZoom - 1) * (cos(π * d / range) + 1) / 2     when d < range, else 1
```

```qml file="rice/dock/DockWindow.qml"
import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services
import qs.widgets

Variants {
    id: root
    property string layout: "floating"     // "floating" | "shelf" | "side"
    property bool autoHide: true
    property real maxZoom: 1.6
    property real range: 140
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property ShellScreen modelData
        screen: modelData
        readonly property bool side: root.layout === "side"
        readonly property bool shelf: root.layout === "shelf"
        readonly property string edge: side ? "left" : "bottom"

        // reveal when the mouse touches the edge, or when there's no window on this screen
        readonly property bool empty: !ToplevelManager.toplevels.values.some(t => t.screens.includes(modelData))
        readonly property bool revealed: !root.autoHide || hoverArea.containsMouse || empty || GlobalStates.dockPinnedOpen

        anchors { bottom: !win.side; left: win.side || win.shelf; right: win.shelf; top: false }
        implicitWidth: win.side ? 110 : win.shelf ? 0 : row.implicitWidth + 200      // room for magnified icons
        implicitHeight: win.side ? col.implicitHeight + 200 : 110
        exclusionMode: root.autoHide ? ExclusionMode.Ignore : ExclusionMode.Auto
        exclusiveZone: root.autoHide ? 0 : 70
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:dock"
        // only the dock body (or the 2px trigger strip when hidden) takes input
        mask: Region { item: win.revealed ? body : trigger }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            property point pos: Qt.point(-1000, -1000)
            onPositionChanged: m => pos = Qt.point(m.x, m.y)
            onExited: pos = Qt.point(-1000, -1000)
        }
        Item {
            id: trigger
            width: win.side ? 2 : parent.width; height: win.side ? parent.height : 2
            x: 0; y: win.side ? 0 : parent.height - 2
        }

        TSurface {
            id: body
            color: Theme.barBg
            radius: win.shelf ? 0 : Theme.radius + 8
            raised: !win.shelf
            width: win.side ? 72 : win.shelf ? parent.width : row.implicitWidth + 20
            height: win.side ? col.implicitHeight + 20 : 68
            x: win.side ? (win.revealed ? 8 : -width - 4) : (parent.width - width) / 2
            y: win.side ? (parent.height - height) / 2 : parent.height - height - (win.shelf ? 0 : 8) + (win.revealed ? 0 : height + 12)
            Behavior on x { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: Theme.fast } }
        }

        // shared delegate logic: compute the zoom for each item from the mouse position
        function zoomFor(item) {
            if (!item) return 1
            const c = item.mapToItem(hoverArea, item.width / 2, item.height / 2)
            const d = win.side ? Math.abs(hoverArea.pos.y - c.y) : Math.abs(hoverArea.pos.x - c.x)
            return d < root.range ? 1 + (root.maxZoom - 1) * (Math.cos(Math.PI * d / root.range) + 1) / 2 : 1
        }

        Component {
            id: entryDelegate
            Loader {
                required property var modelData
                sourceComponent: modelData.separator ? sep : app
                Component { id: sep; DockSeparator { vertical: win.side } }
                Component { id: app; DockItem {
                    id: di
                    appId: modelData.id
                    vertical: win.side
                    edge: win.edge
                    zoom: win.shelf ? 1 : win.zoomFor(di)    // shelf: no magnification
                    Behavior on zoom { NumberAnimation { duration: 90 } }
                } }
            }
        }

        Row {
            id: row
            visible: !win.side
            anchors { horizontalCenter: body.horizontalCenter; bottom: body.bottom; bottomMargin: 0 }
            Repeater { model: DockModel.items; delegate: entryDelegate }
        }
        Column {
            id: col
            visible: win.side
            anchors { verticalCenter: body.verticalCenter; left: body.left }
            Repeater { model: DockModel.items; delegate: entryDelegate }
        }
    }
}
```

> [!NOTE] Why the window is bigger than the dock
> Magnified icons and tooltips stick out of the dock body. The window leaves room for them, and `mask` makes the empty area click-through so it doesn't block the apps behind it.

> [!TIP] Live zoom
> `win.zoomFor(di)` reads `hoverArea.pos`, so the binding re-evaluates on every mouse move. That's cheap here: one `mapToItem` per icon.

<div class="preview"><svg width="660" height="180" viewBox="0 0 660 180"><g font-size="10"><g transform="translate(5 5)"><rect width="210" height="150" rx="8" fill="#26233a"/><rect x="45" y="116" width="120" height="26" rx="12" fill="#1e1e2e"/><g fill="#89b4fa"><rect x="53" y="121" width="16" height="16" rx="4"/><rect x="73" y="114" width="22" height="22" rx="5" fill="#a6e3a1"/><rect x="99" y="121" width="16" height="16" rx="4" fill="#fab387"/><rect x="119" y="121" width="16" height="16" rx="4" fill="#f5c2e7"/><rect x="139" y="121" width="16" height="16" rx="4" fill="#94e2d5"/></g><text x="105" y="170" fill="#a6adc8" text-anchor="middle">floating pill + zoom</text></g><g transform="translate(225 5)"><rect width="210" height="150" rx="8" fill="#26233a"/><rect x="0" y="124" width="210" height="26" fill="#1e1e2e"/><g><rect x="62" y="129" width="16" height="16" rx="4" fill="#89b4fa"/><rect x="82" y="129" width="16" height="16" rx="4" fill="#a6e3a1"/><rect x="102" y="129" width="16" height="16" rx="4" fill="#fab387"/><rect x="122" y="129" width="16" height="16" rx="4" fill="#f5c2e7"/></g><text x="105" y="170" fill="#a6adc8" text-anchor="middle">full-width shelf</text></g><g transform="translate(445 5)"><rect width="210" height="150" rx="8" fill="#26233a"/><rect x="6" y="30" width="26" height="92" rx="12" fill="#1e1e2e"/><g><rect x="11" y="38" width="16" height="16" rx="4" fill="#89b4fa"/><rect x="11" y="58" width="16" height="16" rx="4" fill="#a6e3a1"/><rect x="11" y="78" width="16" height="16" rx="4" fill="#fab387"/><rect x="11" y="98" width="16" height="16" rx="4" fill="#f5c2e7"/></g><text x="105" y="170" fill="#a6adc8" text-anchor="middle">side dock</text></g></g></svg></div>

Add `property bool dockPinnedOpen: false` to `GlobalStates` and toggle it from an IPC call or keybind to keep the dock visible.

<!-- ex:## Assembly -->
::: exercise challenge | Smaller zoom on small screens
Use a smaller `maxZoom` (1.3) and `baseSize` (36) on screens narrower than 1600 logical pixels.
--- solution
```qml
maxZoom: modelData.width < 1600 ? 1.3 : 1.6
```
:::


## Polish checklist

- [ ] Magnification is smooth (a cosine wave over neighbors, not a single icon jumping).
- [ ] Icons grow away from the edge; tooltips never get clipped.
- [ ] Indicators: dots for windows, a pill for the focused app.
- [ ] Click focuses or cycles; middle-click opens a new instance; launching bounces.
- [ ] Auto-hide reveals on edge touch and on an empty desktop; the hidden dock doesn't block clicks.
- [ ] The separator only appears when there are running unpinned apps.
- [ ] Unknown apps fall back to a generic icon.

<!-- ex:## Polish checklist -->
## Practice

::: exercise project | Dock folder
Add a "folder" item that opens a popup grid of extra apps (a `PopupWindow` anchored to the item).
:::

