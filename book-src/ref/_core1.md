=== Quickshell
@@@ intro
The `Quickshell` singleton is your handle on **Quickshell itself**: the list of screens, your config folder and per-shell data directories, environment variables, launching detached processes, icon lookup, reload control and version checks. You use it in almost every config.

Use it from any file: `Quickshell.screens`, `Quickshell.env("HOME")`, `Quickshell.execDetached([...])`.

@@@ example Example: using every property and function
```qml file="~/.config/quickshell/qs-test/shell.qml"
import Quickshell
import QtQuick
import QtQuick.Layouts

FloatingWindow {
    implicitWidth: 640; implicitHeight: 720
    color: "#1e1e2e"

    component Row2: RowLayout {
        property string k; property string v
        Text { text: parent.k; color: "#a6adc8"; Layout.preferredWidth: 200 }
        Text { text: parent.v; color: "#cdd6f4"; Layout.fillWidth: true; elide: Text.ElideMiddle }
    }

    ColumnLayout {
        anchors { fill: parent; margins: 16 }
        spacing: 4
        // ---- identity ----
        Row2 { k: "processId";  v: Quickshell.processId }
        Row2 { k: "instanceId"; v: Quickshell.instanceId }
        Row2 { k: "shellId";    v: Quickshell.shellId }
        Row2 { k: "appId";      v: Quickshell.appId }
        Row2 { k: "launchTime"; v: Qt.formatDateTime(Quickshell.launchTime, "hh:mm:ss") }
        // ---- folders ----
        Row2 { k: "shellDir";  v: Quickshell.shellDir }
        Row2 { k: "dataDir";   v: Quickshell.dataDir }
        Row2 { k: "stateDir";  v: Quickshell.stateDir }
        Row2 { k: "cacheDir";  v: Quickshell.cacheDir }
        Row2 { k: "shellPath('a.png')"; v: Quickshell.shellPath("assets/a.png") }
        Row2 { k: "statePath('x.json')"; v: Quickshell.statePath("x.json") }
        Row2 { k: "workingDirectory"; v: Quickshell.workingDirectory }
        // ---- environment ----
        Row2 { k: "env('HOME')"; v: Quickshell.env("HOME") }
        Row2 { k: "env('NOPE')"; v: String(Quickshell.env("NOPE")) }      // null if unset
        // ---- screens ----
        Row2 { k: "screens"; v: Quickshell.screens.map(s => s.name).join(", ") }
        // ---- icons ----
        Row2 { k: "hasThemeIcon('firefox')"; v: Quickshell.hasThemeIcon("firefox") }
        Image { source: Quickshell.iconPath("firefox", "application-x-executable"); sourceSize: Qt.size(32, 32) }
        // ---- versions ----
        Row2 { k: "hasVersion(0, 2)"; v: Quickshell.hasVersion(0, 2) }
        Row2 { k: "hasQtVersion(6, 8)"; v: Quickshell.hasQtVersion(6, 8) }
        Row2 { k: "watchFiles"; v: Quickshell.watchFiles }

        RowLayout {
            Text { text: "[launch kitty]"; color: "#89b4fa"
                   TapHandler { onTapped: Quickshell.execDetached(["kitty"]) } }
            Text { text: "[soft reload]"; color: "#89b4fa"
                   TapHandler { onTapped: Quickshell.reload(false) } }
            Text { text: "[copy hello]"; color: "#89b4fa"
                   TapHandler { onTapped: Quickshell.clipboardText = "hello" } }
        }
    }

    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup(); console.log("reloaded") }
        function onReloadFailed(err) { console.warn("reload failed:", err) }
    }
}
```

@@@ member screens
A list of [[ShellScreen]]. It updates when monitors are plugged or unplugged, so `Variants { model: Quickshell.screens }` creates one window per monitor automatically.

@@@ member clipboardText
On Wayland, reading or writing the clipboard only works while a Quickshell window has keyboard focus. For background use, run `wl-copy`/`wl-paste` with [[Process]].

@@@ member execDetached
Pass a list (`["notify-send", "hi"]`). The process isn't a child of Quickshell, so it keeps running if your shell reloads or exits. You can't read its output; use [[Process]] for that.

@@@ member iconPath
Three forms: `iconPath(name)`, `iconPath(name, true)` (returns `""` if the icon doesn't exist), `iconPath(name, "fallback-name")`. The theme comes from `//@ pragma IconTheme`.

@@@ member env
Returns `null` if the variable isn't set, so `Quickshell.env("SWAYSOCK") !== null` tests for Sway.

@@@ notes
- Prefer `shellPath()` over hard-coded paths so your config works wherever it's installed.
- The data/state/cache dirs are per **shell id** (`//@ pragma ShellId`), so two different shells never overwrite each other's files.
- `configDir`, `shellRoot` and `configPath()` are deprecated names for `shellDir` and `shellPath()`.

@@@ see
[[ch:29-shell-structure]] · [[QuickshellSettings]] · [[ShellScreen]]

=== QuickshellSettings
@@@ intro
Settings accessible as `settings` on a [[ShellRoot]]. The same values are also available directly on the [[Quickshell]] singleton (`Quickshell.watchFiles`, `Quickshell.workingDirectory`), which is usually simpler.

@@@ example Example
```qml
ShellRoot {
    settings.watchFiles: true                         // reload on save (default)
    settings.workingDirectory: Quickshell.env("HOME") // where relative paths in processes start
    settings.onLastWindowClosed: console.log("no windows left")
}
```

=== ShellScreen
@@@ intro
A `ShellScreen` is one connected **monitor**. You get them from [[Quickshell.screens]] and assign them to a window's `screen` property. All properties are read-only.

@@@ example Example: using every property
```qml
import Quickshell
import QtQuick

Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property ShellScreen modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 30
            color: "#11111b"
            Text {
                anchors.centerIn: parent
                color: "white"
                text: `${modelData.name} · ${modelData.model} · ${modelData.serialNumber}`
                    + ` · ${modelData.width}×${modelData.height} at (${modelData.x},${modelData.y})`
                    + ` · scale ${modelData.devicePixelRatio}`
                    + ` · ${modelData.physicalPixelDensity.toFixed(2)} px/mm physical`
                    + ` · ${modelData.logicalPixelDensity.toFixed(2)} px/mm logical`
                    + ` · orientation ${modelData.orientation} (primary ${modelData.primaryOrientation})`
            }
        }
    }
}
```

@@@ member name
The connector name, e.g. `eDP-1` (laptop panel), `DP-2`, `HDMI-A-1`. Use it to match compositor monitors (`Hyprland.monitorFor(screen)`) and in config files.

@@@ member devicePixelRatio
The scale factor. Multiply image `sourceSize` by it for crisp images.

@@@ member width
Logical (scaled) width. Physical width = `width * devicePixelRatio`.

=== Reloadable
@@@ intro
The base type of objects that take part in **hot reloading** ([[Scope]], [[Variants]], [[LazyLoader]], windows, [[PersistentProperties]]…). You never create it directly; you use its one property on those types.

@@@ member reloadableId
Quickshell matches old and new objects across a reload by their position in the tree. If you reorder your config, matching can fail and state is lost. A stable `reloadableId` makes matching explicit:
```qml
PersistentProperties { reloadableId: "sidebar"; property bool open }
```

=== Scope
@@@ intro
A **non-visual container**. Windows aren't Items, so they can't be children of a Rectangle; you group them (plus timers, processes, IPC handlers) inside a `Scope`. Most module files (`Bar.qml`, `Launcher.qml`) have a Scope as their root.

@@@ example Example
```qml file="modules/bar/Bar.qml"
import Quickshell
import QtQuick

Scope {
    id: root
    property bool hidden: false          // Scopes can have their own state

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property ShellScreen modelData
            screen: modelData
            visible: !root.hidden
            anchors { top: true; left: true; right: true }
            implicitHeight: 32
        }
    }
    Timer { interval: 5000; running: true; onTriggered: console.log("children:", root.children.length) }
}
```

=== ShellRoot
@@@ intro
The optional root of `shell.qml`. It behaves like a [[Scope]] and adds the `settings` group ([[QuickshellSettings]]).

@@@ example Example
```qml file="shell.qml"
import Quickshell

ShellRoot {
    settings.watchFiles: true
    Bar {}
    Launcher {}
}
```

=== Variants
@@@ intro
`Variants` creates **one instance of its delegate per entry in `model`**, and creates or destroys instances as the model changes. It's the standard way to get one bar per monitor. Unlike `Repeater`, it can create windows and other non-Item objects.

@@@ example Example: one window per screen, using every property
```qml
import Quickshell
import QtQuick

Scope {
    Variants {
        id: bars
        model: Quickshell.screens                       // list<var>; each entry becomes modelData
        delegate: PanelWindow {                         // `delegate:` can be omitted (default property)
            required property ShellScreen modelData
            screen: modelData
            anchors { bottom: true; left: true; right: true }
            implicitHeight: 28
            Text { anchors.centerIn: parent; text: modelData.name }
        }
    }
    // instances: the created objects
    Timer { interval: 2000; running: true; onTriggered: console.log("bars:", bars.instances.length) }
}
```

@@@ member model
Any list. With objects (screens), each instance gets `modelData` set to the element. With plain JS objects, each key becomes a property of the instance if it exists.

@@@ notes
- Declare `required property … modelData` in the delegate.
- Filter screens with a JS expression: `model: Quickshell.screens.filter(s => s.name !== "HDMI-A-1")`.

@@@ see
[[ch:31-multi-monitor]]

=== Region
@@@ intro
A `Region` describes an area of a window, used for [[QsWindow.mask]] (where clicks are accepted), [[HyprlandWindow.visibleMask]] and [[BackgroundEffect.blurRegion]]. Regions can follow an `item`'s geometry automatically and can be nested and combined.

@@@ example Example: using every property
```qml
import Quickshell
import QtQuick

PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    mask: Region {
        item: card                                 // follow this item (overrides x/y/width/height)
        shape: RegionShape.Rect                    // Rect (default) or Ellipse
        radius: 20                                 // rounded corners for Rect
        // per-corner overrides:
        topLeftRadius: 20; topRightRadius: 20; bottomLeftRadius: 4; bottomRightRadius: 4

        Region {                                   // child: add a circle button area
            x: 40; y: 40; width: 60; height: 60    // manual geometry
            shape: RegionShape.Ellipse
            intersection: Intersection.Combine     // Combine | Subtract | Intersect | Xor
        }
        Region {                                   // child: cut a hole out of the card
            item: hole
            intersection: Intersection.Subtract
        }
    }

    Rectangle { id: card; x: 200; y: 200; width: 400; height: 250; radius: 20; color: "#1e1e2e"
        Rectangle { id: hole; x: 150; y: 80; width: 100; height: 80; color: "transparent"; border.color: "red" } }
    Rectangle { x: 40; y: 40; width: 60; height: 60; radius: 30; color: "#cba6f7" }
}
```

@@@ notes
- `mask: Region {}` (empty) makes a window fully click-through.
- Regions bound to items update when the item moves or resizes, including during animations.

@@@ see
[[ch:35-masks]] · [[RegionShape]] · [[Intersection]]

=== PersistentProperties
@@@ intro
Holds properties that **survive hot reloads**. Declare your own properties inside it. Values reset only when Quickshell restarts (for restarts, save to a file with [[FileView]] + [[JsonAdapter]]).

@@@ example Example
```qml
import Quickshell
import QtQuick

Scope {
    PersistentProperties {
        id: persist
        reloadableId: "ui-state"                   // stable id across edits
        property bool sidebarOpen: false
        property int selectedTab: 0
        property string lastQuery: ""

        onLoaded: console.log("ready (every reload)")
        onReloaded: console.log("restored values from the previous config")
    }
    // use: persist.sidebarOpen = true; save a file → value is still true
}
```

=== QsWindow
@@@ intro
The common base of [[PanelWindow]], [[FloatingWindow]] and [[PopupWindow]]. You never create a `QsWindow` directly, but every window has these properties. From any Item inside a window, the attached property `QsWindow.window` returns that window.

@@@ example Example: using the shared window properties
```qml
import Quickshell
import QtQuick

PanelWindow {
    id: win
    anchors { top: true; left: true; right: true }

    // ---- size & visibility ----
    implicitHeight: 40                     // desired size (preferred over width/height)
    visible: true                          // mapped or not
    color: "transparent"                   // background; default WHITE

    // ---- screen ----
    screen: Quickshell.screens[0]

    // ---- input ----
    mask: Region { item: pill }            // only the pill is clickable

    // ---- rendering ----
    surfaceFormat.opaque: false            // request an alpha surface
    updatesEnabled: true                   // false pauses rendering

    Rectangle {
        id: pill
        anchors.centerIn: parent
        width: 200; height: 30; radius: 15; color: "#313244"
        TapHandler {
            onTapped: {
                // read-only info + helpers
                console.log("dpr", win.devicePixelRatio, "backing visible", win.backingWindowVisible)
                console.log("pill rect in window:", win.itemRect(pill), "pos:", win.itemPosition(pill))
                console.log("attached:", pill.QsWindow.window === win)
            }
        }
    }

    onClosed: console.log("compositor closed the window")
    onResourcesLost: console.warn("GPU resources lost")
    onWindowConnected: console.log("surface created")
}
```

@@@ member color
Defaults to white. For rounded or floating designs, set `"transparent"` and draw a Rectangle inside.

@@@ member width
Deprecated for setting: use `implicitWidth`. Reading it gives the real width.

@@@ notes
- `itemRect()`/`itemPosition()` don't update reactively; call them when you need the value, or use `windowTransform` as a binding dependency.
- Children you write inside a window go to `contentItem`, which fills the window.

=== PanelWindow
@@@ intro
A **layer-shell** window glued to screen edges: bars, docks, sidebars, OSDs, launchers, notifications, overlays, desktop widgets and wallpapers. The most-used Quickshell type. It also has every [[QsWindow]] property (size, color, screen, mask…), and the [[WlrLayershell]] attached properties set its layer, namespace and keyboard focus.

@@@ example Example: using every property
```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: bar
    screen: Quickshell.screens[0]

    anchors { top: true; left: true; right: true }    // which screen edges
    margins { top: 6; left: 8; right: 8 }             // distance from anchored edges
    implicitHeight: 36

    exclusiveZone: 42                                  // reserve 42 px (sets mode to Normal-with-zone)
    // exclusionMode: ExclusionMode.Auto               // default: reserve the window size
    // exclusionMode: ExclusionMode.Ignore             // reserve nothing, overlap other panels
    aboveWindows: true                                 // Top layer (false → Bottom layer)
    focusable: false                                   // take keyboard focus when clicked?

    color: "transparent"
    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle { anchors.fill: parent; radius: 12; color: "#cc1e1e2e" }
}
```

@@@ member anchors
Four booleans: `top`, `bottom`, `left`, `right`. Anchoring two opposite edges stretches the window in that direction (no need to set that dimension). No anchors at all centers the window.

@@@ member exclusiveZone
Setting it switches to manual reservation. `0` reserves nothing. Animate it together with the bar for smooth auto-hide.

@@@ member exclusionMode
See [[ExclusionMode]]. Use `Ignore` for overlays, fullscreen click-through windows, OSDs and launchers.

@@@ member focusable
A portable shortcut for keyboard focus on demand. For precise control use [[WlrLayershell.keyboardFocus]].

@@@ see
[[ch:30-panel-windows]] · [[WlrLayershell]] · [[QsWindow]]

=== FloatingWindow
@@@ intro
A **normal application window**, managed by the compositor like any app (tiled, floated, fullscreened). Use it for settings apps, debug panels, or test windows while developing.

@@@ example Example: using every property
```qml
import Quickshell
import QtQuick

FloatingWindow {
    id: win
    title: "My Shell Settings"                   // window title (match it in window rules)
    implicitWidth: 720; implicitHeight: 480
    minimumSize: Qt.size(400, 300)
    maximumSize: Qt.size(1600, 1200)
    color: "#1e1e2e"
    visible: true

    // state (read and request)
    Text {
        anchors.centerIn: parent; color: "white"
        text: `minimized ${win.minimized} · maximized ${win.maximized} · fullscreen ${win.fullscreen}`
    }
    // custom title bar: drag to move, corner to resize
    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 32; color: "#313244"
        DragHandler { target: null; onActiveChanged: if (active) win.startSystemMove() }
        Text { anchors.right: parent.right; text: " □ "; color: "white"; TapHandler { onTapped: win.maximized = !win.maximized } }
    }
    Rectangle {
        anchors { right: parent.right; bottom: parent.bottom }
        width: 16; height: 16; color: "#585b70"
        DragHandler { target: null; onActiveChanged: if (active) win.startSystemResize(Edges.Bottom | Edges.Right) }
    }
    // parentWindow: someOtherWindow    // make it a child/dialog of another window
}
```

```ini file="hyprland.conf"
windowrule = float, title:^(My Shell Settings)$
```

=== PopupWindow
@@@ intro
A window positioned **relative to another window or item**: dropdowns, calendars, tray menus, tooltips. Its position is controlled by the [[PopupAnchor]] in `anchor`. It starts hidden (`visible: false`).

@@@ example Example: using every property
```qml
import Quickshell
import QtQuick

PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    implicitHeight: 34

    Rectangle {
        id: btn
        anchors.centerIn: parent
        width: 120; height: 26; radius: 13; color: "#313244"
        TapHandler { onTapped: pop.visible = !pop.visible }
    }

    PopupWindow {
        id: pop
        anchor.window: bar                       // parent window (implied by anchor.item)
        anchor.item: btn                         // attach to this item
        anchor.edges: Edges.Bottom               // point on the anchor rect
        anchor.gravity: Edges.Bottom             // grow direction
        anchor.margins.top: 8
        anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
        grabFocus: true                          // click outside → closes, visible becomes false
        visible: false
        implicitWidth: 260; implicitHeight: 180
        color: "transparent"
        Rectangle { anchors.fill: parent; radius: 14; color: "#1e1e2e"
            Text { anchors.centerIn: parent; color: "white"; text: "on " + (pop.screen?.name ?? "?") } }
    }
}
```

@@@ member grabFocus
Requests a popup grab: clicking anywhere outside dismisses the popup. The popup also gets keyboard input while open.

@@@ member parentWindow
Deprecated. Use `anchor.window`.

@@@ member relativeX
Deprecated. Use `anchor.rect.x`.

@@@ see
[[ch:32-popups-menus]] · [[PopupAnchor]]

=== Singleton
@@@ intro
The root type for **your own singletons**. Put `pragma Singleton` at the top of a file whose root is `Singleton { }`, place it in an imported folder, and use it by its file name from anywhere.

@@@ example Example
```qml file="services/Counter.qml"
pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root
    property int count: 0
    function increment(): void { count++ }
}
```
```qml
import qs.services
Text { text: Counter.count; TapHandler { onTapped: Counter.increment() } }
```

@@@ notes
Singletons are created on first use. If one must start at login, reference it from `shell.qml`.

@@@ see
[[ch:33-singletons]]
