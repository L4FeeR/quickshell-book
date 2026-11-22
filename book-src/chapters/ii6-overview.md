# end-4 6: The Overview and Search

Press Super+Tab (or right-click the workspaces, or just tap Super) and ii shows the **overview**: a search box above a grid of your workspaces, each a small copy of the screen with **live previews** of its windows. Start typing and the grid turns into launcher results: apps, a calculator, commands and web search. Drag a window onto another workspace to move it.

<div class="preview"><svg width="620" height="300" viewBox="0 0 620 300"><g font-size="10"><rect width="620" height="300" fill="#3a5a8c" opacity=".35"/><rect x="170" y="14" width="280" height="36" rx="18" fill="#141218" stroke="#49454f"/><text x="190" y="36" fill="#938f99">⌕  Search, calculate or run</text><g transform="translate(70 70)"><rect width="480" height="200" rx="22" fill="#141218" stroke="#49454f"/><g transform="translate(12 12)"><g><rect width="86" height="84" rx="10" fill="#1d1b20" stroke="#d0bcff" stroke-width="2"/><rect x="6" y="8" width="44" height="66" rx="5" fill="#2b2930"/><rect x="54" y="8" width="26" height="30" rx="5" fill="#2b2930"/><rect x="54" y="42" width="26" height="32" rx="5" fill="#2b2930"/></g><g transform="translate(92 0)"><rect width="86" height="84" rx="10" fill="#1d1b20"/><rect x="8" y="10" width="70" height="60" rx="5" fill="#2b2930"/></g><g transform="translate(184 0)"><rect width="86" height="84" rx="10" fill="#1d1b20"/><text x="43" y="50" fill="#938f99" font-size="22" text-anchor="middle" opacity=".4">3</text></g><g transform="translate(276 0)"><rect width="86" height="84" rx="10" fill="#1d1b20"/><text x="43" y="50" fill="#938f99" font-size="22" text-anchor="middle" opacity=".4">4</text></g><g transform="translate(368 0)"><rect width="86" height="84" rx="10" fill="#1d1b20"/><text x="43" y="50" fill="#938f99" font-size="22" text-anchor="middle" opacity=".4">5</text></g><g transform="translate(0 92)"><rect width="86" height="84" rx="10" fill="#1d1b20"/><rect x="10" y="12" width="66" height="58" rx="5" fill="#2b2930"/></g><g transform="translate(92 92)"><rect width="86" height="84" rx="10" fill="#1d1b20"/><text x="43" y="50" fill="#938f99" font-size="22" text-anchor="middle" opacity=".4">7</text></g><g transform="translate(184 92)"><rect width="86" height="84" rx="10" fill="#1d1b20"/><text x="43" y="50" fill="#938f99" font-size="22" text-anchor="middle" opacity=".4">8</text></g><g transform="translate(276 92)"><rect width="86" height="84" rx="10" fill="#1d1b20"/><text x="43" y="50" fill="#938f99" font-size="22" text-anchor="middle" opacity=".4">9</text></g><g transform="translate(368 92)"><rect width="86" height="84" rx="10" fill="#1d1b20"/><text x="43" y="50" fill="#938f99" font-size="22" text-anchor="middle" opacity=".4">10</text></g></g></g><text x="310" y="292" fill="#cdd6f4" text-anchor="middle">2 × 5 workspaces; windows are scaled live previews you can click or drag</text></g></svg></div>

```text
modules/overview/  Overview  OverviewGrid  AppIconImage
services/          LauncherSearch  HyprlandData
```

## Module 1: Window data

The overview needs every window's **position and size** on screen, which Quickshell's toplevel list doesn't include. ii asks Hyprland directly.

@include impulse/services/HyprlandData.qml

::: walk
@ 12-13 | The data
`windowList` is `hyprctl clients -j` parsed: one object per window with `address`, `at` (x, y), `size` (w, h), `workspace`, `class`, `title`… `monitors` is `hyprctl monitors -j`, used to turn global positions into positions on one monitor.
@ 15-18 | Refresh
Both commands run again whenever something might have moved.
@ 22-28 | Listening to Hyprland
`rawEvent` delivers every event from Hyprland's event socket. Only events that change window positions trigger a refresh, so the data stays current without polling.
:::

## Module 2: Search

@include impulse/services/LauncherSearch.qml

::: walk
@ 11-12 | Query in, results out
The overview writes `query`; everything else is derived.
@ 14-28 | Results in priority order
A maths result first (if any), then up to ~9 matching apps, then two fallbacks that always appear: run the text as a shell command, or search the web for it. Each result has a `type` label, a name, an icon (Material symbol name or app icon name) and a `run` function.
@ 30-33 | When to calculate
Only text made of digits and operators, or containing " to " (unit/currency conversion), is sent to `qalc`. Every other query skips the calculator.
@ 35-39 | qalc
Runs with the query and stores the terse result.
:::

> [!NOTE] In the original
> `services/LauncherSearch.qml` supports **prefixes** (`/` actions, `:` emoji, `;` clipboard, `=` maths, `!` web…), fuzzy app search, and Hyprland-aware actions. Results render as a `SearchWidget` with keyboard navigation, and the same window hosts the emoji and clipboard pickers.

## Module 3: The overview window

@include impulse/modules/overview/Overview.qml

::: walk
@ 18-32 | One window per monitor, shown on the focused one
`open` is true only on the monitor that has focus, so the overview appears where you're looking. It covers the screen on the overlay layer and takes the keyboard **exclusively** while open, so you can type immediately.
@ 34 | Opening resets the search
Each time it opens: clear the text, focus the field, refresh window data.
@ 36-39 | Click the background to close
A full-window `MouseArea` behind everything.
@ 46-80 | The search pill
A `TextField` without a background inside a rounded `colLayer0` pill. Typing updates `LauncherSearch.query`; ↑/↓ move through results; Enter runs the selected one; Esc closes.
@ 82-122 | Results
Only shown while there's text. Each row is a `RippleButton` with an icon (an app icon when the result has `iconName`, a Material symbol otherwise), a small type label and the name.
@ 124-130 | The grid
Shown when the search is empty.
@ 135-143 | Opening it
IPC and a global shortcut toggle `GlobalStates.overviewOpen`. Right-clicking the bar's workspaces does the same ([[ch:ii4-workspaces]]).
:::

## Module 4: The workspace grid with live previews

A tiny helper used for app icons in results and previews:

@include impulse/modules/overview/AppIconImage.qml

@include impulse/modules/overview/OverviewGrid.qml

::: walk
@ 16-22 | Grid geometry
`rows × columns` workspaces (2 × 5 by default), each the monitor's size times `previewScale` (0.18). `groupStart` shows the group that contains the active workspace. `monData` is this monitor's entry from `hyprctl monitors`.
@ 40-53 | A workspace tile
A small `colLayer1` rectangle; the active workspace gets a primary border. `clip: true` keeps window previews from spilling out.
@ 55-67 | Number and click
A big faint number behind the windows. Clicking empty space in a tile switches to that workspace and closes the overview.
@ 69-72 | Accepting dropped windows
A `DropArea` over the tile: when a window is dropped, it's moved there with `Hypr.moveWindowToWorkspace()` (silently, without following it).
@ 74-75 | This workspace's windows
Filter the window list by workspace id.
@ 80-84 | Matching Hyprland and Wayland
Hyprland's data gives an `address`; the live preview needs the Wayland [[Toplevel]]. The `HyprlandToplevel` attached property on each toplevel exposes its Hyprland address (without the `0x`), which is how the two are matched, the same way the original does it.
@ 86-92 | Scaled position and size
The window's global position minus the monitor's position gives its place on this monitor; multiplying by `previewScale` places it inside the tile.
@ 93-96 | Draggable
The `Drag` attached properties make the window a drag source carrying itself (`Drag.source: winItem`), so the `DropArea` can read its `address`.
@ 98-102 | Live preview
[[ScreencopyView]] shows the window's live contents. `captureSource` is only set while the overview is open, so nothing is captured when it's closed.
@ 103-107 | Icon on top
The app icon over the preview, sized relative to the window.
@ 108-114 | Click and drag
Clicking focuses the window. `drag.target` lets the mouse move it; on release it's dropped, and its position is re-bound to the window data (`Qt.binding`), so it snaps back if it wasn't dropped on another workspace.
:::

> [!NOTE] In the original
> `modules/ii/overview/OverviewWidget.qml` and `OverviewWindow.qml` also handle rotated monitors (`transform`), reserved areas (the bar's space), special workspaces, per-corner rounding so windows at the tile's edges match its rounded corners, middle-click to close a window, and dragging a window to a **position** inside a workspace, not just to the workspace.

## Practice

::: exercise warm | Bigger previews
Set `overview.scale` to 0.25 and `overview.columns` to 4 in `config.json`.
:::

::: exercise practice | Middle-click to close
Middle-click a window preview to close it (`closewindow address:…`, or `hl.dsp.window.close({ window = "address:…" })` on Lua configs; add a `closeWindow` helper to `Hypr`).
:::

::: exercise practice | Emoji results
When the query starts with `:`, return emoji results (see the emoji picker in [[ch:g4-panels]]) that copy the emoji with `wl-copy`.
:::

::: exercise challenge | Keyboard navigation in the grid
With an empty search, let the arrow keys move a highlight between workspaces and Enter switch to the highlighted one.
:::
