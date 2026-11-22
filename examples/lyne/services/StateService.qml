pragma Singleton
import QtQuick
import Quickshell
import qs.services
import Quickshell.Io

// Every setting of the shell lives in ONE file, ~/.config/lyne/state.json.
// Widgets never read the file: they ask for a key path like "bar.style",
// and get the value from state.json, or from defaults.json when it isn't set.
Singleton {
    id: root

    readonly property string statePath: Quickshell.env("HOME") + "/.config/lyne/state.json"
    readonly property string defaultsPath: Quickshell.shellPath("defaults.json")

    property var state: ({})              // what's in state.json
    property var defaults: ({})           // what's in defaults.json
    property bool isLoading: true         // true until state.json has been read once

    // --- Telling bindings that something changed ---------------------------
    // `state` is a plain JavaScript object changed in place, which QML can't
    // see. So every top-level key ("bar", "theme"…) gets a small counter
    // object. get("bar.style") reads the "bar" counter, which makes the
    // binding depend on it; set("bar.style", …) bumps the counter, and only
    // bindings that read something under "bar" re-evaluate.
    property var _counters: ({})
    property int revision: 0              // bumped when defaults.json (re)loads

    Component {
        id: counterComponent
        QtObject { property int rev: 0 }
    }

    function _depend(path) {
        const top = path.split(".")[0];
        let counter = _counters[top];
        if (!counter) {
            counter = counterComponent.createObject(root);
            _counters[top] = counter;
        }
        return counter.rev;               // reading it is what creates the dependency
    }
    function _bump(top) {
        if (_counters[top])
            _counters[top].rev++;
    }

    // --- Reading and writing with dot paths -------------------------------
    function _lookup(obj, path) {
        let current = obj;
        for (const key of path.split(".")) {
            if (current !== null && typeof current === "object" && key in current)
                current = current[key];
            else
                return undefined;
        }
        return current;
    }

    function _assign(obj, path, value) {
        const keys = path.split(".");
        let current = obj;
        for (let i = 0; i < keys.length - 1; i++) {
            if (typeof current[keys[i]] !== "object" || current[keys[i]] === null)
                current[keys[i]] = {};
            current = current[keys[i]];
        }
        current[keys[keys.length - 1]] = value;
    }

    // state.json first, then defaults.json, then the fallback written in the code
    function get(path, fallback) {
        root.revision;
        _depend(path);
        const value = _lookup(state, path);
        if (value !== undefined)
            return value;
        const def = _lookup(defaults, path);
        return def === undefined ? fallback : def;
    }

    function isDefault(path) {
        root.revision;
        _depend(path);
        const value = _lookup(state, path);
        return value === undefined || JSON.stringify(value) === JSON.stringify(_lookup(defaults, path));
    }

    function set(path, value) {
        if (JSON.stringify(_lookup(state, path)) === JSON.stringify(value))
            return;                       // nothing changes: no write, no re-evaluation
        _assign(state, path, value);
        _bump(path.split(".")[0]);
        if (!isLoading)
            saveTimer.restart();
    }

    function reset(path) {
        const def = _lookup(defaults, path);
        if (def !== undefined)
            set(path, JSON.parse(JSON.stringify(def)));
    }

    // --- The files ------------------------------------------------------------
    function _apply(text) {
        let next;
        try {
            next = JSON.parse(text);
        } catch (e) {
            console.warn("[State] state.json is not valid JSON:", e);
            isLoading = false;
            return;
        }
        // which top-level keys differ from what we have now?
        const keys = new Set([...Object.keys(state), ...Object.keys(next)]);
        const changed = [...keys].filter(k => JSON.stringify(state[k]) !== JSON.stringify(next[k]));
        state = next;
        isLoading = false;
        for (const key of changed)
            _bump(key);
    }

    // many set() calls in a row (dragging a slider) become one write
    Timer {
        id: saveTimer
        interval: 300
        onTriggered: stateFile.setText(JSON.stringify(root.state, null, 2) + "\n")
    }

    FileView {
        id: defaultsFile
        path: root.defaultsPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.defaults = JSON.parse(text());
                root.revision++;
            } catch (e) {
                console.warn("[State] defaults.json is not valid JSON:", e);
            }
        }
    }

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true                // edits from a text editor or a script apply live
        atomicWrites: true                // never leave a half-written file behind
        printErrors: false
        onFileChanged: reload()
        onLoaded: root._apply(text())
        onLoadFailed: {
            // first start: no state.json yet. Everything comes from defaults,
            // and the first set() creates the file.
            root.isLoading = false;
        }
    }

    IpcHandler {
        target: "state"
        function get(path: string): string { return JSON.stringify(root.get(path, null)); }
        function set(path: string, json: string): void { root.set(path, JSON.parse(json)); }
        function reset(path: string): void { root.reset(path); }
    }
}
