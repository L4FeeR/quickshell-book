//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.bar
import qs.popups
import qs.panels
import qs.system
import qs.desktop
import qs.effects
import qs.services

// A complete desktop shell built only from gallery pieces.
// Run it with:  qs -p ~/.config/quickshell/galleryshell   (or -c galleryshell)
ShellRoot {
    // ── background ───────────────────────────────────────────
    Wallpaper { id: wallpaper }
    WallpaperPicker { target: wallpaper }
    ScreenCorners {}

    // ── the bar, one per screen ──────────────────────────────
    Variants {
        model: Quickshell.screens
        Bar {
            notifCenter: notifCenter
            quickSettings: quickSettings
            powerMenu: powerMenu
            launcher: launcher
        }
    }

    // ── notifications ────────────────────────────────────────
    NotificationPopups {}
    NotificationCenter { id: notifCenter }

    // ── panels and pickers ───────────────────────────────────
    Launcher { id: launcher }
    AppGrid {}
    QuickSettings {
        id: quickSettings
        // keep the quick-settings toggles and the shared services in sync, both ways
        onDndChanged: Notifs.dnd = dnd
        onCaffeineChanged: Session.caffeine = caffeine
    }
    Connections { target: Notifs; function onDndChanged(): void { quickSettings.dnd = Notifs.dnd } }
    Connections { target: Session; function onCaffeineChanged(): void { quickSettings.caffeine = Session.caffeine } }
    PowerBubbles { id: powerMenu }
    WifiPicker {}
    Calculator {}
    EmojiPicker {}
    ClipboardHistory {}
    ScreenshotMenu {}
    RegionSelector {}
    AltTabSwitcher {}
    ConfirmDialog {}
    Cheatsheet {}

    // ── on-screen displays ───────────────────────────────────
    VerticalOsd {}
    WorkspaceOsd {}
    ChargingPopup {}
    BatteryWarning {}

    // ── desktop ──────────────────────────────────────────────
    Dock {}
    DesktopClock {}

    // ── session ──────────────────────────────────────────────
    LockScreen {}
    IdleManager {}
    PolkitAgent {}

    // ── keybinds: bind = SUPER, Space, global, quickshell:launcher (see hyprland.conf) ──
    GlobalShortcut { name: "launcher"; onPressed: launcher.open = !launcher.open }
    GlobalShortcut { name: "notifications"; onPressed: notifCenter.open = !notifCenter.open }
    GlobalShortcut { name: "quicksettings"; onPressed: quickSettings.open = !quickSettings.open }
    GlobalShortcut { name: "power"; onPressed: powerMenu.open = !powerMenu.open }
    GlobalShortcut { name: "lock"; onPressed: Session.lock() }
}
