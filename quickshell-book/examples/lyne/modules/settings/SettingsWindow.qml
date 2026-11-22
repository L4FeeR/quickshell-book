import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.components

// The Settings app (Super+I). A normal window, so it can stay open while you
// try things: every row writes to state.json immediately and the shell
// follows live. Pages on the left, the current page on the right.
FloatingWindow {
    id: root

    title: "lyne settings"
    implicitWidth: 860
    implicitHeight: 620
    minimumSize: Qt.size(640, 420)
    color: Config.backgroundColor
    onClosed: SettingsService.close()             // the window's own close button

    readonly property var pages: [
        { id: "appearance",    label: "Appearance",    icon: Icons.palette },
        { id: "bar",           label: "Bar",           icon: Icons.window },
        { id: "notifications", label: "Notifications", icon: Icons.bell },
        { id: "osd",           label: "OSD",           icon: Icons.volumeHigh },
        { id: "idle",          label: "Idle and lock", icon: Icons.lock },
        { id: "wallpaper",     label: "Wallpaper",     icon: Icons.wallpaper }
    ]

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── sidebar ──
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 220
            color: Config.surface0Color
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Config.spacing
                spacing: 2
                Row {
                    Layout.margins: Config.spacing
                    spacing: Config.spacing
                    LyneMark { height: 22; width: 26 }
                    StyledText { text: "Settings"; font.bold: true; font.pixelSize: Config.fontSizeLarge }
                }
                Repeater {
                    model: root.pages
                    Rectangle {
                        id: nav
                        required property var modelData
                        readonly property bool current: SettingsService.page === modelData.id
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: Config.radius
                        color: current ? Config.surface1Color : navMouse.containsMouse ? Qt.alpha(Config.surface1Color, 0.5) : "transparent"
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            x: Config.spacing
                            spacing: Config.spacing
                            Glyph { text: nav.modelData.icon; color: nav.current ? Config.accentColor : Config.subtextColor }
                            StyledText { text: nav.modelData.label; font.bold: nav.current }
                        }
                        MouseArea { id: navMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: SettingsService.page = nav.modelData.id }
                    }
                }
                Item { Layout.fillHeight: true }
                StyledText {
                    Layout.margins: Config.spacing
                    Layout.fillWidth: true
                    text: "Saved in ~/.config/lyne/state.json"
                    wrapMode: Text.Wrap
                    font.pixelSize: Config.fontSizeSmall - 1
                    color: Config.mutedColor
                }
            }
        }

        // ── the page ──
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: page.implicitHeight + Config.spacing * 6
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Loader {
                id: page
                x: Config.spacing * 3
                y: Config.spacing * 3
                width: parent.width - Config.spacing * 6
                sourceComponent: ({ appearance: appearancePage, bar: barPage, notifications: notifPage, osd: osdPage, idle: idlePage, wallpaper: wallpaperPage })[SettingsService.page] ?? appearancePage
            }
        }
    }

    component Heading: StyledText {
        Layout.topMargin: Config.spacing
        font.bold: true
        font.pixelSize: Config.fontSizeLarge + 2
    }

    // ── Pages ──────────────────────────────────────────────────────────────
    Component {
        id: appearancePage
        ColumnLayout {
            spacing: Config.spacing
            Heading { text: "Theme" }
            GridLayout {                                   // one tile per theme, painted in its own colours
                Layout.fillWidth: true
                columns: 3
                rowSpacing: Config.spacing
                columnSpacing: Config.spacing
                Repeater {
                    model: ThemeService.list
                    Rectangle {
                        id: tile
                        required property var modelData
                        readonly property bool current: ThemeService.currentName === modelData.slug
                        Layout.fillWidth: true
                        implicitHeight: 84
                        radius: Config.radius
                        color: modelData.palette.background
                        border.width: current ? 3 : 1
                        border.color: current ? Config.accentColor : Config.surface2Color
                        Column {
                            anchors.fill: parent
                            anchors.margins: Config.spacing + 2
                            spacing: Config.spacing
                            StyledText { text: tile.modelData.name; color: tile.modelData.palette.text; font.bold: true; font.pixelSize: Config.fontSizeSmall }
                            Row {
                                spacing: 4
                                Repeater {
                                    model: ["accent", "success", "warning", "error", "surface2", "subtext"]
                                    Rectangle { required property string modelData; width: 16; height: 16; radius: 8; color: tile.modelData.palette[modelData] }
                                }
                            }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ThemeService.set(tile.modelData.slug) }
                    }
                }
            }
            SwitchRow { path: "animations.themeTransition"; title: "Fade between themes"; description: "Colours glide to the new theme instead of switching at once" }
            Heading { text: "Look" }
            SliderRow { path: "opacity.background"; title: "Background opacity"; from: 0.5; to: 1; step: 0.05; factor: 100; unit: "%" }
            SliderRow { path: "geometry.radius"; title: "Corner radius"; from: 0; to: 20; step: 1; unit: " px" }
            SliderRow { path: "geometry.radiusLarge"; title: "Panel corner radius"; from: 0; to: 28; step: 1; unit: " px" }
            SliderRow { path: "typography.sizeNormal"; title: "Text size"; from: 10; to: 20; step: 1; unit: " px" }
            SliderRow { path: "animations.normal"; title: "Animation speed"; description: "Length of most animations"; from: 0; to: 600; step: 10; unit: " ms" }
        }
    }

    Component {
        id: barPage
        ColumnLayout {
            spacing: Config.spacing
            Heading { text: "Bar" }
            ChoiceRow { path: "bar.style"; title: "Style"; options: [["docked", "Docked"], ["docked-corners", "Corners"], ["floating", "Floating"], ["islands", "Islands"]] }
            ChoiceRow { path: "bar.position"; title: "Position"; options: [["top", "Top"], ["bottom", "Bottom"]] }
            SliderRow { path: "bar.height"; title: "Height"; from: 26; to: 48; step: 1; unit: " px" }
            SliderRow { path: "bar.margin"; title: "Gap around a floating bar"; from: 0; to: 24; step: 1; unit: " px" }
            SwitchRow { path: "bar.autoHide"; title: "Auto-hide"; description: "Slides away; touch the screen edge to bring it back" }
            Heading { text: "Workspaces" }
            ChoiceRow { path: "bar.workspaces.style"; title: "Style"; options: [["pills", "Pills"], ["dots", "Dots"], ["numbers", "Numbers"]] }
            SliderRow { path: "bar.workspaces.count"; title: "Workspaces shown"; from: 3; to: 10; step: 1 }
        }
    }

    Component {
        id: notifPage
        ColumnLayout {
            spacing: Config.spacing
            Heading { text: "Notifications" }
            SwitchRow { path: "notifications.dnd"; title: "Do not disturb"; description: "Only critical notifications pop up" }
            SliderRow { path: "notifications.timeout"; title: "Popup time"; from: 1000; to: 15000; step: 500; factor: 0.001; unit: " s" }
            SliderRow { path: "notifications.maxPopups"; title: "Popups at once"; from: 1; to: 8; step: 1 }
            SliderRow { path: "notifications.width"; title: "Width"; from: 280; to: 480; step: 10; unit: " px" }
        }
    }

    Component {
        id: osdPage
        ColumnLayout {
            spacing: Config.spacing
            Heading { text: "On-screen display" }
            ChoiceRow { path: "osd.style"; title: "Style"; options: [["attached", "Attached"], ["pill", "Pill"]] }
            SliderRow { path: "osd.timeout"; title: "Visible for"; from: 500; to: 5000; step: 100; factor: 0.001; unit: " s" }
        }
    }

    Component {
        id: idlePage
        ColumnLayout {
            spacing: Config.spacing
            Heading { text: "Idle" }
            SwitchRow { path: "idle.caffeine"; title: "Caffeine"; description: "Never lock or turn the screen off on idle" }
            SliderRow { path: "idle.lockTimeout"; title: "Lock after"; description: "0 = never"; from: 0; to: 1800; step: 60; factor: 1 / 60; unit: " min" }
            SliderRow { path: "idle.dpmsTimeout"; title: "Screen off after"; description: "0 = never"; from: 0; to: 3600; step: 60; factor: 1 / 60; unit: " min" }
            Heading { text: "Power menu" }
            SliderRow { path: "power.countdown"; title: "Countdown before restart or shut down"; from: 0; to: 10; step: 1; unit: " s" }
        }
    }

    Component {
        id: wallpaperPage
        ColumnLayout {
            spacing: Config.spacing
            Heading { text: "Wallpaper" }
            SettingRow {
                path: "wallpaper.current"
                title: "Current"
                description: WallpaperService.current || "None chosen yet"
                BarButton { onClicked: WallpaperService.togglePicker(); Glyph { text: Icons.image } StyledText { text: "Choose…"; font.pixelSize: Config.fontSizeSmall } }
            }
            SettingRow {
                path: "wallpaper.folder"
                title: "Folder"
                description: WallpaperService.folder + "  (" + WallpaperService.files.length + " images)"
            }
        }
    }
}
