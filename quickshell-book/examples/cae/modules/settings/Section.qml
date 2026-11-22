import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components
import qs.modules.settings

// A titled group of rows. It hides itself when a search matches none of its rows.
ColumnLayout {
    id: root

    property string title: ""
    default property alias rows: content.data

    readonly property bool anyMatch: {
        for (const c of content.children)
            if (c.isSettingRow ? c.matches : SettingsState.query === "") return true;   // extras (previews) only without a search
        return false;
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.small
    visible: anyMatch

    StyledText {
        Layout.topMargin: Tokens.spacing.medium
        Layout.leftMargin: Tokens.padding.small
        text: root.title
        font.pixelSize: Tokens.font.size.normal
        font.weight: 600
        color: Colours.palette.m3primary
    }

    ColumnLayout {
        id: content
        Layout.fillWidth: true
        spacing: 2
    }
}
