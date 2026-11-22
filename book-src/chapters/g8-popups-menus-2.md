# Gallery: Popups, Menus and Pickers

Things that open on top of your desktop: a calendar, an audio mixer, a device picker, reusable tooltips and context menus, a confirmation dialog, clipboard history, a screenshot menu, an Alt+Tab switcher and a battery details popup. The files live in `galleryshell/popups/`.

There are two shapes here:

- **Chip with a popup**: a bar module that opens a [[PopupWindow]] under itself (calendar, mixer, devices, battery). Drop it in your bar like any chip.
- **Overlay with IPC**: a `Scope` with an `open` flag, an [[IpcHandler]] and a window that only exists while open (clipboard, screenshot, Alt+Tab, confirm). Put one anywhere in `shell.qml` and bind a key to `qs ipc call <target> toggle`.

## Calendar Popup

<div class="preview"><svg width="340" height="290" viewBox="0 0 340 290"><rect x="120" y="8" width="100" height="26" rx="13" fill="#45475a"/><text x="170" y="25" fill="#cdd6f4" font-size="12" text-anchor="middle">Sat 22 Nov</text><rect x="30" y="44" width="280" height="236" rx="16" fill="#1e1e2e" stroke="#313244"/><text x="46" y="72" fill="#cdd6f4" font-size="15" font-weight="700">November 2026</text><text x="236" y="72" fill="#a6adc8" font-size="14">‹  ◎  ›</text><g font-size="11" text-anchor="middle" font-weight="700"><text x="58" y="96" fill="#6c7086">Mo</text><text x="94" y="96" fill="#6c7086">Tu</text><text x="130" y="96" fill="#6c7086">We</text><text x="166" y="96" fill="#6c7086">Th</text><text x="202" y="96" fill="#6c7086">Fr</text><text x="238" y="96" fill="#f38ba8">Sa</text><text x="274" y="96" fill="#f38ba8">Su</text></g><g font-size="12" text-anchor="middle" fill="#cdd6f4"><text x="58" y="122" fill="#585b70">26</text><text x="94" y="122" fill="#585b70">27</text><text x="130" y="122" fill="#585b70">28</text><text x="166" y="122" fill="#585b70">29</text><text x="202" y="122" fill="#585b70">30</text><text x="238" y="122" fill="#585b70">31</text><text x="274" y="122">1</text><text x="58" y="152">2</text><text x="94" y="152">3</text><text x="130" y="152">4</text><text x="166" y="152">5</text><text x="202" y="152">6</text><text x="238" y="152">7</text><text x="274" y="152">8</text><text x="58" y="182">9</text><text x="94" y="182">10</text><text x="130" y="182">11</text><text x="166" y="182">12</text><text x="202" y="182">13</text><text x="238" y="182">14</text><text x="274" y="182">15</text><text x="58" y="212">16</text><text x="94" y="212">17</text><text x="130" y="212">18</text><text x="166" y="212">19</text><text x="202" y="212">20</text><text x="274" y="212">22</text><text x="58" y="242">23</text><text x="94" y="242">24</text><text x="130" y="242">25</text><text x="166" y="242">26</text><text x="202" y="242">27</text><text x="238" y="242">28</text><text x="274" y="242">29</text></g><rect x="222" y="196" width="32" height="24" rx="8" fill="#cba6f7"/><text x="238" y="212" fill="#1e1e2e" font-size="12" font-weight="700" text-anchor="middle">21</text></svg></div>

**What it is.** A date chip; click it for a month calendar with today highlighted. Arrows or the scroll wheel move between months, the middle button jumps back to today.

**Kind:** bar module with popup · **Needs:** nothing extra

@include galleryshell/popups/CalendarPopup.qml

::: walk
@ 8-10 | State
Whether the popup is open, which month is shown relative to the current one, and a clock. Minute precision is enough; the date changes at midnight and the binding follows.
@ 12-13 | The shown month
JavaScript's `Date` handles overflow for us: month 13 of 2026 is January 2027, so adding `monthOffset` to the month just works.
@ 14-22 | 42 cells
A month grid is always 6 rows of 7 days. `getDay()` is 0 for Sunday, so `(getDay() + 6) % 7` makes Monday 0. Starting `lead` days before the 1st fills the first row with the end of the previous month. Day numbers like 0 or −2 are fine; `Date` turns them into the right days of the previous month.
@ 23-25 | Same day?
Compares year, month and date, ignoring the time.
@ 27-33 | The chip
Shows "Sat 22 Nov". A click resets to the current month and toggles the popup.
@ 35-42 | The popup window
A [[PopupWindow]] anchored to the chip, opening downward with an 8 px gap.
@ 51-65 | Header
Month and year, then three buttons from a small model of `[icon, step]` pairs. Step 0 means "back to today".
@ 66-79 | Weekday names
The first seven grid cells. Weekends are red.
@ 80-98 | Day cells
Each cell knows whether it's today and whether it belongs to the shown month (others are greyed). Cells fill the grid evenly with `Layout.fillWidth/fillHeight`.
@ 101 | Scroll to change month
:::

::: exercise practice | Week numbers
Add an eighth column on the left with ISO week numbers.
--- hint
The ISO week of a date is the week of its Thursday: take the Monday of each row, add 3 days, and count weeks since the first Thursday of that year.
:::

## Per-App Volume Mixer

<div class="preview"><svg width="360" height="180" viewBox="0 0 360 180"><rect x="160" y="6" width="30" height="26" rx="13" fill="#45475a"/><text x="168" y="24" fill="#cdd6f4" font-size="13">≋</text><rect x="20" y="40" width="320" height="130" rx="16" fill="#1e1e2e" stroke="#313244"/><g font-size="12"><circle cx="46" cy="70" r="11" fill="#a6e3a1"/><text x="66" y="64" fill="#cdd6f4">Spotify · Instant Crush</text><rect x="66" y="74" width="230" height="4" rx="2" fill="#45475a"/><rect x="66" y="74" width="170" height="4" rx="2" fill="#cba6f7"/><circle cx="236" cy="76" r="7" fill="#cdd6f4"/><text x="308" y="76" fill="#a6adc8">🔊</text><circle cx="46" cy="110" r="11" fill="#fab387"/><text x="66" y="104" fill="#cdd6f4">Firefox · YouTube</text><rect x="66" y="114" width="230" height="4" rx="2" fill="#45475a"/><rect x="66" y="114" width="90" height="4" rx="2" fill="#cba6f7"/><circle cx="156" cy="116" r="7" fill="#cdd6f4"/><text x="308" y="116" fill="#a6adc8">🔊</text><circle cx="46" cy="150" r="11" fill="#89b4fa"/><text x="66" y="144" fill="#cdd6f4">Discord</text><rect x="66" y="154" width="230" height="4" rx="2" fill="#45475a"/><text x="308" y="156" fill="#f38ba8">🔇</text></g></svg></div>

**What it is.** One slider per app that is playing sound, so you can turn the game down without touching the music.

**Kind:** bar module with popup · **Needs:** PipeWire

@include galleryshell/popups/AudioMixer.qml

::: walk
@ 12-13 | Which nodes are apps
In PipeWire every sound source and destination is a node. An app playing sound is a **stream** that is a **sink**-side node with audio. Speakers are sinks but not streams; microphone recorders are streams but not sinks.
@ 15 | Track them all
[[PwObjectTracker]] takes a list, so one tracker covers every stream. Without it, `audio.volume` would read 0.
@ 17-22 | The chip
An equaliser icon that toggles the popup.
@ 24-32 | The popup
It grows with the number of streams, but is at least 80 px tall for the "Nothing is playing" message.
@ 49-54 | App name and icon
Apps describe themselves in the node's `properties` map: `application.name`, `application.icon-name` and `media.name` (the song or tab title). Each has a fallback, because not every app sets them.
@ 58-72 | Name and slider
The slider shows the stream's volume. `onMoved` (not `onValueChanged`) only fires for user drags, so the binding isn't fought by its own updates.
@ 73-78 | Mute
:::

::: exercise practice | Show a level meter
Add a thin live level bar under each slider.
--- hint
`PwNodePeakMonitor { node: stream.modelData }` has a `peak` property from 0 to 1 (check your Quickshell version's docs).
:::

## Output and Input Picker

<div class="preview"><svg width="360" height="220" viewBox="0 0 360 220"><rect x="20" y="10" width="320" height="200" rx="16" fill="#1e1e2e" stroke="#313244"/><g font-size="12"><text x="36" y="36" fill="#6c7086" font-size="11" font-weight="700">OUTPUT</text><rect x="32" y="44" width="296" height="32" rx="10" fill="#45365e"/><text x="44" y="65" fill="#cba6f7">◉</text><text x="66" y="65" fill="#cdd6f4">Built-in Audio Analog Stereo</text><text x="44" y="97" fill="#6c7086">○</text><text x="66" y="97" fill="#cdd6f4">WH-1000XM4</text><text x="44" y="127" fill="#6c7086">○</text><text x="66" y="127" fill="#cdd6f4">HDMI / DisplayPort 1</text><text x="36" y="158" fill="#6c7086" font-size="11" font-weight="700">INPUT</text><rect x="32" y="166" width="296" height="32" rx="10" fill="#45365e"/><text x="44" y="187" fill="#cba6f7">◉</text><text x="66" y="187" fill="#cdd6f4">Built-in Audio Digital Microphone</text></g></svg></div>

**What it is.** Switch between speakers, headphones and HDMI (and between microphones) with one click. Running apps move to the new device.

**Kind:** bar module with popup · **Needs:** PipeWire

@include galleryshell/popups/AudioDevices.qml

::: walk
@ 10-11 | Devices, not apps
The opposite filter from the mixer: real devices are nodes that are **not** streams. Sinks are outputs, the rest are inputs.
@ 20-28 | A reusable list
`DeviceList` is an inline component with a title, a device list, the current device and a `pick` signal. Both sections use it, with different data.
@ 32-38 | One row
`chosen` compares the row's node with the current default. A highlighted background and a filled radio icon mark it.
@ 46-50 | Device name
`description` is the friendly name ("Built-in Audio Analog Stereo"); `nickname` and `name` are fallbacks.
@ 53 | Picking
The row doesn't change anything itself; it emits `pick` and lets the user of the component decide what that means.
@ 74-85 | Output and input
Setting `Pipewire.preferredDefaultAudioSink` asks PipeWire to make that node the default. `defaultAudioSink` then updates, and so does the highlight.
:::

::: exercise practice | Merge it into the volume chip
Open this popup with a right-click on the volume chip from [[ch:g1-bar-modules]] instead of a separate icon.
:::

## Reusable Tooltip

<div class="preview"><svg width="260" height="90" viewBox="0 0 260 90"><rect x="110" y="12" width="34" height="26" rx="13" fill="#45475a"/><text x="119" y="30" fill="#cdd6f4" font-size="14">🔊</text><rect x="82" y="46" width="90" height="26" rx="8" fill="#11111b" stroke="#45475a"><animate attributeName="opacity" values="0;0;1;1;0" keyTimes="0;.3;.4;.9;1" dur="3s" repeatCount="indefinite"/></rect><text x="127" y="63" fill="#cdd6f4" font-size="12" text-anchor="middle">Volume 40%<animate attributeName="opacity" values="0;0;1;1;0" keyTimes="0;.3;.4;.9;1" dur="3s" repeatCount="indefinite"/></text></svg></div>

**What it is.** A tooltip you can attach to anything in your bar with one line. It appears after a short hover, fades, and moves to stay on screen.

**Kind:** component · **Needs:** nothing extra

@include galleryshell/popups/Tooltip.qml

::: walk
@ 4-5 | Usage
Place it next to the widget it describes and bind `show` to that widget's hover state.
@ 8-11 | Inputs
`target` is required: a tooltip without something to point at makes no sense, and `required` makes QML complain if you forget it.
@ 13-17 | Placement
Below the target, centred. `PopupAdjustment.Slide | Flip` lets the compositor slide it sideways or flip it above the target when it would leave the screen, so tooltips on the far right of a bar stay readable.
@ 22-26 | Delay and fade-out
`wanted` becomes true only after the delay. The window stays mapped while the box is still fading out (`opacity > 0`), so the fade can be seen. Leaving the target cancels a pending show at once.
@ 28-41 | The box
A dark rounded box; its opacity follows `wanted` with a 120 ms fade.
:::

```qml
// in any bar module
HoverHandler { id: hover }
Tooltip { target: root; text: "Battery " + Math.round(pct * 100) + "%"; show: hover.hovered }
```

::: exercise practice | Multi-line tooltips
Allow `\n` in the text and limit the width to 300 px with wrapping.
:::

## Context Menu

<div class="preview"><svg width="260" height="170" viewBox="0 0 260 170"><rect x="30" y="10" width="34" height="26" rx="13" fill="#313244"/><rect x="30" y="44" width="200" height="118" rx="12" fill="#1e1e2e" stroke="#45475a"/><g font-size="13"><rect x="36" y="50" width="188" height="30" rx="8" fill="#313244"/><text x="48" y="70" fill="#a6adc8">⧉</text><text x="72" y="70" fill="#cdd6f4">Copy</text><text x="48" y="102" fill="#a6adc8">↗</text><text x="72" y="102" fill="#cdd6f4">Open</text><rect x="42" y="116" width="176" height="1" fill="#313244"/><text x="48" y="146" fill="#f38ba8">🗑</text><text x="72" y="146" fill="#f38ba8">Delete</text></g></svg></div>

**What it is.** A styled right-click menu you fill with a plain JavaScript list: icons, separators and red "danger" entries.

**Kind:** component · **Needs:** nothing extra

@include galleryshell/popups/ContextMenu.qml

::: walk
@ 5-12 | Usage
Each entry is an object. `action` is a function, so any code can run when it's picked.
@ 15-19 | Opening and closing
`popup(item)` sets where the menu appears and shows it. Using a function (rather than setting two properties from outside) means you can't forget one of them.
@ 21-25 | Placement
Below the item, kept on screen by the compositor.
@ 39-48 | Separators
An entry with `separator: true` becomes a thin 9 px line instead of a button.
@ 49-67 | Normal entries
Icon and text; danger entries are red and get a reddish hover.
@ 69-74 | Running the action
Close first, then run. `?.()` calls the function only if there is one, so entries without an action are harmless.
:::

::: exercise challenge | Submenus
Allow `children: [...]` on an entry. Hovering it opens a second `ContextMenu` to the right.
--- hint
Use `anchor.edges: Edges.Right` and `anchor.gravity: Edges.Right` for the child menu, anchored to the hovered entry.
:::

## Confirmation Dialog

<div class="preview"><svg width="420" height="230" viewBox="0 0 420 230"><rect width="420" height="230" fill="#000" opacity=".55"/><rect x="40" y="20" width="340" height="190" rx="22" fill="#1e1e2e" stroke="#313244"/><text x="62" y="62" fill="#f9e2af" font-size="26">⚠</text><text x="62" y="96" fill="#cdd6f4" font-size="18" font-weight="700">Shut down?</text><text x="62" y="118" fill="#a6adc8" font-size="12">Continuing in 7 s</text><rect x="152" y="158" width="100" height="36" rx="18" fill="#313244"/><text x="202" y="181" fill="#cdd6f4" text-anchor="middle" font-weight="700">Cancel</text><rect x="260" y="158" width="100" height="36" rx="18" fill="#f38ba8"/><text x="310" y="181" fill="#1e1e2e" text-anchor="middle" font-weight="700">Confirm</text></svg></div>

**What it is.** "Are you sure?" for dangerous actions. The screen dims, Enter confirms, Esc or a click outside cancels, and after a countdown it confirms by itself (like most desktops' shutdown dialog).

**Kind:** overlay with IPC · **Needs:** nothing extra

@include galleryshell/popups/ConfirmDialog.qml

::: walk
@ 12-16 | State
The question, the command to run, how long the countdown lasts (0 turns it off) and how much is left.
@ 18-23 | Asking
`ask` takes either a list (`["systemctl", "poweroff"]`) or a string, which is run with `sh -c`. It resets the countdown and opens.
@ 24 | Accepting
Close first, then run the command detached so it outlives the dialog.
@ 26 | From the terminal
`qs ipc call confirm ask "Reboot?" "systemctl reboot"`. Handy in keybinds and scripts.
@ 28-32 | The countdown
`--root.remaining` decrements and then compares, so after `seconds` ticks it accepts.
@ 36-43 | The dim layer
A fullscreen overlay window with a half-transparent black background. It takes the keyboard so Enter and Esc reach the dialog. The full-window `MouseArea` cancels on any click outside the card.
@ 45-52 | The card
Its own `MouseArea` swallows clicks so they don't fall through to the cancel area behind it.
@ 64-78 | Buttons
Two buttons from a model. Confirm is red, because the action is destructive.
:::

To guard the power menu from [[ch:g4-panels]], replace its `run` with `confirm.ask(actions[i].name + "?", actions[i].cmd)` for reboot and shutdown.

::: exercise practice | No countdown for some questions
Add an optional third IPC argument with the number of seconds.
:::

## Clipboard History

<div class="preview"><svg width="420" height="260" viewBox="0 0 420 260"><rect x="10" y="6" width="400" height="248" rx="20" fill="#1e1e2e" stroke="#313244"/><rect x="24" y="20" width="372" height="38" rx="19" fill="#313244"/><text x="40" y="44" fill="#a6adc8" font-size="14">⌕</text><text x="62" y="44" fill="#cdd6f4" font-size="14">git</text><g font-size="13"><rect x="24" y="68" width="372" height="38" rx="10" fill="#45365e"/><text x="38" y="92" fill="#6c7086">≡</text><text x="62" y="92" fill="#cdd6f4">git push origin main</text><text x="38" y="132" fill="#6c7086">≡</text><text x="62" y="132" fill="#cdd6f4">git rebase -i HEAD~3</text><text x="38" y="172" fill="#6c7086">≡</text><text x="62" y="172" fill="#cdd6f4">https://github.com/quickshell-mirror/quickshell</text><text x="38" y="212" fill="#6c7086">▣</text><text x="62" y="212" fill="#cdd6f4">&#91;&#91; binary data 210 KiB png 1920x1080 &#93;&#93;</text></g><text x="24" y="242" fill="#6c7086" font-size="11">↑↓ move   Enter copy   Del remove   Esc close</text></svg></div>

**What it is.** Everything you copied, searchable. Type to filter, Enter copies the entry back to the clipboard, Delete removes it. Images are listed too.

**Kind:** overlay with IPC · **Needs:** `cliphist`, `wl-clipboard`, and `exec-once = wl-paste --watch cliphist store`

@include galleryshell/popups/ClipboardHistory.qml

::: walk
@ 11-13 | State
`entries` holds `{ id, text }` objects. `qs ipc call clipboard toggle` opens it.
@ 15-26 | Reading the history
`cliphist list` prints one line per entry: an id, a tab, and a one-line preview. Splitting at the first tab gives both parts. The list is reloaded every time the window opens, so it is always current.
@ 28-32 | Copying back
`cliphist decode` wants the original line on its input. The id and text go to `sh` as **arguments** (`$1`, `$2`) and are printed back with `printf`, so text with quotes or `$` can't break or inject anything. The decoded data goes to `wl-copy`.
@ 33-36 | Removing
The same trick with `cliphist delete`, then the entry is dropped from the list straight away.
@ 40-48 | The window
An overlay that takes the keyboard. `shown` is the search-filtered list.
@ 61-70 | Keyboard control
Focus stays in the search field; the arrow keys move the list's selection, Enter copies and Delete removes the selected entry.
@ 74-103 | The list
Each row shows an image or text icon (cliphist previews images as `[[ binary data … ]]`) and the elided text. The current row is highlighted; clicking also copies.
:::

::: exercise challenge | Image previews
Show a thumbnail for image entries.
--- hint
Decode the entry to a temporary file (`cliphist decode > /tmp/qs-clip-ID.png`) in a `Process`, then show it with an `Image` whose `sourceSize.height` is 32.
:::

## Screenshot Menu

<div class="preview"><svg width="440" height="160" viewBox="0 0 440 160"><rect x="10" y="5" width="420" height="150" rx="24" fill="#1e1e2e" stroke="#313244"/><g font-size="11" text-anchor="middle"><rect x="26" y="21" width="124" height="74" rx="16" fill="#cba6f7"/><text x="88" y="56" fill="#1e1e2e" font-size="24">⬚</text><text x="88" y="82" fill="#1e1e2e">Region  (R)</text><rect x="158" y="21" width="124" height="74" rx="16" fill="#313244"/><text x="220" y="56" fill="#cdd6f4" font-size="24">▢</text><text x="220" y="82" fill="#a6adc8">Window  (W)</text><rect x="290" y="21" width="124" height="74" rx="16" fill="#313244"/><text x="352" y="56" fill="#cdd6f4" font-size="24">⛶</text><text x="352" y="82" fill="#a6adc8">Screen  (S)</text></g><text x="26" y="127" fill="#a6adc8" font-size="12">Delay</text><g font-size="11" text-anchor="middle"><rect x="66" y="112" width="44" height="24" rx="12" fill="#cba6f7"/><text x="88" y="128" fill="#1e1e2e">off</text><rect x="116" y="112" width="44" height="24" rx="12" fill="#313244"/><text x="138" y="128" fill="#cdd6f4">3 s</text><rect x="166" y="112" width="44" height="24" rx="12" fill="#313244"/><text x="188" y="128" fill="#cdd6f4">5 s</text><rect x="216" y="112" width="44" height="24" rx="12" fill="#313244"/><text x="238" y="128" fill="#cdd6f4">10 s</text></g></svg></div>

**What it is.** Press Print and choose: a region, the focused window or the whole screen, with an optional delay. The picture is saved, copied to the clipboard and announced with a notification showing it.

**Kind:** overlay with IPC · **Needs:** `grim`, `slurp`, `wl-clipboard`, `jq`, Hyprland (for "window")

@include galleryshell/popups/ScreenshotMenu.qml

::: walk
@ 12-18 | State and commands
`toggle` opens the menu; `region` skips it, for a Shift+Print bind that goes straight to region selection.
@ 20-26 | The script's setup
One shell script does the work. The mode and delay arrive as arguments. It makes the folder, names the file after the date and time, and waits 0.2 s so the menu has disappeared before the picture is taken.
@ 27-32 | Three ways to capture
`slurp` lets you drag a region and prints its geometry (it exits with an error if you press Esc, and then the script stops). For the window, Hyprland's `activewindow` JSON gives position and size, which `jq` formats as `X,Y WxH`. Without a geometry, `grim` captures every screen.
@ 33-34 | Afterwards
Copy the file to the clipboard and send a notification with the screenshot as its icon.
@ 36-39 | Taking it
Close the menu and run the script detached, so it keeps running after the menu window is gone.
@ 52-61 | Keyboard shortcuts
R, W and S pick a mode without the mouse.
@ 69-99 | The three buttons
Built from a model; hover turns a button purple.
@ 101-118 | Delay chips
Four choices; the selected one is highlighted.
:::

::: exercise practice | Edit after capture
Add an "Edit" toggle that opens the picture in `satty` (or `swappy`) after taking it.
--- hint
Add a third argument to the script and end it with `[ "$3" = 1 ] && satty --filename "$file"`.
:::

## Alt+Tab Switcher

<div class="preview"><svg width="460" height="180" viewBox="0 0 460 180"><rect x="10" y="5" width="440" height="170" rx="24" fill="#1e1e2e" stroke="#313244"/><g font-size="11" text-anchor="middle"><rect x="26" y="20" width="120" height="130" rx="16" fill="none"/><circle cx="86" cy="66" r="26" fill="#fab387"/><text x="86" y="118" fill="#cdd6f4">Firefox</text><rect x="160" y="20" width="120" height="130" rx="16" fill="#45365e" stroke="#cba6f7" stroke-width="2"/><circle cx="220" cy="66" r="26" fill="#89b4fa"/><text x="220" y="118" fill="#cdd6f4">kitty — ~/src</text><circle cx="354" cy="66" r="26" fill="#a6e3a1"/><text x="354" y="118" fill="#cdd6f4">Code — shell.qml</text></g></svg></div>

**What it is.** Hold Alt and press Tab to cycle through windows, most recently used first; release Alt to switch. Shift goes backwards.

**Kind:** overlay with IPC · **Needs:** Hyprland binds (any compositor that can run commands on key press and release)

@include galleryshell/popups/AltTabSwitcher.qml

::: walk
@ 8-11 | The binds
`bindr` runs on key **release**: letting go of Alt commits the choice. That's the whole trick behind a "hold Alt" switcher.
@ 14-16 | State
`order` is a frozen copy of the window list made when the switcher opens, so windows appearing meanwhile don't shift the selection.
@ 18-26 | Remembering focus
Wayland doesn't say which window was used before which, so the switcher records it: every time the active window changes, that window moves to the front of `history`. Closed windows are dropped along the way.
@ 27-31 | Most recent first
Windows from the history first (in order), then any it never saw focused.
@ 33-36 | Stepping
The first press opens the switcher and moves to index 1, which is the **previous** window, so a quick Alt+Tab flips between your two latest windows. Further presses move on, wrapping around.
@ 37-41 | Committing
Close and focus the selected window.
@ 52-57 | The window
Centred (no anchors), as wide as its cards but never wider than the screen.
@ 68-91 | Cards
Icon and title; the current card has an outline. Clicking a card switches to it directly.
:::

::: exercise challenge | Live previews
Show a live thumbnail of each window instead of only the icon.
--- hint
`ScreencopyView { captureSource: card.modelData; live: true }` from `Quickshell.Wayland` captures a toplevel. Keep it small, it costs GPU time.
:::

## Battery Details

<div class="preview"><svg width="340" height="300" viewBox="0 0 340 300"><rect x="150" y="6" width="70" height="26" rx="13" fill="#45475a"/><text x="185" y="24" fill="#cdd6f4" font-size="12" text-anchor="middle">🔋 76%</text><rect x="25" y="40" width="290" height="250" rx="18" fill="#1e1e2e" stroke="#313244"/><text x="41" y="82" fill="#cdd6f4" font-size="30" font-weight="700">76%</text><text x="120" y="80" fill="#a6adc8" font-size="13">On battery</text><rect x="41" y="96" width="258" height="8" rx="4" fill="#313244"/><rect x="41" y="96" width="196" height="8" rx="4" fill="#cba6f7"/><g font-size="12"><text x="41" y="132" fill="#a6adc8">◷  Time left</text><text x="299" y="132" fill="#cdd6f4" text-anchor="end" font-weight="700">4 h 12 min</text><text x="41" y="158" fill="#a6adc8">ϟ  Power draw</text><text x="299" y="158" fill="#cdd6f4" text-anchor="end" font-weight="700">8.4 W</text><text x="41" y="184" fill="#a6adc8">♥  Health</text><text x="299" y="184" fill="#cdd6f4" text-anchor="end" font-weight="700">91%</text></g><g font-size="10" text-anchor="middle"><rect x="41" y="206" width="80" height="52" rx="12" fill="#313244"/><text x="81" y="246" fill="#a6adc8">Saver</text><rect x="130" y="206" width="80" height="52" rx="12" fill="#cba6f7"/><text x="170" y="246" fill="#1e1e2e">Balanced</text><rect x="219" y="206" width="80" height="52" rx="12" fill="#313244"/><text x="259" y="246" fill="#a6adc8">Performance</text></g></svg></div>

**What it is.** A battery chip whose popup shows time left (or until full), power draw and battery health, with buttons for the three power profiles.

**Kind:** bar module with popup · **Needs:** UPower, power-profiles-daemon (for the profile buttons)

@include galleryshell/popups/BatteryPopup.qml

::: walk
@ 10-13 | The battery
`UPower.displayDevice` combines all batteries into one. `state` says charging, discharging or full.
@ 15-19 | Durations
UPower gives seconds; this turns them into "4 h 12 min". 0 means UPower doesn't know yet, shown as a dash.
@ 21 | Only on laptops
Desktops have no laptop battery, so the chip hides itself.
@ 27-38 | The chip
Icon by level and charging state, plus the percentage.
@ 42-50 | A stat row
An inline component: icon, label on the left, value on the right.
@ 68-82 | Big number and level bar
@ 83-92 | Details
Time to full while charging, time to empty otherwise. `changeRate` is the power flowing in or out in watts. Health is the current capacity compared with the design capacity, when the battery reports it.
@ 93-120 | Power profiles
[[PowerProfiles]] talks to power-profiles-daemon. The active profile is highlighted; clicking sets it. Performance is hidden on machines that don't offer it.
:::

::: exercise practice | Charge limit
Many laptops can stop charging at 80% to protect the battery. Add a toggle that writes `80` or `100` to `/sys/class/power_supply/BAT0/charge_control_end_threshold` (it needs root: run it through `pkexec`).
:::
