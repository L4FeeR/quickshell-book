import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components
import qs.modules.notifications

// The notification centre: every notification since login, a DND toggle and "clear all".
Item {
    id: root

    property real maxHeight: 600

    implicitWidth: Tokens.sizes.notificationWidth + Tokens.padding.large * 2
    implicitHeight: Math.min(maxHeight, headerRow.height + list.contentHeight + Tokens.padding.large * 3 + Tokens.spacing.medium)

    RowLayout {
        id: headerRow
        x: Tokens.padding.large
        y: Tokens.padding.large
        width: Tokens.sizes.notificationWidth

        StyledText {
            Layout.fillWidth: true
            text: Notifs.list.length > 0 ? Notifs.list.length + " notifications" : "Notifications"
            font.pixelSize: Tokens.font.size.large
            font.weight: 600
        }
        IconButton {
            icon: Notifs.dnd ? "notifications_off" : "notifications"
            toggle: true
            checked: Notifs.dnd
            onClicked: Notifs.dnd = !Notifs.dnd
        }
        IconButton {
            icon: "clear_all"
            onClicked: Notifs.clearAll()
        }
    }

    ListView {
        id: list
        anchors.top: headerRow.bottom
        anchors.topMargin: Tokens.spacing.medium
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.padding.large
        x: Tokens.padding.large
        width: Tokens.sizes.notificationWidth
        clip: true
        spacing: Tokens.spacing.small
        model: Notifs.list

        delegate: NotificationCard {
            required property var modelData
            notif: modelData
            width: ListView.view.width
        }
        add: Transition { Anim { property: "opacity"; from: 0; to: 1; type: Anim.Effects } }
        remove: Transition { Anim { property: "x"; to: list.width; type: Anim.Emphasized } }
        displaced: Transition { Anim { property: "y" } }

        StyledText {
            anchors.centerIn: parent
            visible: Notifs.list.length === 0
            text: "All caught up"
            color: Colours.palette.m3outline
        }
    }
}
