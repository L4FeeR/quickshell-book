import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import QtQuick
import QtQuick.Layouts

// The "authentication required" dialog that apps like GParted, pkexec or systemctl ask for.
// Replaces polkit-gnome / hyprpolkitagent: stop those from autostarting, only one agent can register.
Scope {
    id: root

    PolkitAgent { id: agent }

    LazyLoader {
        active: agent.isActive                            // a request is in progress
        PanelWindow {
            id: win
            readonly property var flow: agent.flow
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "#99000000"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Rectangle {
                anchors.centerIn: parent
                width: 420; height: col.implicitHeight + 48
                radius: 22; color: "#1e1e2e"; border.color: "#313244"

                ColumnLayout {
                    id: col
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24 }
                    spacing: 12

                    RowLayout {
                        spacing: 12
                        Text { text: "admin_panel_settings"; font.family: "Material Symbols Rounded"; font.pixelSize: 36; color: "#cba6f7" }
                        Text { Layout.fillWidth: true; text: "Authentication required"; color: "#cdd6f4"; font.pixelSize: 18; font.bold: true }
                    }
                    Text {                                    // what the app wants to do
                        Layout.fillWidth: true
                        text: win.flow?.message ?? ""
                        color: "#a6adc8"; font.pixelSize: 13; wrapMode: Text.Wrap
                    }
                    Text {                                    // the action id, small, for the curious
                        Layout.fillWidth: true
                        text: win.flow?.actionId ?? ""
                        color: "#585b70"; font.pixelSize: 10; elide: Text.ElideMiddle
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 44; radius: 22; color: "#313244"
                        border.color: win.flow?.failed ? "#f38ba8" : pw.activeFocus ? "#cba6f7" : "transparent"; border.width: 2
                        TextInput {
                            id: pw
                            anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#cdd6f4"; font.pixelSize: 14
                            // the prompt says if the answer is secret (a password) or not
                            echoMode: win.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                            focus: true
                            Keys.onReturnPressed: { win.flow.submit(text); text = "" }
                            Keys.onEscapePressed: win.flow.cancelAuthenticationRequest()
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                            visible: pw.text === ""
                            text: win.flow?.inputPrompt || "Password"
                            color: "#6c7086"; font.pixelSize: 14
                        }
                    }
                    Text {                                    // "Sorry, try again" and similar
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: win.flow?.failed ? "Wrong password, try again" : (win.flow?.supplementaryMessage ?? "")
                        color: win.flow?.failed || win.flow?.supplementaryIsError ? "#f38ba8" : "#a6adc8"; font.pixelSize: 12
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: 8
                        Rectangle {
                            implicitWidth: 100; implicitHeight: 36; radius: 18; color: "#313244"
                            Text { anchors.centerIn: parent; text: "Cancel"; color: "#cdd6f4" }
                            TapHandler { onTapped: win.flow.cancelAuthenticationRequest() }
                        }
                        Rectangle {
                            implicitWidth: 120; implicitHeight: 36; radius: 18; color: "#cba6f7"
                            Text { anchors.centerIn: parent; text: "Authenticate"; color: "#1e1e2e"; font.bold: true }
                            TapHandler { onTapped: { win.flow.submit(pw.text); pw.text = "" } }
                        }
                    }
                }
            }
        }
    }
}
