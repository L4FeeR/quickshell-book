pragma Singleton
import QtQuick
import Quickshell
import qs.services

// Colours taken from the album cover, so music widgets match the song.
// ColorQuantizer reduces an image to a few representative colours; from
// those we pick an accent (vivid and not too dark) and a dark background.
Singleton {
    id: root

    property color fallbackAccent: "#7aa2f7"
    property color fallbackBackground: "#1a1b26"

    readonly property var palette: quantizer.colors
    readonly property color accent: pickAccent(palette)
    readonly property color background: pickBackground(palette)
    // text that reads well on the accent
    readonly property color onAccent: accent.hslLightness > 0.6 ? "#11111b" : "#ffffff"

    ColorQuantizer {
        id: quantizer
        source: Player.artUrl
        depth: 3                 // 2^3 = 8 colours
        rescaleSize: 64          // shrink the cover first: quick, and plenty for colours
    }

    // the most vivid colour that isn't too dark or too light to show up
    function pickAccent(colors) {
        let best = null, score = -1;
        for (const c of colors) {
            if (c.hslLightness < 0.25 || c.hslLightness > 0.85)
                continue;
            const s = c.hslSaturation * (1 - Math.abs(c.hslLightness - 0.6));
            if (s > score) { score = s; best = c; }
        }
        // lift a dull pick so it still works as an accent
        return best ? Qt.hsla(Math.max(0, best.hslHue), Math.max(0.45, best.hslSaturation), Math.max(0.55, best.hslLightness), 1) : fallbackAccent;
    }

    // the darkest colour, darkened a bit more, keeping its hue
    function pickBackground(colors) {
        if (colors.length === 0)
            return fallbackBackground;
        const dark = colors.reduce((a, b) => a.hslLightness < b.hslLightness ? a : b);
        return Qt.hsla(Math.max(0, dark.hslHue), Math.min(0.5, dark.hslSaturation), Math.min(0.14, dark.hslLightness), 1);
    }
}
