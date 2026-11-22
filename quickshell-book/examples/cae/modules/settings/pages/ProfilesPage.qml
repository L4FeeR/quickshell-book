import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components
import qs.modules.settings

// Managing the rice as a whole: named profiles, backups, defaults, and the shell itself.
SettingsPage {
    id: root

    title: "Profiles & data"
    subtitle: "Save your whole setup (settings + wallpaper) as a profile and switch between rices in one click."

    Component.onCompleted: Profiles.refresh()

    Section {
        title: "Profiles"

        SettingRow {
            icon: "add_circle"
            title: "Save current setup"
            description: "Stores every setting and the wallpaper under a name"
            keywords: "profile save preset rice"

            RowLayout {
                spacing: Tokens.spacing.small
                TextField {
                    id: nameField
                    implicitWidth: 180
                    placeholderText: "profile name"
                    placeholderTextColor: Colours.palette.m3outline
                    color: Colours.palette.m3onSurface
                    background: StyledRect { radius: Tokens.rounding.small; color: Colours.palette.m3surfaceContainerHighest }
                    onAccepted: saveButton.clicked()
                }
                IconButton {
                    id: saveButton
                    icon: "save"
                    toggle: true
                    checked: nameField.text.trim() !== ""
                    onClicked: { Profiles.save(nameField.text); nameField.text = ""; }
                }
            }
        }

        Repeater {
            model: Profiles.names

            SettingRow {
                id: profile
                required property string modelData
                icon: "inventory_2"
                title: modelData
                description: "Saved profile"
                keywords: "profile rice"

                RowLayout {
                    spacing: Tokens.spacing.small
                    IconButton { icon: "check"; toggle: true; checked: true; onClicked: Profiles.load(profile.modelData) }
                    IconButton { icon: "delete"; onClicked: Profiles.remove(profile.modelData) }
                }
            }
        }
    }

    Section {
        title: "Backup and reset"

        SettingRow {
            icon: "download"
            title: "Export settings"
            description: "Copies shell.json to ~/cae-settings-backup.json"
            keywords: "backup export save file"
            IconButton { icon: "download"; onClicked: Profiles.exportTo(Quickshell.env("HOME") + "/cae-settings-backup.json") }
        }
        SettingRow {
            icon: "restart_alt"
            title: "Reset everything"
            description: "Restores every setting to its default (profiles are kept)"
            keywords: "defaults reset restore"
            IconButton { icon: "restart_alt"; activeColour: Colours.palette.m3error; onClicked: Profiles.resetToDefaults() }
        }
    }

    Section {
        title: "The shell"

        SettingRow {
            icon: "folder_open"
            title: "Open config folder"
            description: Config.dir
            keywords: "files path json"
            IconButton { icon: "open_in_new"; onClicked: Quickshell.execDetached(["xdg-open", Config.dir]) }
        }
        SettingRow {
            icon: "refresh"
            title: "Reload the shell"
            description: "Restarts every panel (settings are kept)"
            keywords: "restart reload"
            IconButton { icon: "refresh"; onClicked: Quickshell.execDetached(["qs", "-c", "cae", "ipc", "call", "shell", "reload"]) }
        }
    }

    StyledText {
        Layout.topMargin: Tokens.spacing.large
        visible: Profiles.lastMessage !== ""
        text: "✓ " + Profiles.lastMessage
        color: Colours.palette.m3primary
    }
}
