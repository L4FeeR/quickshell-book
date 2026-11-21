# Project: Lock Screen

A real, secure lock screen using the Wayland **ext-session-lock** protocol through [[WlSessionLock]], with PAM authentication via [[PamContext]]: a blurred wallpaper, big clock, avatar, password field with error shake, caps-lock warning, fingerprint support, and media controls.

> [!DANGER] Develop safely
> A lock screen can lock you out. While developing:
> 1. Keep the **auto-unlock safety timer** in the code below until you trust your screen.
> 2. Know your escape hatch: switch to a TTY (<kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>F3</kbd>), log in, run `pkill -f "qs -c myshell"`. With ext-session-lock the compositor keeps the session locked (it shows a solid color) until a new locker takes over; on Hyprland run `hyprctl --instance 0 'keyword misc:allow_session_lock_restore 1'` then restart your shell, or use `hyprlock` as a fallback.
> 3. Never set `locked = false` anywhere except after a successful PAM result.

## How session lock works

- While [[WlSessionLock.locked]] is true, the compositor shows **only** your lock surfaces and sends input only to them. No other window, no keybinds.
- A [[WlSessionLockSurface]] is created **automatically for every screen** from the `surface` component.
- [[WlSessionLock.secure]] becomes true once the compositor confirms every screen is covered.
- If Quickshell crashes while locked, the session **stays locked** (that's the security guarantee).

## The lock controller

```qml file="modules/lock/Lock.qml"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import qs.services

Scope {
    id: root

    // shared state for all screens' surfaces
    property string password: ""
    property bool busy: false
    property string error: ""
    property string pamMessage: ""
    property int failures: 0

    IpcHandler { target: "lock"; function lock(): void { GlobalStates.locked = true } }

    function submit(): void {
        if (busy || password === "") return
        error = ""
        busy = true
        pam.start()
    }

    PamContext {
        id: pam
        config: "login"                     // see "fingerprint" below for a custom config
        onPamMessage: {
            if (responseRequired) {
                respond(root.password)
            } else {
                root.pamMessage = message      // e.g. "Place your finger on the sensor"
            }
        }
        onCompleted: result => {
            root.busy = false
            root.password = ""
            if (result === PamResult.Success) {
                root.failures = 0
                root.error = ""
                GlobalStates.locked = false
            } else {
                root.failures++
                root.error = result === PamResult.MaxTries ? "Too many attempts" : "Incorrect password"
            }
        }
        onError: err => { root.busy = false; root.error = "Authentication error: " + PamError.toString(err) }
    }

    WlSessionLock {
        id: lock
        locked: GlobalStates.locked
        surface: Component { LockSurface { lockScope: root } }
    }

    // ⚠ SAFETY NET while developing: unlock after 60 s. DELETE THIS when you trust it.
    Timer { running: GlobalStates.locked; interval: 60000; onTriggered: GlobalStates.locked = false }
}
```

## The per-screen surface

```qml file="modules/lock/LockSurface.qml"
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.widgets

WlSessionLockSurface {
    id: surface
    required property var lockScope
    color: "black"

    // background: blurred, dimmed wallpaper
    Image {
        id: wall
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/.cache/myshell/wallpaper"
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(surface.width / 2, surface.height / 2)   // blurred anyway: decode small
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: wall
        source: wall
        blurEnabled: true; blur: 1.0; blurMax: 64
        brightness: -0.3
        opacity: wall.status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }

    // everything fades/slides in
    Item {
        anchors.fill: parent
        opacity: 0
        Component.onCompleted: opacity = 1
        Behavior on opacity { NumberAnimation { duration: 400 } }

        ColumnLayout {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -40
            spacing: 6

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(Time.now, "hh:mm")
                color: "white"
                font.pixelSize: 120
                font.weight: Font.Black
                font.features: ({ "tnum": 1 })
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(Time.now, "dddd, d MMMM")
                color: "#ddffffff"
                font.pixelSize: Appearance.font.size.title
            }

            Item { implicitHeight: 40 }

            ClippingRectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 96; implicitHeight: 96; radius: 48
                color: Colors.primaryContainer
                Image {
                    anchors.fill: parent
                    source: "file://" + Quickshell.env("HOME") + "/.face"
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(192, 192)
                }
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Quickshell.env("USER")
                color: "white"
                font.pixelSize: Appearance.font.size.large
            }

            // password field
            Rectangle {
                id: field
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 12
                implicitWidth: 320
                implicitHeight: 52
                radius: 26
                color: Qt.rgba(1, 1, 1, 0.12)
                border.width: 2
                border.color: surface.lockScope.error ? Colors.error
                            : input.activeFocus ? Colors.primary : "transparent"
                Behavior on border.color { CAnim {} }

                TextInput {
                    id: input
                    anchors { fill: parent; leftMargin: 24; rightMargin: 52 }
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    color: "white"
                    font.pixelSize: 20
                    focus: true
                    enabled: !surface.lockScope.busy
                    text: surface.lockScope.password
                    onTextChanged: {
                        surface.lockScope.password = text            // shared across screens
                        if (text !== "") surface.lockScope.error = ""
                    }
                    Keys.onReturnPressed: surface.lockScope.submit()
                    Keys.onEnterPressed: surface.lockScope.submit()
                    Keys.onEscapePressed: surface.lockScope.password = ""
                    Keys.onPressed: e => capsHint.check(e)

                    StyledText {
                        anchors.centerIn: parent
                        visible: !parent.text
                        text: surface.lockScope.busy ? "Checking…" : "Enter password"
                        color: "#99ffffff"
                    }
                }
                MaterialIcon {                                       // submit / spinner
                    anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                    icon: surface.lockScope.busy ? "progress_activity" : "arrow_forward"
                    color: "white"
                    RotationAnimation on rotation {
                        running: surface.lockScope.busy; from: 0; to: 360; duration: 900; loops: Animation.Infinite
                        onStopped: parent.rotation = 0
                    }
                    TapHandler { onTapped: surface.lockScope.submit() }
                }

                // error shake
                transform: Translate { id: shakeTr }
                SequentialAnimation {
                    id: shake
                    loops: 2
                    NumberAnimation { target: shakeTr; property: "x"; to: -10; duration: 40 }
                    NumberAnimation { target: shakeTr; property: "x"; to: 10; duration: 80 }
                    NumberAnimation { target: shakeTr; property: "x"; to: 0; duration: 40 }
                }
                Connections {
                    target: surface.lockScope
                    function onErrorChanged() { if (surface.lockScope.error) shake.restart() }
                }
            }

            StyledText {
                id: capsHint
                Layout.alignment: Qt.AlignHCenter
                property bool caps: false
                function check(e) { caps = e.text !== "" && e.text !== e.text.toLowerCase() && !(e.modifiers & Qt.ShiftModifier) }
                visible: caps
                text: "Caps Lock is on"
                color: Colors.tertiary
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                visible: text !== ""
                text: surface.lockScope.error || surface.lockScope.pamMessage
                color: surface.lockScope.error ? Colors.error : "#ddffffff"
            }
        }

        // bottom bar: battery + media
        RowLayout {
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 32 }
            spacing: 20
            RowLayout {
                visible: Battery.available
                MaterialIcon { icon: Battery.icon; rotation: 90; color: "white" }
                StyledText { text: Math.round(Battery.percent * 100) + "%"; color: "white" }
            }
            RowLayout {
                visible: Media.active !== null
                spacing: 6
                IconButton { icon: "skip_previous"; onClicked: Media.active.previous() }
                IconButton { icon: Media.active?.isPlaying ? "pause" : "play_arrow"; onClicked: Media.active.togglePlaying() }
                IconButton { icon: "skip_next"; onClicked: Media.active.next() }
                StyledText { text: Media.active?.trackTitle ?? ""; color: "white"; Layout.maximumWidth: 260 }
            }
        }
    }
}
```

> [!NOTE] Caps-lock detection
> Qt doesn't expose the caps-lock state directly; the heuristic above checks typed letters. For an exact indicator read `/sys/class/leds/*capslock/brightness` with FileView.

## Fingerprint (fprintd)

Create a PAM config that accepts fingerprint **or** password, and point `PamContext` at it:

```text file="~/.config/quickshell/myshell/pam/fprint-or-password"
auth sufficient pam_fprintd.so
auth required pam_unix.so
```

```qml
PamContext {
    configDirectory: Quickshell.shellPath("pam")
    config: "fprint-or-password"
}
```

Start an attempt as soon as the screen locks (`onLockedChanged: if (locked) pam.start()`) so the fingerprint reader is armed; `pamMessage` shows "Place your finger…".

## Locking: idle, lid, sleep

```qml
// lock after 5 min idle (see Chapter 46)
IdleMonitor { timeout: 300; respectInhibitors: true; onIsIdleChanged: if (isIdle) GlobalStates.locked = true }
```

```ini file="hypridle.conf (if you prefer hypridle)"
general {
    lock_cmd = qs -c myshell ipc call lock lock
    before_sleep_cmd = qs -c myshell ipc call lock lock
}
```

> [!TRY] Exercises
> 1. Remove the safety timer only after testing wrong passwords, correct passwords and multiple monitors.
> 2. Show the number of unread notifications on the lock screen (but not their content).
> 3. Add a "Sleep" button that runs `systemctl suspend`.
