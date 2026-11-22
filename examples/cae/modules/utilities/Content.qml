import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components
import qs.modules.settings

// The bottom-right corner drawer: quick toggles.
ColumnLayout {
    id: root

    property bool caffeine: false

    spacing: Tokens.spacing.medium
    implicitWidth: grid.implicitWidth + Tokens.padding.large * 2

    StyledText {
        Layout.leftMargin: Tokens.padding.large
        Layout.topMargin: Tokens.padding.large
        text: "Quick toggles"
        font.weight: 600
    }

    GridLayout {
        id: grid
        Layout.leftMargin: Tokens.padding.large
        Layout.rightMargin: Tokens.padding.large
        Layout.bottomMargin: Tokens.padding.large
        columns: 3
        rowSpacing: Tokens.spacing.small
        columnSpacing: Tokens.spacing.small

        IconButton { icon: "wifi"; size: 52; toggle: true; checked: Networking.wifiEnabled; onClicked: Networking.wifiEnabled = !Networking.wifiEnabled }
        IconButton {
            icon: "bluetooth"; size: 52; toggle: true
            checked: Bluetooth.defaultAdapter?.enabled ?? false
            onClicked: if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
        }
        IconButton { icon: Audio.micMuted ? "mic_off" : "mic"; size: 52; toggle: true; checked: !Audio.micMuted; onClicked: Audio.toggleMicMute() }
        IconButton { icon: "do_not_disturb_on"; size: 52; toggle: true; checked: Notifs.dnd; onClicked: Notifs.dnd = !Notifs.dnd }
        IconButton { icon: "coffee"; size: 52; toggle: true; checked: root.caffeine; onClicked: root.caffeine = !root.caffeine }
        IconButton { icon: "settings"; size: 52; onClicked: Settings.open() }
        IconButton { icon: "screenshot_region"; size: 52; onClicked: Quickshell.execDetached(["sh", "-c", "grim -g \"$(slurp)\" - | wl-copy"]) }
    }

    IdleInhibitor {
        window: root.QsWindow.window
        enabled: root.caffeine
    }
}
