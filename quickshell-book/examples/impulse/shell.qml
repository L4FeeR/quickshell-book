//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import Quickshell
import QtQuick
import qs.services
import qs.modules.common
import qs.modules.bar
import qs.modules.background
import qs.modules.lock
import qs.modules.notificationPopup
import qs.modules.onScreenDisplay
import qs.modules.overview
import qs.modules.screenCorners
import qs.modules.sessionScreen
import qs.modules.sidebarLeft
import qs.modules.sidebarRight

// A rebuild of end-4's "illogical-impulse" shell, written for "The Quickshell Book".
// Run with:  qs -c impulse
ShellRoot {
    Component.onCompleted: MaterialThemeLoader.reapply()

    // Like end-4's PanelLoader: each panel only exists once the config file has loaded.
    component PanelLoader: LazyLoader {
        active: Config.ready
    }

    PanelLoader { component: Background {} }
    PanelLoader { component: Bar {} }
    PanelLoader { component: ScreenCorners {} }
    PanelLoader { component: NotificationPopup {} }
    PanelLoader { component: OnScreenDisplay {} }
    PanelLoader { component: Overview {} }
    PanelLoader { component: SidebarLeft {} }
    PanelLoader { component: SidebarRight {} }
    PanelLoader { component: SessionScreen {} }
    PanelLoader { component: Lock {} }
}
