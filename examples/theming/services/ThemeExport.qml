pragma Singleton
import Quickshell
import QtQuick
import qs.services

// Carries the shell's theme to other programs. Whenever the chosen theme changes (not while
// previewing), it writes small colour files that kitty, Hyprland and GTK can include.
// Turn each target on or off with the properties below.
Singleton {
    id: root

    property bool kitty: true          // ~/.config/kitty/theming-colors.conf
    property bool hyprland: true       // ~/.config/hypr/theming-colors.conf + live border colours
    property bool gtk: true            // ~/.config/gtk-3.0/theming-colors.css and gtk-4.0

    readonly property string home: Quickshell.env("HOME")

    // "#cba6f7" (or "#ffcba6f7" with opacity) -> "cba6f7"
    function hex(v: var): string {
        const s = String(v);
        return s.length === 9 ? s.slice(3) : s.slice(1, 7);
    }

    // 16 terminal colours: the theme file's "terminal" list if it has one, otherwise built from roles
    function terminalColors(t: var, c: var): list<string> {
        if (Array.isArray(t.terminal) && t.terminal.length === 16) return t.terminal;
        const base = [c.surfaceHigh, c.red, c.green, c.yellow, c.blue, c.magenta, c.cyan, c.textMuted];
        const bright = [c.textFaint, c.red, c.green, c.yellow, c.blue, c.magenta, c.cyan, c.text];
        return [...base, ...bright].map(x => "#" + hex(x));
    }

    function writeFile(path: string, text: string): void {
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"', "sh", path, text]);
    }

    function exportAll(): void {
        // the CHOSEN theme, never a preview: resolve every role of it into c.<role>
        const t = Theme.themes[Theme.chosenId];
        const c = {};
        for (const r of Object.keys(t.roles)) c[r] = Theme.resolve(t, r);
        const name = t.name;

        if (kitty) {
            const term = terminalColors(t, c);
            const lines = [`# ${name}, written by the Quickshell theme switcher`,
                           `foreground #${hex(c.text)}`, `background #${hex(c.background)}`,
                           `selection_foreground #${hex(c.background)}`, `selection_background #${hex(c.primary)}`,
                           `cursor #${hex(c.primary)}`, `url_color #${hex(c.blue)}`,
                           `active_border_color #${hex(c.primary)}`, `inactive_border_color #${hex(c.border)}`];
            term.forEach((col, i) => lines.push(`color${i} ${col}`));
            writeFile(`${home}/.config/kitty/theming-colors.conf`, lines.join("\n") + "\n");
            // kitty re-reads its config (and the include) on SIGUSR1
            Quickshell.execDetached(["pkill", "-USR1", "-x", "kitty"]);
        }

        if (hyprland) {
            const vars = ["background", "surface", "border", "text", "primary", "secondary", "red", "green", "yellow", "blue"]
                .map(r => `$theme_${r} = rgb(${hex(c[r])})`);
            writeFile(`${home}/.config/hypr/theming-colors.conf`, `# ${name}\n` + vars.join("\n") + "\n");
            // apply the border colours right away, without reloading Hyprland
            Quickshell.execDetached(["hyprctl", "--batch",
                `keyword general:col.active_border rgb(${hex(c.primary)}) rgb(${hex(c.secondary)}) 45deg ; keyword general:col.inactive_border rgb(${hex(c.border)})`]);
        }

        if (gtk) {
            const css = [`/* ${name} */`,
                         `@define-color accent_color #${hex(c.primary)};`, `@define-color accent_bg_color #${hex(c.primary)};`,
                         `@define-color accent_fg_color #${hex(c.onPrimary)};`,
                         `@define-color window_bg_color #${hex(c.background)};`, `@define-color window_fg_color #${hex(c.text)};`,
                         `@define-color view_bg_color #${hex(c.surface)};`, `@define-color view_fg_color #${hex(c.text)};`,
                         `@define-color headerbar_bg_color #${hex(c.surface)};`, `@define-color headerbar_fg_color #${hex(c.text)};`,
                         `@define-color card_bg_color #${hex(c.surfaceHigh)};`, `@define-color card_fg_color #${hex(c.text)};`,
                         `@define-color popover_bg_color #${hex(c.surfaceHigh)};`, `@define-color popover_fg_color #${hex(c.text)};`,
                         `@define-color destructive_color #${hex(c.red)};`, `@define-color success_color #${hex(c.green)};`,
                         `@define-color warning_color #${hex(c.yellow)};`, `@define-color error_color #${hex(c.red)};`].join("\n") + "\n";
            writeFile(`${home}/.config/gtk-3.0/theming-colors.css`, css);
            writeFile(`${home}/.config/gtk-4.0/theming-colors.css`, css);
            Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", t.variant === "light" ? "prefer-light" : "prefer-dark"]);
        }
    }

    // Export when the chosen theme changes, after a short pause (fast cycling exports once).
    Connections {
        target: Theme
        function onChosenIdChanged(): void { debounce.restart() }
        function onThemesChanged(): void { debounce.restart() }
    }
    Timer {
        id: debounce
        interval: 400
        onTriggered: if (Theme.themes[Theme.chosenId]) root.exportAll()
    }
}
