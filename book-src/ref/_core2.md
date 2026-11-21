=== LazyLoader
@@@ intro
Creates its component **only when needed** and destroys it when not, which saves memory for panels that are usually closed. It works with windows and any other object, and can pre-load in the background so opening is instant.

@@@ example Example: every property
```qml
import Quickshell
import QtQuick

Scope {
    property bool open: false

    LazyLoader {
        id: loader
        // choose ONE way to control it:
        active: open              // true → load synchronously now; false → destroy
        // activeAsync: open      // true → load in the background, then activate
        // loading: true          // pre-load in the background without showing yet

        // what to load: inline (component) or from a file (source)
        component: PanelWindow {
            implicitWidth: 400; implicitHeight: 300
            Text { anchors.centerIn: parent; text: "I exist only while open" }
        }
        // source: "BigPanel.qml"
    }

    // the created object (null when not loaded)
    Timer { interval: 1000; running: true; repeat: true; onTriggered: console.log("item:", loader.item) }
}
```

@@@ member loading
Setting `loading: true` starts building in the background; when `active` later becomes true the object is ready immediately. Combine both: `loading: true; active: GlobalStates.launcherOpen`.

@@@ notes
When `active` becomes false the object is destroyed immediately, so there's no time for a closing animation. Keep it active while animating: `active: open || closeAnim.running`.

@@@ see
[[ch:34-lazy-loading]]

=== EasingCurve
@@@ intro
Evaluates an easing curve **in JavaScript**, so you can apply the same curve as your animations to computed values (for example, mapping a scroll position or a progress value through a curve).

@@@ example Example
```qml
import Quickshell
import QtQuick

Item {
    EasingCurve {
        id: curve
        curve.type: Easing.OutCubic               // same options as an animation's `easing`
    }
    property real progress: 0.3                    // 0..1, e.g. from a drag
    readonly property real eased: curve.valueAt(progress)
    readonly property real x2: curve.interpolate(progress, 0, 300)                       // number
    readonly property point p: curve.interpolate(progress, Qt.point(0, 0), Qt.point(100, 50))   // point
    readonly property rect r: curve.interpolate(progress, Qt.rect(0, 0, 10, 10), Qt.rect(50, 50, 200, 100))
}
```

=== TransformWatcher
@@@ intro
Notifies you whenever the geometry relationship between two items changes, including when any ancestor moves, resizes or transforms. Useful when something must track another item's position across different parts of the tree (e.g. an indicator following a button inside a moving panel).

@@@ example Example
```qml
import Quickshell
import QtQuick

Item {
    TransformWatcher {
        id: watcher
        a: buttonInBar             // item A
        b: overlayRoot             // item B
        commonParent: null         // optional optimization if you know one
    }
    Rectangle {
        // re-evaluates whenever watcher.transform changes
        readonly property point p: { watcher.transform; return buttonInBar.mapToItem(overlayRoot, 0, 0) }
        x: p.x; y: p.y; width: 10; height: 10; color: "red"
    }
}
```

=== BoundComponent
@@@ intro
Like a `Loader`, but properties you declare on the `BoundComponent` are passed to the loaded object and (by default) kept bound. Handy for loading a component from a file and feeding it properties without wiring each one by hand.

@@@ example Example
```qml
import Quickshell
import QtQuick

BoundComponent {
    source: "Card.qml"                // or sourceComponent: Component { … }
    bindValues: true                  // keep the values below bound (default)
    property string title: "Hello"    // passed to Card's `title`
    property color accent: "#cba6f7"  // passed to Card's `accent`
    onLoaded: console.log("loaded", item, "size", implicitWidth, implicitHeight)
}
```

=== ObjectModel
@@@ intro
Quickshell's **live list** type. Service lists like [[Hyprland.workspaces]], [[Mpris.players]], [[SystemTray.items]], [[Pipewire.nodes]] and [[DesktopEntries.applications]] are ObjectModels. Give them directly to a Repeater/ListView/Variants, or read `.values` as a JS array.

@@@ example Example
```qml
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Column {
    Repeater {                                    // 1. as a model: delegates get modelData
        model: Mpris.players
        Text { required property MprisPlayer modelData; text: modelData.identity }
    }
    Text {                                        // 2. as an array
        text: "playing: " + Mpris.players.values.filter(p => p.isPlaying).length
    }
    Connections {                                 // 3. per-item change signals
        target: Mpris.players
        function onObjectInsertedPost(obj, index) { console.log("added", obj.identity, "at", index) }
        function onObjectRemovedPre(obj, index) { console.log("removing", obj.identity) }
    }
    Component.onCompleted: console.log("index of first:", Mpris.players.indexOf(Mpris.players.values[0]))
}
```

@@@ see
[[ch:36-models]] · [[ScriptModel]]

=== ElapsedTimer
@@@ intro
Measures elapsed time precisely, like a stopwatch. Starts when created.

@@@ example Example: every function
```qml
import Quickshell
import QtQuick

Item {
    ElapsedTimer { id: sw }
    TapHandler {
        onTapped: {
            console.log("seconds:", sw.elapsed())       // real, nanosecond precision
            console.log("ms:", sw.elapsedMs())
            console.log("ns:", sw.elapsedNs())
            const lap = sw.restart()                     // returns elapsed seconds, then restarts
            // restartMs() / restartNs() return ms / ns
            console.log("lap:", lap)
        }
    }
}
```

=== DesktopEntry
@@@ intro
One installed application, read from a `.desktop` file. Get entries from [[DesktopEntries]]: the `applications` list, `byId()` or `heuristicLookup()`.

@@@ example Example: every property
```qml
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    readonly property DesktopEntry e: DesktopEntries.heuristicLookup("firefox")
    visible: e !== null
    IconImage { implicitSize: 48; source: Quickshell.iconPath(e?.icon ?? "", "application-x-executable") }
    Text { text: "id: " + e?.id }                         // "firefox" (file name without .desktop)
    Text { text: "name: " + e?.name }                     // "Firefox"
    Text { text: "genericName: " + e?.genericName }       // "Web Browser"
    Text { text: "comment: " + e?.comment }
    Text { text: "icon: " + e?.icon }
    Text { text: "startupClass: " + e?.startupClass }     // window class/app id it will use
    Text { text: "noDisplay: " + e?.noDisplay }
    Text { text: "runInTerminal: " + e?.runInTerminal }
    Text { text: "categories: " + e?.categories.join(", ") }
    Text { text: "keywords: " + e?.keywords.join(", ") }
    Text { text: "execString: " + e?.execString }         // raw Exec= line (don't run it directly)
    Text { text: "command: " + JSON.stringify(e?.command) } // parsed argv, safe to run
    Text { text: "workingDirectory: " + e?.workingDirectory }
    Repeater { model: e?.actions ?? []; Text { required property DesktopAction modelData; text: "action: " + modelData.name } }
    Text { text: "[launch]"; TapHandler { onTapped: e.execute() } }
}
```

@@@ member command
The `Exec` line parsed into a list, with field codes (`%u`, `%F`…) removed. Run it with `Quickshell.execDetached(entry.command)` or put a terminal in front when `runInTerminal` is true.

@@@ member execute
Launches the app. It currently ignores `runInTerminal`; handle that yourself.

=== DesktopAction
@@@ intro
An extra action an app offers in its `.desktop` file, such as Firefox's "New Private Window". Found in [[DesktopEntry.actions]].

@@@ example Example
```qml
Repeater {
    model: DesktopEntries.heuristicLookup("firefox")?.actions ?? []
    Text {
        required property DesktopAction modelData
        text: modelData.name + "  (" + modelData.id + ")"      // icon, execString, command also available
        TapHandler { onTapped: modelData.execute() }
    }
}
```

=== DesktopEntries
@@@ intro
The index of every installed application. It updates automatically when apps are installed or removed.

@@@ example Example: every member
```qml
import Quickshell
import QtQuick

Column {
    Text { text: DesktopEntries.applications.values.length + " apps installed" }
    Text { text: "byId('kitty'): " + (DesktopEntries.byId("kitty")?.name ?? "none") }               // exact id, includes NoDisplay entries
    Text { text: "heuristic('Code'): " + (DesktopEntries.heuristicLookup("Code")?.name ?? "none") } // fuzzy: matches window classes
    ListView {
        width: 300; height: 300; clip: true
        model: DesktopEntries.applications
        delegate: Text { required property DesktopEntry modelData; text: modelData.name }
    }
}
```

@@@ member heuristicLookup
Use it to map a **window's app id or class** to its desktop entry (icons in docks, taskbars and overviews). It tries exact ids, `StartupWMClass` and case-insensitive matches.

=== QsMenuHandle
@@@ intro
An opaque handle to a menu (for example [[SystemTrayItem.menu]]). Pass it to [[QsMenuAnchor.menu]] to show the menu, or to [[QsMenuOpener.menu]] to read its entries.

=== QsMenuEntry
@@@ intro
One item of a menu, obtained from [[QsMenuOpener.children]]. Use its properties to draw a custom menu and emit `triggered()` to activate it.

@@@ example Example: every member
```qml
Repeater {
    model: opener.children
    Row {
        required property QsMenuEntry modelData
        visible: !modelData.isSeparator                       // separators: draw a line instead
        opacity: modelData.enabled ? 1 : 0.4
        Image { source: modelData.icon; width: 16; height: 16; visible: modelData.icon !== "" }
        Text { text: modelData.text.replace(/_/g, "") }
        Text {                                                // checkbox / radio state
            visible: modelData.buttonType !== QsMenuButtonType.None
            text: modelData.checkState === Qt.Checked ? "☑" : "☐"
        }
        Text { visible: modelData.hasChildren; text: "›" }    // submenu: open another QsMenuOpener with menu: modelData
        TapHandler { onTapped: modelData.triggered() }
        // native submenu instead: modelData.display(window, x, y)
    }
}
```

@@@ see
[[ch:50-proj-tray]]

=== QsMenuOpener
@@@ intro
Reads the entries of a menu so you can draw it yourself. Set `menu` to a menu handle (or to a [[QsMenuEntry]] that `hasChildren` to open a submenu).

@@@ example Example
```qml
QsMenuOpener { id: opener; menu: trayItem.menu }
Column {
    Repeater {
        model: opener.children
        Text { required property QsMenuEntry modelData; text: modelData.isSeparator ? "────" : modelData.text
               TapHandler { onTapped: modelData.triggered() } }
    }
}
```

=== Retainable
@@@ intro
Some objects (notably notifications) can be **retained**: kept alive briefly after they would normally be destroyed, so you can animate them out. `Retainable` is attached to such objects: `notification.Retainable.lock()`. Usually [[RetainableLock]] is more convenient.

@@@ example Example
```qml
NotificationCard {
    required property Notification notif
    Component.onCompleted: notif.Retainable.lock()                      // keep alive
    Connections {
        target: notif.Retainable
        function onDropped() { fadeOut.start() }                        // it would be destroyed now
        function onAboutToDestroy() { console.log("gone") }
    }
    SequentialAnimation {
        id: fadeOut
        NumberAnimation { target: card; property: "opacity"; to: 0; duration: 200 }
        ScriptAction { script: notif.Retainable.unlock() }              // allow destruction
    }
}
```

=== RetainableLock
@@@ intro
A declarative way to retain an object: while `locked` is true, the `object` isn't destroyed even after it's closed, giving you time for an exit animation.

@@@ example Example
```qml
Item {
    id: card
    required property Notification notif
    RetainableLock {
        id: lock
        object: card.notif
        locked: true
        onDropped: exit.start()               // notification closed: animate out
    }
    NumberAnimation { id: exit; target: card; property: "opacity"; to: 0; duration: 250
                      onFinished: lock.locked = false }      // now it may be destroyed
}
```

=== PopupAnchor
@@@ intro
The positioning group used by [[PopupWindow.anchor]] and [[QsMenuAnchor.anchor]]. It describes an **anchor rectangle** (an item, or a rect inside a window), which point of it to attach to (`edges`), which way to grow (`gravity`), and how to adjust when the popup doesn't fit.

@@@ example Example: every property
```qml
PopupWindow {
    id: pop
    anchor.window: bar                         // the parent window
    anchor.item: button                        // the rect becomes the button's geometry (sets window too)
    anchor.rect.x: 0                           // or a manual rect relative to item/window
    anchor.rect.y: 0
    anchor.rect.width: button.width
    anchor.rect.height: button.height
    anchor.margins { top: 6; bottom: 6; left: 0; right: 0 }   // grow/shrink the rect
    anchor.edges: Edges.Bottom | Edges.Left    // attach at the bottom-left corner of the rect
    anchor.gravity: Edges.Bottom | Edges.Right // and extend down and to the right
    anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
    anchor.onAnchoring: { /* last chance to tweak anchor.rect before positioning */ }
    implicitWidth: 200; implicitHeight: 100
}
// if the anchor item moved without a property change: pop.anchor.updateAnchor()
```

@@@ see
[[ch:32-popups-menus]] · [[Edges]] · [[PopupAdjustment]]

=== QsMenuAnchor
@@@ intro
Displays a menu (e.g. a tray item's menu) as a **native-styled popup** at an anchor. For custom styling use [[QsMenuOpener]] instead.

@@@ example Example: every member
```qml
QsMenuAnchor {
    id: menu
    menu: trayItem.menu                    // a QsMenuHandle
    anchor.item: trayIcon
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    onOpened: console.log("menu shown")
    onClosed: console.log("menu closed")
}
TapHandler { acceptedButtons: Qt.RightButton; onTapped: menu.visible ? menu.close() : menu.open() }
```

=== SystemClock
@@@ intro
A clock that updates **exactly** on second, minute or hour boundaries, and only as often as you need. It's better than a Timer for any displayed time.

@@@ example Example: every property
```qml
import Quickshell
import QtQuick

Column {
    SystemClock {
        id: clock
        precision: SystemClock.Seconds     // Seconds | Minutes | Hours
        enabled: true                      // false pauses updates
    }
    Text { text: Qt.formatDateTime(clock.date, "dddd d MMMM yyyy, hh:mm:ss") }
    Text { text: `${clock.hours}h ${clock.minutes}m ${clock.seconds}s` }
}
```

@@@ member precision
Use `Minutes` unless you display seconds: the shell wakes 60× less often.

@@@ member minutes
`0` when precision is `Hours`.

@@@ member seconds
`0` when precision is `Minutes` or `Hours`.

@@@ see
[[ch:28-timers-time]]

=== ScriptModel
@@@ intro
A model built from a **JavaScript array** that diffs each new array against the previous one, so views keep existing delegates and animate only real insertions and removals. Use it for filtered or sorted lists.

@@@ example Example: every property
```qml
import Quickshell
import QtQuick

ListView {
    width: 300; height: 400; clip: true
    model: ScriptModel {
        values: DesktopEntries.applications.values
                    .filter(a => a.name.toLowerCase().includes(search.text.toLowerCase()))
                    .sort((a, b) => a.name.localeCompare(b.name))
        comparisonMode: ObjectComparison.Identity       // objects: same reference = same item (fast)
        // objectProp: "id"                              // plain JS objects: compare by this key
    }
    delegate: Text { required property DesktopEntry modelData; text: modelData.name }
    add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 } }
    remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 150 } }
}
```

@@@ notes
Values must be unique. For lists of plain objects (parsed JSON), set `objectProp` to a unique key.

@@@ see
[[ch:36-models]] · [[ObjectComparison]]

=== ColorQuantizer
@@@ intro
Extracts the **dominant colors** of an image, in-process. Use it to tint a media card with album art colors or make accents from a wallpaper without external tools.

@@@ example Example: every property
```qml
import Quickshell
import QtQuick

Row {
    ColorQuantizer {
        id: q
        source: "file:///home/me/Pictures/wall.jpg"   // or Media.active.trackArtUrl
        depth: 3                                      // 2^3 = up to 8 colors
        rescaleSize: 64                               // shrink first for speed (0 = no scaling)
        imageRect: Qt.rect(0, 0, 500, 500)            // optional crop; undefined = whole image
    }
    Repeater {
        model: q.colors                               // list<color> results
        Rectangle { required property color modelData; width: 32; height: 32; color: modelData }
    }
}
```

@@@ notes
Results arrive asynchronously; bind to `colors` and provide a fallback (`q.colors[0] ?? Colors.primary`).
