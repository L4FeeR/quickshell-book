import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.services
import qs.components

// Caelestia-style vertical workspaces: a group of `shown` workspaces, merged backgrounds behind
// occupied ones, a pill on the active one that stretches as it moves ("trail"), and app icons.
StyledRect {
    id: root

    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int shown: Config.bar.workspacesShown
    readonly property int activeId: monitor?.activeWorkspace?.id ?? 1
    readonly property int groupStart: Math.floor((activeId - 1) / shown) * shown + 1
    readonly property int slot: Tokens.sizes.barInnerWidth - Tokens.padding.small * 2

    function workspace(id: int): HyprlandWorkspace {
        return Hyprland.workspaces.values.find(w => w.id === id) ?? null;
    }
    function occupied(id: int): bool {
        return (workspace(id)?.toplevels.values.length ?? 0) > 0;
    }

    implicitWidth: Tokens.sizes.barInnerWidth
    implicitHeight: column.implicitHeight + Tokens.padding.small * 2
    radius: Tokens.rounding.full
    color: Colours.palette.m3surfaceContainer

    // merged backgrounds: each occupied slot stretches toward occupied neighbours
    Repeater {
        model: root.shown

        StyledRect {
            required property int index
            readonly property int wsId: root.groupStart + index
            readonly property bool occ: root.occupied(wsId)
            readonly property bool prevOcc: index > 0 && root.occupied(wsId - 1)
            readonly property bool nextOcc: index < root.shown - 1 && root.occupied(wsId + 1)
            readonly property Item cell: cells.count > index ? cells.itemAt(index) : null   // count makes the binding update

            x: Tokens.padding.small
            width: root.slot
            y: (cell?.y ?? 0) + Tokens.padding.small - (prevOcc ? column.spacing / 2 + 1 : 0)
            height: occ ? (cell?.height ?? 0) + (prevOcc ? column.spacing / 2 + 1 : 0) + (nextOcc ? column.spacing / 2 + 1 : 0) : 0
            radius: Tokens.rounding.full
            topLeftRadius: prevOcc ? 0 : radius
            topRightRadius: prevOcc ? 0 : radius
            bottomLeftRadius: nextOcc ? 0 : radius
            bottomRightRadius: nextOcc ? 0 : radius
            color: Colours.palette.m3surfaceContainerHighest
            opacity: occ ? 1 : 0

            Behavior on opacity { Anim { type: Anim.Effects } }
        }
    }

    // the active pill with a trail: the leading edge moves fast, the trailing edge catches up
    StyledRect {
        id: active

        readonly property Item cell: cells.count > 0 ? cells.itemAt(root.activeId - root.groupStart) : null
        readonly property real targetTop: (cell?.y ?? 0) + Tokens.padding.small
        readonly property real targetBottom: targetTop + (cell?.height ?? root.slot)
        property real topEdge: targetTop
        property real bottomEdge: targetBottom
        property bool movingDown: false

        onTargetTopChanged: movingDown = targetTop > topEdge

        x: Tokens.padding.small
        width: root.slot
        y: topEdge
        height: Math.max(width, bottomEdge - topEdge)
        radius: Tokens.rounding.full
        color: Colours.palette.m3primary

        Behavior on topEdge {
            Anim { type: Anim.Spatial; duration: active.movingDown ? Tokens.anim.durations.slowSpatial : Tokens.anim.durations.fastSpatial }
        }
        Behavior on bottomEdge {
            Anim { type: Anim.Spatial; duration: active.movingDown ? Tokens.anim.durations.fastSpatial : Tokens.anim.durations.slowSpatial }
        }
    }

    Column {
        id: column

        anchors.horizontalCenter: parent.horizontalCenter
        y: Tokens.padding.small
        spacing: Tokens.spacing.small

        Repeater {
            id: cells
            model: root.shown

            Item {
                id: cell

                required property int index
                readonly property int wsId: root.groupStart + index
                readonly property bool isActive: wsId === root.activeId
                readonly property var windows: root.workspace(wsId)?.toplevels.values ?? []

                implicitWidth: root.slot
                implicitHeight: root.slot + (Config.bar.workspaceWindows ? icons.implicitHeight : 0)

                StyledText {
                    id: label
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: (root.slot - height) / 2
                    text: cell.wsId
                    font.pixelSize: Tokens.font.size.small
                    font.bold: cell.isActive
                    color: cell.isActive ? Colours.palette.m3onPrimary
                         : root.occupied(cell.wsId) ? Colours.palette.m3onSurface : Colours.palette.m3outline
                }

                Column {
                    id: icons
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: root.slot - Tokens.padding.extraSmall
                    spacing: 2
                    bottomPadding: Tokens.padding.small
                    visible: Config.bar.workspaceWindows

                    Repeater {
                        model: cell.windows.slice(0, 3)

                        IconImage {
                            required property HyprlandToplevel modelData
                            readonly property string appId: modelData.wayland?.appId ?? modelData.lastIpcObject?.class ?? ""
                            implicitSize: 14
                            source: Quickshell.iconPath(DesktopEntries.heuristicLookup(appId)?.icon ?? appId, "application-x-executable")
                        }
                    }
                }

                StateLayer {
                    radius: Tokens.rounding.full
                    onClicked: Hypr.workspace(cell.wsId)
                }
            }
        }
    }

    WheelHandler {
        onWheel: event => Hypr.workspaceRelative(event.angleDelta.y > 0 ? -1 : 1)
    }
}
