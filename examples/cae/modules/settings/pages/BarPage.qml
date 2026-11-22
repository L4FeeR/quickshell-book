import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components
import qs.modules.settings

SettingsPage {
    title: "Bar"
    subtitle: "The vertical bar on the left side of the frame."

    Section {
        title: "Behaviour"

        SwitchRow {
            icon: "push_pin"
            title: "Always visible"
            description: "Off: the bar hides and slides out when you touch the left edge"
            keywords: "persistent autohide auto hide"
            value: Config.bar.persistent
            defaultValue: true
            onEdited: v => Config.bar.persistent = v
        }
    }

    Section {
        title: "Workspaces"

        SpinRow {
            icon: "grid_view"
            title: "Workspaces shown"
            description: "How many workspaces form one group"
            from: 1; to: 10
            value: Config.bar.workspacesShown
            defaultValue: 5
            onEdited: v => Config.bar.workspacesShown = v
        }
        SwitchRow {
            icon: "apps"
            title: "Window icons"
            description: "Show the icons of each workspace's windows"
            keywords: "app icons"
            value: Config.bar.workspaceWindows
            defaultValue: true
            onEdited: v => Config.bar.workspaceWindows = v
        }
    }

    Section {
        title: "Modules (top to bottom)"

        EntriesEditor {
            value: Config.bar.entries
            onEdited: v => Config.bar.entries = v
        }
    }
}
