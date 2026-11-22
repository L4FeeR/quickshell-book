# ObjectModel and ScriptModel

Quickshell gives you live lists: workspaces, windows, tray icons, media players, notifications, audio nodes, Bluetooth devices, apps. They come as [[ObjectModel]]s. When you need to filter or sort them, [[ScriptModel]] keeps views fast and animated.

## ObjectModel: live lists from services

Many properties in the API reference have the type `ObjectModel<…>`:

| Property | Elements |
|---|---|
| [[Hyprland.workspaces]] | [[HyprlandWorkspace]] |
| [[Hyprland.toplevels]] | [[HyprlandToplevel]] |
| [[ToplevelManager.toplevels]] | [[Toplevel]] |
| [[SystemTray.items]] | [[SystemTrayItem]] |
| [[Mpris.players]] | [[MprisPlayer]] |
| [[UPower.devices]] | [[UPowerDevice]] |
| [[DesktopEntries.applications]] | [[DesktopEntry]] |
| [[NotificationServer.trackedNotifications]] | [[Notification]] |
| [[Pipewire.nodes]] | [[PwNode]] |
| [[Bluetooth.devices]] | [[BluetoothDevice]] |

### Use one directly as a model
```qml
Repeater {
    model: Mpris.players
    Text { required property MprisPlayer modelData; text: modelData.identity }
}
```

When a player appears or disappears, the Repeater adds or removes exactly that delegate.

### .values: as a JavaScript array
`objectModel.values` is a normal list you can `filter`, `find`, `map` or `sort`, and bindings that use it update when the list changes:

```qml
readonly property MprisPlayer active: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
readonly property int windowCount: Hyprland.toplevels.values.length
readonly property list<HyprlandWorkspace> occupied: Hyprland.workspaces.values.filter(w => w.toplevels.values.length > 0)
```

### ObjectModel signals and methods
`indexOf(object)`, and signals `objectInsertedPre/Post(object, index)` and `objectRemovedPre/Post(object, index)` if you need to react to individual changes:

```qml
Connections {
    target: Mpris.players
    function onObjectInsertedPost(player, index) { console.log("new player:", player.identity) }
}
```

## The problem with filtered arrays

```qml
Repeater {
    model: DesktopEntries.applications.values.filter(a => a.name.toLowerCase().includes(query))
    delegate: AppItem {}
}
```

This works, but every time `query` changes, the binding produces a **brand-new array**. The Repeater can't tell which items stayed the same, so it destroys **all** delegates and creates new ones. That means no add/remove animations, scroll and hover state lost, and more CPU.

## ScriptModel: a diffing model

[[ScriptModel]] takes a JS array in `values`, compares it with the previous one, and reports only the actual insertions and removals:

```qml
ListView {
    model: ScriptModel {
        values: DesktopEntries.applications.values
            .filter(a => a.name.toLowerCase().includes(search.text.toLowerCase()))
            .sort((a, b) => a.name.localeCompare(b.name))
    }
    delegate: AppItem { required property DesktopEntry modelData }
    add:    Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 } }
    remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 150 } }
    displaced: Transition { NumberAnimation { property: "y"; duration: 150 } }
}
```

Now typing in the search box smoothly removes non-matching apps and keeps matching delegates alive.

### ScriptModel members

| Member | Meaning |
|---|---|
| `values` | The array to reflect (usually a binding) |
| `objectProp` | For plain JS objects: which key identifies "the same" item (e.g. `"id"`) |
| `comparisonMode` | [[ObjectComparison]]: `Structure` (default, compares contents) or `Identity` (faster, same object reference) |

> [!WARN] Unique values
> ScriptModel expects each value in the list to be **unique**. Duplicates confuse the diff. For lists of plain objects (parsed JSON, `nmcli` results), set `objectProp` to a unique key like `"ssid"` or `"id"`.

```qml
ListView {
    model: ScriptModel {
        values: Network.networks            // [{ ssid, signal, secure }, …], rebuilt on each scan
        objectProp: "ssid"                   // same ssid = same row, so it updates in place
    }
    delegate: NetworkRow { required property var modelData }
}
```

## When to use which

| Situation | Use |
|---|---|
| Show a service list as-is | the ObjectModel directly |
| Read or compute from a list (count, find, any) | `.values` in a binding |
| Filtered or sorted list shown in a view | `ScriptModel { values: … }` |
| A list you edit by hand (todo, history) | `ListModel` |
| A static list | a JS array literal |

## Sorting workspaces and other gotchas

- [[Hyprland.workspaces]] is sorted by id. Named and special workspaces have **negative ids** and come first, so filter them out for a 1–10 indicator: `.filter(w => w.id > 0)`.
- Elements can be **destroyed** while you hold them (a player quits). Always use `?.` on references you keep.
- Don't mutate `.values` (`push`/`splice`); it's a read-only view.

## Practice

::: exercise warm | Count windows
Show the number of open windows.
--- solution
```qml
Text { text: ToplevelManager.toplevels.values.length + " windows"; color: "white" }
```
:::

::: exercise practice | Filtered app list
Build an app list filtered by a `TextField` with `ScriptModel` and add/remove transitions.
--- solution
```qml
Column {
    TextField { id: q; width: 300 }
    ListView { width: 300; height: 300; clip: true
        model: ScriptModel { values: DesktopEntries.applications.values.filter(a => a.name.toLowerCase().includes(q.text.toLowerCase())) }
        delegate: Text { required property DesktopEntry modelData; text: modelData.name; color: "white" }
        add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 } }
        remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 150 } } } }
```
:::

::: exercise challenge | Watch the tray
Log every time a tray icon appears or disappears.
--- solution
```qml
Connections { target: SystemTray.items
    function onObjectInsertedPost(obj, index) { console.log("tray +", obj.id) }
    function onObjectRemovedPre(obj, index) { console.log("tray -", obj.id) } }
```
:::
