# Windows: PanelWindow, Layers and Exclusive Zones

Everything Quickshell shows lives in a **window**. There are three kinds:

| Type | What it is | Use for |
|---|---|---|
| [[PanelWindow]] | A layer-shell surface glued to screen edges | bars, docks, OSDs, launchers, notifications, overlays, desktop widgets, wallpapers |
| [[FloatingWindow]] | A normal app window the compositor manages | settings apps, debug panels |
| [[PopupWindow]] | A popup positioned relative to another window | dropdown menus, calendars, tooltips |

All three share the base type [[QsWindow]]: `visible`, `implicitWidth`/`implicitHeight`, `color`, `screen`, `mask`, `devicePixelRatio`, and helpers like `itemRect()`.

## PanelWindow in depth

```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: bar

    // ---- which screen ----
    screen: Quickshell.screens[0]

    // ---- placement ----
    anchors { top: true; left: true; right: true }   // edges to attach to
    margins { top: 6; left: 8; right: 8 }            // distance from those edges
    implicitHeight: 36

    // ---- space reservation ----
    exclusiveZone: 36 + 6          // pixels reserved; tiled windows won't overlap
    // exclusionMode: ExclusionMode.Auto   (default) reserve the window's size
    // exclusionMode: ExclusionMode.Ignore don't reserve, and ignore other panels' zones
    // exclusionMode: ExclusionMode.Normal reserve nothing, but respect others

    // ---- stacking & input ----
    aboveWindows: true             // Top layer (false = Bottom layer)
    focusable: false               // take keyboard focus?

    // ---- look ----
    color: "transparent"           // window background (default WHITE!)
    visible: true

    // ---- layer-shell specifics ----
    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
}
```

### anchors: attaching to screen edges

`anchors` has four booleans. The combination decides the shape:

| Anchors set | Result | You must set |
|---|---|---|
| none | centered on screen | `implicitWidth` and `implicitHeight` |
| `top` | centered along the top edge | both |
| `top`, `left`, `right` | full-width top bar | `implicitHeight` |
| `bottom`, `left`, `right` | full-width bottom bar | `implicitHeight` |
| `left`, `top`, `bottom` | full-height left bar | `implicitWidth` |
| `top`, `right` | top-right corner (notifications) | both |
| all four | covers the whole screen | nothing |

### margins
Distance from each **anchored** edge. Margins on un-anchored edges do nothing. Use them for floating "island" bars and for placing popups below the bar.

### exclusiveZone and exclusionMode

<div class="diagram"><svg viewBox="0 0 760 210" role="img" aria-label="exclusive zones">
<rect class="n" x="20" y="20" width="340" height="170" rx="8"/><rect class="a" x="20" y="20" width="340" height="30" rx="8"/><text x="30" y="40">bar: exclusiveZone 30</text>
<rect class="g" x="30" y="60" width="320" height="120" rx="6"/><text x="40" y="125">tiled windows start below the bar</text>
<rect class="n" x="400" y="20" width="340" height="170" rx="8"/><rect class="g" x="410" y="30" width="320" height="150" rx="6"/><text x="420" y="110">windows fill the screen…</text>
<rect class="a" x="400" y="20" width="340" height="30" rx="8" opacity="0.9"/><text x="410" y="40">…bar with ExclusionMode.Ignore overlaps</text>
</svg></div>

- `exclusionMode: ExclusionMode.Auto` (default): reserve exactly the window's height or width plus margin.
- Setting `exclusiveZone: N` switches to manual mode and reserves N pixels.
- `ExclusionMode.Ignore`: reserve nothing **and** ignore other panels' reservations. Use it for overlays, fullscreen click-through windows, OSDs and launchers.
- `ExclusionMode.Normal`: reserve nothing but stay out of other panels' zones.

> [!TIP] Autohide bars
> To hide a bar without windows jumping around, switch `exclusiveZone` between the bar height and `0` at the same time as animating the bar's content.

### Layers

[[WlrLayershell.layer]] picks one of four layers, via [[WlrLayer]]:

| Layer | Above | Use |
|---|---|---|
| `WlrLayer.Background` | nothing | wallpaper |
| `WlrLayer.Bottom` | wallpaper | desktop widgets, desktop clock |
| `WlrLayer.Top` | normal windows | bars, docks (hidden by fullscreen windows) |
| `WlrLayer.Overlay` | everything, including fullscreen | launchers, OSDs, notifications, power menu |

`aboveWindows: true/false` is a shortcut for Top/Bottom.

### Namespace

[[WlrLayershell.namespace]] names the surface for compositor rules. Pick a scheme like `quickshell:<component>`:

```ini file="hyprland.conf"
layerrule = blur, quickshell:bar
layerrule = ignorealpha 0.3, quickshell:.*
layerrule = animation slide top, quickshell:notifications
layerrule = noanim, quickshell:osd
```

The namespace can't change after the window is created.

### Keyboard focus

[[WlrLayershell.keyboardFocus]] uses [[WlrKeyboardFocus]]:

| Mode | Behavior | Use |
|---|---|---|
| `None` (default) | never receives keys | bars, widgets |
| `OnDemand` | receives keys when clicked or focused normally | sidebars with search boxes |
| `Exclusive` | grabs all keyboard input while mapped | launchers, power menus, lock-like UIs |

`focusable: true` on PanelWindow is a portable shortcut (roughly `OnDemand`).

### color, transparency and surface format

The window's `color` defaults to **white**. For rounded, floating or translucent designs, set `color: "transparent"` and draw your own background inside. Translucency requires an alpha surface, which Quickshell picks automatically when the color isn't opaque at creation. [[QsWindow.surfaceFormat]] lets you force `opaque` for performance on opaque windows.

## FloatingWindow

```qml
FloatingWindow {
    title: "My Shell Settings"
    implicitWidth: 700; implicitHeight: 500
    minimumSize: Qt.size(400, 300)
    visible: GlobalStates.settingsOpen
    color: "#1e1e2e"
    onClosed: GlobalStates.settingsOpen = false     // user closed it via the compositor
}
```

It's managed like any app window: tiled, floated or fullscreened by the compositor. Members include `title`, `minimumSize`, `maximumSize`, `minimized`, `maximized`, `fullscreen`, `parentWindow`, `startSystemMove()` and `startSystemResize(edges)`. Match it in compositor rules by title or app id.

## Which screen? `screen`

Every window has `screen` ([[ShellScreen]]). If you don't set it, the compositor picks one (usually the focused monitor). [[ch:31-multi-monitor]] shows how to make one window per screen with [[Variants]].

## Useful QsWindow members

| Member | Use |
|---|---|
| `visible` | show/hide (window is unmapped when false) |
| `backingWindowVisible` | whether it's actually mapped right now |
| `contentItem` | root Item holding your children |
| `devicePixelRatio` | the screen's scale factor |
| `mask` | click-through region ([[ch:35-masks]]) |
| `itemPosition(item)` / `itemRect(item)` | where an item is within the window (to anchor popups) |
| `mapFromItem(item, …)` | coordinate mapping |
| `updatesEnabled` | pause rendering of a hidden-but-mapped window |
| `closed()` signal | the compositor closed the window |
| `windowConnected()` signal | the window got its platform surface |

From inside any item, the attached `QsWindow.window` gives you the containing window:

```qml
Rectangle {
    // deep inside a bar component:
    TapHandler { onTapped: console.log("I'm in", QsWindow.window, "on", QsWindow.window.screen.name) }
}
```

## Common window recipes

```qml
// 1. centered launcher (no anchors), above everything, grabs keys
PanelWindow {
    implicitWidth: 600; implicitHeight: 420
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
}

// 2. click-through fullscreen overlay (decorations, screen corners)
PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}                       // empty region = no input at all
    WlrLayershell.layer: WlrLayer.Overlay
}

// 3. desktop widget on the Bottom layer
PanelWindow {
    anchors { top: true; left: true }
    margins { top: 80; left: 80 }
    implicitWidth: 400; implicitHeight: 200
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
}

// 4. OSD at bottom center
PanelWindow {
    anchors.bottom: true
    margins.bottom: 80
    implicitWidth: 300; implicitHeight: 56
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
}
```

## Practice

::: exercise warm | Left bar that reserves space
Make a 44 px left vertical bar that pushes windows aside.
--- solution
```qml
PanelWindow { anchors { left: true; top: true; bottom: true }; implicitWidth: 44; color: "#1e1e2e" }
```
The default `exclusionMode` (`Normal`) reserves its width automatically.
:::

::: exercise practice | Escapable overlay
Make a centered 500×300 overlay that closes on <kbd>Esc</kbd>.
--- solution
```qml
PanelWindow { id: ov
    implicitWidth: 500; implicitHeight: 300; color: "#1e1e2e"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: ov.visible = false } }
```
With no anchors set, a layer-shell window is centered.
:::

::: exercise practice | Under the windows
Make a desktop clock on the `Bottom` layer and confirm windows cover it.
--- solution
```qml
PanelWindow { anchors { top: true; left: true }; margins { top: 100; left: 100 }
    implicitWidth: 300; implicitHeight: 120; color: "transparent"
    exclusionMode: ExclusionMode.Ignore; WlrLayershell.layer: WlrLayer.Bottom
    Text { text: "12:00"; color: "white"; font.pixelSize: 72 } }
```
:::

::: exercise challenge | Floating bar
Turn your bar into a floating bar: 8 px from the screen edges, rounded, with a transparent window and a still-correct exclusive zone.
--- solution
```qml
PanelWindow { anchors { top: true; left: true; right: true }
    margins { top: 8; left: 8; right: 8 }
    implicitHeight: 38; color: "transparent"
    Rectangle { anchors.fill: parent; radius: 12; color: "#1e1e2e" } }
```
The exclusive zone covers the bar's height; Hyprland adds its own `gaps_out` on top, so lower those if the gap looks doubled.
:::
