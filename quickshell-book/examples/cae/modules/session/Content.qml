import Quickshell
import QtQuick
import qs.config
import qs.services
import qs.components

// The session drawer on the right edge: a column of big buttons. Arrow keys move, Enter runs.
Column {
    id: root

    required property ScreenState screenState

    readonly property var actions: [
        { icon: "logout", cmd: ["loginctl", "terminate-user", Quickshell.env("USER")] },
        { icon: "power_settings_new", cmd: ["systemctl", "poweroff"] },
        { icon: "bedtime", cmd: ["systemctl", "suspend"] },
        { icon: "restart_alt", cmd: ["systemctl", "reboot"] }
    ]
    property int current: 1

    padding: Tokens.padding.large
    spacing: Tokens.spacing.large

    // take the keyboard when the drawer opens (the window has keyboard focus while it's open)
    Connections {
        target: root.screenState
        function onSessionChanged(): void {
            if (root.screenState.session) root.forceActiveFocus();
        }
    }

    Keys.onUpPressed: current = Math.max(0, current - 1)
    Keys.onDownPressed: current = Math.min(actions.length - 1, current + 1)
    Keys.onEscapePressed: screenState.session = false
    Keys.onReturnPressed: run(current)

    function run(i: int): void {
        screenState.session = false;
        Quickshell.execDetached(actions[i].cmd);
    }

    Repeater {
        model: root.actions

        StyledRect {
            required property var modelData
            required property int index
            readonly property bool selected: root.current === index

            width: Tokens.sizes.sessionButton
            height: Tokens.sizes.sessionButton
            radius: selected ? Tokens.rounding.large : Tokens.rounding.extraLarge
            color: selected ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainer

            Behavior on radius { Anim { type: Anim.FastSpatial } }

            MaterialIcon {
                anchors.centerIn: parent
                text: parent.modelData.icon
                font.pixelSize: 28
                fill: parent.selected ? 1 : 0
                color: parent.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            }
            StateLayer {
                onEntered: root.current = parent.index
                onClicked: root.run(parent.index)
            }
        }
    }
}
