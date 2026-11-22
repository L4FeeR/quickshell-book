# Models, Repeater and ListView

Workspaces, tray icons, notifications, apps, Wi-Fi networks, media players: shells are full of **lists of things**. QML handles them with **models** (the data), **delegates** (a template per item) and **views** (Repeater, ListView, GridView) that combine the two.

<div class="diagram"><svg viewBox="0 0 780 150" role="img" aria-label="model delegate view">
<rect class="g" x="20" y="40" width="200" height="70" rx="10"/><text x="40" y="70">Model</text><text class="sm" x="40" y="90">the data: [a, b, c]</text>
<rect class="a" x="290" y="40" width="200" height="70" rx="10"/><text x="310" y="70">Delegate</text><text class="sm" x="310" y="90">template for ONE item</text>
<rect class="n" x="560" y="40" width="200" height="70" rx="10"/><text x="580" y="70">View</text><text class="sm" x="580" y="90">stamps delegate per item</text>
<path class="ln" d="M220 75 H290 M490 75 H560"/>
</svg></div>

## Repeater

`Repeater` creates one delegate per model entry, places them in its parent, and keeps them in sync with the model.

### Model = a number
```qml
Row {
    spacing: 6
    Repeater {
        model: 5                                  // 5 copies, index 0..4
        Rectangle {
            required property int index           // provided by the Repeater
            width: 24; height: 24; radius: 12
            color: index === 2 ? "#cba6f7" : "#45475a"
            Text { anchors.centerIn: parent; text: parent.index + 1; color: "white" }
        }
    }
}
```

### Model = a JS array
```qml
Column {
    Repeater {
        model: ["Firefox", "Kitty", "Spotify"]
        Text {
            required property string modelData    // the array element
            required property int index
            text: (index + 1) + ". " + modelData
            color: "white"
        }
    }
}
```

### Model = an array of objects
```qml
Repeater {
    model: [
        { icon: "wifi",       label: "Wi-Fi",     on: true },
        { icon: "bluetooth",  label: "Bluetooth", on: false }
    ]
    Row {
        required property var modelData
        spacing: 6
        Text { text: modelData.icon; font.family: "Material Symbols Rounded"; color: modelData.on ? "#a6e3a1" : "#6c7086" }
        Text { text: modelData.label; color: "white" }
    }
}
```

### Model = a Quickshell ObjectModel
Quickshell's lists (workspaces, tray items, players, devices, notifications) are [[ObjectModel]]s. Pass them directly:

```qml
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Row {
    Repeater {
        model: SystemTray.items
        IconImage {
            required property SystemTrayItem modelData    // each element is a SystemTrayItem
            implicitSize: 18
            source: modelData.icon
        }
    }
}
```

### required properties in delegates
A delegate receives its data through these names:

| Name | Available when | Meaning |
|---|---|---|
| `index` | always | position in the model |
| `modelData` | arrays, ObjectModels, numbers | the element itself |
| *role names* | `ListModel` / C++ models | each field directly (e.g. `title`) |

Always **declare** them with `required property`. That makes the data explicit, gives you types and autocomplete, and is required for some models in Qt 6.

### Repeater properties

| Property / method | Meaning |
|---|---|
| `model` | The data |
| `delegate` | The template (implicit when you write a child) |
| `count` | Number of created items |
| `itemAt(i)` | The delegate object at index i |
| `onItemAdded(index, item)` / `onItemRemoved` | Signals |

## ListModel: a mutable list you control

When *you* own the list (history, todo items, a custom menu) and want to add or remove entries with nice animations:

```qml
ListModel {
    id: todos
    ListElement { title: "Rice the bar"; done: true }
    ListElement { title: "Lock screen"; done: false }
}

// later, in JS:
todos.append({ title: "Launcher", done: false })
todos.insert(0, { title: "First!", done: false })
todos.remove(1)
todos.setProperty(0, "done", true)
todos.move(0, 2, 1)
todos.clear()
todos.count        // number of entries
todos.get(0).title // read an entry
```

Delegates receive role names directly: `required property string title`, `required property bool done`.

## ListView: scrolling lists

`Repeater` creates **everything** at once. `ListView` creates only the delegates that are **visible**, scrolls, and supports keyboard navigation, highlights and transitions. Use it for anything that might be long (apps, notifications, clipboard history).

```qml
ListView {
    id: list
    width: 300; height: 400
    clip: true                                 // don't draw outside the view
    spacing: 4
    model: DesktopEntries.applications         // ObjectModel of DesktopEntry
    delegate: Rectangle {
        required property DesktopEntry modelData
        required property int index
        width: ListView.view.width             // attached: the view this delegate is in
        height: 40; radius: 8
        color: ListView.isCurrentItem ? "#45475a" : "transparent"
        Text { anchors.verticalCenter: parent.verticalCenter; x: 12; text: modelData.name; color: "white" }
        MouseArea { anchors.fill: parent; onClicked: list.currentIndex = index }
    }
}
```

### Important ListView properties

| Property | Meaning |
|---|---|
| `model`, `delegate` | Data and template |
| `orientation` | `ListView.Vertical` (default) or `ListView.Horizontal` |
| `spacing` | Gap between delegates |
| `currentIndex`, `currentItem` | Selection |
| `highlight`, `highlightFollowsCurrentItem`, `highlightMoveDuration` | A moving selection rectangle |
| `keyNavigationEnabled`, `keyNavigationWraps` | Arrow keys move the selection |
| `clip` | Cut delegates at the view's edges (almost always `true`) |
| `interactive` | Allow drag/flick scrolling |
| `boundsBehavior` | `Flickable.StopAtBounds` stops the "rubber band" overscroll |
| `cacheBuffer` | Pixels of off-screen delegates to keep alive |
| `header`, `footer`, `section.*` | Extra items and grouping |
| `verticalLayoutDirection` | `ListView.BottomToTop` for chat-like lists |
| `add`, `remove`, `displaced`, `move` | Transitions for model changes |
| `contentY`, `contentHeight`, `atYEnd` | Scroll state |

Methods: `positionViewAtIndex(i, ListView.Contain)`, `positionViewAtEnd()`, `incrementCurrentIndex()`, `decrementCurrentIndex()`, `indexAt(x, y)`, `itemAtIndex(i)`.

Attached in delegates: `ListView.view`, `ListView.isCurrentItem`, `ListView.onAdd`, `ListView.onRemove`.

### A keyboard-driven list with highlight
```qml
ListView {
    id: list
    focus: true
    keyNavigationEnabled: true
    highlight: Rectangle { radius: 10; color: "#45475a" }
    highlightMoveDuration: 120
    Keys.onReturnPressed: console.log("chose", model[currentIndex])
    model: ["one", "two", "three"]
    delegate: Text { required property string modelData; text: modelData; color: "white"; padding: 10 }
}
```

### Animating additions and removals
```qml
ListView {
    add: Transition { NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 200 }
                      NumberAnimation { properties: "x"; from: 100; duration: 250; easing.type: Easing.OutCubic } }
    remove: Transition { NumberAnimation { properties: "opacity"; to: 0; duration: 150 } }
    displaced: Transition { NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutCubic } }
}
```

These transitions only work when the model reports *which* items changed (`ListModel`, Quickshell `ObjectModel`, [[ScriptModel]]). A plain JS array that you reassign replaces everything at once; [[ch:36-models]] shows how ScriptModel fixes that.

## GridView

Like ListView, but in a grid. Good for wallpaper pickers and app grids:

```qml
GridView {
    width: 600; height: 400; clip: true
    cellWidth: 150; cellHeight: 100
    model: wallpapers
    delegate: Image {
        required property string modelData
        width: 140; height: 90
        source: "file://" + modelData
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(280, 180)
        asynchronous: true
    }
}
```

## Flickable and ScrollView

To scroll arbitrary content (not a list), wrap it in a `Flickable`:

```qml
Flickable {
    width: 300; height: 400; clip: true
    contentWidth: column.width; contentHeight: column.height
    boundsBehavior: Flickable.StopAtBounds
    Column { id: column; width: 300 /* lots of content */ }
}
```

`ScrollView` (from Controls) is a Flickable with styled scrollbars.

## Never store state in delegates

Delegates are created and destroyed as you scroll or as the model changes. A `property bool expanded` inside a delegate is **lost** when it scrolls away. Store per-item state in the model, or in a JS object keyed by id in a parent or singleton.

## Practice

::: exercise warm | Workspaces 1–10
Show workspaces 1–10 with a `Repeater` and `model: 10`, highlighting number 3.
--- solution
```qml
Row { spacing: 4
    Repeater { model: 10
        Rectangle { required property int index
            width: 22; height: 22; radius: 11; color: index + 1 === 3 ? "#cba6f7" : "#313244"
            Text { anchors.centerIn: parent; text: parent.index + 1; color: "white" } } } }
```
:::

::: exercise practice | Todo list
Build a `ListModel` todo list with a button that appends entries, and animate additions.
--- solution
```qml
ListModel { id: todos }
Column {
    Rectangle { width: 80; height: 28; color: "#313244"
        TapHandler { onTapped: todos.append({ title: "Task " + (todos.count + 1) }) } }
    ListView { width: 200; height: 200; model: todos
        delegate: Text { required property string title; text: title; color: "white" }
        add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250 } } }
}
```
:::

::: exercise challenge | App list with keys
Show all installed apps (`DesktopEntries.applications`) in a `ListView` with arrow-key navigation and a highlight.
--- solution
```qml
ListView {
    width: 300; height: 400; focus: true; clip: true
    model: DesktopEntries.applications
    highlight: Rectangle { color: "#45475a"; radius: 6 }
    delegate: Text { required property DesktopEntry modelData; text: modelData.name; color: "white"; padding: 6 }
    Keys.onReturnPressed: model.values[currentIndex].execute()
}
```
The window needs keyboard focus (`WlrLayershell.keyboardFocus`) for arrow keys to arrive, see [[ch:21-input]].
:::
