# Project: Polkit Authentication Agent

When you run `pkexec`, mount a drive, or change a system setting in an app, polkit asks an **authentication agent** to show a password dialog. Instead of polkit-gnome or hyprpolkitagent, Quickshell's [[PolkitAgent]] lets you draw that dialog in your own style.

## How a polkit request flows

1. An app asks polkit to authorize an action (e.g. `org.freedesktop.udisks2.filesystem-mount`).
2. polkit calls your agent. [[PolkitAgent]] emits `authenticationRequestStarted` and exposes the request as `flow` ([[AuthFlow]]).
3. `flow.message` describes the action; `flow.inputPrompt` / `isResponseRequired` ask for input.
4. You call `flow.submit(password)`. On failure, `authenticationFailed` fires and a new attempt starts automatically; on success, `authenticationSucceeded`.
5. `flow.cancelAuthenticationRequest()` cancels from your side; `authenticationRequestCancelled` means polkit cancelled.

> [!WARN] One agent at a time
> Stop other agents first (`pkill -f polkit-gnome; pkill hyprpolkitagent`) and remove them from autostart. `agent.isRegistered` tells you if registration succeeded.

## The agent and dialog

```qml file="modules/polkit/Polkit.qml"
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Polkit
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.widgets

Scope {
    id: root

    PolkitAgent {
        id: agent
        onIsRegisteredChanged: console.info("polkit agent registered:", isRegistered)
    }

    LazyLoader {
        active: agent.isActive && agent.flow !== null

        PanelWindow {
            id: win
            readonly property AuthFlow flow: agent.flow
            screen: Quickshell.screens.find(s => s.name === GlobalStates.activeScreen) ?? null
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: Colors.alpha("#000000", 0.5)
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell:polkit"

            Connections {
                target: win.flow
                function onAuthenticationFailed() { pw.text = ""; shake.restart() }
            }

            StyledRect {
                anchors.centerIn: parent
                width: 420
                height: col.implicitHeight + 40
                level: 3
                color: Colors.surface

                transform: Translate { id: tr }
                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: tr; property: "x"; to: -12; duration: 50 }
                    NumberAnimation { target: tr; property: "x"; to: 12; duration: 100 }
                    NumberAnimation { target: tr; property: "x"; to: 0; duration: 50 }
                }

                ColumnLayout {
                    id: col
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
                    spacing: 14

                    RowLayout {
                        spacing: 12
                        IconImage {
                            implicitSize: 40
                            source: Quickshell.iconPath(win.flow?.iconName || "dialog-password", "dialog-password")
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            StyledText { text: "Authentication required"; font.bold: true; font.pixelSize: Appearance.font.size.large }
                            StyledText { text: win.flow?.actionId ?? ""; color: Colors.outline; font.pixelSize: Appearance.font.size.tiny; Layout.fillWidth: true }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: win.flow?.message ?? ""
                        wrapMode: Text.Wrap
                        elide: Text.ElideNone
                    }

                    // choose which identity (user/admin) to authenticate as
                    ComboBox {
                        Layout.fillWidth: true
                        visible: (win.flow?.identities.length ?? 0) > 1
                        model: (win.flow?.identities ?? []).map(i => String(i))
                        onActivated: idx => win.flow.selectedIdentity = win.flow.identities[idx]
                    }

                    TextField {
                        id: pw
                        Layout.fillWidth: true
                        placeholderText: win.flow?.inputPrompt || "Password"
                        echoMode: win.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                        enabled: win.flow?.isResponseRequired ?? false
                        focus: true
                        onAccepted: if (text) win.flow.submit(text)
                        Keys.onEscapePressed: win.flow.cancelAuthenticationRequest()
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: win.flow?.failed && !win.flow?.supplementaryMessage ? "Authentication failed, try again"
                                                                                  : (win.flow?.supplementaryMessage ?? "")
                        color: win.flow?.supplementaryIsError || win.flow?.failed ? Colors.error : Colors.onSurfaceVariant
                        wrapMode: Text.Wrap
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: 8
                        Button { text: "Cancel"; onClicked: win.flow.cancelAuthenticationRequest() }
                        Button { text: "Authenticate"; highlighted: true; enabled: pw.text !== ""; onClicked: win.flow.submit(pw.text) }
                    }
                }
            }
        }
    }
}
```

Add `Polkit {}` to `shell.qml` (it must be created at startup to register).

## Test it

```bash
pkexec echo "it works"          # should show your dialog
```

> [!NOTE] Fingerprint
> polkit uses the PAM stack in `/etc/pam.d/polkit-1`. If that includes `pam_fprintd.so`, `supplementaryMessage` will say something like "Swipe your finger" and you may not need to type anything.

> [!TRY] Exercises
> 1. Show the requesting program's details (inspect `flow` properties in the reference).
> 2. Blur the background with a layerrule.
> 3. Add a short success animation before the window closes.
