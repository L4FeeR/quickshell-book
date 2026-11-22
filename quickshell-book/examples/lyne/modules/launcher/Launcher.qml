import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.components

// The launcher window ("spotlight" style: a box in the upper middle of the
// focused screen). It only draws LauncherService.entries and forwards keys;
// the service decides what's in the list and what Enter does.
PanelWindow {
    id: root

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors.top: true
    margins.top: Math.round((screen?.height ?? 1080) * 0.2)
    implicitWidth: 620
    implicitHeight: box.implicitHeight + 40
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lyne_launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    HyprlandFocusGrab { active: true; windows: [root]; onCleared: LauncherService.hide() }

    Rectangle {
        id: box
        width: parent.width - 40
        x: 20
        y: 10
        implicitHeight: col.implicitHeight + Config.spacing * 2
        radius: Config.radiusLarge
        color: Config.backgroundTransparentColor
        border.color: Config.surface1Color

        // open: fade in while growing from 92% (lyne's popup motion)
        scale: 0.92
        opacity: 0
        Component.onCompleted: { scale = 1; opacity = 1; }
        Behavior on scale { NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutExpo } }
        Behavior on opacity { NumberAnimation { duration: Config.animDuration } }

        ColumnLayout {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Config.spacing
            spacing: Config.spacing

            // ── the search field, with the mode's icon on a chip ──
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: Config.radius
                color: Config.cardColor
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Config.padding
                    anchors.rightMargin: Config.spacing * 2
                    spacing: Config.spacing
                    Rectangle {
                        implicitWidth: modeRow.implicitWidth + Config.spacing * 2
                        implicitHeight: 32
                        radius: Config.radiusSmall
                        color: LauncherService.mode.id === "apps" ? "transparent" : Qt.alpha(Config.accentColor, 0.2)
                        Row {
                            id: modeRow
                            anchors.centerIn: parent
                            spacing: Config.padding
                            Glyph { text: LauncherService.mode.icon; color: Config.accentColor }
                            StyledText { visible: LauncherService.mode.id !== "apps"; text: LauncherService.mode.label; font.pixelSize: Config.fontSizeSmall; color: Config.accentColor }
                        }
                    }
                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        focus: true
                        text: LauncherService.query
                        onTextEdited: LauncherService.query = text
                        color: Config.textColor
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeLarge
                        clip: true
                        Keys.onEscapePressed: LauncherService.hide()
                        Keys.onDownPressed: LauncherService.move(1)
                        Keys.onUpPressed: LauncherService.move(-1)
                        Keys.onReturnPressed: LauncherService.activate()
                        Keys.onEnterPressed: LauncherService.activate()
                        Keys.onTabPressed: e => {
                            // Ctrl+Tab: next mode (puts its prefix in the field)
                            if (e.modifiers & Qt.ControlModifier) {
                                const m = LauncherService.modes;
                                const next = m[(m.indexOf(LauncherService.mode) + 1) % m.length];
                                LauncherService.query = next.prefix + LauncherService.term;
                            } else {
                                LauncherService.move(1);
                            }
                        }
                        StyledText {
                            visible: parent.text === "" || parent.text === LauncherService.mode.prefix
                            anchors.verticalCenter: parent.verticalCenter
                            x: parent.text === "" ? 0 : parent.contentWidth + 4
                            text: LauncherService.mode.placeholder
                            color: Config.mutedColor
                            font.pixelSize: Config.fontSizeNormal
                        }
                    }
                }
            }

            // ── results ──
            ListView {
                id: list
                Layout.fillWidth: true
                implicitHeight: Math.min(contentHeight, 7 * 52)
                visible: count > 0
                clip: true
                spacing: 2
                model: LauncherService.entries
                currentIndex: LauncherService.selectedIndex
                highlightMoveDuration: Config.animDurationShort
                highlight: Rectangle { radius: Config.radius; color: Config.cardHoverColor }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: 50

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Config.spacing
                        anchors.rightMargin: Config.spacing
                        spacing: Config.spacing
                        Item {
                            implicitWidth: 32
                            implicitHeight: 32
                            IconImage {
                                anchors.fill: parent
                                visible: row.modelData.iconName !== ""
                                source: Quickshell.iconPath(row.modelData.iconName, "application-x-executable")
                                asynchronous: true
                            }
                            Glyph {
                                anchors.centerIn: parent
                                visible: row.modelData.iconName === ""
                                text: row.modelData.icon
                                font.pixelSize: Config.fontSizeIcon
                                color: Config.accentColor
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText { Layout.fillWidth: true; text: row.modelData.title; maximumLineCount: 1; font.bold: row.index === list.currentIndex }
                            StyledText { Layout.fillWidth: true; visible: text !== ""; text: row.modelData.subtitle ?? ""; font.pixelSize: Config.fontSizeSmall; color: Config.mutedColor }
                        }
                        Glyph {                                   // favourite star for apps
                            visible: row.modelData.kind === "app" && (row.index === list.currentIndex || LauncherService.favorites.includes(row.modelData.data.id))
                            text: LauncherService.favorites.includes(row.modelData.data?.id) ? Icons.star : Icons.starOutline
                            color: Config.warningColor
                            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: LauncherService.toggleFavorite(row.modelData.data) }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.rightMargin: 40
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: LauncherService.selectedIndex = row.index
                        onClicked: LauncherService.activate(row.index)
                    }
                }
            }

            StyledText {
                visible: list.count === 0 && LauncherService.term !== ""
                Layout.alignment: Qt.AlignHCenter
                Layout.margins: Config.spacing
                text: LauncherService.mode.id === "calc" ? "…" : "No results"
                color: Config.mutedColor
            }
        }
    }
}
