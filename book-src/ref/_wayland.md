=== WlrLayershell
@@@ intro
Layer-shell settings for a [[PanelWindow]], used as **attached properties**: `WlrLayershell.layer`, `WlrLayershell.namespace`, `WlrLayershell.keyboardFocus`. They decide which stacking layer the window lives on, what name compositor rules see, and whether it receives keyboard input.

@@@ example Example: every property
```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    implicitWidth: 500; implicitHeight: 60
    color: "#1e1e2e"
    WlrLayershell.layer: WlrLayer.Overlay                   // Background | Bottom | Top (default) | Overlay
    WlrLayershell.namespace: "quickshell:search"            // for layerrules; can't change after creation
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive // None (default) | Exclusive | OnDemand

    TextInput { anchors.centerIn: parent; focus: true; color: "white"; width: 400; Keys.onEscapePressed: Qt.quit() }
}
```

@@@ member keyboardFocus
`Exclusive` takes all keyboard input while the window is mapped, so close it with <kbd>Esc</kbd>. `OnDemand` gets focus when clicked. Bars should stay `None`.

@@@ member namespace
Use a consistent scheme such as `quickshell:bar` and match it in Hyprland with `layerrule = blur, quickshell:bar`.

@@@ see
[[ch:30-panel-windows]] · [[WlrLayer]] · [[WlrKeyboardFocus]]

=== WlSessionLock
@@@ intro
Locks the session with the **ext-session-lock** protocol: while `locked` is true, the compositor shows only your lock surfaces and sends input only to them. If your shell crashes, the session stays locked.

@@@ example Example: every property
```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

Scope {
    WlSessionLock {
        id: lock
        locked: false                                 // set true to lock
        surface: Component {                          // one surface per screen, created automatically
            WlSessionLockSurface {
                color: "black"
                Text { anchors.centerIn: parent; color: "white"; text: "Locked" + (lock.secure ? " (secure)" : "") }
                // unlock ONLY after successful PAM auth (see PamContext)
            }
        }
        onSecureChanged: console.log("compositor confirmed lock:", secure)
    }
}
```

@@@ member locked
Only one `WlSessionLock` may be locked at a time. Setting `locked = false` unlocks.

@@@ member secure
True once the compositor confirms every screen is covered. Don't show sensitive UI before then.

@@@ notes
Never unlock without authentication. Keep a safety timer while developing ([[ch:57-proj-lock]]).

@@@ see
[[WlSessionLockSurface]] · [[PamContext]] · [[ch:57-proj-lock]]

=== WlSessionLockSurface
@@@ intro
The lock screen shown on **one screen** while a [[WlSessionLock]] is locked. Put your lock UI inside it; Quickshell creates one per monitor from the lock's `surface` component.

@@@ example Example: every property
```qml
WlSessionLockSurface {
    id: s
    color: "#11111b"                        // background
    Text {
        anchors.centerIn: parent; color: "white"
        text: `${s.screen?.name}: ${s.width}×${s.height}, visible ${s.visible}`
    }
    TextInput { focus: true; echoMode: TextInput.Password }   // receives keys while locked
}
```

=== Toplevel
@@@ intro
A window of **another application**, from the compositor-independent foreign-toplevel protocol. Get them from [[ToplevelManager]] or [[HyprlandToplevel.wayland]]. Use them for taskbars, docks and live previews.

@@@ example Example: every property and function
```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

Column {
    Repeater {
        model: ToplevelManager.toplevels
        Row {
            required property Toplevel modelData
            spacing: 8
            Text { text: (modelData.activated ? "● " : "  ") + modelData.appId + " — " + modelData.title }
            Text { text: modelData.maximized ? "[max]" : ""; color: "grey" }
            Text { text: modelData.minimized ? "[min]" : ""; color: "grey" }
            Text { text: modelData.fullscreen ? "[full]" : ""; color: "grey" }
            Text { text: modelData.parent ? "dialog of " + modelData.parent.title : "" }
            Text { text: "on " + modelData.screens.map(s => s.name).join(",") }
            Text { text: "[focus]"; TapHandler { onTapped: modelData.activate() } }
            Text { text: "[max]"; TapHandler { onTapped: modelData.maximized = !modelData.maximized } }
            Text { text: "[min]"; TapHandler { onTapped: modelData.minimized = true } }
            Text { text: "[full on 1st screen]"; TapHandler { onTapped: modelData.fullscreenOn(Quickshell.screens[0]) } }
            Text { text: "[close]"; TapHandler { onTapped: modelData.close() } }
            Connections { target: modelData; function onClosed() { console.log("closed:", modelData.title) } }
        }
    }
}
```

@@@ member setRectangle
Tells the compositor where this window's icon is (e.g. in your dock), so minimize animations can fly there: `toplevel.setRectangle(dockWindow, dockWindow.itemRect(icon))`.

@@@ notes
All state changes are **requests**; the compositor may ignore them.

=== ToplevelManager
@@@ intro
Lists every application window on compositors that support the foreign-toplevel protocol (Hyprland, Sway, niri, river, labwc, Wayfire…).

@@@ example Example
```qml
import Quickshell.Wayland
import QtQuick

Column {
    Text { text: "focused: " + (ToplevelManager.activeToplevel?.title ?? "none") }
    Text { text: ToplevelManager.toplevels.values.length + " windows" }
}
```

@@@ see
[[Toplevel]] · [[ch:59-proj-dock]]

=== ScreencopyView
@@@ intro
Displays a live video (or a single frame) of **a window or a whole monitor**. That's how overviews and window switchers show previews.

@@@ example Example: every property and function
```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

Row {
    spacing: 10
    ScreencopyView {                                       // live monitor preview
        id: mon
        width: 320; height: 180
        captureSource: Quickshell.screens[0]               // ShellScreen, Toplevel, or null
        live: true                                         // continuous updates
        paintCursor: true                                  // include the mouse cursor
        constraintSize: Qt.size(320, 180)                  // fit within, keep aspect ratio
        onStopped: console.log("stream ended")
    }
    ScreencopyView {                                       // still frame of the focused window
        id: still
        width: 320; height: 180
        captureSource: ToplevelManager.activeToplevel
        live: false
        Component.onCompleted: captureFrame()              // grab one frame
        Text { visible: !still.hasContent; text: "no content yet"; color: "white" }
        Text { anchors.bottom: parent.bottom; color: "white"
               text: still.hasContent ? still.sourceSize.width + "×" + still.sourceSize.height : "" }
    }
}
```

@@@ notes
Live capture costs GPU time. Enable `live` only while visible.

=== IdleInhibitor
@@@ intro
Prevents the session from going idle (screen blanking, auto-lock) while `enabled`, for "caffeine" toggles or while presenting. It must be associated with a window.

@@@ example Example
```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    implicitHeight: 30
    property bool caffeine: false
    IdleInhibitor { window: bar; enabled: bar.caffeine }
    Text { anchors.centerIn: parent; text: bar.caffeine ? "☕ awake" : "💤 normal"
           TapHandler { onTapped: bar.caffeine = !bar.caffeine } }
}
```

@@@ member window
The compositor may ignore the inhibitor if this window isn't visible.

=== IdleMonitor
@@@ intro
Tells you when the user has been **idle** for `timeout` seconds. Use it to lock the screen, dim, or turn displays off, without hypridle.

@@@ example Example: every property
```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

Scope {
    IdleMonitor {
        id: idle
        enabled: true
        timeout: 300                       // seconds
        respectInhibitors: true            // don't report idle while a video/IdleInhibitor blocks it
        onIsIdleChanged: {
            if (isIdle) GlobalStates.locked = true
        }
    }
}
```

=== ShortcutInhibitor
@@@ intro
While enabled and its window has keyboard focus, **compositor shortcuts are disabled**: every key goes to your window. Useful for key-capture UIs (keybind editors), games or kiosk screens.

@@@ example Example: every property
```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: win
    implicitWidth: 400; implicitHeight: 120
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    ShortcutInhibitor {
        id: inhib
        window: win
        enabled: true
        onCancelled: console.log("compositor cancelled the inhibitor")
    }
    Text { anchors.centerIn: parent; text: inhib.active ? "Press any key combo…" : "inactive" }
    Item { focus: true; Keys.onPressed: e => console.log("captured", e.key, e.modifiers) }
}
```

=== BackgroundEffect
@@@ intro
Asks the compositor to **blur what's behind** parts of your window, through a Wayland protocol (on compositors that support it). Used as an attached property on a window: `BackgroundEffect.blurRegion`.

@@@ example Example
```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    anchors { top: true; left: true; right: true }
    implicitHeight: 40
    color: "transparent"
    BackgroundEffect.blurRegion: Region { item: panel; radius: 12 }   // null removes blur
    Rectangle { id: panel; anchors.fill: parent; anchors.margins: 6; radius: 12; color: "#801e1e2e" }
}
```

@@@ notes
If your compositor doesn't support the protocol, nothing happens. On Hyprland, `layerrule = blur` works regardless.
