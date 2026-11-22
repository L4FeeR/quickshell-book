# Ricing Notifications, Module by Module

Notifications interrupt you, so they should be **beautiful but calm**: clear hierarchy, an obvious way to dismiss, and motion that tells you where they come from and where they go. This guide builds a notification card from modules and offers three popup styles: a corner stack, a Dynamic-Island-style top banner, and minimal toasts.

**Logic** (the server, tracking, popups list, DND) comes from the `Notifs` service in [[ch:51-proj-notifications]]. This guide is about the look.

## Anatomy of a card

<div class="preview"><svg width="440" height="210" viewBox="0 0 440 210"><rect x="40" y="15" width="360" height="170" rx="18" fill="#1e1e2e" stroke="#313244"/><rect x="40" y="15" width="4" height="170" rx="2" fill="#cba6f7"/><g font-size="10"><circle cx="72" cy="40" r="9" fill="#89b4fa"/><text x="88" y="44" fill="#a6adc8">Discord · now</text><text x="380" y="44" fill="#a6adc8" text-anchor="end">✕</text><circle cx="78" cy="88" r="22" fill="#f5c2e7"/><text x="112" y="80" fill="#cdd6f4" font-size="13" font-weight="700">Alex</text><text x="112" y="98" fill="#a6adc8" font-size="11">Did you push the new rice? It looks</text><text x="112" y="112" fill="#a6adc8" font-size="11">amazing in the screenshot!</text><rect x="62" y="134" width="150" height="28" rx="14" fill="#313244"/><text x="137" y="152" fill="#cdd6f4" text-anchor="middle">Reply</text><rect x="222" y="134" width="150" height="28" rx="14" fill="#313244"/><text x="297" y="152" fill="#cdd6f4" text-anchor="middle">Mark read</text><rect x="62" y="172" width="310" height="3" rx="1.5" fill="#313244"/><rect x="62" y="172" width="180" height="3" rx="1.5" fill="#cba6f7"/></g><g fill="#585b70" font-size="9"><text x="300" y="58">header</text><text x="300" y="72">image + text</text></g></svg></div>

| Module | File | Job |
|---|---|---|
| Header | `NotifHeader.qml` | app icon, app name, relative time, close button |
| Media | `NotifImage.qml` | avatar or image, falling back to the app icon |
| Content | `NotifContent.qml` | summary and body with expand/collapse |
| Actions | `NotifActions.qml` | action buttons |
| Timer bar | `NotifTimer.qml` | countdown, paused on hover |
| Card | `NotifCard.qml` | assembles modules: urgency style, swipe to dismiss |
| Popups | `NotifPopups.qml` | the window: stack, banner or toast style |

## Module 1: Header

```qml file="rice/notifications/NotifHeader.qml"
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

RowLayout {
    id: root
    required property var notif
    property date received: new Date()
    signal closeClicked()
    spacing: 6

    // "now", "3m", "1h"…  updates every minute
    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property string ago: {
        const m = Math.floor((clock.date - root.received) / 60000)
        return m < 1 ? "now" : m < 60 ? m + "m" : Math.floor(m / 60) + "h"
    }

    IconImage { implicitSize: 16; source: Quickshell.iconPath(root.notif?.appIcon || root.notif?.desktopEntry || "", "dialog-information") }
    TText { text: root.notif?.appName ?? ""; color: Theme.fgDim; font.pixelSize: Theme.textSmall }
    TText { text: "· " + root.ago; color: Theme.alpha(Theme.fgDim, 0.6); font.pixelSize: Theme.textSmall }
    Item { Layout.fillWidth: true }
    TButton { icon: "close"; size: 22; onClicked: root.closeClicked() }
}
```

<!-- ex:## Module 1 -->
::: exercise warm | Hide the time for old ones
Change the relative time to show the clock time (`hh:mm`) when the notification is older than 6 hours.
:::


## Module 2: Image

```qml file="rice/notifications/NotifImage.qml"
import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.services

ClippingRectangle {
    required property var notif
    readonly property bool hasImage: (notif?.image ?? "") !== ""
    visible: hasImage
    implicitWidth: 46; implicitHeight: 46
    radius: Theme.style === "neon" ? 0 : 23                   // people avatars look best round
    color: Theme.surface
    Image { anchors.fill: parent; source: parent.notif?.image ?? ""; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(92, 92); asynchronous: true }
}
```

<!-- ex:## Module 2 -->
::: exercise practice | Square images
Show non-avatar images (screenshots) as rounded squares and keep people avatars round.
--- hint
Notifications with a `desktopEntry` of a screenshot tool, or images wider than tall, are usually not avatars.
:::


## Module 3: Content with expand

```qml file="rice/notifications/NotifContent.qml"
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

ColumnLayout {
    id: root
    required property var notif
    property bool expanded: false
    readonly property bool long: (notif?.body ?? "").length > 110
    spacing: 2

    TText {
        Layout.fillWidth: true
        text: root.notif?.summary ?? ""
        font.bold: true; font.pixelSize: Theme.text + 1
    }
    TText {
        Layout.fillWidth: true
        visible: text !== ""
        text: root.notif?.body ?? ""
        textFormat: Text.StyledText
        wrapMode: Text.Wrap
        maximumLineCount: root.expanded ? 12 : 2
        color: Theme.fgDim
        onLinkActivated: l => Qt.openUrlExternally(l)
    }
    TText {
        visible: root.long
        text: root.expanded ? "Show less" : "Show more"
        color: Theme.accent; font.pixelSize: Theme.textSmall
        TapHandler { onTapped: root.expanded = !root.expanded }
    }
}
```

<!-- ex:## Module 3 -->
::: exercise practice | Copy body
Right-click the body text to copy it with `wl-copy`.
:::


## Module 4: Actions

```qml file="rice/notifications/NotifActions.qml"
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

RowLayout {
    required property var notif
    readonly property var actions: (notif?.actions ?? []).filter(a => a.identifier !== "default")
    visible: actions.length > 0
    spacing: 6
    Repeater {
        model: parent.actions
        Rectangle {
            required property var modelData
            required property int index
            Layout.fillWidth: true
            implicitHeight: 32
            radius: Theme.style === "neon" ? 0 : 16
            // first action is the primary one: filled accent
            color: index === 0 ? Theme.accent : hover.hovered ? Theme.surfaceHi : Theme.surface
            TText { anchors.centerIn: parent; text: modelData.text; color: index === 0 ? Theme.onAccent : Theme.fg; font.pixelSize: Theme.textSmall + 1 }
            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: modelData.invoke() }
        }
    }
}
```

**Ricing choice:** make the first action the primary (filled) button and the rest tonal, so users see the main choice at a glance.

<!-- ex:## Module 4 -->
::: exercise practice | Inline reply
If the notification has `hasInlineReply`, show a text field and send it with `sendInlineReply(text)`.
:::


## Module 5: Timer bar

```qml file="rice/notifications/NotifTimer.qml"
import QtQuick
import qs.services

Rectangle {
    id: root
    property int duration: 5000          // ms
    property bool paused: false
    property real progress: 1
    signal finished()
    implicitHeight: 3
    radius: 1.5
    color: Theme.surface
    Rectangle { width: parent.width * root.progress; height: parent.height; radius: parent.radius; color: Theme.accent }
    Timer {
        interval: 40; repeat: true; running: !root.paused && root.duration > 0 && root.progress > 0
        onTriggered: { root.progress -= interval / root.duration; if (root.progress <= 0) root.finished() }
    }
}
```

<!-- ex:## Module 5 -->
::: exercise practice | Circular timer
Replace the bar with a small circular countdown around the close button.
:::


## Module 6: The card

```qml file="rice/notifications/NotifCard.qml"
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

TSurface {
    id: card
    required property var notif
    property bool popup: true
    signal timeout()

    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    readonly property bool low: notif?.urgency === NotificationUrgency.Low

    implicitHeight: col.implicitHeight + 26
    color: critical ? Theme.alpha(Theme.bad, 0.16) : Theme.bg
    radius: Theme.radius
    raised: popup
    border.width: critical ? 1 : Theme.border
    border.color: critical ? Theme.bad : Theme.borderColor
    opacity: low && !hover.hovered ? 0.85 : 1                  // low urgency: quieter
    Behavior on implicitHeight { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

    Rectangle {                                                 // accent stripe on the left
        visible: Theme.style !== "material"
        x: 0; width: 4; height: parent.height; radius: 2
        color: card.critical ? Theme.bad : Theme.accent
    }

    HoverHandler { id: hover }

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14; leftMargin: 18 }
        spacing: 10
        NotifHeader { Layout.fillWidth: true; notif: card.notif; onCloseClicked: card.notif.dismiss() }
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            NotifImage { notif: card.notif; Layout.alignment: Qt.AlignTop }
            NotifContent { Layout.fillWidth: true; notif: card.notif }
        }
        NotifActions { Layout.fillWidth: true; notif: card.notif }
        NotifTimer {
            Layout.fillWidth: true
            visible: card.popup && !card.critical
            duration: card.notif?.expireTimeout > 0 ? card.notif.expireTimeout * 1000 : 5000
            paused: hover.hovered
            onFinished: card.timeout()
        }
    }

    // swipe right to dismiss
    DragHandler {
        id: drag
        yAxis.enabled: false; xAxis.minimum: 0
        onActiveChanged: if (!active) { if (card.x > 120) card.notif.dismiss(); else card.x = 0 }
    }
    Behavior on x { enabled: !drag.active; NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
    TapHandler { onTapped: card.notif?.actions.find(a => a.identifier === "default")?.invoke() }
}
```

**Ricing choices**
- **Urgency styling:** critical gets a red tint and border and never times out; low urgency is slightly transparent until hovered.
- **Accent stripe:** a 4 px bar on the left is a cheap way to make cards feel branded; Material skips it in favor of tonal surfaces.

<!-- ex:## Module 6 -->
::: exercise challenge | Swipe either way
Allow swiping left as well as right to dismiss, with the card fading as it moves away.
--- solution
Remove `xAxis.minimum: 0`, dismiss when `Math.abs(card.x) > 120`, and add `opacity: 1 - Math.min(1, Math.abs(x) / 200)`.
:::


## Assembly: three popup styles

```qml file="rice/notifications/NotifPopups.qml"
import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

PanelWindow {
    id: win
    property string style: "stack"           // "stack" | "banner" | "toast"
    readonly property bool banner: style === "banner"
    readonly property bool toast: style === "toast"

    screen: Quickshell.screens.find(s => s.name === GlobalStates.activeScreen) ?? null
    anchors { top: true; right: !win.banner && !win.toast; bottom: win.toast }
    margins { top: Theme.barHeight + 14; right: 12 }
    implicitWidth: win.banner ? 460 : win.toast ? 360 : 400
    implicitHeight: Math.max(1, list.contentHeight + 20)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: Notifs.popups.length > 0 && !GlobalStates.controlCenterOpen
    mask: Region { item: list.contentItem }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifications"

    ListView {
        id: list
        anchors { fill: parent; margins: 10 }
        spacing: 8
        interactive: false
        verticalLayoutDirection: win.toast ? ListView.BottomToTop : ListView.TopToBottom
        // banner and toast show only the newest; stack shows up to 4
        model: ScriptModel { values: Notifs.popups.slice(0, win.style === "stack" ? 4 : 1) }
        delegate: NotifCard {
            required property var modelData
            notif: modelData
            width: ListView.view.width
            onTimeout: Notifs.hidePopup(modelData)
        }
        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: win.banner || win.toast ? "y" : "x"
                                  from: win.banner ? -120 : win.toast ? 120 : 420
                                  duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220 }
            }
        }
        remove: Transition { ParallelAnimation {
            NumberAnimation { property: "opacity"; to: 0; duration: 180 }
            NumberAnimation { property: "scale"; to: 0.9; duration: 180 } } }
        displaced: Transition { NumberAnimation { properties: "x,y"; duration: 260; easing.type: Easing.OutCubic } }
    }
}
```

<div class="preview"><svg width="660" height="190" viewBox="0 0 660 190"><g font-size="10"><g transform="translate(5 5)"><rect width="210" height="160" rx="8" fill="#26233a"/><rect x="100" y="12" width="100" height="34" rx="8" fill="#1e1e2e"/><rect x="100" y="52" width="100" height="34" rx="8" fill="#1e1e2e" opacity=".8"/><rect x="100" y="92" width="100" height="34" rx="8" fill="#1e1e2e" opacity=".6"/><text x="105" y="180" fill="#a6adc8" text-anchor="middle">stack (top-right)</text></g><g transform="translate(225 5)"><rect width="210" height="160" rx="8" fill="#26233a"/><rect x="40" y="10" width="130" height="40" rx="20" fill="#000"/><circle cx="62" cy="30" r="10" fill="#f5c2e7"/><text x="80" y="34" fill="#fff">Alex: pushed it!</text><text x="105" y="180" fill="#a6adc8" text-anchor="middle">banner (island style)</text></g><g transform="translate(445 5)"><rect width="210" height="160" rx="8" fill="#26233a"/><rect x="45" y="112" width="120" height="34" rx="17" fill="#1e1e2e"/><text x="105" y="133" fill="#a6e3a1" text-anchor="middle">✓ Download done</text><text x="105" y="180" fill="#a6adc8" text-anchor="middle">toast (bottom)</text></g></g></svg></div>

<!-- ex:## Assembly -->
::: exercise practice | Position option
Add `property string corner: "top-right"` supporting all four corners.
:::


## Polish checklist

- [ ] Clear hierarchy: app name small and dim, summary bold, body regular.
- [ ] Hover pauses the timeout; critical notifications don't time out.
- [ ] Three ways to dismiss: ✕, swipe, and timeout. Clicking the body runs the default action.
- [ ] Notifications enter from the edge they live on and leave quickly.
- [ ] Long bodies collapse with "Show more".
- [ ] Popups hide while the notification center is open, so you don't see duplicates.
- [ ] DND silences popups but keeps history.

<!-- ex:## Polish checklist -->
## Practice

::: exercise project | Test it
Send test notifications of every kind with `notify-send` and check your design for each:
```bash
notify-send "Low" "quiet one" -u low
notify-send "Critical" "battery at 5%" -u critical
notify-send "With actions" "pick one" -A yes=Yes -A no=No
notify-send "Long" "$(printf 'word %.0s' {1..60})"
notify-send -i ~/.face "Avatar" "with an image"
```
:::

