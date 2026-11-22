import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Scope {
    id: root
    property bool open: false
    property bool dnd: false
    property bool caffeine: false
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode mic: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.mic] }

    IpcHandler { target: "quicksettings"; function toggle(): void { root.open = !root.open } }

    component Tile: Rectangle {
        id: tile
        property string icon
        property string label
        property bool active
        signal toggled()
        Layout.fillWidth: true
        implicitHeight: 56
        radius: active ? 16 : height / 2
        color: active ? "#cba6f7" : "#313244"
        Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 200 } }
        RowLayout {
            anchors { fill: parent; leftMargin: 16; rightMargin: 12 }
            spacing: 10
            Text { text: tile.icon; font.family: "Material Symbols Rounded"; font.pixelSize: 20
                   font.variableAxes: ({ "FILL": tile.active ? 1 : 0 }); color: tile.active ? "#1e1e2e" : "#cdd6f4" }
            Text { Layout.fillWidth: true; text: tile.label; elide: Text.ElideRight; font.pixelSize: 13
                   color: tile.active ? "#1e1e2e" : "#cdd6f4"; font.bold: tile.active }
        }
        TapHandler { onTapped: tile.toggled() }
    }

    component SliderRow: RowLayout {
        id: sr
        property string icon
        property real value
        signal moved(real v)
        Layout.fillWidth: true
        spacing: 10
        Text { text: sr.icon; font.family: "Material Symbols Rounded"; font.pixelSize: 20; color: "#cdd6f4" }
        Slider {
            id: s
            Layout.fillWidth: true
            from: 0; to: 1; value: sr.value
            onMoved: sr.moved(value)
            background: Rectangle {
                y: s.topPadding + s.availableHeight / 2 - height / 2
                width: s.availableWidth; height: 20; radius: 10; color: "#313244"
                Rectangle { width: Math.max(height, s.visualPosition * parent.width); height: parent.height; radius: 10; color: "#cba6f7" }
            }
            handle: Item {}
        }
    }

    PanelWindow {
        id: panel; anchors { top: true; right: true }
        margins { top: 54; right: 10 }
        implicitWidth: 360; implicitHeight: col.implicitHeight + 32
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        visible: root.open
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:quicksettings"

        Rectangle {
            anchors.fill: parent
            radius: 24; color: "#1e1e2e"; border.color: "#313244"
            ColumnLayout {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                spacing: 10
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2; rowSpacing: 8; columnSpacing: 8
                    Tile {
                        readonly property var net: Networking.devices.values.find(d => d.type === DeviceType.Wifi)?.networks.values.find(n => n.connected)
                        icon: "wifi"; label: net?.name ?? "Wi-Fi"
                        active: Networking.wifiEnabled
                        onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                    Tile {
                        visible: Bluetooth.defaultAdapter !== null
                        icon: "bluetooth"; label: Bluetooth.devices.values.find(d => d.connected)?.name ?? "Bluetooth"
                        active: Bluetooth.defaultAdapter?.enabled ?? false
                        onToggled: Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                    }
                    Tile { icon: "do_not_disturb_on"; label: "Do not disturb"; active: root.dnd; onToggled: root.dnd = !root.dnd }
                    Tile {
                        icon: "nightlight"; label: "Night light"; active: night.running
                        onToggled: night.running = !night.running
                        Process { id: night; command: ["hyprsunset", "-t", "4200"] }
                    }
                    Tile {
                        icon: "coffee"; label: "Caffeine"; active: root.caffeine
                        onToggled: root.caffeine = !root.caffeine
                    }
                    Tile {
                        icon: root.mic?.audio?.muted ? "mic_off" : "mic"; label: "Microphone"
                        active: !(root.mic?.audio?.muted ?? true)
                        onToggled: if (root.mic?.ready) root.mic.audio.muted = !root.mic.audio.muted
                    }
                }
                SliderRow {
                    icon: "volume_up"
                    value: root.sink?.audio?.volume ?? 0
                    onMoved: v => { if (root.sink?.ready) root.sink.audio.volume = v }
                }
            }
            IdleInhibitor { window: panel; enabled: root.caffeine }
        }
    }
}
