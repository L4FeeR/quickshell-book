import Quickshell
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    signal triggered()                          // connect this to anything
    property int delay: 250                     // ms the pointer must stay in the corner

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property ShellScreen modelData
            screen: modelData
            anchors { top: true; left: true }
            implicitWidth: 3; implicitHeight: 3          // a tiny invisible target
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:hotcorner"

            HoverHandler {
                id: hh
                onHoveredChanged: hovered ? wait.restart() : wait.stop()
            }
            Timer { id: wait; interval: root.delay; onTriggered: root.triggered() }
        }
    }
}
