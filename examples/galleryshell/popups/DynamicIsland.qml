import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    // ---------- state ----------
    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? null
    readonly property PwNode sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    property bool expanded: false          // clicked open
    property string flash: ""              // "volume" or "notify": temporary states
    property string notifyTitle: ""
    property string notifyBody: ""
    function showFlash(kind: string): void { flash = kind; flashTimer.restart() }
    Timer { id: flashTimer; interval: 2000; onTriggered: root.flash = "" }

    // volume changes → flash the volume state (ignore the first value at startup)
    property bool armed: false
    Timer { interval: 1500; running: true; onTriggered: root.armed = true }
    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { if (root.armed) root.showFlash("volume") }
        function onMutedChanged() { if (root.armed) root.showFlash("volume") }
    }
    // call this from your notification service: island.notify(n.summary, n.body)
    function notify(title: string, body: string): void { notifyTitle = title; notifyBody = body; showFlash("notify") }

    // which mode wins right now
    readonly property string mode: expanded && player ? "expanded"
                                 : flash === "notify" ? "notify"
                                 : flash === "volume" ? "volume"
                                 : player ? "media" : "idle"
    readonly property size targetSize: ({
        idle:     Qt.size(120, 32),
        media:    Qt.size(300, 40),
        volume:   Qt.size(260, 40),
        notify:   Qt.size(380, 72),
        expanded: Qt.size(400, 140)
    })[mode]

    PanelWindow {
        id: win
        anchors.top: true
        margins.top: 6
        implicitWidth: 420
        implicitHeight: 160
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:island"
        mask: Region { item: island }                 // only the pill itself catches clicks

        Rectangle {
            id: island
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            width: root.targetSize.width
            height: root.targetSize.height
            radius: Math.min(height / 2, 28)
            color: "#000000"
            clip: true
            // springy morph between sizes
            Behavior on width  { SpringAnimation { spring: 4; damping: 0.32; epsilon: 0.5 } }
            Behavior on height { SpringAnimation { spring: 4; damping: 0.32; epsilon: 0.5 } }

            TapHandler { onTapped: root.expanded = !root.expanded }

            // ---- idle: clock ----
            SystemClock { id: clock; precision: SystemClock.Minutes }
            Text {
                anchors.centerIn: parent
                opacity: root.mode === "idle" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                text: Qt.formatDateTime(clock.date, "hh:mm")
                color: "white"; font.pixelSize: 13; font.bold: true
            }

            // ---- media strip ----
            RowLayout {
                anchors { fill: parent; leftMargin: 6; rightMargin: 14 }
                opacity: root.mode === "media" ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
                spacing: 10
                ClippingRectangle {
                    implicitWidth: 28; implicitHeight: 28; radius: 8; color: "#313244"
                    Image { anchors.fill: parent; source: root.player?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(56, 56) }
                }
                Text {
                    Layout.fillWidth: true
                    text: (root.player?.trackTitle ?? "") + (root.player?.trackArtist ? " · " + root.player.trackArtist : "")
                    color: "white"; font.pixelSize: 12; elide: Text.ElideRight
                }
                Row {                                          // fake equalizer bars
                    spacing: 3
                    Repeater {
                        model: 4
                        Rectangle {
                            required property int index
                            width: 3; radius: 1.5; color: "#a6e3a1"
                            anchors.bottom: parent.bottom
                            height: 6
                            SequentialAnimation on height {
                                running: root.mode === "media"; loops: Animation.Infinite
                                NumberAnimation { to: 6 + (index % 2 ? 10 : 6); duration: 280 + index * 70 }
                                NumberAnimation { to: 5; duration: 260 + index * 50 }
                            }
                        }
                    }
                }
            }

            // ---- volume flash ----
            RowLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                opacity: root.mode === "volume" ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                spacing: 10
                Text {
                    text: root.sink?.audio?.muted ? "volume_off" : "volume_up"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: "white"
                }
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 6; radius: 3; color: "#45475a"
                    Rectangle {
                        width: parent.width * Math.min(1, root.sink?.audio?.muted ? 0 : (root.sink?.audio?.volume ?? 0))
                        height: parent.height; radius: 3; color: "white"
                        Behavior on width { NumberAnimation { duration: 120 } }
                    }
                }
            }

            // ---- notification ----
            ColumnLayout {
                anchors { fill: parent; margins: 14 }
                opacity: root.mode === "notify" ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
                spacing: 2
                Text { text: root.notifyTitle; color: "white"; font.bold: true; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true }
                Text { text: root.notifyBody; color: "#a6adc8"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
            }

            // ---- expanded media controls ----
            RowLayout {
                anchors { fill: parent; margins: 16 }
                opacity: root.mode === "expanded" ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                spacing: 14
                ClippingRectangle {
                    implicitWidth: 100; implicitHeight: 100; radius: 16; color: "#313244"
                    Image { anchors.fill: parent; source: root.player?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(200, 200) }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: root.player?.trackTitle ?? ""; color: "white"; font.bold: true; font.pixelSize: 15; elide: Text.ElideRight; Layout.fillWidth: true }
                    Text { text: root.player?.trackArtist ?? ""; color: "#a6adc8"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                    Rectangle {                                  // progress
                        Layout.fillWidth: true; implicitHeight: 4; radius: 2; color: "#45475a"
                        Rectangle {
                            width: parent.width * ((root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                            height: parent.height; radius: 2; color: "white"
                        }
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 22
                        Repeater {
                            model: [{ i: "skip_previous", f: () => root.player.previous() },
                                    { i: root.player?.isPlaying ? "pause" : "play_arrow", f: () => root.player.togglePlaying() },
                                    { i: "skip_next", f: () => root.player.next() }]
                            Text {
                                required property var modelData
                                text: modelData.i
                                font.family: "Material Symbols Rounded"; font.pixelSize: 26; color: "white"
                                TapHandler { onTapped: parent.modelData.f() }
                            }
                        }
                    }
                }
            }
        }
    }
    // keep the progress bar moving while expanded
    Timer { running: root.mode === "expanded" && (root.player?.isPlaying ?? false); interval: 1000; repeat: true
            onTriggered: root.player.positionChanged() }
}
