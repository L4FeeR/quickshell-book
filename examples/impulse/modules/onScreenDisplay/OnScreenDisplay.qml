import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// A pill just under the bar: icon, label, progress bar and value. Shows on volume or
// brightness changes and hides after Config.options.osd.timeout ms.
Scope {
    id: root

    property string kind: "volume"
    property bool armed: false
    readonly property real value: kind === "volume" ? Audio.volume : Brightness.value
    readonly property bool shown: GlobalStates.osdVolumeOpen || GlobalStates.osdBrightnessOpen

    function show(k: string): void {
        if (!armed) return;
        kind = k;
        GlobalStates.osdVolumeOpen = k === "volume";
        GlobalStates.osdBrightnessOpen = k === "brightness";
        hide.restart();
    }

    Timer { running: true; interval: 1500; onTriggered: root.armed = true }
    Timer { id: hide; interval: Config.options.osd.timeout; onTriggered: { GlobalStates.osdVolumeOpen = false; GlobalStates.osdBrightnessOpen = false; } }
    Connections { target: Audio; function onVolumeChanged(): void { root.show("volume") } function onMutedChanged(): void { root.show("volume") } }
    Connections { target: Brightness; function onCurrentChanged(): void { root.show("brightness") } }

    PanelWindow {
        anchors.top: true
        margins.top: Appearance.sizes.barHeight
        implicitWidth: Appearance.sizes.osdWidth + 2 * Appearance.sizes.elevationMargin
        implicitHeight: 80
        visible: root.shown || fade.running
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:onScreenDisplay"

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.shown ? 10 : -height
            width: Appearance.sizes.osdWidth
            height: 50
            radius: Appearance.rounding.full
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            Behavior on y { NumberAnimation { id: fade; duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 16
                spacing: 10
                MaterialSymbol {
                    text: root.kind === "volume" ? (Audio.muted ? "volume_off" : "volume_up") : "light_mode"
                    iconSize: 24
                    fill: 1
                    color: Appearance.colors.colOnLayer0
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    RowLayout {
                        StyledText { Layout.fillWidth: true; text: root.kind === "volume" ? "Volume" : "Brightness"; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer0 }
                        StyledText { text: Math.round(root.value * 100); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer0 }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 6
                        radius: 3
                        color: Appearance.colors.colSecondaryContainer
                        Rectangle {
                            width: parent.width * Math.min(1, root.value)
                            height: parent.height
                            radius: 3
                            color: Appearance.colors.colPrimary
                            Behavior on width { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                        }
                    }
                }
            }
        }
    }
}
