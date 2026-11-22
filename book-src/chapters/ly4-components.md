# lyne-dots 4: The Building Blocks

Before the bar, a handful of small components that everything else is made of: themed text, icons, the **concave corner** that gives lyne its look, the bar's groups and buttons, the logo and a slider. Each one is short, and each one reads its look from `Config`, so changing a setting or a theme restyles them everywhere.

They live in `components/`, which is the `qs.components` module.

## Text and icons

@include lyne/components/StyledText.qml

Every label in the shell is a `StyledText`: the theme's text colour, the shell's font and size, long text cut with "…", centred vertically. A label that needs something else overrides it (`color: Config.subtextColor`).

@include lyne/components/Glyph.qml

An icon is a `StyledText` holding one Nerd Font character, a little bigger and centred: `Glyph { text: Icons.bell }`. Because it **is** text, it takes the theme colour and fades with it like any label.

## The concave corner

<div class="preview"><svg width="560" height="170" viewBox="0 0 560 170"><g font-size="11"><rect x="20" y="20" width="220" height="30" fill="#1a1b26"/><rect x="20" y="50" width="220" height="100" fill="#565f89" opacity=".35"/><text x="130" y="140" fill="#c0caf5" text-anchor="middle">without: a hard edge</text><rect x="300" y="20" width="240" height="30" fill="#1a1b26"/><path d="M300 50h20a20 20 0 0 0-20 20z" fill="#1a1b26"/><path d="M540 50h-20a20 20 0 0 1 20 20z" fill="#1a1b26"/><rect x="300" y="50" width="240" height="100" fill="#565f89" opacity=".35"/><path d="M300 50h20a20 20 0 0 0-20 20z" fill="none" stroke="#7aa2f7" stroke-width="1.5" stroke-dasharray="3 2"/><text x="420" y="140" fill="#c0caf5" text-anchor="middle">with ConcaveCorner: it flows into the screen</text><text x="330" y="80" fill="#7aa2f7">◀ one corner</text></g></svg></div>

@include lyne/components/ConcaveCorner.qml

::: walk
@ 4-10 | What it draws
A small square whose inside corner is cut by a quarter circle. Put one under each end of a full-width bar and the bar seems to melt into the screen. The same piece joins attached panels to the bar ([[ch:ly6-panels]]).
@ 14-17 | Inputs
Its size, its colour, and two flips so one shape covers all four orientations.
@ 19-21 | Size and rendering
A `Shape` would otherwise size itself to its path, so width and height are set explicitly. The curve renderer draws a smooth, antialiased arc ([[ch:26-shapes-canvas]]).
@ 23-28 | Flipping
A `Scale` of −1 around the centre mirrors the shape. `mirrored` flips left-right, for the right end of the bar; `flipped` flips upside down, for a bar at the bottom.
@ 30-44 | The path
Start at the top-left, draw a line along the top edge, then an arc back down to the left edge, curving **towards** the top-left (counter-clockwise), and close up the left edge. The filled area is the top-left corner minus a quarter circle. `strokeWidth: -1` means no outline.
:::

> [!TIP] Hide it with size, not visible
> lyne's comments warn that a `Shape` created hidden may not draw when shown later. The bar sets `size: 0` to hide its corners (in the "docked" style) instead of `visible: false`.

## Bar groups

@include lyne/components/BarIsland.qml

::: walk
@ 11 | Children go in the row
`default property alias content: row.data` means anything you write inside a `BarIsland { … }` becomes a child of its row. That's how the bar writes `BarIsland { LauncherButton {} Workspaces {} }`.
@ 12-13 | Framed or not
Only the "islands" bar style gives each group its own background and padding.
@ 15-18 | Size and look
As wide as the row plus padding, a little shorter than the bar, fully rounded. In other styles it's transparent, and the bar's own background shows.
@ 20-26 | The row
A `RowLayout` vertically centred, items spaced by the padding token.
:::

## The bar button

@include lyne/components/BarButton.qml

::: walk
@ 10-13 | Content and state
Like the island, children go into a row (`Glyph`, `StyledText`, anything). `active` lights the button while its popup is open; `hovered` comes from the mouse area.
@ 15-18 | Signals
Left, right and middle clicks and the scroll wheel, each a signal. A user writes `onRightClicked: …` without dealing with mouse buttons.
@ 20-22 | Size
The content's width plus padding on both sides, the button height token, fully rounded.
@ 23-27 | Hover colour
Lit when active or hovered. The resting colour is the **same colour at zero opacity**, not `"transparent"`: fading from transparent black to a light surface would pass through grey, while fading the alpha of one colour stays clean. During a theme fade the `Behavior` is off, because `Config` is already animating the colour.
@ 29-33 | The row
Centred in the button.
@ 35-50 | Input
One `MouseArea` for everything, with a hand cursor. The clicked button decides which signal fires; the wheel reports +1 or −1.
:::

```qml
BarButton {
    onClicked: SettingsService.open("")
    onRightClicked: ThemeService.step(1)
    Glyph { text: Icons.cog }
}
```

@include lyne/components/BarDivider.qml

A one-pixel line between groups of buttons, about half the button height.

## The logo

@include lyne/components/LyneMark.qml

::: walk
@ 5-7 | A drawn logo
lyne-dots' logo is a line and a dot, drawn with shapes so it can animate (its `LyneLogo.qml` makes the dot ride along the line when the launcher opens). The rebuild has its own simpler mark, an "L" and a dot, driven by two numbers.
@ 11-13 | Colours
The dot is the accent. The line is derived from it: same hue, 60% of the saturation, a bit darker. Any accent gives a matching pair. `Math.max(0, …)` guards against a hue of −1, which Qt reports for greys.
@ 14-15 | Animation inputs
`lift` raises the dot; `stretch` makes it tall and thin (positive) or squashed (negative). The launcher button animates these ([[ch:ly5-bar]]).
@ 20-28 | Drawing at any size
The paths use a 120 × 100 box. The `Shape` is scaled to fit the item and centred, so the logo is as big as you make the item.
@ 30-41 | The line
A thick stroke with round ends: down, a soft curve (`PathQuad`), then across.
@ 42-54 | The dot
An ellipse made of two half-arcs. Its radii change with `stretch` (taller and narrower, or wider and flatter), and its centre moves up with `lift`. Inside the path elements, `dot.rx` refers to the `ShapePath` by id, because path elements have no `parent`.
:::

## Cards and sliders

@include lyne/components/Card.qml

A raised box inside a panel: the card colour (surface0 at the panel's opacity) with the normal radius.

@include lyne/components/QsSlider.qml

::: walk
@ 9-12 | Interface
A value from 0 to 1 and an icon. The slider never changes `value` itself: it emits `moved(v)` and lets its user decide (set the volume, the brightness…). The value then comes back through the binding. This keeps the slider and the real level from disagreeing.
@ 17-20 | The track
The full width, fully rounded, in a surface colour.
@ 22-31 | The fill
Accent-coloured, never narrower than a circle so the icon always sits on it. It animates to new values, except while being dragged (then it follows the pointer directly).
@ 32-38 | The icon
Dark text on the accent. Clicking it emits `iconClicked`; Quick Settings uses that to open the sound page.
@ 39-46 | The percentage
On the right of the track.
@ 49-58 | Input
The mouse area starts after the icon so the icon stays clickable. Pressing or dragging converts the x position to a value; the wheel nudges by 5%.
:::

## Practice

::: exercise warm | A themed label
Add a `StyledText` and a `Glyph` to the bar's right side showing `Icons.cog` and "Settings", and give them a `BarButton` that opens the settings. Switch themes: they follow.
:::

::: exercise practice | All four corners
Place four `ConcaveCorner`s in the corners of a fullscreen transparent `PanelWindow`, with the right `mirrored`/`flipped` values, to round off your screen's corners.
--- solution
```qml
ConcaveCorner { size: 15; color: "black" }                                   // top left
ConcaveCorner { x: parent.width - 15; size: 15; color: "black"; mirrored: true }
ConcaveCorner { y: parent.height - 15; size: 15; color: "black"; flipped: true }
ConcaveCorner { x: parent.width - 15; y: parent.height - 15; size: 15; color: "black"; mirrored: true; flipped: true }
```
Give the window `mask: Region {}` so it never takes clicks.
:::

::: exercise practice | A toggle button
Make a `ToggleButton` component based on `BarButton` with a `checked` property that's shown as `active` and flips on click.
:::

::: exercise challenge | Animate the line
Use `ShapePath`'s `trim.end` (Qt 6.10+) on the logo's line, animated from 0 to 1 when the bar starts, so the line draws itself. lyne's `LauncherButton.qml` does this.
:::
