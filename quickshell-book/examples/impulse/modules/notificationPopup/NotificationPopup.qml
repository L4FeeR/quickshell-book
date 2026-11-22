import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Popups in the top-right corner, sliding in from the right.
PanelWindow {
    anchors { top: true; right: true }
    margins.top: Appearance.sizes.barHeight
    implicitWidth: Appearance.sizes.notificationPopupWidth + 20
    implicitHeight: Math.max(1, list.contentHeight + 20)
    visible: Notifications.popupList.length > 0 && !GlobalStates.sidebarRightOpen && !GlobalStates.screenLocked
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region { item: list.contentItem }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notificationPopup"

    ListView {
        id: list
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8
        interactive: false
        model: Notifications.popupList

        delegate: NotificationItem {
            required property var modelData
            wrapper: modelData
            width: ListView.view.width
        }
        add: Transition {
            NumberAnimation { property: "x"; from: 420; to: 0; duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.emphasizedDecel }
        }
        remove: Transition {
            NumberAnimation { property: "x"; to: 420; duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.emphasizedAccel }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial }
        }
    }
}
