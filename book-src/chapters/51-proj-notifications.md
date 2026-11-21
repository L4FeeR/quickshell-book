# Project: Notification Daemon

Replace dunst/mako/swaync with your own notification system: popups that slide in, auto-expire with a progress bar, pause on hover, show images and action buttons, respect Do Not Disturb, and a history kept for the control center.

> [!WARN] Only one daemon
> The notification bus name can be owned by one program at a time. Stop the old daemon (`pkill dunst mako swaync`) and remove it from autostart, or Quickshell's server will fail to register.

## The service

```qml file="services/Notifs.qml"
pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    readonly property var list: server.trackedNotifications.values      // all (history)
    readonly property int count: list.length
    property var popups: []                                             // currently shown as popups

    function init(): void {}                       // called from shell.qml so the server starts at login

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: false
        actionsSupported: true
        actionIconsSupported: true
        imageSupported: true
        inlineReplySupported: true

        onNotification: n => {
            n.tracked = true                       // keep it (otherwise it's dropped immediately)
            n.closed.connect(() => root.hidePopup(n))   // remove its popup when it closes
            if (n.lastGeneration) return           // re-emitted after a hot reload: don't re-popup
            const critical = n.urgency === NotificationUrgency.Critical
            if (!GlobalStates.dnd || critical)
                root.popups = [n, ...root.popups].slice(0, 6)            // newest first, max 6
        }
    }

    function hidePopup(n): void { popups = popups.filter(p => p !== n) }
    function dismiss(n): void { hidePopup(n); n.dismiss() }
    function clearAll(): void { [...list].forEach(n => n.dismiss()); popups = [] }
}
```

`n.tracked = true` means "keep this notification in `trackedNotifications`". It stays there until `dismiss()`, `expire()` or the app closes it, which makes `trackedNotifications` a ready-made history.

## The popup window

```qml file="modules/notifications/NotificationPopups.qml"
import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

PanelWindow {
    id: win
    screen: Quickshell.screens.find(s => s.name === GlobalStates.activeScreen) ?? null
    anchors { top: !Config.bar.bottom; bottom: Config.bar.bottom; right: true }
    margins { top: 8; bottom: 8; right: 8 }
    implicitWidth: Appearance.sizes.notificationWidth + 20    // room for shadows
    implicitHeight: Math.max(1, list.contentHeight + 20)
    exclusionMode: ExclusionMode.Normal
    color: "transparent"
    visible: Notifs.popups.length > 0 && !GlobalStates.controlCenterOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifications"
    mask: Region { item: list.contentItem }                   // only cards catch clicks

    ListView {
        id: list
        anchors { fill: parent; margins: 10 }
        spacing: 8
        interactive: false
        model: ScriptModel { values: Notifs.popups }
        delegate: NotificationCard {
            required property var modelData
            notif: modelData
            width: ListView.view.width
            popup: true
            onTimeout: Notifs.hidePopup(modelData)
        }
        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "x"; from: 420; to: 0; duration: 400; easing.type: Easing.OutCubic }
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250 }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "x"; to: 420; duration: 250; easing.type: Easing.InCubic }
                NumberAnimation { property: "opacity"; to: 0; duration: 200 }
            }
        }
        displaced: Transition { NumberAnimation { property: "y"; duration: 300; easing.type: Easing.OutCubic } }
    }
}
```

## The notification card

Used both for popups and in the control-center history:

```qml file="modules/notifications/NotificationCard.qml"
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.widgets

StyledRect {
    id: root
    required property Notification notif
    property bool popup: false
    property bool expanded: false
    signal timeout()

    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    // expireTimeout is in SECONDS; <= 0 means "server decides"
    readonly property int timeoutMs: critical ? 0 : (notif?.expireTimeout > 0 ? notif.expireTimeout * 1000 : 5000)

    level: popup ? 2 : 0
    implicitHeight: content.implicitHeight + 24
    radius: Appearance.rounding.large
    color: critical ? Colors.alpha(Colors.error, 0.15) : (popup ? Colors.surfaceContainer : Colors.surfaceContainerHigh)
    border.width: critical ? 1 : 0
    border.color: Colors.error
    Behavior on implicitHeight { Anim {} }

    HoverHandler { id: hover }

    // countdown, paused on hover
    property real elapsed: 0
    Timer {
        running: root.popup && root.timeoutMs > 0 && !hover.hovered
        interval: 50; repeat: true
        onTriggered: { root.elapsed += interval; if (root.elapsed >= root.timeoutMs) root.timeout() }
    }

    // swipe right to dismiss
    DragHandler {
        id: drag
        xAxis.enabled: true; yAxis.enabled: false
        xAxis.minimum: 0
        onActiveChanged: if (!active) { if (root.x > 120) Notifs.dismiss(root.notif); else root.x = 0 }
    }
    opacity: 1 - Math.min(1, x / 300)

    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 8

        RowLayout {
            spacing: 10
            Layout.fillWidth: true

            // image (avatar / album art) or app icon
            ClippingRectangle {
                Layout.preferredWidth: 42; Layout.preferredHeight: 42
                Layout.alignment: Qt.AlignTop
                radius: root.notif?.image ? 21 : Appearance.rounding.normal
                color: Colors.secondaryContainer
                Image {
                    anchors.fill: parent
                    visible: !!root.notif?.image
                    source: root.notif?.image ?? ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(84, 84)
                    asynchronous: true
                }
                IconImage {
                    anchors.centerIn: parent
                    visible: !root.notif?.image
                    implicitSize: 26
                    source: Quickshell.iconPath(root.notif?.appIcon || root.notif?.desktopEntry || "", "dialog-information")
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                RowLayout {
                    StyledText {
                        text: root.notif?.appName ?? ""
                        color: Colors.onSurfaceVariant
                        font.pixelSize: Appearance.font.size.small
                        Layout.fillWidth: true
                    }
                    IconButton {
                        visible: (root.notif?.body ?? "").length > 120
                        icon: root.expanded ? "expand_less" : "expand_more"
                        size: 24
                        onClicked: root.expanded = !root.expanded
                    }
                    IconButton { icon: "close"; size: 24; onClicked: Notifs.dismiss(root.notif) }
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.notif?.summary ?? ""
                    font.bold: true
                    font.pixelSize: Appearance.font.size.large
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.notif?.body ?? ""
                    textFormat: Text.StyledText                    // <b>, <i>, <a href>
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: root.expanded ? 20 : 3
                    color: Colors.onSurfaceVariant
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
            }
        }

        // inline reply (chat apps)
        TextField {
            Layout.fillWidth: true
            visible: root.notif?.hasInlineReply ?? false
            placeholderText: root.notif?.inlineReplyPlaceholder || "Reply…"
            onAccepted: { root.notif.sendInlineReply(text); text = "" }
        }

        // action buttons
        RowLayout {
            Layout.fillWidth: true
            visible: (root.notif?.actions.length ?? 0) > 0
            spacing: 6
            Repeater {
                model: (root.notif?.actions ?? []).filter(a => a.identifier !== "default")
                Rectangle {
                    required property NotificationAction modelData
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 16
                    color: Colors.secondaryContainer
                    StyledText {
                        anchors.centerIn: parent
                        text: modelData.text
                        color: Colors.onSecondaryContainer
                    }
                    StateLayer { tint: Colors.onSecondaryContainer; onClicked: modelData.invoke() }
                }
            }
        }

        // timeout progress bar
        Rectangle {
            visible: root.popup && root.timeoutMs > 0
            Layout.fillWidth: true
            implicitHeight: 3
            radius: 2
            color: Colors.surfaceContainerHighest
            Rectangle {
                width: parent.width * Math.max(0, 1 - root.elapsed / Math.max(1, root.timeoutMs))
                height: parent.height; radius: 2
                color: Colors.primary
            }
        }
    }

    // clicking the body runs the "default" action
    TapHandler {
        onTapped: {
            const d = root.notif?.actions.find(a => a.identifier === "default")
            if (d) d.invoke()
        }
    }
}
```

## Testing

```bash
notify-send "Hello" "Plain notification"
notify-send -i firefox "With icon" "Body with <b>bold</b> and <a href='https://quickshell.org'>a link</a>"
notify-send -u critical "Battery" "5% remaining"
notify-send -A yes=Yes -A no=No "Question" "Pick one"     # prints the chosen action id
notify-send -t 2000 "Short" "Expires in 2 s"
notify-send -h string:image-path:/usr/share/pixmaps/archlinux-logo.png "Image" "With image hint"
```

## Grouping by app (history)

```qml
readonly property var grouped: {
    const g = {}
    for (const n of Notifs.list) (g[n.appName] = g[n.appName] ?? []).push(n)
    return Object.entries(g).map(([app, items]) => ({ app, items }))
}
```

Use it in the control center ([[ch:55-proj-control-center]]) with a collapsible header per app.

## Sounds

```qml
Process { id: ding; command: ["pw-play", "/usr/share/sounds/freedesktop/stereo/message.oga"] }
// in onNotification: if (!GlobalStates.dnd) ding.running = true
```

> [!TRY] Exercises
> 1. Limit popups per app to 2 (replace older ones from the same app).
> 2. Add a "Mark all read" button that clears popups but keeps history.
> 3. Persist DND across restarts in a state file.
