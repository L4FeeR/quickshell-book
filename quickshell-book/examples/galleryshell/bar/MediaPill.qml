import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    readonly property MprisPlayer p: Mpris.players.values.find(pl => pl.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property bool open: hover.hovered
    visible: p !== null

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 28
    radius: height / 2
    color: "#313244"
    clip: true
    Behavior on implicitWidth { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    RowLayout {
        id: row
        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
        spacing: 8
        ClippingRectangle {                                     // spinning disc
            implicitWidth: 22; implicitHeight: 22; radius: 11; color: "#cba6f7"
            Image { anchors.fill: parent; source: root.p?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(44, 44) }
            RotationAnimation on rotation { running: root.p?.isPlaying ?? false; from: 0; to: 360; duration: 6000; loops: Animation.Infinite }
        }
        Text {
            text: root.p?.trackTitle ?? ""
            color: "#cdd6f4"; font.pixelSize: 12
            elide: Text.ElideRight
            Layout.maximumWidth: root.open ? 220 : 120
        }
        Repeater {
            model: root.open ? [["skip_previous", () => root.p.previous()],
                                [root.p?.isPlaying ? "pause" : "play_arrow", () => root.p.togglePlaying()],
                                ["skip_next", () => root.p.next()]] : []
            Text {
                required property var modelData
                text: modelData[0]
                font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: "#cdd6f4"
                TapHandler { onTapped: parent.modelData[1]() }
            }
        }
        Item { implicitWidth: 4 }
    }
    HoverHandler { id: hover }
}
