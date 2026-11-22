import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.popups

// The assembled bar: gallery chips in three groups. One instance per screen (see shell.qml).
PanelWindow {
    id: bar
    required property ShellScreen modelData
    // windows elsewhere in the shell that bar buttons open (passed in by shell.qml)
    property var notifCenter: null
    property var quickSettings: null
    property var powerMenu: null
    property var launcher: null

    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: 42
    color: "transparent"
    WlrLayershell.namespace: "quickshell:bar"

    Rectangle {
        anchors { fill: parent; topMargin: 6; leftMargin: 8; rightMargin: 8 }
        radius: 14
        color: "#1e1e2e"
        border.color: "#313244"

        // ── left ─────────────────────────────────────────────
        RowLayout {
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            spacing: 6
            Rectangle {                                          // launcher button
                implicitWidth: 30; implicitHeight: 26; radius: 13
                color: launchHover.hovered ? "#cba6f7" : "#313244"
                Text { anchors.centerIn: parent; text: "apps"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: launchHover.hovered ? "#1e1e2e" : "#cba6f7" }
                HoverHandler { id: launchHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: if (bar.launcher) bar.launcher.open = !bar.launcher.open }
            }
            WorkspaceList { screen: bar.screen }
            SubmapIndicator {}
            ActiveWindow { maxWidth: 260 }
        }

        // ── centre ───────────────────────────────────────────
        RowLayout {
            anchors.centerIn: parent
            spacing: 6
            CalendarPopup {}
            MediaMarquee {}
        }

        // ── right ────────────────────────────────────────────
        RowLayout {
            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
            spacing: 6
            LockKeys {}
            Tray {}
            NetworkChip { showName: false }
            BluetoothChip {}
            AudioMixer {}
            VolumeChip {}
            MicChip {}
            BatteryPopup {}
            NotificationBell {
                count: Notifs.count
                dnd: Notifs.dnd
                TapHandler { onTapped: if (bar.notifCenter) bar.notifCenter.open = !bar.notifCenter.open }
            }
            Rectangle {                                          // quick settings + power
                implicitWidth: 56; implicitHeight: 26; radius: 13
                color: "#313244"
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "tune"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: "#cdd6f4"
                        TapHandler { onTapped: if (bar.quickSettings) bar.quickSettings.open = !bar.quickSettings.open }
                    }
                    Text {
                        text: "power_settings_new"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: "#f38ba8"
                        TapHandler { onTapped: if (bar.powerMenu) bar.powerMenu.open = !bar.powerMenu.open }
                    }
                }
            }
        }
    }
}
