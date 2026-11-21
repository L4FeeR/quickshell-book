# Qt Reference: Positioning and Layouts

## Anchors (on every Item)

| Property | Description |
|---|---|
| `anchors.left`, `right`, `top`, `bottom` | attach edges to another item's anchor lines |
| `anchors.horizontalCenter`, `verticalCenter`, `baseline` | attach center lines / text baseline |
| `anchors.fill` | fill an item |
| `anchors.centerIn` | center in an item |
| `anchors.margins` | default margin for all anchored edges |
| `anchors.leftMargin`, `rightMargin`, `topMargin`, `bottomMargin` | per-edge margins |
| `anchors.horizontalCenterOffset`, `verticalCenterOffset`, `baselineOffset` | offsets |
| `anchors.alignWhenCentered` | snap centered items to whole pixels |

Set an anchor to `undefined` to remove it.

## Row

| Property | Description |
|---|---|
| `spacing` | gap between children |
| `padding`, `leftPadding`, `rightPadding`, `topPadding`, `bottomPadding` | inner padding |
| `layoutDirection` | `Qt.LeftToRight` / `Qt.RightToLeft` |
| `effectiveLayoutDirection` | read-only, includes mirroring |
| `add`, `move`, `populate` | transitions |

Method: `forceLayout()`. Signal: `positioningComplete()`.

## Column

Same as Row (vertical), without `layoutDirection`.

## Grid

| Property | Description |
|---|---|
| `columns`, `rows` | grid shape |
| `rowSpacing`, `columnSpacing`, `spacing` | gaps |
| `flow` | `Grid.LeftToRight` (row by row) or `Grid.TopToBottom` |
| `horizontalItemAlignment`, `verticalItemAlignment` | `Grid.AlignLeft`/`AlignHCenter`/… |
| `layoutDirection`, padding, transitions | as Row |

## Flow

Wraps children like text. `flow: Flow.LeftToRight | Flow.TopToBottom`, `spacing`, padding, `layoutDirection`, transitions.

## Layouts (`import QtQuick.Layouts`)

### RowLayout / ColumnLayout

| Property | Description |
|---|---|
| `spacing` | gap |
| `layoutDirection` | RowLayout only |
| `uniformCellSizes` | equal cells (Qt 6.6+) |

### GridLayout

| Property | Description |
|---|---|
| `columns`, `rows` | shape |
| `rowSpacing`, `columnSpacing` | gaps |
| `flow` | `GridLayout.LeftToRight` / `TopToBottom` |
| `uniformCellWidths`, `uniformCellHeights` | equal cells (Qt 6.6+) |

### StackLayout
`currentIndex`, `count`; attached `StackLayout.index`, `StackLayout.isCurrentItem`.

### Layout attached properties (on children)

| Property | Description |
|---|---|
| `Layout.fillWidth`, `Layout.fillHeight` | take leftover space |
| `Layout.preferredWidth`, `Layout.preferredHeight` | desired size (−1 = implicit) |
| `Layout.minimumWidth/Height`, `Layout.maximumWidth/Height` | limits |
| `Layout.alignment` | `Qt.AlignLeft|AlignVCenter…` |
| `Layout.margins`, `leftMargin`, `rightMargin`, `topMargin`, `bottomMargin` | spacing |
| `Layout.row`, `column`, `rowSpan`, `columnSpan` | GridLayout placement |
| `Layout.horizontalStretchFactor`, `verticalStretchFactor` | share extra space (Qt 6.5+) |

## Flickable

Scrollable area for arbitrary content.

| Property | Description |
|---|---|
| `contentWidth`, `contentHeight` | size of the scrollable content |
| `contentX`, `contentY` | scroll position |
| `interactive` | allow drag/flick |
| `boundsBehavior` | `Flickable.StopAtBounds`, `DragOverBounds`, `OvershootBounds`, `DragAndOvershootBounds` |
| `flickableDirection` | `Flickable.AutoFlickDirection`, `HorizontalFlick`, `VerticalFlick`, `HorizontalAndVerticalFlick` |
| `maximumFlickVelocity`, `flickDeceleration` | feel |
| `atXBeginning`, `atXEnd`, `atYBeginning`, `atYEnd` | read-only edges |
| `moving`, `flicking`, `dragging` | read-only state |
| `contentItem` | the item that holds content |

Methods: `flick(xVel, yVel)`, `cancelFlick()`, `returnToBounds()`, `resizeContent(w, h, center)`.

## Positioning helpers

| Type | Use |
|---|---|
| `Item` as spacer | `Item { Layout.fillWidth: true }` |
| `Loader` | sized by its item unless sized itself |
| `Repeater` | creates children *in the parent positioner/layout* |
| `childrenRect` | quick bounding box |
