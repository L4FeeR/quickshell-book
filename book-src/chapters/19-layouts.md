# Positioners and Layouts

Anchors are great for a few items. For rows of modules, grids of toggles and lists of buttons, use **positioners** (simple stacking) or **layouts** (stacking plus stretching).

## Positioners: Row, Column, Grid, Flow

Positioners place children one after another using each child's own size. They're simple and cheap.

```qml
Row {
    spacing: 8                       // gap between children
    padding: 4                       // space around all children
    Rectangle { width: 30; height: 30; color: "#f38ba8" }
    Rectangle { width: 50; height: 30; color: "#a6e3a1" }
    Rectangle { width: 20; height: 30; color: "#89b4fa" }
}

Column { spacing: 4 /* stacked top to bottom */ }

Grid {
    columns: 3                       // or rows: 2
    spacing: 6
    // fills row by row: items 1 2 3 / 4 5 6
}

Flow {
    width: 200                       // wraps like text when a row is full
    spacing: 4
}
```

| Positioner property | Meaning |
|---|---|
| `spacing` | Gap between items |
| `padding`, `leftPadding`… | Inner padding |
| `layoutDirection` | `Qt.LeftToRight` or `Qt.RightToLeft` (Row, Grid, Flow) |
| `columns`, `rows`, `flow` | Grid shape and fill order |
| `horizontalItemAlignment`, `verticalItemAlignment` | Grid alignment |
| `add`, `move`, `populate` | Transitions when children appear or move ([[ch:24-animation-advanced]]) |

Rules:

- Children must have a size (implicit or explicit).
- Don't set `x` (in a Row) or `y` (in a Column) on children: the positioner controls them.
- To vertically center children of a `Row`, give each child `anchors.verticalCenter: parent.verticalCenter`.
- Invisible children (`visible: false`) take **no space**, which is perfect for optional modules.

## Layouts: RowLayout, ColumnLayout, GridLayout

`import QtQuick.Layouts`. Layouts do what positioners do **plus** stretching, alignment and min/max sizes, controlled by attached `Layout.*` properties on each child.

```qml
import QtQuick
import QtQuick.Layouts

RowLayout {
    anchors.fill: parent
    anchors.margins: 6
    spacing: 8

    Rectangle { Layout.preferredWidth: 32; Layout.fillHeight: true; color: "#cba6f7" }   // fixed width
    Rectangle { Layout.fillWidth: true;    Layout.fillHeight: true; color: "#313244" }   // takes the rest
    Rectangle { Layout.preferredWidth: 80; Layout.preferredHeight: 20; color: "#a6e3a1"
                Layout.alignment: Qt.AlignVCenter }                                     // centered vertically
}
```

### All Layout attached properties

| Property | Meaning |
|---|---|
| `Layout.fillWidth` / `fillHeight` | Grow to take available space |
| `Layout.preferredWidth` / `preferredHeight` | Desired size (default: implicit size) |
| `Layout.minimumWidth` / `minimumHeight` | Never smaller than this |
| `Layout.maximumWidth` / `maximumHeight` | Never larger than this (great with elided text) |
| `Layout.alignment` | `Qt.AlignLeft`, `AlignRight`, `AlignHCenter`, `AlignTop`, `AlignBottom`, `AlignVCenter`, combine with `|` |
| `Layout.margins`, `leftMargin`, `rightMargin`, `topMargin`, `bottomMargin` | Extra space around this item |
| `Layout.horizontalStretchFactor` / `verticalStretchFactor` | Share extra space unequally between fillers (Qt 6.5+) |
| `Layout.row`, `column`, `rowSpan`, `columnSpan` | Placement in a `GridLayout` |
| `Layout.uniformCellWidths` / `uniformCellHeights` | On the layout itself: equal cells |

### Spacers
An empty `Item` that fills pushes things apart:

```qml
RowLayout {
    Text { text: "left" }
    Item { Layout.fillWidth: true }      // spacer
    Text { text: "right" }
}
```

### GridLayout: a quick-settings grid
```qml
GridLayout {
    columns: 2
    rowSpacing: 8; columnSpacing: 8
    Repeater {
        model: ["Wi-Fi", "Bluetooth", "Do not disturb", "Night light", "Caffeine", "Airplane"]
        Rectangle {
            required property string modelData
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            radius: 16; color: "#313244"
            Text { anchors.centerIn: parent; text: parent.modelData; color: "white" }
        }
    }
}
```

### StackLayout: one child at a time
```qml
StackLayout {
    currentIndex: tabs.currentIndex          // show page 0, 1 or 2
    Rectangle { color: "#f38ba8" }
    Rectangle { color: "#a6e3a1" }
    Rectangle { color: "#89b4fa" }
}
```

## Positioners or layouts?

| Need | Use |
|---|---|
| Items stacked at their natural size | `Row` / `Column` |
| Something must stretch, or needs min/max sizes | `RowLayout` / `ColumnLayout` |
| Wrapping tags or chips | `Flow` |
| Grid of equal tiles | `GridLayout` with `fillWidth`, or `Grid` with fixed sizes |
| Tabs or pages | `StackLayout` (or a `Loader` to save memory) |
| Precise overlapping placement | anchors |

## A full bar layout

```qml file="~/.config/quickshell/playground/shell.qml"
import Quickshell
import QtQuick
import QtQuick.Layouts

PanelWindow {
    anchors { top: true; left: true; right: true }
    implicitHeight: 38
    color: "#11111b"

    component Chip: Rectangle {
        property alias text: t.text
        implicitWidth: t.implicitWidth + 20; implicitHeight: 26
        radius: 13; color: "#313244"
        Text { id: t; anchors.centerIn: parent; color: "#cdd6f4"; font.pixelSize: 12 }
    }

    RowLayout {                                   // left group
        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 6
        Chip { text: "1" } Chip { text: "2" } Chip { text: "3" }
        Text {
            text: "kitty — ~/projects/quickshell/very/long/path/that/goes/on"
            color: "#a6adc8"; elide: Text.ElideRight
            Layout.maximumWidth: 260                // cap the width so elide kicks in
        }
    }

    Chip { anchors.centerIn: parent; text: "Fri 21 Nov  14:32" }   // true center

    RowLayout {                                   // right group
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 6
        Chip { text: "wifi" } Chip { text: "vol 62%" } Chip { text: "bat 81%" }
    }
}
```

## Practice

::: exercise warm | Sidebar column
Make a `ColumnLayout` sidebar: a header with fixed height, a list area that fills, and a footer with fixed height.
--- solution
```qml
ColumnLayout { anchors.fill: parent; spacing: 0
    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 48; color: "#313244" }
    Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: "#1e1e2e" }
    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 36; color: "#313244" } }
```
:::

::: exercise practice | Tile grid
Build a 3×2 `GridLayout` of toggle tiles that stretch to the window width and toggle color on click.
--- solution
```qml
GridLayout { anchors.fill: parent; anchors.margins: 10; columns: 3; rowSpacing: 8; columnSpacing: 8
    Repeater { model: 6
        Rectangle { property bool on: false
            Layout.fillWidth: true; Layout.preferredHeight: 50; radius: 12
            color: on ? "#cba6f7" : "#313244"
            TapHandler { onTapped: parent.on = !parent.on } } } }
```
:::

::: exercise practice | Close the gap
Hide one chip in a `RowLayout` with `visible: false` and watch the others close the gap. Then use `opacity: 0` instead and compare.
--- why
Layouts skip invisible items entirely, but an item with `opacity: 0` still takes its space. Use `visible` to remove a module from the bar; use opacity when you want to fade it while keeping the layout steady.
:::

::: exercise challenge | Responsive
Make a `GridLayout` whose `columns` is 1 when the window is narrower than 400 px and 3 otherwise.
--- solution
```qml
GridLayout { anchors.fill: parent; columns: width < 400 ? 1 : 3 }
```
:::
