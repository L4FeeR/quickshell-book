# Settings App 4: The Pages

With rows, sections and the window in place, each page is a readable list of settings. This chapter goes through all seven, plus the two special editors: a **live frame preview** drawn with the shell's own components, and an **editor for the bar's module list**.

```text
modules/settings/pages/  AppearancePage  FramePage  BarPage  PanelsPage  ServicesPage  KeybindsPage  ProfilesPage
modules/settings/        FramePreview  EntriesEditor
```

Every row follows the same three lines: `value:` binds to the setting, `defaultValue:` states the default, and `onEdited:` writes the new value to `Config`. Because the shell is built from bindings, nothing else is needed for the change to appear on screen.

## Page 1: Appearance

@include cae/modules/settings/pages/AppearancePage.qml

| Setting | What happens when you change it |
|---|---|
| **Mode** (segmented) | writes `appearance.mode`, then `Wallpapers.regenerate()` re-runs matugen on the current wallpaper in that mode; the new `scheme.json` re-colours everything |
| **Wallpaper grid** | each thumbnail calls `Wallpapers.set(path)`: saved, matugen runs, colours update. The current wallpaper gets a primary border and rounder corners |
| **Wallpaper folder** | a `TextRow`; after editing, `Wallpapers.rescan()` lists the new folder (this row has no default, so no reset button) |
| **Transparency / Opacity** | the frame and drawers become see-through at once ([[ch:cae3-frame]] draws them in one layer, so overlaps never darken) |
| **Font** | `Tokens.font.sans` follows `appearance.font`, so every `StyledText` in the shell switches font |
| **Roundness** | scales every rounding token: cards, buttons, drawers and their concave joints |
| **Animation speed** | divides every duration token: 2× makes the whole shell snappier, 0.5× calmer |

The wallpaper grid isn't a row, so it sets its own visibility during search (it shows when the search matches "wallpaper", "background" or "image").

## Page 2: Frame, with a live preview

@include cae/modules/settings/pages/FramePage.qml

Two spin rows change the frame's thickness and inner rounding. Above them, the preview:

@include cae/modules/settings/FramePreview.qml

::: walk
@ 14-16 | Half-size measurements
The preview draws everything at half scale: thickness, the bar's width (computed exactly as `BarWrapper` does) and the rounding all come from the live config.
@ 22 | Hidden while searching
It's not a setting, so it disappears when you search.
@ 24-38 | A fake screen
A 400×200 area with a gradient in the theme's primary and tertiary colours as the "wallpaper".
@ 40-42 | Same transparency trick
Drawn opaque inside an item that gets the surface opacity, like the real frame.
@ 44-49 | The real Border
`Border.qml` from the drawers module, with the scaled values. This is the same shape the shell draws; nothing is faked.
@ 50-57 | Two dummy drawers
Empty items positioned where a dashboard (top) and an OSD (right) would be.
@ 58-67 | The real PanelBg
`PanelBg.qml` draws their backgrounds with concave joints that follow the rounding setting. Move the rounding spinner and watch the joints grow.
:::

> [!TIP] Reuse the real components in previews
> A preview built from the shell's own components can never disagree with the shell. If you change how the frame is drawn, the preview changes too.

## Page 3: Bar, with a module editor

@include cae/modules/settings/pages/BarPage.qml

"Always visible" and the workspace options are plain rows. The modules list uses a custom editor:

@include cae/modules/settings/EntriesEditor.qml

::: walk
@ 13-19 | Value, names and edits
`value` is the current list (`Config.bar.entries`). `available` maps each module id to a label and icon. Like a row, the editor only emits `edited(newList)`.
@ 21-27 | Moving an entry
Copy the list, swap two neighbours with destructuring assignment, report the new list. The original list is never modified in place; a new array also guarantees QML sees the change.
@ 31 | Searchable
The editor shows when the search mentions bar modules, ordering, adding or removing.
@ 33-60 | One row per module
Position, icon and label, then ↑, ↓ (disabled at the ends) and ✕. Removing filters the list without that index.
@ 62-91 | Adding modules
Chips for modules that aren't on the bar yet; spacers can always be added. Clicking appends to the list.
:::

Each edit writes `Config.bar.entries`; the bar's `Repeater` over that list ([[ch:cae4-bar]]) rebuilds the bar in the new order immediately.

## Page 4: Panels

@include cae/modules/settings/pages/PanelsPage.qml

Hover behaviour for the dashboard and notification centre, the launcher's command prefix and result count, and the popup and OSD timings. The prefix row guards against an empty value (`v || ">"`), because an empty prefix would turn every search into a command.

## Page 5: Services

@include cae/modules/settings/pages/ServicesPage.qml

Volume and brightness steps (used by scrolling, the OSD and keys), the terminal used by launcher actions, and the profile picture path.

## Page 6: Keybinds

@include cae/modules/settings/pages/KeybindsPage.qml

A list of every shortcut, built from data with a `Repeater` of `SettingRow`s (so they're searchable too). Each row shows the keys, the exact Hyprland line in the description, a **copy** button (`wl-copy`) and a **play** button that runs the action now through IPC. Because the play button uses `qs -c cae ipc call …`, it works in both modes: from inside the shell and from the standalone settings program.

> [!NOTE] In the original
> end-4 reads the **real** keybinds from Hyprland (`hyprctl binds -j`, see the cheatsheet in [[ch:g3-islands-popups]]) and shows them in its cheatsheet panel, grouped by the comments in its keybind file. That's a good upgrade for this page.

## Page 7: Profiles & data

@include cae/modules/settings/pages/ProfilesPage.qml

Saving, loading and deleting profiles, exporting a backup, resetting to defaults, opening the config folder and reloading the shell. Every button calls the `Profiles` service, covered with the rest of the "managing the rice" features in [[ch:set5-profiles]].

## Practice

::: exercise warm | A new setting end to end
Add `bar.clockSeconds` (default `false`): a `property bool clockSeconds` in `Config.qml`, a `SwitchRow` on the Bar page, and `Time.format(Config.bar.clockSeconds ? "hh:mm:ss" : "hh:mm")` in the dashboard clock. Toggle it and watch it change.
--- hint
`Time` updates every second, so the binding with seconds updates by itself.
:::

::: exercise practice | Preview the bar
Add a preview to the Bar page: a miniature vertical bar that shows the current module order as icons, using `Config.bar.entries` and the `available` table.
:::

::: exercise practice | Wallpaper paging
The grid shows the first 24 wallpapers. Add "Show more" that loads 24 more each time.
:::

::: exercise challenge | Real keybinds
Replace the static list on the Keybinds page with Hyprland's real binds (`hyprctl binds -j`), keeping only those that dispatch `global` with `cae:` or run `qs -c cae`.
:::
