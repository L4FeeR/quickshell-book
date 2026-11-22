# Item and the Visual Tree

Every visible thing in Qt Quick (rectangles, text, images, your components, even the content of a Quickshell window) is an **Item** or inherits from it. Learn `Item`'s properties once and you know half of every other visual type.

## Item: the invisible base

```qml
Item {
    x: 10; y: 20                // position relative to the parent's top-left corner
    width: 100; height: 50      // size
    z: 1                        // stacking order among siblings (higher = on top)
    visible: true               // false hides it AND its children; also stops input
    opacity: 1.0                // 0.0 transparent … 1.0 opaque (children too)
    enabled: true               // false disables input for it and its children
    clip: false                 // true cuts off children drawn outside its bounds
    scale: 1.0                  // grow/shrink around transformOrigin
    rotation: 0                 // degrees, clockwise
    transformOrigin: Item.Center
}
```

An `Item` draws nothing itself. It's a **container** and positioning helper. Use it to group things, as an invisible spacer, or as the root of components that shouldn't expose `Rectangle` properties.

## Complete Item property reference (the ones you'll use)

| Property | Type | Meaning |
|---|---|---|
| `x`, `y` | real | Position relative to the parent |
| `width`, `height` | real | Actual size |
| `implicitWidth`, `implicitHeight` | real | Preferred size from content ([[ch:17-sizing]]) |
| `z` | real | Stacking order among siblings |
| `visible` | bool | Shown? (inherited: a hidden parent hides children) |
| `opacity` | real | 0–1 transparency (multiplies down the tree) |
| `enabled` | bool | Accepts input? |
| `clip` | bool | Clip children to own rectangle |
| `scale`, `rotation`, `transformOrigin` | | Simple transforms |
| `transform` | list | Advanced transforms: `Scale`, `Rotation`, `Translate`, `Matrix4x4` |
| `anchors.*` | group | Attach edges to other items ([[ch:18-anchors]]) |
| `parent` | Item | Visual parent |
| `children`, `data` | list | Child items / all child objects |
| `childrenRect` | rect | Bounding box of all children |
| `focus`, `activeFocus` | bool | Keyboard focus ([[ch:21-input]]) |
| `states`, `transitions`, `state` | | State machine ([[ch:24-animation-advanced]]) |
| `layer.enabled`, `layer.effect` | | Render offscreen for effects ([[ch:25-effects]]) |
| `antialiasing`, `smooth` | bool | Edge and scaling quality |
| `containmentMask` | object | Custom shape for mouse hit-testing |
| `visibleChildren` | list | Children currently visible |

Methods you might use: `mapToItem(item, x, y)`, `mapFromItem(item, x, y)`, `mapToGlobal(x, y)`, `contains(point)`, `forceActiveFocus()`, `childAt(x, y)`, `grabToImage(callback)`.

## Coordinates

Every item has its own coordinate system with `(0, 0)` at its top-left:

<div class="diagram"><svg viewBox="0 0 520 220" role="img" aria-label="coordinates">
<rect class="n" x="20" y="20" width="460" height="180" rx="6"/><text x="30" y="40">parent (0,0)</text>
<rect class="a" x="140" y="80" width="200" height="80" rx="6"/><text x="150" y="100">child: x: 120, y: 60</text><text class="sm" x="150" y="120">its own (0,0) is here ↖</text>
<path class="ln" d="M20 20 L140 80"/>
</svg></div>

To convert between coordinate systems (e.g. "where is this button on screen, so I can open a popup there?"), use `mapToItem` / `mapFromItem`, or in Quickshell the window helpers [[QsWindow.itemPosition()]] and [[QsWindow.itemRect()]].

## Stacking order: who's on top

1. Children draw **above** their parent.
2. Later siblings draw **above** earlier siblings.
3. `z` overrides this **among siblings only**: a child can't escape its parent's stacking position.

```qml
Item {
    Rectangle { color: "red";  width: 100; height: 100 }
    Rectangle { color: "blue"; width: 100; height: 100; x: 50 }        // on top of red
    Rectangle { color: "green"; width: 100; height: 100; x: 25; z: -1 } // below both
}
```

## visible vs opacity vs enabled

| | Drawn | Takes space in layouts | Gets mouse/keys | Bindings run |
|---|---|---|---|---|
| `visible: false` | no | **no** (layouts skip it) | no | yes |
| `opacity: 0` | no (invisible) | yes | **yes!** | yes |
| `enabled: false` | yes | yes | no | yes |
| `Loader { active: false }` | no | no | no | no (doesn't exist) |

> [!WARN] Invisible but clickable
> An item with `opacity: 0` still catches clicks. When fading something out, either also set `visible: false` at the end of the animation or disable its MouseArea.

## clip

By default children can draw outside their parent. Set `clip: true` to cut them off at the parent's rectangle. This is needed for scrolling lists and sliding panels:

```qml
Rectangle {
    width: 200; height: 40; radius: 8; color: "#313244"
    clip: true                                  // the long text is cut at the edge
    Text { x: 8; text: "A very very very long song title that keeps going"; color: "white" }
}
```

`clip` cuts to a **rectangle** and ignores `radius`. For rounded clipping use Quickshell's [[ClippingRectangle]] ([[ch:25-effects]]).

## Transforms

```qml
Rectangle {
    width: 40; height: 40; color: "#cba6f7"
    rotation: 45                                 // diamond
    scale: hovered ? 1.15 : 1.0                  // grow on hover
    transformOrigin: Item.Center                 // pivot point (Center, TopLeft, Bottom…)
    property bool hovered: hh.hovered
    HoverHandler { id: hh }
}

Image {
    transform: [
        Scale { xScale: -1; origin.x: width / 2 },     // mirror horizontally
        Translate { y: 4 }
    ]
}
```

## The visual tree vs the object tree

Not every object is visual. `Timer`, `Process`, `Connections` and `SystemClock` have no position. They can live inside items (QML puts them in the `data` list) but don't draw. Quickshell's `Scope` and `ShellRoot` are non-visual containers for windows and services.

```qml
Item {
    Rectangle { }        // visual child → goes into children
    Timer { }            // non-visual → goes into data but not children
}
```

## Inside a Quickshell window

A [[PanelWindow]] isn't an Item itself. It's a window that **contains** an Item tree. Children you write inside it go into its `contentItem`, which fills the window. So `anchors.fill: parent` on a window's child means "fill the window".

## Practice

::: exercise warm | Bring to front
Stack three overlapping circles and make the one under the mouse come to the front (`z`).
--- solution
```qml
Item {
    width: 200; height: 100
    Repeater {
        model: ["#f38ba8", "#a6e3a1", "#89b4fa"]
        Rectangle {
            required property string modelData
            required property int index
            x: index * 50; width: 90; height: 90; radius: 45; color: modelData
            z: hov.hovered ? 10 : index
            HoverHandler { id: hov }
        }
    }
}
```
:::

::: exercise practice | Disabled look
Make an item that fades to `opacity: 0.3` when `enabled` is false, with a click elsewhere toggling `enabled`.
--- solution
```qml
Rectangle { id: box; width: 80; height: 40; color: "#cba6f7"; opacity: enabled ? 1 : 0.3
            Behavior on opacity { NumberAnimation { duration: 150 } } }
MouseArea { x: 100; width: 80; height: 40; onClicked: box.enabled = !box.enabled }
```
:::

::: exercise practice | Spinner
Rotate a Material Symbols `refresh` icon continuously while `property bool busy` is true.
--- hint
`RotationAnimation on rotation { running: busy; loops: Animation.Infinite; from: 0; to: 360; duration: 1000 }`
--- solution
```qml
Text {
    text: "refresh"; font.family: "Material Symbols Rounded"; font.pixelSize: 24; color: "white"
    RotationAnimation on rotation { running: busy; loops: Animation.Infinite; from: 0; to: 360; duration: 1000 }
}
```
:::

::: exercise challenge | Mapping coordinates
Put a small dot in a nested item and print its position relative to the window with `mapToItem(null, 0, 0)` when clicked.
--- solution
```qml
Rectangle { x: 40; y: 30; width: 100; height: 60; color: "#313244"
    Rectangle { id: dot; x: 20; y: 10; width: 8; height: 8; radius: 4; color: "red"
        TapHandler { onTapped: console.log(dot.mapToItem(null, 0, 0)) } } }       // QPointF(60, 40)
```
:::
