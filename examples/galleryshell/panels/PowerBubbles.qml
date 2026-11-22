import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root
    property bool open: false
    IpcHandler { target: "power"; function toggle(): void { root.open = !root.open } }

    readonly property var actions: [
        { k: "l", icon: "lock",               name: "Lock",     cmd: ["loginctl", "lock-session"] },
        { k: "s", icon: "bedtime",            name: "Sleep",    cmd: ["systemctl", "suspend"] },
        { k: "e", icon: "logout",             name: "Logout",   cmd: ["loginctl", "terminate-user", Quickshell.env("USER")] },
        { k: "r", icon: "restart_alt",        name: "Reboot",   cmd: ["systemctl", "reboot"] },
        { k: "p", icon: "power_settings_new", name: "Shutdown", cmd: ["systemctl", "poweroff"] }
    ]
    property int sel: 0
    function run(i: int): void { root.open = false; Quickshell.execDetached(actions[i].cmd) }

    LazyLoader {
        active: root.open
        PanelWindow {
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "#88000000"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            MouseArea { anchors.fill: parent; onClicked: root.open = false }
            RowLayout {
                anchors.centerIn: parent
                spacing: 20
                focus: true
                Keys.onEscapePressed: root.open = false
                Keys.onLeftPressed: root.sel = (root.sel + 4) % 5
                Keys.onRightPressed: root.sel = (root.sel + 1) % 5
                Keys.onReturnPressed: root.run(root.sel)
                Keys.onPressed: e => { const i = root.actions.findIndex(a => a.k === e.text); if (i >= 0) root.run(i) }

                Repeater {
                    model: root.actions
                    ColumnLayout {
                        id: cell; required property var modelData
                        required property int index
                        readonly property bool hot: root.sel === index
                        spacing: 10
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 84; implicitHeight: 84
                            radius: cell.hot ? 24 : 42
                            color: cell.hot ? "#cba6f7" : "#313244"
                            scale: cell.hot ? 1.08 : 1
                            Behavior on radius { NumberAnimation { duration: 220 } }
                            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                            Text { anchors.centerIn: parent; text: modelData.icon; font.family: "Material Symbols Rounded"; font.pixelSize: 34
                                   color: cell.hot ? "#1e1e2e" : (modelData.k === "p" ? "#f38ba8" : "#cdd6f4") }
                            MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: root.sel = index; onClicked: root.run(index) }
                        }
                        Text { Layout.alignment: Qt.AlignHCenter; text: modelData.name; color: "white"; font.pixelSize: 13 }
                    }
                }
            }
        }
    }
}
