# Lazy Loading and Memory

A full shell has a dozen panels: launcher, sidebar, overview, power menu, wallpaper picker, settings, cheatsheet. If all of them existed all the time, your shell would use hundreds of megabytes and start slowly. The fix: create panels only while they're open.

## LazyLoader

[[LazyLoader]] creates a component when needed and destroys it when not. Unlike Qt's `Loader`, it's designed for **windows** and non-visual objects (anything, not just Items), and it can pre-load in the background.

```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

Scope {
    LazyLoader {
        id: loader
        active: GlobalStates.launcherOpen     // true → create now; false → destroy

        PanelWindow {                         // the component (implicit)
            implicitWidth: 600; implicitHeight: 400
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            // …launcher UI…
        }
    }
}
```

### LazyLoader members

| Member | Meaning |
|---|---|
| `active` | `true`: load fully **now** (synchronously, blocking) and keep it. `false`: destroy it. |
| `activeAsync` | Like `active`, but loads asynchronously first (no stutter), then activates. |
| `loading` | `true`: start loading **in the background** without showing it, so a later `active: true` is instant. |
| `component` | The component to load (implicit when you write a child). |
| `source` | Load from a file URL instead. |
| `item` | The created object, or `null`. |

### Three strategies

```qml
// 1. Create on open, destroy on close (lowest memory)
LazyLoader { active: GlobalStates.overviewOpen; Overview {} }

// 2. Pre-load in the background at startup, show instantly later
LazyLoader {
    loading: true                         // build in the background
    active: GlobalStates.launcherOpen     // flip to visible instantly when needed
    Launcher {}
}

// 3. Async activation (no frame drop for heavy panels)
LazyLoader { activeAsync: GlobalStates.settingsOpen; SettingsWindow {} }
```

> [!TIP] Closing animations with LazyLoader
> If `active` goes false the window is destroyed immediately, so there's no time for a closing animation. Keep it active during the animation: `active: GlobalStates.sidebarOpen || closeAnim.running`, or keep a separate `property bool shown` that turns false only after the animation finishes.

## Loader (for items inside a window)

For parts of a window (tab pages, heavy widgets), use Qt's `Loader` ([[ch:14-lifecycle]]):

```qml
Loader {
    active: tabs.currentIndex === 2
    asynchronous: true
    sourceComponent: BigMediaDashboard {}
}
```

## visible vs LazyLoader vs Loader

| | Memory while hidden | Opens instantly | State kept when hidden | Use for |
|---|---|---|---|---|
| `visible: false` | full | yes | yes | small or frequently toggled things |
| `LazyLoader { active }` | none | small delay | no | big windows opened sometimes |
| `LazyLoader { loading: true; active }` | full after preload | yes | yes | big windows opened often (launcher) |
| `Loader { active }` | none | small delay | no | heavy parts *inside* a window |

## Keeping state across loads

Destroyed panels forget their state (scroll position, selected tab, typed text). Keep anything worth remembering in a singleton, so the new instance picks it up:

```qml
// in the panel:
TabBar { currentIndex: GlobalStates.sidebarTab; onCurrentIndexChanged: GlobalStates.sidebarTab = currentIndex }
```

## Other memory tips

- Set **`sourceSize`** on every image ([[ch:16-rect-text-image]]).
- Use **ListView** instead of Repeater for long lists: it only creates visible delegates.
- Don't keep `ScreencopyView.live: true` for hidden previews.
- Watch memory: `ps -o rss,cmd -p $(pgrep -f "qs -c myshell")` shows resident memory in KB.

> [!WILD] In the wild
> end-4 loads its sidebars, overview, session screen and cheatsheet lazily, controlled by `GlobalStates`. Caelestia keeps its drawers mostly loaded so they animate out of the bar instantly, a deliberate memory-for-smoothness trade.

> [!TRY] Exercises
> 1. Wrap a big test window in a `LazyLoader` toggled by a bar button. Add `Component.onCompleted`/`onDestruction` logs and watch them.
> 2. Switch it to `loading: true` and notice that it opens instantly.
> 3. Keep it alive during a 300 ms fade-out using `active: open || fade.running`.
