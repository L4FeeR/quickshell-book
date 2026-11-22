import Quickshell
import QtQuick
import qs.config
import qs.components

// The bar's slot in the frame. Its width animates between the frame thickness (hidden)
// and the full bar width (shown), and the real bar is only loaded while it's visible.
Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property Item popouts

    property bool hovered: false
    readonly property int padding: Math.max(Tokens.padding.small, Config.border.thickness)
    readonly property int contentWidth: Tokens.sizes.barInnerWidth + padding * 2
    readonly property bool shown: Config.bar.persistent || screenState.bar || hovered
    readonly property int exclusiveZone: Config.bar.persistent || screenState.bar ? contentWidth : Config.border.thickness

    function checkPopout(y: real): void {
        loader.item?.checkPopout(y);
    }

    implicitWidth: shown ? contentWidth : Config.border.thickness
    clip: true

    Behavior on implicitWidth {
        Anim { type: root.shown ? Anim.Spatial : Anim.Emphasized }
    }

    Loader {
        id: loader

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        active: root.shown || root.implicitWidth > Config.border.thickness

        sourceComponent: Bar {
            width: root.contentWidth
            screen: root.screen
            screenState: root.screenState
            popouts: root.popouts
        }
    }
}
