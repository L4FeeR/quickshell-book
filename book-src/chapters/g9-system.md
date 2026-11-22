# Gallery: System Pieces

The parts that turn a bar into a **desktop shell**: a notification daemon with popups and a notification center, a lock screen, a polkit agent, battery warnings, an idle manager, a launcher, a dock, a wallpaper with a picker, a workspace OSD and a region selector. With these, the shell can replace mako/dunst, hyprlock, hypridle, hyprpolkitagent, swww, slurp and rofi.

The files are in `galleryshell/system/`, plus two small singletons in `galleryshell/services/` that several pieces share.

> [!IMPORTANT] Only one of each
> Some of these take over a system role that only **one** program can hold: the notification server, the polkit agent and the session lock. Stop mako/dunst/swaync, polkit-gnome/hyprpolkitagent and hyprlock/hypridle from autostarting before using these, or the shell will log that the role is already taken (and keep trying in the background).

## The Notification Service

**What it is.** The notification daemon itself: it receives every notification apps send, keeps the open ones, and decides which to show as popups. It's a singleton, so the popups, the notification center and any bell or island in your bar all share it.

**Kind:** service (singleton) · **Needs:** nothing extra (no other notification daemon running)

@include galleryshell/services/Notifs.qml

::: walk
@ 1 | A singleton
`pragma Singleton` plus the `Singleton` root: one instance, available as `Notifs` to any file that writes `import qs.services`.
@ 7-8 | Why a service
The freedesktop notification protocol allows **one** server per session. Putting it in a singleton means any number of widgets can display notifications without fighting over the server.
@ 11-16 | Public state
`dnd` (do not disturb), the full `list` of open notifications (oldest first), its `count` for badges, and `popups`, the subset currently shown as popups.
@ 18 | A hook
Other parts can react to new notifications with `Connections { target: Notifs; function onArrived(n) {…} }`, for example to play a sound or flash the dynamic island from [[ch:g3-islands-popups]].
@ 20-26 | The server
`keepOnReload` keeps notifications across config reloads. The `…Supported` flags tell apps what the shell can show; apps then send actions, images and simple markup.
@ 28-34 | A new notification
Setting `tracked` is essential: an untracked notification is discarded as soon as this handler returns. When it closes later (dismissed, expired, or closed by the app), it's removed from the popups. In do-not-disturb mode only critical notifications pop up; the rest go quietly into the list.
@ 37-38 | Helpers
`hidePopup` removes a notification from the popups but keeps it in the list. `clearAll` dismisses everything; `slice()` copies the list first, because dismissing changes it while we loop.
@ 40-45 | Terminal commands
`qs ipc call notifs toggleDnd`, `clear` and `count`.
:::

And a tiny second service for session state:

@include galleryshell/services/Session.qml

`Session.locked` drives the lock screen and `Session.caffeine` pauses the idle manager. Any widget, keybind or script can lock the screen with `Session.lock()` or `qs ipc call session lock`.

::: exercise practice | Notification sounds
Play a sound for every new notification, except in do-not-disturb mode.
--- solution
```qml
Connections {
    target: Notifs
    function onArrived(n): void {
        if (!Notifs.dnd) Quickshell.execDetached(["pw-play", "/usr/share/sounds/freedesktop/stereo/message.oga"])
    }
}
```
:::

## Notification Popups

<div class="preview"><svg width="420" height="230" viewBox="0 0 420 230"><g><rect x="20" y="10" width="380" height="96" rx="16" fill="#1e1e2e" stroke="#313244"><animateTransform attributeName="transform" type="translate" values="400 0;0 0;0 0" keyTimes="0;.12;1" dur="6s" repeatCount="indefinite"/></rect></g><rect x="32" y="22" width="44" height="44" rx="10" fill="#a6e3a1"/><text x="88" y="38" fill="#cdd6f4" font-size="14" font-weight="700">Spotify</text><text x="300" y="38" fill="#6c7086" font-size="11">spotify   ✕</text><text x="88" y="56" fill="#a6adc8" font-size="12">Instant Crush — Daft Punk</text><rect x="88" y="66" width="140" height="26" rx="13" fill="#313244"/><text x="158" y="83" fill="#cdd6f4" font-size="12" text-anchor="middle">Skip</text><rect x="234" y="66" width="140" height="26" rx="13" fill="#313244"/><text x="304" y="83" fill="#cdd6f4" font-size="12" text-anchor="middle">Like</text><rect x="30" y="102" height="2" rx="1" fill="#cba6f7"><animate attributeName="width" values="360;0" dur="6s" repeatCount="indefinite"/></rect><rect x="20" y="116" width="380" height="72" rx="16" fill="#1e1e2e" stroke="#f38ba8" stroke-width="2"/><circle cx="54" cy="146" r="16" fill="#f38ba8"/><text x="88" y="142" fill="#cdd6f4" font-size="14" font-weight="700">Battery critical</text><text x="88" y="162" fill="#a6adc8" font-size="12">5% remaining. Plug in now.</text></svg></div>

**What it is.** Popups in the top-right corner. Each shows the image or app icon, title, body, action buttons, and a thin line counting down its time. Hovering holds a popup open; clicking runs its default action. Critical notifications get a red outline and stay until dismissed.

**Kind:** own window · **Needs:** the notification service above

@include galleryshell/system/NotificationPopups.qml

::: walk
@ 11-21 | The window
A [[PanelWindow]] in the top-right corner, exactly as tall as its popups, and hidden when there are none. It's on the overlay layer, above normal windows, and doesn't reserve space.
@ 23-29 | The stack
A `ColumnLayout` with one card per entry in `Notifs.popups`. New notifications are added at the end, so they appear at the bottom.
@ 32-36 | Per-card values
`critical` from the urgency. The timeout is the app's own, or 5 seconds, or none for critical ones. `defaultAction` is the action with identifier `"default"`, which by convention is "what clicking the notification does".
@ 38-42 | The card
Height follows its content. Critical cards get a thicker red border.
@ 44-47 | Sliding in
A layout controls its children's `x`, so animating `x` directly would be overridden. A `Translate` transform moves the card visually without the layout noticing: it starts 400 px to the right and glides in.
@ 49-54 | Lifetime
When the timer fires, the popup is hidden but the notification stays in the list (and the notification center). The timer stops while hovered; when the pointer leaves, it starts again from the full timeout.
@ 61-75 | Image or icon
An image sent with the notification (album art, an avatar) is shown in a rounded clip. Otherwise the app icon is looked up from `appIcon` or the app's desktop entry.
@ 80-92 | Title row
The summary, the app name, and a close button that dismisses the notification (removing it everywhere).
@ 93-100 | Body
Apps may send simple HTML like `<b>`; `StyledText` renders it. Long bodies are cut after four lines.
@ 101-117 | Action buttons
Every action except the default one becomes a button. `invoke()` tells the app which was chosen.
@ 121-132 | The countdown line
It shrinks from full width to zero over the timeout, and restarts together with the timer after a hover.
@ 134-140 | Clicking the card
Runs the default action if there is one, otherwise just hides the popup.
:::

::: exercise practice | Limit the stack
Show at most three popups. When a fourth arrives, hide the oldest one.
--- hint
In the service's `onNotification`, after adding: `if (root.popups.length > 3) root.popups = root.popups.slice(-3)`.
:::

## Notification Center

<div class="preview"><svg width="420" height="320" viewBox="0 0 420 320"><rect x="10" y="6" width="400" height="308" rx="20" fill="#1e1e2e" stroke="#313244"/><text x="26" y="40" fill="#cdd6f4" font-size="18" font-weight="700">Notifications</text><rect x="268" y="20" width="34" height="30" rx="15" fill="#313244"/><text x="278" y="40" fill="#cdd6f4" font-size="13">🔔</text><rect x="308" y="20" width="86" height="30" rx="15" fill="#313244"/><text x="351" y="40" fill="#cdd6f4" font-size="12" text-anchor="middle">Clear all</text><g font-size="12"><circle cx="34" cy="72" r="7" fill="#89b4fa"/><text x="48" y="76" fill="#a6adc8" font-weight="700">Discord</text><text x="370" y="76" fill="#6c7086" font-size="11">Clear</text><rect x="26" y="86" width="368" height="54" rx="12" fill="#181825"/><text x="38" y="106" fill="#cdd6f4" font-weight="700" font-size="13">Alex</text><text x="38" y="126" fill="#a6adc8">are you coming tonight?</text><rect x="26" y="146" width="368" height="54" rx="12" fill="#181825"/><text x="38" y="166" fill="#cdd6f4" font-weight="700" font-size="13">#ricing</text><text x="38" y="186" fill="#a6adc8">Sam posted a screenshot</text><circle cx="34" cy="222" r="7" fill="#a6e3a1"/><text x="48" y="226" fill="#a6adc8" font-weight="700">Updates</text><rect x="26" y="236" width="368" height="54" rx="12" fill="#313244"/><text x="38" y="256" fill="#cdd6f4" font-weight="700" font-size="13">12 updates available</text><text x="370" y="256" fill="#a6adc8">✕</text><text x="38" y="276" fill="#a6adc8">linux, mesa, firefox and 9 more</text></g></svg></div>

**What it is.** A side panel with every open notification, grouped by app, newest first. It has a do-not-disturb toggle, "clear all", per-app "clear", and closes when you click outside it or press Esc.

**Kind:** own window · **Needs:** the notification service, Hyprland (for click-outside-to-close)

@include galleryshell/system/NotificationCenter.qml

::: walk
@ 14-15 | Opening
`open` toggles the panel; `qs ipc call notifcenter toggle` does it from a keybind. The bar bell in [[ch:g10-full-shell]] sets `open` directly.
@ 17-27 | Grouping
Walk the list newest first. The first time an app is seen it gets a group (remembering its order), and every notification is pushed into its app's group. The result is a list of groups, ordered by each app's latest notification.
@ 29-39 | The panel
Created only while open. It's anchored to the top, bottom and right edges, so it's as tall as the screen minus the margins. `OnDemand` keyboard focus lets Esc work without stealing the keyboard permanently.
@ 41-42 | Click outside to close
[[HyprlandFocusGrab]] makes Hyprland send `cleared` when you click anywhere outside the listed windows.
@ 54-68 | Header
Title, a do-not-disturb button that flips `Notifs.dnd`, and "Clear all" when there is something to clear.
@ 70-77 | Empty state
A friendly message when the list is empty, centred with spacers.
@ 79-96 | Groups
A `ListView` of groups, each with the app's icon and name and a "Clear" that dismisses the whole group.
@ 97-127 | Notifications
Each notification is a card with its summary, a close button that appears on hover, and up to three lines of body text.
:::

::: exercise practice | Time stamps
Show how long ago each notification arrived ("2 min", "1 h").
--- hint
Notifications don't carry a time. Record `Date.now()` in a map keyed by `n.id` inside the service's `onNotification`, and expose a helper `Notifs.age(n)`.
:::

## Lock Screen

<div class="preview"><svg width="440" height="260" viewBox="0 0 440 260"><rect width="440" height="260" rx="12" fill="#11111b"/><text x="220" y="100" fill="#cdd6f4" font-size="64" font-weight="700" text-anchor="middle">14:32</text><text x="220" y="130" fill="#a6adc8" font-size="15" text-anchor="middle">Saturday, 22 November</text><g><rect x="100" y="164" width="240" height="44" rx="22" fill="#1e1e2e" stroke="#f38ba8" stroke-width="2"><animateTransform attributeName="transform" type="translate" values="0 0;-8 0;8 0;-8 0;8 0;0 0;0 0" keyTimes="0;.05;.1;.15;.2;.25;1" dur="4s" repeatCount="indefinite"/></rect></g><text x="220" y="191" fill="#cdd6f4" font-size="16" text-anchor="middle" letter-spacing="4">●●●●●●</text><text x="220" y="232" fill="#f38ba8" font-size="12" text-anchor="middle">Wrong password</text></svg></div>

**What it is.** A real, secure lock screen: a big clock and a password field on every screen. It checks your normal login password, shakes on a wrong one, and also responds to `loginctl lock-session`, so power menus and suspend hooks lock with it.

**Kind:** session · **Needs:** a compositor with ext-session-lock (Hyprland, Sway, niri…), PAM

@include galleryshell/system/LockScreen.qml

::: walk
@ 9-10 | Why this is secure
[[WlSessionLock]] uses the ext-session-lock protocol: the **compositor** hides everything else and sends all input to the lock surfaces. If the shell crashed while locked, the compositor would keep the screen locked (showing a blank or red screen) instead of revealing your desktop.
@ 13-15 | State
The typed password, an error message, and `busy` while PAM is checking.
@ 17-21 | Trying to unlock
Ignore Enter while already checking or with an empty field, then start a PAM conversation.
@ 23-31 | Listening to logind
`loginctl lock-session` doesn't lock anything by itself; it sends a `Lock` signal on the system bus and expects a locker to react. `gdbus monitor` prints every signal from logind as a line; when a `Session.Lock` line appears, we lock. Now any tool that uses the standard way of locking (power menus, `systemctl suspend` hooks, idle daemons) locks with this screen.
@ 33-42 | PAM
[[PamContext]] runs the same authentication as your login (the `login` PAM service by default). When PAM asks a question that needs an answer, we reply with the typed password. On success, the password is cleared and `Session.locked` becomes false; otherwise the error is set.
@ 44-49 | One surface per screen
`WlSessionLock` creates a `WlSessionLockSurface` for every screen automatically.
@ 57-66 | Clock and date
Updated every second.
@ 67-73 | The field
Its outline is red after an error and purple while focused.
@ 75-84 | Shaking
A `Translate` transform with a short left-right animation. It's started whenever `error` changes to something non-empty.
@ 86-98 | The input
Dots instead of characters. Every screen's input is bound to the same `root.password`, so typing on one monitor shows on all. Typing clears the error; Enter tries to unlock.
@ 99-110 | Hint and error
"Password" (or "Checking…") while the field is empty, and the error message below.
:::

> [!WARNING] Test it safely first
> Before relying on it, test with a second way back in: keep a TTY login available (Ctrl+Alt+F3), or temporarily add an IPC function that unlocks. A typo in a lock screen can lock you out of your session.

::: exercise practice | Show the user and avatar
Show `Quickshell.env("USER")` and the image at `~/.face` above the field, in a round clip.
:::

## Polkit Agent

<div class="preview"><svg width="460" height="270" viewBox="0 0 460 270"><rect width="460" height="270" fill="#000" opacity=".55"/><rect x="20" y="10" width="420" height="250" rx="22" fill="#1e1e2e" stroke="#313244"/><text x="44" y="56" fill="#cba6f7" font-size="30">🛡</text><text x="88" y="52" fill="#cdd6f4" font-size="18" font-weight="700">Authentication required</text><text x="44" y="86" fill="#a6adc8" font-size="13">Authentication is needed to run `/usr/bin/gparted'</text><text x="44" y="104" fill="#585b70" font-size="10">org.archlinux.pkexec.gparted</text><rect x="44" y="118" width="372" height="44" rx="22" fill="#313244" stroke="#cba6f7" stroke-width="2"/><text x="64" y="146" fill="#6c7086" font-size="14">Password:</text><rect x="196" y="200" width="100" height="36" rx="18" fill="#313244"/><text x="246" y="223" fill="#cdd6f4" text-anchor="middle">Cancel</text><rect x="304" y="200" width="120" height="36" rx="18" fill="#cba6f7"/><text x="364" y="223" fill="#1e1e2e" font-weight="700" text-anchor="middle">Authenticate</text></svg></div>

**What it is.** The dialog that appears when an app needs administrator rights (GParted, `pkexec`, installing a package from a GUI store). It shows what the app wants to do and asks for your password, styled like the rest of your shell.

**Kind:** session · **Needs:** polkit (no other polkit agent running)

@include galleryshell/system/PolkitAgent.qml

::: walk
@ 7-8 | One agent per session
polkit asks a registered **agent** to talk to the user. Only one can be registered, so remove `exec-once = /usr/lib/polkit-gnome/...` or `hyprpolkitagent` from your config.
@ 12 | Registering
Creating a [[PolkitAgent]] registers the shell as the session's agent.
@ 14-23 | Only while asked
`isActive` is true while a request is in progress, so the dialog exists only then. It dims the screen and takes the keyboard. `flow` is the current request.
@ 40-49 | What and who
`message` is the human-readable request from the app. `actionId` names the exact permission, useful when you wonder what is asking.
@ 50-71 | The answer field
`responseVisible` tells you whether the expected answer is secret (a password) or not (some PAM setups ask other questions). The placeholder shows polkit's own prompt, such as "Password:". Enter submits, Esc cancels.
@ 72-77 | Feedback
After a wrong password `failed` is set and polkit asks again; extra messages from PAM (like "fingerprint not recognised") are shown too.
@ 78-91 | Buttons
Cancel tells the app it was refused; Authenticate submits.
:::

Test it with `pkexec true`: the dialog should appear, and a correct password ends with no output.

::: exercise practice | Choose the identity
When several users are allowed (say, a second admin account), `flow.identities` lists them. Add a dropdown that sets `flow.selectedIdentity`.
:::

## Battery Warnings

<div class="preview"><svg width="460" height="80" viewBox="0 0 460 80"><rect x="8" y="8" width="444" height="48" rx="16" fill="#f38ba8"><animate attributeName="opacity" values="1;.75;1" dur="1.2s" repeatCount="indefinite"/></rect><text x="28" y="40" fill="#1e1e2e" font-size="20">🪫</text><text x="62" y="38" fill="#1e1e2e" font-size="13" font-weight="700">Battery critical: 5%. Plug in now, the computer will suspend at 3%.</text></svg></div>

**What it is.** A notification at 15%, a pulsing red banner on every screen at 5%, and an automatic suspend at 3%, so your laptop never just dies with unsaved work. Plugging in resets it.

**Kind:** background service with windows · **Needs:** UPower

@include galleryshell/system/BatteryWarning.qml

::: walk
@ 10-15 | Thresholds and state
Three levels you can change. `UPower.onBattery` is true when running on battery.
@ 17-18 | What was shown
`level` remembers which warning has already been given, so each one is shown once per discharge, not on every percentage change.
@ 20-21 | When to check
On every percentage change. Plugging in resets the warnings and closes the banner.
@ 23-31 | The checks
Only on laptops while discharging. The order matters: the most serious level is checked first. The low warning is a normal notification (from `notify-send`, which works with any notification daemon, including ours).
@ 33-38 | The banner
`Variants` with a model of either all screens or none: setting `bannerOpen` creates a banner on every monitor at once.
@ 45-67 | The banner's content
A pulsing red bar with the message and a close button. Closing it doesn't stop the suspend at 3%.
:::

::: exercise practice | Charging popup
Combine it with the charging popup from [[ch:g3-islands-popups]] so plugging in also shows that.
:::

## Workspace OSD

<div class="preview"><svg width="420" height="110" viewBox="0 0 420 110"><rect x="40" y="13" width="340" height="84" rx="24" fill="#1e1e2e"/><g font-size="18" font-weight="700" text-anchor="middle"><rect x="60" y="29" width="44" height="52" rx="14" fill="#45475a"/><text x="82" y="62" fill="#cdd6f4">1</text><rect x="112" y="29" width="44" height="52" rx="14" fill="#313244"/><text x="134" y="62" fill="#6c7086">2</text><rect x="164" y="29" width="64" height="52" rx="14" fill="#cba6f7"/><text x="196" y="62" fill="#1e1e2e">3</text><rect x="236" y="29" width="44" height="52" rx="14" fill="#45475a"/><text x="258" y="62" fill="#cdd6f4">4</text><rect x="288" y="29" width="44" height="52" rx="14" fill="#313244"/><text x="310" y="62" fill="#6c7086">5</text></g></svg></div>

**What it is.** When you switch workspace, a row of numbered boxes flashes in the middle of the screen with the new one highlighted, like on GNOME or macOS. Workspaces with windows are brighter.

**Kind:** OSD · **Needs:** Hyprland

@include galleryshell/system/WorkspaceOsd.qml

::: walk
@ 10-12 | State
`current` is the focused workspace. `count` is at least 5, or the highest workspace number in use.
@ 14-18 | When to show
Every change of the focused workspace shows the OSD and restarts a 900 ms hide timer. `armed` skips the change that happens when the shell starts and first learns the current workspace.
@ 20-28 | The window
Created only while shown, on the screen of the focused monitor (matching the Hyprland monitor's name with the screen's). With no anchors, a layer-shell window is centred.
@ 37-54 | The boxes
The active one is wider and purple, used ones are lighter. The width change bounces a little.
:::

::: exercise practice | Show app icons
Show the icons of each workspace's windows inside its box, like the workspace list in [[ch:g7-bar-modules-2]].
:::

## Region Selector

<div class="preview"><svg width="440" height="250" viewBox="0 0 440 250"><rect width="440" height="250" fill="#45475a"/><rect x="40" y="30" width="160" height="80" rx="6" fill="#89b4fa" opacity=".6"/><rect x="230" y="120" width="170" height="100" rx="6" fill="#a6e3a1" opacity=".6"/><path d="M0 0H440V250H0Z M120 70V190H330V70Z" fill="#000" opacity=".5" fill-rule="evenodd"/><rect x="120" y="70" width="210" height="120" fill="none" stroke="#cba6f7" stroke-width="2"/><rect x="250" y="196" width="80" height="22" rx="6" fill="#1e1e2e"/><text x="290" y="211" fill="#cdd6f4" font-size="11" text-anchor="middle">420 × 240</text></svg></div>

**What it is.** Drag a rectangle on any screen; the rest of the screen darkens and the size is shown. Then the region is screenshotted, screen-recorded, or printed for scripts. A themed replacement for `slurp`.

**Kind:** overlay with IPC · **Needs:** `grim` and `wl-clipboard` (screenshots), `wf-recorder` (recording)

@include galleryshell/system/RegionSelector.qml

::: walk
@ 13-18 | Three uses
`qs ipc call region screenshot`, `record` or `geometry`. The last one prints the geometry to the shell's log, for your own scripts.
@ 20-30 | What happens after
The geometry is formatted like slurp's, `X,Y WxH`, and passed as an argument to a small shell script: take a screenshot and copy it, or start recording that area. `sleep 0.2` gives the overlay time to disappear before the capture.
@ 32-42 | An overlay on every screen
While active, a fullscreen transparent window covers each monitor, so you can start dragging on any of them.
@ 44-48 | The selection
Start and end points of the drag. `sel` turns them into a normal rectangle whatever direction you drag in.
@ 50-55 | Darkening the rest
Before dragging, one rectangle darkens the whole screen. While dragging, four rectangles darken the areas above, below, left and right of the selection, leaving it clear.
@ 57-66 | Outline and size
A purple frame and a small label with the size.
@ 75-88 | Mouse input
Press starts, move updates, release finishes. A click without a drag cancels. Window coordinates plus the screen's position give global coordinates, which is what grim expects when you have several monitors.
:::

::: exercise challenge | Snap to windows
Clicking (without dragging) on a window should select that window's area.
--- hint
`Hyprland.toplevels` gives every window; `lastIpcObject.at` and `.size` are its global position and size. Convert to this screen's coordinates and test which one contains the click.
:::

## Wallpaper

**What it is.** The shell draws the wallpaper itself on the background layer of every screen, with a crossfade when it changes, and remembers your choice. No swww or hyprpaper needed.

**Kind:** background · **Needs:** nothing extra

@include galleryshell/system/Wallpaper.qml

::: walk
@ 10-13 | Which image
The saved path, or a default. `set()` saves a new one.
@ 15-22 | Remembering it
A [[FileView]] with a [[JsonAdapter]] stores the path in the shell's state folder. Changing `saved.path` writes the file; `watchChanges` means editing the file by hand also works.
@ 24-28 | From the terminal
`qs ipc call wallpaper set ~/Pictures/wall.png`. Scripts and other tools (matugen, a wallpaper rotator) can use this.
@ 30-40 | One window per screen
On the **background** layer, below everything, including desktop widgets on the bottom layer.
@ 42-52 | Two images
The `Layer` component sets up an image that fills the screen and fades its opacity. `sourceSize` makes Qt decode a 6000-pixel photo at screen size, which saves a lot of memory.
@ 53-63 | Taking turns
`a` loads the first wallpaper once, in `Component.onCompleted`, and deliberately not as a binding: a binding would make `a` reload too whenever the path changed. Whichever image finishes loading becomes the visible one.
@ 65-71 | Changing wallpaper
The new file is loaded into the hidden image. When it's ready, its status handler swaps `showA`, and the two opacity behaviours crossfade.
:::

## Wallpaper Picker

<div class="preview"><svg width="460" height="170" viewBox="0 0 460 170"><rect x="5" y="5" width="450" height="160" rx="24" fill="#1e1e2e" stroke="#313244"/><rect x="21" y="27" width="130" height="116" rx="14" fill="#89b4fa" opacity=".7"/><rect x="161" y="21" width="140" height="128" rx="16" fill="#f5c2e7" stroke="#cba6f7" stroke-width="3"/><circle cx="283" cy="39" r="12" fill="#cba6f7"/><text x="283" y="44" fill="#1e1e2e" font-size="13" text-anchor="middle">✓</text><rect x="311" y="27" width="130" height="116" rx="14" fill="#a6e3a1" opacity=".7"/></svg></div>

**What it is.** A strip of thumbnails from your wallpaper folder, newest first. Hover or use the arrow keys to move, click or Enter to apply. The current wallpaper has a check mark.

**Kind:** overlay with IPC · **Needs:** the Wallpaper above (or `swww` as a fallback)

@include galleryshell/system/WallpaperPicker.qml

::: walk
@ 11-14 | Settings
The folder to read, and `target`: the Wallpaper object to control. In `shell.qml` that's `WallpaperPicker { target: wallpaper }`.
@ 18-24 | Finding images
`find` lists jpg, png and webp files up to one folder deep, prefixed with their modification time; `sort -rn` puts the newest first and `cut` removes the time again. The folder is passed as `$1`, so spaces in its name are fine. The scan reruns every time the picker opens.
@ 26-29 | Applying
Through the Wallpaper object if there is one, otherwise with `swww`.
@ 51-63 | A horizontal list
`ApplyRange` with a highlight range in the middle keeps the selected thumbnail near the centre as you move. It starts on the current wallpaper.
@ 65-71 | Thumbnails
`current` for the selection, `inUse` for the active wallpaper.
@ 73-92 | Drawing a thumbnail
`sourceSize.width: 340` decodes each photo small, which keeps a folder of large wallpapers fast and light. The selected one is full size; the others are shrunk to 94%.
@ 93-94 | Mouse
Hovering selects, clicking applies.
:::

::: exercise practice | Generate colours too
After applying a wallpaper, also run `matugen image <path>` so the theme from [[ch:th7-beyond-the-shell]] follows it.
:::

## Dock

<div class="preview"><svg width="460" height="110" viewBox="0 0 460 110"><rect x="90" y="36" width="280" height="62" rx="20" fill="#1e1e2e" stroke="#313244"/><circle cx="130" cy="64" r="20" fill="#fab387"/><rect x="125" y="88" width="10" height="4" rx="2" fill="#cba6f7"/><circle cx="182" cy="56" r="26" fill="#89b4fa"/><rect x="176" y="88" width="4" height="4" rx="2" fill="#a6adc8"/><rect x="183" y="88" width="4" height="4" rx="2" fill="#a6adc8"/><circle cx="236" cy="64" r="20" fill="#a6e3a1"/><circle cx="284" cy="64" r="20" fill="#f9e2af"/><rect x="282" y="88" width="4" height="4" rx="2" fill="#a6adc8"/><circle cx="332" cy="64" r="20" fill="#f5c2e7"/><rect x="330" y="88" width="4" height="4" rx="2" fill="#a6adc8"/></svg></div>

**What it is.** A macOS-style dock: pinned apps plus running ones, dots for open windows, icons that grow on hover. Click launches, focuses or cycles windows; middle-click opens a new window. It slides away when a maximized or fullscreen window would cover it and comes back when you touch the bottom edge.

**Kind:** own window · **Needs:** nothing extra

@include galleryshell/system/Dock.qml

::: walk
@ 11 | Pinned apps
App ids or desktop file names. Change the list to your favourites.
@ 13-19 | The app list
Pinned apps first, then every running app that isn't pinned, each once.
@ 20 | Windows per app
All windows whose app id matches.
@ 24-33 | One dock per screen
A bottom-anchored window, wider than the dock so magnified icons have room, and 90 px tall for the hover zoom.
@ 35-37 | Hiding
`covered` is true when a maximized or fullscreen window is on this screen. The dock shows when not covered, or while the pointer is over it.
@ 38-41 | Input mask
While hidden, only a 4 px strip along the bottom accepts the pointer, so you can still click windows above it. While shown, the dock and the gap below it accept the pointer, so moving down onto the edge doesn't make it disappear under you.
@ 43-56 | Sliding
The dock's `y` moves it below the window edge to hide it; a `Behavior` makes that a slide.
@ 64-71 | One app
Its desktop entry (for the icon and launching), its windows, and whether one of them is focused. The slot widens as its icon grows, pushing neighbours aside.
@ 73-81 | Magnification
Hovered icons scale to 130% from their bottom edge, so they grow upward.
@ 82-89 | Window dots
Up to three dots; a wide purple one when the app is focused.
@ 91-99 | Clicks
No windows: launch the app. Not focused: focus its first window. Already focused: focus the next one, cycling. Middle-click always launches a new instance.
:::

::: exercise practice | Pin from the dock
Right-click a running app to pin or unpin it, and save `pinned` with a `FileView` + `JsonAdapter` like the wallpaper.
:::

## App Launcher

<div class="preview"><svg width="440" height="300" viewBox="0 0 440 300"><rect x="10" y="6" width="420" height="288" rx="24" fill="#1e1e2e" stroke="#313244"/><rect x="24" y="20" width="392" height="48" rx="24" fill="#313244"/><text x="44" y="50" fill="#a6adc8" font-size="16">⌕</text><text x="70" y="50" fill="#cdd6f4" font-size="16">fi</text><g font-size="14"><rect x="24" y="78" width="392" height="52" rx="14" fill="#45365e"/><circle cx="52" cy="104" r="16" fill="#fab387"/><text x="80" y="100" fill="#cdd6f4">Firefox</text><text x="80" y="118" fill="#6c7086" font-size="11">Browse the World Wide Web</text><circle cx="52" cy="160" r="16" fill="#89b4fa"/><text x="80" y="156" fill="#cdd6f4">Files</text><text x="80" y="174" fill="#6c7086" font-size="11">Access and organize files</text><circle cx="52" cy="216" r="16" fill="#a6e3a1"/><text x="80" y="212" fill="#cdd6f4">FileZilla</text><text x="80" y="230" fill="#6c7086" font-size="11">FTP client</text><circle cx="52" cy="270" r="16" fill="#f9e2af"/><text x="80" y="275" fill="#cdd6f4">GIMP</text></g></svg></div>

**What it is.** A keyboard-first launcher: start typing, the best match is already selected, press Enter. Prefix matches rank first, keywords count ("browser" finds Firefox), and apps you launch often float to the top.

**Kind:** overlay with IPC · **Needs:** nothing extra

@include galleryshell/system/Launcher.qml

::: walk
@ 15-21 | Launch counts
A small JSON file in the state folder maps desktop entry ids to how often you launched them.
@ 23-32 | Scoring a match
Higher is better: the name starts with the query (100), a word in the name does ("code" in "Visual Studio Code", 60), the name contains it (40), then the generic name ("Web Browser", 20) and keywords (15). An empty query matches everything.
@ 33-42 | Building the result list
Hidden entries (`noDisplay`) are dropped. Each app gets its match score plus a frequency bonus of up to 30. The second filter keeps only apps whose **match** score is above zero, so a frequently used app doesn't show up for an unrelated query. Then: sort by score, then by name, keep the top 50.
@ 43-49 | Launching
Update the count, then `execute()` the desktop entry (which handles field codes and terminal apps). The counts object is copied, changed and assigned back: changing a key inside a `var` property wouldn't be noticed, but assigning a new object is, and that triggers the save.
@ 53-60 | The window
`shown` recomputes whenever the search text changes.
@ 74-88 | The search field
Focus never leaves it: arrows and Tab move the selection, Enter launches it, Esc closes. Every new query selects the first (best) result again.
@ 91-123 | Results
Icon, name and description. The current row is highlighted; clicking launches too.
:::

::: exercise practice | Actions
Desktop entries have `actions` ("New Private Window"). Show them when you press the right arrow on a result.
--- hint
`row.modelData.actions` is a list of `DesktopAction`s with `name`, `icon` and `execute()`.
:::

## Idle Manager

**What it is.** Replaces hypridle: the screen dims after 4 minutes, locks after 5, turns off after 6, and the machine suspends after 15. Video players and games that ask for no idle are respected, and the caffeine toggle pauses everything.

**Kind:** background service · **Needs:** a compositor with ext-idle-notify (Hyprland, Sway, niri…)

@include galleryshell/system/IdleManager.qml

::: walk
@ 11-14 | One idle stage
[[IdleMonitor]] becomes `isIdle` after `timeout` seconds without input and goes back to false on any input. Every stage shares two settings: disabled while caffeine is on, and respecting idle inhibitors (apps like mpv or Firefox playing video inhibit idle).
@ 16-34 | Dim
After 4 minutes, a black overlay fades to 60% on every screen. An empty `Region {}` mask means it takes no input. Any movement ends idle, which removes the overlay.
@ 36-37 | Lock
At 5 minutes, lock.
@ 39-43 | Screens off
At 6 minutes, `dpms off`; when you return, `dpms on`. The same handler does both directions.
@ 45-49 | Suspend
Lock first, so the machine wakes up locked.
:::

::: exercise practice | Different times on battery
Use shorter timeouts when `UPower.onBattery` is true.
--- solution
```qml
Stage { timeout: UPower.onBattery ? 120 : 300; onIsIdleChanged: if (isIdle) Session.locked = true }
```
(and `import Quickshell.Services.UPower`).
:::
