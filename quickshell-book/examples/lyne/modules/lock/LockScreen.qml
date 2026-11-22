import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.components

// The lock screen (lyne's "center" template). Every monitor gets the blurred
// wallpaper; the monitor that was focused when locking also gets the clock,
// the password field, the player and the power buttons.
//
// Security comes from ext-session-lock: while locked, the compositor shows
// only these surfaces and sends them all input. If the shell crashed, the
// screen would stay locked.
WlSessionLock {
    id: root

    locked: LockService.locked
    readonly property string mainScreen: Hyprland.focusedMonitor?.name ?? ""
    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? null

    WlSessionLockSurface {
        id: surface
        readonly property bool isMain: screen?.name === root.mainScreen || Quickshell.screens.length === 1
        color: Config.backgroundColor

        // ── the blurred wallpaper ──
        Image {
            id: wall
            anchors.fill: parent
            source: WallpaperService.current ? "file://" + WallpaperService.current : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(surface.width / 2, surface.height / 2)     // blur hides the detail anyway
            visible: false
        }
        MultiEffect {
            anchors.fill: wall
            source: wall
            blurEnabled: true
            blur: 1
            blurMax: 64
            brightness: -0.15
        }

        SystemClock { id: clock; precision: SystemClock.Seconds }

        // every surface has an input: whichever has the keyboard edits the shared buffer
        TextInput {
            id: hidden
            opacity: 0                       // not visible: false (invisible items get no keyboard)
            focus: true
            text: LockService.buffer
            onTextEdited: { LockService.buffer = text; LockService.failed = false; }
            Keys.onReturnPressed: LockService.submit()
            Keys.onEnterPressed: LockService.submit()
            Keys.onEscapePressed: LockService.buffer = ""
        }

        // ── centre: clock, user, password ──
        ColumnLayout {
            anchors.centerIn: parent
            spacing: Config.spacing * 2

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "hh:mm")
                font.pixelSize: 110
                font.bold: true
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                font.pixelSize: Config.fontSizeLarge + 2
                color: Config.subtextColor
            }

            ColumnLayout {
                visible: surface.isMain
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Config.spacing * 4
                spacing: Config.spacing * 2

                Rectangle {                               // avatar: ~/.face, or the first letter
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 72
                    implicitHeight: 72
                    radius: 36
                    color: Config.accentColor
                    clip: true
                    StyledText { anchors.centerIn: parent; text: (Quickshell.env("USER") || "?")[0].toUpperCase(); font.pixelSize: 32; font.bold: true; color: Config.textReverseColor }
                    Image { anchors.fill: parent; source: "file://" + Quickshell.env("HOME") + "/.face"; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                }

                Rectangle {                               // the field: one dot per character
                    id: field
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 300
                    implicitHeight: 46
                    radius: height / 2
                    color: Config.backgroundTransparentColor
                    border.width: 2
                    border.color: LockService.failed ? Config.errorColor : LockService.checking ? Config.warningColor : Config.surface2Color

                    transform: Translate { id: shake }
                    SequentialAnimation {
                        id: shakeAnim
                        loops: 2
                        NumberAnimation { target: shake; property: "x"; to: -10; duration: 50 }
                        NumberAnimation { target: shake; property: "x"; to: 10; duration: 100 }
                        NumberAnimation { target: shake; property: "x"; to: 0; duration: 50 }
                    }
                    Connections {
                        target: LockService
                        function onFailedChanged() { if (LockService.failed) shakeAnim.restart(); }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Repeater {
                            model: LockService.buffer.length
                            Rectangle { width: 10; height: 10; radius: 5; color: Config.textColor }
                        }
                    }
                    StyledText {
                        anchors.centerIn: parent
                        visible: LockService.buffer.length === 0
                        text: LockService.checking ? "Checking…" : LockService.failed ? "Wrong password" : "Enter password"
                        color: LockService.failed ? Config.errorColor : Config.mutedColor
                    }
                    MouseArea { anchors.fill: parent; onClicked: hidden.forceActiveFocus() }
                }
            }
        }

        // ── bottom left: battery and keyboard hint ──
        Row {
            visible: surface.isMain && (UPower.displayDevice?.isLaptopBattery ?? false)
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: Config.spacing * 4
            spacing: Config.padding
            Glyph { text: UPower.onBattery ? Icons.battery : Icons.batteryCharging }
            StyledText { text: Math.round((UPower.displayDevice?.percentage ?? 0) * 100) + "%" }
        }

        // ── bottom centre: the player ──
        Rectangle {
            visible: surface.isMain && root.player !== null
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Config.spacing * 4
            implicitWidth: playerRow.implicitWidth + Config.spacing * 4
            implicitHeight: 48
            radius: height / 2
            color: Config.backgroundTransparentColor
            RowLayout {
                id: playerRow
                anchors.centerIn: parent
                spacing: Config.spacing
                Glyph { text: Icons.music; color: Config.accentColor }
                StyledText { Layout.maximumWidth: 260; text: (root.player?.trackTitle ?? "") + (root.player?.trackArtist ? "  ·  " + root.player.trackArtist : "") }
                BarButton { onClicked: root.player.previous(); Glyph { text: Icons.previous } }
                BarButton { onClicked: root.player.togglePlaying(); Glyph { text: root.player?.isPlaying ? Icons.pause : Icons.play } }
                BarButton { onClicked: root.player.next(); Glyph { text: Icons.next } }
            }
        }

        // ── bottom right: suspend, restart, shut down ──
        Row {
            visible: surface.isMain
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Config.spacing * 4
            spacing: Config.spacing
            Repeater {
                model: [[Icons.sleep, ["systemctl", "suspend"]], [Icons.restart, ["systemctl", "reboot"]], [Icons.power, ["systemctl", "poweroff"]]]
                Rectangle {
                    required property var modelData
                    width: 44
                    height: 44
                    radius: 22
                    color: pMouse.containsMouse ? Config.surface1Color : Config.backgroundTransparentColor
                    Glyph { anchors.centerIn: parent; text: parent.modelData[0] }
                    MouseArea { id: pMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(parent.modelData[1]) }
                }
            }
        }
    }
}
