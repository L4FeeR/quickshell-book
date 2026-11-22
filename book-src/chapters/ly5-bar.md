# lyne-dots 5: The Bar

lyne's bar has three groups: **left** (logo, workspaces, window title), **centre** (the clock) and **right** (tray, status icons, bell). It comes in four styles you switch from Settings without restarting, and it can sit at the top or bottom and hide itself. This chapter builds the bar window and every button on it.

<div class="preview"><svg width="640" height="250" viewBox="0 0 640 250"><g font-size="10"><g transform="translate(0 6)"><rect width="640" height="26" fill="#1a1b26"/><text x="560" y="17" fill="#a9b1d6">docked</text></g><g transform="translate(0 50)"><rect width="640" height="26" fill="#1a1b26"/><path d="M0 26h14a14 14 0 0 0-14 14z" fill="#1a1b26"/><path d="M640 26h-14a14 14 0 0 1 14 14z" fill="#1a1b26"/><text x="530" y="17" fill="#a9b1d6">docked-corners (default)</text></g><g transform="translate(0 110)"><rect x="8" y="6" width="624" height="26" rx="13" fill="#1a1b26"/><text x="560" y="23" fill="#a9b1d6">floating</text></g><g transform="translate(0 165)"><rect x="8" y="4" width="200" height="22" rx="11" fill="#1a1b26"/><rect x="270" y="4" width="100" height="22" rx="11" fill="#1a1b26"/><rect x="440" y="4" width="192" height="22" rx="11" fill="#1a1b26"/><text x="470" y="19" fill="#a9b1d6">islands</text></g><g fill="#7aa2f7"><rect x="40" y="13" width="22" height="10" rx="5"/><rect x="40" y="57" width="22" height="10" rx="5"/><rect x="48" y="122" width="22" height="10" rx="5"/><rect x="40" y="174" width="22" height="10" rx="5"/></g><g fill="#414868"><circle cx="72" cy="18" r="5"/><circle cx="72" cy="62" r="5"/><circle cx="80" cy="127" r="5"/><circle cx="72" cy="179" r="5"/></g><g fill="#c0caf5" text-anchor="middle"><text x="320" y="23">14:58</text><text x="320" y="67">14:58</text><text x="320" y="131">14:58</text><text x="320" y="183">14:58</text></g><text x="20" y="232" fill="#a9b1d6" font-size="11">Settings › Bar › Style, or: qs -c lyne ipc call state set bar.style '"islands"'</text></g></svg></div>

## The bar window

@include lyne/modules/bar/Bar.qml

::: walk
@ 1-9 | Imports
The bar uses components (`qs.components`) and buttons from three module folders. Each subfolder of `modules/` is its own module, `qs.modules.quickSettings` and so on.
@ 16-23 | One bar per screen
[[Variants]] creates a `PanelWindow` for every screen and recreates bars when you plug monitors in or out. `modelData` is the screen.
@ 25-30 | Top or bottom
The anchors come from the setting, so moving the bar is a state change: the window is re-anchored live.
@ 31-35 | Size, reserved space, namespace
The window is the bar's height plus its margin plus room for the concave corners, which hang **below** the reserved area. `exclusiveZone` tells the compositor how much space to keep free for the bar: the bar and margin, not the corners. An auto-hiding bar reserves nothing (`-1`, the same value `ExclusionMode.Ignore` sends). The namespace lets Hyprland blur behind it ([[ch:ly12-assemble]]).
@ 37-39 | Auto-hide
The bar shows when auto-hide is off, while the pointer is over it, or while any popup is open (`WindowManagerService.anyModuleOpen`, [[ch:ly6-panels]]), so it doesn't slide away under the Quick Settings panel you're using.
@ 41-46 | The input mask
A transparent window still swallows clicks everywhere it covers. The [[Region]] mask limits input to the bar itself, so the corners hanging below it click through to your windows. When hidden, only a 1-pixel strip at the screen edge takes input: touch the edge and the hover brings the bar back ([[ch:35-masks]]).
@ 48-53 | Sliding away
Everything visible sits in `slide`. Hidden, it moves one window-height off screen (up, or down for a bottom bar), with `OutExpo` easing: fast at first, gentle at the end.
@ 55-56 | Where things go
At the top, the bar is at the margin and the corners hang just below it. At the bottom, the corners come first and the bar under them.
@ 58-72 | The corners
Two [[ch:ly4-components]] concave corners, left and mirrored right, flipped for a bottom bar. In styles without corners `barCornerSize` is 0, which hides them.
@ 74-86 | The bar's background
`barArea` is inset by the margin (only a floating bar has one). One rectangle draws the background, rounded when floating, absent for islands, where each group draws its own.
@ 88-96 | Left
The logo, the workspaces, a divider and the window title. The divider hides with the title, on an empty workspace.
@ 98-102 | Centre
The clock, centred on the screen whatever the sides contain.
@ 104-111 | Right
Tray, status icons, bell. The three ids are used just below.
@ 115-118 | The panels of this bar
Each bar owns a dashboard, a Quick Settings panel and a notification history, opened by its buttons. Each gets its screen, the bar window (so clicks on the bar don't count as "outside") and the button it should centre under. [[ch:ly6-panels]] builds them.
:::

## The logo button

@include lyne/components/LauncherButton.qml

::: walk
@ 8-15 | A bar button
It **is** a `BarButton`, with handlers attached. Click opens the launcher; right-click opens it in actions mode (the `>` prefix) and middle-click in clipboard mode (`;`), the same defaults as lyne. It's lit while the launcher is open.
@ 15 | Hover starts the hop
Only if it isn't already hopping, so moving the pointer in and out quickly doesn't restart it.
@ 17-23 | The mark
A bit smaller than a full icon.
@ 25-44 | The hop
Classic animation principles in five steps: **anticipation** (squash before jumping), the **leap** (rise while stretched tall), the **fall**, the **impact** (flattened) and a springy return to round (`OutBack` overshoots). It takes about 0.8 seconds and only animates two numbers on the mark. lyne's own button goes further: the dot rides along the whole line like a comet when the launcher opens, then breathes.
:::

## Workspaces

<div class="preview"><svg width="560" height="120" viewBox="0 0 560 120"><g font-size="10"><g transform="translate(20 15)"><rect x="0" y="0" width="30" height="16" rx="8" fill="#7aa2f7"/><g fill="#565f89"><rect x="36" y="0" width="16" height="16" rx="8"/></g><g fill="#414868" opacity=".65"><rect x="58" y="0" width="16" height="16" rx="8"/><rect x="80" y="0" width="16" height="16" rx="8"/></g><rect x="102" y="0" width="16" height="16" rx="8" fill="#f7768e"/><text x="140" y="12" fill="#a9b1d6">pills: occupied brighter, urgent red</text></g><g transform="translate(20 50)"><rect x="0" y="0" width="30" height="16" rx="8" fill="#7aa2f7"/><circle cx="44" cy="8" r="4" fill="#a9b1d6"/><circle cx="62" cy="8" r="2.5" fill="#565f89"/><circle cx="80" cy="8" r="2.5" fill="#565f89"/><text x="140" y="12" fill="#a9b1d6">dots</text></g><g transform="translate(20 85)"><rect x="0" y="0" width="22" height="18" rx="6" fill="#7aa2f7"/><text x="11" y="13" fill="#1a1b26" text-anchor="middle" font-weight="700">1</text><text x="33" y="13" fill="#c0caf5" text-anchor="middle">2</text><text x="55" y="13" fill="#545c7e" text-anchor="middle">3</text><text x="77" y="13" fill="#545c7e" text-anchor="middle">4</text><text x="140" y="13" fill="#a9b1d6">numbers</text></g><g transform="translate(320 30)"><rect y="0" height="16" rx="8" fill="#7aa2f7"><animate attributeName="x" values="0;0;0;60;60;60;0" keyTimes="0;.2;.3;.42;.7;.8;1" dur="3s" repeatCount="indefinite"/><animate attributeName="width" values="30;30;90;30;30;90;30" keyTimes="0;.2;.3;.42;.7;.8;1" dur="3s" repeatCount="indefinite"/></rect><text x="0" y="40" fill="#a9b1d6">the indicator stretches, then snaps</text></g></g></svg></div>

@include lyne/components/Workspaces.qml

::: walk
@ 17-21 | What to show
How many workspaces and which style, from the settings. The active workspace comes from Hyprland; `activeIndex` is its position from 0.
@ 23-26 | Sizes
Each slot is a little wider than the small font; the active one is twice as wide (except in the numbers style, where every slot is the same). Spacing and the indicator height are derived from the padding and font tokens, so the strip scales with your settings.
@ 28-29 | Occupied and urgent
A workspace is occupied if it exists and has windows (`toplevels`). Urgent means a window on it asked for attention.
@ 31-38 | Positions
A slot's x is the sum of the widths and gaps before it, so when the active slot widens, everything after it moves along.
@ 40-41 | The strip's size
The end of the last slot (minus the trailing gap).
@ 44-57 | The indicator
An accent pill behind the active slot (in front of it for pills and dots, behind the number for numbers). Instead of animating `x` and `width`, it animates its **two edges** separately…
@ 59-61 | …at different speeds
The edge facing the direction of travel moves in 60% of the time, the other in the full time. Moving right, the right edge races ahead and the left edge catches up: the pill stretches across and snaps back. That's lyne's signature workspace motion.
@ 63-64 | Which way
Each time the active workspace changes, compare it with the last one to get the direction.
@ 67-81 | One slot per workspace
Its position and width animate when the active slot changes.
@ 83-110 | Three looks
All three are declared and only the current style's is visible. Pills are bars (brighter when occupied, red when urgent); dots grow when occupied; numbers are dim when empty and dark on the indicator.
@ 112-116 | Clicking
`Hypr.workspace(n)` switches workspace (below).
@ 120-123 | Scrolling
Up for the previous workspace, down for the next, kept between 1 and the count.
:::

@include lyne/services/Hypr.qml

::: walk
@ 8-10 | Two config languages
lyne-dots configures Hyprland in **Lua**. There, `hyprctl dispatch` takes Lua code: `hl.dsp.focus({ workspace = 3 })`. A classic config takes `workspace 3`. The shell must speak the right one.
@ 14-20 | Which one?
At startup, check whether `~/.config/hypr/hyprland.lua` exists (`test -f` exits with 0 if it does).
@ 22-24 | Switching
`Hyprland.dispatch` sends the command in the right form.
@ 25-32 | Screens and logging out
Two more commands the idle manager and the power menu need ([[ch:ly9-lock-power]]): turning the screens off and on, and ending the session, each in both languages.
:::

> [!NOTE] In the original
> lyne's `components/workspaces/` has five styles (pills, numbers, dots, groups, icons) sharing `WorkspaceStrip.qml`, and a `WorkspacesModel` that gives **each monitor its own block** of workspaces (monitor 1 has 1–10, monitor 2 has 11–20…), set in Settings › Workspaces. The strip also scrolls when you have more workspaces than it shows.

## The window title

@include lyne/components/ActiveWindow.qml

The focused window's title (or its app id), in secondary colour, cut at `maxWidth`. `activated` is false when no window has focus, which hides the label and its divider.

## The tray drawer

@include lyne/components/TrayWidget.qml

::: walk
@ 14-17 | Items and state
Every tray item, and whether the drawer is open. Open-ness is a **setting** (`bar.tray.open`), so the drawer remembers its state across restarts. No items, no tray.
@ 19-26 | The drawer
An item whose width animates between 0 and the icons' width, with `clip` hiding whatever doesn't fit. That's the whole sliding effect.
@ 28-32 | Icons anchored right
The icons are pinned to the drawer's right edge, next to the chevron, so they appear to slide out from it.
@ 35-47 | One icon
The app's icon and its menu, opening below the icon (above for a bottom bar).
@ 48-60 | Clicks
Left activates the app (unless it says it's "menu only"), middle is the secondary action, right opens the menu ([[ch:50-proj-tray]]).
@ 66-74 | The chevron
A bar button that flips the setting; the arrow turns 180° when open.
:::

## The clock

@include lyne/modules/dashboard/ClockButton.qml

Date and time side by side; a click opens the dashboard on this bar's screen. `screenName` is `required`: each bar passes its own, so the dashboard opens on the screen you clicked.

## The status icons

@include lyne/modules/quickSettings/QuickSettingsButton.qml

::: walk
@ 9-11 | One button, several icons
lyne's "icons" style: network, Bluetooth, volume, the microphone only when muted, and battery, all inside one `BarButton`. A click anywhere opens Quick Settings.
@ 17-19 | Behaviour
Lit while its panel is open on this screen. Scrolling changes the volume and shows the OSD ([[ch:ly8-notifications-osd]]).
@ 21-24 | Network and battery
The Wi-Fi device and its connected network; a connected device that isn't Wi-Fi counts as wired; UPower's combined battery.
@ 26-31 | Network icon
Ethernet, Wi-Fi off, or one of five strength icons: `signalStrength` (0–1) × 4, rounded up, picks from `Icons.wifi`.
@ 32-36 | Bluetooth
Only with an adapter. Accent-coloured while a device is connected, dim when off.
@ 37-45 | Volume and microphone
The volume icon for the level. The microphone appears only when muted, in red, a reminder you won't be heard.
@ 46-61 | Battery
Only on laptops: an icon by level (green while charging, red at 15% and below) and the percentage.
:::

## The bell

@include lyne/modules/notifications/NotificationButton.qml

A bell, crossed out in do-not-disturb mode, with an accent dot when there are notifications. The `Item` wrapper gives the dot something to sit on, at the bell's top-right corner. Click: history; right-click: do not disturb.

## Practice

::: exercise warm | Try every style
Open Settings (Super+I, or `qs -c lyne ipc call settings toggle`) › Bar and try all four styles, the bottom position and auto-hide.
:::

::: exercise practice | Seconds on hover
Make the clock show seconds while hovered.
--- hint
`BarButton` has `hovered`. Use `precision: root.hovered ? SystemClock.Seconds : SystemClock.Minutes` and pick the format the same way.
:::

::: exercise practice | Hide empty workspaces
Add `bar.workspaces.hideEmpty`: when true, give empty, inactive slots width 0 and hide them.
--- hint
In `slotWidth(index)`, return 0 for a hidden slot, and skip adding the spacing for it in `slotX()`.
:::

::: exercise practice | A keyboard-layout button
Add a button showing the current layout (Hyprland's `activelayout` event carries it, [[ch:g1-bar-modules]] has an example) that only appears when you have more than one layout. lyne shows it in the right group before the tray.
:::

::: exercise challenge | Per-monitor workspaces
Give each monitor its own workspaces: monitor *n* (in `Quickshell.screens` order) shows workspaces `n*10+1` to `n*10+10`. Add a `monitorOffset` property to `Workspaces` and pass it from the bar.
:::
