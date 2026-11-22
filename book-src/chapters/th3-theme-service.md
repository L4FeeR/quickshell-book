# Theming 3: The Theme Service

The `Theme` singleton is the heart of the switcher. It loads the theme files, turns roles into colours, measures contrast, switches themes, remembers your choice, follows a day/night schedule and answers commands from the terminal. Every widget in the shell talks to it, and only to it.

This chapter walks through the whole file, every line, in order.

@include theming/services/Theme.qml

## Line by line

::: walk
@ 1 | A singleton
`pragma Singleton` makes exactly one `Theme` for the whole shell. Any file that writes `import qs.services` can use `Theme.colors.primary`.
@ 2-5 | Imports
`Quickshell` for `Singleton`, `SystemClock` and `Quickshell.shellPath`; `Quickshell.Io` for `Process`, `FileView`, `JsonAdapter` and `IpcHandler`; `QtQuick` for the basics. `qs.services` is the file's own folder: importing it explicitly keeps tools like qmllint happy about other singletons there.
@ 13 | All loaded themes
An object from id to theme, like `{ "nord": {…}, "dracula": {…} }`. It starts empty and is filled by `load()` at the bottom. `var` because it's plain JavaScript data.
@ 14 | The preview
While you hover a card in the picker, its id goes here and the whole shell shows that theme. It's never saved.
@ 15 | The chosen theme
What you picked, or, when automatic switching is on, the theme the schedule says (`scheduledId`, line 25). Because this is a binding, flipping `autoSwitch` immediately changes the chosen theme.
@ 16 | The active theme
The preview if there is one, otherwise the chosen theme. Everything visible follows `activeId`; saving and exporting follow `chosenId`. Keeping the two apart is what makes previews safe.
@ 17 | The theme object
Look up the active id. If it doesn't exist (a typo, or the files haven't loaded yet), use Catppuccin Mocha, and if even that's missing, the built-in fallback at the end of the file. The `??` operator means "if the left side is null or undefined, use the right side".
@ 18 | Dark or light
A convenience: `true` unless the theme says `"variant": "light"`.
@ 21 | The sorted list
All themes as an array, sorted by family, then by name. `localeCompare` sorts text properly (accents included). The picker and next/previous use this order.
@ 24-25 | Day or night
`isDay` is true between `dayStart` and `nightStart` (7:00 and 19:00 by default). `scheduledId` picks the day or night theme. `clock` is the `SystemClock` near the bottom; with minute precision, the binding re-checks every minute, so the switch happens by itself at 7:00 and 19:00.
@ 28-50 | The colours
One property per role. Each calls `role("…")`, which reads the active theme. Because `role()` uses `theme`, which uses `activeId`, changing the theme re-evaluates all 17 bindings at once, and every widget bound to them updates. `success`, `warning` and `error` are aliases of green, yellow and red, so widgets can say what they *mean*.
@ 54-58 | Resolving a role
Take the role's value from the theme. If it starts with `#`, it's already a colour. Otherwise it's a palette name, so look it up in the palette. If anything is missing, return `#ff00ff` (bright pink) so a broken theme file is easy to spot. The `?.` operator means "stop and give `undefined` if the left side is null", so a half-written theme can't crash the shell.
@ 59-61 | role()
`resolve` for the active theme. Declaring the return type `color` converts the hex string into a real colour.
@ 64-66 | alpha()
The same colour with a different opacity: `Theme.alpha(Theme.colors.primary, 0.2)` for a soft tint.
@ 67-69 | mix()
Blends two colours: `mix(background, primary, 0.1)` is the background with 10% of the accent, handy for subtle hover colours that suit every theme.
@ 71-78 | contrast()
The WCAG contrast ratio from [[ch:th1-colour-basics]]. `lum` computes a colour's **relative luminance**: each channel is converted from screen values to light intensity (the `ch` function), then weighted by how sensitive our eyes are to red, green and blue (green counts most). The ratio is (lighter + 0.05) / (darker + 0.05).
@ 80-82 | readableOn()
For a background you don't control (an album cover's colour, a tag colour), pick whichever of the theme's text or background colour is more readable on it.
@ 85-90 | set()
Choose a theme for good: ignore unknown ids, end any preview, turn off automatic switching (you've made a manual choice), and store the id in the saved settings, which writes it to disk.
@ 91-94 | step()
Next (+1) or previous (−1) theme in the sorted list, wrapping around at both ends. Adding `ids.length` before `%` keeps the index positive when going back from the first theme.
@ 96-100 | toggleVariant()
Find a theme with the same family and the opposite variant (Mocha → Latte, Tokyo Night → Tokyo Night Day) and switch to it. Families without a twin (Nord, Dracula) simply don't change.
@ 104 | Your themes folder
`~/.config/theming/themes` (respecting `XDG_CONFIG_HOME` if set). Themes you write or download go here, outside the kit's own folder, so updating the kit never deletes them.
@ 106-110 | Loading
`load()` starts the loader process; it runs once at startup and again when you call `reload` over IPC.
@ 112-116 | Reading every file at once
One small shell loop prints every `.json` file from the built-in folder (`Quickshell.shellPath("themes")` is `themes/` inside this config) and then from your folder. After each file it prints a line containing the ASCII "record separator" character (code 30, written `\036`), which never appears in JSON, so the output can be split back into files. Both folder paths are passed as arguments (`$1`, `$2`), never pasted into the command, so unusual folder names can't break anything.
@ 117-131 | Parsing
Split the output on the separator, parse each piece, and keep it if it has an id, a palette and roles. A broken file is skipped with a warning instead of breaking the whole switcher. Your folder is read last, so a file of yours with a built-in's id replaces the built-in. Assigning `root.themes` once at the end updates the list and the picker in one step.
@ 135-150 | Saving your choice
A `FileView` + `JsonAdapter` pair stores six settings in the shell's state folder (`Quickshell.statePath`, under `~/.local/state/quickshell/`): the theme, whether automatic switching is on, the day and night themes, and the two switch hours. `onAdapterUpdated: writeAdapter()` saves every change; `onLoadFailed: writeAdapter()` creates the file on the first run.
@ 151 | Exposing the settings
`Theme.settings.autoSwitch` and friends can be read and changed from widgets (the picker's schedule button does).
@ 153-156 | The clock
Used by `isDay`. Minute precision is plenty for a schedule.
@ 159-169 | Terminal commands
Each function becomes a command: `qs -c theming ipc call theme set nord`, `… theme next`, `… theme list` (prints every id), `… theme get`, `… theme reload` (after adding a file), `… theme auto true`. Scripts, keybinds and cron jobs can drive the theme this way.
@ 172-178 | The fallback
Catppuccin Mocha written directly as role colours, so the very first frame, before the files are read, already looks right.
:::

## Trying it from a terminal

```bash
qs -c theming ipc call theme list            # every theme id
qs -c theming ipc call theme set tokyo-night
qs -c theming ipc call theme toggleVariant   # Tokyo Night -> Tokyo Night Day
qs -c theming ipc call theme next
qs -c theming ipc call theme auto true       # follow the day/night schedule
```

Change the schedule by editing `~/.local/state/quickshell/by-shell/<id>/theme.json` (or from the exercises below).

> [!NOTE] Compared to Caelestia and end-4
> Caelestia's `Colours` service ([[ch:cae2-foundations]]) and end-4's `MaterialThemeLoader` ([[ch:ii2-foundations]]) load a **single generated scheme** (from the wallpaper or a preset) into Material roles. This service keeps a **library** of named themes and switches between them; [[ch:th7-beyond-the-shell]] adds a wallpaper-generated theme to the same library.

## Practice

::: exercise warm | A new IPC command
Add `function random(): void` that picks a random theme.
--- solution
```qml
function random(): void { root.set(root.list[Math.floor(Math.random() * root.list.length)].id) }
```
:::

::: exercise practice | Schedule from the terminal
Add IPC functions `setDay(id: string)` and `setNight(id: string)` that change `saved.dayTheme` and `saved.nightTheme`.
:::

::: exercise practice | A contrast warning
Log a warning when a theme loads whose `text` has less than 4.5:1 contrast on its `background`.
--- hint
In the loader's handler, after parsing `t`, compute `root.contrast(root.resolve(t, "text"), root.resolve(t, "background"))`. (`contrast` takes colours; QML converts the hex strings when you pass them to a `color` parameter.)
:::

::: exercise challenge | Watch the folder
Make new theme files appear without calling `reload`: run `inotifywait -m -e close_write,moved_to,delete ~/.config/theming/themes` as a long-running `Process` and call `load()` on each line it prints.
:::
