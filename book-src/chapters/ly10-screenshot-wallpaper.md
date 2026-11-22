# lyne-dots 10: Screenshots and Wallpapers

Two tools that make a rice feel complete: lyne's **screenshot overlay** (press Print, pick a region, a window or a whole screen) and its **wallpaper library**, drawn by the shell itself with a crossfade and chosen from a carousel.

<div class="preview"><svg width="620" height="260" viewBox="0 0 620 260"><rect width="620" height="260" fill="#414868"/><rect x="40" y="30" width="200" height="120" rx="6" fill="#7aa2f7" opacity=".6"/><rect x="290" y="80" width="280" height="150" rx="6" fill="#9ece6a" opacity=".5"/><path d="M0 0H620V260H0Z M150 60V170H400V60Z" fill="#000" opacity=".55" fill-rule="evenodd"/><rect x="150" y="60" width="250" height="110" fill="none" stroke="#7aa2f7" stroke-width="2"/><rect x="330" y="176" width="70" height="20" rx="5" fill="#1a1b26"/><text x="365" y="190" fill="#c0caf5" font-size="10" text-anchor="middle">250 × 110</text><rect x="170" y="206" width="280" height="40" rx="20" fill="#1a1b26" opacity=".95"/><g font-size="11"><rect x="178" y="212" width="66" height="28" rx="14" fill="#292e42"/><text x="188" y="230" fill="#7aa2f7">⬚ Region</text><text x="256" y="230" fill="#c0caf5">▢ Window</text><text x="322" y="230" fill="#c0caf5">⛶ Screen</text><text x="390" y="230" fill="#7aa2f7">📷 Capture</text></g></svg></div>

## Screenshots

@include lyne/modules/screenshot/ScreenshotOverlay.qml

::: walk
@ 18-22 | State
Whether the overlay is up, the mode, and the selection as a rectangle in **global** coordinates (across all monitors, as grim expects). Anything smaller than 2 px doesn't count as a selection.
@ 24-25 | Starting and cancelling
`start()` is called by the Print shortcut in `shell.qml`; it always begins in region mode with nothing selected.
@ 27-36 | Capturing
Close the overlay first, then, a quarter second later (once it's gone from the screen), grab exactly that area with `grim -g "X,Y WxH"`, save it in your Pictures folder with the date in its name, copy it to the clipboard, and show a notification with the picture as its icon. The geometry goes to `sh` as an argument.
@ 38-49 | Which window is under the pointer?
Hyprland knows every window's position (`at`) and size. Look through the windows on the focused workspace for the one containing the point.
@ 51-67 | An overlay on every screen
While active, one fullscreen window per monitor, so you can select on any of them. Only the focused monitor's window takes the keyboard. `local` is the selection converted to this window's coordinates: global minus the screen's position.
@ 69-70 | Fresh window positions
Ask Hyprland for the current window list when the overlay opens.
@ 72-81 | Dimming around the selection
Before anything is selected, one rectangle dims the whole screen. With a selection, four rectangles dim above, below, left and right of it, leaving the selection clear. The edges are clamped to the window, so a selection on another monitor doesn't draw outside this one.
@ 83-106 | The outline and size
An accent frame and a size label. In window and screen modes the frame **glides** from one window to the next as you move the pointer; in region mode it follows the drag directly.
@ 108-130 | The mouse
Region: press to start, drag to grow (global coordinates, so a drag can cross monitors). Window: hovering selects the window under the pointer. Screen: hovering selects this monitor. In those two modes a click captures.
@ 132-151 | The control bar's keys
R, W and S switch mode; Enter captures; Escape cancels.
@ 152-178 | The buttons
Three mode buttons and a Capture button that's dimmed until something is selected.
:::

> [!NOTE] In the original
> lyne's screenshot tool first **freezes** the screen (a grim capture shown fullscreen, with the dimming done by a shader), so a menu or tooltip stays in the picture. It also has a colour picker with a magnifier, OCR ("copy text" through tesseract), editing in satty, guides, and settings for the folder, file name and default action.

## The wallpaper library

@include lyne/services/WallpaperService.qml

::: walk
@ 12-15 | Folder, current, files
The folder and the current wallpaper are settings (`~` is expanded to your home). `files` is every image found there.
@ 17 | Choosing
Setting `wallpaper.current` is all it takes: the background follows (below) and the choice is saved.
@ 19-22 | The picker
Toggled like every popup; opening rescans the folder so new images show up.
@ 24-30 | Finding images
`find` lists jpg, jpeg, png and webp files in the folder and its sub-folders, sorted. The folder is an argument, so spaces in its name are fine.
@ 38-43 | From scripts
`qs -c lyne ipc call wallpaper set ~/Pictures/wall.jpg` (a wallpaper rotator can use this), `… get`, `… picker`.
:::

## Drawing the wallpaper

@include lyne/modules/wallpaper/Background.qml

::: walk
@ 9-19 | One window per screen
On the **background** layer, below every window and below desktop widgets, covering the whole screen. The background colour shows until an image loads.
@ 22-30 | Two images
The `Layer` component is an image that fills the screen and fades its opacity. `sourceSize` makes Qt decode a 6000-pixel photo at screen size: much less memory and a faster load.
@ 31-40 | Taking turns
Whichever image finishes loading becomes the visible one, and the other fades out.
@ 42-45 | Loading into the hidden one
The first wallpaper goes into `a`. After that, each new file goes into the image that's hidden, and when it's ready it fades in over the old one: a crossfade with no flash of the background colour.
@ 46-50 | Following the setting
Load the current wallpaper at startup and every time it changes.
:::

## The picker

@include lyne/modules/wallpaper/WallpaperPicker.qml

::: walk
@ 13-25 | A strip at the bottom
On the focused screen, full width, 230 px tall. It takes the keyboard while open; clicking elsewhere closes it.
@ 34-38 | Empty folder
A message saying which folder it looked in.
@ 41-55 | A centred carousel
A horizontal `ListView`. `StrictlyEnforceRange` with a highlight range in the middle keeps the selected thumbnail centred: moving the selection scrolls the strip. It starts on the current wallpaper.
@ 57-59 | Keys and wheel
Left and right move (the list handles those itself), Enter applies, Escape closes, the wheel moves too.
@ 61-81 | A tile
300 px wide. The selected one is full size with an accent border; the others shrink to 82% and fade a little. Both animate.
@ 82-89 | Thumbnails
Each image is decoded at 640 × 360, small and quick, even when the files are huge.
@ 90-100 | In use
A check mark on the current wallpaper.
@ 102-106 | Clicks
A click on a side tile selects it; a click on the selected tile applies it.
:::

> [!NOTE] In the original
> lyne's picker loops endlessly, has favourites and **per-theme wallpapers**: each theme can bring its own wallpaper, and a generator (`.data/wallpapers/generator/generate.py`) renders contour-line wallpapers in any theme's colours. It can also play **video** wallpapers, paused by rules (on battery, when a window is fullscreen).

## Practice

::: exercise warm | Fill your library
Put a few images in `~/.local/wallpapers`, press Super+B (or `qs -c lyne ipc call wallpaper picker`) and switch between them.
:::

::: exercise practice | Copy only
Add a setting `screenshot.action` with "save" (save and copy) or "copy" (clipboard only, using `grim -g "$1" - | wl-copy`), and use it in `capture()`.
:::

::: exercise practice | A wallpaper for each theme
Add an optional `"wallpaper": "…"` field to theme files. When the theme changes and the field is set, switch to that wallpaper.
--- hint
In `ThemeService`'s `onCurrentChanged`, call `WallpaperService.set(…)` when `current.wallpaper` is set. lyne's themes do exactly this (`"wallpaper": "themes/tokyonight/…"`, relative to `~/.local/wallpapers`).
:::

::: exercise challenge | A slideshow
Add `wallpaper.slideshow` (minutes, 0 = off): a `Timer` in the service that moves to the next file in `files` at that interval.
:::
