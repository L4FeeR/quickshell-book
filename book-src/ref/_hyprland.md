=== Hyprland
@@@ intro
Everything about **Hyprland**: monitors, workspaces, windows, the focused ones, raw events, and running dispatchers. Data updates live from Hyprland's event socket.

@@@ example Example: every property, function and signal
```qml
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

FloatingWindow {
    implicitWidth: 600; implicitHeight: 500
    color: "#1e1e2e"
    ColumnLayout {
        anchors { fill: parent; margins: 14 }
        Text { color: "white"; text: "Lua config: " + Hyprland.usingLua }
        Text { color: "white"; text: "sockets: " + Hyprland.requestSocketPath + " | " + Hyprland.eventSocketPath }
        Text { color: "white"; text: "focused monitor: " + (Hyprland.focusedMonitor?.name ?? "-") }
        Text { color: "white"; text: "focused workspace: " + (Hyprland.focusedWorkspace?.name ?? "-") }
        Text { color: "white"; text: "active window: " + (Hyprland.activeToplevel?.title ?? "-") }
        Text { color: "white"; text: "monitors: " + Hyprland.monitors.values.map(m => m.name).join(", ") }
        Text { color: "white"; text: "workspaces: " + Hyprland.workspaces.values.map(w => w.id).join(", ") }
        Text { color: "white"; text: "windows: " + Hyprland.toplevels.values.length }
        Text { color: "white"; text: "this screen's monitor: " + (Hyprland.monitorFor(Quickshell.screens[0])?.description ?? "") }
        Text { color: "#89b4fa"; text: "[go to workspace 2]"; TapHandler { onTapped: Hyprland.dispatch("workspace 2") } }
        Text { color: "#89b4fa"; text: "[refresh all]"
               TapHandler { onTapped: { Hyprland.refreshMonitors(); Hyprland.refreshWorkspaces(); Hyprland.refreshToplevels() } } }
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) { console.log(event.name, "→", event.data) }
    }
}
```

@@@ member dispatch
Runs any dispatcher, same syntax as `hyprctl dispatch` (e.g. `"exec kitty"`, `"movetoworkspace 3"`). In Lua mode (`usingLua`) the syntax differs (e.g. `hl.dsp.focus({ workspace = "3" })`); prefer helper methods like [[HyprlandWorkspace.activate()]] which handle both.

@@@ member workspaces
Sorted by id. Named and special workspaces have negative ids and come first; filter with `w.id > 0`. Only existing workspaces are listed.

@@@ member refreshToplevels
Updates every window's `lastIpcObject` (position, size, class, floating…). Call it when you need fresh geometry, e.g. when opening an overview.

@@@ see
[[ch:40-compositors]] · [[HyprlandWorkspace]] · [[HyprlandMonitor]] · [[HyprlandToplevel]]

=== HyprlandMonitor
@@@ intro
A Hyprland monitor. Get it from [[Hyprland.monitors]], [[Hyprland.focusedMonitor]] or [[Hyprland.monitorFor()]] (for the screen your bar is on).

@@@ example Example: every property
```qml
Text {
    readonly property HyprlandMonitor m: Hyprland.monitorFor(screen)
    text: `#${m?.id} ${m?.name} "${m?.description}" ${m?.width}x${m?.height}@(${m?.x},${m?.y}) scale ${m?.scale}`
        + ` · focused ${m?.focused} · active ws ${m?.activeWorkspace?.id}`
        + ` · refresh ${m?.lastIpcObject?.refreshRate ?? "?"}Hz`
}
```

@@@ member lastIpcObject
The raw `hyprctl monitors -j` object (refresh rate, special workspace, transform…). Not updated on every change: call [[Hyprland.refreshMonitors()]].

=== HyprlandWorkspace
@@@ intro
A Hyprland workspace, from [[Hyprland.workspaces]], [[Hyprland.focusedWorkspace]] or [[HyprlandMonitor.activeWorkspace]].

@@@ example Example: every property and function
```qml
Repeater {
    model: Hyprland.workspaces
    Text {
        required property HyprlandWorkspace modelData
        text: `${modelData.id} "${modelData.name}" @${modelData.address}`
            + (modelData.active ? " active" : "") + (modelData.focused ? " FOCUSED" : "")
            + (modelData.urgent ? " urgent" : "") + (modelData.hasFullscreen ? " fullscreen" : "")
            + ` · ${modelData.toplevels.values.length} windows on ${modelData.monitor?.name}`
            + ` · ${modelData.lastIpcObject?.windows ?? "?"} (ipc)`
        TapHandler { onTapped: modelData.activate() }
    }
}
```

@@@ member active
Shown on its monitor (each monitor has one active workspace).

@@@ member focused
Active **and** on the focused monitor: there's only one focused workspace.

=== HyprlandToplevel
@@@ intro
A window as Hyprland sees it. From [[Hyprland.toplevels]], [[HyprlandWorkspace.toplevels]] or [[Hyprland.activeToplevel]]. Its `wayland` property gives the generic [[Toplevel]] (for previews and activation).

@@@ example Example: every property
```qml
Repeater {
    model: Hyprland.toplevels
    Text {
        required property HyprlandToplevel modelData
        readonly property var ipc: modelData.lastIpcObject
        text: `0x${modelData.address} "${modelData.title}" class=${ipc?.class}`
            + ` ws=${modelData.workspace?.id} mon=${modelData.monitor?.name}`
            + (modelData.activated ? " ACTIVE" : "") + (modelData.urgent ? " urgent" : "")
            + ` at ${ipc?.at} size ${ipc?.size} floating ${ipc?.floating}`
        TapHandler { onTapped: Hyprland.dispatch("focuswindow address:0x" + modelData.address) }
    }
}
Component.onCompleted: Hyprland.refreshToplevels()     // fill lastIpcObject
```

@@@ member address
Hex string **without** `0x`. Dispatchers need `address:0x…`.

=== HyprlandEvent
@@@ intro
One event from Hyprland's event socket, delivered by [[Hyprland]]'s `rawEvent` signal. `name` is the event type, `data` the raw text after `>>`.

@@@ example Example
```qml
Connections {
    target: Hyprland
    function onRawEvent(event) {
        if (event.name === "activelayout") {
            const [keyboard, layout] = event.parse(2)      // split into exactly 2 fields
            console.log(keyboard, "uses", layout)
        } else if (event.name === "urgent") {
            console.log("urgent window", event.data)
        }
    }
}
```

@@@ member parse
Some events contain commas inside their last field (window titles), so you pass the expected field count and the rest stays together.

=== HyprlandFocusGrab
@@@ intro
Detects when the user clicks or focuses **outside** a set of your windows: the standard "click outside to close" for panels on Hyprland.

@@@ example Example: every property and signal
```qml
import Quickshell
import Quickshell.Hyprland
import QtQuick

PanelWindow {
    id: panel
    implicitWidth: 300; implicitHeight: 200
    visible: open
    property bool open: true
    HyprlandFocusGrab {
        windows: [panel]                   // clicks inside these are allowed (add your bar too)
        active: panel.open                 // grab only while open
        onCleared: panel.open = false      // user clicked elsewhere
    }
}
```

=== GlobalShortcut
@@@ intro
Registers a **Hyprland global shortcut**. You bind keys to it in Hyprland's config; pressing them notifies your shell instantly, with both press and release events.

@@@ example Example: every property and signal
```qml
import Quickshell.Hyprland
import QtQuick

Scope {
    GlobalShortcut {
        id: sc
        appid: "myshell"                     // default "quickshell"
        name: "cheatsheet"                   // bind = SUPER, slash, global, myshell:cheatsheet
        description: "Show the cheatsheet while held"   // visible in `hyprctl globalshortcuts`
        triggerDescription: ""               // rarely used
        onPressed: console.log("down")
        onReleased: console.log("up")
    }
    Text { text: sc.pressed ? "held" : "not held" }
}
```

@@@ notes
`appid` and `name` can't change at runtime, and the pair must be unique across all running clients.

@@@ see
[[ch:39-ipc-keybinds]]

=== HyprlandWindow
@@@ intro
Hyprland-specific settings for **your own** windows, used as attached properties on a Quickshell window: overall opacity and a visible-region hint.

@@@ example Example
```qml
import Quickshell
import Quickshell.Hyprland
import QtQuick

PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    HyprlandWindow.opacity: 0.95                          // multiplies the whole window
    HyprlandWindow.visibleMask: Region { item: panel }    // compositor may skip the rest
    mask: Region { item: panel }
    Rectangle { id: panel; width: 400; height: 300; anchors.centerIn: parent; color: "#1e1e2e" }
}
```
