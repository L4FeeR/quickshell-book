pragma Singleton
import Quickshell
import QtQuick

// What the settings window is showing: the current page and the search text.
Singleton {
    property int page: 0
    property string query: ""

    // page id, label, icon. The order here is the order in the navigation rail.
    readonly property var pages: [
        { id: "appearance", label: "Appearance", icon: "palette" },
        { id: "frame", label: "Frame", icon: "crop_free" },
        { id: "bar", label: "Bar", icon: "view_sidebar" },
        { id: "panels", label: "Panels", icon: "dashboard" },
        { id: "services", label: "Services", icon: "tune" },
        { id: "keybinds", label: "Keybinds", icon: "keyboard" },
        { id: "profiles", label: "Profiles & data", icon: "inventory_2" }
    ]

    // case-insensitive match of the search text against any of the given strings
    function matches(a, b, c): bool {   // untyped: missing arguments stay undefined
        const q = query.trim().toLowerCase();
        return !q || [a, b, c].some(t => (t ?? "").toLowerCase().includes(q));
    }
}
