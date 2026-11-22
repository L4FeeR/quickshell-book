import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// The dashboard: three tabs (Dashboard, Media, Performance) with a sliding indicator.
// The panel resizes smoothly to fit the current tab.
Item {
    id: root

    required property ScreenState screenState
    property bool shown: false
    property int current: 0
    readonly property list<Item> pages: [dash, media, performance]

    implicitWidth: Math.max(tabs.implicitWidth, pages[current].implicitWidth) + Tokens.padding.large * 2
    implicitHeight: tabs.implicitHeight + Tokens.spacing.medium + pages[current].implicitHeight + Tokens.padding.large * 2

    Behavior on implicitWidth { Anim {} }
    Behavior on implicitHeight { Anim {} }

    // poll CPU/RAM only while the dashboard is visible
    onShownChanged: SysInfo.refCount += shown ? 1 : -1

    Row {
        id: tabs

        anchors.horizontalCenter: parent.horizontalCenter
        y: Tokens.padding.large
        spacing: Tokens.spacing.small

        Repeater {
            id: tabButtons
            model: [["dashboard", "Dashboard"], ["queue_music", "Media"], ["speed", "Performance"]]

            Item {
                required property var modelData
                required property int index
                implicitWidth: tabRow.implicitWidth + Tokens.padding.large * 2
                implicitHeight: tabRow.implicitHeight + Tokens.padding.medium * 2

                Row {
                    id: tabRow
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.small
                    MaterialIcon {
                        text: modelData[0]
                        fill: root.current === index ? 1 : 0
                        color: root.current === index ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData[1]
                        color: root.current === index ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    }
                }
                StateLayer {
                    radius: Tokens.rounding.full
                    onClicked: root.current = index
                }
            }
        }
    }

    // the indicator under the selected tab
    StyledRect {
        readonly property Item tab: tabButtons.count > root.current ? tabButtons.itemAt(root.current) : null
        x: tabs.x + (tab?.x ?? 0) + Tokens.padding.large
        y: tabs.y + tabs.height
        width: (tab?.width ?? 0) - Tokens.padding.large * 2
        height: 3
        radius: Tokens.rounding.full
        color: Colours.palette.m3primary

        Behavior on x { Anim { type: Anim.FastSpatial } }
        Behavior on width { Anim { type: Anim.FastSpatial } }
    }

    Item {
        anchors.top: tabs.bottom
        anchors.topMargin: Tokens.spacing.medium
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.pages[root.current].implicitWidth
        height: root.pages[root.current].implicitHeight

        Dash { id: dash; visible: root.current === 0; opacity: visible ? 1 : 0; Behavior on opacity { Anim { type: Anim.Effects } } }
        Media { id: media; visible: root.current === 1; opacity: visible ? 1 : 0; Behavior on opacity { Anim { type: Anim.Effects } } }
        Performance { id: performance; visible: root.current === 2; opacity: visible ? 1 : 0; Behavior on opacity { Anim { type: Anim.Effects } } }
    }
}
