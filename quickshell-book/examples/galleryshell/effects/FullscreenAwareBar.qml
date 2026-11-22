import Quickshell
import Quickshell.Wayland
import QtQuick

Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: bar
            required property ShellScreen modelData
            screen: modelData
            // any fullscreen window on THIS screen?
            readonly property bool fullscreen: ToplevelManager.toplevels.values.some(t => t.fullscreen && t.screens.includes(modelData))
            // Hyprland alternative: Hyprland.monitorFor(modelData)?.activeWorkspace?.hasFullscreen ?? false

            anchors { top: true; left: true; right: true }
            implicitHeight: 40
            exclusiveZone: fullscreen ? 0 : 40
            color: "transparent"
            visible: !fullscreen || slide.running

            Rectangle {
                width: parent.width; height: 40
                y: bar.fullscreen ? -height : 0
                Behavior on y { NumberAnimation { id: slide; duration: 220; easing.type: Easing.InOutQuad } }
                color: "#1e1e2e"
                Text { anchors.centerIn: parent; text: "bar"; color: "#cdd6f4" }
            }
        }
    }
}
