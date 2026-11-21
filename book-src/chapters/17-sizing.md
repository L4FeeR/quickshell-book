# Sizing and Implicit Size

"Why is my component zero pixels wide?" "Why won't my layout stretch?" "Binding loop detected for width?" These questions all come from one concept: the difference between **implicit size** and **actual size**.

## Two sizes for every item

| | Meaning | Who sets it |
|---|---|---|
| `implicitWidth`, `implicitHeight` | The size the item **would like** to be, based on its content | The item itself (Text from its text, Image from its picture, your component from its children) |
| `width`, `height` | The size it **actually is** | Whoever places it: you, anchors, or a layout |

**By default, `width` follows `implicitWidth`.** Set `width` explicitly (or let anchors or a layout set it) and the implicit size is just a hint.

```qml
Text { text: "Hello" }                 // implicitWidth ≈ 36, width = 36 (follows)
Text { text: "Hello"; width: 200 }     // implicitWidth ≈ 36, width = 200 (overridden)
Rectangle { }                          // implicit 0×0, so invisible!
Item { }                               // implicit 0×0
```

## Which types have an implicit size?

| Type | Implicit size comes from |
|---|---|
| `Text` | the laid-out text |
| `Image` | the picture (or `sourceSize`) |
| `Row`, `Column`, `Grid`, `Flow` | their children plus spacing |
| `RowLayout`, `ColumnLayout` | children's preferred sizes plus spacing |
| Controls (`Button`, `Slider`…) | their content and style |
| `Rectangle`, `Item`, `MouseArea` | **nothing: 0×0 unless you set it** |
| Your components | whatever you set on the root's `implicitWidth`/`implicitHeight` |

## Rule 1: components size themselves with implicit size

When you write a component, set `implicitWidth`/`implicitHeight` on its root, computed from its content. **Don't set `width`/`height` on your own root.**

```qml file="Chip.qml"
import QtQuick

Rectangle {
    id: root
    property alias text: label.text

    implicitWidth: label.implicitWidth + 24     // content + padding
    implicitHeight: label.implicitHeight + 10
    radius: height / 2
    color: "#313244"

    Text { id: label; anchors.centerIn: parent; color: "white" }
}
```

Now a `Chip` is exactly as wide as its text plus padding, **and** users can still stretch it with `width:`, anchors or `Layout.fillWidth`. If you'd written `width: label.implicitWidth + 24` instead, a layout couldn't override it (or you'd get warnings), and the chip couldn't be stretched.

## Rule 2: users of a component set the actual size

```qml
Chip { text: "auto size" }                          // uses implicit size
Chip { text: "fixed"; width: 120 }                  // forced width
RowLayout { Chip { text: "fills"; Layout.fillWidth: true } }   // layout decides
```

## Rule 3: Quickshell windows use implicit size

For [[PanelWindow]], [[FloatingWindow]] and [[PopupWindow]], set **`implicitWidth`/`implicitHeight`**. (The window's `width`/`height` exist too, but implicit size is the recommended way to request a size.) An anchored edge overrides the matching dimension: a bar anchored left and right gets the screen width automatically, so you only set `implicitHeight`.

```qml
PanelWindow {
    anchors { top: true; left: true; right: true }
    implicitHeight: 36                   // width comes from the anchors
}
PanelWindow {                            // unanchored popup: set both
    implicitWidth: 400
    implicitHeight: content.implicitHeight + 32   // grows with content
}
```

## Sizing a window to its content

A common pattern for popups and notifications:

```qml
PanelWindow {
    implicitWidth: 360
    implicitHeight: Math.max(1, column.implicitHeight + 24)   // never 0 (an invalid surface)
    Column { id: column; x: 12; y: 12; width: parent.width - 24; spacing: 8 /* … */ }
}
```

## Binding loops and how to avoid them

```text
QML Item: Binding loop detected for property "implicitWidth"
```

This happens when a size depends on itself through a cycle, e.g. a parent's implicit width comes from a child whose width comes from the parent:

```qml
Rectangle {
    implicitWidth: inner.width + 20       // parent ← child
    Text { id: inner; width: parent.width - 20 }   // child ← parent ✗ loop
}
```

Fix: **build implicit sizes from the content's implicit sizes**, and make actual sizes flow from parent to child:

```qml
Rectangle {
    implicitWidth: inner.implicitWidth + 20        // from the text's natural size ✓
    Text { id: inner; anchors.centerIn: parent }   // positioned, not sized from parent
}
```

The mental model: **implicit sizes flow up** (children tell parents what they'd like), **actual sizes flow down** (parents tell children what they get). Never mix directions on the same axis.

## childrenRect

`childrenRect` is the bounding box of an item's children. It's a quick way to size a plain `Item` around absolutely positioned children: `implicitWidth: childrenRect.width`. Prefer positioners or layouts when you can, because `childrenRect` makes loops easy.

## Pixel snapping and HiDPI

- Quickshell windows report `devicePixelRatio` (e.g. `1.5` at 150% scale). Qt scales automatically; you write sizes in **logical pixels**.
- Odd sizes at fractional scaling can blur 1 px lines. Keep borders and dividers at whole logical pixels and consider `border.pixelAligned: true`.
- For images and SVGs, set `sourceSize` to *display size × devicePixelRatio* for crispness.

> [!TRY] Exercises
> 1. Build `Chip.qml` and put three chips with different text lengths in a `Row`. They should all size themselves.
> 2. Put one chip in a `RowLayout` with `Layout.fillWidth: true` and confirm it stretches.
> 3. Create a binding loop on purpose, read the warning, then fix it using implicit sizes.
