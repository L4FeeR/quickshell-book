//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services
import qs.modules.bar
import qs.modules.notifications
import qs.modules.launcher
import qs.modules.osd
import qs.modules.lock
import qs.modules.power
import qs.modules.screenshot
import qs.modules.wallpaper
import qs.modules.settings

// The entry point. It does three things:
//   1. shows what is always there (wallpaper, bar, notification popups)
//   2. creates the rest only while it's needed (Loader / LazyLoader)
//   3. turns Hyprland global shortcuts into actions
ShellRoot {
    id: root

    // ── 1. always there ─────────────────────────────────────────────────────
    Background {}
    Bar {}
    NotificationOverlay {}

    // ── 2. only while needed ────────────────────────────────────────────────
    LazyLoader { active: LauncherService.visible; Launcher {} }
    LazyLoader { active: WallpaperService.pickerVisible; WallpaperPicker {} }
    LazyLoader { active: OsdService.mapped; OsdOverlay {} }
    LazyLoader { active: PowerService.visible; PowerOverlay {} }
    LazyLoader { active: SettingsService.visible; SettingsWindow {} }
    LazyLoader { active: LockService.surfaceActive; LockScreen {} }
    ScreenshotOverlay { id: screenshot }

    // idle: lock, then screens off (paused by caffeine and by apps that inhibit idle)
    IdleMonitor {
        timeout: IdleService.lockTimeout
        enabled: IdleService.lockTimeout > 0 && !IdleService.caffeine && !StateService.isLoading
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) IdleService.lock()
    }
    IdleMonitor {
        timeout: IdleService.dpmsTimeout
        enabled: IdleService.dpmsTimeout > 0 && !IdleService.caffeine && !StateService.isLoading
        respectInhibitors: true
        onIsIdleChanged: isIdle ? IdleService.dpmsOff() : IdleService.dpmsOn()
    }

    // ── 3. global shortcuts ─────────────────────────────────────────────────
    // Hyprland triggers them as "quickshell:<name>" (see extras/lyne.lua).
    // These are the names lyne-dots uses, so its keybinds work with this shell.
    GlobalShortcut { name: "app_launcher"; onPressed: LauncherService.toggle() }
    GlobalShortcut { name: "clipboard_history"; onPressed: LauncherService.toggleMode(";") }
    GlobalShortcut { name: "take_screenshot"; onPressed: WindowManagerService.openExclusive("Screenshot", () => screenshot.start()) }
    GlobalShortcut { name: "lock_screen"; onPressed: LockService.lock() }
    GlobalShortcut { name: "power_menu"; onPressed: PowerService.toggle() }
    GlobalShortcut { name: "wallpaper_picker"; onPressed: WallpaperService.togglePicker() }
    GlobalShortcut { name: "settings"; onPressed: SettingsService.visible ? SettingsService.close() : SettingsService.open("") }
    GlobalShortcut { name: "dashboard"; onPressed: DashboardService.toggle("", DashboardService.focusedScreen()) }
    GlobalShortcut { name: "notifications"; onPressed: NotificationService.toggleHistory(DashboardService.focusedScreen()) }

    GlobalShortcut { name: "volume_up"; onPressed: { AudioService.increaseVolume(); OsdService.show("volume"); } }
    GlobalShortcut { name: "volume_down"; onPressed: { AudioService.decreaseVolume(); OsdService.show("volume"); } }
    GlobalShortcut { name: "volume_mute"; onPressed: { AudioService.toggleMute(); OsdService.show("volume"); } }
    GlobalShortcut { name: "mic_mute"; onPressed: { AudioService.toggleSourceMute(); OsdService.show("mic"); } }
    GlobalShortcut { name: "brightness_up"; onPressed: { BrightnessService.increaseBrightness(); OsdService.show("brightness"); } }
    GlobalShortcut { name: "brightness_down"; onPressed: { BrightnessService.decreaseBrightness(); OsdService.show("brightness"); } }
}
