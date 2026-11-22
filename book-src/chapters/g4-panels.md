# Gallery: Panels and Menus

Bigger pieces of UI that open on demand: quick settings, an app grid, a power menu, pickers. Each is shown standalone with an IPC toggle so you can open it with `qs -c gallery ipc call <name> toggle`. For the full versions wired into a complete shell, see Part VI.

## Quick Settings Tiles

<div class="preview"><svg width="340" height="180" viewBox="0 0 340 180"><rect x="10" y="10" width="320" height="160" rx="22" fill="#1e1e2e"/><g font-size="12"><rect x="26" y="26" width="140" height="52" rx="16" fill="#cba6f7"/><text x="48" y="57" fill="#1e1e2e" font-weight="700">📶  Home-5G</text><rect x="174" y="26" width="140" height="52" rx="26" fill="#313244"><animate attributeName="rx" values="26;26;16;16;26" keyTimes="0;.4;.5;.9;1" dur="4s" repeatCount="indefinite"/><animate attributeName="fill" values="#313244;#313244;#cba6f7;#cba6f7;#313244" keyTimes="0;.4;.5;.9;1" dur="4s" repeatCount="indefinite"/></rect><text x="196" y="57" fill="#cdd6f4">ᛒ  Bluetooth</text><rect x="26" y="86" width="140" height="52" rx="26" fill="#313244"/><text x="48" y="117" fill="#cdd6f4">🌙  Night light</text><rect x="174" y="86" width="140" height="52" rx="16" fill="#cba6f7"/><text x="196" y="117" fill="#1e1e2e" font-weight="700">☕  Caffeine</text></g><rect x="26" y="148" width="288" height="10" rx="5" fill="#313244"/><rect x="26" y="148" width="190" height="10" rx="5" fill="#cba6f7"/></svg></div>

**What it is.** A grid of toggle tiles (Wi-Fi, Bluetooth, DND, night light, caffeine, mic) plus volume and brightness sliders. Active tiles fill with the accent color and morph from pill to rounded square.

**Kind:** its own window · **Needs:** NetworkManager, BlueZ, PipeWire (each tile hides itself if its service is missing)

@include galleryshell/panels/QuickSettings.qml

::: walk
@ 11-18 | Panel state and audio objects
`open` shows the panel. `dnd` and `caffeine` are local toggles (in a real shell they'd live in `GlobalStates`). Both the speaker (`sink`) and microphone (`source`) are tracked so their volume and mute state are live.
@ 20 | Open from a keybind
`qs ipc call quicksettings toggle`.
@ 22-33 | An inline component
`component Tile: Rectangle { … }` defines a reusable type **inside this file**, without creating `Tile.qml`. Each tile has an icon, a label, an `active` state and a `toggled` signal. When active, its corners morph from a pill (`height / 2`) to a rounded square (16) and the color fills: Material You's toggle style.
@ 34-42 | Tile content
Icon (filled when active) and label, both switching to a dark color on the accent background. The tap handler only *emits* `toggled()`: the tile doesn't know what it controls. Each usage decides.
@ 45-65 | Slider row component
An icon and a restyled `Slider`. `background` draws a thick track with a fill whose width follows `visualPosition` (0–1); `Math.max(height, …)` keeps at least a circle at 0%. `handle: Item {}` removes the knob for a clean "pill fill" look. The component re-emits `moved(v)` so the user decides what the value controls.
@ 67-75 | Window
Top-right, under a 54 px bar. It grows with its content (`col.implicitHeight + 32`).
@ 84-86 | Two-column grid
Tiles fill the width (`Layout.fillWidth` inside `Tile`), so two columns split it evenly.
@ 87-92 | Wi-Fi tile
Finds the connected network to show its name as the label. Active means Wi-Fi radio on; tapping flips it.
@ 93-98 | Bluetooth tile
Hidden on machines without an adapter. The label shows a connected device's name when there is one.
@ 99-108 | DND, night light, caffeine
Night light is a `Process` running `hyprsunset`: `running: true` starts it, `false` kills it, and killing it restores normal colors. So "is the process running?" is exactly "is night light on?".
@ 109-113 | Microphone tile
Active when **not** muted (`?? true` treats "no mic" as muted).
@ 115-119 | Volume slider
Binds the slider to the sink's volume and writes back on `moved`. Using `moved` (user drags) instead of `valueChanged` avoids a feedback loop with the binding.
@ 121 | Caffeine
The [[IdleInhibitor]] is attached to this panel's window (`panel`, the id on line 68) and enabled by the caffeine tile. The compositor only honours an inhibitor while its window is on screen, so this one works while the panel is open. To keep it working after you close the panel, move it to a window that is always visible, such as your bar. In the assembled shell ([[ch:g10-full-shell]]), the tile also sets `Session.caffeine`, which pauses the shell's own idle timers.
:::

**Customize**
- Right-click a tile to open a details page (Wi-Fi networks, Bluetooth devices): see [[ch:55-proj-control-center]].
- Add a brightness slider using the Brightness service from [[ch:53-proj-osd]].

::: exercise practice | Brightness slider
Add a brightness `SliderRow` that runs `brightnessctl set <n>%` on `moved`.
--- solution
```qml
SliderRow { icon: "light_mode"; value: 0.5
            onMoved: v => Quickshell.execDetached(["brightnessctl", "set", Math.round(v * 100) + "%"]) }
```
For a live value, read `/sys/class/backlight/*/brightness` as the Circular OSD widget does.
:::

## App Grid Launcher

<div class="preview"><svg width="380" height="220" viewBox="0 0 380 220"><rect x="10" y="10" width="360" height="200" rx="22" fill="#1e1e2e"/><rect x="30" y="26" width="320" height="34" rx="17" fill="#313244"/><text x="50" y="48" fill="#a6adc8" font-size="12">🔍  fi|</text><g><rect x="44" y="76" width="44" height="44" rx="12" fill="#fab387"/><rect x="118" y="76" width="44" height="44" rx="12" fill="#89b4fa"/><rect x="192" y="76" width="44" height="44" rx="12" fill="#a6e3a1"/><rect x="266" y="76" width="44" height="44" rx="12" fill="#f38ba8"/><rect x="44" y="144" width="44" height="44" rx="12" fill="#cba6f7"/><rect x="118" y="144" width="44" height="44" rx="12" fill="#94e2d5"/></g><rect x="36" y="70" width="60" height="64" rx="14" fill="none" stroke="#cba6f7" stroke-width="2"><animate attributeName="x" values="36;110;184;258;36" dur="4s" repeatCount="indefinite"/></rect><g fill="#a6adc8" font-size="9" text-anchor="middle"><text x="66" y="131">Firefox</text><text x="140" y="131">Files</text><text x="214" y="131">Fish</text><text x="288" y="131">Figma</text></g></svg></div>

**What it is.** A full-screen-style launcher showing installed apps as a grid of big icons; type to filter, use arrow keys to move, Enter to launch.

**Kind:** its own window · **Needs:** nothing extra

@include galleryshell/panels/AppGrid.qml

::: walk
@ 8-11 | Open state and IPC
The grid exists only while `open` (see the `LazyLoader` below).
@ 13-14 | Build on demand
`LazyLoader { active: root.open }` creates the window when opened and destroys it when closed: no memory used for hundreds of icons while hidden.
@ 15-21 | Keyboard focus
`WlrKeyboardFocus.Exclusive` gives the launcher all keyboard input so you can type immediately.
@ 23-26 | Filtering and sorting
Takes every installed app, keeps those whose name or generic name ("Web Browser") contains the search text (case-insensitive), and sorts alphabetically with `localeCompare` (correct for accents and other languages).
@ 27 | Launching
`execDetached(e.command)` starts the app independent of the shell, then the launcher closes.
@ 35-47 | Search field
- A placeholder `Text` shows only while the input is empty.
- Typing resets the selection to the first result.
- Enter launches the selected app; Esc closes.
- `Keys.forwardTo: [grid]` passes keys the input doesn't use (arrows) to the grid, so you can type and navigate without switching focus.
@ 49-57 | The grid
Six columns (`cellWidth: width / 6`). `keyNavigationEnabled` makes arrow keys move `currentIndex`. [[ScriptModel]] wraps the filtered array so items that stay in the list are kept instead of rebuilt on every keystroke. The `highlight` is drawn behind the current item and slides between cells in 100 ms.
@ 58-84 | One app cell
An icon (loaded asynchronously so the grid opens fast) that grows slightly on hover with a bounce, and an eliding name. Hovering also moves the keyboard selection, so mouse and keyboard never disagree.
:::

::: exercise practice | Frequent apps first
Sort apps you launch often first: keep a `{ appId: count }` object in a `JsonAdapter`, increment it in `launch()`, and sort by count before name.
:::

## Power Menu Bubbles

<div class="preview"><svg width="420" height="140" viewBox="0 0 420 140"><rect width="420" height="140" fill="#000" opacity=".35"/><g font-size="22" text-anchor="middle"><circle cx="70" cy="62" r="30" fill="#313244"/><text x="70" y="70" fill="#cdd6f4">🔒</text><circle cx="140" cy="62" r="30" fill="#313244"/><text x="140" y="70" fill="#cdd6f4">⏾</text><circle cx="210" cy="62" r="30" fill="#313244"/><text x="210" y="70" fill="#cdd6f4">↪</text><rect x="250" y="32" width="60" height="60" rx="18" fill="#cba6f7"><animate attributeName="rx" values="30;18;18;30" dur="3s" repeatCount="indefinite"/></rect><text x="280" y="70" fill="#1e1e2e">⟳</text><circle cx="350" cy="62" r="30" fill="#313244"/><text x="350" y="70" fill="#f38ba8">⏻</text></g><g fill="#cdd6f4" font-size="11" text-anchor="middle"><text x="70" y="114">Lock</text><text x="140" y="114">Sleep</text><text x="210" y="114">Logout</text><text x="280" y="114">Reboot</text><text x="350" y="114">Shutdown</text></g></svg></div>

**What it is.** A dimmed full-screen overlay with round action buttons. The hovered button morphs into a rounded square; letter shortcuts (L, S, E, R, P) and arrow keys work too.

**Kind:** its own window · **Needs:** systemd (`systemctl`), `loginctl`

A complete version with confirmation for destructive actions is in [[ch:56-proj-session]]. This is the minimal form:

@include galleryshell/panels/PowerBubbles.qml

::: walk
@ 12-18 | Actions as data
Each action is an object with a keyboard shortcut letter, an icon, a name and the command to run. Adding an action is adding one line. Logout uses `loginctl terminate-user` with your username from the environment.
@ 19-20 | Selection and running
`sel` is the highlighted bubble. `run()` closes the menu **first**, then starts the command (closing after a shutdown command would be pointless).
@ 24-31 | Fullscreen dim
The window covers the whole screen with 53% black (`#88000000`). A full-size `MouseArea` closes the menu when clicking the background.
@ 32-40 | Keyboard
The row has focus. Left/right move the selection with wrap-around (`+ 4 % 5` is "−1" without going negative). Enter runs the selection; a letter key runs its action directly.
@ 42-62 | Bubbles
For each action: a circle that morphs into a rounded square and grows when selected (shape + scale + color, all animated). The shutdown icon is red so it stands out. Hovering selects; clicking runs.
:::

::: exercise practice | Confirm shutdown
Require pressing Enter twice for reboot and shutdown: the first press turns the label into "Press again".
:::

## Emoji Picker

<div class="preview"><svg width="300" height="190" viewBox="0 0 300 190"><rect x="10" y="10" width="280" height="170" rx="20" fill="#1e1e2e"/><rect x="26" y="24" width="248" height="30" rx="15" fill="#313244"/><text x="42" y="44" fill="#a6adc8" font-size="12">🔍  heart</text><g font-size="22"><text x="34" y="92">❤️</text><text x="80" y="92">💜</text><text x="126" y="92">💙</text><text x="172" y="92">💚</text><text x="218" y="92">🧡</text><text x="34" y="140">💛</text><text x="80" y="140">🖤</text><text x="126" y="140">🤍</text><text x="172" y="140">💖</text><text x="218" y="140">💕</text></g><rect x="28" y="64" width="40" height="40" rx="10" fill="none" stroke="#cba6f7" stroke-width="2"/></svg></div>

**What it is.** A searchable emoji grid. Pick one to copy it to the clipboard and close.

**Kind:** its own window · **Needs:** `wl-clipboard`; an emoji font (`noto-fonts-emoji`)

@include galleryshell/panels/EmojiPicker.qml

**Customize**
- Load the full Unicode list: download a JSON (e.g. `emoji.json` from the gemoji project) into your config and read it with [[FileView]] + `JSON.parse`.
- Type the emoji directly into the focused app: `wtype` instead of `wl-copy`.

::: walk
@ 12-20 | The data
Each entry is `[emoji, keywords]`. Searching keywords means typing "laugh" finds 😂. For a full set, load a JSON file of all emojis instead.
@ 21 | Picking
Copies the emoji to the clipboard with `wl-copy` and closes. Paste it anywhere with <kbd>Ctrl</kbd>+<kbd>V</kbd>.
@ 32 | Filtering
With no query, everything; otherwise entries whose keywords contain the query.
@ 39-49 | Search
Same pattern as the app grid: focus on the input, Esc closes, Enter picks the selected one, arrows go to the grid.
@ 50-63 | Grid
Seven square cells (`cellHeight: cellWidth`). `font.family: "Noto Color Emoji"` makes sure emojis render in color.
:::

::: exercise practice | Recent emojis
Show the last 7 picked emojis in a row above the grid, saved in a state file.
:::

## Calculator Popup

<div class="preview"><svg width="320" height="130" viewBox="0 0 320 130"><rect x="10" y="10" width="300" height="110" rx="20" fill="#1e1e2e"/><rect x="26" y="24" width="268" height="34" rx="17" fill="#313244"/><text x="44" y="46" fill="#cdd6f4" font-size="13">sqrt(2) * 15 in mm|</text><text x="34" y="96" fill="#cba6f7" font-size="22" font-weight="700">= 21.2132 mm</text></svg></div>

**What it is.** A small floating calculator: type any expression (units and currencies included) and see the result live. Enter copies the result.

**Kind:** its own window · **Needs:** `libqalculate` (`qalc`), `wl-clipboard`

@include galleryshell/panels/Calculator.qml

::: walk
@ 22-26 | qalc
`qalc` (from libqalculate) understands math, units and currencies: `5 USD to EUR`, `30 min + 1.5 h`. `-t` prints only the result. The command includes `expr.text`, so it always uses the current input.
@ 27 | Debounce
Starting a process on every keystroke would be wasteful. Each keystroke **restarts** a 150 ms timer, so `qalc` only runs when you pause typing. Empty input clears the result.
@ 35-43 | Input
`onTextChanged` restarts the debounce. Enter copies the result and closes.
@ 45-52 | Result
Big and colored when there's a result; a small gray hint with examples when empty.
:::

::: exercise practice | History
Keep the last 5 calculations (expression = result) in a list under the input; click one to copy it.
:::

## Wi-Fi Network Picker

<div class="preview"><svg width="300" height="200" viewBox="0 0 300 200"><rect x="10" y="10" width="280" height="180" rx="20" fill="#1e1e2e"/><text x="28" y="38" fill="#cdd6f4" font-size="14" font-weight="700">Wi-Fi</text><rect x="232" y="24" width="38" height="20" rx="10" fill="#cba6f7"/><circle cx="260" cy="34" r="7" fill="#1e1e2e"/><g font-size="12"><rect x="24" y="54" width="252" height="34" rx="12" fill="#45365e"/><text x="40" y="76" fill="#cdd6f4" font-weight="700">📶 Home-5G</text><text x="230" y="76" fill="#a6e3a1" font-size="10">connected</text><rect x="24" y="94" width="252" height="34" rx="12" fill="#313244"/><text x="40" y="116" fill="#cdd6f4">📶 Neighbor 🔒</text><rect x="24" y="134" width="252" height="34" rx="12" fill="#313244"/><text x="40" y="156" fill="#cdd6f4">📶 Cafe_Free</text></g></svg></div>

**What it is.** A list of nearby Wi-Fi networks sorted by signal; click one to connect, with a password field for new secured networks.

**Kind:** its own window · **Needs:** NetworkManager

@include galleryshell/panels/WifiPicker.qml

::: walk
@ 16-24 | Window
Top-right panel. `OnDemand` keyboard focus: the panel only takes the keyboard when you click into its password field, so it doesn't steal typing from your apps.
@ 26-29 | Scanning
Finds the Wi-Fi device. Scanning for nearby networks uses power, so it's enabled when the picker is created and disabled when it's destroyed.
@ 36-39 | Header
Title and a switch bound to the Wi-Fi radio.
@ 40-46 | Sorted network list
`.slice()` copies the list (never sort the service's own list in place), then sorts: connected first, then by signal strength. `b.connected - a.connected` works because booleans become 1/0 in subtraction.
@ 47-59 | One network row
Highlighted when connected. The signal icon has 3 levels. On the right: "…" while connecting, "connected", or a lock icon for secured networks. The font switches between text and the icon font depending on what is shown.
@ 60-68 | Clicking a network
Connected → disconnect. Known (saved) or open → connect directly. Otherwise remember it as `pending`, which shows the password field.
@ 71-77 | Password
Appears only when a network is pending. `echoMode: Password` hides the characters. Enter connects with the password (`connectWithPsk`, which also saves the profile) and resets.
:::

::: exercise practice | Forget network
Right-click a known network to forget it (look up the forget function on [[WifiNetwork]]).
:::
