import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// The bar's layout, like end-4: on the left the sidebar button and active window; in the middle
// three rounded groups (resources + media | workspaces | clock + utilities + battery);
// on the right the status icons (they open the right sidebar) and the tray.
// Scrolling on the left half changes brightness, on the right half volume.
Rectangle {
    id: root

    required property ShellScreen screen

    color: Appearance.colors.colLayer0

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: event => {
            const step = event.angleDelta.y > 0 ? 0.05 : -0.05;
            if (event.x < width / 2) Brightness.set(Brightness.value + step);
            else Audio.setVolume(Audio.volume + step);
        }
    }

    // ---- left: sidebar button + active window ----
    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        RippleButton {
            id: leftButton
            implicitWidth: 32
            implicitHeight: 32
            buttonRadius: Appearance.rounding.full
            toggled: GlobalStates.sidebarLeftOpen
            onClicked: GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen
            contentItem: MaterialSymbol {
                horizontalAlignment: Text.AlignHCenter
                text: "auto_awesome"
                iconSize: Appearance.font.pixelSize.larger
                color: leftButton.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
            }
        }
        ActiveWindow {
            Layout.maximumWidth: root.width / 2 - centerGroups.width / 2 - 70
        }
    }

    // ---- centre: three groups ----
    RowLayout {
        id: centerGroups
        anchors.centerIn: parent
        spacing: 4

        BarGroup {
            Resources {}
            Media { Layout.maximumWidth: 200 }
        }
        BarGroup {
            Workspaces { screen: root.screen }
        }
        BarGroup {
            ClockWidget {}
            UtilButtons {}
            BatteryIndicator {}
        }
    }

    // ---- right: indicators + tray ----
    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        SysTray {}

        RippleButton {
            implicitWidth: indicators.implicitWidth + 20
            implicitHeight: 32
            buttonRadius: Appearance.rounding.full
            toggled: GlobalStates.sidebarRightOpen
            onClicked: GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen

            contentItem: RowLayout {
                id: indicators
                spacing: 8
                readonly property color fg: GlobalStates.sidebarRightOpen ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0

                MaterialSymbol { visible: Audio.muted; text: "volume_off"; color: indicators.fg; Layout.leftMargin: 10 }
                MaterialSymbol { visible: Audio.micMuted; text: "mic_off"; color: indicators.fg }
                StyledText {
                    visible: Notifications.unread > 0
                    text: Notifications.unread
                    color: indicators.fg
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }
                MaterialSymbol { text: "notifications"; color: indicators.fg; Layout.leftMargin: Audio.muted || Audio.micMuted ? 0 : 10 }
                MaterialSymbol { text: "wifi"; color: indicators.fg }
                MaterialSymbol { text: "bluetooth"; color: indicators.fg; Layout.rightMargin: 10 }
            }
        }
    }
}
