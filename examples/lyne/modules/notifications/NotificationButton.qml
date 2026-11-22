import QtQuick
import qs.config
import qs.services
import qs.components

// The bell. A dot shows unread notifications; a crossed bell means do not
// disturb. Click: the history under it. Right click: do not disturb.
BarButton {
    id: root

    required property string screenName

    active: NotificationService.historyVisible && NotificationService.historyScreen === screenName
    onClicked: NotificationService.toggleHistory(screenName)
    onRightClicked: NotificationService.toggleDnd()

    Item {
        implicitWidth: bell.implicitWidth
        implicitHeight: bell.implicitHeight
        Glyph {
            id: bell
            text: NotificationService.dnd ? Icons.bellOff : Icons.bell
            color: NotificationService.dnd ? Config.mutedColor : Config.textColor
        }
        Rectangle {                                     // the unread dot
            visible: NotificationService.count > 0 && !NotificationService.dnd
            width: 7
            height: 7
            radius: 4
            color: Config.accentColor
            anchors.right: bell.right
            anchors.top: bell.top
            anchors.topMargin: 2
        }
    }
}
