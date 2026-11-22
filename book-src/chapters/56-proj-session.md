# Project: Power Menu

A fullscreen session screen: dimmed (optionally blurred) background, big buttons for Lock, Logout, Suspend, Hibernate, Reboot and Shutdown, keyboard navigation, single-letter shortcuts, and a confirmation step for destructive actions.

```qml file="modules/session/Session.qml"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Scope {
    IpcHandler { target: "session"; function toggle(): void { GlobalStates.toggle("session") } }

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
            WlrLayershell.namespace: "quickshell:session"       // layerrule = blur, quickshell:session

            readonly property var actions: [
                { key: "l", icon: "lock",               label: "Lock",      confirm: false, run: () => GlobalStates.locked = true },
                { key: "e", icon: "logout",             label: "Log out",   confirm: true,  run: () => Quickshell.execDetached(["loginctl", "terminate-user", Quickshell.env("USER")]) },
                { key: "s", icon: "bedtime",            label: "Suspend",   confirm: false, run: () => Quickshell.execDetached(["systemctl", "suspend"]) },
                { key: "h", icon: "downloading",        label: "Hibernate", confirm: true,  run: () => Quickshell.execDetached(["systemctl", "hibernate"]) },
                { key: "r", icon: "restart_alt",        label: "Reboot",    confirm: true,  run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
                { key: "p", icon: "power_settings_new", label: "Shut down", confirm: true,  run: () => Quickshell.execDetached(["systemctl", "poweroff"]) }
            ]
            property int current: 0
            property int confirming: -1                 // index awaiting confirmation

            function trigger(i: int): void {
                const a = actions[i]
                if (a.confirm && confirming !== i) { confirming = i; current = i; return }
                GlobalStates.sessionOpen = false
                a.run()
            }

            // dim background, click to close
            Rectangle {
                anchors.fill: parent
                color: Colors.alpha("#000000", 0.55)
                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { Anim {} }
                MouseArea { anchors.fill: parent; onClicked: GlobalStates.sessionOpen = false }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 28

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: win.confirming >= 0 ? `Press again to ${win.actions[win.confirming].label.toLowerCase()}`
                                              : "Goodbye, " + Quickshell.env("USER")
                    color: "white"
                    font.pixelSize: Appearance.font.size.title
                }

                RowLayout {
                    id: buttons
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 18
                    focus: true

                    Keys.onEscapePressed: win.confirming >= 0 ? win.confirming = -1 : GlobalStates.sessionOpen = false
                    Keys.onLeftPressed: { win.current = (win.current + win.actions.length - 1) % win.actions.length; win.confirming = -1 }
                    Keys.onRightPressed: { win.current = (win.current + 1) % win.actions.length; win.confirming = -1 }
                    Keys.onReturnPressed: win.trigger(win.current)
                    Keys.onPressed: e => {
                        const i = win.actions.findIndex(a => a.key === e.text.toLowerCase())
                        if (i >= 0) { win.trigger(i); e.accepted = true }
                    }

                    Repeater {
                        model: win.actions
                        ColumnLayout {
                            id: btn
                            required property var modelData
                            required property int index
                            readonly property bool selected: win.current === index
                            readonly property bool danger: win.confirming === index
                            spacing: 10

                            // staggered entrance
                            opacity: 0
                            transform: Translate { id: tr; y: 30 }
                            Component.onCompleted: enter.start()
                            SequentialAnimation {
                                id: enter
                                PauseAnimation { duration: btn.index * 40 }
                                ParallelAnimation {
                                    NumberAnimation { target: btn; property: "opacity"; to: 1; duration: 250 }
                                    NumberAnimation { target: tr; property: "y"; to: 0; duration: 350; easing.type: Easing.OutCubic }
                                }
                            }

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: 104; implicitHeight: 104
                                radius: btn.selected ? Appearance.rounding.large : 52
                                color: btn.danger ? Colors.error : btn.selected ? Colors.primary : Colors.surfaceContainerHigh
                                scale: btn.selected ? 1.06 : 1
                                Behavior on radius { Anim {} }
                                Behavior on color { CAnim {} }
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    icon: btn.modelData.icon
                                    size: 40
                                    fill: btn.selected ? 1 : 0
                                    color: btn.danger ? Colors.onError : btn.selected ? Colors.onPrimary : Colors.onSurface
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: if (win.confirming !== btn.index) { win.current = btn.index; win.confirming = -1 }
                                    onClicked: win.trigger(btn.index)
                                }
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: btn.modelData.label
                                color: "white"
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: btn.modelData.key.toUpperCase()
                                color: "#99ffffff"
                                font.family: Appearance.font.mono
                                font.pixelSize: Appearance.font.size.small
                            }
                        }
                    }
                }
            }
        }
    }
}
```

## Logout per compositor

| Compositor | Command |
|---|---|
| Hyprland | `hyprctl dispatch exit` (or `Hyprland.dispatch("exit")`) |
| Sway | `swaymsg exit` |
| niri | `niri msg action quit --skip-confirmation` |
| systemd-logind (any) | `loginctl terminate-user $USER` |
| UWSM sessions | `uwsm stop` |

## Blur behind

```ini file="hyprland.conf"
layerrule = blur, quickshell:session
layerrule = ignorealpha 0, quickshell:session
```

## Practice

::: exercise warm | Uptime and battery
Add an uptime line and the battery level under the greeting.
--- hint
Use a `Process` running `uptime -p` when the menu opens; battery from `UPower.displayDevice.percentage`.
:::

::: exercise practice | Firmware restart
Add a "Restart to firmware" action.
--- solution
```js
Quickshell.execDetached(["systemctl", "reboot", "--firmware-setup"])
```
:::

::: exercise challenge | Auto-confirm countdown
Add a 10-second countdown that auto-confirms shutdown, cancelled by any key.
--- solution
```qml
property int left: 10
property bool counting: true
Timer { running: GlobalStates.sessionOpen && counting; interval: 1000; repeat: true
        onTriggered: if (--left === 0) Quickshell.execDetached(["systemctl", "poweroff"]) }
Keys.onPressed: counting = false            // any key cancels; reset both when the menu opens
```
Show `"Shutting down in " + left + " s"` while it runs.
:::
