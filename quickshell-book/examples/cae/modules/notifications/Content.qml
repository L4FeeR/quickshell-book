import QtQuick
import qs.config
import qs.services
import qs.components

// Notification popups in the top-right drawer, newest on top.
Item {
    implicitWidth: Tokens.sizes.notificationWidth + Tokens.padding.large * 2
    implicitHeight: column.implicitHeight + Tokens.padding.large * 2

    Column {
        id: column
        x: Tokens.padding.large
        y: Tokens.padding.large
        spacing: Tokens.spacing.small

        Repeater {
            model: Notifs.popups.slice(0, 4)

            NotificationCard {
                required property var modelData
                notif: modelData
                width: Tokens.sizes.notificationWidth
            }
        }
    }
}
