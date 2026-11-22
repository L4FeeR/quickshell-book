# Anchors

Anchors glue an item's edges to other items' edges. They're the most common way to position things in QML, and they automatically follow when sizes change.

## Anchor lines

Every item has seven invisible **anchor lines**:

<div class="diagram"><svg viewBox="0 0 520 240" role="img" aria-label="anchor lines">
<rect class="a" x="120" y="50" width="280" height="140" rx="6"/>
<path class="ln" d="M120 30 V210 M400 30 V210 M260 30 V210 M100 50 H420 M100 190 H420 M100 120 H420"/>
<text x="92" y="24">left</text><text x="384" y="24">right</text><text x="216" y="24">horizontalCenter</text>
<text x="428" y="54">top</text><text x="428" y="194">bottom</text><text x="428" y="124">verticalCenter</text>
<text class="sm" x="130" y="160">(baseline: the line text sits on)</text>
</svg></div>

You attach your lines to another item's lines (your **parent** or a **sibling**):

```qml
Rectangle {
    id: bar
    width: 600; height: 40; color: "#1e1e2e"

    Text {
        id: title
        anchors.left: parent.left          // my left edge = parent's left edge
        anchors.leftMargin: 12             // …plus 12 px
        anchors.verticalCenter: parent.verticalCenter
        text: "left"; color: "white"
    }
    Text {
        anchors.centerIn: parent           // shortcut: both centers
        text: "center"; color: "white"
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: "right"; color: "white"
    }
    Rectangle {                             // a divider right after the title
        anchors.left: title.right
        anchors.leftMargin: 8
        anchors.top: parent.top; anchors.bottom: parent.bottom
        anchors.margins: 10                 // applies to every anchored side
        width: 1; color: "#45475a"
    }
}
```

## All anchor properties

| Property | Meaning |
|---|---|
| `anchors.left` / `right` / `top` / `bottom` | Attach an edge |
| `anchors.horizontalCenter` / `verticalCenter` | Attach a center line |
| `anchors.baseline` | Attach text baselines (align texts of different sizes) |
| `anchors.fill: item` | All four edges = fill that item |
| `anchors.centerIn: item` | Both centers = center inside that item |
| `anchors.margins` | Margin for all anchored edges |
| `anchors.leftMargin` / `rightMargin` / `topMargin` / `bottomMargin` | Per-edge margin |
| `anchors.horizontalCenterOffset` / `verticalCenterOffset` | Shift a centered item |
| `anchors.baselineOffset` | Shift the baseline |
| `anchors.alignWhenCentered` | Snap centered items to whole pixels (default true) |

## Stretching with two anchors

Anchor opposite edges and the item **stretches** between them, so you don't set that dimension:

```qml
Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right          // width now comes from the anchors
    anchors.top: parent.top
    height: 40                           // only the height is set by hand
}
```

```qml
Text {
    anchors.left: icon.right; anchors.leftMargin: 8
    anchors.right: parent.right; anchors.rightMargin: 8   // a bounded width
    elide: Text.ElideRight                                // so elide works
}
```

## Rules

1. You can anchor only to your **parent** or **siblings** (items with the same parent).
2. Don't combine anchors with explicit `x`/`y` or `width`/`height` on the **same axis**. Anchors win and QML prints warnings.
3. Don't anchor items managed by `Row`/`Column`/layouts on the axis the layout controls. Use `Layout.*` properties instead.
4. Anchors are bindings: when the target moves or resizes, you follow.

## Changing anchors at runtime

Anchors can be bound to conditions:

```qml
Rectangle {
    property bool bottomBar: false
    anchors.top: bottomBar ? undefined : parent.top       // undefined = remove the anchor
    anchors.bottom: bottomBar ? parent.bottom : undefined
}
```

For animated anchor changes use `AnchorChanges` inside states plus an `AnchorAnimation` ([[ch:24-animation-advanced]]).

## The truly centered clock

A classic bar problem: in a row of left, center and right modules, the center module isn't centered on screen when the left and right sides have different widths. Anchors solve it:

```qml
PanelWindow {
    anchors { top: true; left: true; right: true }
    implicitHeight: 36

    Row { anchors.left: parent.left;  anchors.leftMargin: 8;  anchors.verticalCenter: parent.verticalCenter; spacing: 8 /* workspaces… */ }
    Text { anchors.centerIn: parent; text: "12:34" }        // always the exact center of the bar
    Row { anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; spacing: 8 /* tray… */ }
}
```

## Quickshell window "anchors" are different

[[PanelWindow]] has its own `anchors` group with **boolean** members (`top`, `bottom`, `left`, `right`) that attach the *window* to *screen edges*. Same word, different thing:

```qml
PanelWindow {
    anchors.top: true            // window: glue to the top screen edge (a bool)
    Text {
        anchors.top: parent.top  // item: glue to the parent's top line (an anchor line)
    }
}
```

## Practice

::: exercise warm | Three groups
Build a bar with left, center and right groups using only anchors.
--- solution
```qml
Row { anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }; Text { text: "left"; color: "white" } }
Row { anchors.centerIn: parent; Text { text: "center"; color: "white" } }
Row { anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }; Text { text: "right"; color: "white" } }
```
:::

::: exercise practice | Notification card
Make a card: icon on the left, title and body to its right, both eliding at the card's right edge.
--- solution
```qml
Rectangle { width: 320; height: 70; radius: 12; color: "#1e1e2e"
    Rectangle { id: icon; width: 40; height: 40; radius: 20; color: "#89b4fa"
        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter } }
    Text { id: title; text: "A long title that will not fit"; color: "white"; font.bold: true; elide: Text.ElideRight
        anchors { left: icon.right; leftMargin: 10; right: parent.right; rightMargin: 12; top: icon.top } }
    Text { text: "The body text also elides at the right edge of the card"; color: "#a6adc8"; elide: Text.ElideRight
        anchors { left: title.left; right: title.right; top: title.bottom; topMargin: 2 } }
}
```
:::

::: exercise challenge | Conditional anchors
Add `property bool flipped` that moves a small badge between the top-right and bottom-left corners of a rectangle.
--- hint
Assign `undefined` to the anchor you want to release.
--- solution
```qml
Rectangle { width: 10; height: 10; radius: 5; color: "red"
    anchors.top: flipped ? undefined : parent.top
    anchors.right: flipped ? undefined : parent.right
    anchors.bottom: flipped ? parent.bottom : undefined
    anchors.left: flipped ? parent.left : undefined }
```
:::
