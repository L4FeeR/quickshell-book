# Talking to Your Compositor

Workspaces, the focused window's title, window lists for docks, live previews: all of these come from the compositor. Quickshell has dedicated modules for **Hyprland** and **Sway/i3**, the noctalia-qs fork adds **niri** and **DWL**, and there are generic Wayland types that work almost everywhere.

| Compositor | Module | Singleton |
|---|---|---|
| Hyprland | `Quickshell.Hyprland` | [[Hyprland]] |
| Sway, i3 | `Quickshell.I3` | [[I3]] |
| niri | `Quickshell.Niri` *(noctalia-qs fork)* | [[Niri]] |
| dwl | `Quickshell.DWL` *(noctalia-qs fork)* | [[DwlIpc]] |
| any with ext-workspace | `Quickshell.WindowManager` | [[WindowManager]] |
| any with foreign-toplevel | `Quickshell.Wayland` | [[ToplevelManager]] |

## Hyprland

```qml
import Quickshell.Hyprland
```

### Workspaces
```qml
Row {
    spacing: 6
    Repeater {
        model: Hyprland.workspaces                    // ObjectModel<HyprlandWorkspace>, sorted by id
        Rectangle {
            required property HyprlandWorkspace modelData
            visible: modelData.id > 0                 // hide special/named workspaces (negative ids)
            width: modelData.focused ? 28 : 12; height: 12; radius: 6
            color: modelData.focused ? "#cba6f7"
                 : modelData.urgent ? "#f38ba8"
                 : modelData.toplevels.values.length ? "#6c7086" : "#313244"
            Behavior on width { NumberAnimation { duration: 200 } }
            TapHandler { onTapped: modelData.activate() }
        }
    }
}
```

[[HyprlandWorkspace]]: `id`, `name`, `active` (shown on its monitor), `focused` (active *and* its monitor is focused), `urgent`, `hasFullscreen`, `monitor`, `toplevels`, `lastIpcObject`, `activate()`.

> [!TIP] Show 1–10 even when empty
> `Hyprland.workspaces` only contains workspaces that **exist**, and Hyprland destroys empty ones. For a fixed 1–10 indicator, use `Repeater { model: 10 }` and look each id up: `Hyprland.workspaces.values.find(w => w.id === index + 1)`. [[ch:48-proj-workspaces]] does this.

### Monitors, focus, active window
```qml
Text { text: Hyprland.focusedWorkspace?.name ?? "" }
Text { text: Hyprland.activeToplevel?.title ?? "Desktop" }
// per bar: the monitor this bar is on
readonly property HyprlandMonitor mon: Hyprland.monitorFor(screen)
Text { text: "ws " + (mon?.activeWorkspace?.id ?? "?") }
```

[[Hyprland]] properties: `focusedMonitor`, `focusedWorkspace`, `activeToplevel`, `monitors`, `workspaces`, `toplevels`, `usingLua`, `requestSocketPath`, `eventSocketPath`. [[HyprlandMonitor]]: `id`, `name`, `description`, `x`, `y`, `width`, `height`, `scale`, `focused`, `activeWorkspace`, `lastIpcObject`.

### Windows (toplevels)
[[HyprlandToplevel]]: `address`, `title`, `activated`, `urgent`, `workspace`, `monitor`, `wayland` (the generic [[Toplevel]], for previews and activation), `lastIpcObject` (full `hyprctl clients -j` data: class, position, size, floating…).

### Dispatching
```qml
Hyprland.dispatch("workspace 3")
Hyprland.dispatch("movetoworkspace 5")
Hyprland.dispatch("togglefloating")
Hyprland.dispatch(`focuswindow address:0x${toplevel.address}`)
Hyprland.dispatch("exec kitty")
```

> [!WARN] Hyprland Lua configs
> Newer Hyprland versions can use a Lua config. In Lua mode the dispatcher syntax changes (for example `hl.dsp.focus({ workspace = "3" })` instead of `workspace 3`). [[Hyprland.usingLua]] tells you which mode is active. Prefer helper methods like [[HyprlandWorkspace.activate()]], which pick the right syntax for you.

### lastIpcObject and refreshing
Much data (window position and size, workspace window count) only comes from Hyprland's JSON. It's in `lastIpcObject`, but it **isn't refreshed automatically** for every change. Call `Hyprland.refreshToplevels()`, `refreshWorkspaces()` or `refreshMonitors()` when you need fresh data (e.g. when the overview opens).

### Raw events
```qml
Connections {
    target: Hyprland
    function onRawEvent(event) {            // HyprlandEvent: name, data, parse(n)
        switch (event.name) {
        case "activelayout": root.layout = event.parse(2)[1]; break      // keyboard layout name
        case "submap":       root.submap = event.data; break
        case "openwindow":
        case "closewindow":  Hyprland.refreshToplevels(); break
        }
    }
}
```

See the Hyprland wiki's IPC page for all event names.

### Other Hyprland types
- [[GlobalShortcut]]: keybinds into your shell ([[ch:39-ipc-keybinds]]).
- [[HyprlandFocusGrab]]: detect clicks outside your windows. `windows: [popup, bar]`, `active: true`, `onCleared: close()`.
- [[HyprlandWindow]] (attached): `HyprlandWindow.opacity` and `HyprlandWindow.visibleMask` on your windows.

## Sway and i3

```qml
import Quickshell.I3

Row {
    Repeater {
        model: I3.workspaces
        Text {
            required property I3Workspace modelData
            text: modelData.name
            color: modelData.focused ? "#cba6f7" : modelData.urgent ? "#f38ba8" : "#6c7086"
            TapHandler { onTapped: modelData.activate() }
        }
    }
}
Text { text: I3.focusedWorkspace?.name ?? "" }
```

[[I3]]: `workspaces`, `monitors`, `focusedWorkspace`, `focusedMonitor`, `socketPath`, `dispatch(cmd)`, `monitorFor(screen)`, `findWorkspaceByName()`, `findMonitorByName()`, `refreshWorkspaces()`, `refreshMonitors()`, signals `rawEvent(event)` and `connected()`. [[I3Workspace]]: `id`, `name`, `number`, `focused`, `active`, `urgent`, `monitor`, `lastIpcObject`, `activate()`. [[I3IpcListener]] subscribes to arbitrary i3/Sway events (e.g. `["window", "mode"]`).

## niri (noctalia-qs fork)

```qml
import Quickshell.Niri

Row {
    Repeater {
        model: Niri.workspaces                 // sorted by output, then index
        Rectangle {
            required property NiriWorkspace modelData
            width: modelData.focused ? 24 : 10; height: 10; radius: 5
            color: modelData.focused ? "#cba6f7" : modelData.occupied ? "#6c7086" : "#313244"
            TapHandler { onTapped: Niri.dispatch(["focus-workspace", String(modelData.idx)]) }
        }
    }
}
Text { text: Niri.focusedWindow?.title ?? "" }
Text { text: Niri.currentKeyboardLayoutName }
```

[[Niri]] also exposes `windows`, `outputs`, `overviewActive`, keyboard layouts, refresh functions and signals (`rawEvent`, `workspacesUpdated`, `windowsUpdated`…).

### niri on upstream Quickshell
Without the fork, read niri's event stream yourself:

```qml
Process {
    command: ["niri", "msg", "--json", "event-stream"]
    running: true
    stdout: SplitParser {
        onRead: line => {
            const ev = JSON.parse(line)
            if (ev.WorkspacesChanged) root.workspaces = ev.WorkspacesChanged.workspaces
            else if (ev.WorkspaceActivated) root.focusedId = ev.WorkspaceActivated.id
            else if (ev.WindowFocusChanged) root.focusedWindowId = ev.WindowFocusChanged.id
        }
    }
}
```

## dwl (noctalia-qs fork)

[[DwlIpc]] exposes `tagCount`, `layouts` and `outputs` ([[DwlIpcOutput]] with `tags`, `title`, `appId`, `layoutSymbol`, `setTags()`, `setLayout()`…). Each [[DwlTag]] has `active`, `urgent`, `clientCount`.

## Compositor-independent: ToplevelManager

The foreign-toplevel protocol is supported by Hyprland, Sway, niri, river, labwc, Wayfire and others. [[ToplevelManager]] lists every window:

```qml
import Quickshell.Wayland

Repeater {
    model: ToplevelManager.toplevels
    Text {
        required property Toplevel modelData
        text: (modelData.activated ? "▶ " : "  ") + modelData.appId + " — " + modelData.title
        TapHandler { onTapped: modelData.activate() }
        TapHandler { acceptedButtons: Qt.MiddleButton; onTapped: modelData.close() }
    }
}
```

[[Toplevel]]: `appId`, `title`, `activated`, `maximized`, `minimized`, `fullscreen` (settable as requests), `parent`, `screens`, `activate()`, `close()`, `fullscreenOn(screen)`, `setRectangle(window, rect)` (tells the compositor where the dock icon is, for minimize animations). `ToplevelManager.activeToplevel` is the focused window. This is enough for taskbars and docks on any compositor.

## Compositor-independent workspaces: WindowManager

[[WindowManager]] (module `Quickshell.WindowManager`) implements the `ext-workspace-v1` protocol, a standard workspace API that compositors are adopting. It exposes [[Windowset]]s (workspaces or tags) with `name`, `active`, `urgent`, `activate()`, grouped into projections (screens). It's newer and depends on compositor support; check yours.

## Live previews: ScreencopyView

[[ScreencopyView]] shows a live (or still) image of a window or screen:

```qml
ScreencopyView {
    captureSource: hyprToplevel.wayland      // a Toplevel, or a ShellScreen for a whole monitor
    live: true                               // continuous video; false = one frame (captureFrame())
    constraintSize: Qt.size(320, 200)        // fit inside this size, keeping aspect ratio
    paintCursor: false
}
```

Members: `captureSource`, `live`, `paintCursor`, `constraintSize`, `hasContent`, `sourceSize`, `captureFrame()`, `stopped()`. Used for overviews and alt-tab switchers. Keep `live` on only while visible.

## Writing compositor-portable code

Wrap compositor differences in **one service** so the UI doesn't care:

```qml file="services/Workspaces.qml"
pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    readonly property bool isHyprland: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== null
    readonly property int focusedId: isHyprland ? (Hyprland.focusedWorkspace?.id ?? 1) : 1
    function focus(id: int): void { if (isHyprland) Hyprland.dispatch("workspace " + id) }
}
```

> [!WARN] Importing compositor modules elsewhere
> Importing `Quickshell.Hyprland` on Sway is harmless (the singleton just isn't connected), but referencing data from a compositor that isn't running gives null values. Guard with `?.` and environment checks.

## Practice

::: exercise warm | Window title
Show the focused window's title, elided to 300 px.
--- solution
```qml
Text { width: 300; elide: Text.ElideRight; color: "white"
       text: ToplevelManager.activeToplevel?.title ?? "" }
```
:::

::: exercise practice | Keyboard layout
Show the keyboard layout from Hyprland's `activelayout` event.
--- solution
```qml
Connections { target: Hyprland
    function onRawEvent(event) {
        if (event.name === "activelayout") layout.text = event.data.split(",").pop().slice(0, 2).toUpperCase() } }
Text { id: layout; color: "white" }
```
:::

::: exercise challenge | Taskbar
Build a taskbar with `ToplevelManager` that shows app icons and activates windows on click.
--- solution
```qml
Row { spacing: 4
    Repeater { model: ToplevelManager.toplevels
        IconImage { required property Toplevel modelData; implicitSize: 24
            source: Quickshell.iconPath(DesktopEntries.heuristicLookup(modelData.appId)?.icon ?? "", "application-x-executable")
            opacity: modelData.activated ? 1 : 0.6
            TapHandler { onTapped: modelData.activate() } } } }
```
:::
