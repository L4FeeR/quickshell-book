import QtQuick
import qs.config
import qs.components
import qs.modules.bar

// Opens drawers when the pointer touches a frame edge, like Caelestia: top edge = dashboard,
// right edge = OSD, top-right corner = sidebar, bottom-right corner = utilities,
// left edge = bar popouts. It only reacts when you ENTER or LEAVE a zone, so a drawer opened
// by a keybind stays open until you move into its zone and out again.
MouseArea {
    id: root

    required property ScreenState screenState
    required property Panels panels
    required property BarWrapper bar

    property bool inDashboard: false
    property bool inOsd: false
    property bool inSidebar: false
    property bool inUtilities: false

    readonly property real t: Config.border.thickness
    readonly property real r: Config.border.rounding

    // x/y in window coordinates; panels sit at (bar width, thickness)
    function withinX(p: Item, x: real): bool {
        const px = bar.implicitWidth + p.x;
        return x >= px - r && x <= px + p.width + r;
    }
    function withinY(p: Item, y: real): bool {
        const py = t + p.y;
        return y >= py - r && y <= py + p.height + r;
    }

    function update(x: real, y: real): void {
        // bar popouts: hovering a bar item opens its popout; leaving bar and popout closes it
        if (x < bar.implicitWidth)
            bar.checkPopout(y);
        else if (!(x < bar.implicitWidth + panels.popouts.width && withinY(panels.popouts, y)))
            panels.popouts.hasCurrent = false;

        // show a hidden bar while the pointer is at the left edge
        bar.hovered = x < Math.max(bar.implicitWidth, t);

        const dash = Config.dashboard.showOnHover && y < t + panels.dashboard.height && withinX(panels.dashboard, x);
        if (dash !== inDashboard) { inDashboard = dash; screenState.dashboard = dash; }

        const osd = x > width - t - panels.osd.width - panels.session.width && withinY(panels.osd, y) && !screenState.session;
        if (osd !== inOsd) { inOsd = osd; screenState.osd = osd; }

        const side = Config.sidebar.showOnHover && x > width - t - Math.max(r, panels.sidebar.width)
                     && y < t + Math.max(r * 2, panels.sidebar.height);
        if (side !== inSidebar) { inSidebar = side; screenState.sidebar = side; }

        const utils = y > height - t - Math.max(r, panels.utilities.height) && x > width - t - panels.utilities.width - r;
        if (utils !== inUtilities) { inUtilities = utils; screenState.utilities = utils; }
    }

    hoverEnabled: true
    acceptedButtons: Qt.NoButton
    onPositionChanged: event => update(event.x, event.y)
    onExited: update(width / 2, height / 2)      // pointer left the frame: close hover drawers
}
