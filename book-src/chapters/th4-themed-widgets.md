# Theming 4: Making Widgets Themeable

A theme switcher is only as good as the widgets that follow it. One hard-coded `"#1e1e2e"` and that widget stays dark while the rest of the shell turns light. This chapter builds four small base widgets that make following the theme automatic, gives the rules that keep a whole shell themeable, and walks through a demo bar that uses every role.

```text
widgets/  TRect  TText  Icon  IconButton  DemoBar
```

## The rules

1. **Never write a colour in a widget.** Write a role: `Theme.colors.surface`, not `"#181825"`. (The only exception is a theme preview, which shows *another* theme's colours on purpose.)
2. **Pick roles by purpose, not by look.** The active workspace is `primary` because it's the thing that's selected, not because you like purple there.
3. **Put text on its matching role**: `text`/`textMuted` on `background`, `surface` and `surfaceHigh`; `onPrimary` on `primary`.
4. **Fade colour changes.** Give coloured items a `Behavior on color`. Then switching themes is a smooth 400 ms crossfade instead of a flash.
5. **Derive, don't invent.** Need a softer accent? `Theme.alpha(Theme.colors.primary, 0.15)`. A hover colour? `Theme.mix(Theme.colors.surface, Theme.colors.text, 0.08)`. These work in every theme.

## Module 1: A rectangle that fades

@include theming/widgets/TRect.qml

::: walk
@ 4-5 | Transparent by default
Most rectangles in a shell are containers that get a role colour; starting transparent avoids accidental white boxes.
@ 6-8 | Fade the fill
Whenever `color` changes (a theme switch, hover, selection), animate to the new colour over 400 ms with `OutCubic`: fast at first, gentle at the end.
@ 9-11 | Fade the outline too
`border.color` is a separate property and needs its own `Behavior`.
:::

## Module 2: Text that follows the theme

@include theming/widgets/TText.qml

::: walk
@ 2 | The theme service
Importing `qs.services` gives access to `Theme`.
@ 6 | Default colour
The theme's text colour. Override it where needed (`color: Theme.colors.textMuted`).
@ 7-8 | Font
One font for the whole kit. A real shell would take it from a design token ([[ch:43-design-system]]).
@ 9-11 | Fade
Text fades with the backgrounds, so nothing jumps during a switch.
:::

## Module 3: Icons

@include theming/widgets/Icon.qml

An icon is just text in the Material Symbols font, so it inherits `TText`'s colour and fade. `fill` uses the font's variable `FILL` axis: 0 for outlined, 1 for filled.

## Module 4: An icon button

@include theming/widgets/IconButton.qml

::: walk
@ 8-11 | The button's interface
`icon` (an alias to the label's text), `active` (selected state), an optional `tooltip` text, and a `clicked` signal.
@ 13-16 | Three states, three roles
Active: `primary`. Hovered: `surfaceHigh`, the "raised" role. Otherwise transparent. Because the component is a `TRect`, moving between these states fades too.
@ 18-23 | The icon
Filled and in `onPrimary` when active (rule 3: text on primary uses onPrimary), outlined in `text` otherwise.
@ 24-25 | Input
A hand cursor on hover, and a tap emits `clicked`.
:::

## Module 5: A bar that shows off the theme

@include theming/widgets/DemoBar.qml

::: walk
@ 9-20 | One bar per screen
`Variants` makes one `PanelWindow` for each monitor. The window itself is transparent; the visible bar is the rectangle inside, so it can have rounded corners and a margin.
@ 22-29 | The bar's body
`background` with a `border` outline. These two roles alone already make the bar match the theme.
@ 37-50 | The theme's name on the accent
A pill in `primary` with an icon and the theme name in `onPrimary`. The icon switches between a moon and a sun with the variant.
@ 51 | The family
Secondary information, so `textMuted`.
@ 55-70 | All seven accents
A raised group (`surfaceHigh`) with one dot per accent role. `Theme.colors[modelData]` reads a role by name, so the list of names is all the `Repeater` needs.
@ 74-78 | A clock
Plain `text` colour.
@ 79-82 | Theme controls
Previous and next theme, the light/dark twin, and the picker (the button is `active` while the picker is open).
:::

<div class="preview"><svg width="640" height="150" viewBox="0 0 640 150"><g font-size="11"><g transform="translate(10 10)"><rect width="620" height="36" rx="12" fill="#1e1e2e" stroke="#45475a"/><rect x="8" y="5" width="170" height="26" rx="13" fill="#cba6f7"/><text x="22" y="22" fill="#1e1e2e">☾  Catppuccin Mocha</text><text x="188" y="22" fill="#a6adc8">Catppuccin</text><rect x="250" y="5" width="140" height="26" rx="13" fill="#313244"/><g transform="translate(262 12)"><circle cx="6" cy="6" r="6" fill="#f38ba8"/><circle cx="24" cy="6" r="6" fill="#fab387"/><circle cx="42" cy="6" r="6" fill="#f9e2af"/><circle cx="60" cy="6" r="6" fill="#a6e3a1"/><circle cx="78" cy="6" r="6" fill="#94e2d5"/><circle cx="96" cy="6" r="6" fill="#89b4fa"/><circle cx="114" cy="6" r="6" fill="#f5c2e7"/></g><text x="470" y="22" fill="#cdd6f4">14:32   ‹  ›  ◐  🎨</text></g><g transform="translate(10 60)"><rect width="620" height="36" rx="12" fill="#e1e2e7" stroke="#a1a6c5"/><rect x="8" y="5" width="170" height="26" rx="13" fill="#2e7de9"/><text x="22" y="22" fill="#e1e2e7">☀  Tokyo Night Day</text><text x="188" y="22" fill="#6172b0">Tokyo Night</text><rect x="250" y="5" width="140" height="26" rx="13" fill="#c4c8da"/><g transform="translate(262 12)"><circle cx="6" cy="6" r="6" fill="#f52a65"/><circle cx="24" cy="6" r="6" fill="#b15c00"/><circle cx="42" cy="6" r="6" fill="#8c6c3e"/><circle cx="60" cy="6" r="6" fill="#587539"/><circle cx="78" cy="6" r="6" fill="#007197"/><circle cx="96" cy="6" r="6" fill="#2e7de9"/><circle cx="114" cy="6" r="6" fill="#9854f1"/></g><text x="470" y="22" fill="#3760bf">14:32   ‹  ›  ◐  🎨</text></g><g transform="translate(10 110)"><rect width="620" height="36" rx="12" fill="#282828" stroke="#504945"/><rect x="8" y="5" width="170" height="26" rx="13" fill="#fe8019"/><text x="22" y="22" fill="#282828">☾  Gruvbox Dark</text><text x="188" y="22" fill="#a89984">Gruvbox</text><rect x="250" y="5" width="140" height="26" rx="13" fill="#3c3836"/><g transform="translate(262 12)"><circle cx="6" cy="6" r="6" fill="#fb4934"/><circle cx="24" cy="6" r="6" fill="#fe8019"/><circle cx="42" cy="6" r="6" fill="#fabd2f"/><circle cx="60" cy="6" r="6" fill="#b8bb26"/><circle cx="78" cy="6" r="6" fill="#8ec07c"/><circle cx="96" cy="6" r="6" fill="#83a598"/><circle cx="114" cy="6" r="6" fill="#d3869b"/></g><text x="470" y="22" fill="#ebdbb2">14:32   ‹  ›  ◐  🎨</text></g></g></svg></div>

*The same bar in three themes. Not a single line of the bar changes; only the theme file does.*

## Converting an existing widget

Taking a widget from elsewhere in the book (or from your config) and making it themeable is mechanical:

```qml
// before
Rectangle {
    color: "#313244"
    Text { text: "CPU"; color: "#cdd6f4" }
    Rectangle { width: parent.width * usage; color: usage > 0.8 ? "#f38ba8" : "#cba6f7" }
}

// after
TRect {
    color: Theme.colors.surfaceHigh
    TText { text: "CPU" }                           // text colour by default
    TRect { width: parent.width * usage; color: usage > 0.8 ? Theme.colors.error : Theme.colors.primary }
}
```

1. Replace `Rectangle` with `TRect` and `Text` with `TText`.
2. Replace each hex colour with the role that matches its **purpose** (the role table in [[ch:th1-colour-basics]]).
3. Search for leftovers: `grep -rn '"#' widgets/` should find nothing except intentional previews.

## Practice

::: exercise warm | A battery chip
Write a themeable battery chip: `surfaceHigh` background, `text` percentage, and a fill in `success`, `warning` or `error` depending on the level.
:::

::: exercise practice | Show the tooltip
`IconButton` has a `tooltip` property but doesn't show it yet. Add a small `TRect` in `surfaceHigh` with `TText` that appears above the button after a 500 ms hover.
:::

::: exercise practice | A themed slider
Build a volume slider whose track is `surfaceHigh`, fill `primary`, and handle `onPrimary` with a `primary` border.
:::

::: exercise challenge | Convert a gallery widget
Take the "Live Network Speed" widget from [[ch:g2-system-monitors]] and convert it to the theme roles following the steps above. Then switch between Catppuccin Latte and Tokyo Night and check it reads well in both.
:::
