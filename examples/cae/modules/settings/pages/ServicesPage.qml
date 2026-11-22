import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components
import qs.modules.settings

SettingsPage {
    title: "Services"
    subtitle: "Steps, programs and paths the shell uses."

    Section {
        title: "Steps"

        SliderRow {
            icon: "volume_up"
            title: "Volume step"
            description: "Per scroll notch and per key press"
            from: 0.01; to: 0.2; stepSize: 0.01
            value: Config.services.audioStep
            defaultValue: 0.05
            onEdited: v => Config.services.audioStep = v
        }
        SliderRow {
            icon: "light_mode"
            title: "Brightness step"
            from: 0.01; to: 0.2; stepSize: 0.01
            value: Config.services.brightnessStep
            defaultValue: 0.05
            onEdited: v => Config.services.brightnessStep = v
        }
    }

    Section {
        title: "Programs and files"

        TextRow {
            icon: "terminal"
            title: "Terminal"
            description: "Used by launcher actions"
            value: Config.services.terminal
            defaultValue: "kitty"
            onEdited: v => Config.services.terminal = v
        }
        TextRow {
            icon: "account_circle"
            title: "Profile picture"
            description: "Shown on the dashboard and the lock screen"
            keywords: "avatar face"
            value: Config.paths.face
            onEdited: v => Config.paths.face = v
        }
    }
}
