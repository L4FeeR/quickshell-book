# Caelestia 5: The Dashboard

Touch the top edge of the screen and Caelestia's dashboard drops out of the frame: a tabbed panel with your profile, a big clock, a calendar, media and system resources. It's a good model for any large panel: **tabs, cards and a panel that resizes to fit**.

<div class="preview"><svg width="620" height="300" viewBox="0 0 620 300"><g font-size="11"><rect width="620" height="12" fill="#141218"/><path d="M60 12 A25 25 0 0 1 85 37 V250 A28 28 0 0 0 113 278 H507 A28 28 0 0 0 535 250 V37 A25 25 0 0 1 560 12Z" fill="#141218"/><g transform="translate(180 30)"><text x="0" y="12" fill="#d0bcff">▣ Dashboard</text><text x="100" y="12" fill="#cac4d0">♫ Media</text><text x="180" y="12" fill="#cac4d0">◷ Performance</text><rect x="8" y="20" width="70" height="3" rx="1.5" fill="#d0bcff"/></g><g transform="translate(105 64)"><rect width="250" height="76" rx="16" fill="#211f26"/><circle cx="40" cy="38" r="26" fill="#4f378b"/><text x="80" y="34" fill="#e6e0e9" font-size="14">alex</text><text x="80" y="52" fill="#cac4d0">up 3h 12m</text><rect x="258" width="70" height="150" rx="16" fill="#211f26"/><text x="293" y="50" fill="#d0bcff" font-size="28" text-anchor="middle">14</text><text x="293" y="72" fill="#938f99" text-anchor="middle">•••</text><text x="293" y="104" fill="#d0bcff" font-size="28" text-anchor="middle">32</text><rect y="84" width="150" height="120" rx="16" fill="#211f26"/><text x="75" y="104" fill="#e6e0e9" text-anchor="middle">November 2026</text><g fill="#cac4d0" font-size="9"><text x="14" y="124">1 2 3 4 5 6 7</text><text x="14" y="140">8 9 10 11 12 13 14</text><text x="14" y="156">15 16 17 18 19 20</text></g><circle cx="118" cy="153" r="8" fill="#d0bcff"/><rect x="158" y="84" width="92" height="120" rx="16" fill="#211f26"/><rect x="172" y="100" width="8" height="80" rx="4" fill="#36343b"/><rect x="172" y="140" width="8" height="40" rx="4" fill="#d0bcff"/><rect x="194" y="100" width="8" height="80" rx="4" fill="#36343b"/><rect x="194" y="120" width="8" height="60" rx="4" fill="#d0bcff"/><rect x="216" y="100" width="8" height="80" rx="4" fill="#36343b"/><rect x="216" y="160" width="8" height="20" rx="4" fill="#d0bcff"/></g><text x="310" y="296" fill="#a6adc8" text-anchor="middle">user card · big clock · calendar · resources (now playing appears below while music plays)</text></g></svg></div>

```text
modules/dashboard/  Content  Card  Dash  Calendar  Media  Performance
```

The drawer itself was set up in [[ch:cae3-frame]] (`Panels.qml` puts `Dashboard.Content` in a top-edge `DrawerWrapper`). This chapter builds what goes inside.

## Module 1: Tabs and a resizing panel

@include cae/modules/dashboard/Content.qml

::: walk
@ 12-15 | State
`current` is the selected tab; `pages` lists the three page items so the panel can read the current one's size.
@ 17-21 | The panel fits the page
The panel is as large as the current page plus the tab row and padding. Both sizes have a `Behavior`, so switching tabs **morphs** the drawer, and because the frame background follows the drawer's size, the whole shape flows to the new size.
@ 23-24 | Only poll when visible
`SysInfo` reads CPU and memory every 2 seconds, but only while someone needs it. The dashboard adds itself to `refCount` when shown and removes itself when hidden, so a closed dashboard costs nothing. `shown` comes from the wrapper's `visible` (set in `Panels.qml`).
@ 26-64 | Tab buttons
Each tab is an icon plus a label inside an `Item` with a `StateLayer`. The selected tab gets a filled icon and the primary colour.
@ 66-78 | The sliding underline
One rectangle under the tab row, positioned at the selected tab (found with `tabButtons.itemAt()`). Its `x` and `width` animate, so it slides and stretches between tabs of different widths.
@ 80-90 | Pages
All three pages exist; only the current one is visible, and pages fade in. Keeping them alive means switching back is instant and media positions don't reset.
:::

## Module 2: Cards

@include cae/modules/dashboard/Card.qml

One tonal container for every tile: large rounding and the `surfaceContainer` colour, one step lighter than the panel. Material 3 uses these "surface container" steps instead of shadows to separate content.

## Module 3: The dashboard tab

@include cae/modules/dashboard/Dash.qml

A `GridLayout` with three columns arranges the cards:

| Row | Cards |
|---|---|
| 1 | user card (spans 2 columns), big clock (spans 2 rows) |
| 2 | calendar, resources |
| 3 | now playing (spans 3 columns, only while a player exists) |

Things worth noticing:

- The **avatar** reads `~/.face` (the standard profile picture path, also used by login managers) inside a round `ClippingRectangle`.
- The **big clock** is vertical, like the bar's clock: hours, three dots, minutes, then the date.
- The **resource bars** grow from the bottom (`anchors.bottom: parent.bottom`, `height = full * value`) and turn red above 85%.
- The **media art** spins slowly while music plays, like a record, and stops where it is when paused.

## Module 4: The calendar

@include cae/modules/dashboard/Calendar.qml

::: walk
@ 10-12 | The month to show
`monthOffset` moves months forward and back. `first` is the 1st of the shown month, and `lead` is how many cells come before it in a Monday-first week (`getDay()` is 0 for Sunday, so `(day + 6) % 7` makes Monday 0).
@ 38-58 | 42 day cells
Six weeks × seven days always covers any month. Each cell computes its date as "first of month + index - lead"; `Date` handles overflow, so index -2 becomes the end of the previous month and 35 the next month's start. Days outside the month are dimmed; today gets a filled circle.
@ 61-63 | Scroll to change month
A wheel up goes back a month, down goes forward.
:::

## Module 5: The media tab

@include cae/modules/dashboard/Media.qml

A large cover, title, artist and album, a seek slider (only enabled when the player supports seeking), controls with a big play/pause button, and a row of chips for every MPRIS player. Clicking a chip sets `Players.manual`, which makes that player "active" everywhere: the dashboard, the bar and the lock screen.

## Module 6: The performance tab

@include cae/modules/dashboard/Performance.qml

Four 270° rings (open at the bottom, like a speedometer). `startAngle: 135` starts the arc at the bottom-left; `sweepAngle: 270 * value` fills it clockwise. Each ring animates through a `shown` property with the slow spatial curve, so the arcs glide instead of jumping every two seconds.

> [!NOTE] In the original
> `modules/dashboard/` has `Dash.qml` with `dash/User.qml`, `DateTime.qml`, `Calendar.qml`, `Media.qml` (a circular progress around the cover), `Resources.qml` and `SmallWeather.qml`; `Media.qml` is a full media page with a lyrics-style layout and visualiser; `Performance.qml` has GPU, network and storage cards; there's also a `WeatherTab.qml`. Tabs use a custom animated tab bar from the components folder.

## Practice

::: exercise warm | Default tab
Make the dashboard remember the last tab you opened (store `current` in a `PersistentProperties` so it survives reloads).
:::

::: exercise practice | Weather card
Add a weather card to the Dash grid using wttr.in (see the weather card in [[ch:g5-desktop]]). Put it under the clock.
:::

::: exercise practice | GPU ring
Add a GPU ring to the performance tab using the vendor detection from the GPU widget in [[ch:g2-system-monitors]], and only create it when a supported GPU exists.
:::

::: exercise challenge | Keyboard tabs
When the dashboard is opened with its keybind, let ← and → switch tabs. You'll need keyboard focus for the drawers window while the dashboard is open (look at how `ContentWindow` requests focus for the launcher).
--- hint
Add `screenState.dashboard` to the `keyboardFocus` condition, give `Content` `focus: true`, and handle `Keys.onLeftPressed` / `Keys.onRightPressed`. Remember that hover-opening shouldn't steal focus from your apps, so only request focus when it was opened by the shortcut.
:::
