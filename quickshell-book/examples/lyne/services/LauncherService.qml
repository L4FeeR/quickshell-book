pragma Singleton
import QtQuick
import Quickshell
import qs.services
import Quickshell.Io
import qs.config
import "fuzzy.js" as Fuzzy

// The launcher's brain. The window only draws `entries`; everything about
// what to show and what Enter does lives here.
//
// The first character of the query picks the mode:
//   (nothing)  apps          ">"  actions
//   "="        calculator    ";"  clipboard history
Singleton {
    id: root

    property bool visible: false
    property string query: ""
    property int selectedIndex: 0

    readonly property var modes: [
        { id: "apps",      prefix: "",  label: "Apps",       icon: Icons.apps,       placeholder: "Search apps…  (> actions, = calculator, ; clipboard)" },
        { id: "actions",   prefix: ">", label: "Actions",    icon: Icons.lightning,  placeholder: "Run an action…" },
        { id: "calc",      prefix: "=", label: "Calculator", icon: Icons.calculator, placeholder: "Calculate…  (2^10, 5 km to mi, 20% of 150)" },
        { id: "clipboard", prefix: ";", label: "Clipboard",  icon: Icons.clipboard,  placeholder: "Search the clipboard…" }
    ]
    readonly property var mode: modes.find(m => m.prefix !== "" && query.startsWith(m.prefix)) ?? modes[0]
    readonly property string term: query.slice(mode.prefix.length).trim()

    // ── Apps ──────────────────────────────────────────────────────────────
    readonly property var favorites: StateService.get("launcher.favorites", [])   // desktop ids
    readonly property var usage: StateService.get("launcher.usage", ({}))         // id -> launch count

    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay)

    readonly property var appResults: {
        if (term === "") {
            // no query: favourites first, then the most used, then A–Z
            return apps.slice().sort((a, b) =>
                (favorites.includes(b.id) - favorites.includes(a.id))
                || ((usage[b.id] ?? 0) - (usage[a.id] ?? 0))
                || a.name.localeCompare(b.name));
        }
        return apps.map(a => ({ a: a, s: Fuzzy.best(term, [a.name, a.genericName, a.keywords.join(" ")]) }))
            .filter(r => r.s >= 0)
            .map(r => ({ a: r.a, s: r.s + Math.min(50, (usage[r.a.id] ?? 0) * 5) }))   // frequent apps float up
            .sort((x, y) => y.s - x.s)
            .map(r => r.a);
    }

    // ── Actions ──────────────────────────────────────────────────────────
    readonly property var actionResults: term === "" ? LauncherActions.items
        : LauncherActions.items.map(i => ({ i: i, s: Fuzzy.best(term, [i.name, i.keywords]) }))
            .filter(r => r.s >= 0).sort((x, y) => y.s - x.s).map(r => r.i)

    // ── Calculator (qalc) ────────────────────────────────────────────────
    property string calcResult: ""
    onTermChanged: if (mode.id === "calc") calcDebounce.restart()
    Timer {
        id: calcDebounce
        interval: 150
        onTriggered: {
            if (root.term === "") { root.calcResult = ""; return; }
            calc.command = ["qalc", "-t", root.term];       // -t: terse, only the answer
            calc.running = true;
        }
    }
    Process {
        id: calc
        stdout: StdioCollector { onStreamFinished: root.calcResult = text.trim() }
    }

    // ── Clipboard (cliphist) ─────────────────────────────────────────────
    property var clips: []                            // [{ id, text }]
    Process {
        id: clipList
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.clips = text.split("\n").filter(l => l.includes("\t")).map(l => {
                const tab = l.indexOf("\t");
                return { id: l.slice(0, tab), text: l.slice(tab + 1) };
            })
        }
    }
    readonly property var clipResults: term === "" ? clips
        : clips.filter(c => c.text.toLowerCase().includes(term.toLowerCase()))

    // ── What the window shows ────────────────────────────────────────────
    // Every entry has the same shape, whatever the mode:
    // { kind, title, subtitle, icon (glyph) or iconName (app icon), data }
    readonly property var entries: {
        switch (mode.id) {
        case "actions":
            return actionResults.map(i => ({ kind: "action", title: i.name, subtitle: "", icon: i.icon, iconName: "", data: i }));
        case "calc":
            return calcResult === "" ? [] : [{ kind: "calc", title: calcResult, subtitle: "Enter copies the result", icon: Icons.calculator, iconName: "", data: calcResult }];
        case "clipboard":
            return clipResults.map(c => ({ kind: "clip", title: c.text, subtitle: "", icon: c.text.startsWith("[[ binary") ? Icons.image : Icons.clipboard, iconName: "", data: c }));
        default:
            return appResults.slice(0, 60).map(a => ({ kind: "app", title: a.name, subtitle: a.comment || a.genericName, icon: "", iconName: a.icon, data: a }));
        }
    }
    onEntriesChanged: selectedIndex = 0

    // ── Opening, moving, running ─────────────────────────────────────────
    function show(prefix) {
        WindowManagerService.openExclusive("Launcher", () => {
            query = prefix ?? "";
            selectedIndex = 0;
            visible = true;
            clipList.running = true;              // the clipboard list is always fresh
        });
    }
    function hide() { visible = false; }
    function toggle() { visible ? hide() : show(""); }
    function toggleMode(prefix) { visible && mode.prefix === prefix ? hide() : show(prefix); }

    function move(delta) {
        if (entries.length > 0)
            selectedIndex = (selectedIndex + delta + entries.length) % entries.length;
    }

    function activate(index) {
        const e = entries[index ?? selectedIndex];
        if (!e)
            return;
        hide();
        if (e.kind === "app") {
            const counts = Object.assign({}, usage);      // copy, change, set: so the state notices
            counts[e.data.id] = (counts[e.data.id] ?? 0) + 1;
            StateService.set("launcher.usage", counts);
            e.data.execute();
        } else if (e.kind === "action") {
            e.data.run();
        } else if (e.kind === "calc") {
            Quickshell.execDetached(["wl-copy", e.data]);
        } else if (e.kind === "clip") {
            // id and text go to sh as arguments: nothing in them can run as a command
            Quickshell.execDetached(["sh", "-c", 'printf "%s\\t%s" "$1" "$2" | cliphist decode | wl-copy', "sh", e.data.id, e.data.text]);
        }
    }

    function toggleFavorite(app) {
        const list = favorites.includes(app.id) ? favorites.filter(id => id !== app.id) : favorites.concat([app.id]);
        StateService.set("launcher.favorites", list);
    }

    Connections {
        target: WindowManagerService
        function onCloseRequested(except) { if (except !== "Launcher") root.hide(); }
    }
    onVisibleChanged: visible ? WindowManagerService.registerOpen("Launcher") : WindowManagerService.registerClose("Launcher")

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle(); }
        function clipboard(): void { root.toggleMode(";"); }
    }
}
