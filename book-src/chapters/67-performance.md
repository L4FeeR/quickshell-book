# Performance

A well-built Quickshell shell idles near **0% CPU** and a modest amount of RAM. A badly built one can keep a CPU core busy and drain your battery. This chapter shows how to measure and what to fix.

## Measure first

```bash
pid=$(pgrep -f "qs -c myshell" | head -1)
top -p $pid                                   # CPU% and RES (memory)
ps -o rss=,etime= -p $pid                     # resident memory in KB, uptime
pidstat -p $pid 1                             # CPU per second (sysstat)
QSG_RENDER_TIMING=1 qs -c myshell             # per-frame render times
```

Watch idle CPU with no interaction for a minute. Anything consistently above ~1% means something is waking up too often.

## The big wins

### 1. Don't render when nothing changes
Qt only redraws when something changes. Things that change **every frame**:

- infinite animations (spinners, pulsing dots, visualizers),
- `ScreencopyView { live: true }`,
- `AnimatedImage`, `Video`,
- Timers with short intervals that change visible properties.

Bind them to visibility:

```qml
RotationAnimation on rotation { running: busy && root.visible; loops: Animation.Infinite; from: 0; to: 360; duration: 1000 }
ScreencopyView { live: GlobalStates.overviewOpen }
AnimatedImage { playing: visible }
```

### 2. Prefer events to polling
| Instead of polling… | Use |
|---|---|
| `wpctl get-volume` every second | [[Pipewire]] |
| `playerctl` | [[Mpris]] |
| `cat /sys/…/capacity` | [[UPower]] |
| `hyprctl activeworkspace` | [[Hyprland]] |
| `nmcli` every 5 s | [[Networking]] or `nmcli monitor` + SplitParser |
| `date` | [[SystemClock]] with the lowest precision you need |

### 3. Poll slowly, and only when visible
```qml
Timer { interval: 2000; repeat: true; running: dashboard.visible; onTriggered: refresh() }
```

### 4. FileView over Process
Reading `/proc/stat` with FileView is a file read. Running `sh -c "head -1 /proc/stat"` forks and execs two processes each time.

### 5. Lazy-load windows and heavy items
[[LazyLoader]] for panels, `Loader { active: … }` for heavy parts ([[ch:34-lazy-loading]]).

### 6. Decode images at display size
Always `sourceSize`. A wallpaper picker with 100 thumbnails at full 4K resolution can use **several gigabytes**; with `sourceSize: Qt.size(560, 360)` it uses ~80 MB.

### 7. Views, not Repeaters, for long lists
`ListView` creates only visible delegates. `Repeater` over 500 apps creates 500 delegates.

### 8. ScriptModel for filtered lists
Avoids destroying and recreating every delegate on each keystroke ([[ch:36-models]]).

### 9. Keep bindings cheap
A binding that sorts 500 entries re-runs whenever any dependency changes. Compute heavy things once in a `readonly property` and reuse it, or debounce with a Timer.

### 10. Effects and layers cost GPU
- `layer.enabled` and `MultiEffect` allocate offscreen textures. Disable them while hidden (`layer.enabled: visible`).
- Large blurs (`blurMax: 64` over a fullscreen image) are expensive; blur a downscaled image instead (decode the wallpaper at half size for the lock screen).
- Prefer compositor blur (layer rules) for backgrounds.

### 11. Fullscreen transparent windows
For Caelestia-style shells, set [[HyprlandWindow.visibleMask]] so the compositor doesn't composite (or blur) the empty areas.

### 12. Opaque surfaces where possible
If a window is fully opaque, `surfaceFormat.opaque: true` lets the compositor skip blending.

## Memory checklist

| Check | Typical fix |
|---|---|
| Many hidden windows | LazyLoader |
| Big images | `sourceSize`, `cache: false` for one-off images |
| Notification history growing forever | cap it: dismiss the oldest beyond 100 |
| Clipboard image previews | delete temp files, cap the list |
| Leaking objects created with `createObject` | `destroy()` them, or use Loader/Repeater instead |

## Startup time

- `//@ pragma DropExpensiveFonts` can save memory and startup time.
- Avoid `blockLoading` on files that aren't needed for the first frame.
- `LazyLoader { loading: true }` builds panels in the background after startup instead of during it.
- Run fewer `Process`es at startup; stagger polling timers.

## A performance budget

| State | Target |
|---|---|
| Idle, nothing animating | < 0.5% CPU |
| Music playing with progress bar | < 2% CPU |
| Overview open with live previews | GPU-bound, but no stutter |
| RAM, full shell | 150–350 MB is typical for Qt Quick shells |

> [!TRY] Exercises
> 1. Measure your shell's idle CPU for a minute; find and fix the top offender.
> 2. Make every infinite animation in your shell stop when invisible.
> 3. Compare memory of your wallpaper picker with and without `sourceSize`.
