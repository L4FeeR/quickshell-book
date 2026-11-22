import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false
    readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)

    visible: adapter !== null                      // no adapter → no chip
    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26
    radius: height / 2
    color: hover.hovered ? "#45475a" : "#313244"

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Text {
            text: !root.on ? "bluetooth_disabled" : root.connected.length > 0 ? "bluetooth_connected" : "bluetooth"
            font.family: "Material Symbols Rounded"; font.pixelSize: 18
            color: !root.on ? "#6c7086" : root.connected.length > 0 ? "#89b4fa" : "#cdd6f4"
        }
        Text {
            visible: root.connected.length > 0
            text: root.connected.length === 1 ? root.connected[0].name : root.connected.length + " devices"
            color: "#cdd6f4"; font.pixelSize: 12
            elide: Text.ElideRight; Layout.maximumWidth: 110
        }
        // battery of the first connected device that reports one
        Text {
            readonly property var dev: root.connected.find(d => d.batteryAvailable) ?? null
            visible: dev !== null
            text: dev ? Math.round(dev.battery * 100) + "%" : ""
            color: "#a6adc8"; font.pixelSize: 11
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: if (root.adapter) root.adapter.enabled = !root.on }
    TapHandler { acceptedButtons: Qt.RightButton; onTapped: Quickshell.execDetached(["blueman-manager"]) }
}
