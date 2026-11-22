//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import Quickshell
import QtQuick
import qs.modules.settings

// The settings app as its own program (like end-4's settings.qml):
//   qs -p ~/.config/quickshell/cae/settings.qml
// It edits ~/.config/cae/shell.json; the running shell notices the file change and updates.
ShellRoot {
    SettingsWindow {
        onClosed: Qt.quit()
    }
}
