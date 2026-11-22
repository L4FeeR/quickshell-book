pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// Notification server. `list` holds every notification; `popupList` the ones still popping up.
// Opening the right sidebar marks everything as read (see SidebarRight).
Singleton {
    id: root

    property var list: []
    readonly property var popupList: list.filter(n => n.popup)
    property bool silent: false
    property int unread: 0

    function discardAll(): void {
        for (const n of list.slice()) n.notification.dismiss();
    }
    function timeoutAll(): void {
        for (const n of list) n.popup = false;
    }

    NotificationServer {
        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        persistenceSupported: true
        onNotification: notif => {
            notif.tracked = true;
            root.list = [wrapper.createObject(root, { notification: notif, popup: !root.silent }), ...root.list];
            root.unread++;
        }
    }

    Component {
        id: wrapper
        NotifWrapper {}
    }

    component NotifWrapper: QtObject {
        id: w
        required property Notification notification
        property bool popup: true
        readonly property date time: new Date()
        readonly property Timer timer: Timer {
            running: w.popup && w.notification.urgency !== NotificationUrgency.Critical
            interval: w.notification.expireTimeout > 0 ? w.notification.expireTimeout * 1000 : 7000
            onTriggered: w.popup = false
        }
        readonly property Connections conn: Connections {
            target: w.notification
            function onClosed(): void {
                root.list = root.list.filter(x => x !== w);
                w.destroy();
            }
        }
    }
}
