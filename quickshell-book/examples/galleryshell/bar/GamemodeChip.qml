import Quickshell
import Quickshell.Io
import QtQuick

// One click turns off Hyprland's animations, blur, shadows and gaps (for games or slow machines).
Rectangle {
    id: root
    property bool on: false

    function apply(): void {
        if (on)
            Quickshell.execDetached(["hyprctl", "--batch",
                "keyword animations:enabled 0; keyword decoration:shadow:enabled 0; keyword decoration:blur:enabled 0; " +
                "keyword general:gaps_in 0; keyword general:gaps_out 0; keyword general:border_size 1; keyword decoration:rounding 0"])
        else
            Quickshell.execDetached(["hyprctl", "reload"])     // back to whatever your config says
    }

    // pick up the real state at startup (animations off = game mode)
    Process {
        running: true
        command: ["hyprctl", "getoption", "animations:enabled", "-j"]
        stdout: StdioCollector { onStreamFinished: { try { root.on = JSON.parse(text).int === 0 } catch (e) {} } }
    }

    implicitWidth: 30; implicitHeight: 26
    radius: height / 2
    color: on ? "#a6e3a1" : hover.hovered ? "#45475a" : "#313244"
    Behavior on color { ColorAnimation { duration: 150 } }

    Text {
        anchors.centerIn: parent
        text: "sports_esports"
        font.family: "Material Symbols Rounded"; font.pixelSize: 18
        color: root.on ? "#1e1e2e" : "#cdd6f4"
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: { root.on = !root.on; root.apply() } }
}
