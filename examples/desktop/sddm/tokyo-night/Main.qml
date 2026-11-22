import QtQuick
import QtQuick.Effects
import "components"

// SDDM loads this file as the login screen, once per monitor, and gives it:
//   sddm          login(), powerOff(), reboot(), suspend(), canPowerOff…, loginFailed/loginSucceeded
//   userModel     the users: roles name, realName, icon; lastIndex, lastUser
//   sessionModel  the sessions: roles name, comment; lastIndex
//   keyboard      capsLock, numLock, layouts (shortName, longName), currentLayout
//   config        the [General] values of theme.conf
Rectangle {
    id: root
    width: 1920
    height: 1080
    color: theme.base

    Theme { id: theme; conf: config }

    // ── background: picture, blurred and dimmed ──
    Image {
        id: wall
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        blurEnabled: theme.blur > 0
        blur: theme.blur
        blurMax: 64
        brightness: -theme.dim
    }

    // ── clock ──
    Clock {
        theme: theme
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.12
    }

    // ── who and password ──
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.42
        spacing: 22

        UserList {
            id: users
            theme: theme
            model: userModel
            visible: theme.showUsers
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {                                       // with the user row off: just the last user
            visible: !theme.showUsers
            anchors.horizontalCenter: parent.horizontalCenter
            text: userModel.lastUser
            color: theme.text
            font.family: theme.font
            font.pixelSize: 22
        }

        PasswordBox {
            id: password
            theme: theme
            anchors.horizontalCenter: parent.horizontalCenter
            capsLock: keyboard.capsLock
            onSubmitted: pw => sddm.login(theme.showUsers ? users.selectedName : userModel.lastUser, pw, session.currentIndex)
        }
    }

    // SDDM answers a login attempt with one of these
    Connections {
        target: sddm
        function onLoginFailed() { password.fail("Wrong password, try again"); }
        function onLoginSucceeded() { password.busy = false; }
    }

    // ── bottom left: session and keyboard layout ──
    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 32
        spacing: 10

        SessionPicker { id: session; theme: theme; sessions: sessionModel }

        Rectangle {                                  // keyboard layout: click for the next one
            visible: keyboard.layouts.length > 1
            width: layoutText.implicitWidth + 28
            height: 36
            radius: 18
            color: Qt.alpha(theme.base, 0.8)
            Text {
                id: layoutText
                anchors.centerIn: parent
                text: keyboard.layouts[keyboard.currentLayout]?.shortName.toUpperCase() ?? ""
                color: theme.text
                font.family: theme.font
                font.pixelSize: 13
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
            }
        }
    }

    // ── bottom right: power ──
    PowerBar {
        theme: theme
        power: sddm
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 32
    }

    Component.onCompleted: password.focusField()
}
