pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// What the overview's search box shows for a query: apps, a math result (qalc),
// and fallbacks to run the text as a command or search the web.
Singleton {
    id: root

    property string query: ""
    property string mathResult: ""

    readonly property var results: {
        const q = query.trim();
        if (!q) return [];
        const out = [];
        if (mathResult) out.push({ type: "Math", name: mathResult, icon: "calculate", run: () => Quickshell.execDetached(["wl-copy", mathResult]) });
        const lq = q.toLowerCase();
        for (const app of DesktopEntries.applications.values) {
            if (out.length > 8) break;
            if (!app.noDisplay && (app.name.toLowerCase().includes(lq) || (app.genericName ?? "").toLowerCase().includes(lq)))
                out.push({ type: "App", name: app.name, iconName: app.icon, run: () => app.execute() });
        }
        out.push({ type: "Command", name: q, icon: "terminal", run: () => Quickshell.execDetached(["sh", "-c", q]) });
        out.push({ type: "Web", name: "Search the web for " + q, icon: "travel_explore", run: () => Qt.openUrlExternally("https://duckduckgo.com/?q=" + encodeURIComponent(q)) });
        return out;
    }

    onQueryChanged: {
        mathResult = "";
        if (/^[\d\s+\-*/^().%]+$|\bto\b/.test(query.trim())) math.running = true;
    }

    Process {
        id: math
        command: ["qalc", "-t", root.query]
        stdout: StdioCollector { onStreamFinished: root.mathResult = text.trim() }
    }
}
