pragma Singleton
import QtQuick
import Quickshell
import qs.services
import Quickshell.Io

// Loads the theme files, publishes the chosen palette, and paints the rest of
// the desktop with it: kitty, Hyprland's borders and GTK's light/dark mode.
// A theme file is JSON in lyne-dots' format (themes/*.json shows it), so the
// themes you make for the real lyne-dots work here too, and the other way round.
Singleton {
    id: root

    // built-in themes ship with the shell; your own go in ~/.local/themes
    readonly property string builtinDir: Quickshell.shellPath("themes")
    readonly property string userDir: Quickshell.env("HOME") + "/.local/themes"
    readonly property string kittyPath: Quickshell.env("HOME") + "/.config/kitty/current-theme.conf"

    // slug ("tokyonight") -> parsed file
    property var themes: ({})
    // [{ slug, name, variant, palette }] sorted by name, for pickers
    readonly property var list: Object.keys(themes).sort((a, b) => themes[a].name.localeCompare(themes[b].name))
        .map(slug => ({ slug: slug, name: themes[slug].name, variant: themes[slug].variant ?? "dark", palette: themes[slug].palette }))

    readonly property string currentName: StateService.get("theme.name", "tokyonight")
    readonly property var current: themes[currentName] ?? null
    readonly property bool isDark: (current?.variant ?? "dark") === "dark"

    // What Config fades to. Only replaced when the colours really change.
    property var palette: ({})

    // Start the shell with LYNE_NO_EXPORT=1 to try it without touching kitty,
    // Hyprland or GTK (on another desktop, for example).
    readonly property bool exportEnabled: !Quickshell.env("LYNE_NO_EXPORT")

    function set(slug) {
        if (themes[slug])
            StateService.set("theme.name", slug);
    }
    function step(delta) {
        const slugs = list.map(t => t.slug);
        const i = slugs.indexOf(currentName);
        set(slugs[(i + delta + slugs.length) % slugs.length]);
    }

    onCurrentChanged: {
        if (!current)
            return;
        palette = current.palette;
        if (!exportEnabled)
            return;
        _applyKitty(current.terminal);
        _applyHyprland(current.hyprland);
        _applyGtk();
    }

    // ── Loading every theme file with one process ─────────────────────────
    // It prints each file's name, its contents, then a line with the ASCII
    // record separator (\036), which never appears in JSON.
    function reload() { loader.running = true; }
    Component.onCompleted: reload()

    Process {
        id: loader
        command: ["sh", "-c", 'for f in "$1"/*.json "$2"/*.json; do [ -f "$f" ] || continue; basename "$f" .json; cat "$f"; printf "\\n\\036\\n"; done',
            "sh", root.builtinDir, root.userDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                for (const chunk of text.split("\x1e")) {
                    const nl = chunk.trim().indexOf("\n");
                    if (nl < 0)
                        continue;
                    const slug = chunk.trim().slice(0, nl);
                    try {
                        const data = JSON.parse(chunk.trim().slice(nl + 1));
                        if (data.palette)
                            out[slug] = data;           // later files (yours) replace built-ins
                    } catch (e) {
                        console.warn("[Theme] skipping broken theme", slug, e);
                    }
                }
                root.themes = out;
            }
        }
    }

    // ── Painting the desktop ────────────────────────────────────────────────
    // Writes text to a file through `sh`. The path and the text are passed
    // as arguments, never pasted into the command, so quotes can't break it.
    function _write(path, text, after) {
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"; ' + (after ?? ""), "sh", path, text]);
    }

    // kitty: `include current-theme.conf` in kitty.conf, then SIGUSR1 reloads every window
    function _applyKitty(t) {
        if (!t)
            return;
        const keys = {
            background: "background", foreground: "foreground", cursor: "cursor", cursorTextColor: "cursor_text_color",
            selectionBackground: "selection_background", selectionForeground: "selection_foreground", urlColor: "url_color",
            activeTabBackground: "active_tab_background", activeTabForeground: "active_tab_foreground",
            inactiveTabBackground: "inactive_tab_background", inactiveTabForeground: "inactive_tab_foreground",
            activeBorderColor: "active_border_color", inactiveBorderColor: "inactive_border_color"
        };
        const lines = ["# written by the lyne shell: do not edit"];
        for (const k in keys)
            if (t[k]) lines.push(keys[k] + " " + t[k]);
        for (let i = 0; i < 18; i++)
            if (t["color" + i]) lines.push("color" + i + " " + t["color" + i]);
        _write(kittyPath, lines.join("\n") + "\n", "pkill -USR1 -x kitty; true");
    }

    // Hyprland: borders and shadow, applied now. A Lua config (hyprland.lua)
    // takes `hyprctl eval` with hl.config(); a classic config takes `keyword`.
    function _applyHyprland(h) {
        if (!h)
            return;
        const lua = `hl.config({ general = { col = { active_border = "rgba(${h.activeBorder})", inactive_border = "rgba(${h.inactiveBorder})" } },`
            + ` decoration = { shadow = { color = "rgba(${h.shadowColor})" } } })`;
        const classic = `keyword general:col.active_border rgba(${h.activeBorder}); keyword general:col.inactive_border rgba(${h.inactiveBorder});`
            + ` keyword decoration:shadow:color rgba(${h.shadowColor})`;
        Quickshell.execDetached(["sh", "-c", 'if [ -f "$HOME/.config/hypr/hyprland.lua" ]; then hyprctl eval "$1"; else hyprctl --batch "$2"; fi',
            "sh", lua, classic]);
    }

    // GTK 4 / libadwaita apps, Firefox and websites follow this preference
    function _applyGtk() {
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", isDark ? "prefer-dark" : "prefer-light"]);
    }

    IpcHandler {
        target: "theme"
        function set(slug: string): void { root.set(slug); }
        function next(): void { root.step(1); }
        function previous(): void { root.step(-1); }
        function get(): string { return root.currentName; }
        function list(): string { return root.list.map(t => t.slug).join("\n"); }
        function reload(): void { root.reload(); }
    }
}
