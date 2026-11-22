# Rectangle, Text and Image

Ninety percent of what you see in any rice is rectangles, text and images. This chapter covers each in depth: every property worth knowing and the tricks rices use.

## Rectangle

```qml
Rectangle {
    width: 240; height: 80
    color: "#1e1e2e"                  // fill
    radius: 16                        // rounded corners (height/2 = pill shape)
    border.width: 1
    border.color: "#45475a"
    antialiasing: true                // smooth edges (on by default when radius > 0)
}
```

### Per-corner radius (Qt 6.7+)
```qml
Rectangle {
    radius: 16                 // default for all corners
    topLeftRadius: 0           // square top-left: a "tab" attached to the left edge
    bottomLeftRadius: 0
}
```

### Gradients
```qml
Rectangle {
    width: 300; height: 60; radius: 12
    gradient: Gradient {
        orientation: Gradient.Horizontal          // or Vertical (default)
        GradientStop { position: 0.0; color: "#89b4fa" }
        GradientStop { position: 0.5; color: "#cba6f7" }
        GradientStop { position: 1.0; color: "#f5c2e7" }
    }
}
```

Built-in preset gradients exist too: `gradient: Gradient.NightFade`.

### Shapes you can make with a Rectangle

| Shape | How |
|---|---|
| Pill | `radius: height / 2` |
| Circle | `width: height; radius: width / 2` |
| Line / divider | `width: 1; height: 20` (or vice versa) |
| Outline only | `color: "transparent"; border.width: 2` |
| Dot indicator | `width: 6; height: 6; radius: 3` |
| Squircle-ish | `radius: width * 0.3` |

### Rectangle properties

| Property | Type | Meaning |
|---|---|---|
| `color` | color | Fill color |
| `radius` | real | Corner radius for all corners |
| `topLeftRadius` `topRightRadius` `bottomLeftRadius` `bottomRightRadius` | real | Per-corner (Qt 6.7+) |
| `border.width`, `border.color` | real, color | Outline (drawn **inside** the rectangle) |
| `border.pixelAligned` | bool | Snap the border to pixels for crispness |
| `gradient` | Gradient | Overrides `color` |
| `antialiasing` | bool | Smooth curved edges |

## Text

```qml
Text {
    text: "Hello world"
    color: "#cdd6f4"
    font.family: "Inter"
    font.pixelSize: 14               // use pixelSize for predictable sizes in shells
    font.weight: Font.DemiBold       // Thin, Light, Normal, Medium, DemiBold, Bold, Black…
    font.italic: false
    font.letterSpacing: 0.5
    font.capitalization: Font.AllUppercase
}
```

### Fitting text into space

```qml
Text {
    width: 200
    text: "A very long song title that will not fit in two hundred pixels"
    elide: Text.ElideRight           // "A very long song title th…"
    // elide: Text.ElideMiddle       // "A very long…two hundred pixels"
    maximumLineCount: 1
}

Text {
    width: 260
    text: "A longer body of text, such as the body of a notification, that should wrap."
    wrapMode: Text.Wrap              // NoWrap, WordWrap, WrapAnywhere, Wrap
    maximumLineCount: 3
    elide: Text.ElideRight           // "…" after the last allowed line
    lineHeight: 1.2
}
```

`elide` only works when the Text has a **width limit** (set `width`, anchors on both sides, or `Layout.maximumWidth`).

### Alignment
```qml
Text {
    width: 200; height: 40
    horizontalAlignment: Text.AlignHCenter     // AlignLeft, AlignRight, AlignHCenter, AlignJustify
    verticalAlignment: Text.AlignVCenter       // AlignTop, AlignBottom, AlignVCenter
}
```

Alignment positions the text **inside the Text item's box**. If the item is exactly as big as its text (the default), alignment does nothing visible; center the *item* with anchors instead.

### Rich text
```qml
Text {
    textFormat: Text.StyledText      // a safe, fast subset of HTML
    text: "<b>Bold</b>, <i>italic</i>, <font color='#f38ba8'>red</font>, <a href='https://x.org'>link</a>"
    onLinkActivated: link => Qt.openUrlExternally(link)
}
```

Formats: `Text.PlainText`, `Text.StyledText` (recommended for notification bodies), `Text.RichText` (fuller HTML, slower), `Text.MarkdownText`, `Text.AutoText` (guesses; avoid for untrusted input).

### Readable sizes
- `implicitWidth` / `implicitHeight`: the size of the laid-out text.
- `contentWidth` / `contentHeight`: the same after wrapping.
- `lineCount`, `truncated` (true when elided).

### Text properties you'll use

| Property | Meaning |
|---|---|
| `text`, `color` | Content and color |
| `font.*` | `family pixelSize pointSize weight bold italic letterSpacing wordSpacing capitalization hintingPreference variableAxes features` |
| `elide`, `wrapMode`, `maximumLineCount`, `lineHeight` | Fitting |
| `horizontalAlignment`, `verticalAlignment` | Placement in the box |
| `textFormat`, `onLinkActivated`, `linkColor` | Rich text |
| `style`, `styleColor` | `Text.Outline`, `Text.Raised`, `Text.Sunken` for cheap outlines |
| `renderType` | `Text.QtRendering` (default) or `Text.NativeRendering` (hinted, crisp at small sizes) |
| `fontSizeMode`, `minimumPixelSize` | Auto-shrink to fit (`Text.Fit`, `HorizontalFit`) |
| `padding`, `leftPadding`… | Space around the text |

> [!TIP] Crisp small text
> Bar text at 11–13 px can look blurry with default rendering. Try `renderType: Text.NativeRendering`, or enable it globally with the `//@ pragma NativeTextRendering` pragma ([[ch:29-shell-structure]]).

## Image

```qml
Image {
    width: 64; height: 64
    source: "file:///home/me/Pictures/cover.png"
    fillMode: Image.PreserveAspectCrop    // fill the box, crop the overflow
    sourceSize: Qt.size(128, 128)         // DECODE at this size (saves memory)
    asynchronous: true                    // load on a background thread
    smooth: true                          // smooth scaling
    mipmap: true                          // better quality when shrinking a lot
    cache: true                           // reuse decoded images (false for changing files)
}
```

### fillMode

| Value | Result |
|---|---|
| `Image.Stretch` (default) | Stretch to the box, distorting |
| `Image.PreserveAspectFit` | Fit entirely inside, letterboxed |
| `Image.PreserveAspectCrop` | Fill the box, crop overflow (**wallpapers, album art**) |
| `Image.Tile` | Repeat |
| `Image.Pad` | Original size, no scaling |

### sourceSize: the most important performance setting

A 4K wallpaper decoded at full size takes about **33 MB** of memory. If you only show it as a 260×146 thumbnail, set `sourceSize: Qt.size(520, 292)` (2× for HiDPI) and it takes about 0.6 MB. Always set `sourceSize` for thumbnails, album art and avatars.

### Status and loading

```qml
Image {
    id: art
    source: player?.trackArtUrl ?? ""
    onStatusChanged: if (status === Image.Error) console.warn("failed to load", source)
}
Rectangle { visible: art.status !== Image.Ready; color: "#313244" }  // placeholder
```

`status`: `Image.Null`, `Image.Loading`, `Image.Ready`, `Image.Error`. `progress` is 0–1 while loading.

### Reloading an image whose file changed
Images are cached by URL. If a file at the same path changes (a symlinked wallpaper, a regenerated thumbnail), add a changing query string and disable the cache:

```qml
Image { cache: false; source: "file:///tmp/cover.png?" + version }   // bump `version` to reload
```

### Image sources
- Files: `file:///absolute/path.png`
- Relative to the QML file: `"assets/logo.svg"`
- Icon theme: `"image://icon/firefox"` or [[Quickshell.iconPath()]]
- HTTP(S): `"https://…"` (Qt downloads it; MPRIS art URLs are often like this)
- Data URLs: `"data:image/png;base64,…"`

For icons, prefer Quickshell's [[IconImage]], which keeps them square, crisp and correctly sized.

### AnimatedImage
For GIFs and animated WebP:

```qml
AnimatedImage { source: "file:///home/me/Pictures/cat.gif"; playing: visible; speed: 1.0 }
```

### SVG images
SVGs need `qt6-svg`. Set `sourceSize` to the display size (times the device pixel ratio) so they rasterize sharply:

```qml
Image { source: "icons/logo.svg"; sourceSize: Qt.size(width * 2, height * 2) }
```

## Putting it together: a media card

```qml file="MediaCard.qml"
import QtQuick
import Quickshell.Widgets

Rectangle {
    id: root
    property string title: "Song title that is quite long"
    property string artist: "Artist name"
    property url art: ""

    implicitWidth: 320; implicitHeight: 84
    radius: 18
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: "#313244" }
        GradientStop { position: 1; color: "#1e1e2e" }
    }
    border.color: "#45475a"

    ClippingRectangle {                       // rounded clip for the image
        id: cover
        x: 10; anchors.verticalCenter: parent.verticalCenter
        width: 64; height: 64; radius: 12
        color: "#45475a"
        Image {
            anchors.fill: parent
            source: root.art
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(128, 128)
            asynchronous: true
        }
    }
    Column {
        anchors { left: cover.right; leftMargin: 12; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 2
        Text { width: parent.width; text: root.title; color: "#cdd6f4"; font.pixelSize: 15; font.weight: Font.DemiBold; elide: Text.ElideRight }
        Text { width: parent.width; text: root.artist; color: "#a6adc8"; font.pixelSize: 13; elide: Text.ElideRight }
    }
}
```

## Practice

::: exercise warm | Outline badge
Make a pill-shaped badge with only an outline.
--- solution
```qml
Rectangle { width: 70; height: 24; radius: 12; color: "transparent"; border.width: 1.5; border.color: "#cba6f7"
    Text { anchors.centerIn: parent; text: "beta"; color: "#cba6f7" } }
```
:::

::: exercise practice | Two lines max
Make a `Text` that shows at most two lines of a long string and ends with "…".
--- solution
```qml
Text { width: 220; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
       text: "A very long notification body that keeps going and going far beyond two lines of text." }
```
:::

::: exercise practice | Wallpaper thumbnail
Show your wallpaper as a 300×170 rounded thumbnail with `PreserveAspectCrop` and a proper `sourceSize`.
--- hint
`Image` itself can't round its corners: wrap it in a `ClippingRectangle` from `Quickshell.Widgets`.
--- solution
```qml
ClippingRectangle {
    width: 300; height: 170; radius: 14
    Image { anchors.fill: parent; source: "file:///home/you/Pictures/wall.jpg"
            fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(600, 340); asynchronous: true }
}
```
:::

::: exercise challenge | Gradient card
Make a 260×120 card with a diagonal two-color gradient and white text, using `gradient` with `orientation: Gradient.Horizontal`, then rotate the look with a second stop color.
--- solution
```qml
Rectangle {
    width: 260; height: 120; radius: 18
    gradient: Gradient { orientation: Gradient.Horizontal
        GradientStop { position: 0; color: "#cba6f7" } GradientStop { position: 1; color: "#89b4fa" } }
    Text { anchors.centerIn: parent; text: "Now Playing"; color: "white"; font.pixelSize: 20; font.bold: true }
}
```
:::
