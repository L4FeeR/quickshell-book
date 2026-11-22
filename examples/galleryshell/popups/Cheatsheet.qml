import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root
    property bool shown: false
    property var binds: []

    GlobalShortcut {
        name: "cheatsheet"
        onPressed: { loadBinds.running = true; root.shown = true }
        onReleased: root.shown = false
    }

    // hyprctl binds -j → [{ modmask, key, dispatcher, arg, description, … }]
    Process {
        id: loadBinds
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const mods = m => [[64, "SUPER"], [1, "SHIFT"], [4, "CTRL"], [8, "ALT"]].filter(([b]) => m & b).map(([, n]) => n)
                root.binds = JSON.parse(text)
                    .filter(b => b.key && !b.mouse)
                    .map(b => ({ keys: [...mods(b.modmask), b.key].join("+"),
                                 what: b.description || (b.dispatcher + " " + b.arg).trim() }))
                    .slice(0, 40)
            }
        }
    }

    PanelWindow {
        implicitWidth: 760; implicitHeight: grid.implicitHeight + 80
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        visible: root.shown || fade.running
        WlrLayershell.layer: WlrLayer.Overlay

        Rectangle {
            anchors.fill: parent
            radius: 22; color: "#ee1e1e2e"; border.color: "#45475a"
            opacity: root.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { id: fade; duration: 150 } }

            Text { x: 24; y: 20; text: "Keybinds"; color: "#cba6f7"; font.pixelSize: 16; font.bold: true }
            GridLayout {
                id: grid
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24; topMargin: 56 }
                columns: 2; columnSpacing: 24; rowSpacing: 6
                Repeater {
                    model: root.binds
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 10
                        Rectangle {
                            implicitWidth: k.implicitWidth + 14; implicitHeight: 22; radius: 6; color: "#313244"
                            Text { id: k; anchors.centerIn: parent; text: modelData.keys; color: "#cdd6f4"; font.pixelSize: 11; font.family: "JetBrains Mono" }
                        }
                        Text { Layout.fillWidth: true; text: modelData.what; color: "#a6adc8"; font.pixelSize: 12; elide: Text.ElideRight }
                    }
                }
            }
        }
    }
}
