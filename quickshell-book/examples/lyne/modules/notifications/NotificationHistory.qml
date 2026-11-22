import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// The history under the bell: every notification still open, newest first,
// with do-not-disturb and "clear all".
AttachedPopup {
    id: root

    required property string screenName

    shown: NotificationService.historyVisible && NotificationService.historyScreen === screenName
    onDismissed: NotificationService.historyVisible = false
    panelWidth: Config.notifWidth + Config.spacing * 4
    panelHeight: Math.min(560, col.implicitHeight + Config.spacing * 4)

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: Config.spacing * 2
        spacing: Config.spacing

        RowLayout {
            Layout.fillWidth: true
            StyledText { Layout.fillWidth: true; text: "Notifications"; font.bold: true; font.pixelSize: Config.fontSizeLarge }
            BarButton { active: NotificationService.dnd; onClicked: NotificationService.toggleDnd(); Glyph { text: NotificationService.dnd ? Icons.bellOff : Icons.bell } }
            BarButton { visible: NotificationService.count > 0; onClicked: NotificationService.clearAll(); Glyph { text: Icons.clearAll } }
        }

        StyledText {
            visible: NotificationService.count === 0
            Layout.alignment: Qt.AlignHCenter
            Layout.margins: Config.spacing * 2
            text: "No notifications"
            color: Config.mutedColor
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: contentHeight
            visible: NotificationService.count > 0
            clip: true
            spacing: Config.padding
            model: NotificationService.history.slice().reverse()
            delegate: NotificationCard {
                required property var modelData
                notif: modelData
                width: ListView.view.width
            }
        }
    }
}
