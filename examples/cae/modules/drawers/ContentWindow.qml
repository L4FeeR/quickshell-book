import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import qs.config
import qs.services
import qs.components
import qs.modules.bar

// The heart of the shell: one transparent, fullscreen window per monitor that draws the frame
// and contains the bar and every drawer. Only the frame and the open drawers take input.
PanelWindow {
    id: root

    readonly property ScreenState screenState: ScreenState {}
    readonly property alias bar: barWrapper
    readonly property real thickness: Config.border.thickness

    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "cae-drawers"
    WlrLayershell.keyboardFocus: screenState.launcher || screenState.session ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Component.onCompleted: Visibilities.register(screen, screenState)

    // Input only where something is drawn: the four frame strips and each drawer.
    mask: Region {
        Region { width: barWrapper.implicitWidth; height: root.height }
        Region { width: root.width; height: root.thickness }
        Region { x: root.width - root.thickness; width: root.thickness; height: root.height }
        Region { y: root.height - root.thickness; width: root.width; height: root.thickness }
        Region { item: drawerPanels.dashboard }
        Region { item: drawerPanels.launcher }
        Region { item: drawerPanels.notifications }
        Region { item: drawerPanels.sidebar }
        Region { item: drawerPanels.session }
        Region { item: drawerPanels.osd }
        Region { item: drawerPanels.utilities }
        Region { item: drawerPanels.popouts }
    }

    // Clicking outside an open launcher, session menu or sidebar closes it.
    HyprlandFocusGrab {
        windows: [root]
        active: root.screenState.launcher || root.screenState.session || root.screenState.sidebar
        onCleared: {
            root.screenState.launcher = false;
            root.screenState.session = false;
            root.screenState.sidebar = false;
        }
    }

    // Dim the screen behind the session menu.
    StyledRect {
        anchors.fill: parent
        color: Colours.palette.m3scrim
        opacity: root.screenState.session ? 0.4 : 0

        Behavior on opacity {
            Anim { type: Anim.Effects }
        }
    }

    // All surfaces are drawn opaque inside one layer, then the whole layer gets the surface
    // alpha and one shared shadow. Overlapping shapes therefore never look darker.
    Item {
        anchors.fill: parent
        opacity: Colours.surface.a
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
        }

        Border {
            thickness: root.thickness
            leftThickness: barWrapper.implicitWidth
            rounding: Config.border.rounding
            colour: Qt.alpha(Colours.surface, 1)
        }

        Bg { panel: drawerPanels.dashboard; edge: "top" }
        Bg { panel: drawerPanels.launcher; edge: "bottom" }
        Bg { panel: drawerPanels.notifications; edge: "top" }
        Bg { panel: drawerPanels.sidebar; edge: "right" }
        Bg { panel: drawerPanels.session; edge: "right" }
        Bg { panel: drawerPanels.osd; edge: "right" }
        Bg { panel: drawerPanels.utilities; edge: "bottom" }
        Bg { panel: drawerPanels.popouts; edge: "left" }
    }

    Interactions {
        id: interactions

        anchors.fill: parent
        screenState: root.screenState
        panels: drawerPanels
        bar: barWrapper

        Panels {
            id: drawerPanels

            anchors.fill: parent
            anchors.margins: root.thickness
            anchors.leftMargin: barWrapper.implicitWidth
            screen: root.screen
            screenState: root.screenState
        }

        BarWrapper {
            id: barWrapper

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            screen: root.screen
            screenState: root.screenState
            popouts: drawerPanels.popouts
        }
    }

    component Bg: PanelBg {
        offsetX: barWrapper.implicitWidth
        offsetY: root.thickness
        radius: Tokens.rounding.extraLarge
        earRadius: Config.border.rounding
        colour: Qt.alpha(Colours.surface, 1)
    }
}
