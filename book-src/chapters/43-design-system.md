# Building a Design System

A **design system** is a small set of shared tokens (colors, sizes, fonts, motion) plus primitive components built from them. Every rice that looks *cohesive* has one. In this chapter you'll build `Appearance.qml` and a library of styled widgets that the projects in Part VI use.

## Tokens: Appearance.qml

```qml file="services/Appearance.qml"
pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property QtObject rounding: QtObject {
        readonly property int small: 8
        readonly property int normal: 14
        readonly property int large: 22
        readonly property int full: 9999          // pill
    }
    readonly property QtObject spacing: QtObject {
        readonly property int tiny: 2
        readonly property int small: 4
        readonly property int normal: 8
        readonly property int large: 14
        readonly property int huge: 24
    }
    readonly property QtObject padding: QtObject {
        readonly property int small: 6
        readonly property int normal: 10
        readonly property int large: 16
    }
    readonly property QtObject font: QtObject {
        readonly property string family: Config.appearance.font ?? "Inter"
        readonly property string mono: "JetBrainsMono Nerd Font"
        readonly property string icons: "Material Symbols Rounded"
        readonly property QtObject size: QtObject {
            readonly property int tiny: 10
            readonly property int small: 12
            readonly property int normal: 13
            readonly property int large: 16
            readonly property int title: 20
            readonly property int huge: 32
            readonly property int display: 72
        }
    }
    readonly property QtObject anim: QtObject {
        readonly property int fast: 150
        readonly property int normal: 250
        readonly property int slow: 400
        readonly property int verySlow: 600
        readonly property var standard:   [0.2, 0, 0, 1, 1, 1]
        readonly property var emphasized: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property var emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property var expressive: [0.38, 1.21, 0.22, 1, 1, 1]   // slight overshoot
    }
    readonly property QtObject sizes: QtObject {
        readonly property int barHeight: Config.bar.height ?? 36
        readonly property int iconButton: 32
        readonly property int notificationWidth: 380
    }
}
```

`QtObject` groups related values so you can write `Appearance.rounding.normal` and `Appearance.font.size.large`. All `readonly`, because tokens are set here and only here.

## Primitive widgets

### StyledText
```qml file="widgets/StyledText.qml"
import QtQuick
import qs.services

Text {
    color: Colors.onSurface
    font.family: Appearance.font.family
    font.pixelSize: Appearance.font.size.normal
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
    Behavior on color { ColorAnimation { duration: Appearance.anim.normal } }
}
```

### MaterialIcon
```qml file="widgets/MaterialIcon.qml"
import QtQuick
import qs.services

StyledText {
    property string icon
    property real fill: 0
    property int size: 20
    text: icon
    font.family: Appearance.font.icons
    font.pixelSize: size
    font.variableAxes: ({ "FILL": fill, "opsz": Math.max(20, Math.min(48, size)) })
    horizontalAlignment: Text.AlignHCenter
    elide: Text.ElideNone
    Behavior on fill { NumberAnimation { duration: Appearance.anim.fast } }
}
```

### Anim: one animation, house style
```qml file="widgets/Anim.qml"
import QtQuick
import qs.services

NumberAnimation {
    duration: Appearance.anim.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.anim.emphasized
}
```
```qml file="widgets/CAnim.qml"
import QtQuick
import qs.services

ColorAnimation { duration: Appearance.anim.normal }
```

Now every component writes `Behavior on x { Anim {} }` and gets identical motion.

### StateLayer: hover and press feedback
Material Design shows a translucent overlay on hover and press. Make it reusable:

```qml file="widgets/StateLayer.qml"
import QtQuick
import qs.services

MouseArea {
    id: root
    property color tint: Colors.onSurface
    property real radius: parent.radius ?? 0
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.tint
        opacity: root.pressed ? 0.16 : root.containsMouse ? 0.08 : 0
        Behavior on opacity { NumberAnimation { duration: Appearance.anim.fast } }
    }
}
```

### IconButton
```qml file="widgets/IconButton.qml"
import QtQuick
import qs.services

Rectangle {
    id: root
    property alias icon: ic.icon
    property bool toggled: false
    property int size: Appearance.sizes.iconButton
    signal clicked()
    signal rightClicked()

    implicitWidth: size; implicitHeight: size
    radius: toggled ? Appearance.rounding.normal : size / 2        // shape morphs when toggled
    color: toggled ? Colors.primary : "transparent"
    Behavior on radius { Anim {} }
    Behavior on color { CAnim {} }

    MaterialIcon {
        id: ic
        anchors.centerIn: parent
        size: root.size * 0.6
        fill: root.toggled ? 1 : 0
        color: root.toggled ? Colors.onPrimary : Colors.onSurface
    }
    StateLayer {
        tint: root.toggled ? Colors.onPrimary : Colors.onSurface
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => m.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }
}
```

### StyledSlider
```qml file="widgets/StyledSlider.qml"
import QtQuick
import QtQuick.Controls
import qs.services

Slider {
    id: s
    from: 0; to: 1
    implicitHeight: 28
    background: Rectangle {
        x: s.leftPadding; y: s.topPadding + s.availableHeight / 2 - height / 2
        width: s.availableWidth; height: 8; radius: 4
        color: Colors.surfaceContainerHighest
        Rectangle {
            width: s.visualPosition * parent.width; height: parent.height; radius: 4
            color: Colors.primary
            Behavior on width { enabled: !s.pressed; Anim { duration: Appearance.anim.fast } }
        }
    }
    handle: Rectangle {
        x: s.leftPadding + s.visualPosition * (s.availableWidth - width)
        y: s.topPadding + s.availableHeight / 2 - height / 2
        width: 6; height: 22; radius: 3
        color: Colors.primary
        scale: s.pressed ? 1.15 : 1
        Behavior on scale { Anim { duration: Appearance.anim.fast } }
    }
}
```

### StyledSwitch
```qml file="widgets/StyledSwitch.qml"
import QtQuick
import QtQuick.Controls
import qs.services

Switch {
    id: sw
    implicitWidth: 52; implicitHeight: 30
    indicator: Rectangle {
        anchors.fill: parent; radius: height / 2
        color: sw.checked ? Colors.primary : Colors.surfaceContainerHighest
        border.width: sw.checked ? 0 : 2; border.color: Colors.outline
        Behavior on color { CAnim {} }
        Rectangle {
            readonly property int d: sw.checked ? 22 : 16
            width: d; height: d; radius: d / 2
            anchors.verticalCenter: parent.verticalCenter
            x: sw.checked ? parent.width - width - 4 : 7
            color: sw.checked ? Colors.onPrimary : Colors.outline
            Behavior on x { Anim {} }
            Behavior on width { Anim {} }
        }
    }
    contentItem: Item {}
}
```

### StyledRect (surface with elevation)
```qml file="widgets/StyledRect.qml"
import QtQuick
import QtQuick.Effects
import qs.services

Rectangle {
    property int level: 1                 // 0 flat … 3 high
    radius: Appearance.rounding.large
    color: level >= 2 ? Colors.surfaceContainerHigh : Colors.surfaceContainer
    layer.enabled: level > 0
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Colors.shadow
        shadowOpacity: 0.25 + 0.1 * level
        shadowBlur: 0.4 + 0.2 * level
        shadowVerticalOffset: level * 2
    }
    Behavior on color { CAnim {} }
}
```

## Using the system

```qml
import qs.widgets
import qs.services

Row {
    spacing: Appearance.spacing.small
    IconButton { icon: "wifi"; toggled: Network.connected; onClicked: Network.toggle() }
    IconButton { icon: Audio.icon; onClicked: Audio.toggleMute() }
    StyledText { text: Math.round(Audio.volume * 100) + "%" }
}
```

No colors, no sizes, no easing curves in feature code: it's all tokens.

## Design tips for beginners

1. **Pick one radius scale and stick to it.** Inner radius = outer radius − padding looks right for nested rounded rectangles.
2. **Use a spacing scale** (4, 8, 14, 24). Random paddings make things look off.
3. **Limit font sizes** to 4–5 values.
4. **Contrast:** text on surface should have strong contrast. M3's `on*` colors are designed for this.
5. **One accent.** Use `primary` for "active/selected", and keep everything else neutral.
6. **Consistent motion.** Same durations and curves everywhere, via `Anim`.
7. **Steal from the greats**: study end-4's `modules/common/widgets/` and Caelestia's `components/` for ideas, then re-implement them in your own tokens.

## Practice

::: exercise warm | Tokens
Create `Appearance.qml` with rounding, spacing and font tokens, and replace hard-coded values in your bar with them.
:::

::: exercise practice | Change one token
Change `rounding.normal` from 14 to 4 and watch the whole shell go sharp.
--- why
This is the payoff of a design system: one number controls every corner. If something didn't change, it still has a hard-coded radius; find it and replace it with a token.
:::

::: exercise challenge | Token-only Chip
Add `widgets/Chip.qml` (icon + text pill) that uses **only** tokens: no literal colors, sizes or durations.
--- solution
```qml
import QtQuick
import qs.services
Rectangle {
    property string icon; property string text
    implicitWidth: row.implicitWidth + Appearance.spacing.normal * 2; implicitHeight: Appearance.sizes.chip
    radius: Appearance.rounding.full; color: Colors.surfaceContainerHigh
    Row { id: row; anchors.centerIn: parent; spacing: Appearance.spacing.small
        Text { text: parent.parent.icon; font.family: Appearance.font.icons; color: Colors.primary }
        Text { text: parent.parent.text; font.family: Appearance.font.sans; color: Colors.onSurface } } }
```
Adjust the token names to the ones in your `Appearance.qml`.
:::
