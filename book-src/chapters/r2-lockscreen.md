# Ricing the Lock Screen, Module by Module

The lock screen is the first thing you see every day: a perfect place for big typography and atmosphere. This guide splits it into modules (background, clock, greeting, avatar, password field, status row, media) and assembles them into three layouts.

> [!DANGER] Safety first
> Read the safety notes in [[ch:57-proj-lock]] before testing: keep the auto-unlock timer while developing and know how to recover from a TTY. Lock screens are the one component where a bug can lock you out.

## Anatomy

<div class="preview"><svg width="560" height="320" viewBox="0 0 560 320"><defs><linearGradient id="lbg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#45365e"/><stop offset="1" stop-color="#1e2a45"/></linearGradient></defs><rect width="560" height="320" rx="10" fill="url(#lbg)"/><rect width="560" height="320" rx="10" fill="#000" opacity=".3"/><text x="280" y="110" fill="#fff" font-size="74" font-weight="900" text-anchor="middle">14:32</text><text x="280" y="140" fill="#ffffffcc" font-size="15" text-anchor="middle">Friday, 21 November</text><text x="280" y="164" fill="#cba6f7" font-size="12" text-anchor="middle">Good afternoon, l4feer</text><circle cx="280" cy="204" r="22" fill="#cba6f7"/><rect x="190" y="238" width="180" height="34" rx="17" fill="#ffffff22" stroke="#cba6f7" stroke-width="1.5"/><g fill="#fff"><circle cx="252" cy="255" r="4"/><circle cx="266" cy="255" r="4"/><circle cx="280" cy="255" r="4"/><circle cx="294" cy="255" r="4"/></g><text x="30" y="300" fill="#ffffffaa" font-size="11">🔋 81%   📶 Home-5G   ⌨ US</text><rect x="370" y="284" width="170" height="24" rx="12" fill="#ffffff22"/><text x="385" y="300" fill="#fff" font-size="11">♪ Midnight City  ⏸</text></svg></div>

| Module | File | Job |
|---|---|---|
| Controller | `Lock.qml` | session lock, PAM, shared state, IPC |
| Background | `LockBackground.qml` | wallpaper, blur, dim, vignette |
| Clock | `LockClock.qml` | the hero: time in several styles |
| Greeting | `LockGreeting.qml` | date and "Good afternoon, name" |
| Avatar | `LockAvatar.qml` | user picture with an auth ring |
| Input | `LockInput.qml` | password field with dot feedback, errors, shake |
| Status | `LockStatus.qml` | battery, network, keyboard layout |
| Media | `LockMedia.qml` | music controls |
| Surface | `LockSurface.qml` | one per screen: arranges modules in the chosen layout |

## Module 1: The controller

Shared state lives in one object that every screen's surface reads, so typing on one monitor updates the field on all of them.

```qml file="rice/lock/Lock.qml"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import qs.services

Scope {
    id: root
    property string layout: "centered"          // "centered" | "editorial" | "minimal"
    property string password: ""
    property bool busy: false
    property string error: ""
    property string message: ""                 // PAM info, e.g. fingerprint prompts
    property int attempts: 0
    signal failed()

    function submit(): void {
        if (busy || password === "") return
        busy = true; error = ""
        pam.start()
    }

    PamContext {
        id: pam
        config: "login"
        onPamMessage: { if (responseRequired) respond(root.password); else root.message = message }
        onCompleted: result => {
            root.busy = false
            root.password = ""
            if (result === PamResult.Success) { root.attempts = 0; root.message = ""; GlobalStates.locked = false }
            else { root.attempts++; root.error = "Wrong password"; root.failed() }
        }
    }

    WlSessionLock {
        locked: GlobalStates.locked
        surface: Component { LockSurface { lock: root } }
    }

    IpcHandler { target: "lock"; function lock(): void { GlobalStates.locked = true } }

    // ⚠ development safety net: remove when you trust your lock screen
    Timer { running: GlobalStates.locked; interval: 60000; onTriggered: GlobalStates.locked = false }
}
```

<!-- ex:## Module 1 -->
::: exercise warm | Lockout after failures
After 5 failed attempts, disable input for 30 seconds and show a countdown in `message`.
--- solution
```qml
property int lockout: 0
Timer { running: root.lockout > 0; interval: 1000; repeat: true; onTriggered: root.lockout-- }
onFailed: if (attempts >= 5) { lockout = 30; attempts = 0 }
// in submit(): if (busy || password === "" || lockout > 0) return
```
:::


## Module 2: Background

<div class="preview"><svg width="420" height="150" viewBox="0 0 420 150"><defs><linearGradient id="bgw" x1="0" x2="1"><stop offset="0" stop-color="#f5c2e7"/><stop offset="1" stop-color="#89b4fa"/></linearGradient><filter id="bgb"><feGaussianBlur stdDeviation="8"/></filter><radialGradient id="vig"><stop offset=".55" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".7"/></radialGradient></defs><g><rect width="130" height="150" fill="url(#bgw)"/><circle cx="60" cy="60" r="30" fill="#fff" opacity=".6"/></g><g transform="translate(145 0)"><rect width="130" height="150" fill="url(#bgw)" filter="url(#bgb)"/><circle cx="60" cy="60" r="30" fill="#fff" opacity=".6" filter="url(#bgb)"/></g><g transform="translate(290 0)"><rect width="130" height="150" fill="url(#bgw)" filter="url(#bgb)"/><rect width="130" height="150" fill="#000" opacity=".35"/><rect width="130" height="150" fill="url(#vig)"/></g><g fill="#fff" font-size="10" text-anchor="middle"><text x="65" y="142">wallpaper</text><text x="210" y="142">+ blur</text><text x="355" y="142">+ dim + vignette</text></g></svg></div>

```qml file="rice/lock/LockBackground.qml"
import Quickshell
import QtQuick
import QtQuick.Effects
import qs.services

Item {
    id: root
    property real blur: 1.0                   // 0 = sharp wallpaper
    property real dim: 0.35                   // darkening for readable text
    property bool vignette: true
    property bool animatedIn: false
    anchors.fill: parent

    Image {
        id: wall
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/.cache/myshell/wallpaper"
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(parent.width / 2, parent.height / 2)     // it's blurred anyway: decode small, save RAM
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: wall
        source: wall
        blurEnabled: root.blur > 0
        blur: root.animatedIn ? root.blur : 0                  // blur animates in after locking
        blurMax: 64
        saturation: -0.1
        Behavior on blur { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
    }
    Rectangle { anchors.fill: parent; color: "black"; opacity: root.animatedIn ? root.dim : 0
                Behavior on opacity { NumberAnimation { duration: 600 } } }
    Rectangle {                                                // vignette: darker edges
        anchors.fill: parent
        visible: root.vignette
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.45) }
            GradientStop { position: 0.3; color: "transparent" }
            GradientStop { position: 0.7; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.55) }
        }
    }
    Component.onCompleted: animatedIn = true
}
```

**Ricing choices**
- **Blur amount:** full blur keeps focus on the clock; a light blur (0.3) keeps the wallpaper recognizable.
- **Alternatives:** a solid `Theme.bg` (minimal, instant), a live screenshot of your desktop blurred (grab one with `grim` before locking), or a slow animated gradient.

<!-- ex:## Module 2 -->
::: exercise practice | Slow zoom
Make the wallpaper slowly zoom from `scale: 1.0` to `1.08` over 20 seconds while locked (a "Ken Burns" effect).
--- solution
```qml
NumberAnimation on scale { from: 1.0; to: 1.08; duration: 20000; running: true; easing.type: Easing.InOutSine }
```
Put it on the wallpaper image, not the whole background, so the dim layer stays put.
:::


## Module 3: Clock

<div class="preview"><svg width="560" height="170" viewBox="0 0 560 170"><g transform="translate(10 10)"><rect width="170" height="150" rx="10" fill="#1e1e2e"/><text x="85" y="88" fill="#fff" font-size="46" font-weight="900" text-anchor="middle">14:32</text><text x="85" y="138" fill="#a6adc8" font-size="10" text-anchor="middle">"big"</text></g><g transform="translate(195 10)"><rect width="170" height="150" rx="10" fill="#1e1e2e"/><text x="85" y="68" fill="#cba6f7" font-size="50" font-weight="900" text-anchor="middle">14</text><text x="85" y="112" fill="#fff" font-size="50" font-weight="900" text-anchor="middle">32</text><text x="85" y="138" fill="#a6adc8" font-size="10" text-anchor="middle">"stacked"</text></g><g transform="translate(380 10)"><rect width="170" height="150" rx="10" fill="#1e1e2e"/><text x="85" y="80" fill="#fff" font-size="28" font-weight="300" text-anchor="middle" letter-spacing="6">14 : 32</text><text x="85" y="104" fill="#a6adc8" font-size="11" text-anchor="middle" letter-spacing="3">FRIDAY</text><text x="85" y="138" fill="#a6adc8" font-size="10" text-anchor="middle">"thin"</text></g></svg></div>

```qml file="rice/lock/LockClock.qml"
import Quickshell
import QtQuick
import QtQuick.Effects
import qs.services

Item {
    id: root
    property string style: "big"              // "big" | "stacked" | "thin"
    property int size: 120
    SystemClock { id: clock; precision: SystemClock.Seconds }

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    Column {
        id: col
        anchors.centerIn: parent
        spacing: root.style === "stacked" ? -root.size * 0.25 : 0

        Text {                                                    // big: "14:32"
            visible: root.style === "big"
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "hh:mm")
            color: "white"
            font { family: Theme.font; pixelSize: root.size; weight: Font.Black; letterSpacing: -root.size * 0.03 }
            font.features: ({ "tnum": 1 })
        }
        Repeater {                                                // stacked: hours over minutes
            model: root.style === "stacked" ? [Qt.formatDateTime(clock.date, "hh"), Qt.formatDateTime(clock.date, "mm")] : []
            Text {
                required property string modelData
                required property int index
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData
                color: index === 0 ? Theme.accent : "white"
                font { family: Theme.font; pixelSize: root.size; weight: Font.Black }
                font.features: ({ "tnum": 1 })
            }
        }
        Text {                                                    // thin: spaced light digits
            visible: root.style === "thin"
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "hh : mm")
            color: "white"
            font { family: Theme.font; pixelSize: root.size * 0.6; weight: Font.Light; letterSpacing: root.size * 0.08 }
        }
    }
    // soft shadow so it reads on bright wallpapers
    layer.enabled: true
    layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 0.6; shadowOpacity: 0.4; shadowVerticalOffset: 2 }
}
```

**Ricing choices:** the clock is the hero, so make it **huge** (100–160 px) and heavy (Black weight), or go the opposite way, thin and widely spaced, for an elegant look. Pair a heavy clock with a light date.

<!-- ex:## Module 3 -->
::: exercise practice | A fourth style
Add a `"dots"` clock style that shows hours and minutes stacked with a blinking colon between them.
--- hint
`SequentialAnimation on opacity { loops: Animation.Infinite; … }` on the colon `TText`.
:::


## Module 4: Greeting and date

```qml file="rice/lock/LockGreeting.qml"
import Quickshell
import QtQuick
import qs.services
import qs.widgets

Column {
    property bool showGreeting: true
    spacing: 4
    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property string greeting: clock.hours < 5 ? "Still up" : clock.hours < 12 ? "Good morning"
                                     : clock.hours < 18 ? "Good afternoon" : "Good evening"
    TText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
        color: "#ffffffdd"; font.pixelSize: Theme.textLarge + 4
    }
    TText {
        visible: parent.showGreeting
        anchors.horizontalCenter: parent.horizontalCenter
        text: parent.greeting + ", " + Quickshell.env("USER")
        color: Theme.accent; font.pixelSize: Theme.text
    }
}
```

<!-- ex:## Module 4 -->
::: exercise practice | Late-night message
Between 0:00 and 5:00, show "Go to sleep 😴" instead of the greeting.
:::


## Module 5: Avatar with auth ring

<div class="preview"><svg width="200" height="130" viewBox="0 0 200 130"><circle cx="100" cy="65" r="36" fill="#cba6f7"/><circle cx="100" cy="56" r="12" fill="#1e1e2e" opacity=".6"/><path d="M78 88 a22 18 0 0 1 44 0" fill="#1e1e2e" opacity=".6"/><circle cx="100" cy="65" r="44" fill="none" stroke="#cba6f7" stroke-width="3" stroke-dasharray="70 207" stroke-linecap="round"><animateTransform attributeName="transform" type="rotate" from="0 100 65" to="360 100 65" dur="1s" repeatCount="indefinite"/></circle></svg></div>

```qml file="rice/lock/LockAvatar.qml"
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Shapes
import qs.services

Item {
    id: root
    required property var lock
    property int size: 88
    implicitWidth: size + 16; implicitHeight: size + 16

    ClippingRectangle {
        anchors.centerIn: parent
        width: root.size; height: root.size; radius: root.size / 2
        color: Theme.accent
        Image {
            anchors.fill: parent
            source: "file://" + Quickshell.env("HOME") + "/.face"
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(root.size * 2, root.size * 2)
        }
    }
    Shape {                                              // spinning ring while PAM checks; red on error
        anchors.fill: parent
        visible: root.lock.busy || root.lock.error !== ""
        preferredRendererType: Shape.CurveRenderer
        RotationAnimator on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: root.lock.busy }
        ShapePath {
            fillColor: "transparent"; strokeWidth: 3; capStyle: ShapePath.RoundCap
            strokeColor: root.lock.error ? Theme.bad : Theme.accent
            PathAngleArc { centerX: root.width / 2; centerY: root.height / 2; radiusX: root.width / 2 - 3; radiusY: radiusX
                           startAngle: 0; sweepAngle: root.lock.busy ? 90 : 360 }
        }
    }
}
```

<!-- ex:## Module 5 -->
::: exercise practice | Initials fallback
When `~/.face` doesn't exist, show the user's initial in a colored circle instead.
--- hint
`Image.status === Image.Error` tells you the file is missing.
:::


## Module 6: Password input

<div class="preview"><svg width="360" height="100" viewBox="0 0 360 100"><rect x="80" y="30" width="200" height="40" rx="20" fill="#ffffff1a" stroke="#cba6f7" stroke-width="1.5"><animate attributeName="stroke" values="#cba6f7;#cba6f7;#f38ba8;#f38ba8;#cba6f7" keyTimes="0;.5;.55;.8;1" dur="4s" repeatCount="indefinite"/></rect><g fill="#fff"><circle cx="150" cy="50" r="5"/><circle cx="166" cy="50" r="5"/><circle cx="182" cy="50" r="5"/><circle cx="198" cy="50" r="5"><animate attributeName="r" values="0;5;5" keyTimes="0;.1;1" dur="4s" repeatCount="indefinite"/></circle></g><animateTransform attributeName="transform" type="translate" values="0 0;0 0;-8 0;8 0;-4 0;0 0;0 0" keyTimes="0;.5;.53;.56;.59;.62;1" dur="4s" repeatCount="indefinite"/></svg></div>

Instead of `●●●●` text, this input shows animated dots, one per character, that pop in as you type. It turns red and shakes on a wrong password.

```qml file="rice/lock/LockInput.qml"
import QtQuick
import qs.services
import qs.widgets

Item {
    id: root
    required property var lock
    property int fieldWidth: 300
    implicitWidth: fieldWidth
    implicitHeight: 48 + (hint.visible ? hint.implicitHeight + 8 : 0)

    Rectangle {
        id: field
        width: root.fieldWidth; height: 48
        radius: Theme.style === "neon" ? 0 : height / 2
        color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1.5
        border.color: root.lock.error ? Theme.bad : input.activeFocus ? Theme.accent : Qt.rgba(1, 1, 1, 0.2)
        Behavior on border.color { ColorAnimation { duration: Theme.fast } }

        TextInput {                                         // invisible: just captures typing
            id: input
            anchors.fill: parent
            opacity: 0
            focus: true
            echoMode: TextInput.Password
            enabled: !root.lock.busy
            text: root.lock.password
            onTextChanged: { root.lock.password = text; if (text) root.lock.error = "" }
            Keys.onReturnPressed: root.lock.submit()
            Keys.onEnterPressed: root.lock.submit()
            Keys.onEscapePressed: root.lock.password = ""
        }
        Row {                                               // one dot per character
            anchors.centerIn: parent
            spacing: 8
            Repeater {
                model: Math.min(root.lock.password.length, 24)
                Rectangle {
                    width: 10; height: 10; radius: Theme.style === "neon" ? 0 : 5
                    color: root.lock.error ? Theme.bad : "white"
                    scale: 0
                    Component.onCompleted: scale = 1
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                }
            }
        }
        TText {
            anchors.centerIn: parent
            visible: root.lock.password.length === 0
            text: root.lock.busy ? "Checking…" : root.lock.message || "Enter password"
            color: "#ffffff88"
        }
        transform: Translate { id: shakeX }
    }
    TText {
        id: hint
        anchors { top: field.bottom; topMargin: 8; horizontalCenter: field.horizontalCenter }
        visible: text !== ""
        text: root.lock.error + (root.lock.attempts >= 3 ? "  ·  check Caps Lock / keyboard layout" : "")
        color: Theme.bad
    }
    SequentialAnimation {
        id: shake
        NumberAnimation { target: shakeX; property: "x"; to: -12; duration: 45 }
        NumberAnimation { target: shakeX; property: "x"; to: 12; duration: 90 }
        NumberAnimation { target: shakeX; property: "x"; to: -6; duration: 70 }
        NumberAnimation { target: shakeX; property: "x"; to: 0; duration: 50 }
    }
    Connections { target: root.lock; function onFailed() { shake.restart() } }
}
```

**Ricing choices:** dots instead of text feel modern and hide the password length less precisely if you cap them. The hint after three failed attempts is real UX polish.

<!-- ex:## Module 6 -->
::: exercise practice | Caps Lock warning
Show "Caps Lock is on" under the field while Caps Lock is active.
--- hint
Read `/sys/class/leds/*capslock/brightness` with a `FileView` + a short `Timer`, or check `event.modifiers` in `Keys.onPressed` for a quick approximation.
:::


## Module 7: Status row

```qml file="rice/lock/LockStatus.qml"
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

RowLayout {
    spacing: 18
    property string layoutName: ""
    Connections { target: Hyprland; function onRawEvent(e) { if (e.name === "activelayout") layoutName = e.parse(2)[1] } }

    RowLayout { visible: Battery.available; spacing: 4
        TIcon { icon: Battery.icon; rotation: 90; color: Battery.low ? Theme.bad : "white"; size: 16 }
        TText { text: Math.round(Battery.percent * 100) + "%"; color: "white" } }
    RowLayout { spacing: 4
        TIcon { icon: Network.icon; color: "white"; size: 16 }
        TText { text: Network.ssid || (Network.wired ? "Ethernet" : "Offline"); color: "white" } }
    RowLayout { visible: parent.layoutName !== ""; spacing: 4
        TIcon { icon: "keyboard"; color: "white"; size: 16 }
        TText { text: parent.parent.layoutName; color: "white" } }
}
```

<!-- ex:## Module 7 -->
::: exercise practice | Network status
Add the Wi-Fi network name to the status row.
:::


## Module 8: Media

```qml file="rice/lock/LockMedia.qml"
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Rectangle {
    visible: Media.active !== null
    implicitWidth: row.implicitWidth + 20
    implicitHeight: 44
    radius: Theme.style === "neon" ? 0 : 22
    color: Qt.rgba(1, 1, 1, 0.12)
    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 10
        ClippingRectangle { implicitWidth: 30; implicitHeight: 30; radius: 15; color: Theme.accent
            Image { anchors.fill: parent; source: Media.active?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(60, 60) } }
        TText { text: Media.active?.trackTitle ?? ""; color: "white"; Layout.maximumWidth: 200 }
        TButton { icon: "skip_previous"; size: 28; onClicked: Media.active.previous() }
        TButton { icon: Media.active?.isPlaying ? "pause" : "play_arrow"; size: 28; onClicked: Media.active.togglePlaying() }
        TButton { icon: "skip_next"; size: 28; onClicked: Media.active.next() }
    }
}
```

> [!NOTE] Privacy
> Media controls on the lock screen are convenient, but anyone at your desk can see what you play. Don't show notification *content* on the lock screen; a count is fine.

<!-- ex:## Module 8 -->
::: exercise practice | Controls only on hover
Hide the media buttons until the media card is hovered, fading them in.
:::


## Assembly: the surface and three layouts

```qml file="rice/lock/LockSurface.qml"
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.services

WlSessionLockSurface {
    id: surface
    required property var lock
    color: Theme.bg

    LockBackground { blur: surface.lock.layout === "minimal" ? 0 : 1.0; dim: surface.lock.layout === "minimal" ? 0.6 : 0.35 }

    // ---------- centered: clock on top, avatar + input in the middle ----------
    ColumnLayout {
        visible: surface.lock.layout === "centered"
        anchors.centerIn: parent
        spacing: 16
        LockClock { Layout.alignment: Qt.AlignHCenter; style: "big"; size: 130 }
        LockGreeting { Layout.alignment: Qt.AlignHCenter }
        Item { implicitHeight: 30 }
        LockAvatar { Layout.alignment: Qt.AlignHCenter; lock: surface.lock }
        LockInput { Layout.alignment: Qt.AlignHCenter; lock: surface.lock }
    }

    // ---------- editorial: huge stacked clock on the left, input bottom-right ----------
    Item {
        visible: surface.lock.layout === "editorial"
        anchors.fill: parent
        LockClock { anchors { left: parent.left; leftMargin: 90; verticalCenter: parent.verticalCenter } style: "stacked"; size: 200 }
        ColumnLayout {
            anchors { right: parent.right; bottom: parent.bottom; margins: 70 }
            spacing: 12
            LockGreeting { Layout.alignment: Qt.AlignRight; showGreeting: false }
            LockInput { Layout.alignment: Qt.AlignRight; lock: surface.lock; fieldWidth: 260 }
        }
    }

    // ---------- minimal: thin clock and the field, nothing else ----------
    ColumnLayout {
        visible: surface.lock.layout === "minimal"
        anchors.centerIn: parent
        spacing: 28
        LockClock { Layout.alignment: Qt.AlignHCenter; style: "thin"; size: 110 }
        LockInput { Layout.alignment: Qt.AlignHCenter; lock: surface.lock; fieldWidth: 220 }
    }

    // ---------- shared bottom row (not in minimal) ----------
    LockStatus {
        visible: surface.lock.layout !== "minimal"
        anchors { left: parent.left; bottom: parent.bottom; margins: 30 }
    }
    LockMedia {
        visible: surface.lock.layout !== "minimal" && Media.active !== null
        anchors { right: parent.right; margins: 30 }
        // in "editorial" the input sits bottom-right, so move media to the top
        anchors.bottom: surface.lock.layout === "editorial" ? undefined : parent.bottom
        anchors.top: surface.lock.layout === "editorial" ? parent.top : undefined
    }
}
```

<div class="preview"><svg width="660" height="170" viewBox="0 0 660 170"><g font-size="10"><g transform="translate(5 5)"><rect width="210" height="140" rx="8" fill="#2a2440"/><text x="105" y="50" fill="#fff" font-size="30" font-weight="900" text-anchor="middle">14:32</text><text x="105" y="66" fill="#ffffffaa" font-size="8" text-anchor="middle">Friday, 21 November</text><circle cx="105" cy="88" r="10" fill="#cba6f7"/><rect x="65" y="104" width="80" height="14" rx="7" fill="#ffffff22" stroke="#cba6f7"/><text x="105" y="160" fill="#a6adc8" text-anchor="middle">centered</text></g><g transform="translate(225 5)"><rect width="210" height="140" rx="8" fill="#1e2a45"/><text x="20" y="62" fill="#cba6f7" font-size="40" font-weight="900">14</text><text x="20" y="100" fill="#fff" font-size="40" font-weight="900">32</text><rect x="120" y="114" width="76" height="14" rx="7" fill="#ffffff22" stroke="#cba6f7"/><text x="105" y="160" fill="#a6adc8" text-anchor="middle">editorial</text></g><g transform="translate(445 5)"><rect width="210" height="140" rx="8" fill="#111118"/><text x="105" y="66" fill="#fff" font-size="22" font-weight="300" letter-spacing="4" text-anchor="middle">14 : 32</text><rect x="70" y="86" width="70" height="12" rx="6" fill="#ffffff14" stroke="#ffffff44"/><text x="105" y="160" fill="#a6adc8" text-anchor="middle">minimal</text></g></g></svg></div>

<!-- ex:## Assembly -->
::: exercise challenge | A fourth layout
Add a `"split"` layout: clock and date on the left half, avatar and input on the right half.
--- hint
A `RowLayout` filling the surface with two `Item`s of equal `Layout.fillWidth`.
:::


## Polish checklist

- [ ] The field has focus immediately (no clicking needed).
- [ ] Wrong password: red border, shake, clear field, hint after repeated failures.
- [ ] A visible "checking" state (spinner or text) while PAM runs.
- [ ] Readable on any wallpaper: dim + shadow on text.
- [ ] Multi-monitor: same state on all screens; consider showing the input only on the focused monitor.
- [ ] Fast: decode the wallpaper at half size; no heavy effects beyond one blur.
- [ ] No sensitive content: notification counts only, no bodies.
- [ ] Auto-unlock safety timer removed once tested.

<!-- ex:## Polish checklist -->
## Practice

::: exercise project | Your lock screen
Design a lock screen for your own rice: choose a layout, change at least two modules, and test it with wrong and correct passwords **while the safety timer is still on**.
:::

