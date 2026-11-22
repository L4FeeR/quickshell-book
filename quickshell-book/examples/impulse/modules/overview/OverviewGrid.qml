import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// rows × columns workspaces, each a scaled copy of the monitor. Windows are placed using the
// positions from `hyprctl clients -j` and show live previews with ScreencopyView.
Rectangle {
    id: root

    required property HyprlandMonitor monitor
    required property ShellScreen screen
    readonly property int rows: Config.options.overview.rows
    readonly property int columns: Config.options.overview.columns
    readonly property real previewScale: Config.options.overview.scale
    readonly property real wsWidth: screen.width * previewScale
    readonly property real wsHeight: screen.height * previewScale
    readonly property int groupStart: Math.floor(((monitor?.activeWorkspace?.id ?? 1) - 1) / (rows * columns)) * rows * columns
    readonly property var monData: HyprlandData.monitors.find(m => m.name === screen.name) ?? null

    implicitWidth: grid.implicitWidth + 20
    implicitHeight: grid.implicitHeight + 20
    radius: Appearance.rounding.screenRounding
    color: Appearance.colors.colLayer0
    border.width: 1
    border.color: Appearance.colors.colLayer0Border

    Grid {
        id: grid
        anchors.centerIn: parent
        columns: root.columns
        spacing: 5

        Repeater {
            model: root.rows * root.columns

            Rectangle {
                id: ws

                required property int index
                readonly property int wsId: root.groupStart + index + 1
                readonly property bool isActive: root.monitor?.activeWorkspace?.id === wsId

                width: root.wsWidth
                height: root.wsHeight
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer1
                border.width: isActive ? 2 : 0
                border.color: Appearance.colors.colPrimary
                clip: true

                StyledText {
                    anchors.centerIn: parent
                    text: ws.wsId
                    font.pixelSize: ws.height * 0.4
                    font.weight: 700
                    color: Appearance.colors.colSubtext
                    opacity: 0.4
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: { Hypr.workspace(ws.wsId); GlobalStates.overviewOpen = false; }
                }

                DropArea {
                    anchors.fill: parent
                    onDropped: drop => Hypr.moveWindowToWorkspace(drop.source.address, ws.wsId)
                }

                Repeater {
                    model: HyprlandData.windowList.filter(w => w.workspace.id === ws.wsId)

                    Rectangle {
                        id: winItem

                        required property var modelData
                        readonly property string address: modelData.address
                        readonly property Toplevel toplevel: ToplevelManager.toplevels.values.find(t => `0x${t.HyprlandToplevel?.address}` === modelData.address) ?? null
                        readonly property real ox: root.monData ? root.monData.x : 0
                        readonly property real oy: root.monData ? root.monData.y : 0

                        x: (modelData.at[0] - ox) * root.previewScale
                        y: (modelData.at[1] - oy) * root.previewScale
                        width: modelData.size[0] * root.previewScale
                        height: modelData.size[1] * root.previewScale
                        radius: Appearance.rounding.verysmall
                        color: Appearance.colors.colLayer2
                        clip: true
                        Drag.active: drag.drag.active
                        Drag.source: winItem
                        Drag.hotSpot.x: width / 2
                        Drag.hotSpot.y: height / 2

                        ScreencopyView {
                            anchors.fill: parent
                            captureSource: GlobalStates.overviewOpen ? winItem.toplevel : null
                            live: true
                        }
                        AppIconImage {
                            anchors.centerIn: parent
                            name: DesktopEntries.heuristicLookup(winItem.modelData.class)?.icon ?? winItem.modelData.class
                            implicitSize: Math.min(winItem.width, winItem.height) * 0.35
                        }
                        MouseArea {
                            id: drag
                            anchors.fill: parent
                            drag.target: winItem
                            onClicked: { Hypr.focusWindow(winItem.address); GlobalStates.overviewOpen = false; }
                            onReleased: { winItem.Drag.drop(); winItem.x = Qt.binding(() => (winItem.modelData.at[0] - winItem.ox) * root.previewScale); winItem.y = Qt.binding(() => (winItem.modelData.at[1] - winItem.oy) * root.previewScale); }
                        }
                    }
                }
            }
        }
    }
}
