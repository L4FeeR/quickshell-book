import Quickshell
import Quickshell.Io
import QtQuick

Rectangle {
    id: root
    property int count: 0
    property bool checking: false
    visible: count > 0

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 26
    radius: height / 2
    color: "#313244"

    Text {
        id: label
        anchors.centerIn: parent
        text: (root.checking ? "…" : "⟳") + "  " + root.count
        color: root.count > 50 ? "#f38ba8" : "#fab387"
        font.pixelSize: 12; font.bold: true
    }

    Process {
        id: check
        command: ["sh", "-c", "{ checkupdates 2>/dev/null; (paru -Qua 2>/dev/null || yay -Qua 2>/dev/null); } | wc -l"]
        onStarted: root.checking = true
        stdout: StdioCollector { onStreamFinished: { root.count = parseInt(text) || 0; root.checking = false } }
    }
    Timer { interval: 30 * 60 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: check.running = true }

    TapHandler {
        onTapped: Quickshell.execDetached(["kitty", "-e", "sh", "-c", "paru -Syu || sudo pacman -Syu; read -p 'Done, press enter'"])
    }
    TapHandler { acceptedButtons: Qt.RightButton; onTapped: check.running = true }    // manual refresh
}
