pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Synced lyrics for whatever is playing, from LRCLIB (lrclib.net): a free,
// open lyrics database with no account or key. Lyrics come in LRC format,
// one line per lyric with the time it's sung:
//     [00:26.31] I didn't want to be the one to forget
// We fetch them when the track changes, cache them on disk, and work out
// which line is being sung from the player's position.
Singleton {
    id: root

    property var lines: []              // [{ time: seconds, text: "…" }]
    property string plain: ""           // unsynced lyrics, when that's all there is
    property bool instrumental: false
    property string status: "idle"      // "idle" | "loading" | "ready" | "none"
    property real offset: 0             // seconds; nudge if lyrics run early or late

    // the line being sung: the last one whose time has passed
    readonly property int current: {
        const t = Player.position + offset;
        let i = -1;
        for (let k = 0; k < lines.length; k++) {
            if (lines[k].time <= t)
                i = k;
            else
                break;
        }
        return i;
    }
    readonly property string currentText: current >= 0 ? lines[current].text : ""
    readonly property string nextText: current + 1 < lines.length ? lines[current + 1].text : ""
    // 0..1: how far we are through the current line, for a karaoke fill
    readonly property real lineProgress: {
        if (current < 0 || current + 1 >= lines.length)
            return 0;
        const start = lines[current].time, end = lines[current + 1].time;
        return Math.max(0, Math.min(1, (Player.position + offset - start) / Math.max(0.1, end - start)));
    }

    // ── Parsing LRC ─────────────────────────────────────────────────────────
    // A line can carry several times ("[00:12.00][01:30.50] chorus"), so every
    // time tag makes its own entry. Then everything is sorted by time.
    function parse(lrc) {
        const out = [];
        const tag = /\[(\d+):(\d+(?:\.\d+)?)\]/g;     // [mm:ss.xx]
        for (const raw of lrc.split("\n")) {
            const text = raw.replace(/\[[^\]]*\]/g, "").trim();
            // exec() with the g flag finds one tag per call (QML's JavaScript has no matchAll)
            tag.lastIndex = 0;
            let m;
            while ((m = tag.exec(raw)) !== null)
                out.push({ time: Number(m[1]) * 60 + Number(m[2]), text: text });
        }
        return out.sort((a, b) => a.time - b.time);
    }

    // ── Fetching ────────────────────────────────────────────────────────────
    readonly property string key: Player.artist + " — " + Player.title
    onKeyChanged: debounce.restart()
    // wait a moment: skipping through tracks shouldn't fire a request for each
    Timer { id: debounce; interval: 600; onTriggered: root.load() }

    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/qs-lyrics"
    function cachePath() {
        // a file name from artist and title, keeping only safe characters
        return cacheDir + "/" + key.toLowerCase().replace(/[^a-z0-9]+/g, "_").slice(0, 120) + ".json";
    }

    function load() {
        lines = [];
        plain = "";
        instrumental = false;
        if (!Player.title) {
            status = "idle";
            return;
        }
        status = "loading";
        cache.path = "";
        cache.path = cachePath();          // try the cache first; on failure, ask LRCLIB
    }

    function apply(data) {
        instrumental = data.instrumental === true;
        lines = data.syncedLyrics ? parse(data.syncedLyrics) : [];
        plain = data.plainLyrics ?? "";
        status = lines.length > 0 || plain || instrumental ? "ready" : "none";
    }

    FileView {
        id: cache
        printErrors: false
        onLoaded: {
            try { root.apply(JSON.parse(text())); }
            catch (e) { root.fetch(); }
        }
        onLoadFailed: root.fetch()
    }

    // `get` wants the exact track; `search` is the fallback when that misses.
    // The duration helps LRCLIB pick the right version of a song.
    function fetch() {
        const q = "track_name=" + encodeURIComponent(Player.title)
            + "&artist_name=" + encodeURIComponent(Player.artist)
            + (Player.album ? "&album_name=" + encodeURIComponent(Player.album) : "")
            + (Player.length > 0 ? "&duration=" + Math.round(Player.length) : "");
        request.forKey = key;
        request.command = ["curl", "-sf", "--max-time", "10",
            "-H", "Lrclib-Client: quickshell-book (https://github.com/quickshell-mirror/quickshell)",
            "https://lrclib.net/api/get?" + q,
            "-w", "\n", "--next", "-sf", "--max-time", "10",
            "https://lrclib.net/api/search?track_name=" + encodeURIComponent(Player.title) + "&artist_name=" + encodeURIComponent(Player.artist)];
        request.running = true;
    }

    Process {
        id: request
        property string forKey
        stdout: StdioCollector {
            onStreamFinished: {
                if (request.forKey !== root.key)
                    return;                         // the track changed meanwhile
                // first line: the exact match (or nothing); second: search results
                const [exact, search] = text.split("\n");
                let data = null;
                try { data = JSON.parse(exact); } catch (e) {}
                if (!data?.syncedLyrics) {
                    try {
                        const results = JSON.parse(search);
                        data = results.find(r => r.syncedLyrics) ?? results[0] ?? data;
                    } catch (e) {}
                }
                if (!data) {
                    root.status = "none";
                    return;
                }
                root.apply(data);
                // save it, so the song never needs a request again
                Quickshell.execDetached(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"', "sh",
                    root.cachePath(), JSON.stringify({ syncedLyrics: data.syncedLyrics ?? "", plainLyrics: data.plainLyrics ?? "", instrumental: data.instrumental === true })]);
            }
        }
    }

    IpcHandler {
        target: "lyrics"
        function offsetBy(seconds: real): void { root.offset += seconds; }
        function current(): string { return root.currentText; }
        function reload(): void { root.fetch(); }
    }
}
