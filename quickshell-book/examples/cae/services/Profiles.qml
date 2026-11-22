pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.config
import qs.services

// Managing the rice: save the whole configuration (plus the wallpaper) as a named profile,
// switch between profiles, export a backup, and reset to the defaults.
// A profile file is { "config": <shell.json>, "wallpaper": "<path>", "saved": "<date>" }.
Singleton {
    id: root

    readonly property string dir: Config.dir + "/profiles"
    readonly property string configPath: Config.dir + "/shell.json"
    readonly property string defaultsPath: Quickshell.shellPath("extras/defaults.json")
    property list<string> names: []
    property string lastMessage: ""

    function refresh(): void {
        list.running = true;
    }

    // write text to a file (creating folders), safely: the path and text are passed as arguments
    function writeFile(path: string, text: string): void {
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"', "sh", path, text]);
    }

    function save(name: string): void {
        const clean = name.trim().replace(/[^\w.-]+/g, "-");
        if (!clean) return;
        current.reload();
        const data = { config: JSON.parse(current.text() || "{}"), wallpaper: Wallpapers.current, saved: new Date().toISOString() };
        writeFile(`${dir}/${clean}.json`, JSON.stringify(data, null, 2));
        lastMessage = `Saved profile "${clean}"`;
        refreshLater.restart();
    }

    function load(name: string): void {
        reader.target = name;
        reader.command = ["cat", `${dir}/${name}.json`];
        reader.running = true;
    }

    function remove(name: string): void {
        Quickshell.execDetached(["rm", "-f", `${dir}/${name}.json`]);
        lastMessage = `Deleted profile "${name}"`;
        refreshLater.restart();
    }

    function exportTo(path: string): void {
        current.reload();
        writeFile(path, current.text());
        lastMessage = `Exported to ${path}`;
    }

    function resetToDefaults(): void {
        defaults.reload();
        // the defaults file uses "~/" so it works for everyone; expand it to this user's home
        writeFile(configPath, defaults.text().replace(/"~\//g, `"${Quickshell.env("HOME")}/`));
        lastMessage = "Restored the default settings";
    }

    Component.onCompleted: refresh()

    Timer { id: refreshLater; interval: 300; onTriggered: root.refresh() }

    FileView { id: current; path: root.configPath; blockLoading: true; printErrors: false }
    FileView { id: defaults; path: root.defaultsPath; blockLoading: true }

    Process {
        id: list
        command: ["sh", "-c", 'ls "$1" 2>/dev/null | sed -n "s/\\.json$//p"', "sh", root.dir]
        stdout: StdioCollector {
            onStreamFinished: root.names = text.split("\n").filter(n => n)
        }
    }

    Process {
        id: reader
        property string target: ""
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.writeFile(root.configPath, JSON.stringify(data.config, null, 2));
                    if (data.wallpaper) Wallpapers.set(data.wallpaper);
                    root.lastMessage = `Loaded profile "${reader.target}"`;
                } catch (e) {
                    root.lastMessage = `Couldn't read profile "${reader.target}"`;
                }
            }
        }
    }
}
