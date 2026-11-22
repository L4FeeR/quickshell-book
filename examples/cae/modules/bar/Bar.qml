import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components

// The vertical bar. Which modules appear, and in what order, comes from Config.bar.entries,
// e.g. ["logo", "workspaces", "spacer", "activeWindow", "spacer", "tray", "clock", "statusIcons", "power"].
ColumnLayout {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property Item popouts

    // Called while the pointer moves over the bar: open the popout of the status icon under it.
    function checkPopout(y: real): void {
        const entry = childAt(width / 2, y);
        const icons = entry?.item;
        if (entry?.entryId === "statusIcons" && icons) {
            const hit = icons.iconAt(icons.mapFromItem(root, 0, y).y);
            if (hit) {
                popouts.currentName = hit.name;
                popouts.currentCenter = hit.mapToItem(root, 0, hit.height / 2).y;
                popouts.hasCurrent = true;
                return;
            }
        }
        popouts.hasCurrent = false;
    }

    spacing: Tokens.spacing.medium

    Repeater {
        model: Config.bar.entries

        Loader {
            required property string modelData
            readonly property string entryId: modelData

            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: modelData === "spacer"
            Layout.topMargin: index === 0 ? Tokens.padding.large : 0
            Layout.bottomMargin: index === Config.bar.entries.length - 1 ? Tokens.padding.large : 0

            required property int index

            sourceComponent: ({
                spacer: spacer, logo: logo, workspaces: workspaces, activeWindow: activeWindow,
                tray: tray, clock: clock, statusIcons: statusIcons, power: power
            })[modelData] ?? null
        }
    }

    Component { id: spacer; Item {} }
    Component { id: logo; OsIcon { screenState: root.screenState } }
    Component { id: workspaces; Workspaces { screen: root.screen } }
    Component { id: activeWindow; ActiveWindow { bar: root } }
    Component { id: tray; Tray {} }
    Component { id: clock; Clock {} }
    Component { id: statusIcons; StatusIcons {} }
    Component { id: power; Power { screenState: root.screenState } }
}
