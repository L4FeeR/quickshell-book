# Animations: Ripples, Stretch and Snow

Three effects ricers ask for again and again: a **ripple** that spreads from where you click or type, a **squash-and-stretch** "jelly" press, and **snow** falling over the desktop. This chapter builds each as a small reusable component, then shows every place you can use them: buttons, password and search fields, tabs, shell events like a volume change, and the desktop itself.

<div class="preview"><svg width="640" height="300" viewBox="0 0 640 300"><rect width="640" height="300" rx="14" fill="#1a1b26"/><g><rect x="30" y="30" width="150" height="48" rx="14" fill="#24283b"/><circle cx="80" cy="54" r="10" fill="#7aa2f7" opacity=".4"><animate attributeName="r" values="0;90" dur="1.4s" repeatCount="indefinite"/><animate attributeName="opacity" values=".45;0" dur="1.4s" repeatCount="indefinite"/></circle><text x="105" y="59" fill="#c0caf5" font-size="15" text-anchor="middle">Ripple</text></g><g transform="translate(270 54)"><rect x="-70" y="-24" width="140" height="48" rx="24" fill="#7aa2f7"><animateTransform attributeName="transform" type="scale" values="1 1;1.12 0.88;0.96 1.05;1.02 0.98;1 1" keyTimes="0;.2;.45;.7;1" dur="1.4s" repeatCount="indefinite"/></rect><text y="5" fill="#1a1b26" font-size="15" font-weight="700" text-anchor="middle">Jelly</text></g><rect x="160" y="130" width="320" height="50" rx="25" fill="#16161e" stroke="#7aa2f7" stroke-width="2"/><g fill="#c0caf5"><circle cx="190" cy="155" r="5"/><circle cx="206" cy="155" r="5"/><circle cx="222" cy="155" r="5"/></g><circle cx="232" cy="155" r="10" fill="#7aa2f7" opacity=".45"><animate attributeName="r" values="0;45" dur="0.7s" repeatCount="indefinite"/><animate attributeName="opacity" values=".5;0" dur="0.7s" repeatCount="indefinite"/></circle><text x="320" y="210" fill="#a9b1d6" font-size="11" text-anchor="middle">a ripple from the caret on every key</text><g fill="#fff"><circle cx="40" cy="240" r="3"><animate attributeName="cy" values="200;300" dur="4s" repeatCount="indefinite"/></circle><circle cx="120" cy="250" r="2.5" opacity=".7"><animate attributeName="cy" values="190;300" dur="5s" repeatCount="indefinite"/></circle><circle cx="540" cy="230" r="3.5"><animate attributeName="cy" values="180;300" dur="4.5s" repeatCount="indefinite"/></circle><circle cx="600" cy="260" r="2.5" opacity=".6"><animate attributeName="cy" values="200;300" dur="3.5s" repeatCount="indefinite"/></circle><circle cx="470" cy="240" r="2" opacity=".8"><animate attributeName="cy" values="170;300" dur="6s" repeatCount="indefinite"/></circle></g></svg></div>

The code is in `examples/ripples/`, a runnable Quickshell config with a showcase window (`qs -p examples/ripples`; the demo password is `secret`). The components use only Qt Quick, so they also work outside Quickshell, for example in an SDDM theme ([[ch:d10-sddm]]).

## One ripple

@include ripples/components/Ripple.qml

::: walk
@ 8-14 | Settings
Where it starts, how big it ends, how long it takes, how visible it starts, filled or a ring, and its colour.
@ 16-26 | Shape and start
A circle the full end size, centred on the start point, but **scaled to 0**: scaling instead of resizing is cheaper (the GPU just draws it bigger) and keeps it perfectly round. A ring is a transparent circle with a border.
@ 27-33 | Grow, fade, vanish
Scale from 0 to 1 with `OutCubic` (fast at first, then slowing, like a real wave) while the opacity falls to 0 with `InQuad` (slowly at first, then fast). When both finish, the ripple destroys itself, so nothing piles up.
:::

## A layer to spawn them

@include ripples/components/RippleLayer.qml

::: walk
@ 3-9 | Usage
Put a layer over (or under) any content and call `burst(x, y)` with optional overrides.
@ 13-17 | Defaults
Every ripple gets these unless a call overrides them. `maxRipples` caps the number alive at once: fast typing could otherwise create hundreds.
@ 19 | The template
A `Component` wrapping `Ripple`, ready to be instantiated.
@ 21-34 | burst()
If the layer is full, destroy the oldest ripple. Then create a new one as a child of the layer, with the given position and each option, falling back to the defaults with `??`.
@ 36-40 | flood()
A ripple from the centre big enough to cover the whole layer (twice its diagonal), for full-area effects like a failure shockwave.
:::

## Click ripples on anything

@include ripples/components/ClickRipple.qml

::: walk
@ 4-8 | Usage
Drop it inside any item, give it the item's corner radius, and it handles clicks, hover and ripples. `clicked` passes the click on.
@ 19-41 | Clipped to the rounded shape
A plain `clip: true` would cut the ripple at the item's square box, so it would show in the rounded-off corners. Instead, the ripples are drawn in a layer and **masked** by a rounded rectangle with [[MultiEffect]]'s `maskEnabled`: they're only visible inside the exact shape. The same layer holds a faint hover highlight.
@ 35-40 | Big enough
The ripple's end size is 2.2 times the item's diagonal, so a ripple from any point reaches the farthest corner.
@ 42-48 | The mask shape
A rounded rectangle the size of the item, invisible itself, rendered into a texture (`layer.enabled`) for the mask to use.
@ 50-57 | Input
Press spawns the ripple at the pointer (at **press**, not release, so it responds instantly); click passes the event on.
:::

```qml
Rectangle {
    radius: 14; color: "#24283b"; implicitWidth: 140; implicitHeight: 48
    Text { anchors.centerIn: parent; text: "Save"; color: "#c0caf5" }
    ClickRipple { radius: 14; tint: "#7aa2f7"; onClicked: save() }
}
```

## Ripples for typing

@include ripples/components/TypingRipple.qml

::: walk
@ 3-10 | Usage
Attach it to a text field. It fills its own area with a ripple layer, so place it where ripples may spread (around the field rather than inside it).
@ 14-21 | Settings
The field, a colour for typing and one for deleting, the ripple size, and an optional set of colours to pick from at random for each key.
@ 25-29 | Where the caret is
`cursorRectangle` is the caret's box in the field's coordinates; `mapToItem` converts its centre to this item's coordinates.
@ 31-42 | One tick later
A subtle trap: inside `textChanged`, Qt hasn't laid out the new text yet, so `cursorRectangle` is still the **old**, even empty, rectangle (it read `QRectF(0, 0, 0, 0)` when tested). The ripple would appear at the field's corner. `Qt.callLater` runs `_typed` after the current event, when the caret has moved. Typing sends a filled ripple; deleting a smaller ring in another colour.
@ 44-56 | Watching the field
Compare the new length with the last one to know whether a character was added or removed. Enter (`accepted`) sends a big ring.
@ 58-62 | The shockwave
`shake()` floods the area with a red ring and a faint red wash at once: the feedback for a wrong password.
:::

## Squash and stretch

@include ripples/components/Stretch.qml

::: walk
@ 3-8 | What it does
Pressing squashes the item wider and flatter; releasing makes it overshoot and wobble back, like jelly. `poke()` does both at once, for keys and events.
@ 12-15 | Settings
The item to deform (its parent by default), how much (12%), and whether it handles the mouse itself.
@ 19-28 | Two scales
A `Scale` transform with separate x and y factors, centred on the item. Making x bigger while y gets smaller keeps the area about the same, which is what makes it look soft rather than just smaller. It's attached to the item as its transform.
@ 30-44 | press, release, poke
`poke` jumps straight to a squashed shape (with an adjustable strength) and starts the spring.
@ 46-51 | The squash
A quick 90 ms ease into the squashed shape.
@ 52-57 | The spring
Back to 1 with **`OutElastic`**: it overshoots past the normal size and oscillates a few times before resting. `amplitude` sets how far it overshoots, `period` how fast it wobbles.
@ 59-67 | Mouse
With `handleMouse`, it presses and releases itself.
:::

@include ripples/components/StretchPill.qml

The elastic tab or workspace pill from [[ch:ly5-bar]], as a general component: point `target` at any item in the same parent and the pill slides to it with its leading edge fast and its trailing edge slow, so it stretches across and snaps back.

## Snow

@include ripples/components/Snow.qml

::: walk
@ 12-15 | Settings
How much snow (0 off, 1 steady, 3 a blizzard), the wind, the colour, and whether it's running.
@ 17-20 | A particle system
Qt's `QtQuick.Particles` simulates thousands of small particles efficiently. The system ties the pieces below together.
@ 22-33 | A flake
Each particle is drawn by this delegate: a round dot with a random size and opacity, so the snow has depth.
@ 35-46 | Steady snow
An emitter along the top edge, just above the screen, releasing flakes that fall downward (angle 90°) with a little spread and varying speed, living long enough to cross the screen. The rate scales with the width, so a wide monitor gets the same density.
@ 48-57 | Puffs
A second emitter that's normally off. `burst()` fires it once from a point, throwing flakes in every direction.
@ 59-63 | Forces
Wind is a sideways gravity on everything; real gravity pulls the puffs back down; `Wander` makes the falling flakes drift left and right like real snow.
@ 66-69 | burst()
A puff of flakes from a point.
:::

## Where to use them

The demo shell puts all of it together:

@include ripples/shell.qml

Here is every use, and how it's wired:

| Where | How |
|---|---|
| **Buttons** of any shape | `ClickRipple { radius: … }` inside the button |
| **Jelly buttons** | `Stretch { handleMouse: true }` inside it |
| **Tabs, workspaces** | `StretchPill { target: currentTab }` behind the row |
| **Password field** (lock screen, SDDM, polkit) | `TypingRipple { target: field }` around it; on a wrong password `typing.shake()` and `jelly.poke(1.4)` |
| **Search fields** (launcher, clipboard) | `TypingRipple { randomTints: true }` for a colour per key; plus `Snow.burst()` from the caret |
| **Correct password** | a celebration: several snow puffs across the window |
| **Shell events** | a `RippleLayer` that bursts from a `Connections`: here on every volume change (an OSD with a pulse); the same works for a notification arriving, a workspace switch or a charger plugged in |
| **Scripts and keybinds** | an `IpcHandler` that calls `burst()`: `qs -p examples/ripples ipc call ripple at 180 180` |
| **The desktop** | `Snow` in a full-screen window on the bottom layer with an empty input mask: snow on the wallpaper, behind your windows, never taking clicks |
| **Over everything** | the same window on the overlay layer: snow (or ripples) over your windows, still click-through |

To use them in your own shell, copy `examples/ripples/components/` into your config (for example as `components/effects/`) and import it.

> [!NOTE] Ripples for keys typed into other apps?
> On Wayland, a shell only receives keys typed into **its own** windows; keys typed into your terminal or browser go only to them. That's a security feature: no program can watch what you type elsewhere. So typing ripples belong in the shell's own fields: the lock screen, launcher, search and login screen. (Reading raw keyboard devices would need special permissions and amounts to a keylogger, so don't.)

## Performance

- Ripples cost nothing at rest: they exist only while animating, and the cap stops them piling up.
- Snow runs continuously. In a full-screen window, 40 flakes a second is light, but turn it off on battery or when a window is fullscreen (`running: !UPower.onBattery`), as the video wallpaper does in [[ch:e5-more]].
- Masked layers (`ClickRipple`) render the button into a texture; that's fine for buttons, but don't wrap huge panels in one.

::: exercise warm | Your colours
Give your bar's buttons a `ClickRipple` in your accent colour, and your launcher's search field a `TypingRipple`.
:::

::: exercise practice | Ripple on notification
Burst a ring from the bell icon every time a notification arrives (`Connections` on your notification service, [[ch:ly8-notifications-osd]]).
:::

::: exercise practice | Seasonal snow
Turn snow on automatically in December only, and off on battery.
--- hint
`Snow { running: new Date().getMonth() === 11 && !UPower.onBattery }`, re-checked by a `SystemClock` binding once a day.
:::

::: exercise challenge | Sakura
Make a petal version of `Snow`: pink, slightly larger, rotating slowly as it falls (`ItemParticle` delegates can animate their own `rotation`), with more wind.
:::
