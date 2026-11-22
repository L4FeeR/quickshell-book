import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.widgets

// Floating lyrics over everything, like a karaoke subtitle: the current line
// big and filling with colour, the next line small under it. It never takes
// clicks, so it can sit over your windows. Toggle: qs ipc call overlay toggle
PanelWindow {
    id: root

    anchors.bottom: true
    margins.bottom: 90
    implicitWidth: 1100
    implicitHeight: 110
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    property bool enabled: true
    visible: enabled && Lyrics.lines.length > 0 && Player.playing
    IpcHandler { target: "overlay"; function toggle(): void { root.enabled = !root.enabled; } }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "eyecandy_lyrics"
    mask: Region {}

    Column {
        anchors.centerIn: parent
        spacing: 6

        Item {
            id: line
            anchors.horizontalCenter: parent.horizontalCenter
            width: base.implicitWidth
            height: base.implicitHeight

            Text {
                id: base
                text: Lyrics.currentText
                color: "white"
                font.family: "Inter"
                font.pixelSize: 34
                font.bold: true
            }
            // the sung part in the accent, clipped by progress
            Item {
                width: base.width * Lyrics.lineProgress
                height: base.height
                clip: true
                Text { text: base.text; color: ArtColors.accent; font: base.font }
            }
            // a dark glow makes it readable on any background
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "black"
                shadowBlur: 0.8
                shadowOpacity: 0.9
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Lyrics.nextText
            color: Qt.alpha("white", 0.65)
            font.family: "Inter"
            font.pixelSize: 18
            style: Text.Outline
            styleColor: Qt.alpha("black", 0.6)
        }
    }
}
