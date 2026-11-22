# Effects: Shadows, Blur, Masks, Tints

Shadows give depth, blur gives glass, masks give rounded images, tints make monochrome icons match your theme. Qt 6 provides all of this through **MultiEffect**. Quickshell adds **ClippingRectangle** for cheap rounded clipping and **BackgroundEffect** for compositor blur.

## ClippingRectangle: rounded clipping, the easy way

`clip: true` only clips to a rectangle. To clip children to **rounded corners** (album art, avatars, wallpaper thumbnails), use Quickshell's [[ClippingRectangle]]:

```qml
import Quickshell.Widgets

ClippingRectangle {
    width: 120; height: 120
    radius: 24                       // children are clipped to this rounded shape
    color: "#313244"                 // background behind the children
    Image {
        anchors.fill: parent
        source: "file:///home/me/.face"
        fillMode: Image.PreserveAspectCrop
    }
}
```

Its sibling [[ClippingWrapperRectangle]] also sizes itself around a single child with margins.

## MultiEffect

`import QtQuick.Effects`. MultiEffect takes a `source` item and draws it with effects applied. The usual pattern: hide the original (`visible: false`) and draw the effect in its place.

### Drop shadow
```qml
import QtQuick
import QtQuick.Effects

Item {
    width: 300; height: 200

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 220; height: 120; radius: 18
        color: "#1e1e2e"
        visible: false                         // drawn by the effect below
    }
    MultiEffect {
        source: card
        anchors.fill: card
        shadowEnabled: true
        shadowColor: "#000000"
        shadowOpacity: 0.55
        shadowBlur: 0.9                        // 0..1
        shadowVerticalOffset: 6
        shadowHorizontalOffset: 0
        autoPaddingEnabled: true               // allow the shadow to extend outside the item
    }
}
```

> [!TIP] Shadows near window edges
> A shadow is drawn **inside your window**. If your card touches the window's edge, the shadow is cut off. Leave margins around shadowed items, and make the window bigger than the visible card.

### Blur (of your own content)
```qml
Image { id: wall; anchors.fill: parent; source: "file:///…/wall.jpg"; fillMode: Image.PreserveAspectCrop; visible: false }
MultiEffect {
    source: wall
    anchors.fill: wall
    blurEnabled: true
    blur: 1.0             // amount 0..1
    blurMax: 64           // maximum radius in px (affects quality and cost)
    brightness: -0.2      // darken a bit for readable text on top
    saturation: 0.2
}
```

That's the lock screen look: a blurred, dimmed wallpaper.

### Colorize (tint icons)
```qml
Image { id: icon; source: "icons/logo.svg"; sourceSize: Qt.size(32, 32); visible: false }
MultiEffect {
    source: icon; anchors.fill: icon
    colorization: 1.0                 // 0 = original, 1 = fully tinted
    colorizationColor: "#cba6f7"
}
```

### Mask (shape one item by another)
```qml
Image { id: photo; width: 200; height: 120; source: "…"; fillMode: Image.PreserveAspectCrop; visible: false }
Rectangle { id: shape; width: 200; height: 120; radius: 30; visible: false; layer.enabled: true }
MultiEffect {
    source: photo; anchors.fill: photo
    maskEnabled: true
    maskSource: shape                 // where the mask is opaque, the photo shows
    maskThresholdMin: 0.5
    maskSpreadAtMin: 1.0
}
```

The mask source must be rendered offscreen, which is why it has `layer.enabled: true`. For plain rounded corners, `ClippingRectangle` is simpler and cheaper; use masks for arbitrary shapes (a circle with a notch, text-shaped holes).

### MultiEffect property reference

| Group | Properties |
|---|---|
| Source | `source`, `autoPaddingEnabled`, `paddingRect` |
| Brightness/contrast | `brightness` (-1..1), `contrast` (-1..1), `saturation` (-1..1) |
| Colorize | `colorization` (0..1), `colorizationColor` |
| Blur | `blurEnabled`, `blur` (0..1), `blurMax` (px), `blurMultiplier` |
| Shadow | `shadowEnabled`, `shadowColor`, `shadowOpacity`, `shadowBlur`, `shadowHorizontalOffset`, `shadowVerticalOffset`, `shadowScale` |
| Mask | `maskEnabled`, `maskSource`, `maskInverted`, `maskThresholdMin/Max`, `maskSpreadAtMin/Max` |

## layer: render an item offscreen

Any item can be rendered into an offscreen texture with `layer.enabled: true`, and an effect can be applied with `layer.effect`:

```qml
Rectangle {
    width: 200; height: 100; radius: 16; color: "#1e1e2e"
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowBlur: 0.8
        shadowVerticalOffset: 4
    }
}
```

This is more compact than a separate MultiEffect, and the item stays interactive. It's also how you make a **group** of items fade as one (otherwise overlapping children show through each other at partial opacity): `layer.enabled: true; opacity: 0.5`.

> [!WARN] Layers cost memory and GPU time
> Each layer is a full texture. Don't enable layers on dozens of items, and don't put them on things that change every frame unless needed. Turn them off while hidden: `layer.enabled: visible`.

## Blur *behind* your window (glass)

MultiEffect only blurs **your own** content. To blur the windows and wallpaper **behind** a panel, the compositor must do it.

### Hyprland: layer rules
```ini file="hyprland.conf"
layerrule = blur, quickshell:bar          # namespace from WlrLayershell.namespace
layerrule = ignorealpha 0.2, quickshell:bar   # don't blur nearly transparent pixels (e.g. shadows)
```

Give your window a namespace and a translucent background:

```qml
PanelWindow {
    WlrLayershell.namespace: "quickshell:bar"
    color: "transparent"
    Rectangle { anchors.fill: parent; radius: 14; color: "#b31e1e2e" }   // 70% opaque
}
```

### The Wayland background-effect protocol: BackgroundEffect
Newer Quickshell versions include [[BackgroundEffect]] (module `Quickshell.Wayland`), which asks the compositor to blur behind specific regions of your window through a Wayland protocol, where the compositor supports it. Check its reference page for the exact properties and compositor support.

## Qt5Compat.GraphicalEffects (legacy)

Older configs use `import Qt5Compat.GraphicalEffects` with `DropShadow`, `OpacityMask`, `ColorOverlay`, `FastBlur`, `GaussianBlur`. They still work if `qt6-5compat` is installed, but MultiEffect is the modern replacement:

| Old | New |
|---|---|
| `DropShadow` | `MultiEffect { shadowEnabled: true }` |
| `OpacityMask` | `MultiEffect { maskEnabled: true }` or `ClippingRectangle` |
| `ColorOverlay` | `MultiEffect { colorization: 1 }` |
| `FastBlur` / `GaussianBlur` | `MultiEffect { blurEnabled: true }` |

## Custom shaders (advanced)

`ShaderEffect` runs your own GLSL fragment shader, compiled to `.qsb` with Qt's `qsb` tool. It's used for animated gradients, noise and wave effects. That's out of scope for beginners, but know it exists when you see `.frag.qsb` files in advanced rices.

## Practice

::: exercise warm | Soft shadow
Make a floating card with a soft shadow, leaving enough margin in its window for the shadow.
--- solution
```qml
Rectangle { anchors.centerIn: parent; width: 260; height: 120; radius: 16; color: "#1e1e2e"
    layer.enabled: true
    layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 0.8; shadowColor: "#80000000"; shadowVerticalOffset: 6 } }
```
Give the window ~30 px more than the card on each side; shadows outside the window get cut off.
:::

::: exercise practice | Blurred backdrop
Show your wallpaper blurred and darkened behind a big clock.
--- solution
```qml
Image { id: wall; anchors.fill: parent; source: "file:///path/wall.jpg"; fillMode: Image.PreserveAspectCrop; visible: false }
MultiEffect { anchors.fill: wall; source: wall; blurEnabled: true; blur: 1; blurMax: 64; brightness: -0.3 }
Text { anchors.centerIn: parent; text: Qt.formatTime(new Date(), "hh:mm"); color: "white"; font.pixelSize: 96 }
```
:::

::: exercise practice | Tint an icon
Tint a white SVG icon with your accent color using `colorization`.
--- solution
```qml
Image { id: ico; source: "icon.svg"; sourceSize: Qt.size(32, 32); visible: false }
MultiEffect { anchors.fill: ico; source: ico; colorization: 1; colorizationColor: "#cba6f7" }
```
:::

::: exercise challenge | Compositor blur
On Hyprland, add a `layerrule = blur` for your bar's namespace and make the bar 70% opaque.
--- solution
```qml
WlrLayershell.namespace: "quickshell:bar"
color: Qt.rgba(0.12, 0.12, 0.18, 0.7)
```
```ini
layerrule = blur, quickshell:bar
layerrule = ignorealpha 0.2, quickshell:bar
```
:::
