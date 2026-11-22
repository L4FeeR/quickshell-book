pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// User options, read from ~/.config/cae/shell.json (created with defaults on first run).
// Edit the file while the shell runs: changes apply immediately.
Singleton {
    id: root

    property alias border: adapter.border
    property alias bar: adapter.bar
    property alias dashboard: adapter.dashboard
    property alias launcher: adapter.launcher
    property alias notifs: adapter.notifs
    property alias osd: adapter.osd
    property alias sidebar: adapter.sidebar
    property alias appearance: adapter.appearance
    property alias paths: adapter.paths
    property alias services: adapter.services

    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/cae"

    FileView {
        path: root.dir + "/shell.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                Quickshell.execDetached(["mkdir", "-p", root.dir]);
                writeAdapter();
            }
        }

        JsonAdapter {
            id: adapter

            property JsonObject border: JsonObject {
                property int thickness: 10          // the frame around the screen
                property int rounding: 25           // inner corner radius of the frame
            }
            property JsonObject bar: JsonObject {
                property bool persistent: true      // false = hidden until you hover the left edge
                property list<string> entries: ["logo", "workspaces", "spacer", "activeWindow", "spacer", "tray", "clock", "statusIcons", "power"]
                property int workspacesShown: 5
                property bool workspaceWindows: true
            }
            property JsonObject dashboard: JsonObject {
                property bool showOnHover: true
            }
            property JsonObject launcher: JsonObject {
                property string actionPrefix: ">"
                property int maxShown: 7
            }
            property JsonObject notifs: JsonObject {
                property int defaultExpire: 5000    // ms, when the app doesn't say
            }
            property JsonObject osd: JsonObject {
                property int hideDelay: 2000
            }
            property JsonObject sidebar: JsonObject {
                property bool showOnHover: true
            }
            property JsonObject appearance: JsonObject {
                property bool transparency: false
                property real transparencyBase: 0.85
                property string mode: "dark"        // colour scheme mode for matugen: "dark" | "light"
                property string font: "Rubik"
                property real roundingScale: 1.0    // multiplies every rounding token
                property real animationSpeed: 1.0   // 2 = twice as fast, 0.5 = half speed
            }
            property JsonObject paths: JsonObject {
                property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
                property string face: Quickshell.env("HOME") + "/.face"
            }
            property JsonObject services: JsonObject {
                property real audioStep: 0.05
                property real brightnessStep: 0.05
                property string terminal: "kitty"
            }
        }
    }
}
