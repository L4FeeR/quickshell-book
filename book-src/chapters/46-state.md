# Orchestrating Panels and State

With a launcher, control center, overview, power menu and wallpaper picker, you need rules: should two panels be open at once? What happens on <kbd>Esc</kbd>? Which monitor? What closes when the screen locks? A central **GlobalStates** singleton answers all of these in one place.

## The GlobalStates singleton

```qml file="services/GlobalStates.qml"
pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    // ---- panels ----
    property bool launcherOpen: false
    property bool controlCenterOpen: false
    property bool overviewOpen: false
    property bool sessionOpen: false
    property bool wallpaperPickerOpen: false
    property bool clipboardOpen: false

    // ---- modes ----
    property bool locked: false
    property bool dnd: false
    property bool caffeine: false
    property bool barHidden: false

    // ---- extra context ----
    property string launcherQuery: ""
    property string activeScreen: Hyprland.focusedMonitor?.name ?? (Quickshell.screens[0]?.name ?? "")

    readonly property bool anyPanelOpen: launcherOpen || controlCenterOpen || overviewOpen
                                      || sessionOpen || wallpaperPickerOpen || clipboardOpen

    // ---- the rules ----
    readonly property var panels: ["launcher", "controlCenter", "overview", "session", "wallpaperPicker", "clipboard"]

    function closeAll(): void {
        for (const p of panels) root[p + "Open"] = false
    }
    function open(name: string): void {           // exclusive: opening one closes the others
        closeAll()
        root[name + "Open"] = true
    }
    function toggle(name: string): void {
        const was = root[name + "Open"]
        closeAll()
        root[name + "Open"] = !was
    }

    // locking closes everything
    onLockedChanged: if (locked) closeAll()

    // ---- external control ----
    IpcHandler {
        target: "shell"
        function toggle(panel: string): void { root.toggle(panel) }
        function open(panel: string): void { root.open(panel) }
        function close(): void { root.closeAll() }
        function lock(): void { root.locked = true }
        function dnd(on: bool): void { root.dnd = on }
    }

    GlobalShortcut { name: "launcher";      onPressed: root.toggle("launcher") }
    GlobalShortcut { name: "controlCenter"; onPressed: root.toggle("controlCenter") }
    GlobalShortcut { name: "overview";      onPressed: root.toggle("overview") }
    GlobalShortcut { name: "session";       onPressed: root.toggle("session") }
    GlobalShortcut { name: "wallpaper";     onPressed: root.toggle("wallpaperPicker") }
    GlobalShortcut { name: "clipboard";     onPressed: root.toggle("clipboard") }
    GlobalShortcut { name: "lock";          onPressed: root.locked = true }
}
```

```ini file="hyprland.conf"
bind = SUPER, Space,  global, quickshell:launcher
bind = SUPER, N,      global, quickshell:controlCenter
bind = SUPER, Tab,    global, quickshell:overview
bind = SUPER, Escape, global, quickshell:session
bind = SUPER, W,      global, quickshell:wallpaper
bind = SUPER, V,      global, quickshell:clipboard
bind = SUPER, L,      global, quickshell:lock
# other compositors:  qs -c myshell ipc call shell toggle launcher
```

## Each panel follows the same pattern

```qml file="modules/launcher/Launcher.qml"
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.services

Scope {
    LazyLoader {
        active: GlobalStates.launcherOpen
        PanelWindow {
            id: win
            screen: Quickshell.screens.find(s => s.name === GlobalStates.activeScreen) ?? null
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            implicitWidth: 600; implicitHeight: 440

            // close on click outside (Hyprland); grabFocus on PopupWindow does this for popups
            HyprlandFocusGrab { windows: [win]; active: true; onCleared: GlobalStates.launcherOpen = false }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: GlobalStates.launcherOpen = false
                // …content…
            }
        }
    }
}
```

The checklist for every panel:

1. `active`/`visible` bound to its GlobalStates flag.
2. `screen` = the active screen.
3. Overlay layer; keyboard focus only if it needs typing.
4. Close on <kbd>Esc</kbd>, on click outside, and after its action completes (launching an app closes the launcher).
5. Never set another panel's flag directly; call `GlobalStates.open/toggle/closeAll`.

## The bar reflects state too

```qml
IconButton { icon: "apps"; toggled: GlobalStates.launcherOpen; onClicked: GlobalStates.toggle("launcher") }
IconButton { icon: "tune"; toggled: GlobalStates.controlCenterOpen; onClicked: GlobalStates.toggle("controlCenter") }
```

## Dimming the background when a panel is open

One fullscreen scrim window per screen, visible whenever any modal panel is open:

```qml file="modules/decorations/Scrim.qml"
import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

Variants {
    model: Quickshell.screens
    PanelWindow {
        required property ShellScreen modelData
        screen: modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:scrim"
        visible: GlobalStates.sessionOpen || fade.running
        color: Qt.rgba(0, 0, 0, GlobalStates.sessionOpen ? 0.45 : 0)
        Behavior on color { ColorAnimation { id: fade; duration: 250 } }
        MouseArea { anchors.fill: parent; onClicked: GlobalStates.closeAll() }
    }
}
```

## Remembering state across reloads and restarts

| Should survive… | Use |
|---|---|
| nothing (panels start closed) | plain properties |
| hot reload only | [[PersistentProperties]] |
| restarts | Config / state file with [[JsonAdapter]] |

DND and caffeine are good candidates to persist across restarts: move them into a state JSON file.

## Idle, lock and caffeine together

```qml file="services/Idle.qml"
pragma Singleton
import Quickshell
import Quickshell.Wayland
import QtQuick

Singleton {
    IdleMonitor {
        timeout: 300                          // 5 minutes
        respectInhibitors: true               // videos and caffeine keep the screen awake
        enabled: !GlobalStates.caffeine
        onIsIdleChanged: if (isIdle) GlobalStates.locked = true
    }
    IdleMonitor {
        timeout: 600
        enabled: !GlobalStates.caffeine
        onIsIdleChanged: Quickshell.execDetached(["hyprctl", "dispatch", "dpms", isIdle ? "off" : "on"])
    }
}
```

[[IdleMonitor]] reports idleness after `timeout` seconds. An [[IdleInhibitor]] attached to a visible window (with `enabled: GlobalStates.caffeine`) prevents idling system-wide while enabled.

> [!TRY] Exercises
> 1. Implement `GlobalStates` with `open/toggle/closeAll`, and wire two panels so opening one closes the other.
> 2. Add IPC and keybinds for both panels.
> 3. Add a caffeine toggle in the bar that controls an `IdleInhibitor` and an `IdleMonitor`.
