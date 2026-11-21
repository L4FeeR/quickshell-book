# Qt Reference: Models and Views

## Repeater

| Member | Description |
|---|---|
| `model` | number, JS array, ListModel, ObjectModel, ScriptModel, C++ model |
| `delegate` | template (default property) |
| `count` | number of items |
| `itemAt(index)` | delegate instance |
| signals | `itemAdded(index, item)`, `itemRemoved(index, item)` |

Delegate context: `index`, `modelData`, role names. Declare with `required property`.

## ListView

| Property | Description |
|---|---|
| `model`, `delegate`, `count` | |
| `orientation` | `ListView.Vertical` / `Horizontal` |
| `spacing` | gap |
| `currentIndex`, `currentItem`, `currentSection` | selection |
| `highlight`, `highlightItem`, `highlightFollowsCurrentItem` | selection visual |
| `highlightMoveDuration`, `highlightMoveVelocity`, `highlightResizeDuration` | highlight animation |
| `highlightRangeMode`, `preferredHighlightBegin`, `preferredHighlightEnd` | keep selection in view: `ListView.NoHighlightRange`, `ApplyRange`, `StrictlyEnforceRange` |
| `snapMode` | `ListView.NoSnap`, `SnapToItem`, `SnapOneItem` |
| `keyNavigationEnabled`, `keyNavigationWraps` | arrow keys |
| `header`, `footer`, `headerItem`, `footerItem`, `headerPositioning` | extra items |
| `section.property`, `section.criteria`, `section.delegate`, `section.labelPositioning` | group headers |
| `cacheBuffer` | off-screen pixels kept alive |
| `reuseItems` | recycle delegates (faster scrolling) |
| `verticalLayoutDirection` | `ListView.TopToBottom` / `BottomToTop` |
| `layoutDirection` | for horizontal lists |
| `add`, `remove`, `move`, `displaced`, `addDisplaced`, `removeDisplaced`, `moveDisplaced`, `populate` | transitions |
| inherited from Flickable | `contentY`, `interactive`, `boundsBehavior`, `atYEnd`, … |

Methods: `positionViewAtIndex(index, mode)` (`ListView.Beginning`, `Center`, `End`, `Visible`, `Contain`, `SnapPosition`), `positionViewAtBeginning()`, `positionViewAtEnd()`, `incrementCurrentIndex()`, `decrementCurrentIndex()`, `indexAt(x, y)`, `itemAt(x, y)`, `itemAtIndex(index)`, `forceLayout()`.

Attached in delegates: `ListView.view`, `ListView.isCurrentItem`, `ListView.previousSection`, `ListView.nextSection`, `ListView.section`, signals `ListView.onAdd`, `ListView.onRemove`, `ListView.onPooled`, `ListView.onReused`.

## GridView

Like ListView in a grid: `cellWidth`, `cellHeight`, `flow` (`GridView.FlowLeftToRight`, `FlowTopToBottom`), `snapMode`, highlight, transitions, `positionViewAtIndex`, `moveCurrentIndexUp/Down/Left/Right()`.

## PathView

Items along a path (carousels, coverflow): `path`, `pathItemCount`, `preferredHighlightBegin/End`, `currentIndex`, `offset`, `incrementCurrentIndex()`.

## ListModel / ListElement

| Member | Description |
|---|---|
| `count` | number of items |
| `dynamicRoles` | allow roles of varying types |
| `append(obj)`, `insert(i, obj)`, `remove(i, n)`, `move(from, to, n)`, `clear()` | edit |
| `get(i)` | read an item (object) |
| `set(i, obj)`, `setProperty(i, role, value)` | update |
| `sync()` | for WorkerScript |

## ObjectModel (QtQml.Models)

A model whose items are visual items themselves: `ObjectModel { Rectangle {} Text {} }` used as a `ListView` model. (Not to be confused with Quickshell's [[ObjectModel]].)

## DelegateModel, DelegateModelGroup

Advanced filtering/sorting of delegates within a view: `model`, `delegate`, `groups`, `filterOnGroup`, `items.insert`, `persistedItems`.

## Instantiator

Creates objects (not necessarily visual) from a model: `model`, `delegate`, `active`, `asynchronous`, `objectAt(i)`, signals `objectAdded`, `objectRemoved`. Quickshell's [[Variants]] fills a similar role for reloadable objects.

## WorkerScript

Runs JS on another thread: `source: "worker.mjs"`, `sendMessage(obj)`, `onMessage`. Rarely needed, but useful for very heavy filtering.
