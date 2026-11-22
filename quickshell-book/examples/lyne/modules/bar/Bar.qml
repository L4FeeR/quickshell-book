import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components
import qs.modules.quickSettings
import qs.modules.notifications
import qs.modules.dashboard

// One bar per screen. Four looks, chosen with bar.style:
//   "docked"          full width, flush with the screen edge
//   "docked-corners"  the same, with concave corners flowing into the screen
//   "floating"        a rounded bar with a gap around it
//   "islands"         no bar background: each group is its own pill
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            anchors {
                top: !Config.barOnBottom
                bottom: Config.barOnBottom
                left: true
                right: true
            }
            // the corners hang below the reserved area, so the window is taller than the bar
            implicitHeight: Config.barReservedHeight + Config.barCornerSize
            exclusiveZone: Config.barAutoHide ? -1 : Config.barReservedHeight
            color: "transparent"
            WlrLayershell.namespace: "lyne_bar"

            // auto-hide: slide away unless hovered or a popup is open
            readonly property bool shown: !Config.barAutoHide || hover.hovered || WindowManagerService.anyModuleOpen
            HoverHandler { id: hover }

            // only the bar takes clicks (the corners click through); when hidden, a 1 px strip
            mask: Region {
                y: Config.barOnBottom ? (bar.shown ? Config.barCornerSize : bar.height - 1) : 0
                width: bar.width
                height: bar.shown ? Config.barReservedHeight : 1
            }

            Item {
                id: slide
                width: parent.width
                height: parent.height
                y: bar.shown ? 0 : (Config.barOnBottom ? height : -height)
                Behavior on y { NumberAnimation { duration: Config.animDurationLong; easing.type: Easing.OutExpo } }

                readonly property real barY: Config.barOnBottom ? Config.barCornerSize : Config.barMargin
                readonly property real cornerY: Config.barOnBottom ? 0 : Config.barHeight

                ConcaveCorner {
                    x: 0
                    y: slide.cornerY
                    size: Config.barCornerSize
                    flipped: Config.barOnBottom
                    color: Config.backgroundTransparentColor
                }
                ConcaveCorner {
                    x: parent.width - width
                    y: slide.cornerY
                    size: Config.barCornerSize
                    flipped: Config.barOnBottom
                    mirrored: true
                    color: Config.backgroundTransparentColor
                }

                Item {
                    id: barArea
                    x: Config.barMargin
                    y: slide.barY
                    width: parent.width - Config.barMargin * 2
                    height: Config.barHeight

                    Rectangle {                              // one background, unless islands
                        anchors.fill: parent
                        visible: !Config.barIslands
                        radius: Config.barFloating ? Config.radiusLarge : 0
                        color: Config.backgroundTransparentColor
                    }

                    BarIsland {                              // left
                        anchors.left: parent.left
                        anchors.leftMargin: Config.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        LauncherButton {}
                        Workspaces {}
                        BarDivider { visible: title.visible }
                        ActiveWindow { id: title }
                    }

                    BarIsland {                              // centre
                        id: centre
                        anchors.centerIn: parent
                        ClockButton { id: clockButton; screenName: bar.modelData.name }
                    }

                    BarIsland {                              // right
                        anchors.right: parent.right
                        anchors.rightMargin: Config.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        TrayWidget {}
                        QuickSettingsButton { id: qsButton; screenName: bar.modelData.name }
                        NotificationButton { id: bellButton; screenName: bar.modelData.name }
                    }
                }
            }

            // the panels that slide out of this bar, one of each per screen
            DashboardWindow { screen: bar.modelData; screenName: bar.modelData.name; barWindow: bar; anchorItem: clockButton }
            QuickSettingsWindow { screen: bar.modelData; screenName: bar.modelData.name; barWindow: bar; anchorItem: qsButton }
            NotificationHistory { screen: bar.modelData; screenName: bar.modelData.name; barWindow: bar; anchorItem: bellButton }
        }
    }
}
