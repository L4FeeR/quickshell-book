import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.services

// A side panel with every notification that is still open, grouped by app, newest first.
Scope {
    id: root
    property bool open: false
    IpcHandler { target: "notifcenter"; function toggle(): void { root.open = !root.open } }

    // [{ app, items: [newest … oldest] }], apps ordered by their newest notification
    readonly property var groups: {
        const map = {}
        const order = []
        for (const n of Notifs.list.slice().reverse()) {
            const key = n.appName || "Other"
            if (!map[key]) { map[key] = { app: key, icon: n.appIcon || n.desktopEntry, items: [] }; order.push(key) }
            map[key].items.push(n)
        }
        return order.map(k => map[k])
    }

    LazyLoader {
        active: root.open
        PanelWindow {
            id: win
            anchors { top: true; bottom: true; right: true }
            margins { top: 8; bottom: 8; right: 8 }
            implicitWidth: 400
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            // clicking anywhere outside the panel closes it
            HyprlandFocusGrab { active: true; windows: [win]; onCleared: root.open = false }

            Rectangle {
                anchors.fill: parent
                radius: 20; color: "#1e1e2e"; border.color: "#313244"
                focus: true
                Keys.onEscapePressed: root.open = false

                ColumnLayout {
                    anchors { fill: parent; margins: 16 }
                    spacing: 12

                    RowLayout {
                        Text { Layout.fillWidth: true; text: "Notifications"; color: "#cdd6f4"; font.pixelSize: 18; font.bold: true }
                        Rectangle {
                            implicitWidth: 34; implicitHeight: 30; radius: 15
                            color: Notifs.dnd ? "#cba6f7" : "#313244"
                            Text { anchors.centerIn: parent; text: Notifs.dnd ? "notifications_off" : "notifications"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: Notifs.dnd ? "#1e1e2e" : "#cdd6f4" }
                            TapHandler { onTapped: Notifs.dnd = !Notifs.dnd }
                        }
                        Rectangle {
                            visible: Notifs.count > 0
                            implicitWidth: clearTxt.implicitWidth + 20; implicitHeight: 30; radius: 15; color: "#313244"
                            Text { id: clearTxt; anchors.centerIn: parent; text: "Clear all"; color: "#cdd6f4"; font.pixelSize: 12 }
                            TapHandler { onTapped: Notifs.clearAll() }
                        }
                    }

                    ColumnLayout {                               // empty state
                        visible: Notifs.count === 0
                        Layout.fillWidth: true; Layout.fillHeight: true
                        Item { Layout.fillHeight: true }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "notifications_paused"; font.family: "Material Symbols Rounded"; font.pixelSize: 48; color: "#45475a" }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "You're all caught up"; color: "#6c7086"; font.pixelSize: 13 }
                        Item { Layout.fillHeight: true }
                    }

                    ListView {
                        visible: Notifs.count > 0
                        Layout.fillWidth: true; Layout.fillHeight: true
                        clip: true; spacing: 12
                        model: root.groups
                        delegate: ColumnLayout {
                            id: group
                            required property var modelData
                            width: ListView.view.width
                            spacing: 6
                            RowLayout {                          // group header
                                IconImage { implicitSize: 16; source: Quickshell.iconPath(group.modelData.icon, "dialog-information") }
                                Text { Layout.fillWidth: true; text: group.modelData.app; color: "#a6adc8"; font.pixelSize: 12; font.bold: true }
                                Text {
                                    text: "Clear"; color: "#6c7086"; font.pixelSize: 11
                                    TapHandler { onTapped: group.modelData.items.forEach(n => n.dismiss()) }
                                }
                            }
                            Repeater {
                                model: group.modelData.items
                                Rectangle {
                                    id: item
                                    required property Notification modelData
                                    Layout.fillWidth: true
                                    implicitHeight: col.implicitHeight + 20
                                    radius: 12
                                    color: itemHover.hovered ? "#313244" : "#181825"
                                    ColumnLayout {
                                        id: col
                                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                                        spacing: 2
                                        RowLayout {
                                            Text { Layout.fillWidth: true; text: item.modelData.summary; color: "#cdd6f4"; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight }
                                            Text {
                                                visible: itemHover.hovered
                                                text: "close"; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: "#a6adc8"
                                                TapHandler { onTapped: item.modelData.dismiss() }
                                            }
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            visible: text !== ""
                                            text: item.modelData.body; textFormat: Text.StyledText
                                            color: "#a6adc8"; font.pixelSize: 12; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight
                                        }
                                    }
                                    HoverHandler { id: itemHover }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
