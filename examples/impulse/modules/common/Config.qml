pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Options from ~/.config/impulse/config.json, as nested JSON objects. Use them as
// Config.options.bar.bottom. Change one from a terminal:  qs -c impulse ipc call config set bar.bottom true
Singleton {
    id: root

    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/impulse"
    property alias options: adapter
    property bool ready: false

    // "bar.autoHide.enable" -> options.bar.autoHide.enable = value (strings like "true"/"3" are parsed)
    function setNestedValue(key: string, value: var): void {
        const keys = key.split(".");
        let obj = root.options;
        for (let i = 0; i < keys.length - 1; i++)
            obj = obj[keys[i]];
        let v = value;
        if (typeof v === "string" && (v === "true" || v === "false" || !isNaN(Number(v))))
            v = JSON.parse(v);
        obj[keys[keys.length - 1]] = v;
    }

    FileView {
        path: root.dir + "/config.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: root.ready = true
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                Quickshell.execDetached(["mkdir", "-p", root.dir]);
                writeAdapter();
            }
            root.ready = true;
        }

        JsonAdapter {
            id: adapter

            property JsonObject appearance: JsonObject {
                property bool transparency: false
            }
            property JsonObject bar: JsonObject {
                property bool bottom: false
                property int cornerStyle: 0            // 0 = hug (rounded corners under the bar), 1 = float, 2 = plain
                property JsonObject autoHide: JsonObject {
                    property bool enable: false
                }
                property JsonObject workspaces: JsonObject {
                    property int shown: 10
                    property bool showAppIcons: true
                }
            }
            property JsonObject background: JsonObject {
                property string wallpaperPath: ""
                property bool showClock: true
            }
            property JsonObject osd: JsonObject {
                property int timeout: 1000
            }
            property JsonObject overview: JsonObject {
                property int rows: 2
                property int columns: 5
                property real scale: 0.18
            }
            property JsonObject apps: JsonObject {
                property string terminal: "kitty"
            }
        }
    }

    IpcHandler {
        target: "config"
        function set(key: string, value: string): void { root.setNestedValue(key, value) }
    }
}
