import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root
    property bool open: false
    property string result: ""
    IpcHandler { target: "calc"; function toggle(): void { root.open = !root.open } }

    LazyLoader {
        active: root.open
        PanelWindow {
            implicitWidth: 420; implicitHeight: 140
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Process {
                id: qalc
                command: ["qalc", "-t", expr.text]          // -t: terse, only the result
                stdout: StdioCollector { onStreamFinished: root.result = text.trim() }
            }
            Timer { id: debounce; interval: 150; onTriggered: if (expr.text.trim()) qalc.running = true; else root.result = "" }

            Rectangle {
                anchors.fill: parent; radius: 22; color: "#1e1e2e"; border.color: "#313244"
                ColumnLayout {
                    anchors { fill: parent; margins: 16 }
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 40; radius: 20; color: "#313244"
                        TextInput {
                            id: expr
                            anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#cdd6f4"; font.pixelSize: 15; focus: true
                            onTextChanged: debounce.restart()
                            Keys.onEscapePressed: root.open = false
                            Keys.onReturnPressed: { Quickshell.execDetached(["wl-copy", root.result]); root.open = false }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.result ? "= " + root.result : "Try: 2^10, 5 USD to EUR, 30 min + 1.5 h"
                        color: root.result ? "#cba6f7" : "#6c7086"
                        font.pixelSize: root.result ? 24 : 13
                        font.bold: root.result !== ""
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
