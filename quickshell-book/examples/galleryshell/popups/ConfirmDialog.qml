import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// "Are you sure?" over a dimmed screen, with an automatic yes after a countdown.
//   qs ipc call confirm ask "Shut down?" "systemctl poweroff"
// Call root.ask() from QML too, e.g. from the power menu.
Scope {
    id: root
    property bool open: false
    property string question: ""
    property var command: []
    property int seconds: 10                      // 0 = never confirm automatically
    property int remaining: 0

    function ask(q: string, cmd: var): void {
        question = q
        command = typeof cmd === "string" ? ["sh", "-c", cmd] : cmd
        remaining = seconds
        open = true
    }
    function accept(): void { open = false; Quickshell.execDetached(command) }

    IpcHandler { target: "confirm"; function ask(q: string, cmd: string): void { root.ask(q, cmd) } }

    Timer {
        interval: 1000; repeat: true
        running: root.open && root.seconds > 0
        onTriggered: if (--root.remaining <= 0) root.accept()
    }

    LazyLoader {
        active: root.open
        PanelWindow {
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "#99000000"                           // dims everything below
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            MouseArea { anchors.fill: parent; onClicked: root.open = false }   // click outside = cancel

            Rectangle {
                anchors.centerIn: parent
                width: 380; height: 190
                radius: 22; color: "#1e1e2e"; border.color: "#313244"
                focus: true
                Keys.onEscapePressed: root.open = false
                Keys.onReturnPressed: root.accept()
                MouseArea { anchors.fill: parent }                             // swallow clicks on the card

                ColumnLayout {
                    anchors { fill: parent; margins: 22 }
                    spacing: 10
                    Text { text: "warning"; font.family: "Material Symbols Rounded"; font.pixelSize: 32; color: "#f9e2af" }
                    Text { text: root.question; color: "#cdd6f4"; font.pixelSize: 18; font.bold: true }
                    Text {
                        visible: root.seconds > 0
                        text: "Continuing in " + root.remaining + " s"; color: "#a6adc8"; font.pixelSize: 12
                    }
                    Item { Layout.fillHeight: true }
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: 8
                        Repeater {
                            model: [{ t: "Cancel", yes: false }, { t: "Confirm", yes: true }]
                            Rectangle {
                                required property var modelData
                                implicitWidth: 100; implicitHeight: 36; radius: 18
                                color: modelData.yes ? "#f38ba8" : btnHover.hovered ? "#45475a" : "#313244"
                                Text { anchors.centerIn: parent; text: parent.modelData.t; color: parent.modelData.yes ? "#1e1e2e" : "#cdd6f4"; font.bold: true }
                                HoverHandler { id: btnHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: parent.modelData.yes ? root.accept() : (root.open = false) }
                            }
                        }
                    }
                }
            }
        }
    }
}
