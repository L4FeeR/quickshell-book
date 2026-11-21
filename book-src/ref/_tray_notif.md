=== SystemTray
@@@ intro
The **system tray** host. Apps that use the StatusNotifierItem protocol (Discord, Steam, Telegram, nm-applet, Nextcloud…) appear in `items`.

@@@ example Example
```qml
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick

Row {
    spacing: 6
    Repeater {
        model: SystemTray.items
        IconImage { required property SystemTrayItem modelData; implicitSize: 18; source: modelData.icon
                    TapHandler { onTapped: modelData.activate() } }
    }
}
```

@@@ notes
Old XEmbed tray icons (some very old apps) aren't supported; most apps today use SNI.

@@@ see
[[ch:50-proj-tray]] · [[SystemTrayItem]]

=== SystemTrayItem
@@@ intro
One tray icon. Show its `icon`, react to clicks with `activate()`/`secondaryActivate()`/`scroll()`, and show its `menu`.

@@@ example Example: every property and function
```qml
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick

PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    implicitHeight: 32
    Row {
        anchors.centerIn: parent
        spacing: 8
        Repeater {
            model: SystemTray.items
            IconImage {
                id: icon
                required property SystemTrayItem modelData
                implicitSize: 20
                source: modelData.icon                                 // image source string
                opacity: modelData.status === Status.Passive ? 0.5 : 1 // Passive | Active | NeedsAttention
                Component.onCompleted: console.log(modelData.id, modelData.title, "category", modelData.category,
                                                   "tooltip:", modelData.tooltipTitle, modelData.tooltipDescription,
                                                   "hasMenu", modelData.hasMenu, "onlyMenu", modelData.onlyMenu)
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    onClicked: m => {
                        if (m.button === Qt.LeftButton && !icon.modelData.onlyMenu) icon.modelData.activate()
                        else if (m.button === Qt.MiddleButton) icon.modelData.secondaryActivate()
                        else if (icon.modelData.hasMenu) {
                            const p = bar.itemPosition(icon)
                            icon.modelData.display(bar, p.x, p.y + icon.height)      // quick native menu
                        }
                    }
                    onWheel: w => icon.modelData.scroll(w.angleDelta.y / 120, false)  // horizontal = false
                }
            }
        }
    }
}
```

@@@ member icon
Usually an `image://` URL usable directly as an image source. Some apps send `name?path=/dir`; see [[ch:50-proj-tray]] for a fix.

@@@ member menu
Pass it to [[QsMenuAnchor]] (native) or [[QsMenuOpener]] (custom-drawn menu).

@@@ member onlyMenu
If true, `activate()` does nothing: open the menu on left click instead.

=== NotificationServer
@@@ intro
Makes your shell the **notification daemon**. Create one (only one daemon can run on the system), declare which features you support, and handle `notification` to receive them.

@@@ example Example: every property and signal
```qml
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Scope {
    NotificationServer {
        id: server
        keepOnReload: true                 // re-emit existing notifications after a hot reload (default)
        persistenceSupported: true         // you keep notifications after they leave the screen
        bodySupported: true                // default true
        bodyMarkupSupported: true          // <b>, <i>, <u>
        bodyHyperlinksSupported: true      // <a href>
        bodyImagesSupported: false         // <img> in body
        actionsSupported: true             // buttons
        actionIconsSupported: false        // action identifiers are icon names
        imageSupported: true               // image / avatar
        inlineReplySupported: true         // reply text field
        extraHints: []                     // extra hint names to advertise

        onNotification: n => {
            n.tracked = true               // REQUIRED: keep it in trackedNotifications
            console.log(n.appName, n.summary)
        }
    }
    // history: server.trackedNotifications (ObjectModel<Notification>)
}
```

@@@ member keepOnReload
Re-emitted notifications have `lastGeneration` true. Skip showing popups for those.

@@@ notes
- Stop dunst, mako or swaync first.
- Advertising a feature tells apps they may use it; only enable what your UI shows.

@@@ see
[[ch:51-proj-notifications]] · [[Notification]]

=== Notification
@@@ intro
One notification received by a [[NotificationServer]]. Show its content, run its actions, and close it.

@@@ example Example: every property and function
```qml
import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    required property Notification n
    Text { text: `#${n.id} from ${n.appName} (${n.desktopEntry}) icon ${n.appIcon}` }
    Text { text: n.summary; font.bold: true }
    Text { text: n.body; textFormat: Text.StyledText; wrapMode: Text.Wrap }
    Image { source: n.image; visible: n.image !== ""; sourceSize: Qt.size(64, 64) }
    Text { text: "urgency: " + NotificationUrgency.toString(n.urgency) }
    Text { text: "expire after: " + n.expireTimeout + " s" }                    // ≤ 0 means "you decide"
    Text { text: `resident ${n.resident} transient ${n.transient} tracked ${n.tracked} lastGeneration ${n.lastGeneration}` }
    Text { text: "hints: " + JSON.stringify(n.hints) }
    Row {
        Repeater {
            model: n.actions
            Button { required property NotificationAction modelData; text: modelData.text; onClicked: modelData.invoke() }
        }
    }
    TextField {
        visible: n.hasInlineReply
        placeholderText: n.inlineReplyPlaceholder
        onAccepted: n.sendInlineReply(text)
    }
    Row {
        Button { text: "Dismiss"; onClicked: n.dismiss() }   // user closed it
        Button { text: "Expire"; onClicked: n.expire() }     // timed out
    }
    Connections { target: n; function onClosed(reason) { console.log("closed:", NotificationCloseReason.toString(reason)) } }
}
```

@@@ member tracked
Set to `true` in `onNotification` to keep it. Setting it to `false` is like dismissing it.

@@@ member expireTimeout
In **seconds**. `0` or negative means the server decides (typically 5 s; critical: never).

@@@ member resident
If true, invoking an action doesn't close the notification.

@@@ member transient
If true, don't keep it in a history/notification center.

=== NotificationAction
@@@ intro
A button on a [[Notification]]. Show `text`; call `invoke()` when clicked. The action with identifier `"default"` is conventionally triggered by clicking the notification body.

@@@ example Example
```qml
Repeater {
    model: notif.actions.filter(a => a.identifier !== "default")
    Button { required property NotificationAction modelData; text: modelData.text; onClicked: modelData.invoke() }
}
TapHandler { onTapped: notif.actions.find(a => a.identifier === "default")?.invoke() }
```

@@@ member identifier
When the notification's `hasActionIcons` is true, this is an icon name you can display instead of text.

=== DBusMenuHandle
@@@ intro
The handle type behind tray menus ([[SystemTrayItem.menu]]). You normally pass it to [[QsMenuAnchor]] or [[QsMenuOpener]]; its `menu` property gives the root [[DBusMenuItem]].

=== DBusMenuItem
@@@ intro
A menu item exported by another program (a tray app). It's a [[QsMenuEntry]] with extras: `menuHandle` and `updateLayout()` to refresh the contents when an app builds its menu lazily.

@@@ example Example
```qml
QsMenuOpener {
    id: opener
    menu: trayItem.menu
    onMenuChanged: if (menu && menu.updateLayout) menu.updateLayout()   // some apps need a refresh
}
```
