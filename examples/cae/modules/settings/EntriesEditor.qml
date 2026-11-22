import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components
import qs.modules.settings

// Edit the bar's module list: reorder with the arrows, remove with ✕, add from the chips below.
// It edits a copy and emits edited(newList); the page writes it to Config.
ColumnLayout {
    id: root

    property list<string> value: []
    readonly property var available: ({
        logo: ["Logo", "deployed_code"], workspaces: ["Workspaces", "grid_view"], activeWindow: ["Window title", "web_asset"],
        tray: ["Tray", "apps"], clock: ["Clock", "schedule"], statusIcons: ["Status icons", "wifi"], power: ["Power", "power_settings_new"],
        spacer: ["Spacer", "expand"]
    })
    signal edited(var value)

    function move(i: int, delta: int): void {
        const list = [...value];
        const j = i + delta;
        if (j < 0 || j >= list.length) return;
        [list[i], list[j]] = [list[j], list[i]];
        edited(list);
    }

    Layout.fillWidth: true
    spacing: 2
    visible: SettingsState.query === "" || SettingsState.matches("bar modules entries order reorder add remove")

    Repeater {
        model: root.value

        StyledRect {
            id: entry
            required property string modelData
            required property int index

            Layout.fillWidth: true
            implicitHeight: 48
            radius: Tokens.rounding.small
            color: Colours.palette.m3surfaceContainer

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.large
                anchors.rightMargin: Tokens.padding.small
                spacing: Tokens.spacing.small

                StyledText { text: (entry.index + 1) + "."; color: Colours.palette.m3outline; font.family: Tokens.font.mono }
                MaterialIcon { text: root.available[entry.modelData]?.[1] ?? "help"; color: Colours.palette.m3primary }
                StyledText { Layout.fillWidth: true; text: root.available[entry.modelData]?.[0] ?? entry.modelData }
                IconButton { icon: "arrow_upward"; size: 32; inactiveColour: "transparent"; enabled: entry.index > 0; opacity: enabled ? 1 : 0.3; onClicked: root.move(entry.index, -1) }
                IconButton { icon: "arrow_downward"; size: 32; inactiveColour: "transparent"; enabled: entry.index < root.value.length - 1; opacity: enabled ? 1 : 0.3; onClicked: root.move(entry.index, 1) }
                IconButton { icon: "close"; size: 32; inactiveColour: "transparent"; onClicked: root.edited(root.value.filter((_, i) => i !== entry.index)) }
            }
        }
    }

    Flow {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small
        spacing: Tokens.spacing.small

        Repeater {
            // modules not on the bar yet (spacers can always be added)
            model: Object.keys(root.available).filter(k => k === "spacer" || !root.value.includes(k))

            StyledRect {
                id: chip
                required property string modelData
                implicitWidth: chipRow.implicitWidth + Tokens.padding.large * 2
                implicitHeight: 34
                radius: Tokens.rounding.small
                color: "transparent"
                border.width: 1
                border.color: Colours.palette.m3outline

                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.extraSmall
                    MaterialIcon { text: "add"; font.pixelSize: 18; color: Colours.palette.m3primary }
                    StyledText { anchors.verticalCenter: parent.verticalCenter; text: root.available[chip.modelData][0] }
                }
                StateLayer { onClicked: root.edited([...root.value, chip.modelData]) }
            }
        }
    }
}
