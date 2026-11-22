import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components
import qs.modules.settings
import qs.modules.settings.pages

// The settings app: a normal resizable window with a search field, a navigation rail and
// the pages. It edits the same Config singleton the shell uses, so changes are live.
FloatingWindow {
    id: root

    title: "Shell settings"
    implicitWidth: 1000
    implicitHeight: 700
    minimumSize: Qt.size(760, 520)
    color: Colours.palette.m3surface

    readonly property list<Item> pageItems: [appearance, frame, bar, panels, services, keybinds, profiles]
    readonly property var counts: pageItems.map(p => p.matchCount)

    // When a search hides everything on the current page, jump to the first page with matches.
    Connections {
        target: SettingsState
        function onQueryChanged(): void {
            Qt.callLater(() => {
                if (SettingsState.query && root.counts[SettingsState.page] === 0) {
                    const first = root.counts.findIndex(c => c > 0);
                    if (first >= 0) SettingsState.page = first;
                }
            });
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        // ---- left: title, search, navigation ----
        ColumnLayout {
            // a layout whose children fill the width would fill the width itself; pin it to 250 px
            Layout.fillWidth: false
            Layout.preferredWidth: 250
            Layout.maximumWidth: 250
            Layout.fillHeight: true
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.leftMargin: Tokens.padding.medium
                Layout.topMargin: Tokens.padding.medium
                spacing: Tokens.spacing.small
                MaterialIcon { text: "settings"; fill: 1; color: Colours.palette.m3primary; font.pixelSize: 26 }
                StyledText { text: "Settings"; font.pixelSize: Tokens.font.size.large; font.weight: 600 }
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: Tokens.rounding.full
                color: Colours.palette.m3surfaceContainerHigh

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.padding.large
                    anchors.rightMargin: Tokens.padding.small
                    MaterialIcon { text: "search"; color: Colours.palette.m3onSurfaceVariant }
                    TextField {
                        id: search
                        Layout.fillWidth: true
                        background: null
                        placeholderText: "Search settings"
                        placeholderTextColor: Colours.palette.m3outline
                        color: Colours.palette.m3onSurface
                        font.family: Tokens.font.sans
                        text: SettingsState.query
                        onTextChanged: SettingsState.query = text
                        Keys.onEscapePressed: text = ""
                    }
                    IconButton {
                        visible: search.text !== ""
                        icon: "close"
                        size: 30
                        inactiveColour: "transparent"
                        onClicked: search.text = ""
                    }
                }
            }

            NavRail {
                Layout.fillWidth: true
                counts: root.counts
            }

            Item { Layout.fillHeight: true }

            StyledText {
                Layout.leftMargin: Tokens.padding.medium
                Layout.bottomMargin: Tokens.padding.small
                text: "Changes apply instantly"
                color: Colours.palette.m3outline
                font.pixelSize: Tokens.font.size.small
            }
        }

        // ---- right: the current page ----
        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Tokens.rounding.extraLarge
            color: Colours.palette.m3surfaceContainerLow

            StackLayout {
                anchors.fill: parent
                currentIndex: SettingsState.page

                AppearancePage { id: appearance }
                FramePage { id: frame }
                BarPage { id: bar }
                PanelsPage { id: panels }
                ServicesPage { id: services }
                KeybindsPage { id: keybinds }
                ProfilesPage { id: profiles }
            }
        }
    }
}
