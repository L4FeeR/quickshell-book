import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Fullscreen session menu: a dimmed screen with big rounded buttons. Arrow keys move the
// focus, Enter runs it, Esc closes; the hovered/focused button's name shows below.
Scope {
    id: root

    readonly property var actions: [
        ["lock", "Lock", () => Quickshell.execDetached(["loginctl", "lock-session"])],
        ["dark_mode", "Sleep", () => Quickshell.execDetached(["systemctl", "suspend"])],
        ["logout", "Logout", () => Quickshell.execDetached(["loginctl", "terminate-user", Quickshell.env("USER")])],
        ["power_settings_new", "Shutdown", () => Quickshell.execDetached(["systemctl", "poweroff"])],
        ["restart_alt", "Reboot", () => Quickshell.execDetached(["systemctl", "reboot"])]
    ]

    LazyLoader {
        active: GlobalStates.sessionOpen

        PanelWindow {
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: Qt.rgba(0, 0, 0, 0.5)
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell:session"

            MouseArea { anchors.fill: parent; onClicked: GlobalStates.sessionOpen = false }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 18

                StyledText { Layout.alignment: Qt.AlignHCenter; text: "Session"; font.family: Appearance.font.family.title; font.pixelSize: Appearance.font.pixelSize.title; color: "white" }
                StyledText { Layout.alignment: Qt.AlignHCenter; text: "Arrow keys to navigate, Enter to select, Esc to cancel"; color: "#cccccc" }

                RowLayout {
                    id: row
                    property int current: 0
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 14
                    focus: true
                    Keys.onLeftPressed: current = (current + root.actions.length - 1) % root.actions.length
                    Keys.onRightPressed: current = (current + 1) % root.actions.length
                    Keys.onEscapePressed: GlobalStates.sessionOpen = false
                    Keys.onReturnPressed: { GlobalStates.sessionOpen = false; root.actions[current][2](); }

                    Repeater {
                        model: root.actions
                        RippleButton {
                            id: action
                            required property var modelData
                            required property int index
                            implicitWidth: 110
                            implicitHeight: 110
                            buttonRadius: row.current === index ? Appearance.rounding.verylarge : Appearance.rounding.large
                            toggled: row.current === index
                            colBackground: Appearance.colors.colLayer1
                            onHoveredChanged: if (hovered) row.current = index
                            onClicked: { GlobalStates.sessionOpen = false; modelData[2](); }
                            contentItem: MaterialSymbol {
                                horizontalAlignment: Text.AlignHCenter
                                text: action.modelData[0]
                                iconSize: 44
                                color: action.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                            }
                            Behavior on buttonRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                        }
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: label.implicitWidth + 30
                    implicitHeight: 36
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colTooltip
                    StyledText { id: label; anchors.centerIn: parent; text: root.actions[row.current][1]; color: Appearance.colors.colOnTooltip }
                }
            }
        }
    }

    IpcHandler {
        target: "session"
        function toggle(): void { GlobalStates.sessionOpen = !GlobalStates.sessionOpen }
    }
}
