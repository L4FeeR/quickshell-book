import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    // apps reading from any audio source (microphones)
    readonly property var micUsers: Pipewire.linkGroups.values
        .filter(g => g.source && !g.source.isStream && !g.source.isSink && g.source.audio && g.target?.isStream)
        .map(g => g.target.properties["application.name"] ?? g.target.name)
    // video streams consuming a screen-capture source (portal screencasts)
    readonly property var screenUsers: Pipewire.nodes.values
        .filter(n => n.isStream && !n.audio && (n.properties["media.class"] ?? "").startsWith("Stream/Input/Video"))
        .map(n => n.properties["application.name"] ?? n.name)

    readonly property bool active: micUsers.length > 0 || screenUsers.length > 0
    visible: active
    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26
    radius: height / 2
    color: Qt.rgba(0.95, 0.55, 0.66, 0.18)

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Text {
            visible: root.micUsers.length > 0
            text: "mic"; font.family: "Material Symbols Rounded"; font.pixelSize: 17; color: "#f38ba8"
            SequentialAnimation on opacity { running: parent.visible; loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 700 } NumberAnimation { to: 1; duration: 700 } }
        }
        Text {
            visible: root.screenUsers.length > 0
            text: "screen_share"; font.family: "Material Symbols Rounded"; font.pixelSize: 17; color: "#fab387"
        }
        Text {
            visible: hover.hovered
            text: [...new Set([...root.micUsers, ...root.screenUsers])].join(", ")
            color: "#cdd6f4"; font.pixelSize: 11
        }
    }
    HoverHandler { id: hover }
}
