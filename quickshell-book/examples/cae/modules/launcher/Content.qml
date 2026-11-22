import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import qs.config
import qs.services
import qs.components
import qs.modules.settings

// The launcher rises from the bottom edge. The search bar sits at the bottom and the list
// grows upward. Type to search apps; start with ">" for actions (">wallpaper", ">calc 2^10", ...).
Item {
    id: root

    required property ScreenState screenState

    readonly property string prefix: Config.launcher.actionPrefix
    readonly property bool actionMode: search.text.startsWith(prefix)
    readonly property string actionText: actionMode ? search.text.slice(prefix.length) : ""
    readonly property bool wallpaperMode: actionMode && actionText.startsWith("wallpaper")
    property string calcResult: ""

    readonly property var actions: [
        { name: "wallpaper", icon: "image", desc: "Pick a wallpaper", run: () => search.text = prefix + "wallpaper " },
        { name: "calc", icon: "calculate", desc: "Calculate with qalc, e.g. calc 5 USD to EUR", run: () => search.text = prefix + "calc " },
        { name: "settings", icon: "settings", desc: "Open the shell settings", run: () => Settings.open() },
        { name: "lock", icon: "lock", desc: "Lock the screen", run: () => Quickshell.execDetached(["qs", "-c", "cae", "ipc", "call", "lock", "lock"]) },
        { name: "logout", icon: "logout", desc: "Log out", run: () => Quickshell.execDetached(["loginctl", "terminate-user", Quickshell.env("USER")]) },
        { name: "sleep", icon: "bedtime", desc: "Suspend", run: () => Quickshell.execDetached(["systemctl", "suspend"]) },
        { name: "reboot", icon: "restart_alt", desc: "Restart", run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
        { name: "shutdown", icon: "power_settings_new", desc: "Shut down", run: () => Quickshell.execDetached(["systemctl", "poweroff"]) }
    ]

    readonly property var results: {
        if (!actionMode) return Apps.search(search.text).slice(0, Config.launcher.maxShown);
        if (actionText.startsWith("calc ")) return [{ name: calcResult || "…", icon: "calculate", desc: "Enter copies the result", run: () => Quickshell.execDetached(["wl-copy", calcResult]) }];
        return actions.filter(a => a.name.startsWith(actionText.split(" ")[0]));
    }

    function close(): void {
        screenState.launcher = false;
    }
    function activate(index: int): void {
        const r = results[index];
        if (!r) return;
        if (typeof r.run !== "function") {   // an app, not an action
            Apps.launch(r);
            close();
        } else {
            r.run();
            if (r.name !== "wallpaper" && r.name !== "calc") close();
        }
    }

    implicitWidth: Tokens.sizes.launcherWidth
    implicitHeight: (wallpaperMode ? walls.height : list.contentHeight) + search.height + Tokens.padding.large * 3

    // reset when it closes, focus the field when it opens
    Connections {
        target: root.screenState
        function onLauncherChanged(): void {
            if (root.screenState.launcher) search.focusField();
            else search.text = "";
        }
    }

    ListView {
        id: list

        visible: !root.wallpaperMode
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: search.top
        anchors.margins: Tokens.padding.large
        height: contentHeight
        interactive: false
        spacing: 2
        currentIndex: 0
        verticalLayoutDirection: ListView.BottomToTop      // best match right above the search bar
        model: ScriptModel { values: root.results }

        highlight: StyledRect {
            radius: Tokens.rounding.large
            color: Colours.palette.m3surfaceContainerHighest
        }
        highlightMoveDuration: Tokens.anim.durations.fastSpatial

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool isApp: typeof modelData.run !== "function"

            width: ListView.view.width
            height: 54

            Row {
                anchors.verticalCenter: parent.verticalCenter
                x: Tokens.padding.medium
                spacing: Tokens.spacing.medium

                Loader {
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: row.isApp ? appIcon : symbol
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    StyledText { text: row.modelData.name; font.weight: 500 }
                    StyledText {
                        width: list.width - 90
                        text: (row.isApp ? (row.modelData.comment || row.modelData.genericName) : row.modelData.desc) ?? ""
                        elide: Text.ElideRight
                        color: Colours.palette.m3outline
                        font.pixelSize: Tokens.font.size.small
                        visible: text !== ""
                    }
                }
            }

            Component { id: appIcon; IconImageWrapper { entry: row.modelData } }
            Component { id: symbol; MaterialIcon { text: row.modelData.icon; font.pixelSize: 26; color: Colours.palette.m3primary } }

            StateLayer {
                radius: Tokens.rounding.large
                onClicked: root.activate(row.index)
                onEntered: list.currentIndex = row.index
            }
        }

        add: Transition { Anim { property: "opacity"; from: 0; to: 1; type: Anim.Effects } }
        displaced: Transition { Anim { property: "y"; type: Anim.FastSpatial } }
    }

    WallpaperGrid {
        id: walls
        visible: root.wallpaperMode
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: search.top
        anchors.margins: Tokens.padding.large
        filter: root.actionText.slice("wallpaper".length).trim()
        onPicked: root.close()
    }

    StyledRect {
        id: search

        property alias text: field.text

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.large
        height: 48
        radius: Tokens.rounding.full
        color: Colours.palette.m3surfaceContainer

        function focusField(): void { field.forceActiveFocus() }

        MaterialIcon {
            id: searchIcon
            anchors.verticalCenter: parent.verticalCenter
            x: Tokens.padding.large
            text: root.actionMode ? "terminal" : "search"
            color: Colours.palette.m3onSurfaceVariant
        }

        TextField {
            id: field
            anchors.left: searchIcon.right
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.spacing.small
            anchors.rightMargin: Tokens.padding.large
            background: null
            color: Colours.palette.m3onSurface
            font.family: Tokens.font.sans
            font.pixelSize: Tokens.font.size.normal
            placeholderText: `Type "${root.prefix}" for commands`
            placeholderTextColor: Colours.palette.m3outline

            onTextChanged: {
                list.currentIndex = 0;
                if (root.actionText.startsWith("calc ")) calc.running = true;
            }
            Keys.onUpPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
            Keys.onDownPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
            Keys.onEscapePressed: root.close()
            onAccepted: root.wallpaperMode ? walls.pickCurrent() : root.activate(list.currentIndex)
        }
    }

    Process {
        id: calc
        command: ["qalc", "-t", root.actionText.slice(5)]
        stdout: StdioCollector {
            onStreamFinished: root.calcResult = text.trim()
        }
    }
}
