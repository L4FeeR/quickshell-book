pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services

// Hyprland commands that work with both config styles. lyne-dots configures
// Hyprland in Lua (hyprland.lua), where dispatchers are Lua calls like
// hl.dsp.focus({ workspace = 3 }). A classic hyprland.conf uses "workspace 3".
Singleton {
    id: root

    property bool lua: false

    Process {
        running: true
        command: ["test", "-f", Quickshell.env("HOME") + "/.config/hypr/hyprland.lua"]
        onExited: code => root.lua = code === 0
    }

    function workspace(id) {
        Hyprland.dispatch(lua ? `hl.dsp.focus({ workspace = ${id} })` : `workspace ${id}`);
    }
    // screens off / on
    function dpms(on) {
        Hyprland.dispatch(lua ? `hl.dsp.dpms({ action = "${on ? "on" : "off"}" })` : `dpms ${on ? "on" : "off"}`);
    }
    // log out: end the Hyprland session
    function exit() {
        Hyprland.dispatch(lua ? "hl.dsp.exit()" : "exit");
    }
}
