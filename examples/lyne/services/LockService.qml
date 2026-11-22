pragma Singleton
import QtQuick
import Quickshell
import qs.services
import Quickshell.Io
import Quickshell.Services.Pam

// Whether the session is locked, what has been typed, and checking it.
// Every monitor's lock surface edits the same `buffer`, so typing works
// whichever monitor has the keyboard.
Singleton {
    id: root

    property bool locked: false
    // the lock windows exist a little longer than `locked`, so the
    // compositor is told "unlocked" before the windows are destroyed
    property bool surfaceActive: false
    property string buffer: ""
    property bool checking: false
    property bool failed: false

    function lock() { buffer = ""; failed = false; surfaceActive = true; locked = true; }

    function submit() {
        if (checking || buffer === "")
            return;
        checking = true;
        failed = false;
        pam.start();
    }

    PamContext {
        id: pam
        // PAM asks for the password: answer with what was typed
        onPamMessage: if (responseRequired) respond(root.buffer)
        onCompleted: result => {
            root.checking = false;
            root.buffer = "";
            if (result === PamResult.Success) {
                root.locked = false;
                release.restart();
            }
            else
                root.failed = true;
        }
    }

    Timer { id: release; interval: 500; onTriggered: root.surfaceActive = false }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock(); }
    }
}
