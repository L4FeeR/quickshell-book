import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// end-4's overview: a search box (apps, math, commands, web) above a grid of workspaces that
// show live, scaled-down previews of their windows. Type to search; click a window to focus it.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property ShellScreen modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
            readonly property bool open: GlobalStates.overviewOpen && Hyprland.focusedMonitor === monitor

            screen: modelData
            visible: open
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:overview"
            WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            onOpenChanged: if (open) { search.text = ""; search.forceActiveFocus(); HyprlandData.refresh(); }

            MouseArea {
                anchors.fill: parent
                onClicked: GlobalStates.overviewOpen = false
            }

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                y: Appearance.sizes.barHeight + 20
                spacing: 16

                // ---- search ----
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 460
                    implicitHeight: 48
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colLayer0
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        MaterialSymbol { text: "search"; iconSize: 22; color: Appearance.colors.colOnLayer0 }
                        TextField {
                            id: search
                            Layout.fillWidth: true
                            background: null
                            color: Appearance.colors.colOnLayer0
                            placeholderText: "Search, calculate or run"
                            placeholderTextColor: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.small
                            onTextChanged: { LauncherSearch.query = text; results.currentIndex = 0; }
                            Keys.onEscapePressed: GlobalStates.overviewOpen = false
                            Keys.onDownPressed: results.currentIndex = Math.min(results.count - 1, results.currentIndex + 1)
                            Keys.onUpPressed: results.currentIndex = Math.max(0, results.currentIndex - 1)
                            onAccepted: {
                                const r = LauncherSearch.results[results.currentIndex];
                                if (r) { r.run(); GlobalStates.overviewOpen = false; }
                            }
                        }
                    }
                }

                // ---- results (only while typing) ----
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    visible: search.text !== ""
                    implicitWidth: 460
                    implicitHeight: Math.min(400, results.contentHeight + 16)
                    radius: Appearance.rounding.large
                    color: Appearance.colors.colLayer0

                    ListView {
                        id: results
                        anchors.fill: parent
                        anchors.margins: 8
                        clip: true
                        model: LauncherSearch.results
                        highlight: Rectangle { radius: Appearance.rounding.normal; color: Appearance.colors.colLayer1Hover }
                        highlightMoveDuration: 100
                        delegate: RippleButton {
                            id: res
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 50
                            buttonRadius: Appearance.rounding.normal
                            onClicked: { modelData.run(); GlobalStates.overviewOpen = false; }
                            contentItem: RowLayout {
                                spacing: 12
                                Loader {
                                    Layout.leftMargin: 10
                                    sourceComponent: res.modelData.iconName !== undefined ? appIcon : symbolIcon
                                    Component { id: appIcon; AppIconImage { name: res.modelData.iconName } }
                                    Component { id: symbolIcon; MaterialSymbol { text: res.modelData.icon; iconSize: 26 } }
                                }
                                ColumnLayout {
                                    spacing: 0
                                    StyledText { text: res.modelData.type; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
                                    StyledText { Layout.fillWidth: true; text: res.modelData.name; elide: Text.ElideRight; color: Appearance.colors.colOnLayer0 }
                                }
                            }
                        }
                    }
                }

                // ---- workspace grid (hidden while typing) ----
                OverviewGrid {
                    Layout.alignment: Qt.AlignHCenter
                    visible: search.text === ""
                    monitor: win.monitor
                    screen: win.modelData
                }
            }
        }
    }

    IpcHandler {
        target: "overview"
        function toggle(): void { GlobalStates.overviewOpen = !GlobalStates.overviewOpen }
    }
    GlobalShortcut {
        appid: "impulse"
        name: "overviewToggle"
        onPressed: GlobalStates.overviewOpen = !GlobalStates.overviewOpen
    }
}
