import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components
import qs.modules.settings

// What every shortcut does, the Hyprland line to bind it, and a button to try it now.
SettingsPage {
    id: root

    readonly property var binds: [
        { name: "launcher", keys: "Super (tap)", line: "bindr = SUPER, SUPER_L, global, cae:launcher", icon: "search", desc: "Open the launcher" },
        { name: "dashboard", keys: "Super + D", line: "bind = SUPER, D, global, cae:dashboard", icon: "dashboard", desc: "Toggle the dashboard" },
        { name: "sidebar", keys: "Super + A", line: "bind = SUPER, A, global, cae:sidebar", icon: "notifications", desc: "Toggle the notification centre" },
        { name: "utilities", keys: "Super + U", line: "bind = SUPER, U, global, cae:utilities", icon: "toggle_on", desc: "Toggle quick toggles" },
        { name: "session", keys: "Ctrl + Alt + Delete", line: "bind = CTRL ALT, Delete, global, cae:session", icon: "power_settings_new", desc: "Toggle the session menu" },
        { name: "settings", keys: "Super + Comma", line: "bind = SUPER, comma, global, cae:settings", icon: "settings", desc: "Open these settings" }
    ]

    title: "Keybinds"
    subtitle: "Add the lines to your Hyprland config. The play button runs the action now through IPC."

    Section {
        title: "Shortcuts"

        Repeater {
            model: root.binds

            SettingRow {
                id: row
                required property var modelData
                icon: modelData.icon
                title: modelData.desc
                description: modelData.line
                keywords: modelData.keys + " " + modelData.name

                RowLayout {
                    spacing: Tokens.spacing.small

                    StyledRect {
                        implicitWidth: keysText.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: 30
                        radius: Tokens.rounding.small
                        color: Colours.palette.m3surfaceContainerHighest
                        StyledText { id: keysText; anchors.centerIn: parent; text: row.modelData.keys; font.family: Tokens.font.mono }
                    }
                    IconButton {
                        icon: "content_copy"
                        size: 34
                        onClicked: Quickshell.execDetached(["wl-copy", row.modelData.line])
                    }
                    IconButton {
                        icon: "play_arrow"
                        size: 34
                        onClicked: Quickshell.execDetached(row.modelData.name === "settings"
                            ? ["qs", "-c", "cae", "ipc", "call", "settings", "open"]
                            : ["qs", "-c", "cae", "ipc", "call", "drawers", "toggle", row.modelData.name])
                    }
                }
            }
        }
    }
}
