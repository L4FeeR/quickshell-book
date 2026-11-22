pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// The Material 3 palette. Colours come from scheme.json (written by matugen from your wallpaper,
// or by the real caelestia CLI). Until a scheme exists, the defaults below (a dark purple) are used.
Singleton {
    id: root

    property string scheme: "default"
    property bool light: false
    readonly property M3Palette palette: M3Palette {}

    // The surface colour of the frame and every drawer, with optional transparency.
    readonly property color surface: Qt.alpha(palette.m3surface, Config.appearance.transparency ? Config.appearance.transparencyBase : 1)

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/cae"

    // A readable foreground for any background colour.
    function on(c: color): color {
        return c.hslLightness < 0.5 ? Qt.hsla(c.hslHue, c.hslSaturation, 0.9, 1) : Qt.hsla(c.hslHue, c.hslSaturation, 0.1, 1);
    }

    function load(text: string): void {
        const s = JSON.parse(text);
        scheme = s.name ?? "dynamic";
        light = s.mode === "light";
        for (const [name, hex] of Object.entries(s.colours ?? {})) {
            const prop = "m3" + name;
            if (palette.hasOwnProperty(prop))
                palette[prop] = "#" + hex.replace("#", "");
        }
    }

    FileView {
        path: root.stateDir + "/scheme.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.load(text())
    }

    component M3Palette: QtObject {
        property color m3primary: "#d0bcff"
        property color m3onPrimary: "#381e72"
        property color m3primaryContainer: "#4f378b"
        property color m3onPrimaryContainer: "#eaddff"
        property color m3secondary: "#ccc2dc"
        property color m3onSecondary: "#332d41"
        property color m3secondaryContainer: "#4a4458"
        property color m3onSecondaryContainer: "#e8def8"
        property color m3tertiary: "#efb8c8"
        property color m3onTertiary: "#492532"
        property color m3tertiaryContainer: "#633b48"
        property color m3onTertiaryContainer: "#ffd8e4"
        property color m3error: "#f2b8b5"
        property color m3onError: "#601410"
        property color m3errorContainer: "#8c1d18"
        property color m3onErrorContainer: "#f9dedc"
        property color m3surface: "#141218"
        property color m3onSurface: "#e6e0e9"
        property color m3surfaceVariant: "#49454f"
        property color m3onSurfaceVariant: "#cac4d0"
        property color m3surfaceContainerLowest: "#0f0d13"
        property color m3surfaceContainerLow: "#1d1b20"
        property color m3surfaceContainer: "#211f26"
        property color m3surfaceContainerHigh: "#2b2930"
        property color m3surfaceContainerHighest: "#36343b"
        property color m3outline: "#938f99"
        property color m3outlineVariant: "#49454f"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
        property color m3inverseSurface: "#e6e0e9"
        property color m3inverseOnSurface: "#322f35"
        property color m3inversePrimary: "#6750a4"
    }
}
