import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components
import qs.modules.settings

// A scrollable page with a big title. It counts how many of its rows match the search,
// which the navigation rail shows as a badge.
Flickable {
    id: root

    property string title: ""
    property string subtitle: ""
    default property alias sections: content.data

    function countMatches(item: Item): int {
        let n = 0;
        for (const c of item.children) {
            if (c.isSettingRow && c.matches) n++;
            n += countMatches(c);
        }
        return n;
    }
    readonly property int matchCount: SettingsState.query ? countMatches(content) : 0

    contentHeight: column.implicitHeight + Tokens.padding.large * 2
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: column

        x: Tokens.padding.extraLarge
        y: Tokens.padding.large
        width: root.width - Tokens.padding.extraLarge * 2
        spacing: Tokens.spacing.small

        StyledText {
            text: root.title
            font.pixelSize: Tokens.font.size.extraLarge
            font.weight: 600
        }
        StyledText {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.subtitle
            wrapMode: Text.Wrap
            color: Colours.palette.m3onSurfaceVariant
        }

        ColumnLayout {
            id: content
            Layout.fillWidth: true
            spacing: Tokens.spacing.small
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.extraLarge
            Layout.alignment: Qt.AlignHCenter
            visible: SettingsState.query !== "" && root.matchCount === 0
            text: `No settings on this page match "${SettingsState.query}"`
            color: Colours.palette.m3outline
        }
    }
}
