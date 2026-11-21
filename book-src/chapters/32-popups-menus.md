# Popups, Anchors and Menus

Click the clock and a calendar drops down. Click a tray icon and a menu appears. Hover a module and a tooltip shows. These are **popups**: separate surfaces positioned relative to something in your bar. Quickshell provides [[PopupWindow]], the [[PopupAnchor]] positioning system, and [[QsMenuAnchor]] / [[QsMenuOpener]] for menus.

## Why not just a bigger rectangle?

Your bar window is 36 px tall. Anything drawn below that is clipped, invisible. A popup needs its **own window**. That's what PopupWindow creates, positioned by the compositor relative to the parent window, even across screen edges.

## PopupWindow basics

```qml
import Quickshell
import QtQuick

PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    implicitHeight: 36

    Text {
        id: clockText
        anchors.centerIn: parent
        text: "14:32"
        MouseArea { anchors.fill: parent; onClicked: cal.visible = !cal.visible }
    }

    PopupWindow {
        id: cal
        anchor.window: bar               // positioned relative to the bar window…
        anchor.item: clockText           // …and to this item inside it
        anchor.edges: Edges.Bottom       // attach to the item's bottom edge
        anchor.gravity: Edges.Bottom     // and grow downward from there
        anchor.margins.top: 8            // gap between bar and popup
        implicitWidth: 280
        implicitHeight: 300
        color: "transparent"
        visible: false
        grabFocus: true                  // close automatically when clicking outside

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: "#1e1e2e"
            Text { anchors.centerIn: parent; color: "white"; text: Qt.formatDate(new Date(), "MMMM yyyy") }
        }
    }
}
```

### PopupWindow members

| Member | Meaning |
|---|---|
| `anchor` | a [[PopupAnchor]] group describing where the popup attaches (below) |
| `visible` | show or hide (defaults to **false**) |
| `grabFocus` | if true, clicking outside dismisses the popup and sets `visible` to false |
| `implicitWidth`, `implicitHeight`, `color`, `mask`… | inherited from [[QsWindow]] |
| `screen` | read-only: where it ended up |

> [!TIP] grabFocus
> `grabFocus: true` gives you "click outside to close" on any compositor that supports popup grabs, with no extra code. While open, the popup receives keyboard input too.

## PopupAnchor: where the popup goes

The `anchor` group positions the popup:

| Property | Meaning |
|---|---|
| `window` | the parent window (required, unless `item` is set, in which case its window is used) |
| `item` | an item to attach to; the anchor rectangle becomes that item's rectangle |
| `rect.x`, `rect.y`, `rect.width`, `rect.height` | a manual anchor rectangle, relative to `item` or `window` |
| `margins.left/right/top/bottom` | shrink or grow the anchor rectangle |
| `edges` | which point of the anchor rectangle to attach to ([[Edges]] flags) |
| `gravity` | which direction the popup extends from that point |
| `adjustment` | what to do if it doesn't fit on screen ([[PopupAdjustment]]: `Slide`, `Flip`, `Resize`, `All`…) |
| `updateAnchor()` | recompute when the anchor item moved but no property changed |
| `anchoring()` signal | fires just before positioning, so you can tweak `rect` |

### edges + gravity, visually

<div class="diagram"><svg viewBox="0 0 760 230" role="img" aria-label="edges and gravity">
<rect class="a" x="300" y="20" width="160" height="40" rx="6"/><text x="330" y="45">anchor item</text>
<rect class="g" x="300" y="66" width="160" height="70" rx="6"/><text x="306" y="96">edges: Bottom</text><text x="306" y="114">gravity: Bottom</text>
<rect class="g" x="60" y="66" width="180" height="70" rx="6"/><text x="66" y="96">edges: Bottom | Left</text><text x="66" y="114">gravity: Bottom | Left</text>
<rect class="g" x="520" y="66" width="190" height="70" rx="6"/><text x="526" y="96">edges: Bottom | Right</text><text x="526" y="114">gravity: Bottom | Right</text>
<text class="sm" x="60" y="170">edges = WHICH point of the anchor rect (Bottom = bottom-center, Bottom|Left = bottom-left corner)</text>
<text class="sm" x="60" y="190">gravity = WHICH WAY the popup grows from that point (Bottom|Right = down and to the right)</text>
</svg></div>

Common setups:

```qml
// dropdown centered under an item
anchor.item: btn; anchor.edges: Edges.Bottom; anchor.gravity: Edges.Bottom

// menu aligned to the item's left edge
anchor.edges: Edges.Bottom | Edges.Left; anchor.gravity: Edges.Bottom | Edges.Right

// for a bottom bar: open upward
anchor.edges: Edges.Top; anchor.gravity: Edges.Top

// for a left vertical bar: open to the right
anchor.edges: Edges.Right; anchor.gravity: Edges.Right

// manual position relative to the window
anchor.window: bar
anchor.rect.x: bar.width - width - 10
anchor.rect.y: bar.height + 6
```

### Keeping popups on screen

```qml
anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip   // slide along the edge, flip if needed
```

## Hover tooltips

A tooltip is a PopupWindow shown while hovering, after a short delay:

```qml file="widgets/Tooltip.qml"
import Quickshell
import QtQuick

PopupWindow {
    id: tip
    required property Item target
    property string text
    property bool show: false

    anchor.item: target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6
    implicitWidth: label.implicitWidth + 16
    implicitHeight: label.implicitHeight + 10
    color: "transparent"
    visible: show && text !== ""

    Rectangle { anchors.fill: parent; radius: 8; color: "#11111b"; border.color: "#313244" }
    Text { id: label; anchors.centerIn: parent; text: tip.text; color: "#cdd6f4"; font.pixelSize: 12 }
}
```

```qml
Rectangle {
    id: wifiIcon
    HoverHandler { id: hh }
    Timer { id: delay; interval: 500; running: hh.hovered }
    Tooltip { target: wifiIcon; text: "Connected to Home-5G"; show: hh.hovered && !delay.running }
}
```

## Menus

### System tray menus: QsMenuAnchor
Tray items expose a menu handle ([[SystemTrayItem.menu]]). [[QsMenuAnchor]] displays it as a native-looking menu at an anchor:

```qml
QsMenuAnchor {
    id: menuAnchor
    menu: trayItem.menu                   // a QsMenuHandle
    anchor.item: trayIcon
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
}
// on right click: menuAnchor.open()
```

Members: `anchor`, `menu`, `visible`, `open()`, `close()`, signals `opened()`, `closed()`.

### Fully custom menus: QsMenuOpener
To draw the menu **in your own style**, read its entries with [[QsMenuOpener]] and build the UI yourself in a PopupWindow:

```qml
QsMenuOpener {
    id: opener
    menu: trayItem.menu
}

ColumnLayout {
    Repeater {
        model: opener.children                  // ObjectModel of QsMenuEntry
        Rectangle {
            required property QsMenuEntry modelData
            Layout.fillWidth: true
            implicitHeight: modelData.isSeparator ? 1 : 30
            color: modelData.isSeparator ? "#45475a" : hov.hovered ? "#313244" : "transparent"
            HoverHandler { id: hov }
            Text {
                visible: !modelData.isSeparator
                anchors.verticalCenter: parent.verticalCenter; x: 10
                text: modelData.text
                color: modelData.enabled ? "#cdd6f4" : "#6c7086"
            }
            TapHandler { enabled: modelData.enabled && !modelData.isSeparator; onTapped: modelData.triggered() }
        }
    }
}
```

[[QsMenuEntry]] gives you `text`, `icon`, `enabled`, `isSeparator`, `buttonType` (checkbox or radio), `checkState`, `hasChildren` (for submenus: open another QsMenuOpener with `menu: entry`), the `triggered()` signal to activate it, and `display(window, x, y)` for a native submenu. [[ch:50-proj-tray]] builds a complete custom tray menu, submenus included.

## Popups from deep inside components

A widget nested deep in a bar can find its window with the attached `QsWindow.window`:

```qml
PopupWindow {
    anchor.window: QsWindow.window      // whatever window contains this component
    anchor.item: myButton
}
```

## Popups vs separate panels

| Use a PopupWindow when… | Use a separate PanelWindow when… |
|---|---|
| it belongs to one bar element (calendar under clock) | it's a big standalone panel (sidebar, launcher) |
| it should follow that element | it has its own position (screen edge, center) |
| it's small and transient | it needs exclusive keyboard focus or its own layer |

> [!TRY] Exercises
> 1. Add a calendar popup under your clock with `grabFocus: true`.
> 2. Build `Tooltip.qml` and add tooltips to three bar modules.
> 3. Make the calendar open **upward** if the bar is at the bottom (bind `edges`/`gravity` to a `property bool bottomBar`).
