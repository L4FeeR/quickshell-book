# Bindings: The Heart of QML

If you understand this chapter, you understand QML. A **binding** is a property whose value is an **expression** that QML keeps up to date automatically.

## The idea

```qml
Rectangle {
    id: root
    property int volume: 40

    width: 200
    height: 20
    color: volume > 80 ? "red" : "grey"     // ← binding

    Rectangle {
        width: parent.width * root.volume / 100   // ← binding
        height: parent.height
        color: "white"
    }
}
```

`color: volume > 80 ? "red" : "grey"` isn't run once. QML:

1. evaluates the expression,
2. **records every property it read** (here: `volume`),
3. re-evaluates it **whenever any of those properties change**.

So if anything sets `volume = 90` (a click, a timer, the audio service), the color turns red and the inner bar grows, with **no update code anywhere**. That's why a full desktop bar in QML can have almost no "logic".

<div class="diagram"><svg viewBox="0 0 760 170" role="img" aria-label="binding dependency graph">
<rect class="g" x="20" y="60" width="170" height="44" rx="10"/><text x="40" y="87">volume (40 → 90)</text>
<rect class="a" x="300" y="14" width="200" height="44" rx="10"/><text x="315" y="41">color: volume &gt; 80 ? …</text>
<rect class="a" x="300" y="108" width="200" height="44" rx="10"/><text x="315" y="135">width: … * volume / 100</text>
<rect class="n" x="580" y="14" width="160" height="44" rx="10"/><text x="605" y="41">turns red</text>
<rect class="n" x="580" y="108" width="160" height="44" rx="10"/><text x="605" y="135">bar grows</text>
<path class="ln" d="M190 82 L300 36 M190 82 L300 130 M500 36 H580 M500 130 H580"/>
</svg></div>

## What can go in a binding

Any JavaScript **expression**:

```qml
text: "Battery: " + Math.round(bat.percentage * 100) + "%"
visible: players.length > 0 && !GlobalStates.dnd
opacity: hovered ? 1.0 : 0.6
width: Math.max(label.implicitWidth + 20, 60)
color: Colors.primary
```

For more complex logic, use a **block**. The last `return` gives the value:

```qml
text: {
    const p = Math.round(bat.percentage * 100)
    if (bat.state === UPowerDeviceState.Charging) return "⚡ " + p + "%"
    if (p < 15) return "‼ " + p + "%"
    return p + "%"
}
```

Or call a **function**. QML tracks the properties the function reads, too:

```qml
function label(): string {
    return players.length ? players[0].trackTitle : "Idle"
}
text: label()      // re-evaluates when players or trackTitle change
```

## Bindings vs assignments

There are two ways to give a property a value:

| | Syntax | Where | Effect |
|---|---|---|---|
| **Binding** | `width: parent.width / 2` | in the object body | stays up to date forever |
| **Assignment** | `width = 50` | inside JavaScript (handlers, functions) | sets a fixed value **and removes any binding** |

```qml
Rectangle {
    id: box
    width: parent.width / 2               // binding

    MouseArea {
        anchors.fill: parent
        onClicked: box.width = 50          // ⚠ binding destroyed: box.width is now
                                           //   always 50, even if the parent resizes
    }
}
```

This is the most common "it stopped updating!" bug. Think of it like this: **bindings describe what something *is*; assignments are for *events*.**

### Restoring a binding from JavaScript

```qml
onClicked: box.width = Qt.binding(() => parent.width / 4)   // a NEW binding
```

### The better pattern: bind to state, change the state

Instead of assigning to visual properties, keep a small piece of **state** and bind visuals to it:

```qml
Rectangle {
    id: box
    property bool expanded: false            // state
    width: expanded ? 300 : 120              // visual, bound to state
    height: expanded ? 200 : 40
    color: expanded ? "#cba6f7" : "#45475a"

    MouseArea { anchors.fill: parent; onClicked: box.expanded = !box.expanded }  // only touch state
}
```

You assign only to `expanded`, a property no binding depends on for its *own* value, and everything visual stays a binding. This scales to entire shells: one `GlobalStates.launcherOpen` boolean drives the launcher window, the bar button highlight and the blur, all through bindings.

## Binding loops

If a property depends on itself, directly or in a circle, QML stops and warns:

```qml
Rectangle {
    width: height
    height: width + 1      // width → height → width …
}
```

```text
QML Rectangle: Binding loop detected for property "width"
```

The fix is always to break the circle: one of the values must come from somewhere else (a constant, the parent, the content). Layout code is the usual culprit: a parent's size depends on its child and the child's size depends on the parent. [[ch:17-sizing]] shows how to avoid this.

## Performance notes

- Bindings are cheap. A bar with hundreds is fine.
- An expensive binding (sorting 500 apps) re-runs every time **any** input changes. Compute it once into a `readonly property` and reuse it.
- Don't read a frequently changing property (like a playback position updated every frame) in a binding that does heavy work.

## The Binding object (conditional bindings)

Sometimes you want a binding only while a condition holds:

```qml
Binding {
    target: osd
    property: "visible"
    value: true
    when: Audio.volumeChangedRecently       // while true, osd.visible = true; afterwards the old value returns
}
```

You'll rarely need this, but it's useful for "override while hovering" or "force while locked" situations.

## A complete example: everything flows from one value

```qml file="~/.config/quickshell/playground/shell.qml"
import Quickshell
import QtQuick

PanelWindow {
    id: win
    anchors { top: true; left: true; right: true }
    implicitHeight: 44
    color: "#11111b"

    property real level: 0.3                       // the ONLY state

    Rectangle {
        id: track
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        width: 260; height: 14; radius: 7
        color: "#313244"

        Rectangle {
            width: track.width * win.level
            height: parent.height; radius: 7
            color: win.level > 0.8 ? "#f38ba8" : win.level > 0.5 ? "#f9e2af" : "#a6e3a1"
            Behavior on width { NumberAnimation { duration: 200 } }   // animate changes (Ch. 23)
        }
    }
    Text {
        anchors { left: track.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
        text: Math.round(win.level * 100) + "%" + (win.level > 0.8 ? "  LOUD" : "")
        color: "#cdd6f4"
        font.bold: win.level > 0.8
    }
    MouseArea {                                     // scroll anywhere to change level
        anchors.fill: parent
        onWheel: w => win.level = Math.max(0, Math.min(1, win.level + (w.angleDelta.y > 0 ? 0.05 : -0.05)))
    }
}
```

Scroll on the bar: the fill, its color, the label and the bold text all follow `level`. That one assignment in `onWheel` is the only imperative line in the file.

> [!TRY] Exercises
> 1. In the example, add a second bar below that shows `1 - level`.
> 2. Break a binding on purpose: add a button that assigns the fill's `width = 30`, then scroll. Fix it with `Qt.binding`.
> 3. Rewrite it so a click toggles a `property bool muted`, and when muted the fill is grey and the label says "muted", without assigning to any visual property.
