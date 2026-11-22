# ids, parent and Scope

Objects need to refer to each other: "make this text the same width as that box", "when this button is clicked, open that popup". QML gives you three ways to name things: **ids**, **parent** and **scope lookup**.

## ids

An `id` is a name you give an object so other objects in the **same file** can refer to it:

```qml
Rectangle {
    id: root
    width: 300; height: 60
    color: "#1e1e2e"

    Rectangle {
        id: knob
        width: root.height            // use another object's property
        height: root.height
        radius: height / 2
        color: "#cba6f7"
    }

    Text {
        anchors.left: knob.right      // position relative to knob
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: "knob is " + knob.width + "px wide"
        color: "white"
    }
}
```

Rules:

- `id` isn't a normal property: no quotes, no type, can't be changed later.
- Must start with a **lowercase** letter or underscore: `root`, `clockText`, `_internal`.
- Must be **unique within the file**.
- Is visible **everywhere in that file**, at any depth, in any direction (a child can name its parent's sibling).
- Is **invisible outside the file**. Another file can't see `knob`; you pass things between files with properties (next chapters).

> [!TIP] Name the root `root`
> By convention every file's root object gets `id: root`. Then anywhere in the file, `root.someProperty` clearly means "the top object of this file".

## parent

`parent` always refers to an item's **visual parent**, the object it's nested inside:

```qml
Rectangle {
    width: 200; height: 50
    Rectangle {
        width: parent.width / 2     // half of the outer rectangle
        height: parent.height
    }
}
```

`parent` is convenient for "fill my container" code (`anchors.fill: parent`), but it changes meaning if you move the object somewhere else. When you mean a specific object, use its id.

## this

Inside a JavaScript function or signal handler, `this` is the object the code belongs to. You rarely need it, since ids are clearer, but you'll see it in upstream docs, e.g. inside a [[StdioCollector]]: `onStreamFinished: console.log(this.text)`.

## How bare names are found (scope lookup)

When you write a name without `id.` in front, like `height` or `volume`, QML searches in this order:

1. **JavaScript locals**: function parameters, `let`/`const` variables.
2. **The current object's properties**.
3. **ids** in the file.
4. **The root object's properties** (properties of the file's top object).
5. **The surrounding context**: things like `index` and `modelData` provided by a Repeater or ListView delegate.
6. **Singletons and global names**: `Quickshell`, `Hyprland`, `Qt`, `Math`, `console`.

```qml
Rectangle {
    id: root
    property int volume: 50       // root property

    Rectangle {
        property int volume: 10   // shadows the root's volume!
        width: volume             // → 10  (current object wins)
        height: root.volume       // → 50  (explicit)
    }
}
```

> [!WARN] Be explicit
> Unqualified names that reach *outward* (to the root or to delegate context) are a common source of confusing bugs and are slower for the engine. Prefer `root.volume` over `volume` when you mean the root's property, and declare delegate data with `required property` ([[ch:20-models-views]]).

## Talking between files: properties in, signals out

Since ids don't cross files, components communicate through their **public properties** and **signals**:

```qml file="Counter.qml"
import QtQuick

Rectangle {
    id: root
    property int value: 0          // input/state, visible to the user of Counter
    signal clicked()               // output: tells the outside something happened

    width: 60; height: 30; radius: 6
    color: "#45475a"
    Text { anchors.centerIn: parent; text: root.value; color: "white" }
    MouseArea { anchors.fill: parent; onClicked: root.clicked() }
}
```

```qml file="shell.qml"
import Quickshell
import QtQuick

PanelWindow {
    anchors { top: true; left: true; right: true }
    implicitHeight: 40

    Counter {
        id: counter
        anchors.centerIn: parent
        onClicked: counter.value++       // the user of the component decides what a click does
    }
}
```

This "data down, events up" pattern keeps components reusable. You'll formalize it in [[ch:12-components]].

## Global state: singletons

For things *many* files need (volume, theme colors, "is the launcher open"), passing properties through every level gets tedious. QML has **singletons**: one global object accessible by name from any file. Quickshell provides many (`Quickshell`, `Hyprland`, `UPower`, `Pipewire`…) and you'll write your own in [[ch:33-singletons]].

```qml
Text { text: Hyprland.focusedWorkspace?.name ?? "" }   // Hyprland is a singleton: no id needed
```

## Practice

::: exercise warm | Doubling widths
Make three rectangles in a `Row` where each one's width is twice the previous one's, using ids.
--- solution
```qml
Row {
    spacing: 4
    Rectangle { id: a; width: 20; height: 20; color: "#f38ba8" }
    Rectangle { id: b; width: a.width * 2; height: 20; color: "#fab387" }
    Rectangle { width: b.width * 2; height: 20; color: "#a6e3a1" }
}
```
:::

::: exercise practice | Shadowing
Reproduce the shadowing example from this chapter and print both values with `console.log` in `Component.onCompleted`.
--- hint
Use `root.name` to reach the outer property when an inner object has a property with the same name.
:::

::: exercise challenge | Linked counters
Build `Counter.qml` (a number + click to increment) and use two counters in `shell.qml`: clicking the first also increments the second.
--- hint
Give both instances ids in `shell.qml`; add a `signal clicked()` to `Counter.qml`.
--- solution
```qml
// Counter.qml
import QtQuick
Rectangle {
    property int count: 0
    signal clicked()
    width: 60; height: 30; radius: 6; color: "#313244"
    Text { anchors.centerIn: parent; text: parent.count; color: "white" }
    MouseArea { anchors.fill: parent; onClicked: { parent.count++; parent.clicked() } }
}
```
```qml
// in shell.qml
Row {
    Counter { id: first; onClicked: second.count++ }
    Counter { id: second }
}
```
:::
