import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Scope {
    id: root
    property bool open: false
    IpcHandler { target: "wifi"; function toggle(): void { root.open = !root.open } }

    LazyLoader {
        active: root.open
        PanelWindow {
            id: win
            anchors { top: true; right: true }
            margins { top: 54; right: 10 }
            implicitWidth: 340; implicitHeight: 420
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            readonly property var dev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
            property var pending: null
            Component.onCompleted: if (dev) dev.scannerEnabled = true
            Component.onDestruction: if (dev) dev.scannerEnabled = false

            Rectangle {
                anchors.fill: parent; radius: 22; color: "#1e1e2e"; border.color: "#313244"
                ColumnLayout {
                    anchors { fill: parent; margins: 16 }
                    spacing: 10
                    RowLayout {
                        Text { text: "Wi-Fi"; color: "#cdd6f4"; font.pixelSize: 16; font.bold: true; Layout.fillWidth: true }
                        Switch { checked: Networking.wifiEnabled; onToggled: Networking.wifiEnabled = checked }
                    }
                    ListView {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        clip: true; spacing: 6
                        model: ScriptModel {
                            values: (win.dev?.networks.values ?? []).slice()
                                .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
                        }
                        delegate: Rectangle {
                            required property WifiNetwork modelData
                            width: ListView.view.width; implicitHeight: 44; radius: 12
                            color: modelData.connected ? "#45365e" : ma.containsMouse ? "#45475a" : "#313244"
                            RowLayout {
                                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                                Text { text: modelData.signalStrength > 0.66 ? "signal_wifi_4_bar" : modelData.signalStrength > 0.33 ? "network_wifi_2_bar" : "network_wifi_1_bar"
                                       font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: "#cdd6f4" }
                                Text { Layout.fillWidth: true; text: modelData.name; color: "#cdd6f4"; font.bold: modelData.connected; elide: Text.ElideRight }
                                Text { text: modelData.stateChanging ? "…" : modelData.connected ? "connected" : modelData.security !== WifiSecurityType.Open ? "lock" : ""
                                       font.family: modelData.connected || modelData.stateChanging ? "" : "Material Symbols Rounded"
                                       color: modelData.connected ? "#a6e3a1" : "#a6adc8"; font.pixelSize: modelData.connected ? 11 : 15 }
                            }
                            MouseArea {
                                id: ma; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    const n = parent.modelData
                                    if (n.connected) n.disconnect()
                                    else if (n.known || n.security === WifiSecurityType.Open) n.connect()
                                    else win.pending = n
                                }
                            }
                        }
                    }
                    TextField {
                        Layout.fillWidth: true
                        visible: win.pending !== null
                        placeholderText: "Password for " + (win.pending?.name ?? "")
                        echoMode: TextInput.Password
                        onAccepted: { win.pending.connectWithPsk(text); text = ""; win.pending = null }
                    }
                }
            }
        }
    }
}
