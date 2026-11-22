import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components
import qs.modules.settings

SettingsPage {
    title: "Panels"
    subtitle: "How the drawers open and behave."

    Section {
        title: "Opening on hover"

        SwitchRow {
            icon: "dashboard"
            title: "Dashboard on top edge"
            description: "Touch the middle of the top edge to open the dashboard"
            keywords: "hover"
            value: Config.dashboard.showOnHover
            defaultValue: true
            onEdited: v => Config.dashboard.showOnHover = v
        }
        SwitchRow {
            icon: "notifications"
            title: "Notification centre on top-right corner"
            keywords: "sidebar hover"
            value: Config.sidebar.showOnHover
            defaultValue: true
            onEdited: v => Config.sidebar.showOnHover = v
        }
    }

    Section {
        title: "Launcher"

        TextRow {
            icon: "terminal"
            title: "Command prefix"
            description: "Type this first to get actions like wallpaper and calc"
            keywords: "action"
            value: Config.launcher.actionPrefix
            defaultValue: ">"
            onEdited: v => Config.launcher.actionPrefix = v || ">"
        }
        SpinRow {
            icon: "format_list_numbered"
            title: "Results shown"
            from: 3; to: 15
            value: Config.launcher.maxShown
            defaultValue: 7
            onEdited: v => Config.launcher.maxShown = v
        }
    }

    Section {
        title: "Timing"

        SliderRow {
            icon: "timer"
            title: "Notification popup time"
            description: "When the app doesn't choose one"
            keywords: "expire timeout"
            from: 1000; to: 15000; stepSize: 500; decimals: 0; unit: " ms"
            value: Config.notifs.defaultExpire
            defaultValue: 5000
            onEdited: v => Config.notifs.defaultExpire = v
        }
        SliderRow {
            icon: "volume_up"
            title: "OSD hide delay"
            keywords: "volume brightness slider"
            from: 500; to: 5000; stepSize: 250; decimals: 0; unit: " ms"
            value: Config.osd.hideDelay
            defaultValue: 2000
            onEdited: v => Config.osd.hideDelay = v
        }
    }
}
