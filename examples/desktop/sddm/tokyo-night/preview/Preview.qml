import QtQuick

// Stand-ins for the objects SDDM gives a theme, so the theme can be run and
// screenshotted with `qml` alone (see preview.sh). Entering "secret" logs in;
// anything else shows the failure.
Item {
    width: 1920
    height: 1080

    QtObject {
        id: sddm
        signal loginFailed
        signal loginSucceeded
        property bool canSuspend: true
        property bool canReboot: true
        property bool canPowerOff: true
        function login(user, password, session) {
            console.log("login:", user, "session", session);
            password === "secret" ? loginSucceeded() : loginFailed();
        }
        function suspend() { console.log("suspend"); }
        function reboot() { console.log("reboot"); }
        function powerOff() { console.log("power off"); }
    }
    ListModel {
        id: userModel
        property int lastIndex: 1
        property string lastUser: "alex"
        ListElement { name: "sam"; realName: "Sam Rivera"; icon: "" }
        ListElement { name: "alex"; realName: "Alex Kim"; icon: "" }
        ListElement { name: "guest"; realName: ""; icon: "" }
    }
    ListModel {
        id: sessionModel
        property int lastIndex: 0
        ListElement { name: "Hyprland"; comment: "" }
        ListElement { name: "Plasma (Wayland)"; comment: "" }
    }
    QtObject {
        id: keyboard
        property bool capsLock: true
        property bool numLock: false
        property var layouts: [{ shortName: "us", longName: "English (US)" }, { shortName: "de", longName: "German" }]
        property int currentLayout: 0
    }
    QtObject {
        id: config
        property string background: "background.jpg"     // as in theme.conf: resolved next to Main.qml
        property string blur: "0.6"
        property string dim: "0.15"
        property string accent: "#7aa2f7"
        property string font: "Inter"
        property string clockFormat: "hh:mm"
        property string dateFormat: "dddd, d MMMM"
        property string showUsers: "true"
    }

    Loader { id: theme; anchors.fill: parent; source: "../Main.qml" }

    // run with a .png file name after "--" to save a screenshot and quit:
    //   qml preview/Preview.qml -- shot.png
    readonly property string shotFile: Qt.application.arguments.find(a => a.endsWith(".png")) ?? ""
    Timer {
        running: parent.shotFile !== ""
        interval: 1500
        onTriggered: theme.item.grabToImage(r => { r.saveToFile(parent.shotFile); Qt.quit(); })
    }
}
