import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services

// The workspace strip. One slot per workspace (1 … count); the active slot
// is wider and an accent "indicator" pill slides to it. The indicator's two
// edges move at different speeds: the edge in the direction of travel leads,
// the other follows, so the pill stretches and snaps like elastic.
//
// Three looks (bar.workspaces.style): "pills" (a bar per workspace),
// "dots" (small circles) and "numbers".
Item {
    id: root

    property int count: Config.barWorkspaceCount
    property string style: Config.barWorkspaceStyle

    readonly property int activeId: Hyprland.focusedWorkspace?.id ?? 1
    readonly property int activeIndex: activeId - 1

    readonly property int itemWidth: style === "numbers" ? Config.fontSizeSmall + Config.padding * 2 : Config.fontSizeSmall + Math.round(Config.padding / 2)
    readonly property int activeWidth: style === "numbers" ? itemWidth : itemWidth * 2
    readonly property int itemSpacing: Math.round(Config.padding * 2 / 3)
    readonly property int indicatorHeight: Config.fontSizeSmall + Config.padding

    function isOccupied(id) { return Hyprland.workspaces.values.some(w => w.id === id && w.toplevels.values.length > 0); }
    function isUrgent(id) { return Hyprland.workspaces.values.some(w => w.id === id && w.urgent); }

    // where each slot starts and how wide it is, from left to right
    function slotX(index) {
        let x = 0;
        for (let i = 0; i < index; i++)
            x += (i === activeIndex ? activeWidth : itemWidth) + itemSpacing;
        return x;
    }
    function slotWidth(index) { return index === activeIndex ? activeWidth : itemWidth; }

    implicitWidth: slotX(count) - itemSpacing
    implicitHeight: Config.barButtonHeight

    // ── The indicator ─────────────────────────────────────────────────────
    Rectangle {
        id: indicator
        property real leftEdge: root.slotX(root.activeIndex)
        property real rightEdge: leftEdge + root.slotWidth(root.activeIndex)
        property int direction: 0                     // +1 moving right, -1 moving left

        z: root.style === "numbers" ? 0 : 1          // numbers are drawn on top of it
        x: leftEdge
        width: rightEdge - leftEdge
        height: root.indicatorHeight
        anchors.verticalCenter: parent.verticalCenter
        radius: root.style === "dots" ? height / 2 : Config.radius
        color: Config.accentColor
        visible: root.activeIndex >= 0 && root.activeIndex < root.count

        // the leading edge is quick, the trailing edge slower: the stretch
        Behavior on leftEdge { NumberAnimation { duration: indicator.direction < 0 ? Config.animDuration * 0.6 : Config.animDuration; easing.type: Easing.OutCubic } }
        Behavior on rightEdge { NumberAnimation { duration: indicator.direction > 0 ? Config.animDuration * 0.6 : Config.animDuration; easing.type: Easing.OutCubic } }
    }
    property int lastIndex: activeIndex
    onActiveIndexChanged: { indicator.direction = Math.sign(activeIndex - lastIndex); lastIndex = activeIndex; }

    // ── The slots ─────────────────────────────────────────────────────────
    Repeater {
        model: root.count
        Item {
            id: slot
            required property int index
            readonly property int wsId: index + 1
            readonly property bool active: index === root.activeIndex
            readonly property bool occupied: root.isOccupied(wsId)
            readonly property bool urgent: root.isUrgent(wsId)

            x: root.slotX(index)
            width: root.slotWidth(index)
            height: parent.height
            Behavior on x { NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic } }

            // pills: a bar, brighter when the workspace has windows
            Rectangle {
                visible: root.style === "pills"
                anchors.centerIn: parent
                width: parent.width
                height: root.indicatorHeight
                radius: Config.radius
                color: slot.urgent ? Config.errorColor : slot.occupied ? Config.surface3Color : Qt.alpha(Config.surface2Color, 0.65)
            }
            // dots: a small circle, bigger when occupied
            Rectangle {
                visible: root.style === "dots"
                anchors.centerIn: parent
                width: slot.occupied ? 8 : 5
                height: width
                radius: width / 2
                color: slot.urgent ? Config.errorColor : slot.occupied ? Config.subtextColor : Config.surface3Color
            }
            // numbers: the number, dim when empty, dark on the indicator
            StyledText {
                visible: root.style === "numbers"
                z: 2
                anchors.centerIn: parent
                text: slot.wsId
                font.pixelSize: Config.fontSizeSmall
                font.bold: slot.active
                color: slot.active ? Config.textReverseColor : slot.urgent ? Config.errorColor : slot.occupied ? Config.textColor : Config.mutedColor
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hypr.workspace(slot.wsId)
            }
        }
    }

    // the wheel moves to the next or previous workspace
    WheelHandler {
        onWheel: e => Hypr.workspace(Math.max(1, Math.min(root.count, root.activeId + (e.angleDelta.y > 0 ? -1 : 1))))
    }
}
