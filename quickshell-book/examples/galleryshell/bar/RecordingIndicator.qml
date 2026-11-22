import Quickshell
import Quickshell.Io
import QtQuick

Rectangle {
    id: root
    property bool recording: false
    property int seconds: 0
    visible: recording

    implicitWidth: label.implicitWidth + 40
    implicitHeight: 26
    radius: height / 2
    color: "#313244"

    Rectangle {
        x: 10; anchors.verticalCenter: parent.verticalCenter
        width: 10; height: 10; radius: 5; color: "#f38ba8"
        SequentialAnimation on opacity { running: root.recording; loops: Animation.Infinite
            NumberAnimation { to: 0.2; duration: 600 } NumberAnimation { to: 1; duration: 600 } }
    }
    Text {
        id: label
        x: 28; anchors.verticalCenter: parent.verticalCenter
        text: "REC " + String(Math.floor(root.seconds / 60)).padStart(2, "0") + ":" + String(root.seconds % 60).padStart(2, "0")
        color: "#cdd6f4"; font.pixelSize: 12; font.bold: true
        font.features: ({ "tnum": 1 })
    }

    Process {                                           // poll every 2 s for a recorder process
        id: probe
        command: ["pgrep", "-x", "wf-recorder|gpu-screen-reco"]
        onExited: code => {
            const now = code === 0
            if (now && !root.recording) root.seconds = 0
            root.recording = now
        }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: probe.running = true }
    Timer { interval: 1000; running: root.recording; repeat: true; onTriggered: root.seconds++ }

    TapHandler { onTapped: Quickshell.execDetached(["pkill", "-INT", "-x", "wf-recorder"]) }   // SIGINT finishes the file
}
