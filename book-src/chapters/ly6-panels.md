# lyne-dots 6: Panels That Grow Out of the Bar

Click the clock and the dashboard doesn't just appear: it **slides out from under the bar**, its top corners curve into the bar's edge, and the bar and panel look like one surface. The Quick Settings panel and the notification history do the same. This chapter builds that effect once, as two reusable components, then uses it for Quick Settings and the dashboard. It also adds the rule that only one popup is open at a time.

<div class="preview"><svg width="620" height="220" viewBox="0 0 620 220"><g font-size="11"><rect width="620" height="30" fill="#1a1b26"/><path d="M200 30 h220 v130 a15 15 0 0 1 -15 15 h-190 a15 15 0 0 1 -15 -15 z" fill="#1a1b26"><animateTransform attributeName="transform" type="translate" values="0 -150;0 0;0 0;0 -150" keyTimes="0;.25;.75;1" dur="4s" repeatCount="indefinite"/></path><path d="M185 30 h15 v15 a15 15 0 0 0 -15 -15z" fill="#1a1b26"/><path d="M420 30 h15 a15 15 0 0 0 -15 15z" fill="#1a1b26"/><text x="310" y="20" fill="#c0caf5" text-anchor="middle">Sun 22 Nov  14:58</text><text x="130" y="60" fill="#7aa2f7">fillet ▶</text><text x="440" y="60" fill="#7aa2f7">◀ fillet</text><text x="310" y="200" fill="#a9b1d6" text-anchor="middle">the panel slides down from behind the bar and is clipped at its edge</text></g></svg></div>

## One popup at a time

@include lyne/services/WindowManagerService.qml

::: walk
@ 11-13 | What's open
A list of the popups open right now, by name. `anyModuleOpen` keeps an auto-hiding bar shown while you use a popup ([[ch:ly5-bar]]).
@ 15-16 | The close request
A signal every popup service listens to. Each closes itself unless the request names it.
@ 18-31 | Registering
Each popup service calls `registerOpen` when it opens and `registerClose` when it closes. The object is **copied** before changing it: assigning a changed copy is what makes QML notice ([[ch:ly2-state]] explains the same problem).
@ 35-38 | Opening exclusively
Ask everyone else to close, then run the opening function. Every "open" in the shell goes through this, so opening the launcher closes Quick Settings and opening the dashboard closes the launcher.
:::

> [!NOTE] In the original
> lyne's version also waits for the other popups' **exit animations** to finish before opening the new one (`openAfterClose`), because creating a window while another animates out made the old one stutter. It tracks mapped surfaces per name to know when they're gone.

## The attached panel

@include lyne/components/AttachedPanel.qml

::: walk
@ 18-26 | Inputs
Whether it's shown, which edge the bar is on, colour, corner radius and fillet size (both default to the large radius). Content goes into `body`.
@ 28-34 | Animating in, even at creation
`progress` runs from 0 (hidden) to 1 (out). A panel created already `shown` would otherwise start at 1 and never animate. So `progress` stays 0 until one tick after creation (`Qt.callLater`), and only then is bound to `shown`. The `Behavior` animates every change.
@ 35-40 | Timing
Out over the long duration, back in over the normal one, both with `OutExpo`: a quick start that settles gently.
@ 42-50 | The clipper
An item the size of the panel, plus room for a fillet on each side, that clips its contents. The panel slides **towards the bar** to hide, and the clipper's edge is exactly at the bar's edge, so the panel disappears behind it.
@ 52-58 | Sliding
`y` goes from one panel-height above (or below, for a bottom bar) to 0. The opacity reaches full at half the progress, so the panel is solid for most of the slide.
@ 60-75 | The body
Rounded corners, except the two touching the bar. The trick: a rounded rectangle **taller** than the panel, pushed past the bar edge by one radius, inside an item that clips it. Only the far corners show their rounding. Drawing a second square rectangle over the corners would be simpler, but the colour is see-through: where the two overlapped, the panel would look darker.
@ 77-92 | The fillets
Two concave corners outside the panel's sides, at the bar edge: the left one mirrored, both flipped for a bottom bar. They fill the angle between bar and panel with a curve, which is what makes them look like one shape.
@ 94-97 | The content
Whatever you put inside fills the panel and slides with it.
:::

## The popup window around it

A panel needs a window. It can't live inside the bar's window, which is only as tall as the bar.

@include lyne/components/AttachedPopup.qml

::: walk
@ 14-21 | Inputs
`shown`, the button it opens from, the panel's size, the bar window, the content, and a `dismissed` signal for Escape or a click elsewhere.
@ 23-25 | Centring under the button
When opening, ask the button where its centre is in window coordinates. The bar spans the whole screen, so that's also the screen x.
@ 27-28 | Staying for the exit
The window stays mapped while the panel slides back in, and unmaps when `progress` reaches 0.
@ 30-41 | Placement
Full width along the bar's edge. `ExclusionMode.Ignore` means it starts at the screen edge, under the bar, ignoring the space the bar reserves, so the panel can sit flush against it. Keyboard focus only while shown, and only when clicked (`OnDemand`), so it never steals typing.
@ 43 | Only the panel takes clicks
The window is wide, but the mask limits input to the panel. Clicks beside it reach your windows.
@ 45-49 | Clicking elsewhere closes
[[HyprlandFocusGrab]] reports `cleared` when you click outside its windows. The bar window is included: otherwise clicking the bar button that opened the panel would close it (the click lands outside) and then immediately reopen it (the button toggles).
@ 51-58 | Positioning the panel
Under the bar (`barReservedHeight` from the top), centred on the button, but never closer to the screen edge than the spacing plus a fillet.
@ 60-65 | The content holder
It holds the focus, so Escape reaches it.
:::

## Quick Settings

Each popup has a service (state and logic) and a window (drawing). The service:

@include lyne/services/QuickSettingsService.qml

::: walk
@ 12-14 | State
Open or not, on which screen, and which page.
@ 16-23 | Toggle
Clicking the button on the screen where it's open closes it. Otherwise close every other popup, then open here on the main page.
@ 27-31 | Being polite
Close when another popup opens, and tell the window manager service when we open or close.
@ 33-36 | IPC
For a keybind: `qs -c lyne ipc call quicksettings toggle` opens it on the focused monitor.
:::

The panel:

@include lyne/modules/quickSettings/QuickSettingsWindow.qml

::: walk
@ 15-24 | An attached popup
Shown when its service says so for this screen. Escape on a sub-page goes back to the main page; on the main page it closes. The height follows the current page, animated.
@ 26-28 | Shortcuts to the data
The Wi-Fi device, its network, and the Bluetooth adapter.
@ 30-38 | A tile
An inline component: icon, title, status line, an "on" state, and optionally the sub-page its arrow opens.
@ 40-45 | Tile look
Accent when on, a hover colour, a card otherwise.
@ 46-65 | Tile content and input
Clicking the tile toggles; clicking the arrow opens its page. On an accent tile, text uses `textReverseColor`, the colour meant for text on the accent.
@ 68-74 | Page header
A back button and a title, shared by the sub-pages.
@ 76-97 | A list row
Icon, name and status, highlighted when current.
@ 99-117 | Swapping pages
A `Loader` shows the component for `QuickSettingsService.page`. When a page loads, it starts transparent and 20 px to the right, and slides into place. The container's `implicitHeight` is the page's, which sets the panel height.
@ 120-131 | Main page: header
Your user name, then three buttons: next theme, Settings, power menu.
@ 133-168 | Four tiles
Wi-Fi (on/off, with its network), Bluetooth, do not disturb and caffeine. Each reads its state from a service and calls the service to toggle, so the bar icons, the Settings app and these tiles always agree.
@ 170-183 | Sliders
Volume (the icon opens the sound page) and brightness (only when there's a backlight).
@ 187-207 | Wi-Fi page
Networks sorted connected first, then by strength, at most eight. A click disconnects the current one or connects to another. Known networks connect directly; a new secured network needs its password set once with your network tool (lyne has its own password page, `WifiPasswordPage.qml`).
@ 209-227 | Bluetooth page
Paired devices, with battery when connected. A click connects or disconnects.
@ 229-245 | Sound page
Every output device; a click makes it the default.
:::

## The dashboard

@include lyne/services/DashboardService.qml

The same shape as Quick Settings, plus a tab. `toggle("media", screen)` opens on the media tab; pressing it again on the same tab closes it; an empty tab keeps the last one. lyne has a global shortcut for each tab, so you can bind keys straight to "dashboard media".

@include lyne/modules/dashboard/DashboardWindow.qml

::: walk
@ 15-24 | An attached popup
520 pixels wide, as tall as its content.
@ 26-27 | Shared data
The active player (the one playing, else the first) and a clock with seconds.
@ 29-32 | Switching tabs
Next or previous, wrapping around.
@ 34-41 | Keyboard
Ctrl+Tab and Ctrl+Shift+Tab move between tabs, as in lyne.
@ 43-74 | The tab bar
One rounded pill slides under the active tab: its x is the tab's index times a third of the width. Three tab buttons with icon and label sit on top.
@ 76-79 | The current tab
A `Loader` with one component per tab.
@ 82-88 | Player controls
Previous, play/pause and next.
@ 90-113 | Player card
Cover art (or a music icon), title, artist and controls.
@ 115-133 | Overview: clock and player
A large clock and the date in a card, with the player card under it.
@ 135-178 | Overview: calendar
A month grid of 6 × 7 days starting on Monday. `lead` is how many days of the previous month come first; `new Date(year, month, 1 - lead + index)` lets JavaScript work out the actual dates, including the previous and next months. Today is accent-filled; other months are dim.
@ 180-202 | Media tab
The player card, larger, and a progress bar. MPRIS players don't send their position continuously, so a timer asks for it once a second while playing (`positionChanged()`).
@ 204-215 | System tab: data
CPU, memory and disk usage, from 0 to 1.
@ 217-223 | Sources
`/proc/stat` and `/proc/meminfo` are read with `FileView`, which needs no process. Disk usage comes from `df`.
@ 224-241 | Measuring
Every 1.5 seconds. CPU: the first line of `/proc/stat` lists time spent in each state since boot; idle time is fields 4 and 5. Usage is the share of time **not** idle between this read and the last one. Memory: one minus available/total.
@ 243-273 | Three bars
One card per value, with a bar that turns red above 85%.
:::

> [!NOTE] In the original
> lyne's dashboard has four tabs: Overview (clock, weather, a calendar with public holidays, resources, player), Media (a cava audio ring, synced lyrics, a dancing GIF), System (CPU, GPU, memory, storage, network with sparklines) and Weather (Open-Meteo forecasts). Tabs can be swiped, and the bar's centre can show buttons that open each tab.

## Practice

::: exercise warm | Open from the keyboard
Bind `qs -c lyne ipc call dashboard toggle system` to a key in Hyprland and try it.
:::

::: exercise practice | A fifth tile
Add a "Night light" tile to Quick Settings that runs `hyprsunset -t 4000` while on (a `Process` whose `running` is the tile's state).
:::

::: exercise practice | Notification history in Quick Settings
lyne's Quick Settings shows the latest notifications under the sliders. Add a list of the last three (`NotificationService.history`, [[ch:ly8-notifications-osd]]) to the main page.
:::

::: exercise challenge | A weather tab
Add a fourth dashboard tab with the current weather from Open-Meteo (`https://api.open-meteo.com/v1/forecast?latitude=…&longitude=…&current=temperature_2m,weather_code`), fetched with `curl` in a `Process` every 30 minutes.
:::
