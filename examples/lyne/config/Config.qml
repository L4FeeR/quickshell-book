pragma Singleton
import QtQuick
import Quickshell
import qs.services
import "../services/color.js" as Color

// Design tokens: every colour, size, font and duration the shell uses.
// Widgets write Config.accentColor or Config.radius, never a number or a hex
// code, so changing a setting (or the theme) restyles the whole shell.
Singleton {
    id: root

    function getState(path, fallback) {
        return StateService.get(path, fallback);
    }

    // ── COLOURS ─────────────────────────────────────────────────────────────
    // They come from the theme file. On a theme switch each one fades from
    // the old palette to the new one (see the fade machinery further down).
    readonly property color backgroundColor: _shown("background", "#1a1b26")
    readonly property real backgroundOpacity: getState("opacity.background", 0.9)
    readonly property color backgroundTransparentColor: Qt.alpha(backgroundColor, backgroundOpacity)
    readonly property color surface0Color: _shown("surface0", "#24283b")
    readonly property color surface1Color: _shown("surface1", "#292e42")
    readonly property color surface2Color: _shown("surface2", "#414868")
    readonly property color surface3Color: _shown("surface3", "#565f89")
    readonly property color cardColor: Qt.alpha(surface0Color, backgroundOpacity)
    readonly property color cardHoverColor: Qt.alpha(surface1Color, backgroundOpacity)

    readonly property color textColor: _shown("text", "#c0caf5")
    readonly property color textReverseColor: _shown("textReverse", "#1a1b26")
    readonly property color subtextColor: _shown("subtext", "#a9b1d6")
    readonly property color mutedColor: _shown("muted", "#545c7e")

    readonly property color accentColor: _shown("accent", "#7aa2f7")
    readonly property color successColor: _shown("success", "#9ece6a")
    readonly property color warningColor: _shown("warning", "#e0af68")
    readonly property color errorColor: _shown("error", "#f7768e")

    // dimming behind overlays (power menu, screenshot): black on every theme
    readonly property color scrimColor: "black"

    // ── GEOMETRY ────────────────────────────────────────────────────────────
    readonly property int radiusSmall: getState("geometry.radiusSmall", 5)
    readonly property int radius: getState("geometry.radius", 10)
    readonly property int radiusLarge: getState("geometry.radiusLarge", 15)
    readonly property int spacing: getState("geometry.spacing", 8)
    readonly property int padding: getState("geometry.padding", 6)

    // ── BAR ─────────────────────────────────────────────────────────────────
    readonly property int barHeight: getState("bar.height", 33)
    readonly property bool barAutoHide: getState("bar.autoHide", false)
    readonly property bool barOnBottom: getState("bar.position", "top") === "bottom"
    // "docked" | "docked-corners" | "floating" | "islands"
    readonly property string barStyle: getState("bar.style", "docked-corners")
    readonly property bool barIslands: barStyle === "islands"
    readonly property bool barFloating: barStyle === "floating"
    readonly property bool barCorners: barStyle === "docked-corners"
    readonly property int barMargin: barFloating ? getState("bar.margin", 8) : 0
    readonly property int barCornerSize: barCorners ? radiusLarge : 0
    readonly property int barReservedHeight: barHeight + barMargin
    readonly property int barIslandHeight: barHeight - padding
    readonly property int barButtonHeight: barIslandHeight - Math.round(padding * 2 / 3)
    // "pills" | "dots" | "numbers"
    readonly property string barWorkspaceStyle: getState("bar.workspaces.style", "pills")
    readonly property int barWorkspaceCount: getState("bar.workspaces.count", 10)

    // ── TYPOGRAPHY ──────────────────────────────────────────────────────────
    // A Nerd Font: one font for the text AND the icons (icons are glyphs)
    readonly property string font: getState("typography.font", "CaskaydiaCove Nerd Font")
    readonly property int fontSizeSmall: getState("typography.sizeSmall", 12)
    readonly property int fontSizeNormal: getState("typography.sizeNormal", 14)
    readonly property int fontSizeLarge: getState("typography.sizeLarge", 16)
    readonly property int fontSizeIconSmall: getState("typography.iconSmall", 18)
    readonly property int fontSizeIcon: getState("typography.icon", 22)
    readonly property int fontSizeIconLarge: getState("typography.iconLarge", 28)

    // ── MOTION ──────────────────────────────────────────────────────────────
    readonly property int animDurationShort: getState("animations.short", 100)
    readonly property int animDuration: getState("animations.normal", 200)
    readonly property int animDurationLong: getState("animations.long", 400)
    readonly property bool themeTransition: getState("animations.themeTransition", true)

    // ── OTHER MODULES ───────────────────────────────────────────────────────
    readonly property int notifWidth: getState("notifications.width", 350)
    readonly property int notifTimeout: getState("notifications.timeout", 5000)
    readonly property int notifMaxPopups: getState("notifications.maxPopups", 4)
    readonly property string osdStyle: getState("osd.style", "attached")     // "attached" | "pill"
    readonly property int osdTimeout: getState("osd.timeout", 1500)

    // ── THE THEME FADE ──────────────────────────────────────────────────────
    // _target is the palette being shown. During a fade, _t runs from 0 to 1
    // and each colour is mixed from _fromLab to _toLab (both in OKLab).
    property var _target: ({})
    property var _fromLab: ({})
    property var _toLab: ({})
    property real _t: 1
    readonly property bool themeTransitioning: fade.running

    function _shown(key, fallback) {
        const to = _target[key] ?? fallback;
        if (_t >= 1 || !_fromLab[key] || !_toLab[key])
            return to;
        const c = Color.mix(_fromLab[key], _toLab[key], _t);
        return Qt.rgba(c[0], c[1], c[2], c[3]);
    }

    function _setPalette(pal) {
        const empty = Object.keys(_target).length === 0;
        if (empty || !themeTransition) {          // first palette: no fade
            fade.stop();
            _t = 1;
            _target = pal;
            return;
        }
        const from = {}, to = {};
        for (const key in pal) {
            to[key] = Color.toOklab(Qt.color(pal[key]));
            // start from what is on screen right now, even in the middle of a fade
            from[key] = Color.toOklab(Qt.color(_shown(key, pal[key])));
        }
        fade.stop();
        _fromLab = from;
        _toLab = to;
        _target = pal;
        _t = 0;
        fade.start();
    }

    Component.onCompleted: _setPalette(ThemeService.palette)
    Connections {
        target: ThemeService
        function onPaletteChanged() { root._setPalette(ThemeService.palette); }
    }

    NumberAnimation {
        id: fade
        target: root
        property: "_t"
        from: 0
        to: 1
        duration: root.animDurationLong * 2
        easing.type: Easing.InOutQuad
    }
}
