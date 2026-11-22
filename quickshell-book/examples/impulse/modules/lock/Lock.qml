import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import qs.services

Scope {
    id: root

    property string password: ""
    property bool unlocking: false
    property bool failed: false

    function tryUnlock(): void {
        if (password === "" || unlocking) return;
        unlocking = true;
        pam.start();
    }

    PamContext {
        id: pam
        onPamMessage: if (responseRequired) respond(root.password)
        onCompleted: result => {
            root.unlocking = false;
            if (result === PamResult.Success) {
                GlobalStates.screenLocked = false;
                root.failed = false;
            } else {
                root.failed = true;
            }
            root.password = "";
        }
    }

    WlSessionLock {
        locked: GlobalStates.screenLocked
        WlSessionLockSurface {
            color: "black"
            LockSurface { context: root }
        }
    }

    IpcHandler {
        target: "lock"
        function activate(): void { GlobalStates.screenLocked = true }
    }
}
