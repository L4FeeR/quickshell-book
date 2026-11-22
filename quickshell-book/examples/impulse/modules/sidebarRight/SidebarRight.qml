import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.services
import qs.modules.common

// The right sidebar window: full height on the right, closes on Esc or a click outside.
Scope {
    PanelWindow {
        id: win

        visible: GlobalStates.sidebarRightOpen
        anchors { top: true; right: true; bottom: true }
        implicitWidth: Appearance.sizes.sidebarWidth
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "quickshell:sidebarRight"
        WlrLayershell.keyboardFocus: GlobalStates.sidebarRightOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        onVisibleChanged: if (visible) { Notifications.timeoutAll(); Notifications.unread = 0; }

        HyprlandFocusGrab {
            windows: [win]
            active: win.visible
            onCleared: GlobalStates.sidebarRightOpen = false
        }

        SidebarRightContent {
            anchors.fill: parent
            anchors.margins: Appearance.sizes.hyprlandGapsOut
            anchors.leftMargin: Appearance.sizes.elevationMargin
            focus: true
            Keys.onEscapePressed: GlobalStates.sidebarRightOpen = false
        }
    }

    IpcHandler {
        target: "sidebarRight"
        function toggle(): void { GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen }
    }
    GlobalShortcut {
        appid: "impulse"
        name: "sidebarRightToggle"
        onPressed: GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
    }
}
