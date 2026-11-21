# Qt Reference: Controls

Import: `import QtQuick.Controls`. Use `//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic` for easy restyling ([[ch:22-controls]]).

## Control (base of all controls)

| Property | Description |
|---|---|
| `background`, `contentItem` | replaceable visuals |
| `padding`, `leftPadding`, `rightPadding`, `topPadding`, `bottomPadding`, `horizontalPadding`, `verticalPadding` | inner space |
| `inset`, `leftInset`, … | background inset |
| `availableWidth`, `availableHeight` | size minus padding (read-only) |
| `font`, `palette`, `locale` | |
| `hovered`, `hoverEnabled`, `focusPolicy`, `focusReason`, `visualFocus` | interaction |
| `implicitContentWidth`, `implicitBackgroundWidth`, … | sizing helpers |

## Buttons (AbstractButton)

| Property / signal | Description |
|---|---|
| `text`, `icon.name`, `icon.source`, `icon.color`, `icon.width`, `display` | content |
| `checkable`, `checked`, `autoExclusive`, `autoRepeat` | toggling |
| `down`, `pressed` | read-only |
| `indicator` | for CheckBox/Switch/RadioButton |
| signals | `clicked()`, `pressed()`, `released()`, `toggled()`, `pressAndHold()`, `doubleClicked()`, `canceled()` |
| methods | `toggle()`, `click()`, `animateClick()` |

Types: `Button` (`flat`, `highlighted`), `RoundButton` (`radius`), `ToolButton`, `CheckBox` (`checkState`, `tristate`), `RadioButton`, `Switch` (`position`, `visualPosition`), `DelayButton` (`delay`, `progress`, `activated()`), `TabButton`, `MenuItem`, `ItemDelegate`, `SwitchDelegate`, `CheckDelegate`.

`ButtonGroup { buttons: [...]; exclusive: true; checkedButton }` groups buttons.

## Value controls

| Control | Key members |
|---|---|
| `Slider` | `from`, `to`, `value`, `stepSize`, `snapMode`, `orientation`, `live`, `position`, `visualPosition`, `pressed`, `handle`, `touchDragThreshold`, `moved()`, `increase()`, `decrease()`, `valueAt(pos)` |
| `RangeSlider` | `first.value`, `second.value`, `first.handle`, `second.handle`, `setValues(a, b)` |
| `Dial` | `value`, `from`, `to`, `inputMode`, `wrap`, `angle`, `startAngle`, `endAngle` |
| `SpinBox` | `value`, `from`, `to`, `stepSize`, `editable`, `textFromValue`, `valueFromText`, `up.indicator`, `down.indicator`, `valueModified()` |
| `ProgressBar` | `value`, `from`, `to`, `indeterminate`, `position`, `visualPosition` |
| `BusyIndicator` | `running` |
| `Tumbler` | `model`, `currentIndex`, `visibleItemCount`, `wrap` |

## Text controls

| Control | Key members |
|---|---|
| `TextField` | everything from TextInput + `placeholderText`, `placeholderTextColor`, `background`, `hovered` |
| `TextArea` | multi-line, `placeholderText`, `wrapMode`; wrap in `ScrollView` |
| `ComboBox` | `model`, `textRole`, `valueRole`, `currentIndex`, `currentText`, `currentValue`, `editable`, `displayText`, `popup`, `delegate`, `indicator`, `activated(index)`, `accepted()`, `find(text)`, `indexOfValue(v)` |
| `Label` | `Text` with Controls styling and `background` |

## Containers and navigation

| Control | Key members |
|---|---|
| `ScrollView` | `contentWidth`, `contentHeight`, `ScrollBar.vertical.policy` (`ScrollBar.AsNeeded`, `AlwaysOn`, `AlwaysOff`) |
| `ScrollBar` | `policy`, `size`, `position`, `active`, `interactive`, `orientation`, `minimumSize`; attach with `ScrollBar.vertical: ScrollBar {}` |
| `ScrollIndicator` | passive scroll indicator |
| `Frame`, `GroupBox`, `Pane` | grouping containers (`title` for GroupBox) |
| `TabBar` + `TabButton` | `currentIndex`, `count`, `position` |
| `StackView` | `initialItem`, `depth`, `currentItem`, `busy`, `push(item, props, op)`, `pop()`, `replace()`, `clear()`, `pushEnter/pushExit/popEnter/popExit` transitions |
| `SwipeView` | `currentIndex`, `interactive`, `orientation`; with `PageIndicator { count; currentIndex }` |
| `Page` | `header`, `footer`, `title` |
| `ToolBar`, `MenuBar`, `DialogButtonBox` | |
| `SplitView` | resizable panes (`SplitView.preferredWidth`) |

## Popups (inside a window)

> [!WARN] Clipped to the window
> Controls popups live inside their window. In a thin bar, use Quickshell's [[PopupWindow]] instead.

| Control | Key members |
|---|---|
| `Popup` | `open()`, `close()`, `visible`, `modal`, `dim`, `closePolicy` (`Popup.CloseOnEscape`, `CloseOnPressOutside`…), `x`, `y`, `margins`, `enter`, `exit` transitions, `opened()`, `closed()` |
| `Menu` | `MenuItem`, `MenuSeparator`, `Menu` (submenus), `popup()`, `addItem()` |
| `Dialog` | `title`, `standardButtons`, `accepted()`, `rejected()` |
| `Drawer` | `edge`, `position`, `interactive` |
| `ToolTip` | attached: `ToolTip.visible`, `ToolTip.text`, `ToolTip.delay`, `ToolTip.timeout`; or `ToolTip.show(text, ms)` |
