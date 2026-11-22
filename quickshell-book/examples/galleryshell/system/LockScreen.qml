import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Layouts
import qs.services

// A real lock screen: ext-session-lock (the compositor guarantees nothing else is shown)
// and PAM (your normal login password). Lock with: qs ipc call session lock
Scope {
    id: root
    property string password: ""
    property string error: ""
    property bool busy: false

    function tryUnlock(): void {
        if (busy || password === "") return
        busy = true; error = ""
        pam.start()
    }

    // `loginctl lock-session` (used by power menus, hypridle, `systemctl suspend` hooks…) sends
    // logind's Lock signal. Listening for it makes all of those lock with this screen.
    Process {
        running: true
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1"]
        stdout: SplitParser {
            onRead: line => { if (line.includes("org.freedesktop.login1.Session.Lock ")) Session.locked = true }
        }
    }

    PamContext {
        id: pam
        // PAM asks for the password; answer with what was typed
        onPamMessage: if (responseRequired) respond(root.password)
        onCompleted: result => {
            root.busy = false
            if (result === PamResult.Success) { root.password = ""; Session.locked = false }
            else { root.password = ""; root.error = "Wrong password" }
        }
    }

    WlSessionLock {
        locked: Session.locked

        // one surface per screen
        WlSessionLockSurface {
            color: "#11111b"

            SystemClock { id: clock; precision: SystemClock.Seconds }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 14

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(clock.date, "hh:mm")
                    color: "#cdd6f4"; font.pixelSize: 96; font.bold: true
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: "#a6adc8"; font.pixelSize: 18
                }
                Rectangle {
                    id: field
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 30
                    implicitWidth: 300; implicitHeight: 48; radius: 24
                    color: "#1e1e2e"
                    border.color: root.error ? "#f38ba8" : input.activeFocus ? "#cba6f7" : "#313244"; border.width: 2

                    // shake on a wrong password
                    transform: Translate { id: shake }
                    SequentialAnimation {
                        id: shakeAnim
                        loops: 2
                        NumberAnimation { target: shake; property: "x"; to: -10; duration: 50 }
                        NumberAnimation { target: shake; property: "x"; to: 10; duration: 100 }
                        NumberAnimation { target: shake; property: "x"; to: 0; duration: 50 }
                    }
                    Connections { target: root; function onErrorChanged(): void { if (root.error) shakeAnim.restart() } }

                    TextInput {
                        id: input
                        anchors { fill: parent; leftMargin: 20; rightMargin: 20 }
                        verticalAlignment: TextInput.AlignVCenter
                        horizontalAlignment: TextInput.AlignHCenter
                        echoMode: TextInput.Password; passwordCharacter: "●"
                        color: "#cdd6f4"; font.pixelSize: 16
                        focus: true
                        enabled: !root.busy
                        text: root.password
                        onTextEdited: { root.password = text; root.error = "" }
                        Keys.onReturnPressed: root.tryUnlock()
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: input.text === ""
                        text: root.busy ? "Checking…" : "Password"
                        color: "#6c7086"; font.pixelSize: 14
                    }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.error
                    color: "#f38ba8"; font.pixelSize: 13
                }
            }
        }
    }
}
