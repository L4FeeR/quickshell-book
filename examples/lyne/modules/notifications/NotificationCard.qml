import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.config
import qs.services
import qs.components

// One notification: image or app icon, title, app and time, body, action
// buttons, and a reply field when the app supports inline replies.
// Used by the popups and by the history.
Rectangle {
    id: root

    required property Notification notif
    readonly property bool critical: notif.urgency === NotificationUrgency.Critical
    property bool showClose: true

    implicitHeight: col.implicitHeight + Config.spacing * 2
    radius: Config.radius
    color: Config.cardColor
    border.width: critical ? 1 : 0                 // only critical ones get a border
    border.color: Config.errorColor

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Config.spacing
        spacing: Config.padding

        RowLayout {
            spacing: Config.spacing
            Item {
                Layout.alignment: Qt.AlignTop
                implicitWidth: 40
                implicitHeight: 40
                ClippingRectangle {
                    anchors.fill: parent
                    radius: Config.radiusSmall
                    visible: root.notif.image !== ""
                    color: Config.surface1Color
                    Image { anchors.fill: parent; source: root.notif.image; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                }
                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 32
                    visible: root.notif.image === ""
                    source: Quickshell.iconPath(root.notif.appIcon || root.notif.desktopEntry, "dialog-information")
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                RowLayout {
                    StyledText { Layout.fillWidth: true; text: root.notif.summary; font.bold: true; font.pixelSize: Config.fontSizeSmall + 1 }
                    StyledText { text: NotificationService.age(root.notif); font.pixelSize: Config.fontSizeSmall - 1; color: Config.mutedColor }
                    Glyph {
                        visible: root.showClose
                        text: Icons.close
                        font.pixelSize: Config.fontSizeSmall + 2
                        color: Config.subtextColor
                        MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: root.notif.dismiss() }
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.notif.body
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    font.pixelSize: Config.fontSizeSmall
                    color: Config.subtextColor
                }
            }
        }

        RowLayout {                                   // actions
            Layout.fillWidth: true
            visible: root.notif.actions.length > 0
            spacing: Config.padding
            Repeater {
                model: root.notif.actions
                Rectangle {
                    required property NotificationAction modelData
                    Layout.fillWidth: true
                    implicitHeight: 28
                    radius: height / 2
                    color: actMouse.containsMouse ? Config.surface2Color : Config.surface1Color
                    StyledText { anchors.centerIn: parent; text: parent.modelData.text; font.pixelSize: Config.fontSizeSmall }
                    MouseArea { id: actMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData.invoke() }
                }
            }
        }

        Rectangle {                                   // inline reply (chat apps)
            Layout.fillWidth: true
            visible: root.notif.hasInlineReply
            implicitHeight: 30
            radius: height / 2
            color: Config.surface1Color
            TextInput {
                id: reply
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                color: Config.textColor
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
                onAccepted: { root.notif.sendInlineReply(text); text = ""; }
                StyledText {
                    visible: parent.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.notif.inlineReplyPlaceholder || "Reply…"
                    color: Config.mutedColor
                    font.pixelSize: Config.fontSizeSmall
                }
            }
        }
    }
}
