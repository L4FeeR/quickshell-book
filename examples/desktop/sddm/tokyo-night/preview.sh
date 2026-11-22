#!/usr/bin/env bash
# Run the theme without SDDM, with stand-in users and sessions.
#   ./preview.sh            opens it in a window (enter "secret" to "log in")
#   ./preview.sh shot.png   saves a 1920x1080 screenshot instead (the window
#                           opens for a moment: the blur needs a real GPU
#                           surface, and an offscreen run would leave it out)
set -euo pipefail
cd "$(dirname "$0")"
qml=$(command -v qml6 || command -v qml || echo /usr/lib/qt6/bin/qml)
if [ $# -ge 1 ]; then
    "$qml" preview/Preview.qml -- "$(realpath -m "$1")"
else
    "$qml" preview/Preview.qml
fi
