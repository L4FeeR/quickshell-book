import QtQuick
import QtQuick.Effects

// An SDDM theme is a QML file that SDDM loads as the login screen. SDDM
// gives it a few objects by name:
//   sddm          login(user, password, session), powerOff(), reboot(), suspend(),
//                 canPowerOff…, and the signals loginFailed / loginSucceeded
//   userModel     the users (name, realName, icon) and lastUser
//   sessionModel  the sessions (Hyprland, Plasma…) and lastIndex
//   config        the values from theme.conf: config.background, config.accent…
Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#1a1b26"

    readonly property color accent: config.accent || "#7aa2f7"
    readonly property color text: "#c0caf5"
    readonly property color subtext: "#a9b1d6"
    readonly property color surface: "#1a1b26"
    property int sessionIndex: sessionModel.lastIndex
    property string userName: userModel.lastUser || ""

    // ── background: the image, blurred and darkened ──
    Image {
        id: wall
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        visible: false
    }
    MultiEffect {
        anchors.fill: wall
        source: wall
        blurEnabled: true
        blur: 0.7
        blurMax: 48
        brightness: -0.2
    }

    // ── clock ──
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.18
        Text {
            id: time
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.text
            font.family: config.font
            font.pixelSize: 110
            font.bold: true
            text: Qt.formatTime(new Date(), "hh:mm")
        }
        Text {
            id: date
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.subtext
            font.family: config.font
            font.pixelSize: 20
            text: Qt.formatDate(new Date(), "dddd, d MMMM")
        }
    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: { time.text = Qt.formatTime(new Date(), "hh:mm"); date.text = Qt.formatDate(new Date(), "dddd, d MMMM"); }
    }

    // ── login box ──
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 80
        spacing: 16

        // user: click to cycle through the users
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 84
            height: 84
            radius: 42
            color: root.accent
            Text {
                anchors.centerIn: parent
                text: root.userName ? root.userName[0].toUpperCase() : "?"
                color: root.surface
                font.pixelSize: 36
                font.bold: true
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.userName
            color: root.text
            font.family: config.font
            font.pixelSize: 18
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                property int i: 0
                onClicked: {
                    // userModel is a list model; data() reads a user's name (role 257 = Qt.UserRole + 1)
                    i = (i + 1) % userModel.rowCount();
                    root.userName = userModel.data(userModel.index(i, 0), 257);
                }
            }
        }

        Rectangle {
            id: field
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320
            height: 48
            radius: 24
            color: Qt.alpha(root.surface, 0.85)
            border.width: 2
            border.color: password.activeFocus ? root.accent : "#414868"

            TextInput {
                id: password
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: TextInput.Password
                passwordCharacter: "●"
                color: root.text
                font.pixelSize: 16
                focus: true
                onAccepted: sddm.login(root.userName, text, root.sessionIndex)
            }
            Text {
                anchors.centerIn: parent
                visible: password.text === ""
                text: "Password"
                color: "#545c7e"
                font.pixelSize: 15
            }
            SequentialAnimation {
                id: shake
                loops: 2
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -10; duration: 50 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 10; duration: 100 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50 }
            }
        }

        Text {
            id: message
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#f7768e"
            font.pixelSize: 13
            text: ""
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            message.text = "Wrong password";
            password.text = "";
            shake.restart();
        }
        function onLoginSucceeded() { message.text = ""; }
    }

    // ── bottom: session on the left, power on the right ──
    Text {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 32
        color: root.subtext
        font.family: config.font
        font.pixelSize: 14
        // role 260 of sessionModel is the session's name (SDDM: Qt.UserRole + 4)
        text: "Session: " + sessionModel.data(sessionModel.index(root.sessionIndex, 0), 260) + "  ›"
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 32
        spacing: 12
        Repeater {
            model: [["Suspend", () => sddm.suspend()], ["Restart", () => sddm.reboot()], ["Shut down", () => sddm.powerOff()]]
            Rectangle {
                required property var modelData
                width: label.implicitWidth + 28
                height: 36
                radius: 18
                color: hover.containsMouse ? "#292e42" : Qt.alpha(root.surface, 0.8)
                Text { id: label; anchors.centerIn: parent; text: parent.modelData[0]; color: root.text; font.pixelSize: 13 }
                MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData[1]() }
            }
        }
    }
}
