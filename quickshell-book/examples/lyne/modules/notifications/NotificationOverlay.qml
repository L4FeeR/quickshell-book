import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services

// The popup stack at the top right of the focused monitor. Each card slides
// in from the right, lives for the notification's timeout (hovering holds
// it), then leaves; it stays in the history either way.
PanelWindow {
    id: root

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors {
        top: !Config.barOnBottom
        bottom: Config.barOnBottom
        right: true
    }
    margins.top: Config.barOnBottom ? 0 : Config.barReservedHeight + Config.spacing
    margins.bottom: Config.barOnBottom ? Config.barReservedHeight + Config.spacing : 0
    margins.right: Config.spacing
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Config.notifWidth
    implicitHeight: Math.max(1, stack.implicitHeight)
    visible: NotificationService.popups.length > 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lyne_notifications"
    // the keyboard only while typing a reply, so popups never steal focus
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Column {
        id: stack
        width: parent.width
        spacing: Config.spacing

        Repeater {
            model: NotificationService.popups
            NotificationCard {
                id: card
                required property var modelData
                notif: modelData
                width: stack.width
                color: Config.backgroundTransparentColor

                // slide in from the right
                transform: Translate { id: shift; x: root.width }
                Component.onCompleted: slideIn.start()
                NumberAnimation { id: slideIn; target: shift; property: "x"; to: 0; duration: Config.animDurationLong; easing.type: Easing.OutExpo }

                readonly property int timeout: card.critical ? 0 : (modelData.expireTimeout > 0 ? modelData.expireTimeout : Config.notifTimeout)
                Timer {
                    interval: card.timeout
                    running: card.timeout > 0 && !hover.hovered
                    onTriggered: NotificationService.hidePopup(card.modelData)
                }
                HoverHandler { id: hover }
                // right or middle click: dismiss now; left click: the default action
                TapHandler {
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onTapped: (point, button) => {
                        if (button !== Qt.LeftButton) { card.modelData.dismiss(); return; }
                        const def = card.modelData.actions.find(a => a.identifier === "default");
                        if (def) def.invoke(); else NotificationService.hidePopup(card.modelData);
                    }
                }
            }
        }
    }
}
