import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

// Replaces hypridle: dim after 4 min, lock after 5, screen off after 6, suspend after 15.
// Apps that inhibit idle (video players, games) are respected; so is Session.caffeine.
Scope {
    id: root

    component Stage: IdleMonitor {
        enabled: !Session.caffeine
        respectInhibitors: true
    }

    // 1. dim: a black, half-transparent overlay that fades in
    Stage { id: dim; timeout: 240 }
    Variants {
        model: dim.isIdle && !Session.locked ? Quickshell.screens : []
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"
            mask: Region {}                                  // never takes input; moving the mouse ends idle anyway
            Rectangle {
                anchors.fill: parent
                color: "black"
                NumberAnimation on opacity { from: 0; to: 0.6; duration: 4000 }
            }
        }
    }

    // 2. lock
    Stage { timeout: 300; onIsIdleChanged: if (isIdle) Session.locked = true }

    // 3. screens off, and back on when you return
    Stage {
        timeout: 360
        onIsIdleChanged: Quickshell.execDetached(["hyprctl", "dispatch", "dpms", isIdle ? "off" : "on"])
    }

    // 4. suspend (lock first so the machine wakes up locked)
    Stage {
        timeout: 900
        onIsIdleChanged: if (isIdle) { Session.locked = true; Quickshell.execDetached(["systemctl", "suspend"]) }
    }
}
