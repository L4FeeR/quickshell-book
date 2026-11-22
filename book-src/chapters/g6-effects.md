# Gallery: Effects, Decorations and Interactions

The polish layer: rounded screen corners, glass, animated borders, hot corners, auto-hide, crossfading wallpapers, ripples. These are the details that make a rice feel finished.

## Rounded Screen Corners

<div class="preview"><svg width="400" height="200" viewBox="0 0 400 200"><rect width="400" height="200" fill="#89b4fa" opacity=".25"/><rect x="40" y="30" width="320" height="140" rx="6" fill="#313244"/><g fill="#000"><path d="M0 0h22a22 22 0 0 0-22 22z"/><path d="M400 0h-22a22 22 0 0 1 22 22z"/><path d="M0 200h22a22 22 0 0 1-22-22z"/><path d="M400 200h-22a22 22 0 0 0 22-22z"/></g></svg></div>

**What it is.** Black rounded corners drawn over the four screen corners, so the screen looks rounded like a phone or laptop panel. They're completely click-through.

**Kind:** its own window (one per screen) · **Needs:** nothing extra

@include galleryshell/effects/ScreenCorners.qml

::: walk
@ 6-8 | Settings
The corner size and color, shared by every corner on every monitor.
@ 10-23 | One corner shape
A square `r × r` with a quarter circle cut out. The path starts at the top-left, goes right along the top edge, then `PathArc` curves back down to the left edge **counter-clockwise** (bulging toward the top-left), then closes. The filled area is the little "triangle with a curved side" that hides the screen's square corner. `strokeWidth: -1` disables the outline.
@ 25-29 | One window per monitor
[[Variants]] creates a copy of the window for each screen in `Quickshell.screens`, and gives it `modelData` (the [[ShellScreen]]). Plug in a monitor and a new copy appears.
@ 30-35 | A fullscreen, invisible, click-through window
Anchored to all four edges = covers the whole screen. Transparent, ignores exclusive zones, and `mask: Region {}` means it receives **no** input: you can click right through it. `Overlay` keeps corners on top of everything, even fullscreen apps.
@ 37-40 | Four rotated corners
The same shape, anchored to each corner and rotated 0°, 90°, 180° and 270°. Rotation happens around the item's center, which for a square is exactly what we need.
:::

**Customize**
- Match your bar color and offset the top corners below the bar for the "bar melts into the screen" look.

::: exercise practice | Only the top corners
Add `property bool bottomCorners: true` and hide the two bottom corners when it's false (useful with a bottom bar).
:::

## Frosted Glass Bar

<div class="preview"><svg width="420" height="120" viewBox="0 0 420 120"><defs><linearGradient id="wp" x1="0" x2="1"><stop offset="0" stop-color="#f38ba8"/><stop offset=".5" stop-color="#cba6f7"/><stop offset="1" stop-color="#89b4fa"/></linearGradient><filter id="bl"><feGaussianBlur stdDeviation="6"/></filter></defs><rect width="420" height="120" fill="url(#wp)" opacity=".7"/><circle cx="90" cy="40" r="30" fill="#f9e2af" opacity=".8"/><circle cx="320" cy="90" r="40" fill="#94e2d5" opacity=".7"/><g filter="url(#bl)"><rect x="20" y="12" width="380" height="40" rx="14" fill="#1e1e2e" opacity=".35"/></g><rect x="20" y="12" width="380" height="40" rx="14" fill="#1e1e2e" opacity=".45" stroke="#ffffff" stroke-opacity=".25"/><text x="40" y="37" fill="#fff" font-size="13">● ● ●</text><text x="210" y="37" fill="#fff" font-size="13" font-weight="700" text-anchor="middle">14:32</text></svg></div>

**What it is.** A translucent bar that blurs the wallpaper and windows behind it, with a thin light border for a glassy edge.

**Kind:** bar window · **Needs:** a compositor with layer blur (Hyprland), or [[BackgroundEffect]] support

@include galleryshell/effects/GlassBar.qml

```ini file="hyprland.conf"
layerrule = blur, quickshell:glass
layerrule = ignorealpha 0.1, quickshell:glass       # don't blur fully transparent pixels around the bar
decoration {
    blur { enabled = true; size = 8; passes = 3; vibrancy = 0.2 }
}
```

::: walk
@ 5-10 | A floating bar with a namespace
A floating bar (margins from the edges) with a transparent window. The namespace `quickshell:glass` is the name the compositor's layer rule targets for blur.
@ 11-12 | Blur through the protocol
`BackgroundEffect.blurRegion` asks the compositor (where it supports the background-effect protocol) to blur behind a region, here the rounded `glass` rectangle. On Hyprland, the `layerrule` below does the same.
@ 14-20 | The glass
A dark color at 45% opacity: enough to tint and keep text readable, transparent enough to show the blurred wallpaper. A 1 px white border at 18% gives the "edge of a glass pane" highlight.
@ 21-28 | Top shine
A second rectangle over the top half with a gradient from 8% white to transparent imitates light reflecting on glass. Subtle, but it's what makes glass look like glass.
:::

::: exercise practice | Glass on hover
Make the bar more opaque (0.8) while hovered so text is easier to read, animating the change.
:::

## Animated Gradient Border

<div class="preview"><svg width="360" height="150" viewBox="0 0 360 150"><defs><linearGradient id="gb" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="360" y2="0"><stop offset="0" stop-color="#cba6f7"/><stop offset=".33" stop-color="#89b4fa"/><stop offset=".66" stop-color="#94e2d5"/><stop offset="1" stop-color="#cba6f7"/><animateTransform attributeName="gradientTransform" type="rotate" from="0 180 75" to="360 180 75" dur="4s" repeatCount="indefinite"/></linearGradient></defs><rect x="30" y="20" width="300" height="110" rx="24" fill="url(#gb)"/><rect x="33" y="23" width="294" height="104" rx="21" fill="#1e1e2e"/><text x="180" y="80" fill="#cdd6f4" font-size="15" font-weight="700" text-anchor="middle">Now Playing</text></svg></div>

**What it is.** A card whose border is a slowly rotating rainbow gradient, an eye-catching frame for a media card or an active panel.

**Kind:** reusable item · **Needs:** nothing extra

@include galleryshell/effects/GradientBorder.qml

Use it: `GradientBorder { width: 300; height: 110; Text { anchors.centerIn: parent; text: "Now Playing"; color: "white" } }`

> [!NOTE] Qt versions before 6.8
> `PathRectangle` needs Qt 6.8. On older Qt, draw the rounded rectangle with `PathLine` + `PathArc` segments, or use a `Rectangle` with a `ConicalGradient` from `Qt5Compat.GraphicalEffects` masked by an `OpacityMask`.

::: walk
@ 4-10 | Properties
Corner radius, border thickness, inner color, the current gradient `angle`, and a default property alias so you can put content inside: `GradientBorder { Text { … } }`.
@ 12 | Rotating forever
The angle loops 0→360 every 4 seconds, only while visible.
@ 14-29 | Gradient-filled shape
A `Shape` filled (not stroked) with a `ConicalGradient`: colors arranged around a center point, like a color wheel. The first and last stops are the same color so there's no seam. `PathRectangle` draws a rounded rectangle (needs Qt 6.8 or newer). Changing `angle` rotates the colors around the center.
@ 30-36 | Cover the middle
A slightly smaller rectangle (inset by `borderWidth`) covers the center with the fill color. Only a thin rim of the gradient stays visible: the "border". Its radius is reduced by the border width so the curves stay parallel.
:::

::: exercise practice | Only on hover
Run the animation and show the gradient only while hovered; otherwise show a plain gray border.
:::

## Hover-Expand Icon Row

<div class="preview"><svg width="380" height="90" viewBox="0 0 380 90"><rect x="30" y="25" width="320" height="40" rx="20" fill="#313244"/><g font-size="11"><rect x="40" y="31" height="28" rx="14" fill="#45475a"><animate attributeName="width" values="28;100;28;28;28" keyTimes="0;.15;.3;.9;1" dur="6s" repeatCount="indefinite"/></rect><text x="48" y="50" fill="#cdd6f4">📶 <tspan opacity="0">Home-5G<animate attributeName="opacity" values="0;1;0;0" keyTimes="0;.15;.3;1" dur="6s" repeatCount="indefinite"/></tspan></text></g></svg></div>

**What it is.** A row of status icons where hovering an icon makes it grow into a pill with a label (Wi-Fi name, volume %, battery %). It's minimal at rest and informative on hover.

**Kind:** bar module · **Needs:** nothing extra (bind labels to your services)

@include galleryshell/effects/ExpandIcon.qml

Use it: `Row { spacing: 2; ExpandIcon { icon: "wifi"; label: "Home-5G" } ExpandIcon { icon: "volume_up"; label: "62%" } ExpandIcon { icon: "battery_5_bar"; label: "81%" } }`

::: walk
@ 3-7 | Properties
An icon, a label, and `open` derived from hover.
@ 9-15 | Collapsed vs open
Collapsed, the item is a 28 px circle showing only the icon, with no background. Open, it's as wide as icon + label, with a background. `clip: true` hides the label while collapsed (it's still there, just outside the visible area). Width and color animate.
@ 17-21 | Left-pinned row
The row starts at `x: 6`, so the icon stays in place and the label is revealed to the right as the width grows.
@ 22-29 | Icon fills, label fades
The icon switches to its filled variant and the label fades in, both tied to `open`.
:::

::: exercise practice | A row of them
Put four in a `Row` (wifi, bluetooth, volume, battery) and make only one expand at a time, even if the mouse moves quickly.
:::

## Hot Corner

<div class="preview"><svg width="400" height="180" viewBox="0 0 400 180"><rect width="400" height="180" fill="#313244" opacity=".4"/><path d="M0 0h40a40 40 0 0 1-40 40z" fill="#cba6f7" opacity=".5"><animate attributeName="opacity" values="0;.6;0" dur="3s" repeatCount="indefinite"/></path><path d="M14 14l12 4-5 2 6 6-2 2-6-6-2 5z" fill="#fff"/><g opacity="0"><animate attributeName="opacity" values="0;0;1;1;0" keyTimes="0;.3;.4;.85;1" dur="3s" repeatCount="indefinite"/><rect x="60" y="30" width="80" height="50" rx="8" fill="#1e1e2e"/><rect x="160" y="30" width="80" height="50" rx="8" fill="#1e1e2e"/><rect x="260" y="30" width="80" height="50" rx="8" fill="#1e1e2e"/><rect x="60" y="100" width="80" height="50" rx="8" fill="#1e1e2e"/><rect x="160" y="100" width="80" height="50" rx="8" fill="#1e1e2e" stroke="#cba6f7" stroke-width="2"/></g></svg></div>

**What it is.** Push the mouse into the top-left corner of the screen and something happens (open the overview, like GNOME), after a short delay so it doesn't trigger by accident.

**Kind:** its own window (one per screen) · **Needs:** nothing extra

@include galleryshell/effects/HotCorner.qml

Use it: `HotCorner { onTriggered: Hyprland.dispatch("hyprexpo:expo toggle") }` or `onTriggered: GlobalStates.toggle("overview")`.

::: walk
@ 5-8 | A reusable trigger
The hot corner only emits `triggered()`. What happens (open the overview, show the desktop…) is up to the code that uses it: `HotCorner { onTriggered: GlobalStates.toggle("overview") }`. `delay` prevents accidental triggers when the pointer just passes by.
@ 10-20 | A tiny window per screen
A 3×3 px transparent window in the top-left corner of each screen. It's too small to see or to get in the way, but the pointer hits it when you slam the mouse into the corner.
@ 22-26 | Hover + timer
When the pointer enters, the timer starts; if it leaves before 250 ms, the timer stops. Only a deliberate stop in the corner fires `triggered()`.
:::

::: exercise practice | All four corners
Add `property string corner: "top-left"` that places the window in any corner.
:::

## Auto-Hide Bar (Edge Reveal)

<div class="preview"><svg width="420" height="150" viewBox="0 0 420 150"><rect width="420" height="150" fill="#45475a" opacity=".3"/><rect x="0" y="0" width="420" height="3" fill="#cba6f7" opacity=".6"/><rect x="10" rx="14" width="400" height="36" fill="#1e1e2e"><animate attributeName="y" values="-40;-40;8;8;-40" keyTimes="0;.25;.35;.8;1" dur="5s" repeatCount="indefinite"/></rect><path d="M200 20l10 6-4 1 3 5-2 1-3-5-3 3z" fill="#fff"><animate attributeName="transform" attributeType="XML" type="translate" values="0 60;0 60;0 0;0 0;0 60" keyTimes="0;.15;.25;.8;1" dur="5s" repeatCount="indefinite"/></path></svg></div>

**What it is.** The bar hides above the screen and slides down when you touch the top edge (or when no window is open), and windows get the full screen while it's hidden.

**Kind:** bar window · **Needs:** nothing extra

@include galleryshell/effects/AutoHideBar.qml

::: walk
@ 5-9 | When to show
Revealed when hovered, when no window is focused (empty desktop), or when `pinned` (set it while a popup from the bar is open, so the bar doesn't hide under your menu).
@ 11-14 | Overlay instead of reserve
`exclusiveZone: 0`: windows use the full screen height. The window is 10 px taller than the bar to leave room for the floating margin.
@ 16-19 | Smart input mask
When hidden, only a 3 px strip at the top edge catches the mouse (`trigger`); when shown, the whole bar does. Without this, an invisible bar-sized area would block clicks on your windows' title bars.
@ 21-24 | Hide delay
Showing is instant, hiding waits 400 ms. If the pointer leaves for a moment (overshooting the edge), the bar doesn't flicker.
@ 26-34 | Sliding content
The bar's `y` is 6 when shown and above the screen when hidden; a `Behavior` animates the slide.
:::

**Customize**
- Reserve space only while revealed: `exclusiveZone: shown ? barHeight + 6 : 0` (windows will resize as it moves).
- Reveal on a keybind: an [[IpcHandler]] that sets `pinned`.

::: exercise practice | Keybind peek
Add an IPC function that pins the bar open for 3 seconds (`pinned = true`, then a timer sets it back).
:::

## Wallpaper Slideshow with Crossfade

<div class="preview"><svg width="400" height="170" viewBox="0 0 400 170"><defs><linearGradient id="w1" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f38ba8"/><stop offset="1" stop-color="#fab387"/></linearGradient><linearGradient id="w2" x1="1" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#89b4fa"/><stop offset="1" stop-color="#94e2d5"/></linearGradient></defs><rect width="400" height="170" fill="url(#w1)"/><rect width="400" height="170" fill="url(#w2)"><animate attributeName="opacity" values="0;0;1;1;0" keyTimes="0;.35;.5;.85;1" dur="6s" repeatCount="indefinite"/></rect><circle cx="300" cy="60" r="28" fill="#fff" opacity=".25"/></svg></div>

**What it is.** Quickshell draws the wallpaper itself and changes it every N minutes from a folder, crossfading between images. No swww or hyprpaper needed.

**Kind:** its own window (one per screen) · **Needs:** a folder of images

@include galleryshell/effects/Slideshow.qml

```bash
qs -c gallery ipc call slideshow next
```

::: walk
@ 6-12 | State
The wallpaper folder, the interval, the shuffled file list, and an ever-increasing `index`. `current` wraps the index with `%` and adds `file://`.
@ 14-18 | Listing images
`find` lists jpg/png/webp files in the folder (not subfolders), and `shuf` shuffles them. The folder is passed as `$1` instead of being pasted into the script, so paths with spaces or quotes are safe.
@ 19-20 | Advancing
A timer bumps `index` every 15 minutes (only if there's more than one image), and IPC `next()` skips manually.
@ 22-31 | Background window per screen
A fullscreen window on the `Background` layer: under everything, like a normal wallpaper.
@ 33-37 | Two images, one hidden
`aOnTop` says which image is visible. When `current` changes, the new file is loaded into the **hidden** image, so the old wallpaper stays on screen while the new one decodes.
@ 38-44 | Shared image settings
`sourceSize` decodes at the screen's real pixel size (logical size × scale), never the full file size: a 6K wallpaper doesn't need 100 MB of memory. `cache: false` because each wallpaper is shown once in a while. Opacity changes fade over 1.2 s.
@ 45-46 | Swap when ready
When the hidden image finishes loading **and** it holds the current file, it becomes the top one. The opacities swap and both `Behavior`s run: a crossfade.
@ 47 | First wallpaper
Loads the first image into `a` on startup.
:::

**Customize**
- Re-theme on every change: run your matugen script ([[ch:44-theming]]) in `onCurrentChanged`.

::: exercise practice | Pause when on battery
Stop the slideshow timer while on battery (`UPower.onBattery`).
:::

## Click Ripple

<div class="preview"><svg width="300" height="120" viewBox="0 0 300 120"><rect x="60" y="30" width="180" height="60" rx="18" fill="#313244"/><clipPath id="cp"><rect x="60" y="30" width="180" height="60" rx="18"/></clipPath><g clip-path="url(#cp)"><circle cx="120" cy="58" fill="#cdd6f4"><animate attributeName="r" values="0;110" dur="1.6s" repeatCount="indefinite"/><animate attributeName="opacity" values=".35;0" dur="1.6s" repeatCount="indefinite"/></circle></g><text x="150" y="65" fill="#cdd6f4" font-size="14" font-weight="700" text-anchor="middle">Click me</text></svg></div>

**What it is.** A Material-style ripple that spreads from exactly where you clicked inside a button.

**Kind:** reusable item · **Needs:** nothing extra

@include galleryshell/effects/RippleButton.qml

> [!TIP] Rounded clipping
> `clip: true` clips to a rectangle, so the ripple may show in the corners of a very round button. Wrap the content in a [[ClippingRectangle]] for perfectly rounded clipping.

::: walk
@ 3-11 | The button
A rounded rectangle with a label. `clip: true` keeps the ripple inside the button's box. (The clip is rectangular, so on very round buttons the ripple corners can show; wrap in a `ClippingRectangle` for an exact rounded clip.)
@ 13-20 | The ripple circle
A circle that starts at width 0 and is centered on `cx, cy` (the click position).
@ 21-25 | The spread animation
Width grows to twice the button's diagonal (big enough to cover it from any point) while the opacity fades from 30% to 0.
@ 28-35 | Start at the click point
`point.position` is where you tapped inside the button. The ripple is moved there, the animation restarts, and the `clicked` signal fires.
:::

::: exercise practice | Hold to keep
Keep the ripple visible (at 20%) while the button is held down, and fade it out on release.
:::

## Hide Bar on Fullscreen

<div class="preview"><svg width="400" height="160" viewBox="0 0 400 160"><rect width="400" height="160" fill="#45475a" opacity=".3"/><rect x="10" width="380" height="30" rx="10" fill="#1e1e2e"><animate attributeName="y" values="8;8;-40;-40;8" keyTimes="0;.3;.4;.8;1" dur="5s" repeatCount="indefinite"/></rect><rect fill="#11111b"><animate attributeName="x" values="10;10;0;0;10" keyTimes="0;.3;.4;.8;1" dur="5s" repeatCount="indefinite"/><animate attributeName="y" values="46;46;0;0;46" keyTimes="0;.3;.4;.8;1" dur="5s" repeatCount="indefinite"/><animate attributeName="width" values="380;380;400;400;380" keyTimes="0;.3;.4;.8;1" dur="5s" repeatCount="indefinite"/><animate attributeName="height" values="106;106;160;160;106" keyTimes="0;.3;.4;.8;1" dur="5s" repeatCount="indefinite"/></rect><text x="200" y="100" fill="#cdd6f4" font-size="14" text-anchor="middle">▶ video</text></svg></div>

**What it is.** When the focused window on a monitor goes fullscreen (videos, games), that monitor's bar slides away; it returns when you leave fullscreen.

**Kind:** behavior for your bar · **Needs:** any compositor with foreign-toplevel (Hyprland shown as alternative)

@include galleryshell/effects/FullscreenAwareBar.qml

::: walk
@ 6-11 | One bar per screen
`Variants` again, because fullscreen state is per monitor: a fullscreen video on one screen shouldn't hide the bar on the other.
@ 12-14 | Fullscreen detection
Checks all windows for one that is fullscreen **and** on this screen. A Hyprland-specific alternative is in the comment.
@ 16-20 | Get out of the way
`exclusiveZone` drops to 0 so the fullscreen app isn't squeezed, and the window stays visible only while the slide-out animation runs.
@ 22-28 | Slide up
The bar moves above the screen edge when fullscreen, and back down when the app leaves fullscreen.
:::

::: exercise practice | Peek while fullscreen
While fullscreen, let the bar slide down when the pointer touches the top edge (combine with the auto-hide trigger strip).
:::

## Rainbow Active Workspace

<div class="preview"><svg width="320" height="70" viewBox="0 0 320 70"><defs><linearGradient id="rb" x1="0" x2="1"><stop offset="0" stop-color="#f38ba8"/><stop offset=".25" stop-color="#fab387"/><stop offset=".5" stop-color="#a6e3a1"/><stop offset=".75" stop-color="#89b4fa"/><stop offset="1" stop-color="#cba6f7"/><animate attributeName="x1" values="0;-1;0" dur="3s" repeatCount="indefinite"/><animate attributeName="x2" values="1;2;1" dur="3s" repeatCount="indefinite"/></linearGradient></defs><rect x="30" y="20" width="260" height="30" rx="15" fill="#313244"/><rect x="50" y="29" width="40" height="12" rx="6" fill="url(#rb)"/><g fill="#585b70"><circle cx="110" cy="35" r="4"/><circle cx="130" cy="35" r="4"/><circle cx="150" cy="35" r="4"/><circle cx="170" cy="35" r="4"/></g></svg></div>

**What it is.** The active-workspace pill filled with a slowly shifting rainbow gradient, a fun twist on the standard indicator.

**Kind:** bar module piece · **Needs:** nothing extra (combine with Workspace Dots)

@include galleryshell/effects/RainbowPill.qml

Replace the sliding pill's `color: "#cba6f7"` in [[ch:g1-bar-modules|Workspace Dots]] with this component.

::: walk
@ 3-7 | The pill and its phase
A small pill. `shift` loops from 0 to 1 every 3 seconds, only while visible.
@ 8-13 | Three moving hues
Each gradient stop computes its color with `Qt.hsla(hue, saturation, lightness, alpha)`. The hues are `shift`, `shift + 0.33` and `shift + 0.66` (one third of the color wheel apart), wrapped with `% 1`. As `shift` grows, all three hues rotate together, so the rainbow flows along the pill. Saturation and lightness stay fixed, so the colors keep a consistent pastel feel.
:::

::: exercise practice | Use your accent
Instead of a full rainbow, vary only the lightness of your accent color (`Qt.hsla(accent.hslHue, …)`), for a subtle shimmer.
:::
