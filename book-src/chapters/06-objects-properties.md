# Objects and Properties

Everything in QML is built from two ideas: **objects** and **properties**. Master these and the rest of the language is detail.

## Objects

An **object** is a thing: a rectangle, a piece of text, a window, a timer, a battery. You create one by writing its **type name** followed by curly braces:

```qml
Rectangle {
}
```

That's a complete, valid object: a `Rectangle` with all default settings (which happen to make it invisible: zero size, white).

Rules for type names:

- They start with a **capital letter**: `Rectangle`, `Text`, `PanelWindow`.
- They come from **imports** (`import QtQuick` gives you `Rectangle`) or from **your own files** (`Pill.qml` gives you `Pill`).

## Properties

A **property** is a named setting of an object. Inside the braces you write `name: value`:

```qml
Rectangle {
    width: 120
    height: 40
    color: "orange"
    radius: 8
}
```

Now the rectangle is 120×40 pixels, orange, with rounded corners. Each line is a **property assignment**: the property name, a colon, then a value.

- Property names start with a **lowercase letter**: `width`, `color`, `implicitHeight`.
- Order doesn't matter. QML isn't a list of steps.
- One property per line. To put several on one line, separate them with `;`:

```qml
Rectangle { width: 120; height: 40; color: "orange" }
```

## Every object has a type, and every type has a fixed set of properties

You can only set properties the type actually has. `Rectangle` has `color`, `radius`, `border`, plus everything from `Item` (`width`, `height`, `x`, `y`, `opacity`…). `Text` has `text`, `font`, `color`, `wrapMode`…

```qml
Rectangle {
    text: "hi"      // ERROR: Rectangle has no property "text"
}
```

```text
Cannot assign to non-existent property "text"
```

How do you know which properties a type has? That's what the **reference** is for: the [[ch:q1-qt-visual|Qt reference chapters]] for Qt types, and the [[ref:PanelWindow|API reference]] for Quickshell types. Every property is listed there with its type and meaning.

## Nesting: children

Put an object inside another object's braces and it becomes a **child**:

```qml
Rectangle {                 // parent
    width: 200; height: 100
    color: "#1e1e2e"

    Text {                  // child of the Rectangle
        text: "inside"
        color: "white"
    }

    Rectangle {             // another child
        x: 150; y: 60
        width: 40; height: 30
        color: "tomato"
    }
}
```

Children are:

- **positioned relative to their parent.** `x: 150` means 150 px from the parent's left edge, not the screen's.
- **drawn on top of their parent**, and later children on top of earlier ones.
- **moved, hidden and faded with their parent.** Set the parent's `opacity: 0.5` and the children fade too.

The whole file is a **tree** of objects. The top object is the **root**, and a file can have only one.

<div class="diagram"><svg viewBox="0 0 720 200" role="img" aria-label="object tree">
<rect class="a" x="270" y="10" width="180" height="40" rx="8"/><text x="290" y="35">PanelWindow (root)</text>
<rect class="n" x="270" y="80" width="180" height="40" rx="8"/><text x="300" y="105">Rectangle</text>
<rect class="n" x="60" y="150" width="160" height="40" rx="8"/><text x="105" y="175">Text</text>
<rect class="n" x="280" y="150" width="160" height="40" rx="8"/><text x="320" y="175">Row</text>
<rect class="n" x="500" y="150" width="160" height="40" rx="8"/><text x="545" y="175">Timer</text>
<path class="ln" d="M360 50 V80 M360 120 V135 H140 V150 M360 135 V150 M360 135 H580 V150"/>
</svg></div>

## Declaring your own properties

You can add new properties to any object with the `property` keyword:

```qml
Rectangle {
    property int volume: 40            // type, name, default value
    property string label: "Volume"
    property bool muted: false

    width: 200; height: 24
    color: muted ? "grey" : "steelblue"
}
```

Syntax: `property <type> <name>: <initial value>`. The initial value is optional (`property int volume` defaults to `0`).

Why declare properties? To store **state** ("is the menu open?") and to create an **API** for your own components, which you'll do in [[ch:12-components]]. A property you declare behaves exactly like built-in ones: you can bind to it, react when it changes, and set it from outside.

### Property modifiers

| Modifier | Meaning | Example |
|---|---|---|
| `readonly` | Can't be assigned after creation; usually a computed value | `readonly property bool loud: volume > 80` |
| `required` | Whoever creates this object **must** set it | `required property string title` |
| `default` | Children written inside this object go into this property | `default property alias content: box.data` |
| `alias` | A second name for another object's property | `property alias text: label.text` |

You'll meet each of these in later chapters. For now, `property TYPE name: value` is enough.

## Comments

```qml
// a line comment: ignored by QML
/* a block comment,
   can span lines */
Rectangle { width: 10 /* inline */ }
```

Comment generously while learning. Future you will thank you.

## Imports

The first lines of every file say which **modules** to load:

```qml
import QtQuick                 // Item, Rectangle, Text, Image, MouseArea, animations…
import QtQuick.Layouts         // RowLayout, ColumnLayout, GridLayout
import QtQuick.Controls        // Button, Slider, Switch, TextField…
import Quickshell              // PanelWindow, Variants, Scope, SystemClock…
import Quickshell.Io           // Process, FileView, IpcHandler…
import Quickshell.Services.UPower   // UPower, UPowerDevice…
```

Forget an import and you get `X is not a type`. In Qt 6 you don't write version numbers (old tutorials show `import QtQuick 2.15`; that still works but isn't needed).

## Putting it together

```qml file="~/.config/quickshell/playground/shell.qml"
import Quickshell
import QtQuick

PanelWindow {
    anchors { top: true; left: true; right: true }
    implicitHeight: 40
    color: "#11111b"

    // our own state
    property int level: 65
    property string name: "Volume"

    Rectangle {                          // the track
        x: 12; y: 14
        width: 200; height: 12
        radius: 6
        color: "#313244"

        Rectangle {                      // the filled part, child of the track
            width: parent.width * level / 100
            height: parent.height
            radius: 6
            color: "#cba6f7"
        }
    }

    Text {
        x: 224; y: 11
        text: name + ": " + level + "%"
        color: "#cdd6f4"
    }
}
```

Change `level` to `20` and save. The bar shrinks and the label updates. You changed one number and two things on screen followed it. That's the next big idea, **bindings**, which [[ch:09-bindings]] explains properly.

> [!TRY] Exercises
> 1. Add `property color accent: "#a6e3a1"` to the window and use it for the filled bar's color.
> 2. Add a third rectangle as a "knob" at the end of the filled part (hint: `x: parent.width * level / 100 - 6`).
> 3. Try to set a property that doesn't exist and read the error.
