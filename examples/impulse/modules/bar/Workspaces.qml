import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// end-4's workspace indicator: occupied workspaces get one merged background, the active one a
// pill that "trails" (front edge fast, back edge slow), and each workspace shows the icon of its
// window. Holding Super swaps icons for numbers.
Item {
    id: root

    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int shown: Config.options.bar.workspaces.shown
    readonly property int activeId: monitor?.activeWorkspace?.id ?? 1
    readonly property int group: Math.floor((activeId - 1) / shown)
    readonly property real button: Appearance.sizes.workspaceButton
    readonly property int activeIndex: (activeId - 1) % shown

    function wsAt(index: int): HyprlandWorkspace {
        return Hyprland.workspaces.values.find(w => w.id === group * shown + index + 1) ?? null;
    }
    function occupied(index: int): bool {
        return index >= 0 && index < shown && (wsAt(index)?.toplevels.values.length ?? 0) > 0;
    }

    implicitWidth: button * shown
    implicitHeight: button

    // 1. occupied backgrounds: each over-stretches toward occupied neighbours, so runs merge
    Repeater {
        model: root.shown

        Rectangle {
            required property int index
            readonly property bool occ: root.occupied(index)
            readonly property bool prev: root.occupied(index - 1)
            readonly property bool next: root.occupied(index + 1)
            property real leftEdge: occ ? index * root.button - (prev ? root.button / 2 : 0) : index * root.button + root.button / 2
            property real rightEdge: occ ? (index + 1) * root.button + (next ? root.button / 2 : 0) : index * root.button + root.button / 2

            x: leftEdge
            width: rightEdge - leftEdge
            height: root.button
            radius: root.button / 2
            color: ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, 0.4)

            Behavior on leftEdge { animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this) }
            Behavior on rightEdge { animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this) }
        }
    }

    // 2. the trailing active indicator
    Rectangle {
        id: active

        readonly property real target: root.activeIndex * root.button + 2
        property real leftEdge: target
        property real rightEdge: target + root.button - 4
        property bool movingRight: false

        onTargetChanged: {
            movingRight = target > leftEdge;
            leftEdge = target;
            rightEdge = target + root.button - 4;
        }

        x: leftEdge
        y: 2
        width: rightEdge - leftEdge
        height: root.button - 4
        radius: height / 2
        color: Appearance.colors.colPrimary

        Behavior on leftEdge {
            NumberAnimation { duration: active.movingRight ? 500 : 250; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial }
        }
        Behavior on rightEdge {
            NumberAnimation { duration: active.movingRight ? 250 : 500; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial }
        }
    }

    // 3. numbers / app icons on top
    Row {
        Repeater {
            model: root.shown

            Item {
                id: cell

                required property int index
                readonly property int wsId: root.group * root.shown + index + 1
                readonly property bool isActive: index === root.activeIndex
                readonly property HyprlandToplevel biggest: {
                    const ws = root.wsAt(index);
                    if (!ws) return null;
                    const list = ws.toplevels.values;
                    return list.length ? list.reduce((a, b) => ((a.lastIpcObject.size?.[0] ?? 0) * (a.lastIpcObject.size?.[1] ?? 0)
                                                              >= (b.lastIpcObject.size?.[0] ?? 0) * (b.lastIpcObject.size?.[1] ?? 0) ? a : b)) : null;
                }
                readonly property bool showIcon: Config.options.bar.workspaces.showAppIcons && biggest !== null && !GlobalStates.superDown

                width: root.button
                height: root.button

                StyledText {
                    anchors.centerIn: parent
                    opacity: cell.showIcon ? 0 : 1
                    text: cell.wsId
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: cell.isActive ? Appearance.colors.colOnPrimary
                         : root.occupied(cell.index) ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
                    Behavior on opacity { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                }

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: cell.showIcon ? root.button * 0.69 : 0
                    opacity: cell.showIcon ? 1 : 0
                    source: Quickshell.iconPath(DesktopEntries.heuristicLookup(cell.biggest?.lastIpcObject.class ?? "")?.icon ?? "", "image-missing")
                    Behavior on implicitSize { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                    Behavior on opacity { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                        else Hypr.workspace(cell.wsId);
                    }
                }
            }
        }
    }

    WheelHandler {
        onWheel: event => Hypr.workspaceRelative(event.angleDelta.y < 0 ? 1 : -1)
    }
}
