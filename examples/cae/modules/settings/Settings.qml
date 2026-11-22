pragma Singleton
import Quickshell
import QtQuick
import qs.modules.settings

// Opens the settings window inside the running shell (like Caelestia's Nexus).
// Only one window exists at a time; it is destroyed when closed.
Singleton {
    id: root

    property SettingsWindow window: null

    function open(): void {
        if (!root.window)
            root.window = windowComp.createObject(root);
    }

    Component {
        id: windowComp

        SettingsWindow {
            onClosed: {
                root.window = null;
                destroy();
            }
        }
    }
}
