pragma Singleton
import Quickshell
import QtQuick

// App search for the launcher: names first, then generic names, keywords and comments.
Singleton {
    readonly property list<DesktopEntry> all: DesktopEntries.applications.values.filter(a => !a.noDisplay)
        .slice().sort((a, b) => a.name.localeCompare(b.name))

    function score(app: DesktopEntry, q: string): int {
        const name = app.name.toLowerCase();
        if (name.startsWith(q)) return 100 - name.length;
        if (name.includes(q)) return 60 - name.length;
        const extra = [app.genericName, app.comment, ...(app.keywords ?? [])].join(" ").toLowerCase();
        return extra.includes(q) ? 20 : -1;
    }

    function search(query: string): list<DesktopEntry> {
        const q = query.trim().toLowerCase();
        if (!q) return all;
        return all.map(a => ({ a, s: score(a, q) })).filter(x => x.s >= 0)
                  .sort((x, y) => y.s - x.s).map(x => x.a);
    }

    function launch(app: DesktopEntry): void {
        app.execute();
    }
}
