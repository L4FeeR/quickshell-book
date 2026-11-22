# Masks, Regions and Click-Through

A window catches every click inside its rectangle, even where it's transparent. That's a problem for screen-corner overlays, OSDs, floating widgets and Caelestia-style fullscreen shells. The **mask** property controls exactly which parts of a window accept input.

## mask and Region

Every [[QsWindow]] has a `mask` property that takes a [[Region]]. When it's set, **only the region is clickable**; everything else passes through to the windows underneath.

### Fully click-through

```qml
PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {}                 // empty region → no input anywhere
    // decorations, screen corners, visual effects…
}
```

Use it for anything purely visual on top of your desktop: screen corners, a desktop clock you don't interact with, OSDs.

### Clickable only where an item is

```qml
PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    mask: Region { item: card }     // only the card catches clicks

    Rectangle {
        id: card
        x: 100; y: 100; width: 300; height: 200; radius: 16
        color: "#1e1e2e"
    }
}
```

The region **follows the item's geometry automatically**: move or resize `card` (even with an animation) and the clickable area moves with it.

## Region properties

| Property | Meaning |
|---|---|
| `item` | Take geometry from this item (overrides x/y/width/height) |
| `x`, `y`, `width`, `height` | Manual geometry (window coordinates) |
| `shape` | [[RegionShape]]: `RegionShape.Rect` (default) or `RegionShape.Ellipse` |
| `radius`, `topLeftRadius`, `topRightRadius`, `bottomLeftRadius`, `bottomRightRadius` | Rounded rectangle corners |
| `intersection` | How it combines with its parent region ([[Intersection]]): `Combine`, `Subtract`, `Intersect`, `Xor` |
| `regions` | Child regions (default property: write them inside) |
| `changed()` | Emitted when geometry changes |

## Combining regions

Nest regions to build complex shapes. Children combine with their parent according to `intersection`:

```qml
mask: Region {
    item: bar                                           // the bar is clickable…
    Region { item: drawer }                             // …plus the drawer (Combine is the default)
    Region { item: notifications }                      // …plus the notification stack
    Region { item: hole; intersection: Intersection.Subtract }   // minus this hole
}
```

| Intersection | Result |
|---|---|
| `Combine` | union: parent OR child |
| `Subtract` | parent minus child |
| `Intersect` | only where both overlap |
| `Xor` | where exactly one of them is |

## The fullscreen-shell architecture (Caelestia style)

Instead of one window per bar, popup and drawer, some shells use **one fullscreen transparent window per monitor** that contains *everything* (bar, drawers, popups, notifications), with a mask covering only the visible parts:

<div class="diagram"><svg viewBox="0 0 760 260" role="img" aria-label="fullscreen shell with mask">
<rect class="n" x="20" y="20" width="720" height="220" rx="10"/><text x="30" y="40" class="sm">one fullscreen window (transparent, ExclusionMode.Ignore)</text>
<rect class="a" x="20" y="20" width="40" height="220" rx="6"/><text x="26" y="140" class="sm">bar</text>
<rect class="g" x="60" y="60" width="220" height="140" rx="10"/><text x="80" y="135">drawer (open)</text>
<rect class="g" x="520" y="40" width="200" height="80" rx="10"/><text x="540" y="85">notification</text>
<text x="330" y="180" class="sm">everything else: clicks go to your apps</text>
</svg></div>

Why do this?

- Drawers can **animate out of the bar** seamlessly: same window, same coordinates, shared shapes.
- Inverted corners and outlines connect bar and panels in one `Shape`.
- Popups never need cross-window positioning.

What you must handle yourself:

1. **Space reservation**: with `ExclusionMode.Ignore` the big window reserves nothing, so add a second, invisible PanelWindow per screen with an `exclusiveZone` equal to your bar size.
2. **Masking**: keep the mask in sync with what's visible (bind each region's `item` to visible parts).
3. **Keyboard focus**: switch `WlrLayershell.keyboardFocus` to `OnDemand` or `Exclusive` only while a panel that needs typing is open.

```qml
// the reservation window (one per screen)
PanelWindow {
    required property ShellScreen modelData
    screen: modelData
    anchors { left: true; top: true; bottom: true }
    implicitWidth: 1                     // tiny, invisible
    exclusiveZone: 44                    // = bar width
    color: "transparent"
    mask: Region {}
}
```

[[ch:65-proj-drawers]] builds this architecture in full.

## HyprlandWindow.visibleMask

On Hyprland, [[HyprlandWindow]] adds `visibleMask`: a hint about which regions are actually visible, so the compositor can skip rendering (and blurring) the transparent parts of a big window. That's a worthwhile optimization for fullscreen shells:

```qml
import Quickshell.Hyprland
PanelWindow {
    mask: Region { item: panel }
    HyprlandWindow.visibleMask: Region { item: panel }
}
```

## Masks and blur

With compositor blur (Hyprland `layerrule = blur`), blur applies to the whole layer surface, minus fully transparent pixels when `ignorealpha` is set. On fullscreen transparent windows, always use `ignorealpha`, otherwise the entire screen may get blurred.

## Practice

::: exercise warm | Click-through overlay
Make a fullscreen transparent overlay where only a 200×100 card catches clicks.
--- solution
```qml
PanelWindow { anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"; exclusionMode: ExclusionMode.Ignore
    mask: Region { item: card }
    Rectangle { id: card; x: 100; y: 100; width: 200; height: 100; radius: 12; color: "#1e1e2e" } }
```
:::

::: exercise practice | Draggable card
Make the card draggable while the rest stays click-through.
--- solution
Add `DragHandler {}` inside the card. The mask follows the card because `Region { item: card }` tracks the item's position.
:::

::: exercise practice | Round region
Make the clickable region a circle with `shape: RegionShape.Ellipse`.
--- solution
```qml
mask: Region { item: card; shape: RegionShape.Ellipse }
```
:::

::: exercise challenge | Bar + drawer
Build a mask that is the bar **plus** an animated drawer below it, and confirm clicks pass through everywhere else.
--- solution
```qml
mask: Region { item: bar
    Region { item: drawer } }          // child regions are added (union) by default
```
:::
