import Quickshell
import QtQuick

// One frame window (plus the windows that reserve space) for every monitor.
Variants {
    model: Quickshell.screens

    Scope {
        id: scope

        required property ShellScreen modelData

        Exclusions {
            screen: scope.modelData
            barZone: content.bar.exclusiveZone
        }

        ContentWindow {
            id: content
            screen: scope.modelData
        }
    }
}
