# lyne-dots 11: The Settings App

lyne-dots' big promise is "no config files to edit": almost everything is set from its own Settings window, applied live. Thanks to [[ch:ly2-state]], that's simpler than it sounds. Every setting is a key in `state.json`, and every row in the Settings app is a control bound to one key. This chapter builds the row types and the window.

<div class="preview"><svg width="620" height="300" viewBox="0 0 620 300"><g font-size="11"><rect width="620" height="300" rx="10" fill="#1a1b26"/><rect width="170" height="300" rx="10" fill="#24283b"/><text x="20" y="34" fill="#c0caf5" font-size="13" font-weight="700">Settings</text><rect x="10" y="50" width="150" height="28" rx="8" fill="#292e42"/><text x="22" y="68" fill="#7aa2f7">🎨</text><text x="44" y="68" fill="#c0caf5" font-weight="700">Appearance</text><text x="44" y="98" fill="#c0caf5">Bar</text><text x="44" y="126" fill="#c0caf5">Notifications</text><text x="44" y="154" fill="#c0caf5">OSD</text><text x="44" y="182" fill="#c0caf5">Idle and lock</text><text x="44" y="210" fill="#c0caf5">Wallpaper</text><text x="190" y="36" fill="#c0caf5" font-size="14" font-weight="700">Bar</text><rect x="190" y="50" width="410" height="40" rx="8" fill="#24283b"/><text x="204" y="74" fill="#c0caf5">Style</text><rect x="340" y="58" width="250" height="24" rx="12" fill="#292e42"/><text x="352" y="74" fill="#c0caf5" font-size="10">Docked</text><rect x="398" y="60" width="60" height="20" rx="10" fill="#7aa2f7"/><text x="408" y="74" fill="#1a1b26" font-size="10">Corners</text><text x="468" y="74" fill="#c0caf5" font-size="10">Floating  Islands</text><rect x="190" y="98" width="410" height="40" rx="8" fill="#24283b"/><text x="204" y="122" fill="#c0caf5">Height</text><text x="410" y="122" fill="#a9b1d6" font-size="10">36 px</text><rect x="450" y="115" width="140" height="6" rx="3" fill="#414868"/><rect x="450" y="115" width="70" height="6" rx="3" fill="#7aa2f7"/><circle cx="520" cy="118" r="8" fill="#c0caf5"/><text x="380" y="122" fill="#a9b1d6">⟲</text><rect x="190" y="146" width="410" height="48" rx="8" fill="#24283b"/><text x="204" y="166" fill="#c0caf5">Auto-hide</text><text x="204" y="182" fill="#545c7e" font-size="9">Slides away; touch the screen edge to bring it back</text><rect x="546" y="157" width="44" height="24" rx="12" fill="#414868"/><circle cx="558" cy="169" r="9" fill="#c0caf5"/><text x="200" y="230" fill="#a9b1d6" font-size="10">⟲ = this value differs from defaults.json; click to reset it</text></g></svg></div>

## Why it's easy

A Settings row needs to do three things: show the current value, change it, and update when it changes elsewhere. With `StateService`:

```qml
value: StateService.get("bar.height", 33)       // show, and stay in sync
onMoved: v => StateService.set("bar.height", v) // change: saved, and the bar follows
```

So each row type only needs to know its **key path**. The rest of the shell already reads the same keys through `Config`, so a change in Settings appears everywhere the moment you make it.

## The row frame

@include lyne/modules/settings/SettingRow.qml

::: walk
@ 13-17 | Inputs
The key path, a title, an optional description, and the control (whatever is placed inside the row). `value` is the key's current value, live.
@ 20 | Height
At least 56 px, taller for a long description.
@ 29-35 | Title and description
The description is muted and wraps.
@ 36-40 | Reset
Shown only when the value differs from `defaults.json` (`isDefault`, [[ch:ly2-state]]). Clicking it puts the default back. You always know what you've changed, and can undo it.
@ 41-45 | The control slot
Children of the row go here, on the right. Each row type below places its control in this slot.
:::

## Three row types

@include lyne/modules/settings/SwitchRow.qml

::: walk
@ 6-8 | A row with a switch
A `SettingRow` whose value is on or off.
@ 10-15 | The track
Accent when on, grey when off.
@ 16-24 | The knob
Slides from left to right.
@ 25 | Clicking
Writes the opposite value to the key. Nothing else: the knob moves because `value` changed.
:::

@include lyne/modules/settings/ChoiceRow.qml

::: walk
@ 7-10 | Options
A list of `[value, label]` pairs, like `[["top", "Top"], ["bottom", "Bottom"]]`.
@ 12-17 | A segmented control
A rounded track holding one segment per option.
@ 22-36 | A segment
Accent-filled when it's the current value; a click writes its value to the key.
:::

@include lyne/modules/settings/SliderRow.qml

::: walk
@ 10-14 | Range
`from`, `to`, the `step` to round to, a unit for the label, and `factor` for showing a value differently from how it's stored: opacity is stored as 0.9 and shown as 90% (`factor: 100`), timeouts are stored in milliseconds and shown in seconds (`factor: 0.001`).
@ 18-25 | The label
The value times the factor, rounded to two decimals, with its unit.
@ 26-48 | Track, fill and knob
Positioned by the value's place between `from` and `to`.
@ 50-58 | Dragging
Turn the pointer position into a value, round it to the step, and write it. `toFixed(4)` removes floating-point noise: 0.1 + 0.2 is 0.30000000000000004 in JavaScript, and nobody wants that in their `state.json`. Every write is saved by `StateService` a moment after you stop dragging.
:::

## The window

@include lyne/modules/settings/SettingsWindow.qml

::: walk
@ 11-19 | A normal window
A [[FloatingWindow]], not a layer-shell panel: it can stay open, be moved and resized while you try things. Its title lets Hyprland float and centre it ([[ch:ly12-assemble]]). Closing it with its own close button tells the service.
@ 21-28 | The pages
Id, label and icon for the sidebar.
@ 34-79 | The sidebar
The logo and title, one entry per page (lit when current), and at the bottom a reminder of where everything is saved.
@ 81-97 | The page area
A scrollable area with a `Loader` showing the current page's component.
@ 99-103 | Headings
A larger bold label between groups of rows.
@ 106-152 | Appearance
A tile for every theme, **painted in that theme's own colours** from `ThemeService.list`, so you see each theme before choosing it. Then the fade switch, opacity, corner radii, text size and animation speed. Each line is one row bound to one key.
@ 155-169 | Bar
Style, position, height, the floating gap, auto-hide, the workspace style and count.
@ 171-181 | Notifications
Do not disturb, popup time (stored in ms, shown in seconds), maximum popups, width.
@ 183-191 | OSD
Style and how long it stays.
@ 193-204 | Idle and lock
Caffeine, lock and screen-off timeouts (stored in seconds, shown in minutes), and the power menu's countdown.
@ 206-223 | Wallpaper
A plain `SettingRow` with a button inside: the row frame works with any control.
:::

## Adding a setting, start to finish

Every new setting follows the same four steps. Here's "bar height when floating":

1. **Default**: add it to `defaults.json` → `"bar": { …, "floatingHeight": 30 }`.
2. **Token**: read it in `Config` → `readonly property int barFloatingHeight: getState("bar.floatingHeight", 30)`.
3. **Use**: use the token where it matters → `height: Config.barFloating ? Config.barFloatingHeight : Config.barHeight`.
4. **Row**: add a row → `SliderRow { path: "bar.floatingHeight"; title: "Floating height"; from: 24; to: 48; step: 1; unit: " px" }`.

That's how lyne grew to 27 pages without becoming hard to maintain.

> [!NOTE] In the original
> lyne's `modules/settings/` has 27 pages, a search over every row (each row registers its title and keywords), live previews of bar, launcher, OSD and lock templates, a monitor arrangement map with a "keep these settings?" countdown, a keybind editor that records keys, and a theme creator with an OKLCH colour picker. Hyprland settings are written to `~/.config/hypr/local/settings.lua`, which the Lua config loads.

## Practice

::: exercise warm | Use it
Open Settings (Super+I) and change the corner radius, the bar style and the workspace style. Look at `~/.config/lyne/state.json` afterwards, then reset one value with its ⟲ button.
:::

::: exercise practice | A text row
Make a `TextRow` with a text field that saves on Enter, and use it for `typography.font`.
--- solution
```qml
// TextRow.qml
import QtQuick
import qs.config
import qs.services
SettingRow {
    id: root
    Rectangle {
        width: 220; height: 32; radius: 16; color: Config.surface1Color
        TextInput {
            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
            verticalAlignment: TextInput.AlignVCenter
            color: Config.textColor; font.family: Config.font
            text: root.value ?? ""
            onAccepted: StateService.set(root.path, text)
        }
    }
}
```
:::

::: exercise practice | Follow the four steps
Add a setting for the launcher's width, through all four steps.
:::

::: exercise challenge | Search
Add a search field above the sidebar. Give each page a list of `{ title, keywords }` for its rows, and show matching rows' titles as results that switch to their page.
:::
