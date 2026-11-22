# end-4 2: Appearance, Config and Common Widgets

illogical-impulse is built on one big design file, `Appearance.qml`, plus a nested JSON config and a set of shared widgets. This chapter builds all three, and the two singletons that hold global state and load colours.

```text
modules/common/           Appearance  Config  functions/ColorUtils
modules/common/widgets/   StyledText  MaterialSymbol  RippleButton  RoundCorner  CircularProgress
services/                 GlobalStates  MaterialThemeLoader  Hypr
```

## Module 1: Colour helpers

@include impulse/modules/common/functions/ColorUtils.qml

Two operations build every derived colour in ii:

- `mix(a, b, p)` blends two colours: `mix(layer, text, 0.92)` is the layer with 8% of the text colour mixed in, which is a Material **hover** colour.
- `transparentize(c, amount)` makes a colour more see-through.

## Module 2: Appearance

@include impulse/modules/common/Appearance.qml

::: walk
@ 13-14 | Raw colours and transparency
`m3colors` holds the Material palette exactly as the theme generator produces it (Module 6 loads it). `transparency` is applied to the panel background when enabled.
@ 16-21 | Layer 0: panel backgrounds
The **layers** are ii's key idea. Instead of using Material roles directly everywhere, it defines what each depth of the UI uses. Layer 0 is the bar and the sidebars' background, plus its text colour and a subtle border.
@ 22-31 | Layers 1 and 2
Layer 1 is a group or card sitting on layer 0 (the bar's rounded groups, the sidebar's cards); layer 2 is a control inside a card. Each layer has hover and active versions, made by mixing a little of its text colour into it. A widget never asks "which Material role?", only "which layer am I on?".
@ 32-41 | Accents
Primary for active things, secondary container for selected/occupied things, inverse surface for tooltips.
@ 44-53 | Rounding
ii's rounding scale, from `unsharpen` (2 px, barely rounded) to `full`. `screenRounding` is used for the bar's hanging corners and the screen corners.
@ 55-72 | Fonts
Rubik for the UI, Gabarito for titles, Material Symbols for icons. Sizes are named, so changing `normal` adjusts every normal text.
@ 76-89 | Animation presets
The same Material 3 expressive curves as Caelestia. Each preset (`elementMove`, `elementMoveFast`…) bundles a duration and a curve.
@ 101-119 | Ready-made animations
Each preset also carries a `Component` of a `NumberAnimation` (and a `ColorAnimation`) with its settings. A widget can then write `Behavior on x { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }`. `createObject(this)` creates a fresh animation owned by that widget. This is exactly how ii applies motion everywhere, and it means changing one preset changes every animation that uses it.
@ 121-149 | Default palette
A dark Material palette until the theme file is loaded.
:::

> [!NOTE] In the original
> `modules/common/Appearance.qml` (~420 lines) has more layers (0–4), "solved" overlay colours that look right even when transparent, an automatic transparency based on the wallpaper's vibrancy (using a [[ColorQuantizer]]), terminal colours, and many more sizes. The structure is the same.

## Module 3: Config

@include impulse/modules/common/Config.qml

::: walk
@ 11-13 | Folder, options and ready
`options` is the whole config as nested objects: `Config.options.bar.autoHide.enable`. `ready` becomes true once the file has been read (or created), so panels can wait for real settings instead of flashing with defaults.
@ 15-25 | Setting a nested key
`setNestedValue("bar.cornerStyle", "1")` walks the dots to the right object and assigns. Text like `"true"` or `"3"` is turned into a real boolean or number, which matters when the value comes from a terminal.
@ 27-39 | The file
Same pattern as Caelestia's config: watch and reload on change, save on adapter updates, create on first run, and mark `ready` in every case.
@ 41-73 | The options
`bar.cornerStyle` picks the bar style (0 = hug the screen with hanging corners, 1 = floating, 2 = plain). `overview.rows`/`columns`/`scale` shape the overview grid.
@ 76-79 | Changing options from the terminal
`qs -c impulse ipc call config set bar.bottom true` moves the bar to the bottom, live.
:::

## Module 4: Global state

@include impulse/services/GlobalStates.qml

One boolean per panel. Panels read their flag (`visible: GlobalStates.sidebarRightOpen`) and buttons, keybinds and IPC write it. The `GlobalShortcut` sets `superDown` while Super is held; the workspace indicator uses it to show numbers instead of icons.

> [!NOTE] In the original
> `GlobalStates.qml` sits in the config's root folder and has more flags (OSK, overlay, region selector, screen translator…). Its `onSidebarRightOpenChanged` marks notifications as read; the rebuild does that in the sidebar itself.

## Module 5: Hyprland commands

@include impulse/services/Hypr.qml

The same helper as in the Caelestia rebuild. ii's real code writes the Lua form directly (`hl.dsp.focus({workspace = …})`) because its own Hyprland config is Lua; the helper keeps the rebuild working with both styles.

## Module 6: Loading the theme

@include impulse/services/MaterialThemeLoader.qml

::: walk
@ 12 | Where colours come from
matugen writes `~/.local/state/impulse/colors.json` from the template in `extras/` (the original's file is `~/.local/state/quickshell/user/generated/colors.json`, written by its `switchwall.sh` script).
@ 14-22 | snake_case to m3camelCase
The file has keys like `on_primary_container`. A regex turns `_x` into `X` (`onPrimaryContainer`) and the `m3` prefix is added, matching the property names in `Appearance.m3colors`. Unknown keys are skipped. `darkmode` is worked out from the background's lightness.
@ 24-26 | Reapply
Singletons load lazily, so `shell.qml` calls `reapply()` at startup to read the file immediately.
@ 28-35 | Watching
Every time matugen rewrites the file, the colours update everywhere.
:::

## Module 7: Common widgets

@include impulse/modules/common/widgets/StyledText.qml

@include impulse/modules/common/widgets/MaterialSymbol.qml

`MaterialSymbol` animates its `fill` with the `elementMoveFast` preset, using the `createObject(this)` pattern from Module 2.

@include impulse/modules/common/widgets/RippleButton.qml

::: walk
@ 10-16 | Configurable colours
Every colour has a default from the layers but can be overridden per button: `colBackground` for a group button, `toggled` colours for active toggles.
@ 21-30 | The background
A rounded rectangle whose colour depends on toggled/hovered. `clip: true` keeps the ripple inside.
@ 32-43 | The ripple circle
A circle centred on the press point, starting at width 0 and invisible.
@ 46-50 | Starting the ripple
`pressX`/`pressY` (from `Button`) give the press position inside the button.
@ 52-59 | Spreading and fading
The circle grows to twice the button's diagonal while it flashes in and fades out: the Material ripple.
:::

@include impulse/modules/common/widgets/RoundCorner.qml

::: walk
@ 9-12 | Which corner
An `enum` for the four corners and a size.
@ 14-23 | One drawing, four corners
The shape is drawn once as a top-left corner. A `Scale` transform with `-1` flips it horizontally for right corners and vertically for bottom corners, around the shape's centre.
@ 25-33 | The concave shape
A square minus a quarter circle: from the top-left go right along the top, then arc counter-clockwise down to the left side. Filled with the bar's colour and placed under the bar, it makes the bar look like it melts into the screen.
:::

@include impulse/modules/common/widgets/CircularProgress.qml

A small ring for the bar's resource indicators and media progress, with a slot for content in the middle (`default property alias`).

## Module 8: System services

@include impulse/services/Audio.qml

@include impulse/services/Brightness.qml

@include impulse/services/MprisController.qml

@include impulse/services/ResourceUsage.qml

@include impulse/services/DateTime.qml

These mirror the Caelestia rebuild's services ([[ch:cae2-foundations]]) with ii's names: `MprisController.activePlayer`, `ResourceUsage.cpuUsage` / `memoryUsedPercentage`, `DateTime.time` / `date` / `uptime`. ii's real services folder has about fifty of these, from `Battery` and `Network` to `Weather`, `Todo` and `Ai`; each is a good template for adding your own.

## Practice

::: exercise warm | A layer 3
Add `colLayer3` (from `m3surfaceContainerHigh`) with hover/active variants to Appearance, for controls inside layer-2 items.
:::

::: exercise practice | Snappier shell
Make every "elementMove" animation 30% faster by changing one place.
--- solution
`elementMove: AnimPreset { duration: 350; … }`. Every `Behavior` that uses `elementMove.numberAnimation` follows, because each one creates its animation from the preset.
:::

::: exercise practice | Light mode
matugen can generate light schemes (`matugen image file.jpg -m light`). Generate one and check that `Appearance.m3colors.darkmode` becomes false (log it in `MaterialThemeLoader.applyColors`).
:::

::: exercise challenge | Automatic transparency
Like the original, compute the transparency from the wallpaper: use a [[ColorQuantizer]] with `depth: 0` on the wallpaper, take the vibrancy `(saturation + lightness) / 2`, and map it to 0–0.2.
:::
