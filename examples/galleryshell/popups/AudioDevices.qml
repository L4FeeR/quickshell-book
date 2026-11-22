import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

// Pick the output (speakers, headphones, HDMI…) and input device from a popup.
Rectangle {
    id: root
    property bool open: false
    readonly property var sinks: Pipewire.nodes.values.filter(n => !n.isStream && n.isSink && n.audio)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isStream && !n.isSink && n.audio)

    implicitWidth: 30; implicitHeight: 26
    radius: height / 2
    color: open || hover.hovered ? "#45475a" : "#313244"
    Text { anchors.centerIn: parent; text: "headphones"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: "#cdd6f4" }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.open = !root.open }

    // one titled list of devices; `current` is highlighted, `pick` makes one the default
    component DeviceList: ColumnLayout {
        id: dl
        property string title
        property var devices: []
        property var current: null
        signal pick(var node)
        Layout.fillWidth: true
        spacing: 4
        Text { text: dl.title; color: "#6c7086"; font.pixelSize: 11; font.bold: true; font.capitalization: Font.AllUppercase }
        Repeater {
            model: dl.devices
            Rectangle {
                id: item
                required property PwNode modelData
                readonly property bool chosen: modelData === dl.current
                Layout.fillWidth: true
                implicitHeight: 34; radius: 10
                color: chosen ? "#45365e" : itemHover.hovered ? "#313244" : "transparent"
                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    Text {
                        text: item.chosen ? "radio_button_checked" : "radio_button_unchecked"
                        font.family: "Material Symbols Rounded"; font.pixelSize: 16
                        color: item.chosen ? "#cba6f7" : "#6c7086"
                    }
                    Text {
                        Layout.fillWidth: true
                        text: item.modelData.description || item.modelData.nickname || item.modelData.name
                        color: "#cdd6f4"; font.pixelSize: 12; elide: Text.ElideRight
                    }
                }
                HoverHandler { id: itemHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: dl.pick(item.modelData) }
            }
        }
    }

    PopupWindow {
        visible: root.open
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 8
        implicitWidth: 320
        implicitHeight: col.implicitHeight + 28
        color: "transparent"
        Rectangle {
            anchors.fill: parent
            radius: 16; color: "#1e1e2e"; border.color: "#313244"
            ColumnLayout {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                spacing: 12
                DeviceList {
                    title: "Output"
                    devices: root.sinks
                    current: Pipewire.defaultAudioSink
                    onPick: node => Pipewire.preferredDefaultAudioSink = node
                }
                DeviceList {
                    title: "Input"
                    devices: root.sources
                    current: Pipewire.defaultAudioSource
                    onPick: node => Pipewire.preferredDefaultAudioSource = node
                }
            }
        }
    }
}
