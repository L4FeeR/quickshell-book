# end-4 7: OSD, Notification Popups and Screen Corners

Three small panels that pop up on their own: the **OSD** pill that drops from the bar when you change volume or brightness, **notification popups** that slide in from the right, and the **screen corners** that round off your monitor.

```text
modules/onScreenDisplay/   OnScreenDisplay
modules/notificationPopup/ NotificationPopup
modules/screenCorners/     ScreenCorners
```

## Module 1: The OSD

<div class="preview"><svg width="460" height="110" viewBox="0 0 460 110"><g font-size="11"><rect width="460" height="36" fill="#141218"/><path d="M0 36h22a22 22 0 0 0-22 22z" fill="#141218"/><path d="M460 36h-22a22 22 0 0 1 22 22z" fill="#141218"/><rect x="130" y="46" width="200" height="50" rx="25" fill="#141218" stroke="#49454f"><animate attributeName="y" values="10;46;46;46;10" keyTimes="0;.15;.5;.85;1" dur="4s" repeatCount="indefinite"/></rect><g><animateTransform attributeName="transform" type="translate" values="0 -36;0 0;0 0;0 0;0 -36" keyTimes="0;.15;.5;.85;1" dur="4s" repeatCount="indefinite"/><text x="152" y="76" fill="#e6e0e9" font-size="16">🔊</text><text x="180" y="66" fill="#e6e0e9" font-size="9">Volume</text><text x="306" y="66" fill="#e6e0e9" font-size="9">64</text><rect x="180" y="74" width="136" height="6" rx="3" fill="#4a4458"/><rect x="180" y="74" width="87" height="6" rx="3" fill="#d0bcff"/></g></g></svg></div>

@include impulse/modules/onScreenDisplay/OnScreenDisplay.qml

::: walk
@ 14-17 | What's shown
`kind` is "volume" or "brightness", `value` reads the matching service, and `shown` comes from the two `GlobalStates` flags (so other code can open or check the OSD too).
@ 19-25 | Showing
Pick the kind, set the matching flag, restart the hide timer.
@ 27-30 | Triggers
Ignore the first 1.5 s (services report their initial values at startup), then any volume, mute or brightness change shows the OSD. The hide timer uses `osd.timeout` from the config.
@ 32-42 | A click-through window under the bar
Anchored to the top, pushed down by the bar's height. `mask: Region {}` means it never takes input, so it can't block anything while visible. It stays mapped while the slide-out animation runs.
@ 44-54 | Dropping from the bar
The pill's `y` goes from above the window (hidden behind the bar) to 10 px below it, with the springy expressive curve, so it looks like it drops out of the bar.
@ 56-66 | Content
A filled icon (it changes with mute), then a column with the label, the value and a progress bar whose width animates with the fast preset.
:::

> [!NOTE] In the original
> `modules/ii/onScreenDisplay/` has one indicator component per kind (`VolumeIndicator`, `BrightnessIndicator`, `GammaIndicator` for night light), shows a different style for the microphone, and can appear on the focused monitor only.

## Module 2: Notification popups

@include impulse/modules/notificationPopup/NotificationPopup.qml

A transparent window in the top-right corner, sized to its list. Its mask is the list's content, so only the cards take clicks. The three transitions give the motion:

- **add**: new cards slide in from the right with the "emphasized decelerate" curve (fast start, gentle stop: things entering);
- **remove**: dismissed or timed-out cards slide out right with "emphasized accelerate" (things leaving speed up);
- **displaced**: the remaining cards move up with the springy spatial curve.

The window hides while the right sidebar is open (the same notifications are listed there) and while the screen is locked (no private content on the lock screen).

## Module 3: Screen corners

@include impulse/modules/screenCorners/ScreenCorners.qml

Four `RoundCorner`s ([[ch:ii2-foundations]]) in a fullscreen, click-through overlay window on every monitor. The two **top** corners are hidden when the bar is at the top in "hug" style, because the bar's own hanging corners already round the top of the screen (in the bar's colour instead of black).

## Practice

::: exercise warm | Longer OSD
`qs -c impulse ipc call config set osd.timeout 2500`.
:::

::: exercise practice | Microphone OSD
Show the OSD with a "Microphone" label and a `mic_off` icon when the mic is muted or unmuted.
--- hint
Add `"mic"` as a third kind: a `Connections` on `Audio` with `onMicMutedChanged`, and use 0 or 1 as the value.
:::

::: exercise practice | Popup limit
Show at most three popups; when a fourth arrives, time out the oldest one.
:::

::: exercise challenge | Coloured corners
Make the bottom screen corners use the bar's colour when the bar is at the bottom in hug style, and black otherwise.
:::
