pragma Singleton
import QtQuick
import Quickshell
import qs.services

// Keeps the shell's popups polite: only one is open at a time, and the bar
// knows when something is open (an auto-hiding bar stays out while it is).
Singleton {
    id: root

    // names of the popups open right now: { "Launcher": true, … }
    property var openModules: ({})
    readonly property bool anyModuleOpen: Object.keys(openModules).length > 0

    // every popup listens to this and closes unless it is `except`
    signal closeRequested(string except)

    function registerOpen(name) {
        if (openModules[name])
            return;
        const copy = Object.assign({}, openModules);   // a new object, so bindings notice
        copy[name] = true;
        openModules = copy;
    }
    function registerClose(name) {
        if (!openModules[name])
            return;
        const copy = Object.assign({}, openModules);
        delete copy[name];
        openModules = copy;
    }

    // Close everything else, then run `open` (which may also close `name`
    // again: that's how a shortcut toggles its popup).
    function openExclusive(name, open) {
        closeRequested(name);
        open();
    }
}
