pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

// The theme service. It loads every theme file, remembers your choice, and exposes the
// current theme's colours as properties. Widgets only ever use Theme.colors.<role>.
Singleton {
    id: root

    // ---- which theme is active ----
    property var themes: ({})                     // id -> theme object, filled by load()
    property string previewId: ""                 // set while hovering a card in the picker
    readonly property string chosenId: saved.autoSwitch ? scheduledId : saved.theme
    readonly property string activeId: previewId !== "" ? previewId : chosenId
    readonly property var theme: themes[activeId] ?? themes["catppuccin-mocha"] ?? fallback
    readonly property bool dark: theme.variant !== "light"

    // all themes, sorted by family, then name (for the picker)
    readonly property var list: Object.values(themes).sort((a, b) => a.family.localeCompare(b.family) || a.name.localeCompare(b.name))

    // ---- automatic day/night switching ----
    readonly property bool isDay: clock.hours >= saved.dayStart && clock.hours < saved.nightStart
    readonly property string scheduledId: isDay ? saved.dayTheme : saved.nightTheme

    // ---- the colours every widget uses ----
    readonly property QtObject colors: QtObject {
        readonly property color background: root.role("background")
        readonly property color surface: root.role("surface")
        readonly property color surfaceHigh: root.role("surfaceHigh")
        readonly property color border: root.role("border")
        readonly property color text: root.role("text")
        readonly property color textMuted: root.role("textMuted")
        readonly property color textFaint: root.role("textFaint")
        readonly property color primary: root.role("primary")
        readonly property color onPrimary: root.role("onPrimary")
        readonly property color secondary: root.role("secondary")
        readonly property color red: root.role("red")
        readonly property color orange: root.role("orange")
        readonly property color yellow: root.role("yellow")
        readonly property color green: root.role("green")
        readonly property color cyan: root.role("cyan")
        readonly property color blue: root.role("blue")
        readonly property color magenta: root.role("magenta")
        // meanings built from the accents
        readonly property color success: green
        readonly property color warning: yellow
        readonly property color error: red
    }

    // ---- looking up colours ----
    // A role's value is a palette name ("mauve") or a literal colour ("#cba6f7").
    function resolve(t: var, roleName: string): string {
        const v = t?.roles?.[roleName] ?? "";
        if (v.startsWith("#")) return v;
        return t?.palette?.[v] ?? "#ff00ff";          // bright pink = a mistake in the theme file
    }
    function role(roleName: string): color {
        return resolve(theme, roleName);
    }

    // ---- colour helpers ----
    function alpha(c: color, a: real): color {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
    function mix(a: color, b: color, amount: real): color {      // amount 0 = a, 1 = b
        return Qt.rgba(a.r + (b.r - a.r) * amount, a.g + (b.g - a.g) * amount, a.b + (b.b - a.b) * amount, 1);
    }
    // WCAG contrast ratio between two colours: 1 (none) .. 21 (black on white). 4.5+ is good for text.
    function contrast(a: color, b: color): real {
        const lum = c => {
            const ch = x => x <= 0.03928 ? x / 12.92 : Math.pow((x + 0.055) / 1.055, 2.4);
            return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
        };
        const l1 = lum(a), l2 = lum(b);
        return (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);
    }
    // the more readable of the theme's text and background colours on top of `bg`
    function readableOn(bg: color): color {
        return contrast(colors.text, bg) >= contrast(colors.background, bg) ? colors.text : colors.background;
    }

    // ---- switching ----
    function set(id: string): void {
        if (!themes[id]) return;
        previewId = "";
        saved.autoSwitch = false;
        saved.theme = id;
    }
    function step(delta: int): void {
        const ids = list.map(t => t.id);
        set(ids[(ids.indexOf(chosenId) + delta + ids.length) % ids.length]);
    }
    // jump to the same family's light or dark version (e.g. Mocha <-> Latte)
    function toggleVariant(): void {
        const wanted = dark ? "light" : "dark";
        const twin = list.find(t => t.family === theme.family && t.variant === wanted);
        if (twin) set(twin.id);
    }

    // ---- loading theme files ----
    // Built-in themes live in <config>/themes, your own in ~/.config/theming/themes.
    readonly property string userDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/theming/themes"

    function load(): void {
        loader.running = true;
    }

    Component.onCompleted: load()

    Process {
        id: loader
        // print every theme file, separated by a line with a single ASCII "record separator"
        command: ["sh", "-c", 'for f in "$1"/*.json "$2"/*.json; do [ -f "$f" ] && cat "$f" && printf "\\n\\036\\n"; done',
                  "sh", Quickshell.shellPath("themes"), root.userDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = {};
                for (const chunk of text.split("\u001e")) {
                    if (!chunk.trim()) continue;
                    try {
                        const t = JSON.parse(chunk);
                        if (t.id && t.palette && t.roles) found[t.id] = t;
                    } catch (e) {
                        console.warn("Theme: skipping a file that isn't valid JSON");
                    }
                }
                root.themes = found;               // user themes with the same id replace built-ins
            }
        }
    }

    // ---- remembering the choice ----
    FileView {
        path: Quickshell.statePath("theme.json")
        printErrors: false
        onAdapterUpdated: writeAdapter()
        onLoadFailed: writeAdapter()

        JsonAdapter {
            id: saved
            property string theme: "catppuccin-mocha"
            property bool autoSwitch: false
            property string dayTheme: "catppuccin-latte"
            property string nightTheme: "catppuccin-mocha"
            property int dayStart: 7
            property int nightStart: 19
        }
    }
    readonly property alias settings: saved

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ---- shell commands: qs -c theming ipc call theme <function> ----
    IpcHandler {
        target: "theme"
        function set(id: string): void { root.set(id) }
        function next(): void { root.step(1) }
        function previous(): void { root.step(-1) }
        function toggleVariant(): void { root.toggleVariant() }
        function list(): string { return root.list.map(t => t.id).join("\n") }
        function get(): string { return root.chosenId }
        function reload(): void { root.load() }
        function auto(on: bool): void { saved.autoSwitch = on }
    }

    // used before the theme files have loaded (Catppuccin Mocha)
    readonly property var fallback: ({
        id: "fallback", name: "Fallback", family: "Fallback", variant: "dark",
        palette: {},
        roles: { background: "#1e1e2e", surface: "#181825", surfaceHigh: "#313244", border: "#45475a", text: "#cdd6f4",
                 textMuted: "#a6adc8", textFaint: "#6c7086", primary: "#cba6f7", onPrimary: "#1e1e2e", secondary: "#89b4fa",
                 red: "#f38ba8", orange: "#fab387", yellow: "#f9e2af", green: "#a6e3a1", cyan: "#94e2d5", blue: "#89b4fa", magenta: "#f5c2e7" }
    })
}
