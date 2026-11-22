# lyne-dots 7: The Launcher

Tap Super and lyne's launcher opens: start typing and the best app is already selected, press Enter. The same box does more with a **prefix**: `>` runs shell actions, `=` is a calculator, `;` searches your clipboard history. This chapter builds the fuzzy matcher, the service that turns a query into a list of results, and the window.

<div class="preview"><svg width="560" height="250" viewBox="0 0 560 250"><g font-size="12"><rect x="10" y="10" width="540" height="230" rx="15" fill="#1a1b26" stroke="#292e42"/><rect x="20" y="20" width="520" height="40" rx="10" fill="#24283b"/><rect x="26" y="26" width="104" height="28" rx="5" fill="#7aa2f7" opacity=".2"/><text x="36" y="45" fill="#7aa2f7">ϟ Actions</text><text x="140" y="45" fill="#c0caf5">&gt;th</text><rect x="20" y="68" width="520" height="44" rx="10" fill="#292e42"/><text x="40" y="95" fill="#7aa2f7" font-size="16">🎨</text><text x="70" y="95" fill="#c0caf5" font-weight="700">Next theme</text><text x="40" y="141" fill="#7aa2f7" font-size="16">⚙</text><text x="70" y="141" fill="#c0caf5">Settings</text><text x="40" y="187" fill="#7aa2f7" font-size="16">⏻</text><text x="70" y="187" fill="#c0caf5">Power menu</text><text x="30" y="226" fill="#545c7e" font-size="11">(nothing) apps   &gt; actions   = calculator   ; clipboard   ·   Ctrl+Tab: next mode</text></g></svg></div>

## Fuzzy matching

Typing "ffx" should find Firefox, and "vsc" should find Visual Studio Code. A **fuzzy matcher** accepts a query whose letters appear in order, not necessarily next to each other, and scores how good the match is.

@include lyne/services/fuzzy.js

::: walk
@ 7-11 | Setup
Lowercase both, so case doesn't matter. An empty query matches everything with score 0.
@ 12-13 | Prefixes win
If the name starts with the query, give a very high score, higher for shorter names: typing "code" puts "Code" above "Code - OSS".
@ 14-23 | Letters in order
Look for each query letter after the previous one. A missing letter means no match (−1). Each found letter scores 10, plus 30 if it starts a word ("**v**isual **s**tudio **c**ode") and 20 if it directly follows the previous match ("**fir**efox").
@ 24 | Shorter wins ties
A small penalty for long names.
@ 27-33 | Several fields
An app matches on its name, its generic name ("Web Browser") or its keywords. The best field counts.
:::

> [!NOTE] In the original
> lyne's `services/fuzzy.js` is more thorough (it highlights the matched letters in the results and handles accents), but the idea is the same.

## The actions

@include lyne/services/LauncherActions.qml

The `>` mode's list. Each action is a name, an icon, words to search for, and a function. They call services directly, so an action does exactly what the matching button elsewhere does. Add your own by adding a line: `{ name: "Screenshot", icon: Icons.screenshot, keywords: "capture", run: () => … }`.

## The launcher service

@include lyne/services/LauncherService.qml

::: walk
@ 18-20 | State
Open or not, what's typed, and which result is selected. The window binds to these; keybinds and IPC change them.
@ 22-26 | Modes
Each mode has a prefix, a label, an icon and placeholder text. The apps mode has no prefix.
@ 28-29 | Which mode
The first mode whose prefix the query starts with, otherwise apps. `term` is the query without the prefix: for `=2^10`, the term is `2^10`.
@ 32-35 | Apps, favourites and usage
Favourites (a list of desktop ids) and launch counts are **settings**, saved in `state.json` with everything else. `apps` is every installed application that isn't marked hidden.
@ 37-44 | No query
Favourites first, then the most launched, then alphabetical. The `-` between two booleans gives −1, 0 or 1, which is what `sort` wants; `||` moves to the next rule on a tie.
@ 45-49 | A query
Score every app, drop non-matches, add a bonus for frequently used apps (up to 50, so usage can't outweigh a much better match), and sort by score.
@ 52-55 | Actions
All actions without a query, or the fuzzy-matched ones.
@ 57-72 | Calculator
150 ms after you stop typing, run `qalc -t` (terse: only the answer) on the term. qalc understands a lot: `2^10`, `5 km to mi`, `20% of 150`, `10 USD to EUR`. The result arrives asynchronously and updates the entries.
@ 74-87 | Clipboard
`cliphist list` prints one line per entry: an id, a tab, a preview. It's reloaded every time the launcher opens. A query filters by text.
@ 89-103 | One shape for every result
Whatever the mode, each entry has a `kind`, a `title`, a `subtitle`, an icon (a glyph, or an app's icon name) and the original `data`. The window draws them all the same way and never needs to know the mode.
@ 104 | New list, back to the top
Every time the results change, select the first one, the best match.
@ 107-113 | Opening
Close every other popup, set the query (`show(">")` opens in actions mode), select the first entry, and refresh the clipboard list.
@ 115-117 | Toggling
`toggleMode(";")` closes the launcher if it's already open in that mode, otherwise opens it there. That's what makes Super+V toggle the clipboard.
@ 119-122 | Moving
Down and up wrap around the list.
@ 124-133 | Running an app
Close the launcher, add one to the app's launch count (copy, change, set, so the state notices), and `execute()` the desktop entry, which handles `%U`-style placeholders and terminal apps.
@ 134-141 | Running the rest
Actions run their function. The calculator copies its result. A clipboard entry is decoded by cliphist back to its original data and put on the clipboard; its id and text go to `sh` as arguments.
@ 144-147 | Favourites
Add or remove an app's id in the saved list.
@ 149-159 | Polite, and scriptable
The usual close request and registration; `qs -c lyne ipc call launcher toggle` and `… clipboard`.
:::

## The window

@include lyne/modules/launcher/Launcher.qml

::: walk
@ 14-26 | Where and how
On the focused screen, a fifth of the way down, 620 px wide. Overlay layer, and **exclusive** keyboard focus: while it's open, your typing goes to it.
@ 28 | Click outside to close
Clicking any other window clears the focus grab, which hides the launcher.
@ 30-45 | The box and its entrance
Grows from 92% to full size while fading in, lyne's popup motion. Setting `scale` and `opacity` in `Component.onCompleted` (instead of starting at 1) is what triggers the `Behavior`s.
@ 55-78 | The search field and mode chip
The mode's icon sits on a chip; outside the apps mode, the chip is tinted and shows the mode's name.
@ 79-88 | The input
Its text follows `LauncherService.query`, and `onTextEdited` (only fired for typing, not for the binding) writes back to it. The service, not the window, owns the query, so `show(">")` can fill it in.
@ 89-103 | Keys
Escape closes, arrows move, Enter runs. Tab moves down; Ctrl+Tab switches to the next mode by replacing the prefix and keeping what you typed.
@ 104-111 | Placeholder
Shown when the field is empty or holds only the prefix, right after the prefix.
@ 117-127 | The results list
At most seven rows tall. Its selection follows the service's `selectedIndex`, and a highlight rectangle glides between rows.
@ 129-157 | A row's icon
An app's icon from the icon theme, or a glyph for actions, the calculator and clipboard entries.
@ 158-163 | Title and subtitle
The selected row's title is bold; the subtitle (an app's description) is muted and hidden when empty.
@ 164-170 | Favourite star
On apps: filled for favourites, outlined on the selected row. Clicking it toggles the favourite.
@ 171-178 | Mouse
Hovering selects a row; clicking runs it.
@ 182-188 | Nothing found
"No results", or "…" while the calculator is still working.
:::

## Opening it with Super

lyne opens the launcher when you **tap** Super alone, without breaking Super+1 and every other Super shortcut. Hyprland can do that with a bind on the key's release, which only fires when no other key was pressed in between. One catch: inside a release bind, Hyprland sends a global shortcut as "released" only, and the shell reacts to "pressed". So lyne dispatches it a moment later, outside the bind ([[ch:ly12-assemble]] has the whole file):

```lua
hl.bind("SUPER + SUPER_L", function()
    LYNE_TAP = hl.timer(function() hl.dispatch(hl.dsp.global("quickshell:app_launcher")) end,
                        { timeout = 1, type = "oneshot" })
end, { release = true })
```

## Practice

::: exercise warm | Your own action
Add an action "Toggle bar style" that switches `bar.style` between "floating" and "docked-corners".
--- solution
```qml
{ name: "Toggle bar style", icon: Icons.window, keywords: "bar layout",
  run: () => StateService.set("bar.style", StateService.get("bar.style", "") === "floating" ? "docked-corners" : "floating") }
```
:::

::: exercise practice | A web-search mode
Add a mode with the prefix `?` that shows one entry, "Search the web for …", and opens `https://duckduckgo.com/?q=<term>` with `xdg-open`.
--- hint
Add the mode to `modes`, a case in `entries` returning one entry of kind `"web"`, and a branch in `activate()` running `Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(e.data)])`.
:::

::: exercise practice | Highlight the match
Show the matched letters of app names in the accent colour. Make `score()` also return the positions it matched, and build the title as rich text with `<font color=…>` around those letters.
:::

::: exercise challenge | Emoji mode
Add a `:` mode that searches a list of emoji by name (keep a small JSON file next to the service) and copies the chosen one.
:::
