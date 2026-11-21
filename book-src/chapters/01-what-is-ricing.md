# What Ricing Is (and How a Linux Desktop Works)

Welcome. This book assumes you know **nothing**: not Linux internals, not Qt, not programming. By the last page you'll be able to design a desktop in your head (or on paper, or from a screenshot you love) and build it, piece by piece, with Quickshell.

This first chapter has no code. It gives you the mental map. Every later chapter hangs off it, so don't skip it.

## What "ricing" means

**Ricing** is customizing how your desktop looks and behaves: bars, colors, fonts, widgets, animations, wallpapers, lock screens. The word comes from car culture (making a car look fast with body kits). In the Linux world it simply means *making your desktop yours*. Communities like r/unixporn are full of "rices".

A rice usually has these parts:

| Part | What it is | Examples of tools |
|---|---|---|
| **Compositor / window manager** | Places windows on the screen, handles workspaces and keybinds | Hyprland, Sway, niri, river, KDE's KWin |
| **Bar / panel** | The strip with workspaces, clock, battery, tray | Waybar, Polybar, **Quickshell** |
| **Launcher** | Search box to open apps | rofi, wofi, fuzzel, **Quickshell** |
| **Notification daemon** | Shows popups when apps send notifications | dunst, mako, swaync, **Quickshell** |
| **Lock screen** | Asks for your password | swaylock, hyprlock, **Quickshell** |
| **Widgets** | Clocks, music players, system monitors on the desktop | eww, conky, **Quickshell** |
| **Theme** | Colors, fonts, icons, cursor | matugen, pywal, GTK/Qt themes |

Notice how often **Quickshell** appears. That's the point: Quickshell isn't "a bar". It's a **toolkit for building every one of those shell components**, all in one language, sharing one set of colors and one state. A single Quickshell config can replace Waybar + rofi + dunst + swaylock + eww.

## How a Linux desktop is put together

When you look at your screen, several programs are cooperating. Here is the stack from the hardware up:

<div class="diagram"><svg viewBox="0 0 860 330" role="img" aria-label="Linux desktop stack">
<rect class="n" x="10" y="270" width="840" height="46" rx="10"/><text x="30" y="299">Kernel + drivers: GPU, input devices, battery, backlight, audio hardware</text>
<rect class="n" x="10" y="214" width="410" height="46" rx="10"/><text x="30" y="243">System services: PipeWire, UPower, NetworkManager, BlueZ</text>
<rect class="n" x="440" y="214" width="410" height="46" rx="10"/><text x="460" y="243">D-Bus: the message bus they all talk over</text>
<rect class="a" x="10" y="158" width="840" height="46" rx="10"/><text x="30" y="187">Compositor (Hyprland / Sway / niri …): draws everything, owns the screen and the keyboard</text>
<rect class="n" x="10" y="102" width="410" height="46" rx="10"/><text x="30" y="131">Normal apps: Firefox, kitty, Spotify</text>
<rect class="g" x="440" y="102" width="410" height="46" rx="10"/><text x="460" y="131">Shell layer: Quickshell (bar, popups, lock…)</text>
<rect class="n" x="10" y="20" width="840" height="70" rx="10"/><text x="30" y="50">What you see: windows + your bar + your widgets, composited into one image</text><text class="sm" x="30" y="72">Quickshell sits next to normal apps but uses special Wayland protocols to become bars, overlays and lock screens.</text>
</svg></div>

### The kernel and drivers
The very bottom. It talks to the hardware: your GPU, keyboard, battery, speakers. You rarely touch it while ricing, but files like `/sys/class/backlight/` (screen brightness) and `/sys/class/power_supply/` (battery) come from here.

### System services and D-Bus
Background programs (daemons) that manage things:

- **PipeWire** (with WirePlumber) handles all audio: volume, which speaker, per-app streams.
- **UPower** watches batteries and power.
- **NetworkManager** handles Wi-Fi and Ethernet.
- **BlueZ** handles Bluetooth.
- **MPRIS** isn't a daemon but a *standard*: every media player (Spotify, Firefox, mpv) announces itself on D-Bus so others can control it.

**D-Bus** is the "telephone network" these programs use to talk. When your bar shows the volume, it's really asking PipeWire over its own protocol, or asking UPower over D-Bus. Quickshell has these connections **built in**, which is why it can show live battery and volume without running scripts.

### The compositor
On modern Linux (**Wayland**), the compositor is the most important program. It:

- receives every frame from every app and *composes* them into the final image,
- decides where windows go (tiling, floating, workspaces),
- owns the keyboard and mouse and sends input to the right window,
- runs your keybinds.

Hyprland, Sway, niri and river are compositors. If you used Linux years ago you might know **X11**, the older system, where the "X server" did this job and a separate "window manager" placed windows. On Wayland, compositor and window manager are one program.

> [!NOTE] Wayland vs X11
> Quickshell is built for **Wayland**. Most of its special features (bars that reserve space, lock screens, overlays) use Wayland protocols. It can show plain windows on X11, but this book assumes Wayland, and every modern ricing compositor is Wayland.

### Apps and the shell layer
Normal apps make normal windows. A **shell** (in the desktop sense, not the terminal sense) is the set of programs that make up *the desktop itself*: the bar, the dock, the launcher, notifications. On GNOME this is gnome-shell; on KDE it's Plasma. When you rice a compositor like Hyprland, **you build your own shell**, and Quickshell is the tool for that.

> [!WARN] Two meanings of "shell"
> In this book, **shell** almost always means *desktop shell* (bars, panels, widgets). The *terminal shell* (bash, zsh, fish) is the program in your terminal that runs commands. When we mean that one, we'll say "terminal" or "bash".

## Layer shell: how a bar becomes a bar

A normal app window can be moved and tiled by the compositor. A bar mustn't be: it has to stick to the top edge, stay above windows, and push tiled windows down so they don't cover it. Wayland solves this with the **layer shell** protocol (`wlr-layer-shell`). A program asks the compositor for a *layer surface* and says:

- **anchor me** to the top/bottom/left/right edges,
- put me on **layer** Background, Bottom, Top or Overlay,
- **reserve** N pixels (the *exclusive zone*) so windows avoid me,
- give me (or don't give me) **keyboard focus**.

<div class="diagram"><svg viewBox="0 0 860 210" role="img" aria-label="Layer shell layers">
<rect class="n" x="40" y="160" width="780" height="34" rx="8"/><text x="60" y="182">Background layer: wallpaper, desktop icons</text>
<rect class="n" x="70" y="122" width="720" height="34" rx="8"/><text x="90" y="144">Bottom layer: desktop widgets (below windows)</text>
<rect class="a" x="100" y="84" width="660" height="34" rx="8"/><text x="120" y="106">Normal windows (Firefox, terminal…)</text>
<rect class="n" x="130" y="46" width="600" height="34" rx="8"/><text x="150" y="68">Top layer: bars, docks</text>
<rect class="g" x="160" y="8" width="540" height="34" rx="8"/><text x="180" y="30">Overlay layer: launchers, OSDs, notifications (even above fullscreen)</text>
</svg></div>

In Quickshell this is the [[PanelWindow]] type plus the [[WlrLayershell]] settings. You'll use it constantly from [[ch:04-first-shell]] onward.

## What Quickshell actually is

Quickshell is a program (`quickshell`, also installed as `qs`) that:

1. Reads a folder of **QML files** you write (your "config").
2. Creates the windows, widgets and connections those files describe.
3. **Watches the files**: when you save, it reloads instantly (*hot reload*).
4. Gives your QML extra building blocks that plain Qt doesn't have:
   - **Windows**: [[PanelWindow]], [[FloatingWindow]], [[PopupWindow]], and per-monitor copies with [[Variants]].
   - **System services**: [[Pipewire]] audio, [[Mpris]] media, [[UPower]] battery, [[SystemTray]], [[NotificationServer]], [[Bluetooth]], [[Networking]], [[PamContext]] passwords, [[PolkitAgent]], [[Greetd]].
   - **Compositor integration**: [[Hyprland]], [[I3]] (Sway), [[Niri]], plus generic [[ToplevelManager]].
   - **I/O**: run commands with [[Process]], read and write files with [[FileView]], expose commands with [[IpcHandler]].

### What QML is
**QML** (Qt Modeling Language) is a *declarative* language for user interfaces. Instead of writing steps ("create a box, then set its color, then when the volume changes update the box…"), you **describe what things are**:

```qml
Rectangle {
    width: 200
    height: 20
    color: Audio.muted ? "red" : "green"
}
```

That rectangle is *always* red when muted and green otherwise. You never write "update the color": QML tracks it for you. This idea, the **binding**, is why QML is so good for live desktop widgets. [[ch:09-bindings]] is devoted to it.

QML comes from **Qt** (pronounced "cute"), a huge, mature toolkit used by KDE Plasma, many embedded screens and car dashboards. Quickshell runs on Qt 6, so everything in Qt Quick (animations, effects, layouts, text rendering) is available to you.

### Quickshell vs the alternatives

| Tool | Language | What it can build | Live data | Notes |
|---|---|---|---|---|
| Waybar | JSON + CSS | Bars only | Built-in modules + scripts | Easy, but limited to what modules exist |
| eww | Yuck + GTK CSS | Widgets, bars | Mostly polling scripts | Flexible but scripts everywhere |
| AGS / Astal | JS/TS + GTK | Everything | Native libraries | Powerful, heavier toolchain |
| **Quickshell** | **QML + JS** | **Everything** | **Native services, no polling** | Hot reload, GPU animations, compositor integrations |

## The rices you'll learn from

These popular configs are built with Quickshell. You'll recognize their techniques as the book goes on, and [[ch:68-reading-rices]] shows you how to read their source.

- **end-4 / dots-hyprland ("illogical-impulse")** — a Material You desktop with a bar, left and right sidebars (AI chat, quick settings, notifications), an overview with live window previews, a dock, OSDs, a cheatsheet and a lock screen.
- **Caelestia** — a shell built from "drawers" that slide out of the screen edges, with smooth shape morphing, a media dashboard and an audio visualizer.
- **Noctalia** and **DankMaterialShell** — complete, distributable shells with settings apps, aimed at being installed by others.
- **JaKooLit's Hyprland-Dots** — a popular all-in-one Hyprland setup that mixes classic tools (Waybar, rofi) with Quickshell components, a good model for adopting Quickshell gradually.

## How this book is organized

- **Part I (you are here):** Linux basics, installing, your first shell, editor setup.
- **Part II: the QML language.** Every concept, from one property to components and imports.
- **Part III: Qt Quick.** Drawing, layout, input, animation, effects.
- **Part IV: Quickshell concepts.** Windows, monitors, popups, singletons, processes, files, IPC, compositors, services.
- **Part V: design and architecture.** How big rices are organized, theming from wallpapers, motion design.
- **Part VI: build-along projects.** Nineteen real components, start to finish.
- **Part VII: mastery.** Debugging, performance, a recipe cookbook.
- **Qt reference:** the Qt types you'll use, with their important properties.
- **API reference:** *every* Quickshell type, with every property, function, signal and enum, plus complete examples.
- **Glossary and A–Z index:** look up any word.

> [!TIP] How to read
> Read Parts I–III in order and type every example yourself; copying and pasting teaches far less. From Part IV on, read in order *or* jump to what you need, using the API reference as your dictionary. Press <kbd>/</kbd> anywhere to search.

> [!TRY] Before the next chapter
> Open a terminal and run `echo $XDG_SESSION_TYPE`. If it prints `wayland`, you're ready. If it prints `x11`, log out and choose a Wayland session (Hyprland, Sway, niri…) on your login screen.
