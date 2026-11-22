import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config

// The frame window itself ignores exclusive zones (it covers the whole screen). These four
// invisible 1px windows reserve space instead, so tiled windows sit inside the frame.
Scope {
    id: root

    required property ShellScreen screen
    required property int barZone

    Zone { anchors.left: true; exclusiveZone: root.barZone }
    Zone { anchors.top: true }
    Zone { anchors.right: true }
    Zone { anchors.bottom: true }

    component Zone: PanelWindow {
        screen: root.screen
        color: "transparent"
        exclusiveZone: Config.border.thickness
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
        WlrLayershell.namespace: "cae-border-exclusion"
    }
}
