import Quickshell
import QtQuick
import qs.config
import qs.services
import qs.components

// Volume and brightness as two vertical sliders on the right edge. They appear when the value
// changes (keys, scripts) or when you hover the right edge, and hide after a delay.
Row {
    id: root

    required property ScreenState screenState
    required property ShellScreen screen
    property bool armed: false

    function flash(): void {
        if (!armed) return;
        screenState.osd = true;
        hide.restart();
    }

    padding: Tokens.padding.large
    spacing: Tokens.spacing.medium

    // ignore the values services report at startup
    Timer { running: true; interval: 1500; onTriggered: root.armed = true }
    Timer { id: hide; interval: Config.osd.hideDelay; onTriggered: if (!hover.hovered) root.screenState.osd = false }
    HoverHandler { id: hover }

    Connections {
        target: Audio
        function onVolumeChanged(): void { root.flash() }
        function onMutedChanged(): void { root.flash() }
    }
    Connections {
        target: Brightness
        function onCurrentChanged(): void { root.flash() }
    }

    VerticalSlider {
        icon: Audio.icon
        value: Audio.muted ? 0 : Audio.volume
        onMoved: Audio.setVolume(value)
    }
    VerticalSlider {
        visible: Brightness.available
        icon: "light_mode"
        value: Brightness.value
        onMoved: Brightness.set(value)
    }
}
