import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import qs.services

// A "now playing" card coloured by the album cover: the cover, blurred, as
// the background; the cover itself; title, artist; a progress bar you can
// click to seek; and the controls. Accent and background come from ArtColors.
Rectangle {
    id: root

    property string fontFamily: "Inter"
    implicitWidth: 420
    implicitHeight: 150
    radius: 22
    color: ArtColors.background
    clip: true
    visible: Player.active !== null
    Behavior on color { ColorAnimation { duration: 600 } }

    // ── the blurred cover behind everything ──
    Image {
        id: backdrop
        anchors.fill: parent
        source: Player.artUrl
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(128, 128)        // tiny: it's blurred anyway
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: backdrop
        blurEnabled: true
        blur: 1
        blurMax: 48
        opacity: 0.45
        brightness: -0.3
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // ── the cover ──
        ClippingRectangle {                        // rounded corners on the image too
            Layout.preferredWidth: 118
            Layout.preferredHeight: 118
            radius: 14
            color: Qt.alpha(ArtColors.accent, 0.3)
            Image {
                anchors.fill: parent
                source: Player.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Text {
                Layout.fillWidth: true
                text: Player.title || "Nothing playing"
                color: "white"
                font.family: root.fontFamily
                font.pixelSize: 18
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: Player.artist
                color: Qt.alpha("white", 0.7)
                font.family: root.fontFamily
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            // ── progress: click to seek ──
            Item {
                Layout.fillWidth: true
                Layout.topMargin: 8
                implicitHeight: 14
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Qt.alpha("white", 0.2)
                    Rectangle {
                        width: parent.width * (Player.length > 0 ? Math.min(1, Player.position / Player.length) : 0)
                        height: parent.height
                        radius: 2
                        color: ArtColors.accent
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: m => Player.seek(m.x / width * Player.length)
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: Player.format(Player.position); color: Qt.alpha("white", 0.6); font.pixelSize: 11 }
                Item { Layout.fillWidth: true }
                Text { text: Player.format(Player.length); color: Qt.alpha("white", 0.6); font.pixelSize: 11 }
            }

            // ── controls ──
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 18
                Repeater {
                    model: [["⏮", () => Player.active.previous()], [Player.playing ? "⏸" : "▶", () => Player.active.togglePlaying()], ["⏭", () => Player.active.next()]]
                    Rectangle {
                        required property var modelData
                        required property int index
                        width: index === 1 ? 40 : 30
                        height: width
                        radius: width / 2
                        color: index === 1 ? ArtColors.accent : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData[0]
                            color: parent.index === 1 ? ArtColors.onAccent : "white"
                            font.pixelSize: parent.index === 1 ? 18 : 15
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData[1]() }
                    }
                }
            }
        }
    }
}
