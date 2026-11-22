-- ~/.config/hypr/look.lua: the look of Hyprland itself (Lua config).
-- Load it from hyprland.lua with:  require("look")

-- ── Environment: one cursor and one Qt theme for every app ────────────────
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

hl.config({
    general = {
        gaps_in = 5,                 -- between windows
        gaps_out = 12,               -- between windows and the screen edge
        border_size = 2,
        col = {
            -- a gradient border on the focused window, a quiet one elsewhere
            active_border = "rgba(7aa2f7ff) rgba(bb9af7ff) 45deg",
            inactive_border = "rgba(414868aa)",
        },
        layout = "dwindle",
    },

    decoration = {
        rounding = 12,
        rounding_power = 4,          -- 2 = circle corners, higher = squircle
        active_opacity = 1.0,
        inactive_opacity = 0.94,     -- unfocused windows fade a little
        dim_inactive = false,

        shadow = {
            enabled = true,
            range = 18,
            render_power = 3,
            offset = "0 4",
            color = "rgba(00000066)",
        },

        blur = {
            enabled = true,
            size = 8,
            passes = 3,              -- more passes = smoother, slower
            noise = 0.02,            -- a little grain looks like frosted glass
            contrast = 1.0,
            brightness = 1.0,
            vibrancy = 0.2,
            popups = true,
        },
    },

    animations = { enabled = true },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },
})

-- ── Motion ───────────────────────────────────────────────────────────────
-- Bezier curves: four numbers, like CSS cubic-bezier. "out" curves start fast
-- and end slow; a y value above 1 overshoots and bounces back.
hl.curve("smoothOut", { type = "bezier", points = { {0.36, 0}, {0.66, -0.56} } })
hl.curve("overshot", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.1} } })
hl.curve("easeOut", { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "overshot", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "smoothOut", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "easeOut" })
hl.animation({ leaf = "border", enabled = true, speed = 8, bezier = "easeOut" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "easeOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "easeOut", style = "slidefade 15%" })
hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "easeOut", style = "fade" })

-- ── Rules ────────────────────────────────────────────────────────────────
-- small tools float and centre
for _, class in ipairs({ "pavucontrol", "nm-connection-editor", "blueman-manager", "org.gnome.Calculator" }) do
    hl.window_rule({ name = "float-" .. class, match = { class = class }, float = true, center = true, size = {720, 520} })
end
-- picture-in-picture: float, keep on all workspaces, bottom-right corner
hl.window_rule({ name = "pip", match = { title = "^(Picture-in-Picture)$" }, float = true, pin = true, size = {480, 270} })
-- the terminal is a little see-through even when focused
hl.window_rule({ name = "kitty-opacity", match = { class = "kitty" }, opacity = "0.97 0.92" })
