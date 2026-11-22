# Settings App 3: The Window, Navigation and Search

The pages need a home: a resizable window with a title, a search field, a navigation rail with one entry per page, and the current page on the right. This chapter builds that window, the small state singleton that drives it, and both ways of opening it.

```text
modules/settings/  SettingsState  SettingsWindow  NavRail  Settings
settings.qml
```

## Module 1: Shared state

@include cae/modules/settings/SettingsState.qml

::: walk
@ 7-8 | Page and search
Two properties drive the whole window. Pages, rows and the navigation rail all read them, so changing either one updates everything.
@ 11-19 | The page list
Ids, labels and Material icons for the navigation rail. The order matches the pages in the window's `StackLayout`.
@ 22-25 | One matching rule
Every row asks this function whether it matches: the search text is lower-cased and looked up in up to three strings. The function is deliberately **untyped**. With `(a: string, …)`, a missing argument would be converted to the string `"undefined"`, and a search for "def" would match rows that never mention it.
:::

## Module 2: The window

@include cae/modules/settings/SettingsWindow.qml

::: walk
@ 13-20 | A normal window
[[FloatingWindow]] is Quickshell's type for an ordinary application window: the compositor decorates it, tiles or floats it like any app, and you can resize it down to `minimumSize`. Panels use `PanelWindow`; settings shouldn't be a panel.
@ 22-23 | Match counts
The seven pages, and the number of search matches on each (every page computes its own `matchCount`, [[ch:set2-building-blocks]]).
@ 25-36 | Jump to results
When you type a search and the current page has no matches, the window switches to the first page that has some. `Qt.callLater` waits until the pages have recounted with the new text.
@ 44-50 | A fixed-width side column
A `ColumnLayout` whose children fill its width would itself fill the width of the row, squeezing the pages to nothing. Pinning it to 250 px fixes that. (This exact bug showed up when testing the app, see [[ch:set5-profiles]].)
@ 60-91 | The search field
A pill containing a `TextField` that writes `SettingsState.query`. Esc or the ✕ button clears it.
@ 93-96 | Navigation
The rail gets the match counts for its badges.
@ 110-128 | Pages
All pages are created once and kept; `StackLayout` shows the current one. Switching pages is instant, and each page keeps its scroll position.
:::

## Module 3: The navigation rail

@include cae/modules/settings/NavRail.qml

Each entry is a pill: filled with the secondary container colour and a filled icon when selected. While searching, pages with matches show a **badge** with the count and pages without matches fade to 40%, so you can see at a glance where a setting lives.

## Module 4: Opening it inside the shell

@include cae/modules/settings/Settings.qml

::: walk
@ 11 | One window at most
`window` holds the open settings window, or `null`.
@ 13-16 | Open
Create the window from the component if none is open. Opening twice does nothing.
@ 18-27 | Close
When the window is closed, forget it and destroy it, which frees all its pages. The next `open()` creates a fresh one.
:::

> [!NOTE] In the original
> Caelestia's `modules/nexus/WindowFactory.qml` uses the same pattern: a singleton with a `Component` holding a `FloatingWindow`, created with `createObject` and destroyed when it's hidden.

Four ways reach `Settings.open()` in the rebuild:

| Where | How |
|---|---|
| Keybind | `GShortcut { name: "settings" }` in `daemons/Shortcuts.qml`; bind it with `bind = SUPER, comma, global, cae:settings` |
| IPC | `IpcHandler { target: "settings" }` in the same file: `qs -c cae ipc call settings open` |
| Launcher | the `>settings` action in `modules/launcher/Content.qml` |
| Quick toggles | the gear button in `modules/utilities/Content.qml` |

## Module 5: Opening it as its own program

@include cae/settings.qml

`qs -p <file>` runs a single QML file as a shell. The file's folder becomes the config root, so `import qs.modules.settings` finds the same modules, and the app uses its own copy of `Config`, `Colours` and `Tokens`, reading the same files as the shell. When the window closes, `Qt.quit()` ends the program.

Two things to be careful about in a second process:

- **Don't touch singletons that own system services.** If the settings app used `Notifs`, it would start a second notification server; if it created `GlobalShortcut`s, they would collide with the shell's. The pages here only use `Config`, `Colours`, `Tokens`, `Wallpapers` and `Profiles`.
- **Actions that belong to the shell go through IPC.** "Reload the shell" and the keybind "play" buttons run `qs -c cae ipc call …`, so they work the same from both modes.

> [!NOTE] In the original
> end-4 starts its settings with `qs -p ~/.config/quickshell/ii/settings.qml`, from the right sidebar's settings button and the `Super+I` keybind. It sets `Config.readWriteDelay = 0` on startup so each change is written immediately.

## Practice

::: exercise warm | Remember the page
Open the settings on the page you last used: store `SettingsState.page` in a `PersistentProperties` (inside the shell) or a small state file (works in both modes).
:::

::: exercise practice | Open on a page
Add `IpcHandler` function `openPage(id: string)` that opens the window directly on a page: `qs -c cae ipc call settings openPage bar`.
--- solution
```qml
function openPage(id: string): void {
    const i = SettingsState.pages.findIndex(p => p.id === id);
    if (i >= 0) SettingsState.page = i;
    Settings.open();
}
```
:::

::: exercise practice | Ctrl+F
Focus the search field when Ctrl+F is pressed anywhere in the window.
--- hint
`Shortcut { sequence: StandardKey.Find; onActivated: search.forceActiveFocus() }` inside the window.
:::

::: exercise challenge | A compact layout
When the window is narrower than 900 px, collapse the navigation rail to icons only.
:::
