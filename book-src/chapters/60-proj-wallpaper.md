# Project: Wallpaper and Theme Switcher

Two pieces: a **wallpaper layer** drawn by Quickshell (so you don't need swww/hyprpaper) with crossfade transitions, and a **picker** that shows thumbnails of your wallpaper folder; choosing one changes the wallpaper and re-themes the whole shell through matugen ([[ch:44-theming]]).

## Wallpaper service

```qml file="services/Wallpaper.qml"
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property string dir: Config.wallpaper?.dir ?? (Quickshell.env("HOME") + "/Pictures/Wallpapers")
    property string current: state.path
    property var files: []

    function set(path: string): void {
        state.path = path
        Quickshell.execDetached([Quickshell.shellPath("scripts/wallpaper.sh"), path, Config.appearance.mode ?? "dark"])
    }
    function random(): void { if (files.length) set(files[Math.floor(Math.random() * files.length)]) }
    function rescan(): void { scan.running = true }

    Process {
        id: scan
        running: true
        command: ["find", root.dir, "-maxdepth", "2", "-type", "f",
                  "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")"]
        stdout: StdioCollector { onStreamFinished: root.files = text.trim().split("\n").filter(f => f).sort() }
    }

    FileView {
        path: Quickshell.statePath("wallpaper.json")
        onAdapterUpdated: writeAdapter()
        printErrors: false
        JsonAdapter { id: state; property string path: "" }
    }

    IpcHandler {
        target: "wallpaper"
        function set(path: string): void { root.set(path) }
        function random(): void { root.random() }
        function picker(): void { GlobalStates.toggle("wallpaperPicker") }
        function get(): string { return root.current }
    }
}
```

## The background layer with crossfade

```qml file="modules/wallpaper/Wallpaper.qml"
import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bg
            required property ShellScreen modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "black"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "quickshell:wallpaper"

            // two images: the new one fades in over the old one
            property bool showA: true
            property string target: Wallpaper.current ? "file://" + Wallpaper.current : ""
            onTargetChanged: {
                const next = showA ? imgB : imgA
                next.source = target
            }

            component Wall: Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(bg.width * bg.modelData.devicePixelRatio, bg.height * bg.modelData.devicePixelRatio)
                asynchronous: true
                cache: false
                smooth: true
                Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.InOutQuad } }
            }

            Wall {
                id: imgA
                opacity: bg.showA ? 1 : 0
                onStatusChanged: if (status === Image.Ready && source == bg.target) bg.showA = true
            }
            Wall {
                id: imgB
                opacity: bg.showA ? 0 : 1
                onStatusChanged: if (status === Image.Ready && source == bg.target) bg.showA = false
            }
            Component.onCompleted: imgA.source = target
        }
    }
}
```

The new image loads in the hidden layer; when it's ready, `showA` flips and the opacity Behaviors crossfade.

## The picker

```qml file="modules/wallpaper/WallpaperPicker.qml"
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Scope {
    LazyLoader {
        active: GlobalStates.wallpaperPickerOpen

        PanelWindow {
            id: win
            screen: Quickshell.screens.find(s => s.name === GlobalStates.activeScreen) ?? null
            anchors.bottom: true
            margins.bottom: 24
            implicitWidth: Math.min(1200, (screen?.width ?? 1400) - 80)
            implicitHeight: 260
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell:wallpicker"

            StyledRect {
                anchors.fill: parent
                anchors.margins: 6
                level: 3
                color: Colors.surface

                ColumnLayout {
                    anchors { fill: parent; margins: 14 }
                    spacing: 10

                    RowLayout {
                        StyledText { text: "Wallpapers"; font.bold: true; font.pixelSize: Appearance.font.size.large; Layout.fillWidth: true }
                        StyledText { text: Wallpaper.files.length + " images"; color: Colors.onSurfaceVariant }
                        IconButton { icon: "shuffle"; onClicked: Wallpaper.random() }
                        IconButton { icon: "refresh"; onClicked: Wallpaper.rescan() }
                        IconButton {
                            icon: Config.appearance.mode === "light" ? "light_mode" : "dark_mode"
                            onClicked: { Config.appearance.mode = Config.appearance.mode === "light" ? "dark" : "light"; Wallpaper.set(Wallpaper.current) }
                        }
                    }

                    ListView {
                        id: list
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        orientation: ListView.Horizontal
                        spacing: 10
                        clip: true
                        focus: true
                        model: Wallpaper.files
                        currentIndex: Math.max(0, Wallpaper.files.indexOf(Wallpaper.current))
                        highlightMoveDuration: 200
                        preferredHighlightBegin: width / 2 - 140
                        preferredHighlightEnd: width / 2 + 140
                        highlightRangeMode: ListView.ApplyRange
                        keyNavigationEnabled: true
                        cacheBuffer: 1200

                        Keys.onEscapePressed: GlobalStates.wallpaperPickerOpen = false
                        Keys.onReturnPressed: { Wallpaper.set(model[currentIndex]); GlobalStates.wallpaperPickerOpen = false }

                        delegate: Item {
                            id: thumb
                            required property string modelData
                            required property int index
                            readonly property bool selected: ListView.isCurrentItem
                            width: 280
                            height: list.height

                            ClippingRectangle {
                                anchors.fill: parent
                                anchors.margins: thumb.selected ? 0 : 8
                                Behavior on anchors.margins { Anim {} }
                                radius: Appearance.rounding.normal
                                color: Colors.surfaceContainerHigh
                                border.width: thumb.selected ? 3 : 0
                                border.color: Colors.primary

                                Image {
                                    anchors.fill: parent
                                    source: "file://" + thumb.modelData
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize: Qt.size(560, 360)          // decode thumbnails small!
                                    asynchronous: true
                                    opacity: status === Image.Ready ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 200 } }
                                }
                                Rectangle {                                // file name label
                                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                    height: 28
                                    color: Colors.alpha(Colors.surface, 0.75)
                                    visible: thumb.selected
                                    StyledText {
                                        anchors.centerIn: parent
                                        width: parent.width - 16
                                        horizontalAlignment: Text.AlignHCenter
                                        text: thumb.modelData.split("/").pop()
                                        font.pixelSize: Appearance.font.size.small
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: list.currentIndex = thumb.index
                                onClicked: { Wallpaper.set(thumb.modelData); GlobalStates.wallpaperPickerOpen = false }
                            }
                        }
                    }
                }
            }
        }
    }
}
```

## Thumbnail cache (large folders)

Decoding many 4K images is slow even with `sourceSize`. Pre-generate thumbnails once with ImageMagick and show those:

```bash file="scripts/thumbs.sh"
#!/usr/bin/env bash
src="$1"; out="$HOME/.cache/myshell/thumbs"; mkdir -p "$out"
for f in "$src"/*.{jpg,jpeg,png,webp}; do
  [ -e "$f" ] || continue
  t="$out/$(echo -n "$f" | md5sum | cut -d' ' -f1).jpg"
  [ -e "$t" ] || magick "$f" -resize 560x360^ -gravity center -extent 560x360 -quality 85 "$t"
done
```

## Video and animated wallpapers

```qml
import QtMultimedia
Video {
    anchors.fill: parent
    source: "file:///home/me/Videos/live.mp4"
    loops: MediaPlayer.Infinite
    autoPlay: true
    muted: true
    fillMode: VideoOutput.PreserveAspectCrop
}
```

Video decoding costs power; pause it when a window covers the screen (`ToplevelManager.toplevels.values.some(t => t.fullscreen || t.maximized)`).

> [!TRY] Exercises
> 1. Add a timer that changes to a random wallpaper every 30 minutes (toggleable).
> 2. Add per-monitor wallpapers (store a map `{ screenName: path }`).
> 3. Add a search box to filter by file name.
