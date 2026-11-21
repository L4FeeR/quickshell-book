=== I3
@@@ intro
Sway and i3 integration over their IPC socket: workspaces, monitors, focus, raw events, and running commands.

@@@ example Example: every property, function and signal
```qml
import Quickshell
import Quickshell.I3
import QtQuick

Column {
    Text { text: "socket: " + I3.socketPath }
    Text { text: "focused ws: " + (I3.focusedWorkspace?.name ?? "-") + " on " + (I3.focusedMonitor?.name ?? "-") }
    Text { text: "workspaces: " + I3.workspaces.values.map(w => w.name).join(" ") }
    Text { text: "monitors: " + I3.monitors.values.map(m => m.name).join(" ") }
    Text { text: "ws '1' exists: " + (I3.findWorkspaceByName("1") !== null) }
    Text { text: "monitor for screen 0: " + (I3.monitorFor(Quickshell.screens[0])?.name ?? "") }
    Text { text: "[ws 3]"; TapHandler { onTapped: I3.dispatch("workspace number 3") } }
    Text { text: "[refresh]"; TapHandler { onTapped: { I3.refreshWorkspaces(); I3.refreshMonitors() } } }
    Connections {
        target: I3
        function onConnected() { console.log("connected to sway/i3") }
        function onRawEvent(e) { console.log(e.type, e.data) }
    }
}
```

@@@ see
[[ch:40-compositors]] · [[I3Workspace]] · [[I3IpcListener]]

=== I3Workspace
@@@ intro
A Sway/i3 workspace from [[I3.workspaces]].

@@@ example Example
```qml
Repeater {
    model: I3.workspaces
    Text {
        required property I3Workspace modelData
        text: `${modelData.number}:${modelData.name} (id ${modelData.id}) on ${modelData.monitor?.name}`
            + (modelData.focused ? " focused" : modelData.active ? " active" : "")
            + (modelData.urgent ? " urgent" : "")
        TapHandler { onTapped: modelData.activate() }
    }
}
```

@@@ notes
Sway only lists workspaces that exist (have windows or are visible). `num` is the deprecated name of `number`.

=== I3Monitor
@@@ intro
A Sway/i3 output from [[I3.monitors]] or [[I3.monitorFor()]].

@@@ example Example
```qml
Text {
    readonly property I3Monitor m: I3.monitorFor(screen)
    text: `${m?.name} #${m?.id} ${m?.width}x${m?.height}@(${m?.x},${m?.y}) scale ${m?.scale}`
        + ` power ${m?.power} focused ${m?.focused} ws ${m?.activeWorkspace?.name}`
}
```

=== I3Event
@@@ intro
A raw Sway/i3 IPC event: `type` (e.g. `workspace`, `window`, `mode`) and `data` (JSON text). From [[I3]]'s `rawEvent` or [[I3IpcListener]]'s `ipcEvent`.

@@@ example Example
```qml
Connections {
    target: I3
    function onRawEvent(e) {
        if (e.type === "mode") modeText.text = JSON.parse(e.data).change   // binding mode indicator
    }
}
```

=== I3IpcListener
@@@ intro
Subscribes to specific Sway/i3 event types and emits them.

@@@ example Example
```qml
I3IpcListener {
    subscriptions: ["window", "mode", "binding"]
    onIpcEvent: e => {
        const d = JSON.parse(e.data)
        if (e.type === "window" && d.change === "focus") console.log("focus →", d.container.name)
    }
}
```

=== Niri
@@@ intro
niri integration (**noctalia-qs fork only**): outputs, workspaces, windows, keyboard layouts, the overview state, raw events and actions.

@@@ example Example: every property, function and signal
```qml
import Quickshell.Niri
import QtQuick

Column {
    Text { text: "socket: " + Niri.socketPath }
    Text { text: "focused: " + (Niri.focusedWindow?.title ?? "-") }
    Text { text: "overview open: " + Niri.overviewActive }
    Text { text: "layout: " + Niri.currentKeyboardLayoutName + " (" + Niri.currentKeyboardLayoutIndex + " of " + Niri.keyboardLayoutNames.length + ")" }
    Text { text: "outputs: " + Niri.outputs.values.map(o => o.name).join(", ") }
    Text { text: "workspaces: " + Niri.workspaces.values.map(w => w.idx).join(" ") }
    Text { text: "windows: " + Niri.windows.values.length }
    Text { text: "[ws 2]"; TapHandler { onTapped: Niri.dispatch(["focus-workspace", "2"]) } }
    Text { text: "[overview]"; TapHandler { onTapped: Niri.dispatch(["toggle-overview"]) } }
    Text { text: "[refresh]"; TapHandler { onTapped: { Niri.refreshOutputs(); Niri.refreshWorkspaces(); Niri.refreshWindows() } } }
    Connections {
        target: Niri
        function onRawEvent(e) { console.log(e.type) }
        function onWorkspacesUpdated() { console.log("workspaces changed") }
        function onWindowsUpdated() {}
        function onOutputsUpdated() {}
        function onKeyboardLayoutSwitched() { console.log("layout →", Niri.currentKeyboardLayoutName) }
    }
}
```

@@@ member dispatch
Takes a list of arguments for `niri msg action`, e.g. `["focus-workspace", "3"]`, `["spawn", "--", "kitty"]`.

=== NiriWorkspace
@@@ intro
A niri workspace (**noctalia-qs fork only**), from [[Niri.workspaces]].

@@@ example Example
```qml
Repeater {
    model: Niri.workspaces
    Text {
        required property NiriWorkspace modelData
        text: `${modelData.idx}${modelData.name ? ":" + modelData.name : ""} on ${modelData.output} (id ${modelData.id})`
            + (modelData.focused ? " focused" : modelData.active ? " active" : "")
            + (modelData.occupied ? " ●" : " ○") + (modelData.urgent ? " !" : "")
            + " activeWindow=" + modelData.activeWindowId
        TapHandler { onTapped: Niri.dispatch(["focus-workspace", String(modelData.idx)]) }
    }
}
```

@@@ member idx
The workspace's position on its output (1-based), what you pass to `focus-workspace`. `id` is a global unique id.

=== NiriWindow
@@@ intro
A niri window (**noctalia-qs fork only**), from [[Niri.windows]] or [[Niri.focusedWindow]].

@@@ example Example
```qml
Repeater {
    model: Niri.windows
    Text {
        required property NiriWindow modelData
        text: `${modelData.appId}: ${modelData.title} ws=${modelData.workspaceId} out=${modelData.output}`
            + (modelData.focused ? " ★" : "") + (modelData.isFloating ? " floating" : ` col ${modelData.positionX}`)
        TapHandler { onTapped: Niri.dispatch(["focus-window", "--id", String(modelData.id)]) }
    }
}
```

=== NiriOutput
@@@ intro
A niri output/monitor (**noctalia-qs fork only**), from [[Niri.outputs]].

@@@ example Example
```qml
Repeater {
    model: Niri.outputs
    Text {
        required property NiriOutput modelData
        text: `${modelData.name} ${modelData.width}x${modelData.height}@${modelData.refreshRate}Hz scale ${modelData.scale}`
            + ` at (${modelData.x},${modelData.y}) ${modelData.physicalWidth}x${modelData.physicalHeight}mm`
            + ` connected=${modelData.connected} vrr ${modelData.vrrSupported}/${modelData.vrrEnabled} ${modelData.transform}`
    }
}
```

=== NiriEvent
@@@ intro
A raw niri event (**noctalia-qs fork only**): `type` like `"WorkspacesChanged"` and `data` as a JSON object. From [[Niri]]'s `rawEvent`.

=== DwlIpc
@@@ intro
dwl integration (**noctalia-qs fork only**) via the dwl IPC protocol: tag count, layouts and per-output state.

@@@ example Example
```qml
import Quickshell.DWL
import QtQuick

Column {
    visible: DwlIpc.available
    Text { text: DwlIpc.tagCount + " tags, layouts: " + DwlIpc.layouts.join(" ") }
    Repeater {
        model: DwlIpc.outputs
        Row {
            required property DwlIpcOutput modelData
            spacing: 4
            Text { text: modelData.layoutSymbol + " " + modelData.title + (modelData.active ? " *" : "") }
            Repeater {
                model: modelData.tags
                Text {
                    required property DwlTag modelData
                    text: (modelData.index + 1) + (modelData.clientCount ? "•" : "")
                    color: modelData.active ? "#cba6f7" : modelData.urgent ? "#f38ba8" : "grey"
                }
            }
        }
    }
}
```

=== DwlIpcOutput
@@@ intro
One dwl monitor (**noctalia-qs fork only**) from [[DwlIpc.outputs]]: focused window `title`/`appId`, `layoutSymbol`, `tags`, `fullscreen`, `floating`, `kbLayout`, and functions to change tags and layout.

@@@ example Example
```qml
// view tag 3 only (bitmask 1 << 2)
output.setTags(1 << 2, 0)
// move the focused client to tag 2
output.setClientTags(0, 1 << 1)
// switch to the second layout
output.setLayout(1)
```

=== DwlTag
@@@ intro
State of one dwl tag (**noctalia-qs fork only**): `index`, `active`, `urgent`, `clientCount`, `focusedClient`. Found in [[DwlIpcOutput.tags]].

=== WindowManager
@@@ intro
A compositor-independent **workspace API** using the `ext-workspace-v1` Wayland protocol. Workspaces (or tags) are [[Windowset]]s, grouped by the screens they cover ([[WindowsetProjection]]). Support depends on your compositor.

@@@ example Example
```qml
import Quickshell
import Quickshell.WindowManager
import QtQuick

Row {
    spacing: 6
    Repeater {
        model: WindowManager.screenProjection(Quickshell.screens[0])?.windowsets ?? []
        Text {
            required property Windowset modelData
            visible: modelData.shouldDisplay
            text: modelData.name
            color: modelData.active ? "#cba6f7" : modelData.urgent ? "#f38ba8" : "white"
            TapHandler { enabled: modelData.canActivate; onTapped: modelData.activate() }
        }
    }
    Component.onCompleted: console.log("all windowsets:", WindowManager.windowsets.length,
                                       "projections:", WindowManager.windowsetProjections.length)
}
```

=== Windowset
@@@ intro
A workspace or tag from [[WindowManager]].

@@@ example Example: every member
```qml
Text {
    required property Windowset ws
    text: `${ws.name} [${ws.coordinates}] id=${ws.id} active=${ws.active} urgent=${ws.urgent}`
        + ` display=${ws.shouldDisplay} canActivate=${ws.canActivate} canDeactivate=${ws.canDeactivate}`
        + ` canRemove=${ws.canRemove} canSetProjection=${ws.canSetProjection}`
    TapHandler { onTapped: ws.activate() }                     // also: deactivate(), remove(), setProjection(p)
}
```

=== WindowsetProjection
@@@ intro
The set of screens a group of windowsets covers (usually one screen). Has `screens` and `windowsets`.

=== ScreenProjection
@@@ intro
A [[WindowsetProjection]] covering exactly one screen, returned by [[WindowManager.screenProjection()]], the easiest way to get "workspaces on this monitor".
