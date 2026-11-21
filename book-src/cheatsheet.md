# Cheat Sheet

## CLI

```bash
qs -c NAME                    # run ~/.config/quickshell/NAME/shell.qml
qs -p PATH                    # run any file/folder
qs -c NAME -d                 # daemonize
qs list / qs kill -c NAME     # instances
qs log -c NAME -f             # follow logs
qs ipc show                   # list IPC targets
qs ipc call TARGET FN ARGS    # call an IPC function
qs ipc listen TARGET SIGNAL   # watch an IPC signal
qs -vv                        # debug logging
```

## Pragmas (top of shell.qml, before imports)

```qml
//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma ShellId myshell
```

## Windows

```qml
PanelWindow { anchors { top: true; left: true; right: true } implicitHeight: 36; color: "transparent" }
PanelWindow { exclusionMode: ExclusionMode.Ignore; mask: Region {} }                    // click-through overlay
PanelWindow { WlrLayershell.layer: WlrLayer.Overlay; WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive }
PanelWindow { WlrLayershell.namespace: "quickshell:bar" }                               // for layerrules
Variants { model: Quickshell.screens; PanelWindow { required property ShellScreen modelData; screen: modelData } }
PopupWindow { anchor.item: btn; anchor.edges: Edges.Bottom; anchor.gravity: Edges.Bottom; grabFocus: true }
LazyLoader { active: GlobalStates.open; PanelWindow { } }
FloatingWindow { title: "Settings"; implicitWidth: 600; implicitHeight: 400 }
```

## State

```qml
// services/X.qml
pragma Singleton
import Quickshell
Singleton { property bool open: false }
// usage: import qs.services → X.open

FileView { path: Quickshell.statePath("s.json"); onAdapterUpdated: writeAdapter(); JsonAdapter { property int n: 0 } }
PersistentProperties { reloadableId: "ui"; property bool open }
```

## Processes and IPC

```qml
Process { command: ["sh", "-c", "…"]; running: true; stdout: StdioCollector { onStreamFinished: x = text.trim() } }
Process { command: ["nmcli", "monitor"]; running: true; stdout: SplitParser { onRead: line => … } }
Quickshell.execDetached(["kitty"])
IpcHandler { target: "shell"; function toggle(name: string): void { } }
GlobalShortcut { name: "launcher"; onPressed: … }          // bind = SUPER, Space, global, quickshell:launcher
```

## Services

```qml
Pipewire.defaultAudioSink.audio.volume / .muted        + PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
Mpris.players.values[0].trackTitle / .togglePlaying()
UPower.displayDevice.percentage (0–1) / .state / .isLaptopBattery
PowerProfiles.profile = PowerProfile.Performance
SystemTray.items → SystemTrayItem.icon / .activate() / .menu
NotificationServer { onNotification: n => n.tracked = true }
Bluetooth.defaultAdapter.enabled / Bluetooth.devices
Networking.wifiEnabled / Networking.devices
Hyprland.focusedWorkspace / .workspaces / .dispatch("workspace 2") / .activeToplevel?.title
I3.workspaces / I3.dispatch("workspace number 2")
ToplevelManager.toplevels / .activeToplevel
DesktopEntries.applications / .heuristicLookup(appId)
Quickshell.iconPath(name, "fallback")
SystemClock { precision: SystemClock.Minutes } → Qt.formatDateTime(clock.date, "hh:mm")
```

## QML essentials

```qml
property int x: 5                         // declare
readonly property bool big: x > 10        // computed
required property string title            // must be set
property alias text: label.text           // expose a child property
signal clicked()                          // declare signal; emit with clicked()
onXChanged: …                             // react to change
Component.onCompleted: …                  // once at creation
Connections { target: obj; function onSig(a) { } }
a?.b ?? "fallback"                        // null-safe access
list = [...list, item]                    // notify on array change
Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
```

## Layout

```qml
anchors.fill: parent / anchors.centerIn: parent / anchors.left: other.right
Row { spacing: 8 } / Column { } / Grid { columns: 3 }
RowLayout { Item { Layout.fillWidth: true } }          // spacer
implicitWidth: content.implicitWidth + 20              // components size from content
```

## Common gotchas

| Problem | Fix |
|---|---|
| white window | `color: "transparent"` |
| no keyboard input | `WlrLayershell.keyboardFocus` + `focus: true` |
| volume 0 | `PwObjectTracker` |
| notifications vanish | `n.tracked = true` |
| singleton never runs | reference it in shell.qml |
| update stopped | an assignment broke a binding |
| popup clipped | use `PopupWindow` |
| `qs -c name` fails | remove `~/.config/quickshell/shell.qml` |
