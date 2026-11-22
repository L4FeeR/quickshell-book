# Your First Shell and the Dev Loop

Time to put something on the screen. By the end of this chapter you'll have a working bar and know the edit → save → see loop you'll use for the rest of the book.

## Where configs live

Quickshell looks for configs in `~/.config/quickshell/`:

```text
~/.config/quickshell/
├── playground/
│   └── shell.qml        ← a NAMED config: `qs -c playground`
└── myshell/
    ├── shell.qml        ← every config has a shell.qml entry point
    ├── Bar.qml
    └── ...
```

You can also put a single `shell.qml` directly in `~/.config/quickshell/`, and plain `qs` runs it as the "default" config.

> [!WARN] Default config hides named configs
> If `~/.config/quickshell/shell.qml` exists, Quickshell treats the whole folder as **one** config and **ignores the subfolders**, so `qs -c playground` will fail. Use either one default config *or* named subfolders, not both. This book uses named configs.

We'll use a named config called `playground` so your experiments never collide with anything else.

## Step 1: the smallest possible shell

```bash
mkdir -p ~/.config/quickshell/playground
nano ~/.config/quickshell/playground/shell.qml     # or your editor from the next chapter
```

Type this (don't paste; typing builds memory):

```qml file="~/.config/quickshell/playground/shell.qml"
import Quickshell
import QtQuick

PanelWindow {
    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 32

    Text {
        anchors.centerIn: parent
        text: "Hello, rice!"
    }
}
```

Run it:

```bash
qs -c playground
```

A white bar appears along the top of your screen with "Hello, rice!" in the middle, and your tiled windows move down to make room.

### What each line means

| Line | Meaning |
|---|---|
| `import Quickshell` | Load Quickshell's types (`PanelWindow` comes from here). |
| `import QtQuick` | Load Qt's basic visual types (`Text`, `Rectangle`, …). |
| `PanelWindow {` | Create a [[PanelWindow]]: a window glued to screen edges (a layer-shell surface). |
| `anchors.top: true` … | Glue it to the top, left and right edges, so it stretches across the screen. |
| `implicitHeight: 32` | It's 32 pixels tall. |
| `Text { … }` | A child object: a piece of text drawn inside the window. |
| `anchors.centerIn: parent` | Center the text inside its parent (the window). |
| `text: "Hello, rice!"` | What the text says. |

## Step 2: hot reload

Leave `qs` running. Change the text to `"It reloads!"` and **save**. The bar updates instantly, no restart. This is **hot reload**, and it's the most important productivity feature you have.

Now break something on purpose: delete the closing `}` at the end and save. Look at the terminal:

```text
ERROR: Failed to load configuration
  file:///home/you/.config/quickshell/playground/shell.qml:14:1: Expected token `}'
```

The bar on screen **keeps showing the last working version**, and a small popup tells you the reload failed. Put the brace back and save again: everything recovers. You can't break your desktop by saving a bad file.

> [!TIP] Read the error
> Errors always give `file:line:column`. Line 14, column 1 means "look at the start of line 14". Most beginner errors are a missing `}`, a missing import, or a typo in a type name (`Rectange`).

## Step 3: make it look like a rice

```qml file="~/.config/quickshell/playground/shell.qml"
import Quickshell
import QtQuick

PanelWindow {
    anchors { top: true; left: true; right: true }   // the same three lines, grouped
    margins { top: 6; left: 10; right: 10 }          // float it away from the edges
    implicitHeight: 36
    color: "transparent"                             // window itself is invisible…

    Rectangle {                                      // …we draw our own rounded background
        anchors.fill: parent
        radius: 12
        color: "#1e1e2e"
        border.color: "#313244"
        border.width: 1

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: "  my rice"
            color: "#cba6f7"
            font.pixelSize: 14
            font.bold: true
        }

        Text {
            id: clock
            anchors.centerIn: parent
            color: "#cdd6f4"
            font.pixelSize: 14
            text: Qt.formatDateTime(new Date(), "hh:mm:ss")

            Timer {                                   // re-run every second
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.text = Qt.formatDateTime(new Date(), "hh:mm:ss")
            }
        }
    }
}
```

Save. You now have a floating, rounded, dark bar with a ticking clock. In [[ch:28-timers-time]] you'll replace the `Timer` with the better [[SystemClock]].

## The `qs` command line

| Command | What it does |
|---|---|
| `qs` | Run the default config `~/.config/quickshell/shell.qml` |
| `qs -c NAME` | Run `~/.config/quickshell/NAME/shell.qml` |
| `qs -p PATH` | Run a config from any path (a folder or a `.qml` file) |
| `qs -d` | Daemonize: run in the background and free the terminal |
| `qs --allow-duplicate` | Allow a second copy of the same config (by default `qs` refuses to start a config that's already running) |
| `qs list` | List running instances |
| `qs kill` / `qs kill -c NAME` | Stop an instance |
| `qs log -c NAME` / `-f` | Show (or follow) the log of a background instance |
| `qs ipc show` | List IPC commands your config exposes ([[ch:39-ipc-keybinds]]) |
| `qs ipc call TARGET FUNC ARGS…` | Call one |
| `qs -v` / `-vv` | More verbose logging (INFO / DEBUG internal logs) |
| `qs ipc listen TARGET SIGNAL` | Print every time an IPC signal fires |
| `qs --help` | Everything else |

## Logging from QML

Print anything to the terminal with `console.log`:

```qml
Text {
    text: "hi"
    Component.onCompleted: console.log("Text created, width is", width)
}
```

Output: `INFO qml: Text created, width is 14`. Use `console.warn` and `console.error` for louder messages. This is your main debugging tool; [[ch:66-debugging]] covers more.

## Running it for real

When your config is ready to be your daily shell, start it from your compositor:

```ini file="~/.config/hypr/hyprland.conf"
exec-once = qs -c myshell
```

```ini file="~/.config/sway/config"
exec qs -c myshell
```

```text file="~/.config/niri/config.kdl"
spawn-at-startup "qs" "-c" "myshell"
```

To restart it while developing: `qs kill -c myshell; qs -c myshell -d`.

## Common first-day problems

| Problem | Fix |
|---|---|
| `qs: command not found` | Quickshell isn't installed or not on `PATH`. Reinstall. |
| `module "Quickshell" is not installed` | Broken install or Qt version mismatch: reinstall `quickshell` (and its `-git` deps). |
| Nothing appears, no error | Did you set a size (`implicitHeight`)? A zero-size window isn't shown. |
| Bar appears on the wrong monitor | Normal: you haven't chosen a screen yet. [[ch:31-multi-monitor]] fixes it. |
| Windows don't move out of the way | The compositor ignores the exclusive zone for floating windows; tiled ones move. |
| Text is invisible | Default text color is black: on a black background set `color`. |

## Practice

::: exercise warm | Move the bar
Move the bar to the **bottom** of the screen.
--- hint
Only the `anchors` group of the `PanelWindow` changes.
--- solution
```qml
anchors { bottom: true; left: true; right: true }
```
:::

::: exercise practice | Vertical bar
Make a **vertical** bar on the left edge, 44 px wide.
--- hint
Anchor `left`, `top` and `bottom`, and set `implicitWidth` instead of `implicitHeight`.
--- solution
```qml
PanelWindow {
    anchors { left: true; top: true; bottom: true }
    implicitWidth: 44
    color: "#1e1e2e"
    Text { anchors.centerIn: parent; text: "Q"; color: "white" }
}
```
:::

::: exercise practice | Username on the right
Add a third `Text` on the right side showing your username.
--- hint
`anchors.right: parent.right` plus a margin, and `Quickshell.env("USER")`.
--- solution
```qml
Text {
    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
    text: Quickshell.env("USER")
    color: "#cdd6f4"
}
```
:::

::: exercise challenge | Learn the errors
Break the file in three different ways (a missing `}`, a misspelled type like `Txt`, a property that doesn't exist) and read each error message. Note the **line number** it reports.
--- why
Reading errors quickly is the most valuable skill in this book. Quickshell prints the file, line and column; the first error is usually the real one, and later ones are side effects.
:::
