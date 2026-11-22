import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Top: uptime and system buttons. Then quick toggles, sliders, notifications, calendar.
Rectangle {
    id: root

    radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
    color: Appearance.colors.colLayer0
    border.width: 1
    border.color: Appearance.colors.colLayer0Border

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // ---- header ----
        RowLayout {
            Layout.fillWidth: true
            StyledText {
                Layout.fillWidth: true
                text: "Up " + DateTime.uptime
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer0
            }
            Repeater {
                model: [["restart_alt", () => Quickshell.reload(true)],
                        ["settings", () => Quickshell.execDetached(["xdg-open", Config.dir + "/config.json"])],
                        ["power_settings_new", () => { GlobalStates.sidebarRightOpen = false; GlobalStates.sessionOpen = true }]]
                RippleButton {
                    id: sysButton
                    required property var modelData
                    implicitWidth: 36; implicitHeight: 36
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colLayer1
                    onClicked: modelData[1]()
                    contentItem: MaterialSymbol { horizontalAlignment: Text.AlignHCenter; text: sysButton.modelData[0]; iconSize: 20 }
                }
            }
        }

        // ---- quick toggles ----
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: toggles.implicitHeight + 16
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            RowLayout {
                id: toggles
                anchors.centerIn: parent
                spacing: 8

                QuickToggle { symbol: "wifi"; toggled: Networking.wifiEnabled; onClicked: Networking.wifiEnabled = !Networking.wifiEnabled }
                QuickToggle {
                    symbol: "bluetooth"
                    toggled: Bluetooth.defaultAdapter?.enabled ?? false
                    onClicked: if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                }
                QuickToggle { symbol: "nightlight"; toggled: nightLight.running; onClicked: nightLight.running = !nightLight.running }
                QuickToggle { symbol: "do_not_disturb_on"; toggled: Notifications.silent; onClicked: Notifications.silent = !Notifications.silent }
                QuickToggle { symbol: "mic_off"; toggled: Audio.micMuted; onClicked: Audio.toggleMicMute() }
            }
        }
        Process { id: nightLight; command: ["hyprsunset", "-t", "4500"] }

        // ---- sliders ----
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            SliderRow { symbol: "volume_up"; value: Audio.volume; onMoved: v => Audio.setVolume(v) }
            SliderRow { symbol: "light_mode"; visible: Brightness.available; value: Brightness.value; onMoved: v => Brightness.set(v) }
        }

        // ---- notifications ----
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            ListView {
                id: notifList
                anchors.fill: parent
                anchors.margins: 8
                anchors.bottomMargin: 48
                clip: true
                spacing: 6
                model: Notifications.list
                delegate: NotificationItem {
                    required property var modelData
                    wrapper: modelData
                    width: ListView.view.width
                }
            }
            StyledText {
                anchors.centerIn: parent
                visible: Notifications.list.length === 0
                text: "No notifications"
                color: Appearance.colors.colSubtext
            }
            RowLayout {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 8
                StyledText { text: Notifications.list.length + " notifications"; color: Appearance.colors.colSubtext }
                RippleButton {
                    implicitWidth: 90; implicitHeight: 32
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colLayer2
                    onClicked: Notifications.discardAll()
                    contentItem: StyledText { horizontalAlignment: Text.AlignHCenter; text: "Clear" }
                }
            }
        }

        // ---- calendar ----
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: cal.implicitHeight + 20
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1
            MonthGrid { id: cal; anchors.centerIn: parent }
        }
    }

    component QuickToggle: RippleButton {
        id: qt
        property string symbol
        implicitWidth: 44
        implicitHeight: 44
        buttonRadius: toggled ? Appearance.rounding.normal : Appearance.rounding.full
        colBackground: Appearance.colors.colLayer2
        contentItem: MaterialSymbol {
            horizontalAlignment: Text.AlignHCenter
            text: qt.symbol
            iconSize: 22
            fill: qt.toggled ? 1 : 0
            color: qt.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
        }
        Behavior on buttonRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
    }

    component SliderRow: RowLayout {
        id: sr
        property string symbol
        property real value
        signal moved(real v)
        Layout.fillWidth: true
        MaterialSymbol { text: sr.symbol; iconSize: 22; color: Appearance.colors.colOnLayer0 }
        Slider {
            id: s
            Layout.fillWidth: true
            from: 0; to: 1
            value: sr.value
            onMoved: sr.moved(value)
            background: Rectangle {
                y: s.topPadding + s.availableHeight / 2 - height / 2
                width: s.availableWidth; height: 14
                radius: Appearance.rounding.full
                color: Appearance.colors.colSecondaryContainer
                Rectangle { width: Math.max(height, s.visualPosition * parent.width); height: parent.height; radius: parent.radius; color: Appearance.colors.colPrimary }
            }
            handle: Rectangle {
                x: s.leftPadding + s.visualPosition * (s.availableWidth - width)
                y: s.topPadding + s.availableHeight / 2 - height / 2
                width: 4; height: 24
                radius: 2
                color: Appearance.colors.colPrimary
            }
        }
    }
}
