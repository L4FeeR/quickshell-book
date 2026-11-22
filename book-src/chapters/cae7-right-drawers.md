# Caelestia 7: Notifications, Sidebar, Session, OSD, Utilities

The right side of Caelestia's frame is busy: notification popups in the top-right corner, a notification centre below them, the session menu and the OSD sliders in the middle, and quick toggles in the bottom-right corner. All of them are drawers from [[ch:cae3-frame]]; this chapter fills them.

<div class="preview"><svg width="600" height="340" viewBox="0 0 600 340"><g font-size="11"><rect x="588" width="12" height="340" fill="#141218"/><rect width="600" height="10" fill="#141218"/><rect y="330" width="600" height="10" fill="#141218"/><path d="M340 10 A25 25 0 0 1 365 35 V70 A22 22 0 0 0 387 92 H588 V10Z" fill="#141218"/><rect x="380" y="20" width="198" height="62" rx="14" fill="#211f26"/><circle cx="402" cy="42" r="12" fill="#4a4458"/><text x="420" y="40" fill="#e6e0e9">Discord</text><text x="420" y="56" fill="#cac4d0" font-size="10">Alex: pushed the rice!</text><path d="M588 110 A25 25 0 0 1 563 135 V145 A25 25 0 0 0 538 170 Q500 170 500 195 V265 Q500 290 525 290 H538 A25 25 0 0 1 563 315 V330 H588Z" fill="#141218" opacity="0"/><rect x="508" y="120" width="80" height="170" rx="22" fill="#141218"/><rect x="560" y="120" width="28" height="170" fill="#141218"/><rect x="520" y="134" width="16" height="70" rx="8" fill="#2b2930"/><rect x="520" y="160" width="16" height="44" rx="8" fill="#d0bcff"/><rect x="546" y="134" width="16" height="70" rx="8" fill="#2b2930"/><rect x="546" y="150" width="16" height="54" rx="8" fill="#d0bcff"/><text x="490" y="218" fill="#cdd6f4" text-anchor="end">OSD →</text><path d="M380 330 A25 25 0 0 0 405 305 V262 A22 22 0 0 1 427 240 H588 V330Z" fill="#141218"/><g transform="translate(420 252)"><rect width="40" height="34" rx="12" fill="#d0bcff"/><rect x="46" width="40" height="34" rx="17" fill="#2b2930"/><rect x="92" width="40" height="34" rx="12" fill="#d0bcff"/></g><g fill="#cdd6f4"><text x="160" y="50">notification popups (top-right) →</text><text x="160" y="300">quick toggles (bottom-right) →</text></g></g></svg></div>

```text
services/               Notifs
modules/notifications/  Content  NotificationCard
modules/sidebar/        Content
modules/session/        Content
modules/osd/            Content
modules/utilities/      Content
components/             VerticalSlider
```

## Module 1: The notification server

@include cae/services/Notifs.qml

::: walk
@ 11-13 | History, popups and DND
`list` holds every notification since login, newest first. `popups` is derived from it: the ones whose `popup` flag is still on. Turning on Do Not Disturb (`dnd`) makes new notifications skip the popup stage and go straight to the history.
@ 20-26 | Becoming the server
Only one program on your system can be the notification server. Each `…Supported` flag tells apps what the server can show (action buttons, markup in the body, images…), so they can send richer notifications.
@ 28-32 | A new notification
`tracked = true` tells Quickshell to keep the notification alive (otherwise it's dropped as soon as the handler ends). Each one is wrapped in a `Notif` object that adds a popup flag and a timestamp, and is put at the front of the list.
@ 40-51 | The wrapper and its timer
Inline components can contain other objects as property values: the wrapper owns a `Timer` that turns `popup` off after the app's requested timeout (`expireTimeout` is in seconds, or `-1` for "server default"). Critical notifications never time out.
@ 53-59 | Cleaning up
When an app (or you) closes the notification, it emits `closed`; the wrapper removes itself from the list and destroys itself.
:::

## Module 2: A notification card

@include cae/modules/notifications/NotificationCard.qml

The card shows the image if the notification has one (chat apps send avatars), otherwise the app icon. Critical notifications use the `errorContainer` colours. The body supports simple HTML (`Text.StyledText`) and is limited to four lines. Each action becomes a pill button; clicking the card itself runs the action named `"default"` (for most apps: open the conversation). The `HoverHandler` at the end **pauses the popup timer while you're reading**.

## Module 3: Popups

@include cae/modules/notifications/Content.qml

The popups drawer in `Panels.qml` is open whenever `Notifs.popups` is non-empty (and the sidebar is closed). Its size follows the column of cards, so the drawer grows when a notification arrives and shrinks when one times out, all with the drawer's animation and melted frame background.

## Module 4: The notification centre (sidebar)

@include cae/modules/sidebar/Content.qml

A header with a count, a DND toggle and a clear button, then a `ListView` of every notification. The list's `remove` transition slides dismissed cards off to the right; `displaced` moves the others up smoothly. Opening the sidebar hides the popups (they would be duplicates).

## Module 5: The session menu

@include cae/modules/session/Content.qml

::: walk
@ 13-19 | Actions
Logout, shut down, sleep, reboot. Shut down is selected by default (`current: 1`).
@ 24-30 | Keyboard focus on open
While the session drawer is open, the drawers window asks Hyprland for keyboard focus ([[ch:cae3-frame]]). When it opens, this column takes the focus so the arrow keys reach it.
@ 32-40 | Keys
↑/↓ move, Enter runs, Esc closes. `run()` closes the drawer first, then starts the command.
@ 42-69 | The buttons
Large squircles. The selected one gets the secondary container colour, a filled icon and **smaller** rounding: the shape change shows focus even without colour. Hovering selects, so mouse and keyboard stay in sync.
:::

## Module 6: The OSD

Caelestia's OSD is two vertical sliders that slide out of the right frame edge. They're real sliders: you can drag them.

@include cae/components/VerticalSlider.qml

@include cae/modules/osd/Content.qml

::: walk
@ 16-20 | Flashing the OSD
When the volume or brightness changes, the OSD opens and a hide timer restarts. Keeping the key held keeps restarting it, so the OSD stays while you adjust.
@ 25-28 | Startup and hover
At startup, PipeWire and the backlight report their initial values; `armed` ignores those. The hide timer doesn't close the OSD while you're hovering it, so you can grab a slider.
@ 30-38 | What triggers it
`Connections` to the two services. Any change, from your keys, a script or another app, shows the OSD.
@ 40-50 | Two sliders
Each slider shows the live value and writes back on `moved` (only user drags, never the binding itself, which avoids feedback loops). The brightness slider hides on desktops without a backlight.
:::

## Module 7: Quick toggles

@include cae/modules/utilities/Content.qml

Six `IconButton`s in a grid: Wi-Fi, Bluetooth, microphone, Do Not Disturb, caffeine (an `IdleInhibitor` attached to the drawers window) and a region screenshot to the clipboard. Each `checked` is bound to the real state and each click changes that state, never the button.

> [!NOTE] In the original
> `modules/utilities/` contains cards for screen recording (with a recordings list), idle inhibition and toggles, plus the **toasts** system (small status messages like "Wallpaper changed"). `modules/sidebar/` groups notifications by app with expandable groups and swipe-to-dismiss. `modules/osd/` also shows the microphone and can be pinned open.

## Practice

::: exercise warm | Longer popups
Make popups stay 8 seconds when the app doesn't specify a timeout.
--- solution
`"notifs": { "defaultExpire": 8000 }` in `shell.json`. No code change needed.
:::

::: exercise practice | Group by app
In the sidebar, group notifications by `appName` with a small header per group (see the grouped history in [[ch:r5-control-center]]).
:::

::: exercise practice | Mic slider in the OSD
Add a third vertical slider for the microphone (`Audio.source`). Show it only while an app is recording (see the privacy indicator in [[ch:g1-bar-modules]]).
:::

::: exercise challenge | Toasts
Add a toast system: a `Toasts` singleton with `show(title, icon)` and a small stack of pills above the utilities drawer that disappear after 3 seconds. Show a toast when the wallpaper changes and when DND is toggled.
:::
