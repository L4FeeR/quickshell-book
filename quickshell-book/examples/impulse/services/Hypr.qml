pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick

// Hyprland commands that work with both config styles. Newer Hyprland can be configured in Lua,
// and then dispatchers use Lua syntax (hl.dsp.focus({ workspace = 3 })) instead of "workspace 3".
// Hyprland.usingLua says which one is active (undefined on older Quickshell = classic).
Singleton {
    readonly property bool lua: Hyprland.usingLua ?? false

    function workspace(id: var): void {
        Hyprland.dispatch(lua ? `hl.dsp.focus({ workspace = "${id}" })` : `workspace ${id}`);
    }
    // relative move: +1 / -1 across existing workspaces
    function workspaceRelative(delta: int): void {
        workspace(delta > 0 ? "r+1" : "r-1");
    }
    function focusWindow(address: string): void {
        Hyprland.dispatch(lua ? `hl.dsp.focus({ window = "address:${address}" })` : `focuswindow address:${address}`);
    }
    function moveWindowToWorkspace(address: string, id: int): void {
        Hyprland.dispatch(lua ? `hl.dsp.window.move({ workspace = ${id}, follow = false, window = "address:${address}" })`
                              : `movetoworkspacesilent ${id},address:${address}`);
    }
}
