import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.config
import qs.services

// The system tray in lyne's "drawer" style: a chevron that slides the tray
// icons out of the bar. Whether it's open is saved (bar.tray.open), so it
// survives a restart.
Row {
    id: root

    readonly property var items: SystemTray.items.values
    readonly property bool open: StateService.get("bar.tray.open", false)
    spacing: Config.padding
    visible: items.length > 0

    // the icons: their row is clipped, and its width animates between 0 and full
    Item {
        id: drawer
        height: Config.barButtonHeight
        width: root.open ? icons.implicitWidth : 0
        clip: true
        anchors.verticalCenter: parent.verticalCenter
        Behavior on width { NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic } }

        Row {
            id: icons
            anchors.right: parent.right               // the icons slide out from the chevron
            anchors.verticalCenter: parent.verticalCenter
            spacing: Config.padding
            Repeater {
                model: root.items
                Item {
                    id: item
                    required property SystemTrayItem modelData
                    width: Config.fontSizeIconSmall
                    height: width
                    IconImage { anchors.fill: parent; source: item.modelData.icon; asynchronous: true }
                    QsMenuAnchor {
                        id: menu
                        menu: item.modelData.menu
                        anchor.item: item
                        anchor.edges: Config.barOnBottom ? Edges.Top : Edges.Bottom
                        anchor.gravity: Config.barOnBottom ? Edges.Top : Edges.Bottom
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: m => {
                            if (m.button === Qt.LeftButton && !item.modelData.onlyMenu)
                                item.modelData.activate();
                            else if (m.button === Qt.MiddleButton)
                                item.modelData.secondaryActivate();
                            else if (item.modelData.hasMenu)
                                menu.open();
                        }
                    }
                }
            }
        }
    }

    BarButton {
        anchors.verticalCenter: parent.verticalCenter
        onClicked: StateService.set("bar.tray.open", !root.open)
        Glyph {
            text: Icons.chevronLeft
            rotation: root.open ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: Config.animDuration } }
        }
    }
}
