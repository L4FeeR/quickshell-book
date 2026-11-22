import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.modules.common

// One notification card, shared by the popups and the sidebar list. Click the chevron to expand.
Rectangle {
    id: root

    required property var wrapper
    readonly property Notification n: wrapper.notification
    property bool expanded: false

    implicitHeight: layout.implicitHeight + 20
    radius: Appearance.rounding.normal
    color: n?.urgency === NotificationUrgency.Critical ? Appearance.m3colors.m3errorContainer : Appearance.colors.colLayer2

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        ClippingRectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 38; implicitHeight: 38
            radius: Appearance.rounding.full
            color: Appearance.colors.colSecondaryContainer
            Image { anchors.fill: parent; visible: !!root.n?.image; source: root.n?.image ?? ""; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(76, 76) }
            IconImage { anchors.centerIn: parent; visible: !root.n?.image; implicitSize: 22; source: Quickshell.iconPath(root.n?.appIcon || "dialog-information", "dialog-information") }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            RowLayout {
                StyledText { Layout.fillWidth: true; text: root.n?.summary ?? ""; elide: Text.ElideRight; font.weight: 600; color: Appearance.colors.colOnLayer2 }
                StyledText { text: Qt.formatTime(root.wrapper.time, "hh:mm"); color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                MaterialSymbol {
                    text: root.expanded ? "expand_less" : "expand_more"
                    TapHandler { onTapped: root.expanded = !root.expanded }
                }
            }
            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.n?.body ?? ""
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: root.expanded ? 20 : 1
                elide: Text.ElideRight
                color: Appearance.colors.colSubtext
            }
            RowLayout {
                visible: root.expanded
                spacing: 6
                Repeater {
                    model: root.n?.actions ?? []
                    RippleButton {
                        id: actionButton
                        required property NotificationAction modelData
                        implicitHeight: 30
                        implicitWidth: label.implicitWidth + 24
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colSecondaryContainer
                        onClicked: modelData.invoke()
                        contentItem: StyledText { id: label; horizontalAlignment: Text.AlignHCenter; text: actionButton.modelData.text; color: Appearance.colors.colOnSecondaryContainer }
                    }
                }
                RippleButton {
                    implicitHeight: 30
                    implicitWidth: 80
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colLayer1
                    onClicked: root.n.dismiss()
                    contentItem: StyledText { horizontalAlignment: Text.AlignHCenter; text: "Dismiss" }
                }
            }
        }
    }
}
