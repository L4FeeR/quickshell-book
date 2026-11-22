# lyne-dots 8: Notifications, Audio and the OSD

Two things every desktop needs: somewhere for notifications to go, and feedback when you press the volume keys. This chapter turns the shell into the system's **notification daemon** (replacing mako or dunst), with popups, a history under the bell and inline replies, then builds the audio and brightness services and lyne's **OSD**, which slides out of the bar like the other panels.

<div class="preview"><svg width="620" height="200" viewBox="0 0 620 200"><g font-size="11"><rect width="620" height="28" fill="#1a1b26"/><path d="M200 28h220v50a14 14 0 0 1-14 14h-192a14 14 0 0 1-14-14z" fill="#1a1b26"/><path d="M186 28h14v14a14 14 0 0 0-14-14z" fill="#1a1b26"/><path d="M420 28h14a14 14 0 0 0-14 14z" fill="#1a1b26"/><text x="216" y="66" fill="#7aa2f7" font-size="16">🔊</text><text x="244" y="52" fill="#a9b1d6" font-size="10">Volume</text><rect x="244" y="60" width="130" height="6" rx="3" fill="#292e42"/><rect x="244" y="60" width="85" height="6" rx="3" fill="#7aa2f7"/><text x="384" y="66" fill="#c0caf5">65%</text><rect x="440" y="40" width="170" height="70" rx="10" fill="#1a1b26"/><rect x="450" y="50" width="30" height="30" rx="5" fill="#9ece6a"/><text x="488" y="62" fill="#c0caf5" font-weight="700">Spotify</text><text x="488" y="78" fill="#a9b1d6" font-size="10">Instant Crush</text><rect x="450" y="88" width="72" height="16" rx="8" fill="#292e42"/><rect x="528" y="88" width="72" height="16" rx="8" fill="#292e42"/><text x="20" y="180" fill="#a9b1d6">the volume OSD hangs from the bar; notifications pop up at the top right</text></g></svg></div>

## The notification service

@include lyne/services/NotificationService.qml

::: walk
@ 9-11 | One server per session
The freedesktop notification protocol has one server per session: whoever registers first gets every notification. A singleton guarantees the shell creates exactly one, and every widget (popups, history, bell) reads from it.
@ 15-18 | State
Do not disturb is a **setting**, so it survives restarts. `history` is every notification still open, `count` feeds the bell, `popups` is the subset showing as popups.
@ 20-22 | The history popup
Open or not, and on which screen.
@ 24-31 | The server
`keepOnReload` keeps notifications when the config reloads. The `…Supported` flags tell apps what the shell can show; apps then send actions, images, simple markup, and a reply field (chat apps use it).
@ 33-36 | A new notification
`tracked = true` keeps it; without it the notification is dropped as soon as this handler returns. Notifications carry no time stamp, so the arrival time is recorded. When the notification closes (dismissed, expired or withdrawn by the app), it leaves the popups too.
@ 37-38 | Do not disturb
Only critical notifications pop up; the rest go quietly into the history.
@ 39-40 | Never too many
New popups are added at the end, and only the last `maxPopups` are kept.
@ 44-46 | Helpers
Hide a popup (it stays in the history), dismiss everything (`slice()` copies the list first, because dismissing changes it), and flip do not disturb.
@ 48-51 | Toggling the history
The same pattern as every popup.
@ 53-58 | Age
"now", "5 min", "2 h", from the recorded time.
@ 60-70 | Polite, and scriptable
`qs -c lyne ipc call notifications toggleDnd` and `… clear`.
:::

> [!IMPORTANT] Only one daemon
> Stop mako, dunst or swaync before running the shell, or the shell logs that the server is already registered and stays quiet until the other one exits.

## One card, two places

A notification looks the same as a popup and in the history, so it's one component:

@include lyne/modules/notifications/NotificationCard.qml

::: walk
@ 16-18 | Inputs
The notification, whether it's critical, and whether to show a close button.
@ 20-24 | The card
Grows with its content. Only critical notifications get a border, in the error colour.
@ 36-53 | Image or icon
An image sent with the notification (album art, a contact's avatar) is shown in a rounded clip. Otherwise the app's icon, by name or from its desktop entry, with a generic fallback.
@ 57-67 | Title row
The summary, how long ago it arrived, and a close button that dismisses it everywhere.
@ 68-77 | Body
Apps may send simple HTML (`<b>`, `<i>`); `StyledText` renders it. Long bodies are cut after four lines.
@ 81-97 | Actions
One button per action ("Reply", "Mark as read"). `invoke()` tells the app which one was chosen.
@ 99-122 | Inline reply
Only when the app asks for it. Enter sends the text back with `sendInlineReply` and clears the field. The placeholder comes from the app if it gave one.
:::

## The popups

@include lyne/modules/notifications/NotificationOverlay.qml

::: walk
@ 14 | On the focused screen
The screen whose name matches Hyprland's focused monitor.
@ 15-23 | Top right, under the bar
Anchored to the bar's edge and the right, with margins that keep clear of the bar (top or bottom).
@ 24-31 | Size and layer
As tall as the stack, hidden when empty. `OnDemand` keyboard focus: popups never take the keyboard when they appear (that would steal it from the window you're typing in), but clicking a reply field gives it focus.
@ 38-45 | One card per popup
With the panel background colour, so popups look like the rest of the shell.
@ 47-50 | Sliding in
A `Translate` starts one window-width to the right and animates to 0. A transform doesn't affect the column's layout, so the other cards don't jump.
@ 52-58 | Lifetime
The app's own timeout, the setting's default if it gave none, and never for critical ones. Hovering stops the timer; leaving starts it again from the full timeout.
@ 59-67 | Clicks
Right or middle click dismisses. Left click runs the default action (by convention, the action with the id `"default"`, like opening the chat), or just hides the popup.
:::

## The history under the bell

@include lyne/modules/notifications/NotificationHistory.qml

An attached popup ([[ch:ly6-panels]]) under the bell: a header with do-not-disturb and clear-all buttons, "No notifications" when empty, and the cards newest first (`slice().reverse()` copies the list before reversing it, leaving the service's list alone). The panel grows with its content up to 560 px, then the list scrolls.

## Audio

@include lyne/services/AudioService.qml

::: walk
@ 11-17 | The default devices
`Pipewire.defaultAudioSink` is where sound plays, `defaultAudioSource` the microphone. Their volume and mute state, with safe defaults while they're missing.
@ 19-20 | Tracking
PipeWire only fills in a node's audio properties for nodes that are tracked.
@ 22-31 | Changing volume
Changing the volume unmutes (like most desktops), and keeps it between 0 and 100%. Each step is 5%. `ready` guards against calling into a node that isn't fully set up yet.
@ 33-36 | The volume icon
Muted, low, medium or high. Several widgets need the same icon, so it lives with the data.
:::

@include lyne/services/BrightnessService.qml

Brightness through `brightnessctl`: `-m` gives machine-readable output (`name,class,current,percent,max`), read at startup and every 10 seconds; `available` is false on desktops without a backlight, which hides the brightness slider. Setting it updates `brightness` right away and runs `brightnessctl set 42%` in the background.

## The OSD

@include lyne/services/OsdService.qml

::: walk
@ 13-15 | State
What it shows, whether it wants to be visible, and whether its window exists. These are separate so the window can stay for the exit animation after `visible` turns false.
@ 17-23 | What to show
The level, the icon and the label for the current kind, read live from the audio and brightness services. If the volume changes while the OSD is up, it follows.
@ 25-31 | Showing
Keybinds call `show("volume")` after changing the volume. Each call restarts the timer, so holding the key keeps it up. `keepOpen()` restarts it too (hovering does that).
@ 33-43 | Hiding in two steps
When the time is up, `visible` turns false (the panel slides away); one long duration later the window is removed.
@ 45-49 | From scripts
`qs -c lyne ipc call osd trigger volume`. (Not `show`: `qs ipc` uses that word itself.)
:::

@include lyne/modules/osd/OsdOverlay.qml

::: walk
@ 18-31 | Two styles
"attached" hangs from the bar like the other panels (lyne's default); "pill" floats near the bottom of the screen. The window is wide enough for the panel plus its fillets, on the focused screen, and only the visible shape takes input.
@ 33-56 | The level
Icon, label, a bar, and the percentage, as one inline component used by both styles.
@ 58-70 | Interactive
Hovering keeps it open, the wheel changes the level, a click mutes. lyne makes this optional (`osd.interactive`).
@ 72-83 | Attached
An `AttachedPanel` at the bar edge, centred in its window. It slides with `OsdService.visible`.
@ 85-99 | Pill
A capsule that fades and grows in.
:::

> [!NOTE] In the original
> lyne's OSD has four styles (pill, vertical, card, attached), several positions for each, can show on every monitor, and also announces keyboard-layout and window-layout changes and default output switches. Its `NotificationService` adds conversations (messages from the same chat grouped), swipe to dismiss and a richer history with filters.

## Practice

::: exercise warm | Send yourself some
```bash
notify-send "Hello" "From the terminal"
notify-send -u critical "Battery" "5% left"
notify-send -A yes=Yes -A no=No "A question" "Pick one"
```
Watch the popups, the bell's dot and the history.
:::

::: exercise practice | A sound for each notification
Play a sound when a notification arrives, except in do-not-disturb mode (`pw-play /usr/share/sounds/freedesktop/stereo/message.oga`).
:::

::: exercise practice | Group by app
In the history, group the cards under each app's name and icon, newest group first.
--- hint
Build `[{ app, items }]` from `history` in a `readonly property var groups` and use a `Repeater` of groups, each with a header and a `Repeater` of cards ([[ch:g9-system]] has a full version).
:::

::: exercise challenge | A vertical OSD
Add an `osd.style` value "vertical": a tall, narrow bar on the right edge of the screen that fills from the bottom.
:::
