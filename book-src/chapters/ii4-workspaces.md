# end-4 4: The Workspace Indicator

ii's workspace indicator packs a lot into 26-pixel cells: occupied workspaces share **one continuous background**, the active workspace has a pill that **trails** as it moves, and each workspace shows the **icon of its biggest window**. Hold Super and the icons turn into numbers. It's worth a chapter of its own because each layer uses a technique you'll reuse elsewhere.

<div class="preview"><svg width="620" height="200" viewBox="0 0 620 200"><g font-size="11"><g transform="translate(20 14)"><text y="0" fill="#cdd6f4">1. occupied backgrounds (2, 3 and 6 have windows)</text><rect x="0" y="10" width="260" height="26" rx="13" fill="#1d1b20"/><rect x="26" y="10" width="52" height="26" rx="13" fill="#4a4458" opacity=".6"/><rect x="130" y="10" width="26" height="26" rx="13" fill="#4a4458" opacity=".6"/><g fill="#585b70" font-size="9"><text x="13" y="52" text-anchor="middle">1</text><text x="39" y="52" text-anchor="middle">2</text><text x="65" y="52" text-anchor="middle">3</text><text x="91" y="52" text-anchor="middle">4</text><text x="117" y="52" text-anchor="middle">5</text><text x="143" y="52" text-anchor="middle">6</text></g></g><g transform="translate(320 14)"><text y="0" fill="#cdd6f4">how 2 and 3 merge: each stretches half a cell</text><rect x="26" y="12" width="39" height="22" rx="11" fill="#f9e2af" opacity=".5"/><rect x="39" y="12" width="39" height="22" rx="11" fill="#89b4fa" opacity=".5"/><text x="120" y="28" fill="#a6adc8">yellow = 2, blue = 3</text></g><g transform="translate(20 90)"><text y="0" fill="#cdd6f4">2. the active pill trails: moving from 2 to 5</text><g transform="translate(0 10)"><rect width="260" height="26" rx="13" fill="#1d1b20"/><rect x="28" y="2" width="22" height="22" rx="11" fill="#d0bcff"/><text x="275" y="17" fill="#a6adc8">t = 0</text></g><g transform="translate(0 42)"><rect width="260" height="26" rx="13" fill="#1d1b20"/><rect x="40" y="2" width="70" height="22" rx="11" fill="#d0bcff"/><text x="275" y="17" fill="#a6adc8">front edge (right) moves fast, back edge slow</text></g><g transform="translate(0 74)"><rect width="260" height="26" rx="13" fill="#1d1b20"/><rect x="106" y="2" width="22" height="22" rx="11" fill="#d0bcff"/><text x="275" y="17" fill="#a6adc8">both arrive</text></g></g></g></svg></div>

@include impulse/modules/bar/Workspaces.qml

## How it works

::: walk
@ 18-23 | Groups of ten
`shown` workspaces form a group (10 by default): 1–10, 11–20… `group` is the current group number and `activeIndex` the active workspace's position inside it. All the drawing uses positions inside the group, so moving to workspace 13 shows 11–20 with the pill on the third cell.
@ 25-30 | Looking up workspaces
`wsAt(i)` finds the Hyprland workspace for cell `i`. `occupied(i)` also returns false for positions outside the group, which keeps the neighbour checks below simple at both ends.
@ 35-45 | Occupied: stretch toward neighbours
Each cell draws a pill described by a left and a right edge. An occupied cell normally covers its own 26 px. If its **left neighbour is occupied too**, its left edge moves half a cell further left; same on the right. Two neighbouring pills then overlap by a whole cell, and because they're rounded pills of the same colour, the overlap looks like one long pill. An empty cell collapses to zero width at its centre.
@ 47-54 | Animated edges
The edges have `Behavior`s, so when a workspace becomes occupied its pill **grows out of its centre and reaches toward** its neighbours, and when it empties, the joined pill smoothly splits. The colour is the secondary container at 60%, a soft tint.
@ 59-71 | The active pill: two edges
Like the occupied pills, the active indicator is defined by two edges. When the target changes, the code records the direction (`movingRight`) and sets both edges to the new place.
@ 73-78 | Drawn from the edges
`x` is the left edge and `width` the distance between the edges, so animating the edges separately stretches and shrinks the pill.
@ 80-85 | Different speeds = a trail
Moving right, the **right** edge (the front) animates in 250 ms and the left edge (the back) in 500 ms; moving left, the opposite. The pill stretches toward the new workspace, then its tail catches up. Same idea as Caelestia's active trail, horizontal.
@ 89-109 | The top layer: one cell per workspace
A `Row` of cells sits on top of both backgrounds. `biggest` finds the workspace's largest window by area, using the size Hyprland reports in `lastIpcObject.size`. That's the window whose icon represents the workspace.
@ 106 | Icon or number?
Show the icon when the option is on, the workspace has a window, and Super isn't held.
@ 111-119 | The number
Fades out when the icon is shown. Its colour follows the layer underneath: on-primary on the active pill, on-secondary-container on occupied pills, faint otherwise.
@ 121-128 | The icon
The window's class is matched to an installed app for the icon. Both the size and opacity animate, so holding Super makes every icon **shrink away** while the numbers fade in.
@ 130-138 | Clicks
Left click switches to the workspace; right click toggles the overview ([[ch:ii6-overview]]), exactly like the original.
@ 143-145 | Scroll
Scrolling moves between workspaces.
:::

## How the original does it differently

The original (`modules/ii/bar/Workspaces.qml`, ~400 lines) uses the same "over-stretch toward occupied neighbours" idea, but goes further with **masks**:

1. It draws the occupied pills into an invisible layer and uses a `MaskMultiEffect` to show one solid background **through** that mask. Overlaps can never look darker, even with transparency.
2. It draws the numbers once in the normal colour, then uses a **colorizer with a mask**: wherever the active pill covers a number, that part of the number is recoloured to on-primary. When the pill slides halfway across a number, the number is literally half one colour and half the other.
3. A second "interaction" indicator follows the hovered cell, using the same trailing animation.
4. When a special workspace (scratchpad) is open, the regular workspaces blur and shrink slightly behind it.

These are great next steps once the rebuild's version makes sense; the [[ch:25-effects]] chapter covers `MultiEffect` masks.

> [!TIP] Reuse the trick
> "Describe a shape by its edges and animate the edges separately" works for any moving indicator: tab underlines, segmented buttons, list selections. One edge leads, the other follows.

## Practice

::: exercise warm | Five per group
Set `bar.workspaces.shown` to 5 in `config.json` and move between workspaces 1–10. What happens at workspace 6?
--- solution
The indicator switches to the second group (6–10). Everything is computed from `group` and `activeIndex`, so nothing else changes.
:::

::: exercise practice | Hover indicator
Add a second, transparent pill with a 10% primary tint that follows the hovered cell (use a `HoverHandler` on the root and compute the cell from `point.position.x`).
:::

::: exercise practice | Urgent workspaces
Colour a workspace's background red when it's urgent (`HyprlandWorkspace.urgent`).
:::

::: exercise challenge | Masked number colours
Implement the original's colorizer: render the numbers in a layer, then use a `MultiEffect` with `maskSource` set to the active pill so only the covered part of each number turns on-primary.
--- hint
Put the active pill in an item with `layer.enabled: true` and `visible: false`; draw the numbers twice (normal colour and on-primary); show the on-primary copy through a `MultiEffect { maskEnabled: true; maskSource: pillLayer }`.
:::
