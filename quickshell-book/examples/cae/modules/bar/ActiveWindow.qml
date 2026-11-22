import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.services
import qs.components

// The focused window: its icon, then its title written vertically (rotated 90°).
Item {
    id: root

    required property Item bar
    readonly property Toplevel win: ToplevelManager.activeToplevel
    readonly property real maxLength: 280

    implicitWidth: Tokens.sizes.barInnerWidth
    implicitHeight: icon.height + Tokens.spacing.small + Math.min(title.implicitWidth, maxLength)
    visible: win !== null

    IconImage {
        id: icon
        anchors.horizontalCenter: parent.horizontalCenter
        implicitSize: 22
        source: Quickshell.iconPath(DesktopEntries.heuristicLookup(root.win?.appId ?? "")?.icon ?? "", "application-x-executable")
    }

    StyledText {
        id: title

        // laid out horizontally, then rotated around its own centre into the column
        width: Math.min(implicitWidth, root.maxLength)
        x: (root.width - width) / 2
        y: icon.height + Tokens.spacing.small + (width - height) / 2
        rotation: 90
        text: root.win?.title ?? ""
        elide: Text.ElideRight
        color: Colours.palette.m3secondary

        Behavior on text {
            SequentialAnimation {
                Anim { target: title; property: "opacity"; to: 0; type: Anim.Effects }
                PropertyAction {}
                Anim { target: title; property: "opacity"; to: 1; type: Anim.Effects }
            }
        }
    }
}
