# Caelestia 6: The Launcher

Caelestia's launcher rises from the **bottom edge** of the frame. Unusually, the search bar sits at the bottom and results stack **upward**, so the best match is always right above the text you're typing, close to your eyes. Typing `>` switches to commands: change wallpaper, calculate, lock, power off.

<div class="preview"><svg width="560" height="270" viewBox="0 0 560 270"><g font-size="11"><rect y="258" width="560" height="12" fill="#141218"/><path d="M80 258 A25 25 0 0 0 105 233 V44 A28 28 0 0 1 133 16 H427 A28 28 0 0 1 455 44 V233 A25 25 0 0 0 480 258Z" fill="#141218"/><g transform="translate(120 30)"><rect y="0" width="320" height="44" rx="14" fill="#141218"/><rect x="10" y="10" width="26" height="26" rx="6" fill="#a6e3a1"/><text x="48" y="22" fill="#e6e0e9">Files</text><text x="48" y="36" fill="#938f99" font-size="9">Access and organise files</text><rect y="48" width="320" height="44" rx="14" fill="#141218"/><rect x="10" y="58" width="26" height="26" rx="6" fill="#89b4fa"/><text x="48" y="70" fill="#e6e0e9">Firewall</text><text x="48" y="84" fill="#938f99" font-size="9">Configure the firewall</text><rect y="96" width="320" height="44" rx="14" fill="#36343b"/><rect x="10" y="106" width="26" height="26" rx="6" fill="#fab387"/><text x="48" y="118" fill="#e6e0e9">Firefox</text><text x="48" y="132" fill="#938f99" font-size="9">Browse the World Wide Web</text><rect y="160" width="320" height="44" rx="22" fill="#211f26"/><text x="18" y="187" fill="#cac4d0">⌕   fi|</text></g><text x="470" y="150" fill="#cdd6f4">← best match is</text><text x="470" y="166" fill="#cdd6f4">right above the</text><text x="470" y="182" fill="#cdd6f4">search bar</text></g></svg></div>

```text
modules/launcher/  Content  IconImageWrapper  WallpaperGrid
services/          Apps  Wallpapers
```

## Module 1: App search

@include cae/services/Apps.qml

::: walk
@ 7-8 | All apps, sorted
Every desktop entry that isn't hidden (`noDisplay`), alphabetically. A `.slice()` copy is sorted, because sorting the service's own list in place would modify shared data.
@ 10-16 | Scoring
A simple, predictable ranking. A name that **starts with** the query scores highest, then a name that contains it, then matches in the generic name, comment or keywords. Subtracting the name's length breaks ties in favour of shorter names, so typing `fi` puts "Files" before "Firefox Developer Edition".
@ 18-23 | Search
Score every app, drop the ones that don't match (`-1`), sort by score.
:::

> [!NOTE] In the original
> Caelestia uses a fuzzy matcher (`utils/Searcher.qml` with the fzf algorithm) and remembers how often you launch each app. The scoring here is easier to understand and works well; swap in fuzzy search later if you like (see the launcher project in [[ch:52-proj-launcher]]).

## Module 2: The launcher

@include cae/modules/launcher/Content.qml

::: walk
@ 17-21 | Modes from the text
Everything follows from what's in the search field: `actionMode` when it starts with the prefix (`>` by default), `wallpaperMode` for `>wallpaper…`. No separate mode switches to keep in sync.
@ 23-31 | Actions as data
Each action is an object with a name, an icon, a description and a `run` function. Adding a command is adding one line. `wallpaper` and `calc` don't run anything themselves; they complete the text to enter their mode.
@ 34-38 | Results
Apps (limited to `maxShown`), the calculator result, or the actions whose name starts with what you typed. One property feeds the list in every mode.
@ 43-53 | Activating
Apps have no `run` function, actions do; that's how the two kinds are told apart. Most things close the launcher; the two "mode" actions keep it open.
@ 55-56 | Size from the content
The launcher is as tall as its list (or the wallpaper strip) plus the search bar. The drawer grows and shrinks as results change, and the frame background follows.
@ 58-65 | Focus on open, clear on close
When the launcher opens, the text field takes keyboard focus (the drawers window asks Hyprland for keyboard focus while the launcher is open). When it closes, the query is cleared for next time.
@ 67-80 | A list that grows upward
`verticalLayoutDirection: ListView.BottomToTop` puts item 0 at the bottom, right above the search bar. `height: contentHeight` and `interactive: false` make it a plain stack (no scrolling needed with 7 results). `ScriptModel` keeps rows alive as results change, so the `add` and `displaced` transitions can animate instead of rebuilding the list.
@ 82-86 | The highlight
A rounded highlight behind the current row that slides between rows.
@ 88-128 | One row
Apps show their real icon; actions show a Material icon. Two text lines: the name and a dimmer description. Hovering a row moves the keyboard selection, so mouse and keyboard never disagree.
@ 134-143 | Wallpaper mode
A thumbnail strip replaces the list; anything you type after `>wallpaper` filters by file name.
@ 145-191 | The search bar
A pill with an icon (search or terminal, depending on the mode) and a `TextField` with its background removed. Because the list is upside-down, ↑ moves to a **higher index** (further from the bar). Enter runs the current row (or applies the highlighted wallpaper).
@ 193-199 | The calculator
`qalc -t` prints just the result of an expression and understands units and currencies (`>calc 5 USD to EUR`). It runs when the text changes in calc mode, and the result appears as the only row; Enter copies it.
:::

## Module 3: Small helpers

@include cae/modules/launcher/IconImageWrapper.qml

@include cae/modules/launcher/WallpaperGrid.qml

The wallpaper strip shows every image in `paths.wallpaperDir` (scanned by the `Wallpapers` service). The current wallpaper has a primary-coloured border. Applying one calls `Wallpapers.set()`, which saves it and runs **matugen**, which regenerates `scheme.json`, which `Colours` reloads: picking a wallpaper re-themes the whole shell. [[ch:cae8-lock-background]] covers the service.

> [!NOTE] In the original
> `modules/launcher/` has separate item types (`AppItem`, `ActionItem`, `CalcItem`, `SchemeItem`, `VariantItem`, `WallpaperItem`) and services for actions, colour schemes and Material "variants" (tonal spot, vibrant, expressive…). The wallpaper picker is a large horizontal carousel. Actions are configurable in `shell.json`.

## Practice

::: exercise warm | Your own action
Add a `>term` action that opens your terminal (`Config.services.terminal`).
--- solution
```js
{ name: "term", icon: "terminal", desc: "Open a terminal", run: () => Quickshell.execDetached([Config.services.terminal]) },
```
:::

::: exercise practice | Light and dark
Add `>light` and `>dark` actions that regenerate the scheme in that mode (`matugen image <current wallpaper> -m light`).
:::

::: exercise practice | Wallpaper keys
In wallpaper mode, make ← and → move through the thumbnails.
--- hint
In the `TextField`, add `Keys.onLeftPressed` / `Keys.onRightPressed` that change `walls.currentIndex` only when `root.wallpaperMode` is true (otherwise let the text cursor move: set `event.accepted = false`).
:::

::: exercise challenge | Launch counts
Remember how many times each app was launched (a `JsonAdapter` in the state folder) and add the count to the score, so apps you use often rise to the top.
:::
