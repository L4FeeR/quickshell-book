import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// A bar icon that opens a per-application volume mixer.
Rectangle {
    id: root
    property bool open: false
    // playback streams: nodes that are streams, carry audio and go to a sink (i.e. apps playing sound)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.isSink && n.audio)

    PwObjectTracker { objects: root.streams }     // needed to read and change their volume

    implicitWidth: 30; implicitHeight: 26
    radius: height / 2
    color: open || hover.hovered ? "#45475a" : "#313244"
    Text { anchors.centerIn: parent; text: "graphic_eq"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: "#cdd6f4" }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.open = !root.open }

    PopupWindow {
        visible: root.open
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 8
        implicitWidth: 320
        implicitHeight: Math.max(80, list.implicitHeight + 28)
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 16; color: "#1e1e2e"; border.color: "#313244"

            Text {
                visible: root.streams.length === 0
                anchors.centerIn: parent
                text: "Nothing is playing"; color: "#6c7086"; font.pixelSize: 13
            }
            ColumnLayout {
                id: list
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                spacing: 12
                Repeater {
                    model: root.streams
                    RowLayout {
                        id: stream
                        required property PwNode modelData
                        // apps put their name and icon into the node's properties
                        readonly property string app: modelData.properties["application.name"] ?? modelData.description ?? modelData.name
                        readonly property string iconName: modelData.properties["application.icon-name"] ?? "audio-x-generic"
                        Layout.fillWidth: true
                        spacing: 10
                        IconImage { implicitSize: 24; source: Quickshell.iconPath(stream.iconName, "audio-x-generic") }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: stream.app + (stream.modelData.properties["media.name"] ? " · " + stream.modelData.properties["media.name"] : "")
                                color: "#cdd6f4"; font.pixelSize: 12; elide: Text.ElideRight
                            }
                            Slider {
                                Layout.fillWidth: true
                                from: 0; to: 1
                                value: stream.modelData.audio.volume
                                onMoved: stream.modelData.audio.volume = value
                            }
                        }
                        Text {
                            text: stream.modelData.audio.muted ? "volume_off" : "volume_up"
                            font.family: "Material Symbols Rounded"; font.pixelSize: 18
                            color: stream.modelData.audio.muted ? "#f38ba8" : "#a6adc8"
                            TapHandler { onTapped: stream.modelData.audio.muted = !stream.modelData.audio.muted }
                        }
                    }
                }
            }
        }
    }
}
