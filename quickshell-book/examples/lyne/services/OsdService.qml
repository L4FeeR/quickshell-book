pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.config

// The on-screen display for volume, microphone and brightness.
// Keybinds call show("volume") after changing the level.
Singleton {
    id: root

    property string kind: "volume"        // "volume" | "mic" | "brightness"
    property bool visible: false          // what the OSD wants
    property bool mapped: false           // the window exists (stays a bit longer for the exit animation)

    readonly property real value: kind === "brightness" ? BrightnessService.brightness
        : kind === "mic" ? (AudioService.micMuted ? 0 : AudioService.micVolume)
        : (AudioService.muted ? 0 : AudioService.volume)
    readonly property string icon: kind === "brightness" ? "\u{f00df}"
        : kind === "mic" ? (AudioService.micMuted ? "\u{f036d}" : "\u{f036c}")
        : AudioService.volumeIcon(AudioService.volume, AudioService.muted)
    readonly property string label: kind === "brightness" ? "Brightness" : kind === "mic" ? "Microphone" : "Volume"

    function show(k) {
        kind = k;
        mapped = true;
        visible = true;
        hideTimer.restart();
    }
    function keepOpen() { hideTimer.restart(); }

    Timer {
        id: hideTimer
        interval: Config.osdTimeout
        onTriggered: { root.visible = false; unmapTimer.restart(); }
    }
    // unmap only after the exit animation has played
    Timer {
        id: unmapTimer
        interval: Config.animDurationLong
        onTriggered: if (!root.visible) root.mapped = false
    }

    // scripts can show it too: qs -c lyne ipc call osd trigger volume
    IpcHandler {
        target: "osd"
        function trigger(kind: string): void { root.show(kind); }
    }
}
