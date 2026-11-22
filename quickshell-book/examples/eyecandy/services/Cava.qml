pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The audio spectrum, from cava. cava normally draws bars in a terminal; with
// "raw" output and the "ascii" format it prints one line per frame instead:
// numbers from 0 to 100 separated by ";", one per bar. We read those lines.
//
// cava only runs while something uses it: a widget calls acquire() when it
// appears and release() when it goes, so a hidden visualizer costs nothing.
Singleton {
    id: root

    property int bars: 32
    property int framerate: 60
    readonly property bool available: !missing
    property bool missing: false
    property var values: new Array(bars).fill(0)      // 0..1 per bar
    property int users: 0
    readonly property bool idle: values.every(v => v === 0)

    function acquire() { users++; }
    function release() { users = Math.max(0, users - 1); }

    // cava's config, generated, so the shell decides the bars and the rate
    readonly property string config: `
[general]
bars = ${bars}
framerate = ${framerate}
sleep_timer = 1
autosens = 1

[input]
method = pipewire
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59

[smoothing]
monstercat = 1
noise_reduction = 70
`

    Process {
        id: proc
        running: root.users > 0 && !root.missing
        // write the config to a file (path and text as arguments), then run cava on it
        command: ["sh", "-c", 'command -v cava >/dev/null || exit 127; f="${XDG_RUNTIME_DIR:-/tmp}/qs-cava.conf"; printf "%s" "$1" > "$f" && exec cava -p "$f"', "sh", root.config]
        stdout: SplitParser {
            // one line = one frame: "12;40;100;…;"
            onRead: line => {
                const parts = line.split(";");
                const out = new Array(root.bars);
                for (let i = 0; i < root.bars; i++)
                    out[i] = Math.min(1, (Number(parts[i]) || 0) / 100);
                root.values = out;
            }
        }
        onExited: code => {
            if (code === 127) {
                root.missing = true;
                console.warn("[Cava] cava is not installed: sudo pacman -S cava");
            }
            root.values = new Array(root.bars).fill(0);
        }
    }
}
