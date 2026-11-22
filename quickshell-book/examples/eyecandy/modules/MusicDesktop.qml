import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.widgets

// A music corner on the desktop (behind your windows): the album cover inside
// a pulsing ring visualizer, the scrolling lyrics beside it, and the
// now-playing card under the ring. Everything takes its colours from the cover.
PanelWindow {
    id: root

    anchors { bottom: true; left: true }
    margins { bottom: 60; left: 60 }
    implicitWidth: 980
    implicitHeight: 560
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: Player.active !== null
    WlrLayershell.layer: WlrLayer.Bottom              // on the desktop, under windows
    WlrLayershell.namespace: "eyecandy_music"
    mask: Region {}                                  // decoration only: clicks go to the desktop

    RowLayout {
        anchors.fill: parent
        spacing: 40

        ColumnLayout {
            Layout.preferredWidth: 420
            Layout.fillWidth: false
            spacing: 16

            // ── the ring, with the cover in the middle ──
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 380
                implicitHeight: 380

                VisualizerRing {
                    anchors.fill: parent
                    radius: 120
                    barWidth: 5
                    colorFrom: ArtColors.accent
                    colorTo: Qt.lighter(ArtColors.accent, 1.5)
                }
                // ClippingRectangle clips its content to the rounded shape
                // (plain `clip` would only clip to the square bounding box)
                ClippingRectangle {
                    anchors.centerIn: parent
                    width: 220
                    height: 220
                    radius: 110
                    color: ArtColors.background
                    Image {
                        id: cover
                        anchors.fill: parent
                        source: Player.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        // the cover slowly spins while playing, like a record
                        RotationAnimation on rotation {
                            running: Player.playing
                            from: cover.rotation
                            to: cover.rotation + 360
                            duration: 30000
                            loops: Animation.Infinite
                        }
                    }
                }
            }
            NowPlayingCard { Layout.fillWidth: true }
        }

        // ── lyrics ──
        LyricsView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            accent: ArtColors.accent
            fontSize: 24
        }
    }
}
