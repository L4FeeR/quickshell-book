import QtQuick

// The password field: dots while typing, an eye button to show the text,
// a Caps Lock warning, a "checking…" state, and a shake on a wrong password.
// Enter emits `submitted(password)`.
Item {
    id: root
    required property var theme
    property bool capsLock: false
    property bool busy: false
    property string error: ""
    readonly property alias text: input.text
    signal submitted(string password)

    function fail(message) { error = message; busy = false; input.text = ""; shake.restart(); input.forceActiveFocus(); }
    function focusField() { input.forceActiveFocus(); }

    implicitWidth: 340
    implicitHeight: box.height + hints.implicitHeight + 10

    Rectangle {
        id: box
        width: parent.width
        height: 50
        radius: 25
        color: Qt.alpha(root.theme.base, 0.85)
        border.width: 2
        border.color: root.error ? root.theme.error : input.activeFocus ? root.theme.accent : root.theme.border
        Behavior on border.color { ColorAnimation { duration: 150 } }

        // the shake: move the box left and right twice
        transform: Translate { id: offset }
        SequentialAnimation {
            id: shake
            loops: 2
            NumberAnimation { target: offset; property: "x"; to: -10; duration: 50 }
            NumberAnimation { target: offset; property: "x"; to: 10; duration: 100 }
            NumberAnimation { target: offset; property: "x"; to: 0; duration: 50 }
        }

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 52
            verticalAlignment: TextInput.AlignVCenter
            echoMode: reveal.shown ? TextInput.Normal : TextInput.Password
            passwordCharacter: "●"
            color: root.theme.text
            selectionColor: root.theme.accent
            font.family: root.theme.font
            font.pixelSize: 16
            focus: true
            enabled: !root.busy
            clip: true
            onTextEdited: root.error = ""
            onAccepted: if (text !== "") { root.busy = true; root.submitted(text); }
        }
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: root.busy ? "Logging in…" : "Password"
            color: root.theme.muted
            font.family: root.theme.font
            font.pixelSize: 16
        }

        // show / hide the password
        Text {
            id: reveal
            property bool shown: false
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: shown ? "hide" : "show"
            color: revealMouse.containsMouse ? root.theme.text : root.theme.muted
            font.family: root.theme.font
            font.pixelSize: 12
            MouseArea { id: revealMouse; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: reveal.shown = !reveal.shown }
        }
    }

    // error, or the Caps Lock warning
    Text {
        id: hints
        anchors.top: box.bottom
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.error !== "" ? root.error : root.capsLock ? "Caps Lock is on" : ""
        color: root.error !== "" ? root.theme.error : root.theme.warning
        font.family: root.theme.font
        font.pixelSize: 13
    }
}
