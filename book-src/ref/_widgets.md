=== IconImage
@@@ intro
An image specialized for **icons**: always square, sized by one value (`implicitSize`), and scaled crisply. Use it for app icons, tray icons and notification icons. It accepts any image source, usually from [[Quickshell.iconPath()]].

@@@ example Example: every property
```qml
import Quickshell
import Quickshell.Widgets
import QtQuick

Row {
    spacing: 8
    IconImage {
        id: icon
        implicitSize: 32                                     // width = height = 32 unless overridden
        source: Quickshell.iconPath("firefox", "application-x-executable")
        asynchronous: true                                   // Image properties are available too
        onStatusChanged: if (status === Image.Error) console.warn("icon failed")
    }
    Text { text: "actual: " + icon.actualSize + "px · status " + icon.status }
}
```

@@@ member actualSize
The size the icon is really drawn at (the smaller of width and height).

=== ClippingRectangle
@@@ intro
A rectangle that **clips its children to its rounded corners**. That's the easy way to get rounded album art, avatars and thumbnails (plain `clip: true` ignores `radius`).

@@@ example Example: every property
```qml
import Quickshell.Widgets
import QtQuick

ClippingRectangle {
    width: 160; height: 160
    radius: 32                         // children are clipped to this shape
    color: "#313244"                   // background behind children
    border.width: 4
    border.color: "#cba6f7"
    contentUnderBorder: false          // true: content extends under a (translucent) border
    contentInsideBorder: true          // true: content is resized to fit inside the border

    Image {
        anchors.fill: parent           // fills contentItem (inside the border)
        source: "file:///home/me/.face"
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(320, 320)
    }
}
```

=== ClippingWrapperRectangle
@@@ intro
A [[ClippingRectangle]] that also **sizes itself around one child** plus margins (like [[WrapperRectangle]]). Great for "a rounded frame around this image/widget" without computing sizes.

@@@ example Example
```qml
import Quickshell.Widgets
import QtQuick

ClippingWrapperRectangle {
    radius: 18
    margin: 0                          // from the wrapper manager: padding around the child
    color: "#313244"
    Image { source: "file:///home/me/Pictures/cover.png"; sourceSize: Qt.size(128, 128) }   // the child
}
```

=== WrapperItem
@@@ intro
An `Item` that sizes itself to **exactly one visual child plus margins**, and keeps the child positioned inside. It saves you from writing `implicitWidth: child.implicitWidth + 2*m` by hand. Margin properties come from its [[MarginWrapperManager]].

@@@ example Example
```qml
import Quickshell.Widgets
import QtQuick

WrapperItem {
    margin: 10                 // all sides
    leftMargin: 16             // override one side
    // child: label            // optional: pick the child explicitly
    Text { id: label; text: "padded" }
}
```

=== WrapperRectangle
@@@ intro
A `Rectangle` that sizes itself to one child plus margins: the quickest way to make a padded chip or card.

@@@ example Example: every property
```qml
import Quickshell.Widgets
import QtQuick

WrapperRectangle {
    radius: 14
    color: "#313244"
    border.width: 2
    border.color: "#cba6f7"
    margin: 8                        // padding on all sides
    topMargin: 4; bottomMargin: 4    // per-side overrides
    extraMargin: 2                   // added on top of the margins
    contentInsideBorder: true        // add border width to the margins (default)
    child: chipText                  // optional explicit child
    Text { id: chipText; text: "Chip"; color: "white" }
}
```

=== WrapperMouseArea
@@@ intro
A `MouseArea` that sizes itself around one child plus margins: a clickable, padded area in one element.

@@@ example Example
```qml
import Quickshell.Widgets
import QtQuick

WrapperMouseArea {
    margin: 6
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: console.log("clicked")
    Text { text: "click me"; color: parent.containsMouse ? "#cba6f7" : "white" }
}
```

=== WrapperManager
@@@ intro
The helper behind the Wrapper types: it picks the wrapper's single visual child (`child`) and tracks the `wrapper`. You normally use [[MarginWrapperManager]] or the ready-made `Wrapper*` types instead.

@@@ example Example: making your own wrapper type
```qml file="MyWrapper.qml"
import Quickshell.Widgets
import QtQuick

Rectangle {
    color: "#313244"; radius: 10
    WrapperManager { id: wm }               // wrapper defaults to this parent
    // wm.child is the single visual child written inside MyWrapper { … }
}
```

=== MarginWrapperManager
@@@ intro
Adds margins and automatic sizing to a wrapper: the wrapper's implicit size becomes the child's implicit size plus margins, and the child is placed inside. All `Wrapper*` types use it, so these properties appear on them.

@@@ example Example: every property
```qml
import Quickshell.Widgets
import QtQuick

Rectangle {
    color: "#313244"; radius: 12
    MarginWrapperManager {
        margin: 10                    // default for all sides
        topMargin: 6                  // per-side (falls back to margin)
        bottomMargin: 6
        leftMargin: 14
        rightMargin: 14
        extraMargin: 0                // added to all sides
        resizeChild: true             // stretch child if the wrapper is made bigger
        // implicitWidth / implicitHeight: override the computed size
    }
    Text { text: "auto-sized"; color: "white" }
}
```
