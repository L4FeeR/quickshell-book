pragma Singleton
import QtQuick
import Quickshell
import qs.services
import qs.config

// The commands of the launcher's ">" mode. Each one is a name, an icon,
// some search words and a function to run.
Singleton {
    readonly property var items: [
        { name: "Lock screen",     icon: Icons.lock,       keywords: "lock",                run: () => LockService.lock() },
        { name: "Power menu",      icon: Icons.power,      keywords: "shutdown reboot off", run: () => PowerService.open() },
        { name: "Settings",        icon: Icons.cog,        keywords: "preferences config",  run: () => SettingsService.open("") },
        { name: "Next theme",      icon: Icons.palette,    keywords: "theme colors",        run: () => ThemeService.step(1) },
        { name: "Wallpaper",       icon: Icons.wallpaper,  keywords: "background picture",  run: () => WallpaperService.togglePicker() },
        { name: "Caffeine",        icon: Icons.coffee,     keywords: "idle awake sleep",    run: () => IdleService.toggleCaffeine() },
        { name: "Do not disturb",  icon: Icons.bellOff,    keywords: "notifications dnd",   run: () => NotificationService.toggleDnd() },
        { name: "Clear notifications", icon: Icons.clearAll, keywords: "notifications",    run: () => NotificationService.clearAll() },
        { name: "Reload shell",    icon: Icons.restart,    keywords: "quickshell restart",  run: () => Quickshell.reload(true) }
    ]
}
