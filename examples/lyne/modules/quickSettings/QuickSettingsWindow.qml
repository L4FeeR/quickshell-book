import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import qs.config
import qs.services
import qs.components

// The Quick Settings panel that slides out under the status icons.
// The main page has toggle tiles and sliders; a tile's arrow opens a
// sub-page (Wi-Fi networks, Bluetooth devices, sound outputs), and the
// panel's height follows the page being shown.
AttachedPopup {
    id: root

    required property string screenName

    shown: QuickSettingsService.visible && QuickSettingsService.screenName === screenName
    onDismissed: QuickSettingsService.page === "main" ? QuickSettingsService.close() : QuickSettingsService.openPage("main")
    panelWidth: 360
    panelHeight: pages.implicitHeight + Config.spacing * 4
    Behavior on panelHeight { NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic } }

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var network: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property var adapter: Bluetooth.defaultAdapter

    // ── A toggle tile: icon + title + state, optional arrow to a sub-page ──
    component Tile: Rectangle {
        id: tile
        property string icon
        property string title
        property string status
        property bool on: false
        property string page: ""                   // sub-page opened by the arrow
        signal toggled

        Layout.fillWidth: true
        implicitHeight: 52
        radius: Config.radius
        color: on ? Config.accentColor : tileMouse.containsMouse ? Config.cardHoverColor : Config.cardColor
        Behavior on color { enabled: !Config.themeTransitioning; ColorAnimation { duration: Config.animDuration } }

        MouseArea { id: tileMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tile.toggled() }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Config.spacing + 4
            anchors.rightMargin: Config.padding
            spacing: Config.spacing
            Glyph { text: tile.icon; color: tile.on ? Config.textReverseColor : Config.textColor }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                StyledText { Layout.fillWidth: true; text: tile.title; font.bold: true; font.pixelSize: Config.fontSizeSmall; color: tile.on ? Config.textReverseColor : Config.textColor }
                StyledText { Layout.fillWidth: true; visible: text !== ""; text: tile.status; font.pixelSize: Config.fontSizeSmall - 1; color: tile.on ? Qt.alpha(Config.textReverseColor, 0.75) : Config.subtextColor }
            }
            Glyph {
                visible: tile.page !== ""
                text: Icons.chevronRight
                color: tile.on ? Config.textReverseColor : Config.subtextColor
                MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: QuickSettingsService.openPage(tile.page) }
            }
        }
    }

    // ── A sub-page header: back arrow + title ──
    component PageHeader: RowLayout {
        property string title
        Layout.fillWidth: true
        BarButton { onClicked: QuickSettingsService.openPage("main"); Glyph { text: Icons.back } }
        StyledText { Layout.fillWidth: true; text: parent.title; font.bold: true; font.pixelSize: Config.fontSizeLarge }
    }

    // ── A row in a list (network, device…) ──
    component ListRow: Rectangle {
        id: row
        property string icon
        property string title
        property string status
        property bool current: false
        signal picked
        Layout.fillWidth: true
        implicitHeight: 40
        radius: Config.radiusSmall
        color: current ? Qt.alpha(Config.accentColor, 0.18) : rowMouse.containsMouse ? Config.cardHoverColor : "transparent"
        MouseArea { id: rowMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: row.picked() }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Config.spacing
            anchors.rightMargin: Config.spacing
            Glyph { text: row.icon; color: row.current ? Config.accentColor : Config.textColor }
            StyledText { Layout.fillWidth: true; text: row.title; font.pixelSize: Config.fontSizeSmall; font.bold: row.current }
            StyledText { text: row.status; font.pixelSize: Config.fontSizeSmall - 1; color: Config.subtextColor }
        }
    }

    Item {
        id: pages
        anchors.fill: parent
        anchors.margins: Config.spacing * 2
        implicitHeight: page.item?.implicitHeight ?? 0

        Loader {
            id: page
            width: parent.width
            // a sub-page fades and slides in from the side
            sourceComponent: ({ main: mainPage, wifi: wifiPage, bluetooth: bluetoothPage, sound: soundPage })[QuickSettingsService.page] ?? mainPage
            onLoaded: { item.opacity = 0; item.x = 20; enter.restart(); }
            ParallelAnimation {
                id: enter
                NumberAnimation { target: page.item; property: "opacity"; to: 1; duration: Config.animDuration }
                NumberAnimation { target: page.item; property: "x"; to: 0; duration: Config.animDuration; easing.type: Easing.OutCubic }
            }
        }
    }

    // ── Pages ──────────────────────────────────────────────────────────────
    Component {
        id: mainPage
        ColumnLayout {
            spacing: Config.spacing

            RowLayout {                                   // header: theme, settings, power
                Layout.fillWidth: true
                StyledText { Layout.fillWidth: true; text: Quickshell.env("USER"); font.bold: true; font.pixelSize: Config.fontSizeLarge }
                BarButton { onClicked: ThemeService.step(1); Glyph { text: Icons.palette } }
                BarButton { onClicked: { QuickSettingsService.close(); SettingsService.open(""); } Glyph { text: Icons.cog } }
                BarButton { onClicked: PowerService.open(); Glyph { text: Icons.power; color: Config.errorColor } }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: Config.spacing
                columnSpacing: Config.spacing
                Tile {
                    icon: Networking.wifiEnabled ? Icons.wifi[4] : Icons.wifiOff
                    title: "Wi-Fi"
                    status: root.network?.name ?? (Networking.wifiEnabled ? "Not connected" : "Off")
                    on: Networking.wifiEnabled
                    page: "wifi"
                    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                }
                Tile {
                    icon: root.adapter?.enabled ? Icons.bluetooth : Icons.bluetoothOff
                    title: "Bluetooth"
                    status: Bluetooth.devices.values.find(d => d.connected)?.name ?? (root.adapter?.enabled ? "On" : "Off")
                    on: root.adapter?.enabled ?? false
                    page: "bluetooth"
                    onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
                }
                Tile {
                    icon: NotificationService.dnd ? Icons.bellOff : Icons.bell
                    title: "Do not disturb"
                    status: NotificationService.dnd ? "On" : "Off"
                    on: NotificationService.dnd
                    onToggled: NotificationService.toggleDnd()
                }
                Tile {
                    icon: IdleService.caffeine ? Icons.coffee : Icons.coffeeOutline
                    title: "Caffeine"
                    status: IdleService.caffeine ? "Staying awake" : "Off"
                    on: IdleService.caffeine
                    onToggled: IdleService.toggleCaffeine()
                }
            }

            QsSlider {
                Layout.fillWidth: true
                icon: AudioService.volumeIcon(AudioService.volume, AudioService.muted)
                value: AudioService.muted ? 0 : AudioService.volume
                onMoved: v => AudioService.setVolume(v)
                onIconClicked: QuickSettingsService.openPage("sound")
            }
            QsSlider {
                Layout.fillWidth: true
                visible: BrightnessService.available
                icon: Icons.brightness
                value: BrightnessService.brightness
                onMoved: v => BrightnessService.setBrightness(v)
            }
        }
    }

    Component {
        id: wifiPage
        ColumnLayout {
            spacing: Config.padding
            PageHeader { title: "Wi-Fi" }
            Repeater {
                model: (root.wifi?.networks.values ?? []).slice()
                    .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength)).slice(0, 8)
                ListRow {
                    required property var modelData
                    icon: Icons.wifi[Math.ceil(modelData.signalStrength * 4)]
                    title: modelData.name
                    status: modelData.stateChanging ? "…" : modelData.connected ? "Connected" : modelData.known ? "Saved" : ""
                    current: modelData.connected
                    // known networks connect with one click; new secured ones need a password (nm-connection-editor)
                    onPicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                }
            }
            StyledText { visible: !Networking.wifiEnabled; text: "Wi-Fi is off"; color: Config.subtextColor }
        }
    }

    Component {
        id: bluetoothPage
        ColumnLayout {
            spacing: Config.padding
            PageHeader { title: "Bluetooth" }
            Repeater {
                model: Bluetooth.devices.values.filter(d => d.paired).slice(0, 8)
                ListRow {
                    required property var modelData
                    icon: Icons.bluetooth
                    title: modelData.name
                    status: modelData.connected ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : "Connected") : ""
                    current: modelData.connected
                    onPicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                }
            }
            StyledText { visible: !(root.adapter?.enabled ?? false); text: "Bluetooth is off"; color: Config.subtextColor }
        }
    }

    Component {
        id: soundPage
        ColumnLayout {
            spacing: Config.padding
            PageHeader { title: "Sound output" }
            Repeater {
                model: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
                ListRow {
                    required property var modelData
                    icon: Icons.volumeHigh
                    title: modelData.description || modelData.name
                    current: modelData === Pipewire.defaultAudioSink
                    onPicked: Pipewire.preferredDefaultAudioSink = modelData
                }
            }
        }
    }
}
