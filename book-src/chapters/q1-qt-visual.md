# Qt Reference: Visual Types

The Qt Quick types you'll use most, with their important properties, methods and signals. This isn't every Qt property (Qt has thousands); it's the set that matters for shells. For the complete list, follow the link to Qt's documentation at the end of each section.

Import: `import QtQuick`

## Item

The base of all visual types. Everything below inherits these.

| Property | Type | Description |
|---|---|---|
| `x`, `y`, `z` | real | position relative to parent; stacking order among siblings |
| `width`, `height` | real | actual size |
| `implicitWidth`, `implicitHeight` | real | preferred size from content |
| `visible` | bool | shown (inherited by children; hidden items get no input and take no layout space) |
| `opacity` | real | 0–1, multiplies down the tree |
| `enabled` | bool | accepts input (inherited) |
| `clip` | bool | clip children to this item's rectangle |
| `scale`, `rotation` | real | simple transforms around `transformOrigin` |
| `transformOrigin` | enum | `Item.Center`, `Top`, `TopLeft`, `Bottom`, … |
| `transform` | list | `Scale`, `Rotation`, `Translate`, `Matrix4x4` |
| `anchors.*` | group | see [[ch:18-anchors]] |
| `parent` | Item | visual parent |
| `children`, `data`, `resources` | list | child items / all children / non-visual children |
| `childrenRect` | rect | bounding box of children (read-only) |
| `focus`, `activeFocus`, `activeFocusOnTab` | bool | keyboard focus |
| `state`, `states`, `transitions` | | state machine |
| `layer.enabled`, `layer.effect`, `layer.smooth`, `layer.samples` | | offscreen rendering and effects |
| `antialiasing`, `smooth` | bool | edge and scaling quality |
| `containmentMask` | QtObject | custom hit-test shape |
| `baselineOffset` | real | baseline position for anchors |

| Method | Description |
|---|---|
| `mapToItem(item, x, y)` / `mapFromItem(item, x, y)` | convert coordinates |
| `mapToGlobal(x, y)` / `mapFromGlobal(x, y)` | to/from screen coordinates |
| `contains(point)` | hit test |
| `childAt(x, y)` | topmost child at a point |
| `forceActiveFocus()` | take keyboard focus now |
| `nextItemInFocusChain(forward)` | tab order |
| `grabToImage(callback, size)` | render the item to an image |

Attached: `Keys`, `Layout`, `Component`, `Drag`, `KeyNavigation`, `LayoutMirroring`, `Accessible`.

## Rectangle

| Property | Type | Description |
|---|---|---|
| `color` | color | fill |
| `gradient` | Gradient | overrides `color` |
| `radius` | real | corner radius |
| `topLeftRadius`, `topRightRadius`, `bottomLeftRadius`, `bottomRightRadius` | real | per-corner radius (Qt 6.7+) |
| `border.width`, `border.color`, `border.pixelAligned` | | outline (drawn inside) |
| `antialiasing` | bool | smooth curved edges |

```qml
Rectangle { width: 120; height: 40; radius: 20; color: "#cba6f7"; border { width: 1; color: "#45475a" } }
```

### Gradient and GradientStop
`Gradient { orientation: Gradient.Vertical | Gradient.Horizontal; GradientStop { position: 0..1; color: … } }`. Presets: `gradient: Gradient.NightFade` (Qt ships ~180 named presets).

## Text

| Property | Type | Description |
|---|---|---|
| `text` | string | content |
| `color` | color | text color |
| `font.family`, `font.pixelSize`, `font.pointSize`, `font.weight`, `font.bold`, `font.italic` | | font |
| `font.letterSpacing`, `font.wordSpacing`, `font.capitalization`, `font.features`, `font.variableAxes`, `font.hintingPreference` | | advanced font |
| `horizontalAlignment` | enum | `Text.AlignLeft`, `AlignRight`, `AlignHCenter`, `AlignJustify` |
| `verticalAlignment` | enum | `Text.AlignTop`, `AlignBottom`, `AlignVCenter` |
| `elide` | enum | `Text.ElideNone`, `ElideLeft`, `ElideMiddle`, `ElideRight` |
| `wrapMode` | enum | `Text.NoWrap`, `WordWrap`, `WrapAnywhere`, `Wrap` |
| `maximumLineCount`, `lineCount` | int | |
| `lineHeight`, `lineHeightMode` | | line spacing |
| `textFormat` | enum | `Text.PlainText`, `StyledText`, `RichText`, `MarkdownText`, `AutoText` |
| `linkColor`, `hoveredLink` | | links in rich text |
| `style`, `styleColor` | | `Text.Normal`, `Outline`, `Raised`, `Sunken` |
| `renderType` | enum | `Text.QtRendering`, `Text.NativeRendering` |
| `fontSizeMode`, `minimumPixelSize`, `minimumPointSize` | | auto-shrink: `Text.FixedSize`, `HorizontalFit`, `VerticalFit`, `Fit` |
| `contentWidth`, `contentHeight`, `paintedWidth`, `truncated` | | read-only metrics |
| `padding`, `leftPadding`, `rightPadding`, `topPadding`, `bottomPadding` | real | spacing |

Signals: `linkActivated(link)`, `linkHovered(link)`.

## Image

| Property | Type | Description |
|---|---|---|
| `source` | url | file, http(s), `image://`, data URL, or `qrc:` |
| `fillMode` | enum | `Image.Stretch`, `PreserveAspectFit`, `PreserveAspectCrop`, `Tile`, `TileVertically`, `TileHorizontally`, `Pad` |
| `sourceSize` | size | decode size (memory!) |
| `asynchronous` | bool | load on a background thread |
| `cache` | bool | reuse decoded images by URL |
| `smooth`, `mipmap` | bool | scaling quality |
| `status` | enum | `Image.Null`, `Loading`, `Ready`, `Error` |
| `progress` | real | 0–1 |
| `paintedWidth`, `paintedHeight` | real | displayed image size |
| `horizontalAlignment`, `verticalAlignment` | enum | placement inside the item |
| `mirror`, `mirrorVertically` | bool | flip |
| `autoTransform` | bool | respect EXIF orientation |
| `retainWhileLoading` | bool | keep showing the old image while a new source loads (Qt 6.8+) |

### AnimatedImage
Inherits Image. Adds `playing`, `paused`, `speed`, `currentFrame`, `frameCount`.

### BorderImage
9-patch scaling of an image: `border.left/right/top/bottom`, `horizontalTileMode`, `verticalTileMode`.

## TextInput

Bare single-line input (no styling).

| Property | Description |
|---|---|
| `text`, `displayText`, `placeholderText` (Qt 6.8+ via Controls only) | content |
| `color`, `font`, `selectionColor`, `selectedTextColor` | look |
| `echoMode` | `TextInput.Normal`, `Password`, `NoEcho`, `PasswordEchoOnEdit` |
| `passwordCharacter`, `passwordMaskDelay` | password display |
| `maximumLength`, `validator`, `inputMask`, `acceptableInput` | validation (`IntValidator`, `DoubleValidator`, `RegularExpressionValidator`) |
| `readOnly`, `selectByMouse`, `cursorVisible`, `cursorPosition` | behavior |
| `horizontalAlignment`, `verticalAlignment`, `wrapMode` | layout |

Methods: `selectAll()`, `clear()`, `copy()`, `paste()`, `cut()`, `undo()`, `redo()`, `insert(pos, text)`, `remove(start, end)`. Signals: `accepted()`, `editingFinished()`, `textEdited()`.

### TextEdit
Multi-line editable text. Similar properties plus `textFormat`, `wrapMode`, `lineCount`, `cursorRectangle`.

## Canvas

See [[ch:26-shapes-canvas]]. Properties: `renderTarget` (`Canvas.Image`, `Canvas.FramebufferObject`), `renderStrategy` (`Immediate`, `Threaded`, `Cooperative`), `contextType`, `available`, `canvasSize`. Methods: `getContext("2d")`, `requestPaint()`, `markDirty(rect)`, `loadImage(url)`, `toDataURL()`. Signals: `paint(region)`, `painted()`, `imageLoaded()`.

## Other visual types

| Type | Use |
|---|---|
| `ShaderEffect` | custom GLSL fragment/vertex shaders (`fragmentShader: "file.frag.qsb"`) |
| `ShaderEffectSource` | render an item into a texture for shaders (`sourceItem`, `live`, `hideSource`) |
| `ParticleSystem` (QtQuick.Particles) | snow, sparks, confetti |
| `Video`, `MediaPlayer`, `VideoOutput` (QtMultimedia) | video wallpapers |
| `WebEngineView` (QtWebEngine) | embed web pages (heavy) |

Full docs: doc.qt.io/qt-6/qtquick-qmlmodule.html
