import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root
    readonly property MprisPlayer p: Mpris.players.values.find(pl => pl.isPlaying) ?? Mpris.players.values[0] ?? null
    visible: p !== null
    anchors { bottom: true; left: true }
    margins { bottom: 80; left: 420 }
    implicitWidth: 420; implicitHeight: 180
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom

    Timer { running: root.p?.isPlaying ?? false; interval: 1000; repeat: true; onTriggered: root.p.positionChanged() }

    RowLayout {
        anchors.fill: parent
        spacing: 20
        Item {
            implicitWidth: 160; implicitHeight: 160
            Rectangle {                                       // the record
                id: disc
                anchors.fill: parent
                radius: width / 2
                color: "#11111b"
                Repeater { model: 4; Rectangle {               // grooves
                    required property int index
                    anchors.centerIn: parent
                    width: 150 - index * 20; height: width; radius: width / 2
                    color: "transparent"; border.color: "#24243a" } }
                ClippingRectangle {                           // label = album art
                    anchors.centerIn: parent
                    width: 64; height: 64; radius: 32
                    color: "#cba6f7"
                    Image { anchors.fill: parent; source: root.p?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(128, 128) }
                }
                Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: "#11111b" }
                RotationAnimator on rotation {
                    from: 0; to: 360; duration: 5000; loops: Animation.Infinite
                    running: root.p?.isPlaying ?? false
                }
            }
            TapHandler { onTapped: root.p.togglePlaying() }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Text { Layout.fillWidth: true; text: root.p?.trackTitle ?? ""; color: "#cdd6f4"; font.pixelSize: 20; font.weight: Font.Black; elide: Text.ElideRight }
            Text { Layout.fillWidth: true; text: (root.p?.trackArtist ?? "") + (root.p?.trackAlbum ? " · " + root.p.trackAlbum : ""); color: "#a6adc8"; font.pixelSize: 13; elide: Text.ElideRight }
            Rectangle {
                Layout.fillWidth: true; Layout.topMargin: 8; implicitHeight: 4; radius: 2; color: "#313244"
                Rectangle { width: parent.width * (root.p?.position ?? 0) / Math.max(1, root.p?.length ?? 1); height: parent.height; radius: 2; color: "#cba6f7" }
            }
        }
    }
}
