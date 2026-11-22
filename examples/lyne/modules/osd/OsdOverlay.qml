import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.components

// Volume / microphone / brightness feedback, on the focused screen.
// Two styles (osd.style):
//   "attached"  slides out of the bar like the other panels (lyne's default)
//   "pill"      a floating capsule near the bottom of the screen
// Hovering keeps it open; the wheel changes the level; a click mutes.
PanelWindow {
    id: root

    readonly property bool attached: Config.osdStyle === "attached"
    readonly property bool atTop: attached ? !Config.barOnBottom : false

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors.top: atTop
    anchors.bottom: !atTop
    margins.bottom: attached ? 0 : 80
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 300 + Config.radiusLarge * 2
    implicitHeight: (attached ? Config.barReservedHeight : 0) + 64
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lyne_osd"
    mask: Region { item: attached ? panel : pill }

    // the content: icon, label, level bar and percentage
    component Level: RowLayout {
        spacing: Config.spacing
        Glyph { text: OsdService.icon; font.pixelSize: Config.fontSizeIcon; color: Config.accentColor }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            StyledText { text: OsdService.label; font.pixelSize: Config.fontSizeSmall; color: Config.subtextColor }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 6
                radius: 3
                color: Config.surface1Color
                Rectangle {
                    width: parent.width * Math.min(1, OsdService.value)
                    height: parent.height
                    radius: 3
                    color: Config.accentColor
                    Behavior on width { NumberAnimation { duration: Config.animDurationShort } }
                }
            }
        }
        StyledText { Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight; text: Math.round(OsdService.value * 100) + "%"; font.pixelSize: Config.fontSizeSmall }
    }

    // hover keeps it, wheel changes, click mutes
    component Interaction: MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onContainsMouseChanged: if (containsMouse) OsdService.keepOpen()
        onWheel: w => {
            const up = w.angleDelta.y > 0;
            if (OsdService.kind === "brightness") up ? BrightnessService.increaseBrightness() : BrightnessService.decreaseBrightness();
            else up ? AudioService.increaseVolume() : AudioService.decreaseVolume();
            OsdService.keepOpen();
        }
        onClicked: OsdService.kind === "mic" ? AudioService.toggleSourceMute() : OsdService.kind === "volume" ? AudioService.toggleMute() : null
    }

    AttachedPanel {
        id: panel
        visible: root.attached
        shown: OsdService.visible
        edge: root.atTop ? "top" : "bottom"
        width: 300
        height: 56
        x: Config.radiusLarge
        y: root.atTop ? Config.barReservedHeight : root.height - Config.barReservedHeight - height
        Level { anchors.fill: parent; anchors.margins: Config.spacing + 4 }
        Interaction {}
    }

    Rectangle {
        id: pill
        visible: !root.attached
        width: 300
        height: 56
        x: Config.radiusLarge
        radius: height / 2
        color: Config.backgroundTransparentColor
        opacity: OsdService.visible ? 1 : 0
        scale: OsdService.visible ? 1 : 0.92
        Behavior on opacity { NumberAnimation { duration: Config.animDuration } }
        Behavior on scale { NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutExpo } }
        Level { anchors.fill: parent; anchors.leftMargin: Config.spacing * 2; anchors.rightMargin: Config.spacing * 2 }
        Interaction {}
    }
}
