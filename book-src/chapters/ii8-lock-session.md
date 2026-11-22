# end-4 8: Lock Screen, Session Screen and Background

The last panels: a **lock screen** with a big clock and a password field that draws shapes instead of dots, a fullscreen **session screen**, and the **background** with a desktop clock.

```text
modules/lock/           Lock  LockSurface
modules/sessionScreen/  SessionScreen
modules/background/     Background
```

## Module 1: The lock controller

@include impulse/modules/lock/Lock.qml

The structure matches the Caelestia rebuild ([[ch:cae8-lock-background]]): one shared password, a [[PamContext]] that answers PAM's question with it, and a [[WlSessionLock]] with one surface per monitor. Two ii-style differences: the lock state lives in `GlobalStates.screenLocked` (so the bar and popups can hide themselves while locked), and the IPC function is called `activate` (`qs -c impulse ipc call lock activate`).

## Module 2: The lock surface

<div class="preview"><svg width="560" height="250" viewBox="0 0 560 250"><g><rect width="560" height="250" fill="#3b3550"/><text x="280" y="90" fill="#fff" font-size="60" text-anchor="middle">14:32</text><text x="280" y="118" fill="#fff" font-size="14" text-anchor="middle">Saturday, 21/11</text><rect x="160" y="180" width="240" height="44" rx="22" fill="#141218"/><g fill="#d0bcff"><circle cx="232" cy="202" r="7"/><rect x="246" y="195" width="14" height="14" rx="4"/><rect x="268" y="195" width="12" height="12" rx="2" transform="rotate(45 274 201)"/><circle cx="296" cy="202" r="7"/><rect x="310" y="195" width="14" height="14" rx="4"/></g></g></svg></div>

@include impulse/modules/lock/LockSurface.qml

The wallpaper (from the config) is blurred and darkened with `MultiEffect`. The clock uses the title font. The password field is an invisible `TextInput` with visible shapes drawn on top: each character gets a circle, rounded square, diamond or pill in turn (`radius: [7, 4, 2, 7][index % 4]`, rotated 45° for the diamond), popping in with the small springy preset. A wrong password turns the border and hint red; typing again clears the error.

> [!NOTE] In the original
> ii's lock (`modules/common/panels/lock/` with `LockScreen.qml`, `LockContext.qml` and PAM helpers) uses real **Material shapes** (cookies, clovers, flowers from its `MaterialShape` widget) for the password characters, supports fingerprint unlock, shows media controls and a battery indicator, and can blur the actual screen instead of the wallpaper.

## Module 3: The session screen

@include impulse/modules/sessionScreen/SessionScreen.qml

::: walk
@ 15-21 | Actions
`[icon, label, function]` triples: lock, sleep, logout, shutdown, reboot.
@ 23-32 | Loaded only when open
A `LazyLoader` creates the fullscreen window when `GlobalStates.sessionOpen` turns on and destroys it afterwards. The window dims the screen (50% black), sits on the overlay layer and takes the keyboard exclusively.
@ 34 | Click outside to cancel
A full-window `MouseArea` behind the content.
@ 36-41 | Title and hint
Gabarito title and a one-line hint.
@ 43-52 | Keyboard
←/→ move (wrapping around), Enter runs, Esc cancels. The row has `focus: true` so it receives the keys.
@ 54-75 | Buttons
Big `RippleButton`s. The focused one is `toggled` (primary colour) and gets **more** rounding, a shape change that shows focus. Hovering moves the focus.
@ 78-85 | The label pill
A tooltip-coloured pill under the row shows the focused action's name, like ii's session screen.
:::

## Module 4: The background

@include impulse/modules/background/Background.qml

The wallpaper from `Config.options.background.wallpaperPath`, decoded at the screen's pixel size, plus a large clock in the bottom-right corner in the primary colour. Applying a new wallpaper with the `Wallpaper` service updates the config and runs matugen:

@include impulse/services/Wallpaper.qml

> [!NOTE] In the original
> ii's background supports video wallpapers, a parallax effect that shifts the wallpaper with the active workspace, and draggable desktop widgets (clock styles, weather). Wallpapers are chosen in a dedicated **wallpaper selector** panel, and the `switchwall.sh` script regenerates colours for the shell, GTK, terminals and more.

## Practice

::: exercise warm | Lock on Super+L
Make sure `bind = SUPER, L, exec, qs -c impulse ipc call lock activate` is in your Hyprland config, then lock and unlock. (Test with a safety timer first, as described in [[ch:cae8-lock-background]].)
:::

::: exercise practice | Hibernate
Add a "Hibernate" action (`systemctl hibernate`, icon `downloading`) to the session screen.
:::

::: exercise practice | Parallax wallpaper
Shift the background image left by 2% of the screen width per workspace, animated, so switching workspaces slides the wallpaper slightly.
--- hint
Make the image 120% wide and set `x: -(Hyprland.focusedWorkspace?.id - 1) % 10 * bg.width * 0.02` with a `Behavior`.
:::

::: exercise challenge | Real shapes
Replace the lock's dots with real Material 3 shapes drawn with `Shape` paths (a 4-leaf clover, a scalloped "cookie"), cycling per character.
:::
