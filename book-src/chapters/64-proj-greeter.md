# Project: Login Greeter

Your rice can start at the **login screen**. With **greetd** (a minimal login daemon) and Quickshell's [[Greetd]] service, a Quickshell config becomes your graphical greeter: user picker, password field, session chooser, clock and wallpaper.

> [!DANGER] Test in a VM or keep a fallback
> A broken greeter means you can't log in graphically. Keep a TTY login available (<kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>F2</kbd>) and know how to switch greetd back to `tuigreet` in `/etc/greetd/config.toml`.

## How greetd works

1. greetd runs a **greeter** program as the `greeter` user, inside a minimal compositor (e.g. `cage`, or Hyprland with a tiny config).
2. The greeter talks to greetd over a socket: "create session for user X" → greetd asks auth questions (password, OTP) → the greeter answers.
3. When authenticated, the greeter tells greetd which command to run (e.g. `Hyprland`), then exits.

Quickshell's [[Greetd]] singleton wraps this protocol: `createSession(user)`, the `authMessage(message, error, responseRequired, echoResponse)` signal, `respond(text)`, `readyToLaunch`, `launch(command)`, `authFailure`, `state`.

## Install

```bash
sudo pacman -S greetd cage
sudo mkdir -p /etc/greetd/quickshell
sudo cp -r ~/.config/quickshell/greeter/* /etc/greetd/quickshell/    # the config below
```

```toml file="/etc/greetd/config.toml"
[terminal]
vt = 1

[default_session]
command = "cage -s -- qs -p /etc/greetd/quickshell"
user = "greeter"
```

```bash
sudo systemctl disable --now sddm gdm lightdm 2>/dev/null
sudo systemctl enable greetd
```

## The greeter config

```qml file="/etc/greetd/quickshell/shell.qml"
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
    id: root
    property string user: users.length ? users[0] : ""
    property var users: []
    property var sessions: [{ name: "Hyprland", exec: ["Hyprland"] }, { name: "niri", exec: ["niri-session"] },
                            { name: "Sway", exec: ["sway"] }]
    property int sessionIndex: 0
    property string error: ""
    property bool busy: false

    // list normal users (uid >= 1000) from /etc/passwd
    FileView {
        path: "/etc/passwd"
        onLoaded: root.users = text().split("\n").map(l => l.split(":"))
                    .filter(p => parseInt(p[2]) >= 1000 && parseInt(p[2]) < 60000 && !p[6]?.endsWith("nologin"))
                    .map(p => p[0])
    }

    function login(): void {
        error = ""
        busy = true
        Greetd.createSession(user)
    }

    Connections {
        target: Greetd
        function onAuthMessage(message, isError, responseRequired, echoResponse) {
            if (isError) root.error = message            // recoverable, e.g. fingerprint misread
            else if (!responseRequired) root.error = ""
            if (responseRequired) Greetd.respond(pw.text) // only respond when asked
        }
        function onAuthFailure(message) {
            root.busy = false
            root.error = message || "Login failed"
            pw.text = ""
        }
        function onReadyToLaunch() {
            Greetd.launch(root.sessions[root.sessionIndex].exec)
        }
        function onError(err) { root.busy = false; root.error = err }
    }

    FloatingWindow {                                    // cage shows it fullscreen
        color: "#11111b"
        visible: true

        Image {
            anchors.fill: parent
            source: "file:///etc/greetd/quickshell/wallpaper.jpg"
            fillMode: Image.PreserveAspectCrop
            opacity: 0.5
        }

        SystemClock { id: clock; precision: SystemClock.Minutes }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 14
            width: 340

            Text { Layout.alignment: Qt.AlignHCenter; text: Qt.formatTime(clock.date, "hh:mm"); color: "white"; font.pixelSize: 96; font.bold: true }
            Text { Layout.alignment: Qt.AlignHCenter; text: Qt.formatDate(clock.date, "dddd, d MMMM"); color: "#ccffffff"; font.pixelSize: 18 }

            ComboBox {
                Layout.fillWidth: true
                model: root.users
                onActivated: i => root.user = root.users[i]
            }
            TextField {
                id: pw
                Layout.fillWidth: true
                placeholderText: "Password"
                echoMode: TextInput.Password
                focus: true
                enabled: !root.busy
                onAccepted: root.login()
            }
            ComboBox {
                Layout.fillWidth: true
                model: root.sessions.map(s => s.name)
                onActivated: i => root.sessionIndex = i
            }
            Button { Layout.fillWidth: true; text: root.busy ? "Logging in…" : "Log in"; enabled: !root.busy; onClicked: root.login() }
            Text { Layout.alignment: Qt.AlignHCenter; visible: root.error !== ""; text: root.error; color: "#f38ba8" }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Button { text: "Reboot"; onClicked: Quickshell.execDetached(["systemctl", "reboot"]) }
                Button { text: "Shut down"; onClicked: Quickshell.execDetached(["systemctl", "poweroff"]) }
            }
        }
    }
}
```

## Notes

- The greeter runs as the `greeter` user: it can't read your home folder. Put assets in `/etc/greetd/quickshell/`.
- Remember the last user/session by writing a file the greeter can access (e.g. `/var/cache/greetd/`, owned by `greeter`).
- [[Greetd.available]] is false when not started by greetd, useful for testing the UI as a normal user (`qs -p /etc/greetd/quickshell`) without logging in for real.
- `launch(command, environment, quit)` lets you pass extra environment variables such as `XDG_SESSION_TYPE=wayland`.

## Practice

::: exercise warm | Avatars
Show user avatars from `/var/lib/AccountsService/icons/<user>`.
:::

::: exercise practice | Read sessions
Read available sessions from `/usr/share/wayland-sessions/*.desktop` instead of hard-coding them.
--- solution
```qml
Process { running: true; command: ["sh", "-c", "grep -h '^Exec=\\|^Name=' /usr/share/wayland-sessions/*.desktop"]
    stdout: StdioCollector { onStreamFinished: { /* pair Name= and Exec= lines */ } } }
```
:::

::: exercise challenge | Shared theme
Theme the greeter with the same colors as your shell by copying your `colors.json` somewhere the greeter user can read when the wallpaper changes.
:::
