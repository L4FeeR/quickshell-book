-- Hyprland (Lua config) setup for the lyne rebuild.
-- In ~/.config/hypr/hyprland.lua add:   require("lyne")
-- after copying this file to ~/.config/hypr/lyne.lua.

local mainMod = "SUPER"

-- Start the shell, and the clipboard history it reads
hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c lyne")
    hl.exec_cmd("wl-paste --watch cliphist store")
end)

-- ── Keybinds: each one triggers a GlobalShortcut in shell.qml ──────────────
local function shell(name)
    return hl.dsp.global("quickshell:" .. name)
end

-- Tapping Super alone opens the launcher. A bind on a lone modifier runs on
-- release, and only when no other key was pressed meanwhile, so Super + 1
-- still goes to workspace 1. Inside a release bind Hyprland sends a global
-- shortcut as "released" only, and the shell acts on "pressed", so the
-- shortcut is dispatched a moment later, outside the bind (as lyne does).
hl.bind(mainMod .. " + SUPER_L", function()
    LYNE_TAP = hl.timer(function() hl.dispatch(shell("app_launcher")) end, { timeout = 1, type = "oneshot" })
end, { release = true })
hl.bind(mainMod .. " + V",       shell("clipboard_history"))
hl.bind("Print",                 shell("take_screenshot"))
hl.bind(mainMod .. " + End",     shell("power_menu"))
hl.bind(mainMod .. " + Escape",  shell("lock_screen"))
hl.bind(mainMod .. " + B",       shell("wallpaper_picker"))
hl.bind(mainMod .. " + I",       shell("settings"))
hl.bind(mainMod .. " + A",       shell("dashboard"))
hl.bind(mainMod .. " + N",       shell("notifications"))

-- Media keys: repeat while held, and work on the lock screen too
local held = { repeating = true, locked = true }
hl.bind("XF86AudioRaiseVolume",  shell("volume_up"), held)
hl.bind("XF86AudioLowerVolume",  shell("volume_down"), held)
hl.bind("XF86AudioMute",         shell("volume_mute"), { locked = true })
hl.bind("XF86AudioMicMute",      shell("mic_mute"), { locked = true })
hl.bind("XF86MonBrightnessUp",   shell("brightness_up"), held)
hl.bind("XF86MonBrightnessDown", shell("brightness_down"), held)

-- ── Blur behind the shell's surfaces ───────────────────────────────────────
-- ignore_alpha: fully transparent parts (around the rounded panels) aren't
-- blurred. xray: the bar and attached panels blur only the wallpaper, so
-- they keep one tint whatever window is behind them.
for _, ns in ipairs({ "lyne_bar", "lyne_attached", "lyne_osd" }) do
    hl.layer_rule({ name = ns, match = { namespace = ns }, blur = true, ignore_alpha = 0.45, xray = true, no_anim = true })
end
for _, ns in ipairs({ "lyne_notifications", "lyne_launcher", "lyne_wallpapers", "lyne_power" }) do
    hl.layer_rule({ name = ns, match = { namespace = ns }, blur = true, ignore_alpha = 0.45, no_anim = true })
end

-- The settings app is a normal window: float it and centre it
hl.window_rule({ name = "lyne-settings", match = { title = "^lyne settings$" }, float = true, center = true })
