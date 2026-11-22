import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// One notification: app icon or image, summary, body, actions. Click to run the default
// action; the ✕ dismisses it. Critical notifications are tinted with the error colour.
StyledRect {
    id: root

    required property var notif
    readonly property Notification n: notif.notification
    readonly property bool critical: n?.urgency === NotificationUrgency.Critical

    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2
    radius: Tokens.rounding.large
    color: critical ? Colours.palette.m3errorContainer : Colours.palette.m3surfaceContainer

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        ClippingRectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 42; implicitHeight: 42
            radius: Tokens.rounding.full
            color: Colours.palette.m3secondaryContainer

            Image {
                anchors.fill: parent
                visible: (root.n?.image ?? "") !== ""
                source: root.n?.image ?? ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(84, 84)
            }
            IconImage {
                anchors.centerIn: parent
                visible: !root.n?.image
                implicitSize: 26
                source: Quickshell.iconPath(root.n?.appIcon || "dialog-information", "dialog-information")
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                StyledText {
                    Layout.fillWidth: true
                    text: root.n?.summary ?? ""
                    elide: Text.ElideRight
                    font.weight: 600
                    color: root.critical ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSurface
                }
                StyledText {
                    text: Qt.formatTime(root.notif.time, "hh:mm")
                    color: Colours.palette.m3outline
                    font.pixelSize: Tokens.font.size.small
                }
                MaterialIcon {
                    text: "close"
                    font.pixelSize: Tokens.font.size.normal
                    TapHandler { onTapped: root.n.dismiss() }
                }
            }
            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.n?.body ?? ""
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                color: root.critical ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSurfaceVariant
            }
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.extraSmall
                spacing: Tokens.spacing.small
                visible: (root.n?.actions.length ?? 0) > 0

                Repeater {
                    model: root.n?.actions ?? []
                    StyledRect {
                        required property NotificationAction modelData
                        implicitWidth: label.implicitWidth + Tokens.padding.large * 2
                        implicitHeight: 30
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3secondaryContainer
                        StyledText { id: label; anchors.centerIn: parent; text: parent.modelData.text; color: Colours.palette.m3onSecondaryContainer }
                        StateLayer { onClicked: parent.modelData.invoke() }
                    }
                }
            }
        }
    }

    TapHandler {
        onTapped: root.n?.actions.find(a => a.identifier === "default")?.invoke()
    }
    // hovering keeps a popup on screen
    HoverHandler {
        onHoveredChanged: root.notif.timer.running = !hovered && root.notif.popup
    }
}
