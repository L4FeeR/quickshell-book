import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config

// A popup window that holds one AttachedPanel right under (or above) the bar.
// The Quick Settings panel, the dashboard and the notification history all
// use it. Only the panel takes clicks; the rest of the window lets them
// through. Clicking anywhere else closes it.
PanelWindow {
    id: win

    property bool shown: false
    property Item anchorItem: null              // the bar button it opens from: the panel centres under it
    property real panelX: width / 2             // where the panel's centre is, in screen x
    property real panelWidth: 300
    property real panelHeight: 200
    property var barWindow: null                // clicks on the bar don't count as "outside"
    default property alias content: holder.data
    signal dismissed                            // Escape or a click outside

    // measure the button's position when opening (the bar spans the whole
    // screen, so its window x is the screen x)
    onShownChanged: if (shown && anchorItem) panelX = anchorItem.mapToItem(null, anchorItem.width / 2, 0).x

    // stays mapped until the slide-out animation has finished
    visible: shown || panel.progress > 0

    anchors {
        top: !Config.barOnBottom
        bottom: Config.barOnBottom
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore         // start at the screen edge, under the bar
    implicitHeight: Config.barReservedHeight + panelHeight + 4
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "lyne_attached"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region { item: panel }

    HyprlandFocusGrab {
        active: win.shown
        windows: win.barWindow ? [win, win.barWindow] : [win]
        onCleared: win.dismissed()
    }

    AttachedPanel {
        id: panel
        shown: win.shown
        edge: Config.barOnBottom ? "bottom" : "top"
        width: win.panelWidth
        height: win.panelHeight
        x: Math.max(Config.spacing + filletSize, Math.min(win.width - width - Config.spacing - filletSize, win.panelX - width / 2))
        y: Config.barOnBottom ? win.height - Config.barReservedHeight - height : Config.barReservedHeight

        Item {
            id: holder
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: win.dismissed()
        }
    }
}
