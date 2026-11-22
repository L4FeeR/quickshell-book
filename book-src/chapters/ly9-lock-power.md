# lyne-dots 9: Lock Screen, Power Menu and Idle

Three pieces that deal with the session: a **lock screen** that checks your real password and can't be bypassed, lyne's **power menu** with a key for every action and a countdown before restarting, and **idle handling** that locks the screen and turns the displays off when you walk away.

<div class="preview"><svg width="620" height="300" viewBox="0 0 620 300"><defs><filter id="lyb"><feGaussianBlur stdDeviation="6"/></filter></defs><rect width="620" height="300" fill="#1a1b26"/><g filter="url(#lyb)" opacity=".7"><circle cx="120" cy="80" r="70" fill="#7aa2f7"/><circle cx="480" cy="220" r="90" fill="#bb9af7"/><circle cx="330" cy="40" r="50" fill="#7dcfff"/></g><text x="310" y="110" fill="#c0caf5" font-size="62" font-weight="700" text-anchor="middle">14:58</text><text x="310" y="136" fill="#a9b1d6" font-size="13" text-anchor="middle">Sunday, 22 November</text><circle cx="310" cy="175" r="20" fill="#7aa2f7"/><text x="310" y="182" fill="#1a1b26" font-size="18" font-weight="700" text-anchor="middle">L</text><rect x="210" y="208" width="200" height="34" rx="17" fill="#1a1b26" opacity=".9" stroke="#414868" stroke-width="2"/><g fill="#c0caf5"><circle cx="286" cy="225" r="4"/><circle cx="298" cy="225" r="4"/><circle cx="310" cy="225" r="4"/><circle cx="322" cy="225" r="4"/><circle cx="334" cy="225" r="4"/></g><text x="24" y="284" fill="#c0caf5" font-size="11">▮ 70%</text><rect x="220" y="262" width="180" height="28" rx="14" fill="#1a1b26" opacity=".9"/><text x="234" y="281" fill="#c0caf5" font-size="10">♪ Instant Crush  ⏮ ⏸ ⏭</text><g fill="#1a1b26" opacity=".9"><circle cx="530" cy="276" r="13"/><circle cx="562" cy="276" r="13"/><circle cx="594" cy="276" r="13"/></g><text x="526" y="281" fill="#c0caf5" font-size="10">z  ⟳  ⏻</text></svg></div>

## The lock state

@include lyne/services/LockService.qml

::: walk
@ 8-10 | One buffer for every screen
Each monitor gets a lock surface, and you might type on any of them. So what you type is kept here, in one place, and every surface edits and shows the same `buffer`.
@ 14-20 | State
Locked or not; whether the lock windows exist (below); the typed text; whether PAM is checking; whether the last try failed.
@ 15-17 | Why surfaceActive?
If the lock windows were destroyed at the same moment the compositor is told to unlock, the two could race and leave the screen locked. So `locked` turns false first (the compositor unlocks), and the windows go half a second later.
@ 22 | Locking
Clear any old input and errors, create the lock windows and lock.
@ 24-30 | Submitting
Ignore Enter while already checking or with nothing typed, then start a PAM conversation.
@ 32-46 | PAM
[[PamContext]] runs the same authentication as your login screen (the `login` PAM service by default), so your normal password works, and so do fingerprint readers if PAM is set up for them. When PAM asks a question that needs an answer, the typed text is the answer. On success, unlock; otherwise mark the failure. The text is cleared either way.
@ 48 | Removing the windows
Half a second after a successful unlock, `surfaceActive` turns false and `shell.qml` destroys the lock windows.
@ 50-53 | From the terminal
`qs -c lyne ipc call lock lock`.
:::

## The lock screen

@include lyne/modules/lock/LockScreen.qml

::: walk
@ 17-19 | Why it's secure
[[WlSessionLock]] uses the ext-session-lock protocol. While locked, the **compositor** shows only the lock surfaces and sends them all input; no window, shortcut or notification can appear above them. If the shell crashed while locked, the compositor would keep the session locked (showing a solid colour) instead of revealing your desktop.
@ 23-25 | Lock state and shared data
Locked follows the service. The main screen is the one focused when locking, and the player is whatever is playing.
@ 27-30 | One surface per screen
`WlSessionLock` creates a `WlSessionLockSurface` for every monitor by itself. `isMain` decides which one shows the password field.
@ 32-48 | Blurred wallpaper
The current wallpaper, decoded at half size (a blur hides the detail anyway, and it's faster), hidden, and drawn through a [[MultiEffect]] with full blur and slightly darkened, so white text reads well on any image.
@ 52-62 | The hidden input
Every surface has an invisible text field holding the keyboard focus, bound to the shared buffer. Whichever surface has the keyboard, typing edits the same text. It's made invisible with `opacity: 0`, **not** `visible: false`: Qt never gives keyboard focus to an item that isn't visible.
@ 64-80 | Clock and date
Big, centred, on every screen.
@ 82-97 | The avatar
On the main screen: a circle with your initial, covered by `~/.face` if you have one.
@ 99-108 | The field
Its border is red after a wrong password, yellow while checking.
@ 109-120 | Shaking
A wrong password shakes the field left and right twice.
@ 122-129 | Dots instead of letters
One dot per typed character, drawn from the buffer's length.
@ 130-136 | Hint
"Enter password", "Checking…" or "Wrong password" while the field is empty. Clicking the field gives the hidden input focus.
@ 141-150 | Battery
Bottom left, on laptops.
@ 152-172 | Player
Bottom centre, while something plays, with controls.
@ 174-194 | Power buttons
Bottom right: suspend, restart and shut down work from the lock screen without unlocking.
:::

> [!WARNING] Test with a way back in
> Before relying on any lock screen, test it with a TTY login available (Ctrl+Alt+F3): if something is wrong, you can log in there and run `pkill qs` (Hyprland then shows a red screen; `hyprctl dispatch exit` or a TTY `loginctl unlock-session` gets you out).

> [!NOTE] In the original
> lyne has several lock templates (chosen in Settings › Lock screen), status pills, a session fade-out after a correct password, and guards against the lock being created twice.

## The power menu

@include lyne/services/PowerService.qml

::: walk
@ 13-16 | State
Open or not, the selected action, the seconds left in a countdown, and which action is waiting for it.
@ 18-25 | The actions
Each has a key (L, S, E, R, P), a label, an icon, whether it needs a countdown, and its command. Lock and log out have no command; they're handled specially below.
@ 27-35 | Opening
Close other popups, select the first action, clear any old countdown, show. Closing also cancels.
@ 37-49 | Running
Dangerous actions (log out, restart, shut down) start a countdown instead of running right away, if the countdown setting is above 0. The others run immediately.
@ 50 | Cancelling
Stop the countdown and forget the pending action.
@ 52-61 | Executing
Close the menu, then lock through the lock service, log out through Hyprland ([[ch:ly5-bar]]'s `Hypr` helper speaks both config languages), or run the command.
@ 63-71 | The countdown
Once a second; at zero, run the pending action.
@ 73-82 | Polite, and scriptable
`qs -c lyne ipc call power toggle`.
:::

@include lyne/modules/power/PowerOverlay.qml

::: walk
@ 10-14 | How it's used
Keys run actions directly: press P to shut down (after the countdown). Numbers and arrows move the selection.
@ 20-34 | Every screen dims
One overlay window per monitor, covering everything. Only the focused monitor's window takes the keyboard.
@ 36-44 | The backdrop
Black at 45%, faded in. A click on it cancels a countdown or closes the menu.
@ 46-60 | The strip
A column of buttons on the main screen. It starts just off the right edge and slides in. `entered` turns true one tick after creation, because at creation the window doesn't have its width yet. Clicks on the strip are swallowed so they don't reach the backdrop.
@ 62-80 | Keys
Escape closes (or cancels a countdown); during a countdown, **any** key cancels; up/down or K/J move; Enter runs; 1–9 select; letters run their action.
@ 82-130 | The buttons
The selected one is accent-filled with a squarer shape; the one counting down turns red and shows the seconds instead of its icon. Each shows its key in a corner. Hovering selects (but not during a countdown); clicking runs.
@ 132-145 | The label
Next to the strip: the selected action's name, or "Restart in 3… (any key cancels)".
:::

## Idle

@include lyne/services/IdleService.qml

The idle settings come from the state: lock after 5 minutes, screens off after 10, both 0 for never, and **caffeine**, which pauses both. The actions themselves are tiny. The idle **monitors** live in `shell.qml` ([[ch:ly12-assemble]]):

```qml
IdleMonitor {
    timeout: IdleService.lockTimeout
    enabled: IdleService.lockTimeout > 0 && !IdleService.caffeine && !StateService.isLoading
    respectInhibitors: true
    onIsIdleChanged: if (isIdle) IdleService.lock()
}
```

An [[IdleMonitor]] becomes idle after `timeout` seconds without input and stops being idle at the first key or movement. `respectInhibitors` honours apps that ask the compositor not to go idle: video players, games, a browser playing a video. It waits for the state to load, so it doesn't start counting with the wrong timeout.

## Practice

::: exercise warm | Lock and unlock
With a TTY ready, run `qs -c lyne ipc call lock lock`, type a wrong password, then the right one.
:::

::: exercise practice | A greeting
Show "Good morning", "Good afternoon" or "Good evening" with your user name above the clock, depending on the hour.
:::

::: exercise practice | A firmware entry
Add "Restart to firmware" (key F) to the power menu with `systemctl reboot --firmware-setup`, with a countdown.
:::

::: exercise challenge | Dim before locking
Add a third idle stage, 30 seconds before the lock: a black overlay on every screen that fades to 50%, and disappears when you move the mouse.
--- hint
Another `IdleMonitor` with `timeout: IdleService.lockTimeout - 30`, and a `Variants` of overlay windows whose model is `Quickshell.screens` while it's idle, `[]` otherwise. `mask: Region {}` keeps them from taking clicks.
:::
