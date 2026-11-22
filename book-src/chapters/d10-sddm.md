# Desktop Ricing 10: SDDM Ricing

SDDM is the login screen most Linux rices use, and its themes are **QML**, the same language as your Quickshell shell. Everything you've learned applies: components, bindings, models, animations. This chapter builds a complete theme in several files: a blurred background, a big clock, a **row of users with avatars**, a password box with a **Caps Lock warning** and a show-password button, a **session menu**, the **keyboard layout**, power buttons, and settings in `theme.conf`. It also ships a **preview** that runs the theme without SDDM.

<div class="preview"><svg width="640" height="360" viewBox="0 0 640 360"><defs><radialGradient id="sg" cx="50%" cy="45%" r="70%"><stop offset="0" stop-color="#1d2340"/><stop offset="1" stop-color="#050508"/></radialGradient></defs><rect width="640" height="360" fill="url(#sg)"/><text x="320" y="92" fill="#c0caf5" font-size="56" font-weight="700" text-anchor="middle">16:06</text><text x="320" y="118" fill="#a9b1d6" font-size="12" text-anchor="middle">Sunday, 22 November</text><circle cx="250" cy="170" r="20" fill="#24283b" stroke="#414868" stroke-width="3"/><text x="250" y="176" fill="#c0caf5" font-size="15" text-anchor="middle" font-weight="700">S</text><circle cx="320" cy="166" r="27" fill="#24283b" stroke="#7aa2f7" stroke-width="4"/><text x="320" y="174" fill="#c0caf5" font-size="20" text-anchor="middle" font-weight="700">A</text><circle cx="390" cy="170" r="20" fill="#24283b" stroke="#414868" stroke-width="3"/><text x="390" y="176" fill="#c0caf5" font-size="15" text-anchor="middle" font-weight="700">G</text><text x="250" y="205" fill="#545c7e" font-size="9" text-anchor="middle">Sam Rivera</text><text x="320" y="208" fill="#c0caf5" font-size="10" text-anchor="middle">Alex Kim</text><text x="390" y="205" fill="#545c7e" font-size="9" text-anchor="middle">guest</text><rect x="225" y="224" width="190" height="30" rx="15" fill="#1a1b26" stroke="#7aa2f7" stroke-width="2"/><text x="240" y="243" fill="#545c7e" font-size="11">Password</text><text x="395" y="243" fill="#545c7e" font-size="8" text-anchor="end">show</text><text x="320" y="272" fill="#e0af68" font-size="9" text-anchor="middle">Caps Lock is on</text><rect x="20" y="326" width="70" height="22" rx="11" fill="#1a1b26"/><text x="32" y="341" fill="#c0caf5" font-size="9">Hyprland ▴</text><rect x="96" y="326" width="30" height="22" rx="11" fill="#1a1b26"/><text x="104" y="341" fill="#c0caf5" font-size="9">US</text><g font-size="9" fill="#c0caf5"><rect x="440" y="326" width="56" height="22" rx="11" fill="#1a1b26"/><text x="450" y="341">Suspend</text><rect x="502" y="326" width="52" height="22" rx="11" fill="#1a1b26"/><text x="512" y="341">Restart</text><rect x="560" y="326" width="62" height="22" rx="11" fill="#1a1b26"/><text x="570" y="341">Shut down</text></g></svg></div>

*The theme as `preview.sh` shows it, with stand-in users.*

## What SDDM gives a theme

SDDM loads the theme's main QML file once per monitor and makes five objects available **by name**:

| Object | What it has |
|---|---|
| `sddm` | `login(user, password, sessionIndex)`, `powerOff()`, `reboot()`, `suspend()`, `hibernate()`; `canPowerOff`, `canReboot`, `canSuspend`…; signals `loginFailed()` and `loginSucceeded()` |
| `userModel` | a list model of users with roles `name` (login name), `realName`, `icon` (avatar path), `needsPassword`; plus `lastIndex` and `lastUser` |
| `sessionModel` | a list model of sessions with roles `name`, `comment`, `file`; plus `lastIndex` |
| `keyboard` | `capsLock`, `numLock`, `layouts` (each with `shortName` and `longName`) and `currentLayout` (settable) |
| `config` | every `key=value` from the `[General]` section of `theme.conf`, as text |

There's no Quickshell here: SDDM runs the theme in plain Qt Quick, so only `QtQuick` (and modules like `QtQuick.Effects`) are available. The theme also runs **before anyone is logged in**, as the `sddm` user, so it can't read files in your home folder; everything it needs (the wallpaper too) lives in the theme folder.

## The files

```text
tokyo-night/
├── metadata.desktop         name, main file, config file, Qt 6
├── theme.conf               the settings users can change
├── background.jpg
├── Main.qml                 the screen: puts the components together
├── components/
│   ├── Theme.qml            colours + settings, converted from text
│   ├── Clock.qml
│   ├── UserList.qml         the row of users
│   ├── PasswordBox.qml
│   ├── SessionPicker.qml
│   └── PowerBar.qml
├── preview/Preview.qml      stand-ins for SDDM's objects
└── preview.sh               run or screenshot the theme without SDDM
```

@include desktop/sddm/tokyo-night/metadata.desktop

`MainScript` and `ConfigFile` name the two files SDDM loads, and `QtVersion=6` makes SDDM use its Qt 6 greeter (Qt 5 is the default on some versions). `Screenshot` is shown by theme pickers like KDE's settings.

@include desktop/sddm/tokyo-night/theme.conf

The settings a user can change without touching QML. SDDM also reads `theme.conf.user` next to it, if it exists, and its values win: that's how settings tools save changes without editing your file.

## Theme: colours and settings

@include desktop/sddm/tokyo-night/components/Theme.qml

::: walk
@ 6-7 | A plain object
A `QtObject` with no visuals, created once in `Main.qml` and passed to every component. `conf` is SDDM's `config`.
@ 9-18 | Colours
The accent comes from the settings; the rest is the palette. Components use names like `theme.accent`, never hex codes.
@ 20-25 | Settings, converted
`config` values are always **text**. `Number(...)` turns "0.6" into 0.6; `String(...) === "true"` turns "true" into a real boolean (otherwise the text "false" would count as true). Each has a default, in case the line is missing.
:::

## The screen

@include desktop/sddm/tokyo-night/Main.qml

::: walk
@ 3 | Local components
`import "components"` makes every file in `components/` available by its name.
@ 5-10 | What SDDM provides
The five objects above, by name. Nothing in this file declares them.
@ 11-17 | The root and the theme object
A full-screen rectangle; SDDM sizes it to each monitor. `Theme` wraps `config`.
@ 19-35 | Background
The picture from `theme.conf`. A relative name like `background.jpg` is resolved next to `Main.qml`, so the file sits in the theme folder. It's hidden and drawn through [[MultiEffect]], blurred and darkened by the amounts in the settings.
@ 37-42 | Clock
Centred, 12% from the top.
@ 44-64 | Who
The row of users, or, if `showUsers=false`, just the last user's name (for single-user machines, or for privacy: not listing users).
@ 66-72 | Password
The password box gets the Caps Lock state straight from `keyboard`. When it's submitted, `sddm.login()` gets the selected user's login name, the password and the selected session's index.
@ 75-80 | SDDM's answer
On failure, the password box shows the error, clears itself and shakes. On success, SDDM starts the session and this screen goes away.
@ 82-111 | Session and layout
The session menu, and the keyboard layout as a two-letter code; clicking it moves to the next layout. Hidden when there's only one.
@ 113-120 | Power
Bottom right.
@ 122 | Focus
The password field gets the keyboard at once, so you can start typing.
:::

## The users

@include desktop/sddm/tokyo-night/components/UserList.qml

::: walk
@ 6-9 | A horizontal list
It gets the theme and publishes `selectedName`, the login name of the selected user.
@ 10-22 | Behaviour
At most five avatars wide; starts on the user who logged in last (`lastIndex`); keeps the selected user in the middle with a short slide.
@ 24-30 | A user
`required property` declarations receive the model's roles: `name`, `realName` and `icon`. The same code works with SDDM's model and with the preview's `ListModel`.
@ 35-36 | Publishing the name
A `Binding` that's active only on the current delegate copies its name to the list. Reading a model row from outside the delegate is awkward in QML; letting the selected delegate report itself is simpler.
@ 38-72 | The avatar
An accent ring around a circle when selected (bigger, a little higher), a grey ring otherwise. Inside, the user's initial, covered by their avatar picture if it loads. SDDM finds avatars in `/usr/share/sddm/faces/<user>.face.icon` or `~/.face.icon` (readable by the `sddm` user).
@ 73-85 | The name
The real name, or the login name when there's none.
@ 86 | Clicking selects
:::

## The password box

@include desktop/sddm/tokyo-night/components/PasswordBox.qml

::: walk
@ 8-13 | Interface
In: the Caps Lock state. State: busy while SDDM checks, and an error message. Out: `submitted(password)`.
@ 15-16 | Failing and focusing
`fail()` shows the message, clears the field, shakes and takes focus back, ready for another try.
@ 21-30 | The pill
Its border is red on an error, the accent while focused, grey otherwise, fading between them.
@ 31-39 | The shake
A `Translate` moved left and right twice by an animation.
@ 41-58 | The field
Dots, or plain text when the eye button is on. Disabled while busy, so you can't press Enter twice. Typing clears the error. Enter submits if there's anything typed.
@ 59-68 | Placeholder
"Password", or "Logging in…" while busy.
@ 70-82 | Show and hide
A small text button that flips between dots and text, for checking a long password.
@ 85-95 | Hints
The error if there is one, otherwise a warning when Caps Lock is on: the most common reason for "wrong password".
:::

## Sessions and power

@include desktop/sddm/tokyo-night/components/SessionPicker.qml

A pill showing the current session that opens a list **upward** (it sits at the bottom of the screen). `currentIndex` starts at the last session used; the current entry publishes its name with the same `Binding` trick as the users. Picking an entry sets the index and closes the list.

@include desktop/sddm/tokyo-night/components/PowerBar.qml

Three buttons from a small list of `{ label, allowed, run }`. Each is hidden when SDDM says the machine can't do it (`canSuspend` is false on many desktops). "Shut down" turns red on hover.

@include desktop/sddm/tokyo-night/components/Clock.qml

## Previewing without SDDM

@include desktop/sddm/tokyo-night/preview/Preview.qml

::: walk
@ 10-24 | A fake `sddm`
The same functions and signals as the real one. `login()` prints what it received and "succeeds" only for the password `secret`, so you can test both answers.
@ 25-38 | Users and sessions
`ListModel`s with the same role names as SDDM's models, plus `lastIndex`/`lastUser` properties.
@ 39-45 | Keyboard
Caps Lock on, so the warning shows; two layouts, so the layout button appears.
@ 46-56 | Config
The same keys as `theme.conf`, as text, exactly as SDDM passes them.
@ 58 | Loading the theme
A `Loader` loads `Main.qml`. Objects declared with an `id` in this file are visible to the loaded theme by name, just as SDDM's objects are.
@ 60-67 | Screenshots
When a `.png` file name is passed on the command line, wait for the theme to settle, save a picture of it, and quit.
:::

@include desktop/sddm/tokyo-night/preview.sh

```bash
./preview.sh                 # a window: type "secret", or anything else to see the failure
./preview.sh shot.png        # a screenshot
```

The screenshot mode opens a window for a moment on purpose: the blur needs a real GPU surface, and an offscreen run leaves it out (the background comes out flat). SDDM's own test mode works too, once SDDM is installed:

```bash
sddm-greeter-qt6 --test-mode --theme /path/to/tokyo-night
```

## Installing

```bash
sudo cp -r tokyo-night /usr/share/sddm/themes/
sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=tokyo-night\n' | sudo tee /etc/sddm.conf.d/theme.conf
```

Then log out (or `sudo systemctl restart sddm`, which ends your session). If the theme has an error, SDDM falls back to a plain built-in screen, so you can still log in; `journalctl -b -u sddm` shows the QML error. To use your own wallpaper, copy it into the theme folder (SDDM can't read your home folder) and set `background=` in `theme.conf`.

## Ready-made themes

Read them to learn more tricks: Keyitdev/sddm-astronaut-theme (many variants, video backgrounds), catppuccin/sddm, and KDE's Breeze theme in `/usr/share/sddm/themes/breeze/`. They use the same objects (`sddm`, `userModel`, `sessionModel`, `keyboard`, `config`).

::: exercise warm | Your look
Change the accent, the clock format (`h:mm AP` for 12-hour) and the background in `theme.conf`, then preview.
:::

::: exercise practice | Keyboard user switching
Let Left and Right switch users while the password field is empty.
--- hint
In `PasswordBox`, add `Keys.onLeftPressed: e => { if (text === "") userSwitch(-1); else e.accepted = false; }` with a `signal userSwitch(int delta)`, and in `Main.qml` move `users.currentIndex`.
:::

::: exercise practice | Match your Quickshell lock screen
Make the SDDM screen and your shell's lock screen ([[ch:ly9-lock-power]]) look the same, so logging in and unlocking feel like one thing.
:::

::: exercise challenge | A video background
Use `QtMultimedia`'s `Video` instead of the `Image` (with `loops: MediaPlayer.Infinite` and `muted: true`), falling back to the picture when the video can't play.
:::
