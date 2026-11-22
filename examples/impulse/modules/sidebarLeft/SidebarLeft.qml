import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// The left sidebar. end-4's real one hosts an AI chat, a translator and an anime image browser.
// This rebuild keeps the same tabbed structure with two tools that need no API keys:
// a translator (translate-shell) and clipboard history (cliphist).
Scope {
    PanelWindow {
        id: win
        visible: GlobalStates.sidebarLeftOpen
        anchors { top: true; left: true; bottom: true }
        implicitWidth: Appearance.sizes.sidebarWidth
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "quickshell:sidebarLeft"
        WlrLayershell.keyboardFocus: GlobalStates.sidebarLeftOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        HyprlandFocusGrab {
            windows: [win]
            active: win.visible
            onCleared: GlobalStates.sidebarLeftOpen = false
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: Appearance.sizes.hyprlandGapsOut
            anchors.rightMargin: Appearance.sizes.elevationMargin
            radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            focus: true
            Keys.onEscapePressed: GlobalStates.sidebarLeftOpen = false

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                // tab bar with a sliding underline
                Item {
                    id: tabBar
                    property int current: 0
                    Layout.fillWidth: true
                    implicitHeight: 44
                    Row {
                        id: tabRow
                        anchors.fill: parent
                        Repeater {
                            model: [["translate", "Translator"], ["content_paste", "Clipboard"]]
                            RippleButton {
                                id: tab
                                required property var modelData
                                required property int index
                                width: tabRow.width / 2
                                height: 40
                                onClicked: tabBar.current = index
                                contentItem: RowLayout {
                                    spacing: 6
                                    Item { Layout.fillWidth: true }
                                    MaterialSymbol { text: tab.modelData[0]; fill: tabBar.current === tab.index ? 1 : 0; color: tabBar.current === tab.index ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0 }
                                    StyledText { text: tab.modelData[1]; color: tabBar.current === tab.index ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0 }
                                    Item { Layout.fillWidth: true }
                                }
                            }
                        }
                    }
                    Rectangle {
                        y: parent.height - 3
                        x: tabBar.current * tabRow.width / 2 + tabRow.width / 8
                        width: tabRow.width / 4
                        height: 3
                        radius: 2
                        color: Appearance.colors.colPrimary
                        Behavior on x { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }
                    }
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: tabBar.current
                    Translator {}
                    ClipboardHistory { active: GlobalStates.sidebarLeftOpen && tabBar.current === 1 }
                }
            }
        }
    }

    IpcHandler {
        target: "sidebarLeft"
        function toggle(): void { GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen }
    }
    GlobalShortcut {
        appid: "impulse"
        name: "sidebarLeftToggle"
        onPressed: GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen
    }
}
