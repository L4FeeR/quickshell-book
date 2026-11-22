import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    // the Wi-Fi device, and any other connected device (Quickshell types only Wi-Fi so far: the rest is wired)
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.type !== DeviceType.Wifi && d.connected && d.name !== "lo") ?? null
    readonly property var net: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property real strength: net?.signalStrength ?? 0
    property bool showName: true

    readonly property string icon: wired ? "lan"
        : !Networking.wifiEnabled ? "wifi_off"
        : !net ? "signal_wifi_statusbar_not_connected"
        : strength > 0.75 ? "network_wifi" : strength > 0.5 ? "network_wifi_3_bar"
        : strength > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
    readonly property string label: wired ? "Ethernet" : net?.name ?? (Networking.wifiEnabled ? "Offline" : "Wi-Fi off")

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26
    radius: height / 2
    color: hover.hovered ? "#45475a" : "#313244"
    Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Text {
            text: root.icon
            font.family: "Material Symbols Rounded"; font.pixelSize: 18
            color: root.net || root.wired ? "#89b4fa" : "#6c7086"
        }
        Text {
            visible: root.showName
            text: root.label
            color: "#cdd6f4"; font.pixelSize: 12
            elide: Text.ElideRight
            Layout.maximumWidth: 120
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.showName = !root.showName }
    TapHandler { acceptedButtons: Qt.RightButton; onTapped: Networking.wifiEnabled = !Networking.wifiEnabled }
    TapHandler { acceptedButtons: Qt.MiddleButton; onTapped: Quickshell.execDetached(["nm-connection-editor"]) }
}
