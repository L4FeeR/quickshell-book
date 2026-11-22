//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import Quickshell
import QtQuick
import Quickshell.Io
import qs.services
import qs.daemons
import qs.modules.drawers
import qs.modules.background
import qs.modules.lock

// A rebuild of the Caelestia shell, written for "The Quickshell Book".
// Run with:  qs -c cae
ShellRoot {
    Background {}
    Drawers {}
    Lock {}
    Shortcuts {}

    // `qs -c cae ipc call shell reload` restarts every panel (used by the settings app)
    IpcHandler {
        target: "shell"
        function reload(): void { Quickshell.reload(true) }
    }

    // singletons load lazily; start the notification server at login
    Component.onCompleted: Notifs.dnd = false
}
