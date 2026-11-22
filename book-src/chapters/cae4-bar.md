# Caelestia 4: The Vertical Bar and Its Popouts

Caelestia's bar runs down the left side of the screen, inside the frame. It's narrow (40 px of content), so every module is designed for a column: workspaces stack vertically, the window title is written sideways, and the clock shows hours above minutes. Hovering a status icon slides a **popout** out of the bar with details.

<div class="preview"><svg width="560" height="360" viewBox="0 0 560 360"><g font-size="11"><rect x="0" y="0" width="64" height="360" fill="#141218"/><g transform="translate(12 0)"><circle cx="20" cy="22" r="10" fill="#d0bcff"/><rect x="0" y="42" width="40" height="120" rx="20" fill="#211f26"/><rect x="6" y="48" width="28" height="44" rx="14" fill="#36343b"/><rect x="6" y="48" width="28" height="28" rx="14" fill="#d0bcff"/><text x="20" y="66" fill="#381e72" text-anchor="middle" font-size="10">1</text><rect x="13" y="78" width="14" height="10" rx="3" fill="#fab387"/><text x="20" y="108" fill="#938f99" text-anchor="middle" font-size="10">2</text><rect x="6" y="116" width="28" height="40" rx="14" fill="#36343b"/><text x="20" y="130" fill="#e6e0e9" text-anchor="middle" font-size="10">3</text><rect x="13" y="138" width="14" height="10" rx="3" fill="#89b4fa"/><text x="20" y="230" fill="#ccc2dc" font-size="10" text-anchor="middle" transform="rotate(90 20 230)">kitty — ~/rice</text><rect x="0" y="268" width="40" height="28" rx="14" fill="#211f26"/><circle cx="14" cy="282" r="5" fill="#a6e3a1"/><circle cx="27" cy="282" r="5" fill="#89b4fa"/><text x="20" y="312" fill="#efb8c8" text-anchor="middle">14</text><text x="20" y="326" fill="#efb8c8" text-anchor="middle">32</text></g><path d="M64 170 Q88 170 88 194" fill="none"/><path d="M64 160 A24 24 0 0 1 88 184 V256 A24 24 0 0 0 112 280 H0" fill="#141218" opacity="0"/><rect x="64" y="176" width="230" height="120" rx="22" fill="#141218"/><rect x="64" y="176" width="24" height="120" fill="#141218"/><text x="84" y="202" fill="#e6e0e9" font-size="13">Output</text><text x="84" y="226" fill="#d0bcff">◉ Speakers</text><text x="84" y="246" fill="#cac4d0">○ Headphones</text><rect x="84" y="262" width="150" height="6" rx="3" fill="#36343b"/><rect x="84" y="262" width="96" height="6" rx="3" fill="#d0bcff"/><text x="244" y="268" fill="#e6e0e9">64%</text><g fill="#cdd6f4"><text x="110" y="22">← logo (opens launcher)</text><text x="110" y="70">← workspaces: merged backgrounds, trailing pill, app icons</text><text x="110" y="232" opacity="0">.</text><text x="300" y="232">← audio popout (hover the speaker icon)</text><text x="110" y="320">← clock (hh over mm)</text></g></g></svg></div>

```text
modules/bar/      BarWrapper  Bar  OsIcon  Workspaces  ActiveWindow  Tray  Clock  StatusIcons  Power
modules/popouts/  Wrapper  AudioPopout  NetworkPopout  BluetoothPopout  BatteryPopout
```

## Module 1: The bar's slot

The bar lives in the frame's left side. When `bar.persistent` is false, it shrinks to the frame thickness and slides out when you touch the left edge.

@include cae/modules/bar/BarWrapper.qml

::: walk
@ 15-19 | Shown, width and reserved space
`contentWidth` is the inner width plus padding on both sides. `shown` is true when the bar is persistent, toggled on by a keybind (`screenState.bar`), or hovered. `exclusiveZone` is what `Exclusions` reserves: the full bar when it's pinned, just the frame when it auto-hides (so a hovered bar overlays windows instead of pushing them).
@ 21-23 | A door for the drawers window
`Interactions` calls this while the pointer moves over the bar. `?.` makes it safe while the bar isn't loaded.
@ 25-30 | Sliding by width
The wrapper's width animates, and `clip` hides the part of the bar that doesn't fit. Because the frame's left side is bound to this width (in `ContentWindow`), the frame itself animates along.
@ 32-46 | Load only when needed
The real bar is anchored to the **right** side of the wrapper, so as the wrapper narrows, the bar slides left out of view. The `Loader` keeps it alive during the closing animation (`implicitWidth > thickness`) and destroys it once hidden.
:::

## Module 2: The bar, from a list of entries

@include cae/modules/bar/Bar.qml

::: walk
@ 17-30 | Which popout?
`childAt()` returns the entry under the pointer. For the status icons, the entry is asked which icon is at that height (`iconAt`); the popout gets that icon's name and its vertical centre in bar coordinates, so it can slide to line up with the icon.
@ 34-53 | Entries from the config
A `Repeater` over `Config.bar.entries` creates one `Loader` per entry. The map `({ name: component })[modelData]` picks the component by name, so reordering the JSON list reorders the bar. A `"spacer"` fills the remaining height, which is how the bar spreads into top, middle and bottom groups. `entryId` lets `checkPopout` know what it hit.
@ 55-62 | The modules
Each module is declared once as a `Component`.
:::

> [!NOTE] In the original
> `modules/bar/Bar.qml` uses the same config-driven design with `DelegateChooser`/`DelegateChoice` and also handles the tray's expand/collapse and per-entry options (each entry in `shell.json` is an object with `id` and `enabled`). Scrolling over the bar's top half changes volume and over the bottom half brightness; try adding that in the exercises.

## Module 3: The logo

@include cae/modules/bar/OsIcon.qml

Your distro's ID comes from `/etc/os-release` (`ID=arch`), and icon themes usually ship a `distributor-logo-arch` icon. If not, it falls back to the generic `distributor-logo`, then `start-here`. The `StateLayer` gets negative margins so the round hover highlight is bigger than the icon.

## Module 4: Workspaces

The most detailed module of the bar. It shows a **group** of workspaces (5 by default: 1–5, then 6–10 when you move to 6), with three layers:

<div class="preview"><svg width="560" height="170" viewBox="0 0 560 170"><g font-size="11"><g transform="translate(30 10)"><rect width="40" height="150" rx="20" fill="#211f26"/><text x="20" y="168" fill="#a6adc8" text-anchor="middle" opacity="0">.</text></g><g transform="translate(130 10)"><rect width="40" height="150" rx="20" fill="#211f26"/><rect x="6" y="6" width="28" height="56" rx="14" fill="#36343b"/><rect x="6" y="94" width="28" height="28" rx="14" fill="#36343b"/></g><g transform="translate(230 10)"><rect width="40" height="150" rx="20" fill="#211f26"/><rect x="6" y="6" width="28" height="56" rx="14" fill="#36343b"/><rect x="6" y="94" width="28" height="28" rx="14" fill="#36343b"/><rect x="6" y="36" width="28" height="44" rx="14" fill="#d0bcff"/></g><g transform="translate(330 10)"><rect width="40" height="150" rx="20" fill="#211f26"/><rect x="6" y="6" width="28" height="56" rx="14" fill="#36343b"/><rect x="6" y="94" width="28" height="28" rx="14" fill="#36343b"/><rect x="6" y="36" width="28" height="28" rx="14" fill="#d0bcff"/><g fill="#e6e0e9" text-anchor="middle" font-size="10"><text x="20" y="24">1</text><text x="20" y="54" fill="#381e72">2</text><text x="20" y="82" fill="#938f99">3</text><text x="20" y="112">4</text><text x="20" y="140" fill="#938f99">5</text></g></g><g fill="#cdd6f4"><text x="50" y="168" text-anchor="middle">container</text><text x="150" y="168" text-anchor="middle">+ occupied</text><text x="250" y="168" text-anchor="middle">+ active (moving)</text><text x="350" y="168" text-anchor="middle">+ labels</text><text x="390" y="60">1 and 2 are occupied, so</text><text x="390" y="76">their backgrounds merge;</text><text x="390" y="92">the active pill stretches</text><text x="390" y="108">while it moves from 1 to 2.</text></g></g></svg></div>

@include cae/modules/bar/Workspaces.qml

::: walk
@ 16-20 | Which group?
`activeId` is the focused workspace on **this** monitor. `groupStart` rounds down to the start of its group: with 5 shown, workspace 7 gives a group starting at 6. `slot` is the size of one workspace cell.
@ 22-27 | Looking up workspaces
Hyprland only knows workspaces that exist. `workspace(id)` returns it or `null`; `occupied(id)` checks whether it has windows.
@ 34-60 | Merged occupied backgrounds
One background per cell. An occupied cell **stretches half the spacing up and down toward occupied neighbours** and drops its rounding on those sides, so runs of occupied workspaces look like one continuous pill. Empty cells fade to invisible.
@ 62-88 | The trailing active pill
The pill has two edges, `topEdge` and `bottomEdge`, each animated separately. When moving **down**, the bottom edge (the leading one) moves fast and the top edge (the trailing one) slowly, so the pill stretches toward its target and then catches up. Moving up does the opposite. `movingDown` is decided when the target changes. This is Caelestia's "active trail".
@ 90-110 | The cells
A `Column` of cells, created by a `Repeater` with an id so the layers above can find each cell with `cells.itemAt(index)`. (`column.children[index]` would be off by one, because the Repeater itself is also a child of the column.)
@ 112-121 | Number labels
The label colour depends on state: dark on the active pill, normal when occupied, faint when empty.
@ 123-141 | App icons
Up to three icons of the workspace's windows, under the number. A Hyprland window gives its app id through its Wayland object or its `class` from Hyprland's IPC, which is matched to an installed app to find the icon.
@ 143-146 | Click to switch
`Hypr.workspace()` uses the right command syntax for both classic and Lua Hyprland configs ([[ch:cae2-foundations]]).
@ 151-153 | Scroll to switch
Scrolling moves to the previous or next workspace.
:::

> [!NOTE] In the original
> `modules/bar/components/workspaces/` splits this into files: `Workspaces.qml`, `Workspace.qml` (one cell, with window icons mapped to Material icons by app category), `OccupiedBg.qml`, `ActiveIndicator.qml` (with the trail), `SpecialWorkspaces.qml` (scratchpads) and `GapMarkers.qml`.

## Module 5: The window title, written sideways

@include cae/modules/bar/ActiveWindow.qml

::: walk
@ 17-19 | Height from the title
The module is as tall as the icon plus the title's width (capped at 280 px), because the title is going to be rotated.
@ 28-38 | Rotating a Text
The text is laid out normally (horizontal), capped and elided, then `rotation: 90` turns it around its own centre. The `x`/`y` maths places that centre in the middle of the column, just below the icon: after rotating, the text's visual height equals its width.
@ 40-46 | Fading between titles
`Behavior on text` with a `SequentialAnimation`: fade out, `PropertyAction` applies the new text, fade back in. Switching windows cross-fades the title instead of snapping.
:::

## Module 6: Tray, clock and power

@include cae/modules/bar/Tray.qml

Left click calls `activate()`, right click shows the app's own menu with `display()`, which needs the window (from the `QsWindow` attached property) and a position in window coordinates.

@include cae/modules/bar/Clock.qml

@include cae/modules/bar/Power.qml

## Module 7: Status icons

@include cae/modules/bar/StatusIcons.qml

::: walk
@ 14-19 | Finding the hovered icon
`iconAt(y)` returns the icon under a y position (in this module's coordinates). Each icon has a `name`, used as the popout's name.
@ 32-55 | Four icons
Audio uses the icon from the `Audio` service. Network picks a signal-strength icon. Bluetooth and battery hide when there's no adapter or battery. The battery icon is chosen from 8 levels by rounding `percentage * 7`.
@ 58-61 | A tiny inline component
`component Icon: MaterialIcon { … }` saves repeating the same two lines four times. `required property string name` forces every icon to have a name.
:::

## Module 8: Popouts

The popout is a drawer on the **left** edge (the bar's side of the frame), positioned next to the hovered icon.

@include cae/modules/popouts/Wrapper.qml

::: walk
@ 11-16 | State set by the bar
`currentName` chooses the page, `currentCenter` the vertical position (Panels positions the popout at `currentCenter - height / 2`, clamped to the screen), `hasCurrent` opens it.
@ 18-30 | Morphing between pages
The content's size follows the current page with a fast animation. Moving from the audio icon to the battery icon therefore slides the popout down **and** resizes it in one smooth motion, which is one of Caelestia's nicest details.
@ 32-35 | The pages
One component per page, in the files below.
:::

@include cae/modules/popouts/AudioPopout.qml

@include cae/modules/popouts/NetworkPopout.qml

The network page turns on Wi-Fi **scanning** only while it's open (`Component.onCompleted` / `onDestruction`) to save power, then lists networks sorted connected-first and by signal. Clicking a known or open network connects; for new secured networks, see the Wi-Fi picker in the [[ch:g4-panels]] gallery for a password field you can add.

@include cae/modules/popouts/BluetoothPopout.qml

@include cae/modules/popouts/BatteryPopout.qml

> [!NOTE] In the original
> `modules/bar/popouts/` has more pages (tray menus with submenus via a `StackView`, keyboard layout, lock status, active-window preview with a live screencopy, Wi-Fi password dialog). They can also be **detached** into a floating window.

## Practice

::: exercise warm | Reorder the bar
In `shell.json`, move `"clock"` right after `"logo"` and remove `"activeWindow"`. Save and watch the bar rebuild.
:::

::: exercise practice | Scroll for volume and brightness
Make scrolling over the bar's top half change volume and over the bottom half change brightness (outside the workspaces, which already scroll).
--- solution
In `Bar.qml`:
```qml
WheelHandler {
    onWheel: event => {
        const up = event.angleDelta.y > 0;
        if (point.position.y < root.height / 2) up ? Audio.increment() : Audio.decrement();
        else up ? Brightness.increment() : Brightness.decrement();
    }
}
```
Add `import qs.services`. The workspaces module's own `WheelHandler` takes the event first when the pointer is over it.
:::

::: exercise practice | Numbers or dots
Add `property bool workspaceNumbers` to the bar config. When false, show small dots instead of numbers for inactive workspaces.
:::

::: exercise challenge | A keyboard-layout entry and popout
Add a `"kbLayout"` bar entry that shows the current layout code (see the keyboard-layout widget in [[ch:g1-bar-modules]]) and a popout that lists your configured layouts.
--- hint
Make it a status-icon-like item with `name: "kblayout"`, add a `kblayout` page to the popouts Wrapper, and get the layouts with `hyprctl devices -j`.
:::
