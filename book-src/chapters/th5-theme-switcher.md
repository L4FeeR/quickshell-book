# Theming 5: The Theme Switcher

Now the part you see: a **picker window** with every installed theme as a card. Hover a card and the whole shell previews that theme; click to keep it. It also has search, a dark/light filter, keyboard control, the light/dark twin button and automatic day/night switching. Keybinds open it and cycle themes from anywhere.

<div class="preview"><svg width="640" height="360" viewBox="0 0 640 360"><g font-size="11"><rect width="640" height="360" rx="14" fill="#1a1b26"/><text x="20" y="38" fill="#7aa2f7" font-size="20">🎨</text><text x="48" y="38" fill="#c0caf5" font-size="18">Themes</text><text x="122" y="38" fill="#a9b1d6">19 installed</text><rect x="300" y="20" width="44" height="26" rx="13" fill="#7aa2f7"/><text x="312" y="37" fill="#1a1b26">All</text><rect x="350" y="20" width="50" height="26" rx="13" fill="#292e42"/><text x="362" y="37" fill="#c0caf5">Dark</text><rect x="406" y="20" width="52" height="26" rx="13" fill="#292e42"/><text x="418" y="37" fill="#c0caf5">Light</text><rect x="466" y="18" width="160" height="30" rx="15" fill="#16161e" stroke="#414868"/><text x="480" y="37" fill="#565f89">Search themes</text><g transform="translate(20 64)"><rect width="140" height="104" rx="12" fill="#303446" stroke="#414559"/><rect x="10" y="10" width="120" height="48" rx="7" fill="#292c3c"/><rect x="104" y="40" width="24" height="12" rx="6" fill="#ca9ee6"/><text x="10" y="94" fill="#c6d0f5" font-size="10">Catppuccin Frappé</text><rect x="150" width="140" height="104" rx="12" fill="#eff1f5" stroke="#bcc0cc"/><rect x="160" y="10" width="120" height="48" rx="7" fill="#e6e9ef"/><rect x="254" y="40" width="24" height="12" rx="6" fill="#8839ef"/><text x="160" y="94" fill="#4c4f69" font-size="10">Catppuccin Latte</text><rect x="300" width="140" height="104" rx="12" fill="#1e1e2e" stroke="#cba6f7" stroke-width="3"/><rect x="310" y="10" width="120" height="48" rx="7" fill="#181825"/><rect x="404" y="40" width="24" height="12" rx="6" fill="#cba6f7"/><text x="310" y="94" fill="#cdd6f4" font-size="10">Catppuccin Mocha</text><rect x="450" width="140" height="104" rx="12" fill="#1a1b26" stroke="#a9b1d6" stroke-width="2" transform="scale(1)"/><rect x="460" y="10" width="120" height="48" rx="7" fill="#16161e"/><rect x="554" y="40" width="24" height="12" rx="6" fill="#7aa2f7"/><text x="460" y="94" fill="#c0caf5" font-size="10">Tokyo Night ← hovered</text></g><g transform="translate(20 184)" opacity=".85"><rect width="140" height="104" rx="12" fill="#282828"/><rect x="150" width="140" height="104" rx="12" fill="#2e3440"/><rect x="300" width="140" height="104" rx="12" fill="#191724"/><rect x="450" width="140" height="104" rx="12" fill="#faf4ed"/></g><text x="20" y="330" fill="#a9b1d6">Previewing Tokyo Night (click to keep)</text><text x="470" y="330" fill="#9ece6a">contrast 11.5:1</text><text x="580" y="330" fill="#c0caf5">◐  ⏲</text></g></svg></div>

*Hovering Tokyo Night previews it on the picker itself (and the whole shell); Mocha keeps its "selected" outline until you click.*

```text
widgets/  ThemeCard  ThemePicker
services/ Ui
shell.qml
```

## Module 1: The theme card

Each card draws **its own** theme, so you can compare themes side by side without switching.

@include theming/widgets/ThemeCard.qml

::: walk
@ 9-11 | Inputs
The theme object to draw, and two states set by the picker: `selected` (it's the chosen theme) and `hovered`.
@ 13-16 | This card's colours
`c("surface")` resolves a role **for this card's theme**, using the same `Theme.resolve()` the service uses. This is the one place where a widget deliberately doesn't use `Theme.colors`.
@ 18-26 | The card
The theme's background. The outline is thick and in the theme's own primary when selected, medium when hovered, thin otherwise. Hovering also scales the card up 3%.
@ 28-34 | A mini window
A `surface` panel inside the card, like an app window.
@ 36-48 | Its title bar
`surfaceHigh` with three "traffic light" dots in red, yellow and green.
@ 49-55 | Text lines
Three bars in the three text roles (`text`, `textMuted`, `textFaint`), so you see the theme's text hierarchy at a glance.
@ 56-61 | An accent button
`primary` with "Aa" in `onPrimary`: this checks the theme's most important pairing.
@ 64-72 | Accent swatches
The seven accent roles in order.
@ 74-85 | Name
The theme's name in its own text colour, elided if long.
@ 86-91 | Light or dark badge
☀ or ☾ from the variant.
:::

The image at the top of [[ch:th1-colour-basics]] is this component, rendered for all 19 themes.

## Module 2: The picker window

@include theming/widgets/ThemePicker.qml

::: walk
@ 9-11 | Only exists while open
A `LazyLoader` creates the window when `Ui.pickerOpen` becomes true and destroys it when it turns false, so the picker costs nothing while closed.
@ 13-19 | The window and what it shows
A normal app window ([[FloatingWindow]]). `filter` is the dark/light chip; `shown` is the theme list filtered by variant and by the search text (matching name or family, ignoring case).
@ 21-25 | Size and colour
Resizable down to 480×400. Its background is the theme's background, so the picker itself previews themes too.
@ 27 | Closing
Closing the window (✕ or Esc) ends any preview and marks the picker closed. Without resetting `previewId`, closing while hovering a card would leave the shell showing a theme you didn't choose.
@ 29 | Fade
Even the window background fades between themes.
@ 41-44 | Title
An icon, the title and the number of installed themes.
@ 46-62 | Filter chips
Three pills; the selected one is `primary`. Tapping sets `win.filter`, and `shown` updates by itself.
@ 64-89 | Search
A text field in a `surface` pill whose outline turns `primary` when focused. It has focus as soon as the window opens, so you can type immediately. The arrow keys move the selection in the grid, Enter applies the selected theme, Esc closes.
@ 93-102 | The grid
A `GridView` with as many columns as fit (each cell about 216 px wide). It starts with the chosen theme selected.
@ 104 | Keyboard previews
When the selection moves with the keyboard (the grid or search field has focus), preview that theme, just like hovering.
@ 106-118 | One card per theme
Centred in its cell, with `selected` and `hovered` worked out from the current state.
@ 119-126 | Hover to preview
Entering a card sets `Theme.previewId`; leaving clears it, but only if no other card has taken over in the meantime, so moving quickly from card to card never flickers back to the chosen theme.
@ 127-129 | Click to keep
`Theme.set()` saves the theme and ends the preview.
@ 134-141 | Status
"Previewing …" during a preview, otherwise the current theme (and whether automatic switching is on).
@ 142-145 | Contrast readout
The current theme's text/background contrast, green at 7:1 or more, yellow below.
@ 146-147 | Twin and schedule
The light/dark twin button, and a toggle for automatic day/night switching (it's `active` while the schedule is on).
:::

## Module 3: Small state and the entry point

@include theming/services/Ui.qml

One flag for the picker, plus an IPC toggle: `qs -c theming ipc call picker toggle`.

@include theming/shell.qml

::: walk
@ 1-3 | Pragmas
Native tray menus, no reload popup, and the Basic controls style (so the search field can be restyled).
@ 13-14 | The two visible parts
The demo bar on every screen and the picker (hidden until opened).
@ 17 | Start the exporter
Singletons are created the first time something uses them. Reading any property of `ThemeExport` at startup creates it, so it exports the theme from the first second ([[ch:th7-beyond-the-shell]]).
@ 19-21 | Global shortcuts
Three Hyprland global shortcuts: `theming:picker`, `theming:next` and `theming:toggleVariant`.
:::

## Keybinds

@include theming/extras/hyprland.conf

| Keys | Action |
|---|---|
| Super + T | open or close the picker |
| Super + Shift + T | next theme |
| Super + Alt + T | jump to the light or dark twin |

## Automatic day/night switching

Click the schedule button in the picker (or run `qs -c theming ipc call theme auto true`). From then on the shell uses `dayTheme` from 7:00 and `nightTheme` from 19:00 (Catppuccin Latte and Mocha by default). Choosing a theme by hand turns the schedule off again, because a manual choice means you want that theme now.

## Practice

::: exercise warm | Open on Super+T
Add the keybinds above to your Hyprland config, run `qs -c theming`, and cycle through all 19 themes with Super+Shift+T.
:::

::: exercise practice | Favourites
Add a ★ to each card. Store favourite ids in `Theme.settings` (add `property list<string> favourites: []` to the adapter), show a "★ Favourites" filter chip, and make Super+Shift+T cycle only through favourites when there are any.
:::

::: exercise practice | A quick switcher in the bar
Clicking the theme-name pill in the bar should open a small `PopupWindow` listing the themes of the current family (all Catppuccin flavours, say) for one-click switching.
:::

::: exercise challenge | Smooth previews with a delay
Previewing every card your pointer crosses can be busy. Only preview after the pointer rests on a card for 150 ms.
--- hint
Give each cell a `Timer { interval: 150; onTriggered: Theme.previewId = cell.modelData.id }`, start it when hovered, stop it when not.
:::
