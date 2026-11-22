import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.services

// Notification popups in the top-right corner: icon or image, text, action buttons, timeout bar.
// Hovering a card holds it open; clicking runs its default action.
PanelWindow {
    id: root
    anchors { top: true; right: true }
    margins { top: 8; right: 8 }
    implicitWidth: 380
    implicitHeight: Math.max(1, stack.implicitHeight)
    visible: Notifs.popups.length > 0
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifications"

    ColumnLayout {
        id: stack
        width: parent.width
        spacing: 8

        Repeater {
            model: Notifs.popups
            Rectangle {
                id: card
                required property Notification modelData
                readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
                // the app's timeout, 5 s if it didn't give one, never for critical ones
                readonly property int timeout: critical ? 0 : modelData.expireTimeout > 0 ? modelData.expireTimeout : 5000
                readonly property var defaultAction: modelData.actions.find(a => a.identifier === "default") ?? null

                Layout.fillWidth: true
                implicitHeight: body.implicitHeight + 24
                radius: 16
                color: "#1e1e2e"
                border.color: critical ? "#f38ba8" : "#313244"; border.width: critical ? 2 : 1

                // slide in from the right (a transform, because the layout owns x)
                transform: Translate {
                    NumberAnimation on x { from: 400; to: 0; duration: 260; easing.type: Easing.OutCubic }
                }

                Timer {
                    id: life
                    interval: card.timeout
                    running: card.timeout > 0 && !cardHover.hovered
                    onTriggered: Notifs.hidePopup(card.modelData)        // stays in the history
                }

                RowLayout {
                    id: body
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                    spacing: 12

                    // an image sent with the notification (album art, avatar), else the app icon
                    Item {
                        Layout.alignment: Qt.AlignTop
                        implicitWidth: 44; implicitHeight: 44
                        ClippingRectangle {
                            anchors.fill: parent; radius: 10; color: "#313244"
                            visible: card.modelData.image !== ""
                            Image { anchors.fill: parent; source: card.modelData.image; fillMode: Image.PreserveAspectCrop }
                        }
                        IconImage {
                            visible: card.modelData.image === ""
                            anchors.centerIn: parent; implicitSize: 36
                            source: Quickshell.iconPath(card.modelData.appIcon || card.modelData.desktopEntry, "dialog-information")
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        RowLayout {
                            Text {
                                Layout.fillWidth: true
                                text: card.modelData.summary
                                color: "#cdd6f4"; font.pixelSize: 14; font.bold: true
                                elide: Text.ElideRight
                            }
                            Text { text: card.modelData.appName; color: "#6c7086"; font.pixelSize: 11 }
                            Text {
                                text: "close"; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: "#a6adc8"
                                TapHandler { onTapped: card.modelData.dismiss() }
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: card.modelData.body
                            textFormat: Text.StyledText          // apps may send <b>, <i>, <a>
                            color: "#a6adc8"; font.pixelSize: 12
                            wrapMode: Text.Wrap; maximumLineCount: 4; elide: Text.ElideRight
                        }
                        RowLayout {                              // action buttons (except the default one)
                            visible: card.modelData.actions.length > (card.defaultAction ? 1 : 0)
                            Layout.topMargin: 4
                            spacing: 6
                            Repeater {
                                model: card.modelData.actions.filter(a => a.identifier !== "default")
                                Rectangle {
                                    required property NotificationAction modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 28; radius: 14
                                    color: actHover.hovered ? "#45475a" : "#313244"
                                    Text { anchors.centerIn: parent; text: parent.modelData.text; color: "#cdd6f4"; font.pixelSize: 12 }
                                    HoverHandler { id: actHover; cursorShape: Qt.PointingHandCursor }
                                    TapHandler { onTapped: parent.modelData.invoke() }
                                }
                            }
                        }
                    }
                }

                // time left, as a thin line along the bottom
                Rectangle {
                    visible: card.timeout > 0
                    anchors { left: parent.left; bottom: parent.bottom; margins: 10 }
                    height: 2; radius: 1; color: "#cba6f7"
                    width: (parent.width - 20)
                    NumberAnimation on width {
                        from: card.width - 20; to: 0
                        duration: card.timeout
                        running: card.timeout > 0 && !cardHover.hovered     // restarts with the timer
                    }
                }

                HoverHandler { id: cardHover }
                TapHandler {
                    onTapped: {
                        if (card.defaultAction) card.defaultAction.invoke()
                        else Notifs.hidePopup(card.modelData)
                    }
                }
            }
        }
    }
}
