pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import qs.config

// The notification server. `list` is the history (newest first); `popups` the ones still on screen.
Singleton {
    id: root

    property var list: []
    readonly property var popups: list.filter(n => n.popup)
    property bool dnd: false

    function clearAll(): void {
        for (const n of list.slice())
            n.notification.dismiss();
    }

    NotificationServer {
        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;
            const n = notifComp.createObject(root, { notification: notif, popup: !root.dnd });
            root.list = [n, ...root.list];
        }
    }

    Component {
        id: notifComp
        Notif {}
    }

    component Notif: QtObject {
        id: n

        required property Notification notification
        property bool popup: true
        readonly property date time: new Date()

        readonly property Timer timer: Timer {
            running: n.popup && n.notification.urgency !== NotificationUrgency.Critical
            interval: n.notification.expireTimeout > 0 ? n.notification.expireTimeout * 1000 : Config.notifs.defaultExpire
            onTriggered: n.popup = false
        }

        readonly property Connections conn: Connections {
            target: n.notification
            function onClosed(): void {
                root.list = root.list.filter(x => x !== n);
                n.destroy();
            }
        }
    }
}
