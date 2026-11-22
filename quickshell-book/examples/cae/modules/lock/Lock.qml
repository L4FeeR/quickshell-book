import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

// The lock screen controller. WlSessionLock asks the compositor for a real lock: if the shell
// crashes, the session stays locked. One LockSurface is created per monitor.
Scope {
    id: root

    property bool locked: false
    property string password: ""
    property bool busy: false
    property string message: ""
    signal failed()

    function submit(): void {
        if (busy || password === "") return;
        busy = true;
        message = "";
        pam.start();
    }

    PamContext {
        id: pam
        onPamMessage: if (responseRequired) respond(root.password)
        onCompleted: result => {
            root.busy = false;
            if (result === PamResult.Success) {
                root.locked = false;
            } else {
                root.message = "Wrong password";
                root.failed();
            }
            root.password = "";
        }
    }

    WlSessionLock {
        locked: root.locked
        WlSessionLockSurface {
            LockSurface { lock: root }
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.locked = true }
        function isLocked(): bool { return root.locked }
    }
}
