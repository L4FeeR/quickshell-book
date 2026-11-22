pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

// The notification daemon. Only ONE NotificationServer may exist, so it lives in a singleton
// and every notification widget (popups, center, bell, island) reads from here.
Singleton {
    id: root
    property bool dnd: false
    // every notification still open, oldest first (the history / notification center)
    readonly property var list: server.trackedNotifications.values
    readonly property int count: list.length
    // the ones currently shown as popups (a subset of `list`)
    property var popups: []

    signal arrived(Notification n)                   // for extra reactions (sounds, the dynamic island…)

    NotificationServer {
        id: server
        keepOnReload: true                           // survive config reloads
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true                         // keep it: without this it is dropped immediately
            n.closed.connect(() => root.hidePopup(n))
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.popups = root.popups.concat([n])
            root.arrived(n)
        }
    }

    function hidePopup(n: var): void { popups = popups.filter(x => x !== n) }
    function clearAll(): void { for (const n of list.slice()) n.dismiss() }

    IpcHandler {
        target: "notifs"
        function toggleDnd(): void { root.dnd = !root.dnd }
        function clear(): void { root.clearAll() }
        function count(): int { return root.count }
    }
}
