import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services

// The theme switcher window: search, a dark/light filter and a grid of theme cards.
// Hover a card to preview the theme on the whole shell; click (or Enter) to keep it.
Scope {
    LazyLoader {
        active: Ui.pickerOpen

        FloatingWindow {
            id: win

            property string filter: "all"           // "all" | "dark" | "light"
            readonly property var shown: Theme.list.filter(t =>
                (filter === "all" || t.variant === filter)
                && (search.text === "" || (t.name + " " + t.family).toLowerCase().includes(search.text.toLowerCase())))

            title: "Themes"
            implicitWidth: 920
            implicitHeight: 640
            minimumSize: Qt.size(480, 400)
            color: Theme.colors.background

            onClosed: { Theme.previewId = ""; Ui.pickerOpen = false; }

            Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                // ---- header ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Icon { text: "palette"; fill: 1; color: Theme.colors.primary; font.pixelSize: 26 }
                    TText { text: "Themes"; font.pixelSize: 22; font.weight: Font.DemiBold }
                    TText { text: Theme.list.length + " installed"; color: Theme.colors.textMuted; Layout.alignment: Qt.AlignBottom }
                    Item { Layout.fillWidth: true }

                    Repeater {
                        model: [["all", "All"], ["dark", "Dark"], ["light", "Light"]]
                        TRect {
                            required property var modelData
                            implicitWidth: chipText.implicitWidth + 28
                            implicitHeight: 32
                            radius: 16
                            color: win.filter === modelData[0] ? Theme.colors.primary : Theme.colors.surfaceHigh
                            TText {
                                id: chipText
                                anchors.centerIn: parent
                                text: parent.modelData[1]
                                color: win.filter === parent.modelData[0] ? Theme.colors.onPrimary : Theme.colors.text
                            }
                            TapHandler { onTapped: win.filter = parent.modelData[0] }
                        }
                    }

                    TRect {
                        implicitWidth: 220
                        implicitHeight: 36
                        radius: 18
                        color: Theme.colors.surface
                        border.width: search.activeFocus ? 2 : 1
                        border.color: search.activeFocus ? Theme.colors.primary : Theme.colors.border

                        TextField {
                            id: search
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            background: null
                            placeholderText: "Search themes"
                            placeholderTextColor: Theme.colors.textFaint
                            color: Theme.colors.text
                            focus: true
                            Keys.onEscapePressed: Ui.pickerOpen = false
                            Keys.onDownPressed: grid.moveCurrentIndexDown()
                            Keys.onUpPressed: grid.moveCurrentIndexUp()
                            Keys.onLeftPressed: grid.moveCurrentIndexLeft()
                            Keys.onRightPressed: grid.moveCurrentIndexRight()
                            onAccepted: if (win.shown[grid.currentIndex]) Theme.set(win.shown[grid.currentIndex].id)
                        }
                    }
                }

                // ---- the grid of cards ----
                GridView {
                    id: grid

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cellWidth: Math.floor(width / Math.max(1, Math.floor(width / 216)))
                    cellHeight: 166
                    model: win.shown
                    currentIndex: Math.max(0, win.shown.findIndex(t => t.id === Theme.chosenId))
                    // keyboard selection previews too
                    onCurrentIndexChanged: if (activeFocus || search.activeFocus) Theme.previewId = win.shown[currentIndex]?.id ?? ""

                    delegate: Item {
                        id: cell
                        required property var modelData
                        required property int index
                        width: grid.cellWidth
                        height: grid.cellHeight

                        ThemeCard {
                            anchors.centerIn: parent
                            theme: cell.modelData
                            selected: cell.modelData.id === Theme.chosenId
                            hovered: hover.hovered || grid.currentIndex === cell.index && Theme.previewId === cell.modelData.id
                        }
                        HoverHandler {
                            id: hover
                            cursorShape: Qt.PointingHandCursor
                            onHoveredChanged: {
                                if (hovered) Theme.previewId = cell.modelData.id;
                                else if (Theme.previewId === cell.modelData.id) Theme.previewId = "";
                            }
                        }
                        TapHandler {
                            onTapped: { grid.currentIndex = cell.index; Theme.set(cell.modelData.id); }
                        }
                    }
                }

                // ---- footer ----
                RowLayout {
                    Layout.fillWidth: true
                    TText {
                        Layout.fillWidth: true
                        text: Theme.previewId !== "" ? "Previewing " + Theme.theme.name + " (click to keep)"
                                                     : "Current: " + Theme.theme.name + (Theme.settings.autoSwitch ? " (automatic day/night)" : "")
                        color: Theme.colors.textMuted
                    }
                    TText {
                        text: "contrast " + Theme.contrast(Theme.colors.text, Theme.colors.background).toFixed(1) + ":1"
                        color: Theme.contrast(Theme.colors.text, Theme.colors.background) >= 7 ? Theme.colors.green : Theme.colors.yellow
                    }
                    IconButton { icon: "contrast"; tooltip: "Light/dark twin"; onClicked: Theme.toggleVariant() }
                    IconButton { icon: "schedule"; tooltip: "Automatic day/night"; active: Theme.settings.autoSwitch; onClicked: Theme.settings.autoSwitch = !Theme.settings.autoSwitch }
                }
            }
        }
    }
}
