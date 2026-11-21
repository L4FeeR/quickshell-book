# Glossary

## Alias
A property that is another name for a property of a child object: `property alias text: label.text`. See [[ch:12-components]].

## Anchor
A line (left, right, top, bottom, center, baseline) of an Item that can be attached to another item's line. In [[PanelWindow]], `anchors` instead means which screen edges a window sticks to. See [[ch:18-anchors]].

## Attached property
A property belonging to another type that you set on an object, written `Type.property`, e.g. `Layout.fillWidth` or `WlrLayershell.layer`. See [[ch:13-attached-enums]].

## Binding
A property whose value is an expression that QML re-evaluates automatically when anything it reads changes. The core idea of QML. See [[ch:09-bindings]].

## Binding loop
A binding that depends on itself (directly or in a circle), which QML detects and stops with a warning.

## Bar
A strip along a screen edge showing workspaces, time, status icons. Built with [[PanelWindow]].

## Compositor
The program that draws everything on a Wayland desktop, places windows and handles input: Hyprland, Sway, niri, river. See [[ch:01-what-is-ricing]].

## Component
A reusable template for objects. Every `Capitalized.qml` file is a component; `Component { }` declares one inline. See [[ch:12-components]].

## D-Bus
The message bus Linux desktop programs use to talk to each other and to system services. Quickshell's services use it internally.

## Delegate
The template a view (Repeater, ListView) creates once per model entry. See [[ch:20-models-views]].

## Desktop entry
A `.desktop` file describing an installed app (name, icon, command). Read with [[DesktopEntries]].

## Dispatcher
A Hyprland command such as `workspace 3` or `exec kitty`, run with [[Hyprland.dispatch()]].

## Drawer
A panel that slides out of a screen edge or the bar. See [[ch:65-proj-drawers]].

## Easing
The speed curve of an animation (e.g. fast start, slow end). See [[ch:23-animation-basics]].

## Enum
A named set of fixed values written `Type.Value`, e.g. `Text.AlignHCenter`, `WlrLayer.Overlay`.

## Exclusive zone
Space a layer-shell window reserves at a screen edge so tiled windows don't cover it. See [[PanelWindow.exclusiveZone]].

## FileView
Quickshell's type for reading, watching and writing files. See [[FileView]].

## Fork
A modified copy of a project. noctalia-qs is a fork of Quickshell with extra modules.

## greetd
A minimal login daemon; Quickshell can be its graphical greeter via [[Greetd]].

## Hot reload
Quickshell reloading your config automatically when you save a file, keeping the last working version if there's an error.

## Icon theme
A set of app icons (Papirus, Adwaita) looked up by name. Set with `//@ pragma IconTheme`.

## id
A name for an object, valid within one file: `id: clock`. See [[ch:08-ids-scope]].

## Implicit size
The size an item would like to be, based on its content (`implicitWidth`/`implicitHeight`). See [[ch:17-sizing]].

## IPC
Inter-process communication: letting scripts and keybinds control your shell. See [[IpcHandler]] and [[ch:39-ipc-keybinds]].

## JsonAdapter
Maps a JSON file to QML properties, both ways. See [[JsonAdapter]] and [[ch:38-files-json]].

## Layer
One of four stacking levels for layer-shell windows: Background, Bottom, Top, Overlay. See [[WlrLayer]].

## Layer shell
The Wayland protocol (wlr-layer-shell) that lets bars, docks, overlays and wallpapers attach to screen edges. Quickshell's [[PanelWindow]] uses it.

## Lazy loading
Creating objects only when needed and destroying them when not. See [[LazyLoader]].

## Mask
The region of a window that accepts mouse input; the rest is click-through. See [[Region]] and [[ch:35-masks]].

## matugen
A tool that generates Material You color palettes from an image and renders templates. See [[ch:44-theming]].

## Material Symbols
Google's icon font, used by writing icon names as text. See [[ch:27-fonts-icons]].

## Material You (Material 3)
Google's design system with colors generated from a seed (often your wallpaper) and named roles like `primary`, `surface`, `onSurface`.

## Model
The data a view displays: a number, an array, a ListModel, or a Quickshell [[ObjectModel]].

## MPRIS
The D-Bus standard media players use to expose playback controls. See [[Mpris]].

## Namespace (layer)
A name for a layer-shell window that compositor rules can match, set with [[WlrLayershell.namespace]].

## Nerd Fonts
Programming fonts patched with thousands of icons, addressed by codepoint.

## ObjectModel
Quickshell's live list type for service data (workspaces, players, tray items); use directly as a model or via `.values`. See [[ObjectModel]].

## OSD
On-screen display: the popup showing volume or brightness changes. See [[ch:53-proj-osd]].

## PAM
Pluggable Authentication Modules: Linux's system for checking passwords and fingerprints. See [[PamContext]].

## Panel
A window attached to a screen edge (bar, dock, sidebar).

## PipeWire
The Linux audio (and video) server. See [[Pipewire]].

## Polkit
The system that asks for authorization for privileged actions; an agent shows the password dialog. See [[PolkitAgent]].

## Pragma
A special first-lines comment in `shell.qml` (`//@ pragma …`) that configures Quickshell before loading. See [[ch:29-shell-structure]].

## Property
A named value of an object, like `width` or `color`. See [[ch:06-objects-properties]].

## QML
Qt Modeling Language: the declarative language Quickshell configs are written in.

## qmlls
The QML language server that gives your editor autocomplete and errors. See [[ch:05-editor]].

## Qt
The C++ toolkit QML belongs to (pronounced "cute").

## Qt Quick
Qt's module of visual QML types: Item, Rectangle, Text, animations.

## Rice
A customized Linux desktop setup.

## Scope
Quickshell's non-visual container for windows and services. See [[Scope]].

## ScriptModel
A model that diffs JS arrays so views update efficiently. See [[ScriptModel]].

## Screencopy
Capturing the image of a window or screen; [[ScreencopyView]] shows it live.

## Service
In this book: a singleton that wraps one area of the system (Audio, Battery…). See [[ch:33-singletons]].

## Session lock
The Wayland protocol (ext-session-lock) for secure lock screens. See [[WlSessionLock]].

## Shell
Here: the desktop shell, i.e. bars, panels, launchers, notifications. Not the terminal shell (bash, zsh).

## Signal
An event an object announces, handled with `on<Signal>`. See [[ch:10-signals]].

## Singleton
A type with exactly one instance, accessed by name from anywhere. See [[ch:33-singletons]].

## SNI (StatusNotifierItem)
The modern system tray protocol. See [[SystemTray]].

## Toplevel
A normal application window. See [[Toplevel]] and [[HyprlandToplevel]].

## UPower
The system service that reports battery and power information. See [[UPower]].

## Variants
Quickshell type that creates one copy of something per model entry, typically one window per screen. See [[Variants]].

## Wayland
The modern Linux display protocol, replacing X11.

## Workspace
A virtual desktop that groups windows. See [[ch:48-proj-workspaces]].

## X11
The older Linux display system. Quickshell targets Wayland.

## XDG directories
Standard per-user folders: `~/.config`, `~/.local/share`, `~/.local/state`, `~/.cache`.
