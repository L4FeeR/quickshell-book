pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick

// A registry of each screen's ScreenState, so keybinds and IPC can open drawers
// on the monitor you're looking at.
Singleton {
    property var states: ({})

    function register(screen: ShellScreen, state: QtObject): void {
        states[screen.name] = state;
    }

    function forScreen(screen: ShellScreen): QtObject {
        return states[screen?.name] ?? null;
    }

    function forFocused(): QtObject {
        return states[Hyprland.focusedMonitor?.name] ?? Object.values(states)[0] ?? null;
    }
}
