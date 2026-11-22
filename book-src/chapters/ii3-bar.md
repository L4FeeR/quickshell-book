# end-4 3: The Bar

ii's bar is a full-width strip at the top with three **rounded groups** in the middle, a sidebar button and the window title on the left, and indicators and the tray on the right. In its default "hug" style, two concave corners hang under its ends so the bar seems to pour into the screen's rounded corners.

<div class="preview"><svg width="640" height="110" viewBox="0 0 640 110"><g font-size="10"><rect width="640" height="70" fill="#3a5a8c" opacity=".5"/><rect width="640" height="40" fill="#141218"/><path d="M0 40h23a23 23 0 0 0-23 23z" fill="#141218"/><path d="M640 40h-23a23 23 0 0 1 23 23z" fill="#141218"/><circle cx="20" cy="20" r="13" fill="#211f26"/><text x="20" y="24" fill="#e6e0e9" text-anchor="middle">✦</text><text x="42" y="16" fill="#938f99" font-size="8">firefox</text><text x="42" y="28" fill="#e6e0e9">Quickshell docs</text><g transform="translate(170 6)"><rect width="110" height="28" rx="12" fill="#1d1b20"/><circle cx="16" cy="14" r="9" fill="none" stroke="#4a4458" stroke-width="2.5"/><path d="M16 5 A9 9 0 0 1 24 18" stroke="#e8def8" stroke-width="2.5" fill="none"/><circle cx="38" cy="14" r="9" fill="none" stroke="#4a4458" stroke-width="2.5"/><text x="54" y="18" fill="#cac4d0" font-size="9">Midnight…</text><rect x="114" width="166" height="28" rx="12" fill="#1d1b20"/><rect x="118" y="2" width="50" height="24" rx="12" fill="#4a4458" opacity=".6"/><rect x="120" y="4" width="20" height="20" rx="10" fill="#d0bcff"/><g fill="#938f99" text-anchor="middle"><text x="156" y="18" fill="#e8def8">◉</text><text x="180" y="18">3</text><text x="200" y="18">4</text><text x="220" y="18">5</text><text x="240" y="18">6</text><text x="260" y="18">7</text></g><rect x="284" width="150" height="28" rx="12" fill="#1d1b20"/><text x="296" y="18" fill="#cac4d0">14:32 • Saturday, 21/11</text><text x="404" y="18" fill="#e6e0e9">▭ 81</text></g><rect x="556" y="6" width="76" height="28" rx="14" fill="#211f26"/><text x="594" y="24" fill="#e6e0e9" text-anchor="middle">2 🔔 ◉ ᛒ</text><text x="320" y="96" fill="#a6adc8" text-anchor="middle">left: sidebar button + window · centre: three groups · right: indicators (open the right sidebar) · corners hang under the bar</text></g></svg></div>

```text
modules/bar/  Bar  BarContent  BarGroup  ActiveWindow  Resources  Media  ClockWidget  UtilButtons  BatteryIndicator  SysTray
              (Workspaces gets its own chapter)
```

## Module 1: The bar window

@include impulse/modules/bar/Bar.qml

::: walk
@ 10-15 | One bar per monitor
A `Variants` over the screens, each creating a `PanelWindow`.
@ 17-22 | Styles and auto-hide
`hug` (style 0) adds the hanging corners, `floating` (style 1) puts the bar in a rounded rectangle with a gap around it. `mustShow` is true while the pointer is over the bar or Super is held, which is how the auto-hidden bar reveals itself.
@ 24-36 | Window setup
Top or bottom depending on the config. The window is taller than the bar by `screenRounding`, to make room for the hanging corners. With auto-hide on, the exclusive zone drops to 0 so windows use the whole screen while the bar is hidden.
@ 38-51 | Input only where it matters
The window's mask is `hoverArea`: the bar itself when shown, or a 2 px strip at the screen edge when auto-hidden. The corner area under the bar never blocks clicks.
@ 53-64 | Sliding
Everything visible is inside `slide`, which moves off-screen when auto-hidden. The `Behavior` uses the `elementMoveFast` preset through `createObject(this)`.
@ 66-75 | The content
`BarContent` is the actual bar (Module 2). In floating style it gets rounded corners and the gap as margins.
@ 77-92 | Hanging corners
Two `RoundCorner`s right under the bar's ends (or above them for a bottom bar), filled with the bar's colour. They make the bar and the screen corners read as one curved edge.
:::

> [!NOTE] In the original
> `modules/ii/bar/Bar.qml` is the same idea with more options: a "show bar when pressing Super" delay, a "push windows" option for auto-hide, dead-pixel workarounds, per-screen lists, and the corners implemented in `BarContent`. A separate `VerticalBar` exists for a vertical layout.

## Module 2: The layout

@include impulse/modules/bar/BarContent.qml

::: walk
@ 12-27 | Background and scrolling
The bar is a rectangle in `colLayer0`. A `MouseArea` that accepts no buttons catches the wheel: the **left half** changes brightness, the **right half** changes volume. This is one of ii's most-loved details: you never have to aim for a specific widget.
@ 29-53 | Left side
A round `RippleButton` that toggles the left sidebar (it turns primary-coloured while the sidebar is open), and the active window, which gets whatever width is left before the centre groups.
@ 55-73 | Centre: three groups
Each `BarGroup` is a rounded pill in `colLayer1` holding a few modules: resources and media; workspaces; clock, utility buttons and battery. Centring the middle group's `RowLayout` keeps the workspaces in the middle of the screen.
@ 75-109 | Right side
The tray, then one big button containing status indicators: muted icons only appear when muted, the unread notification count only when there are unread notifications. Clicking it toggles the right sidebar, and it turns primary while the sidebar is open.
:::

## Module 3: Groups

@include impulse/modules/bar/BarGroup.qml

A pill one layer up from the bar (`colLayer1`) that lays out whatever you put inside it. The `default property alias items: row.data` means children written inside `BarGroup { … }` go straight into the row.

## Module 4: The modules

@include impulse/modules/bar/ActiveWindow.qml

Two lines: the app id (small, dim) above the title, both elided to the space the layout gives them. With nothing focused it shows "Desktop / Workspace".

@include impulse/modules/bar/Resources.qml

Memory and CPU as tiny rings with an icon in the middle (`CircularProgress` from [[ch:ii2-foundations]]). The values come from the `ResourceUsage` service, which reads `/proc` every 3 seconds.

@include impulse/modules/bar/Media.qml

A ring showing track progress around a play/pause icon, then "title • artist". A `TapHandler` (not a `MouseArea`, which would take up a slot in the layout) handles left click = play/pause, middle = next, right = previous.

@include impulse/modules/bar/ClockWidget.qml

@include impulse/modules/bar/UtilButtons.qml

Small round buttons in `colLayer2` (they sit inside a layer-1 group): region screenshot to clipboard, colour picker (`hyprpicker -a` copies the picked colour) and microphone mute. They're built from an inline component, so each button is one line.

@include impulse/modules/bar/BatteryIndicator.qml

@include impulse/modules/bar/SysTray.qml

> [!NOTE] In the original
> Each module has a **popup** on hover (`ClockWidgetPopup`, `ResourcesPopup`, `BatteryPopup`, built on a shared `StyledPopup`), the media module opens a full media-controls panel, and `SysTray` collapses rarely used icons behind a chevron. Weather can also appear in the bar.

## Practice

::: exercise warm | Bottom bar
`qs -c impulse ipc call config set bar.bottom true`. Watch the bar and its corners move. Then try `bar.cornerStyle` 1 and 2.
:::

::: exercise practice | Hover popup for the clock
Show a calendar popup (`PopupWindow` anchored to the clock) when hovering the clock group, using `MonthGrid` from the right sidebar ([[ch:ii5-sidebars]]).
:::

::: exercise practice | Super shows the bar
With auto-hide on, show the bar while Super is held. (It's already in `mustShow`; check that the `workspaceNumber` keybind from `extras/hyprland.conf` is set, then explain why holding Super reveals the bar.)
--- solution
`mustShow` includes `GlobalStates.superDown`, which the `workspaceNumber` global shortcut sets on press and clears on release. Auto-hide checks `mustShow`, so the bar slides in while Super is held.
:::

::: exercise challenge | Collapsible tray
Hide tray items with `Status.Passive` behind a chevron button that expands the tray, like the original.
:::
