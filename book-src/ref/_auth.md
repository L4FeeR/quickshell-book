=== PamContext
@@@ intro
Runs a **PAM authentication** conversation: check a password (or fingerprint, or anything your PAM config allows) for a user. Used by lock screens.

@@@ example Example: every property, function and signal
```qml
import Quickshell
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FloatingWindow {
    implicitWidth: 400; implicitHeight: 260
    color: "#1e1e2e"

    PamContext {
        id: pam
        config: "login"                          // file in configDirectory
        configDirectory: "/etc/pam.d"            // default
        user: ""                                 // "" = current user; can't change while active

        onPamMessage: {                          // after message/responseRequired/… update
            console.log("PAM says:", message, "error?", messageIsError)
            if (responseRequired) respond(pw.text)           // responseVisible: echo or hide?
        }
        onCompleted: result => status.text = result === PamResult.Success ? "✓ success" : "✗ " + PamResult.toString(result)
        onError: err => status.text = "error: " + PamError.toString(err)
    }

    ColumnLayout {
        anchors { fill: parent; margins: 20 }
        TextField { id: pw; echoMode: TextInput.Password; placeholderText: "password"; onAccepted: pam.start(); enabled: !pam.active }
        Button { text: pam.active ? "Cancel" : "Check"; onClicked: pam.active ? pam.abort() : pam.start() }   // start() returns bool
        Text { id: status; color: "white" }
        Text { color: "#a6adc8"; text: `active ${pam.active} · needs response ${pam.responseRequired} · visible ${pam.responseVisible}` }
        Text { color: pam.messageIsError ? "#f38ba8" : "#a6adc8"; text: pam.message }
    }
}
```

@@@ member config
Only the `auth` stack is used. Write your own config (e.g. fingerprint OR password) in a folder and point `configDirectory` to it. The module overview explains PAM config syntax.

@@@ see
[[ch:57-proj-lock]] · [[PamResult]] · [[PamError]]

=== PolkitAgent
@@@ intro
Registers your shell as the **polkit authentication agent**, the program that shows "Authentication required" dialogs. When a request arrives, `flow` holds an [[AuthFlow]] describing it.

@@@ example Example
```qml
import Quickshell
import Quickshell.Services.Polkit
import QtQuick

Scope {
    PolkitAgent {
        id: agent
        path: ""                                         // D-Bus path; default /org/quickshell/Polkit
        onAuthenticationRequestStarted: console.log("request:", flow.message, "action:", flow.actionId)
    }
    // agent.isRegistered: did registration succeed (another agent may already be running)
    // agent.isActive: a request is in progress → show your dialog bound to agent.flow
}
```

@@@ see
[[ch:63-proj-polkit]] · [[AuthFlow]]

=== AuthFlow
@@@ intro
One polkit authentication request, available as [[PolkitAgent.flow]] while active. Display its message, collect the password, `submit()` it, or cancel.

@@@ example Example: every property, function and signal
```qml
ColumnLayout {
    required property AuthFlow flow
    Image { source: Quickshell.iconPath(flow.iconName || "dialog-password") }
    Text { text: flow.message }                                   // e.g. "Authentication is required to mount the disk"
    Text { text: "action: " + flow.actionId + " · cookie: " + flow.cookie; color: "grey" }
    ComboBox {                                                    // users/groups allowed to authenticate
        model: flow.identities.map(i => String(i))
        onActivated: i => flow.selectedIdentity = flow.identities[i]   // restarts the conversation
    }
    TextField {
        enabled: flow.isResponseRequired
        placeholderText: flow.inputPrompt                         // e.g. "Password:"
        echoMode: flow.responseVisible ? TextInput.Normal : TextInput.Password
        onAccepted: flow.submit(text)
    }
    Text { text: flow.supplementaryMessage; color: flow.supplementaryIsError ? "red" : "grey" }
    Text { text: `completed ${flow.isCompleted} success ${flow.isSuccessful} cancelled ${flow.isCancelled} failed-once ${flow.failed}` }
    Button { text: "Cancel"; onClicked: flow.cancelAuthenticationRequest() }
    Connections {
        target: flow
        function onAuthenticationSucceeded() { console.log("ok") }
        function onAuthenticationFailed() { console.log("wrong password; a new attempt starts automatically") }
        function onAuthenticationRequestCancelled() { console.log("cancelled by polkit") }
    }
}
```

=== Greetd
@@@ intro
Talks to **greetd** so a Quickshell config can be a graphical **login screen**. Create a session for a user, answer authentication messages, then launch their desktop.

@@@ example Example: every property, function and signal
```qml
import Quickshell
import Quickshell.Services.Greetd
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FloatingWindow {
    color: "#11111b"
    ColumnLayout {
        anchors.centerIn: parent
        Text { color: "white"; text: "greetd available: " + Greetd.available + " · state: " + GreetdState.toString(Greetd.state)
                                     + " · user: " + Greetd.user }
        TextField { id: user; placeholderText: "user" }
        TextField { id: pw; placeholderText: "password"; echoMode: TextInput.Password; onAccepted: Greetd.createSession(user.text) }
        Button { text: "Log in"; onClicked: Greetd.createSession(user.text) }
        Button { text: "Cancel"; onClicked: Greetd.cancelSession() }
        Text { id: msg; color: "#f38ba8" }
    }
    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (error) msg.text = message                    // recoverable error (e.g. fingerprint misread)
            if (responseRequired) Greetd.respond(pw.text)    // echoResponse: show input in clear text?
        }
        function onAuthFailure(message) { msg.text = message || "Login failed" }
        function onReadyToLaunch() {
            Greetd.launch(["Hyprland"])                      // also: launch(cmd, ["VAR=value"]), launch(cmd, env, quit)
        }
        function onLaunched() { console.log("greetd accepted the session") }
        function onError(err) { msg.text = err }
    }
}
```

@@@ member launch
Quickshell exits after launching (unless `quit` is false). Run animations **before** calling `launch`, because greetd expects the greeter to exit quickly.

@@@ see
[[ch:64-proj-greeter]]
