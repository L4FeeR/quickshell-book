import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.components

// The wallpaper picker (Super+B): a carousel of thumbnails at the bottom of
// the focused screen, the selected one in the middle and bigger.
// Left/right or the wheel move, Enter or a click applies, Esc closes.
PanelWindow {
    id: root

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { bottom: true; left: true; right: true }
    margins.bottom: Config.spacing * 4
    implicitHeight: 230
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lyne_wallpapers"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    HyprlandFocusGrab { active: true; windows: [root]; onCleared: WallpaperService.pickerVisible = false }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: Config.spacing * 4
        anchors.rightMargin: Config.spacing * 4
        radius: Config.radiusLarge
        color: Config.backgroundTransparentColor

        StyledText {
            anchors.centerIn: parent
            visible: WallpaperService.files.length === 0
            text: "No images in " + WallpaperService.folder
            color: Config.mutedColor
        }

        ListView {
            id: view
            anchors.fill: parent
            anchors.margins: Config.spacing * 2
            orientation: ListView.Horizontal
            spacing: Config.spacing
            clip: true
            focus: true
            model: WallpaperService.files
            // keep the selection in the middle
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: width / 2 - 150
            preferredHighlightEnd: width / 2 + 150
            highlightMoveDuration: Config.animDuration
            Component.onCompleted: currentIndex = Math.max(0, WallpaperService.files.indexOf(WallpaperService.current))

            Keys.onEscapePressed: WallpaperService.pickerVisible = false
            Keys.onReturnPressed: WallpaperService.set(WallpaperService.files[currentIndex])
            WheelHandler { onWheel: e => e.angleDelta.y > 0 ? view.decrementCurrentIndex() : view.incrementCurrentIndex() }

            delegate: Item {
                id: tile
                required property string modelData
                required property int index
                readonly property bool current: ListView.isCurrentItem
                width: 300
                height: view.height

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    scale: tile.current ? 1 : 0.82                // the sides are smaller
                    opacity: tile.current ? 1 : 0.7
                    Behavior on scale { NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: Config.animDuration } }
                    radius: Config.radius
                    color: Config.surface1Color
                    border.width: tile.current ? 3 : 0
                    border.color: Config.accentColor
                    clip: true
                    Image {
                        anchors.fill: parent
                        anchors.margins: 3
                        source: "file://" + tile.modelData
                        sourceSize: Qt.size(640, 360)            // one small decode per thumbnail
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    Rectangle {                                 // "in use" mark
                        visible: WallpaperService.current === tile.modelData
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        width: 26
                        height: 26
                        radius: 13
                        color: Config.accentColor
                        Glyph { anchors.centerIn: parent; text: Icons.check; color: Config.textReverseColor; font.pixelSize: 14 }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tile.current ? WallpaperService.set(tile.modelData) : view.currentIndex = tile.index
                }
            }
        }
    }
}
