# Components, Files and Imports

A rice is made of dozens of reusable pieces: buttons, pills, icons, cards, sliders. In QML, **every file is a reusable type**. This chapter teaches you to build your own components with clean APIs, the way big shells do.

## One file = one type

Create a file whose name starts with a **capital letter**:

```qml file="~/.config/quickshell/playground/Pill.qml"
import QtQuick

Rectangle {
    implicitWidth: 80
    implicitHeight: 26
    radius: height / 2
    color: "#cba6f7"
}
```

Now `Pill` is a type that any other file **in the same folder** can use:

```qml file="~/.config/quickshell/playground/shell.qml"
import Quickshell
import QtQuick

PanelWindow {
    anchors { top: true; left: true; right: true }
    implicitHeight: 40
    Row {
        anchors.centerIn: parent
        spacing: 8
        Pill {}
        Pill {}
        Pill { color: "#a6e3a1" }       // override a property of the root object
    }
}
```

The type name is the filename without `.qml`. The file's root object (here a `Rectangle`) is what you get, so users can set any `Rectangle` property on a `Pill`.

## Giving your component an API

A good component exposes a few **properties** (inputs) and **signals** (outputs) and hides everything else:

```qml file="Pill.qml"
import QtQuick

Rectangle {
    id: root

    // ---- public API ----
    property string text: ""
    property string icon: ""
    property color accent: "#cba6f7"
    property bool active: false
    signal clicked()
    signal rightClicked()

    // ---- implementation ----
    implicitWidth: row.implicitWidth + 20
    implicitHeight: 28
    radius: height / 2
    color: active ? accent : mouse.containsMouse ? "#45475a" : "#313244"
    Behavior on color { ColorAnimation { duration: 150 } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Text {
            visible: root.icon !== ""
            text: root.icon
            font.family: "Material Symbols Rounded"
            font.pixelSize: 16
            color: root.active ? "#1e1e2e" : "#cdd6f4"
        }
        Text {
            text: root.text
            color: root.active ? "#1e1e2e" : "#cdd6f4"
            font.pixelSize: 13
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => m.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }
}
```

```qml
Pill { icon: "wifi"; text: "Home-5G"; active: true }
Pill { icon: "bluetooth"; text: "Off"; onClicked: console.log("toggle bt") }
```

## property alias: exposing an inner property

An **alias** makes an inner object's property available as if it were the component's own:

```qml file="Label.qml"
import QtQuick

Rectangle {
    property alias text: inner.text          // Label.text IS inner.text
    property alias textColor: inner.color
    property alias font: inner.font          // expose the whole font group

    implicitWidth: inner.implicitWidth + 16
    implicitHeight: inner.implicitHeight + 8
    radius: 6
    color: "#313244"
    Text { id: inner; anchors.centerIn: parent; color: "white" }
}
```

```qml
Label { text: "hello"; font.bold: true; textColor: "#f9e2af" }
```

Aliases are two-way: setting `Label.text` sets `inner.text` and vice versa.

## required properties

Mark a property `required` when the component can't work without it. Forgetting it becomes an error instead of a silent bug:

```qml file="WorkspaceDot.qml"
import QtQuick

Rectangle {
    required property int workspaceId
    required property bool active
    width: active ? 24 : 8; height: 8; radius: 4
    color: active ? "#cba6f7" : "#585b70"
}
```

```qml
WorkspaceDot { workspaceId: 3; active: true }   // OK
WorkspaceDot { }                                // ERROR: Required property workspaceId was not initialized
```

`required` is also how delegates receive their data in Repeaters and ListViews ([[ch:20-models-views]]).

## default property: components that take children

To let users put children *inside* your component and have them land in the right place, use a default property:

```qml file="Card.qml"
import QtQuick

Rectangle {
    default property alias content: column.data   // children go into the column
    property string title: ""

    implicitWidth: 260
    implicitHeight: column.implicitHeight + 24
    radius: 14
    color: "#1e1e2e"
    border.color: "#313244"

    Column {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 6
        Text { text: title; color: "#cba6f7"; font.bold: true; visible: title !== "" }
    }
}
```

```qml
Card {
    title: "System"
    Text { text: "CPU 12%"; color: "white" }      // these go into Card's column
    Text { text: "RAM 41%"; color: "white" }
}
```

## Inline components

For a small type used only inside one file, declare it inline with `component`:

```qml
Item {
    component Badge: Rectangle {
        property string label
        width: 22; height: 22; radius: 11
        color: "#f38ba8"
        Text { anchors.centerIn: parent; text: parent.label; color: "white"; font.pixelSize: 11 }
    }

    Row {
        spacing: 4
        Badge { label: "3" }
        Badge { label: "9+" }
    }
}
```

## Imports: using components from other folders

Files in the **same folder** see each other automatically. For other folders:

```qml
import "widgets"              // relative path: every Capitalized.qml in ./widgets
import "../common"            // up one level
import "widgets" as W         // namespaced: write W.Pill { }
```

### The `qs` import root (recommended)

Quickshell defines a module called **`qs`** that points at **your config's root folder**. Use it to import any folder with an absolute-style path that works from any depth:

```text
~/.config/quickshell/myshell/
├── shell.qml
├── services/Audio.qml
├── widgets/Pill.qml
└── modules/bar/Bar.qml
```

```qml file="modules/bar/Bar.qml"
import qs.widgets          // → myshell/widgets/   (Pill)
import qs.services         // → myshell/services/  (Audio)
```

No `../../` chains, and moving a file doesn't break its imports. This is what modern rices use.

> [!WARN] Folder names must be valid identifiers for `qs.` imports
> `qs.modules.bar` works. A folder called `my-widgets` can't be written as `qs.my-widgets`, so use `myWidgets` or `my_widgets`. Relative string imports (`import "my-widgets"`) have no such restriction.

## How the root object type affects your component

Your component **is** its root object, plus whatever you added:

- Root `Item`: an invisible container with your API, the most flexible.
- Root `Rectangle`: users can set `color`, `radius` and so on.
- Root `MouseArea`: the whole component is clickable.
- Root `PanelWindow`: your component is a window (e.g. `Bar.qml`).
- Root `Scope`: a non-visual group that can contain several windows ([[ch:29-shell-structure]]).

Choose the root carefully, because it's part of your public API: if `Pill`'s root is a `Rectangle`, someone can override `color` and break your styling. Wrap it in an `Item` root if you want to hide that.

## Designing good components

1. **Size yourself from your content** with `implicitWidth`/`implicitHeight` ([[ch:17-sizing]]); never hard-code `width`/`height` on your root.
2. **Expose state, not internals.** `property bool active` beats `property color backgroundColor`.
3. **Signals for events.** Let the user decide what a click does.
4. **Read colors and sizes from a theme singleton** ([[ch:43-design-system]]) instead of hard-coding them.
5. **One responsibility per file.** If a file passes ~200 lines, split it.

> [!TRY] Exercises
> 1. Build `IconButton.qml` with properties `icon` (Material Symbols name), `size`, `toggled`, and signals `clicked`/`rightClicked`. Use it three times in your bar.
> 2. Build `Card.qml` with a default property and put two `Pill`s inside a card.
> 3. Move your components into `widgets/` and import them with `import qs.widgets` (create `.qmlls.ini` and restart `qs` so your editor understands it).
