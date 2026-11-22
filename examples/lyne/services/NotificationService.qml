pragma Singleton
import QtQuick
import Quickshell
import qs.services
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.config

// The notification daemon: receives every notification, keeps the history,
// and decides which ones pop up. Only ONE notification server may run in a
// session, which is why it lives in a singleton.
Singleton {
    id: root

    readonly property bool dnd: StateService.get("notifications.dnd", false)
    readonly property var history: server.trackedNotifications.values    // oldest first
    readonly property int count: history.length
    property var popups: []                       // the ones showing as popups right now

    // the history popup under the bell
    property bool historyVisible: false
    property string historyScreen: ""

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        inlineReplySupported: true                // apps like chat clients can offer a reply field
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;                     // keep it, or it's dropped right away
            root._arrived[n.id] = Date.now();     // notifications carry no time stamp: record it
            n.closed.connect(() => root.hidePopup(n));
            if (root.dnd && n.urgency !== NotificationUrgency.Critical)
                return;                           // do not disturb: history only
            const list = root.popups.concat([n]);
            root.popups = list.slice(-Config.notifMaxPopups);    // never more than maxPopups
        }
    }

    function hidePopup(n) { popups = popups.filter(x => x !== n); }
    function clearAll() { history.slice().forEach(n => n.dismiss()); }
    function toggleDnd() { StateService.set("notifications.dnd", !dnd); }

    function toggleHistory(screen) {
        if (historyVisible && historyScreen === screen) { historyVisible = false; return; }
        WindowManagerService.openExclusive("Notifications", () => { historyScreen = screen; historyVisible = true; });
    }

    // how long ago a notification arrived: "now", "5 min", "2 h"
    property var _arrived: ({})
    function age(n) {
        const s = Math.floor((Date.now() - (_arrived[n.id] ?? Date.now())) / 1000);
        return s < 60 ? "now" : s < 3600 ? Math.floor(s / 60) + " min" : Math.floor(s / 3600) + " h";
    }

    Connections {
        target: WindowManagerService
        function onCloseRequested(except) { if (except !== "Notifications") root.historyVisible = false; }
    }
    onHistoryVisibleChanged: historyVisible ? WindowManagerService.registerOpen("Notifications") : WindowManagerService.registerClose("Notifications")

    IpcHandler {
        target: "notifications"
        function toggleDnd(): void { root.toggleDnd(); }
        function clear(): void { root.clearAll(); }
    }
}
