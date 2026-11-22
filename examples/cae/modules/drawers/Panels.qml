import Quickshell
import QtQuick
import qs.config
import qs.services
import qs.components
import qs.modules.dashboard as Dashboard
import qs.modules.launcher as Launcher
import qs.modules.notifications as Notifications
import qs.modules.sidebar as Sidebar
import qs.modules.session as Session
import qs.modules.osd as Osd
import qs.modules.utilities as Utilities
import qs.modules.popouts as Popouts

// Where every drawer lives inside the frame. Each one is a DrawerWrapper attached to an edge.
Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState

    readonly property alias dashboard: dashboard
    readonly property alias launcher: launcher
    readonly property alias notifications: notifications
    readonly property alias sidebar: sidebar
    readonly property alias session: session
    readonly property alias osd: osd
    readonly property alias utilities: utilities
    readonly property alias popouts: popouts

    DrawerWrapper {
        id: dashboard
        edge: "top"
        open: root.screenState.dashboard
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        Dashboard.Content { screenState: root.screenState; shown: dashboard.visible }
    }

    DrawerWrapper {
        id: launcher
        edge: "bottom"
        open: root.screenState.launcher
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        Launcher.Content { screenState: root.screenState }
    }

    DrawerWrapper {
        id: notifications
        edge: "top"
        open: Notifs.popups.length > 0 && !root.screenState.sidebar
        anchors.top: parent.top
        anchors.right: parent.right

        Notifications.Content {}
    }

    DrawerWrapper {
        id: sidebar
        edge: "right"
        open: root.screenState.sidebar
        anchors.top: parent.top
        anchors.right: parent.right

        Sidebar.Content { maxHeight: root.height - Tokens.sizes.sessionButton * 3 }
    }

    DrawerWrapper {
        id: session
        edge: "right"
        open: root.screenState.session
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right

        Session.Content { screenState: root.screenState }
    }

    DrawerWrapper {
        id: osd
        edge: "right"
        open: root.screenState.osd
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: session.width     // moves aside when the session menu is open

        Osd.Content { screenState: root.screenState; screen: root.screen }
    }

    DrawerWrapper {
        id: utilities
        edge: "bottom"
        open: root.screenState.utilities
        anchors.bottom: parent.bottom
        anchors.right: parent.right

        Utilities.Content {}
    }

    Popouts.Wrapper {
        id: popouts
        // vertically centred on the hovered bar item, but kept inside the screen
        y: Math.max(0, Math.min(root.height - height, currentCenter - Config.border.thickness - height / 2))

        Behavior on y {
            enabled: popouts.visible
            Anim { type: Anim.FastSpatial }
        }
    }
}
