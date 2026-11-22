# Ricing OSDs and the Power Menu

These are the two smallest pieces of a shell, and the ones people judge fastest. An **OSD** (on-screen display) flashes for a second when you press a volume or brightness key. The **power menu** (session menu) appears when you want to leave. Both are simple to build and easy to make look premium.

**Logic:** volume/brightness services from [[ch:53-proj-osd]] and session actions from [[ch:56-proj-session]].

## Part 1: The OSD

### Anatomy

<div class="preview"><svg width="460" height="120" viewBox="0 0 460 120"><rect x="80" y="30" width="300" height="56" rx="28" fill="#1e1e2e" stroke="#313244"/><circle cx="110" cy="58" r="18" fill="#cba6f7"/><text x="110" y="64" font-size="16" text-anchor="middle" fill="#1e1e2e">🔊</text><rect x="140" y="54" width="180" height="8" rx="4" fill="#313244"/><rect x="140" y="54" height="8" rx="4" fill="#cba6f7"><animate attributeName="width" values="60;150;110;60" dur="4s" repeatCount="indefinite"/></rect><text x="358" y="63" font-size="12" fill="#cdd6f4" text-anchor="end">62</text><g fill="#585b70" font-size="9"><text x="90" y="104">icon badge</text><text x="190" y="104">level bar</text><text x="330" y="104">value</text></g></svg></div>

| Module | File | Job |
|---|---|---|
| Controller | `Osd.qml` | listens to services, decides **what** to show and for how long |
| Icon badge | `OsdIcon.qml` | icon in a circle; changes per level (mute, low, high) |
| Level bar | `OsdBar.qml` | horizontal or vertical bar, animated, with overdrive (>100%) |
| Window | `OsdWindow.qml` | position, enter/exit animation, three layouts |

### Module 1: The controller

One controller handles every kind of OSD, so they never overlap: a new event replaces the current one.

```qml file="rice/osd/Osd.qml"
pragma Singleton
import Quickshell
import QtQuick
import qs.services

Singleton {
    id: root
    property bool visible: false
    property string kind: "volume"       // "volume" | "mic" | "brightness" | "kbd"
    property real value: 0               // 0..1 (or up to 1.5 for overdrive)
    property string icon: "volume_up"
    property string label: ""            // optional text instead of a bar (e.g. keyboard layout)
    property bool muted: false

    function show(k, v, i, m, l) {
        kind = k; value = v; icon = i; muted = m ?? false; label = l ?? ""
        visible = true
        hide.restart()
    }
    Timer { id: hide; interval: 1400; onTriggered: root.visible = false }

    // Don't flash the OSD on startup when services first report their values.
    property bool ready: false
    Timer { running: true; interval: 1500; onTriggered: root.ready = true }

    Connections {
        target: Audio
        function onVolumeChanged() { if (root.ready) root.show("volume", Audio.volume, Audio.icon, Audio.muted) }
        function onMutedChanged() { if (root.ready) root.show("volume", Audio.volume, Audio.icon, Audio.muted) }
    }
    Connections {
        target: Brightness
        function onValueChanged() {
            if (root.ready) root.show("brightness", Brightness.value, Brightness.value < 0.3 ? "brightness_low" : Brightness.value < 0.7 ? "brightness_medium" : "brightness_high")
        }
    }
}
```

> [!TIP] Add more kinds
> Caps Lock, keyboard layout, mic mute or "Airplane mode" are just more `show()` calls: `Osd.show("kbd", 0, "keyboard", false, "US → DE")` shows a label instead of a bar.

<!-- ex:### Module 1: The controller -->
::: exercise warm | Caps Lock OSD
Show an OSD with a label "Caps Lock on/off" when Caps Lock changes.
--- hint
Poll `/sys/class/leds/input*::capslock/brightness` with a `FileView` and `Timer { interval: 200 }`, and call `Osd.show("kbd", 0, "keyboard_capslock", false, on ? "Caps Lock on" : "Caps Lock off")` when it changes.
:::


### Module 2: Icon badge

```qml file="rice/osd/OsdIcon.qml"
import QtQuick
import qs.services
import qs.widgets

Rectangle {
    property string icon
    property bool muted: false
    implicitWidth: 38; implicitHeight: 38
    radius: Theme.style === "neon" ? 0 : 19
    color: muted ? Theme.bad : Theme.accent
    Behavior on color { ColorAnimation { duration: Theme.fast } }
    TIcon {
        anchors.centerIn: parent
        icon: parent.icon; fill: 1; size: 20
        color: Theme.onAccent
        // a tiny "bump" whenever the icon changes
        onIconChanged: bump.restart()
        SequentialAnimation on scale { id: bump; running: false
            NumberAnimation { to: 1.25; duration: 80 } NumberAnimation { to: 1; duration: 160; easing.type: Easing.OutBack } }
    }
}
```

<!-- ex:### Module 2: Icon badge -->
::: exercise practice | Level-based icons
Pick the volume icon from the level yourself: `volume_mute` at 0, `volume_down` under 50%, `volume_up` above.
:::


### Module 3: Level bar (with overdrive)

```qml file="rice/osd/OsdBar.qml"
import QtQuick
import qs.services

Rectangle {
    id: bar
    property real value: 0
    property bool vertical: false
    property bool muted: false
    implicitWidth: vertical ? 8 : 180
    implicitHeight: vertical ? 160 : 8
    radius: Theme.style === "neon" ? 0 : Math.min(width, height) / 2
    color: Theme.surface

    readonly property real shown: Math.min(1, value)
    Rectangle {
        // fill grows from the left (horizontal) or from the bottom (vertical)
        width: bar.vertical ? parent.width : parent.width * bar.shown
        height: bar.vertical ? parent.height * bar.shown : parent.height
        y: bar.vertical ? parent.height - height : 0
        radius: parent.radius
        color: bar.muted ? Theme.fgDim : Theme.accent
        Behavior on width { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
    }
    // overdrive: volume above 100% shows a warning-colored tip
    Rectangle {
        visible: bar.value > 1
        anchors { right: bar.vertical ? undefined : parent.right; top: bar.vertical ? parent.top : undefined }
        width: bar.vertical ? parent.width : parent.width * Math.min(0.5, bar.value - 1)
        height: bar.vertical ? parent.height * Math.min(0.5, bar.value - 1) : parent.height
        radius: parent.radius
        color: Theme.warn
    }
}
```

<!-- ex:### Module 3: Level bar -->
::: exercise practice | Segmented bar
Draw the level as 10 segments instead of one fill (a `Row` of 10 rectangles colored by index).
--- solution
```qml
Row { spacing: 3
    Repeater { model: 10
        Rectangle { required property int index; width: 14; height: 8; radius: 2
            color: index < Math.round(Osd.value * 10) ? Theme.accent : Theme.surface } } }
```
:::


### Assembly: three OSD layouts

<div class="preview"><svg width="660" height="190" viewBox="0 0 660 190"><g font-size="10"><g transform="translate(5 5)"><rect width="210" height="160" rx="8" fill="#26233a"/><rect x="45" y="118" width="120" height="28" rx="14" fill="#1e1e2e"/><circle cx="60" cy="132" r="9" fill="#cba6f7"/><rect x="74" y="129" width="80" height="6" rx="3" fill="#313244"/><rect x="74" y="129" width="50" height="6" rx="3" fill="#cba6f7"/><text x="105" y="180" fill="#a6adc8" text-anchor="middle">pill (bottom center)</text></g><g transform="translate(225 5)"><rect width="210" height="160" rx="8" fill="#26233a"/><rect x="180" y="30" width="22" height="100" rx="11" fill="#1e1e2e"/><rect x="188" y="44" width="6" height="64" rx="3" fill="#313244"/><rect x="188" y="70" width="6" height="38" rx="3" fill="#cba6f7"/><circle cx="191" cy="120" r="6" fill="#cba6f7"/><text x="105" y="180" fill="#a6adc8" text-anchor="middle">side (vertical)</text></g><g transform="translate(445 5)"><rect width="210" height="160" rx="8" fill="#26233a"/><rect x="0" y="0" width="210" height="16" fill="#1e1e2e"/><rect x="60" y="2" width="90" height="26" rx="13" fill="#000"/><text x="74" y="19" fill="#fff">☀</text><rect x="88" y="12" width="52" height="5" rx="2.5" fill="#333"/><rect x="88" y="12" width="30" height="5" rx="2.5" fill="#f9e2af"/><text x="105" y="180" fill="#a6adc8" text-anchor="middle">island (from the bar)</text></g></g></svg></div>

```qml file="rice/osd/OsdWindow.qml"
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Variants {
    id: root
    property string layout: "pill"         // "pill" | "side" | "island"
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property ShellScreen modelData
        screen: modelData
        readonly property bool side: root.layout === "side"
        readonly property bool island: root.layout === "island"
        readonly property bool focused: modelData.name === GlobalStates.activeScreen
        visible: focused && (Osd.visible || exitAnim.running)

        anchors { bottom: root.layout === "pill"; right: win.side; top: win.island }
        margins { bottom: 80; right: 16; top: win.island ? 4 : 0 }
        implicitWidth: win.side ? 56 : win.island ? 300 : 320
        implicitHeight: win.side ? 230 : 60
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {}                         // never block clicks
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:osd"

        TSurface {
            id: box
            anchors.centerIn: parent
            width: parent.width; height: parent.height
            color: win.island ? "black" : Theme.bg
            radius: win.side ? width / 2 : height / 2
            raised: !win.island

            // enter/exit: pill rises, side slides in, island expands from a dot
            opacity: Osd.visible ? 1 : 0
            scale: win.island ? (Osd.visible ? 1 : 0.3) : 1
            transform: Translate {
                x: win.side && !Osd.visible ? 40 : 0
                y: root.layout === "pill" && !Osd.visible ? 30 : 0
                Behavior on x { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
            }
            Behavior on opacity { NumberAnimation { id: exitAnim; duration: Theme.normal } }
            Behavior on scale { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutBack } }

            // horizontal content (pill, island)
            RowLayout {
                visible: !win.side
                anchors { fill: parent; leftMargin: 10; rightMargin: 18 }
                spacing: 12
                OsdIcon { icon: Osd.icon; muted: Osd.muted; implicitWidth: win.island ? 30 : 38; implicitHeight: implicitWidth }
                OsdBar { Layout.fillWidth: true; visible: Osd.label === ""; value: Osd.value; muted: Osd.muted }
                TText { Layout.fillWidth: true; visible: Osd.label !== ""; text: Osd.label; color: win.island ? "white" : Theme.fg }
                TText { visible: Osd.label === ""; text: Math.round(Osd.value * 100); font.features: ({ "tnum": 1 })
                        color: win.island ? "white" : Theme.fg; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
            }
            // vertical content (side)
            ColumnLayout {
                visible: win.side
                anchors { fill: parent; topMargin: 18; bottomMargin: 9 }
                spacing: 10
                TText { Layout.alignment: Qt.AlignHCenter; text: Math.round(Osd.value * 100); font.pixelSize: Theme.textSmall }
                OsdBar { Layout.alignment: Qt.AlignHCenter; Layout.fillHeight: true; vertical: true; value: Osd.value; muted: Osd.muted }
                OsdIcon { Layout.alignment: Qt.AlignHCenter; icon: Osd.icon; muted: Osd.muted }
            }
        }
    }
}
```

**Ricing choices**
- `mask: Region {}` makes the OSD click-through: it can never get in the way.
- It shows only on the focused monitor (`GlobalStates.activeScreen`).
- The **island** layout sits flush under the top edge in black, so with a black bar it looks like the bar itself grows.

---

<!-- ex:### Assembly: three OSD layouts -->
::: exercise challenge | Follow the bar
For the island layout, read `Theme.layout` and only use the black island when the bar is full-width; otherwise fall back to the pill.
:::


## Part 2: The power menu

### Anatomy

<div class="preview"><svg width="520" height="220" viewBox="0 0 520 220"><rect width="520" height="220" rx="10" fill="#11111bcc"/><text x="260" y="40" fill="#cdd6f4" font-size="15" text-anchor="middle" font-weight="700">Goodbye, alex</text><text x="260" y="58" fill="#a6adc8" font-size="10" text-anchor="middle">up 3h 12m</text><g font-size="10" text-anchor="middle"><g><rect x="45" y="80" width="70" height="70" rx="20" fill="#313244"/><text x="80" y="122" font-size="20" fill="#cdd6f4">🔒</text><text x="80" y="168" fill="#cdd6f4">Lock</text></g><g><rect x="130" y="80" width="70" height="70" rx="20" fill="#313244"/><text x="165" y="122" font-size="20" fill="#cdd6f4">☾</text><text x="165" y="168" fill="#cdd6f4">Sleep</text></g><g><rect x="215" y="80" width="70" height="70" rx="20" fill="#313244"/><text x="250" y="122" font-size="20" fill="#cdd6f4">⇥</text><text x="250" y="168" fill="#cdd6f4">Log out</text></g><g><rect x="300" y="80" width="70" height="70" rx="20" fill="#45365e" stroke="#cba6f7" stroke-width="2"/><text x="335" y="122" font-size="20" fill="#cba6f7">⟳</text><text x="335" y="168" fill="#cba6f7">Restart</text></g><g><rect x="385" y="80" width="70" height="70" rx="20" fill="#f38ba8"/><text x="420" y="122" font-size="20" fill="#1e1e2e">⏻</text><text x="420" y="168" fill="#f38ba8">Shut down</text></g></g><text x="260" y="200" fill="#6c7086" font-size="10" text-anchor="middle">←→ choose · ↵ confirm · hold to run · Esc cancel</text></svg></div>

| Module | File | Job |
|---|---|---|
| Actions | `PowerActions.qml` | the list of actions and the commands they run |
| Button | `PowerButton.qml` | icon, label, keyboard focus, **hold to confirm** ring |
| Menu | `PowerMenu.qml` | full-screen dimmed overlay, greeting, three layouts |

### Module 1: Actions

```qml file="rice/power/PowerActions.qml"
pragma Singleton
import Quickshell
import QtQuick
import qs.services

Singleton {
    // dangerous: needs a hold or a second press to confirm
    readonly property var list: [
        { id: "lock",     label: "Lock",      icon: "lock",               key: "l", dangerous: false },
        { id: "suspend",  label: "Sleep",     icon: "bedtime",            key: "s", dangerous: false },
        { id: "logout",   label: "Log out",   icon: "logout",             key: "e", dangerous: true  },
        { id: "reboot",   label: "Restart",   icon: "restart_alt",        key: "r", dangerous: true  },
        { id: "poweroff", label: "Shut down", icon: "power_settings_new", key: "p", dangerous: true  }
    ]
    function run(id) {
        GlobalStates.sessionOpen = false
        switch (id) {
        case "lock":     GlobalStates.locked = true; break
        case "suspend":  GlobalStates.locked = true; Quickshell.execDetached(["systemctl", "suspend"]); break
        case "logout":   Quickshell.execDetached(["loginctl", "terminate-session", Quickshell.env("XDG_SESSION_ID") ?? ""]); break
        case "reboot":   Quickshell.execDetached(["systemctl", "reboot"]); break
        case "poweroff": Quickshell.execDetached(["systemctl", "poweroff"]); break
        }
    }
}
```

> [!NOTE] Lock before sleeping
> Suspend sets `locked = true` first, so the session is already locked when you wake up. Lock screens in the [[ch:r2-lockscreen]] guide react to `GlobalStates.locked`.

<!-- ex:### Module 1: Actions -->
::: exercise warm | Hibernate
Add a "Hibernate" action (`systemctl hibernate`) marked as dangerous.
:::


### Module 2: Button with hold-to-confirm

<div class="preview"><svg width="200" height="110" viewBox="0 0 200 110"><rect x="65" y="15" width="70" height="70" rx="20" fill="#313244"/><circle cx="100" cy="50" r="30" fill="none" stroke="#f38ba8" stroke-width="4" stroke-dasharray="188.5" stroke-dashoffset="188.5" transform="rotate(-90 100 50)"><animate attributeName="stroke-dashoffset" values="188.5;0;0" keyTimes="0;.7;1" dur="2s" repeatCount="indefinite"/></circle><text x="100" y="58" font-size="22" text-anchor="middle" fill="#f38ba8">⏻</text><text x="100" y="102" font-size="10" text-anchor="middle" fill="#a6adc8">hold…</text></svg></div>

A quick tap on a dangerous button doesn't run it; you **hold** it (mouse or Enter) for 0.8 s while a ring fills. Safe actions run on a tap.

```qml file="rice/power/PowerButton.qml"
import QtQuick
import QtQuick.Shapes
import qs.services
import qs.widgets

Item {
    id: btn
    required property var action
    property bool selected: false
    property bool compact: false             // list layout: icon + text in a row
    signal triggered()
    implicitWidth: compact ? 260 : 96
    implicitHeight: compact ? 52 : 120

    property real hold: 0                    // 0..1 progress of the hold
    readonly property bool holding: mouse.pressed || keyHeld
    property bool keyHeld: false
    NumberAnimation on hold { id: fill; running: btn.holding && btn.action.dangerous; from: 0; to: 1; duration: 800
                              onFinished: if (btn.hold >= 1) btn.triggered() }
    onHoldingChanged: if (!holding) hold = 0

    Rectangle {
        id: tile
        width: btn.compact ? parent.width : 84; height: btn.compact ? parent.height : 84
        anchors.horizontalCenter: parent.horizontalCenter
        radius: Theme.style === "neon" ? 0 : btn.selected ? Theme.radius + 6 : height / 2      // shape morph on focus
        color: btn.action.id === "poweroff" && btn.selected ? Theme.bad
             : btn.selected ? Theme.alpha(Theme.accent, 0.22) : Theme.surface
        border.width: btn.selected ? 2 : Theme.border
        border.color: btn.selected ? (btn.action.dangerous ? Theme.bad : Theme.accent) : Theme.borderColor
        scale: btn.holding ? 0.94 : 1
        Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Behavior on scale { NumberAnimation { duration: Theme.fast } }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: btn.compact ? 16 : (parent.width - width) / 2
            spacing: 14
            TIcon {
                icon: btn.action.icon; size: btn.compact ? 22 : 32; fill: btn.selected ? 1 : 0
                color: btn.action.id === "poweroff" && btn.selected ? Theme.onAccent : btn.selected ? Theme.accent : Theme.fg
            }
            TText { visible: btn.compact; text: btn.action.label; anchors.verticalCenter: parent.verticalCenter }
        }
        // hold progress ring (around the tile)
        Shape {
            anchors.fill: parent
            visible: btn.hold > 0
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Theme.bad; strokeWidth: 4; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                PathAngleArc { centerX: tile.width / 2; centerY: tile.height / 2; radiusX: tile.width / 2 - 2; radiusY: tile.height / 2 - 2
                               startAngle: -90; sweepAngle: 360 * btn.hold }
            }
        }
    }
    TText {
        visible: !btn.compact
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
        text: btn.holding && btn.action.dangerous ? "Hold…" : btn.action.label
        color: btn.selected ? Theme.fg : Theme.fgDim
        font.bold: btn.selected
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (!btn.action.dangerous) btn.triggered()
    }
}
```

<!-- ex:### Module 2: Button with hold-to-confirm -->
::: exercise practice | Haptic-style shake
If the user releases before the ring is full, shake the button sideways once.
--- hint
In `onHoldingChanged`, when `!holding && hold > 0 && hold < 1`, start a short `SequentialAnimation` on a `Translate` x.
:::


### Assembly: three menu layouts

```qml file="rice/power/PowerMenu.qml"
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Scope {
    id: root
    property string layout: "row"          // "row" | "grid" | "list"

    LazyLoader {
        active: GlobalStates.sessionOpen
        PanelWindow {
            id: win
            screen: Quickshell.screens.find(s => s.name === GlobalStates.activeScreen) ?? null
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell:session"

            property int sel: 0
            readonly property var actions: PowerActions.list
            readonly property int cols: root.layout === "grid" ? 3 : root.layout === "list" ? 1 : actions.length

            Rectangle {                                       // dim + click-outside-to-close
                anchors.fill: parent
                color: Theme.alpha(Theme.bg, 0.7)
                opacity: 0; Component.onCompleted: opacity = 1
                Behavior on opacity { NumberAnimation { duration: Theme.normal } }
                MouseArea { anchors.fill: parent; onClicked: GlobalStates.sessionOpen = false }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 28
                focus: true
                // entrance: grow + fade
                opacity: 0; scale: 0.95
                Component.onCompleted: { opacity = 1; scale = 1 }
                Behavior on opacity { NumberAnimation { duration: Theme.slow } }
                Behavior on scale { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }

                Keys.onLeftPressed: win.sel = (win.sel + win.actions.length - 1) % win.actions.length
                Keys.onRightPressed: win.sel = (win.sel + 1) % win.actions.length
                Keys.onUpPressed: win.sel = Math.max(0, win.sel - win.cols)
                Keys.onDownPressed: win.sel = Math.min(win.actions.length - 1, win.sel + win.cols)
                Keys.onEscapePressed: GlobalStates.sessionOpen = false
                Keys.onPressed: e => {
                    if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && !e.isAutoRepeat) {
                        if (win.actions[win.sel].dangerous) buttons.itemAt(win.sel).keyHeld = true
                        else PowerActions.run(win.actions[win.sel].id)
                    }
                    const i = win.actions.findIndex(a => a.key === e.text)   // shortcut letters
                    if (i >= 0) win.sel = i
                }
                Keys.onReleased: e => { if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) buttons.itemAt(win.sel).keyHeld = false }

                Column {
                    Layout.alignment: Qt.AlignHCenter
                    TText { anchors.horizontalCenter: parent.horizontalCenter; text: "Goodbye, " + Quickshell.env("USER"); font.pixelSize: Theme.textHuge - 6; font.bold: true }
                    TText { anchors.horizontalCenter: parent.horizontalCenter; text: "What would you like to do?"; color: Theme.fgDim }
                }
                GridLayout {
                    Layout.alignment: Qt.AlignHCenter
                    columns: win.cols
                    rowSpacing: root.layout === "list" ? 6 : 18
                    columnSpacing: 18
                    Repeater {
                        id: buttons
                        model: win.actions
                        PowerButton {
                            required property var modelData
                            required property int index
                            action: modelData
                            compact: root.layout === "list"
                            selected: index === win.sel
                            onTriggered: PowerActions.run(modelData.id)
                            HoverHandler { onHoveredChanged: if (hovered) win.sel = parent.index }
                        }
                    }
                }
                TText { Layout.alignment: Qt.AlignHCenter; color: Theme.alpha(Theme.fgDim, 0.6); font.pixelSize: Theme.textSmall
                        text: "←→ choose · ↵ confirm (hold for restart/shut down) · letters jump · Esc cancel" }
            }
        }
    }
}
```

<div class="preview"><svg width="660" height="180" viewBox="0 0 660 180"><g font-size="10"><g transform="translate(5 5)"><rect width="210" height="150" rx="8" fill="#11111b"/><g fill="#313244"><rect x="18" y="55" width="30" height="30" rx="10"/><rect x="55" y="55" width="30" height="30" rx="10"/><rect x="92" y="55" width="30" height="30" rx="10"/><rect x="129" y="55" width="30" height="30" rx="10"/><rect x="166" y="55" width="30" height="30" rx="10" fill="#f38ba8"/></g><text x="105" y="170" fill="#a6adc8" text-anchor="middle">row</text></g><g transform="translate(225 5)"><rect width="210" height="150" rx="8" fill="#11111b"/><g fill="#313244"><rect x="55" y="30" width="30" height="30" rx="10"/><rect x="90" y="30" width="30" height="30" rx="10"/><rect x="125" y="30" width="30" height="30" rx="10"/><rect x="72" y="70" width="30" height="30" rx="10"/><rect x="108" y="70" width="30" height="30" rx="10" fill="#f38ba8"/></g><text x="105" y="170" fill="#a6adc8" text-anchor="middle">grid</text></g><g transform="translate(445 5)"><rect width="210" height="150" rx="8" fill="#11111b"/><g fill="#313244"><rect x="55" y="20" width="100" height="18" rx="6"/><rect x="55" y="42" width="100" height="18" rx="6"/><rect x="55" y="64" width="100" height="18" rx="6"/><rect x="55" y="86" width="100" height="18" rx="6"/><rect x="55" y="108" width="100" height="18" rx="6" fill="#f38ba8"/></g><text x="105" y="170" fill="#a6adc8" text-anchor="middle">list</text></g></g></svg></div>

<!-- ex:### Assembly: three menu layouts -->
::: exercise challenge | Session info
Show the uptime and the number of open windows under the greeting, so users notice unsaved work before logging out.
:::


## Polish checklist

**OSD**
- [ ] Never shows at startup; one OSD at a time; click-through.
- [ ] Shows on the focused monitor only.
- [ ] The icon reflects the level (mute / low / high) and bumps when it changes.
- [ ] The bar animates; overdrive (>100%) is visible.
- [ ] Stays ~1.4 s after the last key press, then leaves quickly.

**Power menu**
- [ ] Fully keyboard-driven: arrows, Enter, Esc, letter shortcuts.
- [ ] Destructive actions need a hold (or a second press); safe ones are instant.
- [ ] Shut down stands out (red when selected).
- [ ] Sleep locks first.
- [ ] Clicking the dimmed background cancels.

<!-- ex:## Polish checklist -->
## Practice

::: exercise project | OSD for your rice
Design an OSD that matches your bar exactly (same radius, font, colors), and test it by holding the volume keys down: it should stay visible and smooth, never flicker.
:::

