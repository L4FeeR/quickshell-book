-- ~/.config/nvim/init.lua: a small, riced Neovim in one file.
-- lazy.nvim installs the plugins on first start (it needs git and internet).

-- ── Options ──────────────────────────────────────────────────────────────
vim.g.mapleader = " "
local o = vim.opt
o.number = true
o.relativenumber = true
o.termguicolors = true          -- 24-bit colour, needed by every modern theme
o.cursorline = true
o.signcolumn = "yes"            -- no jumping when diagnostics appear
o.scrolloff = 8
o.tabstop = 4
o.shiftwidth = 4
o.expandtab = true
o.clipboard = "unnamedplus"     -- share the system clipboard (wl-clipboard)
o.laststatus = 3                -- one statusline for all windows
o.fillchars = { eob = " " }     -- no ~ on empty lines

-- ── lazy.nvim, the plugin manager ────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
        "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- the colour scheme, with a transparent background so kitty's blur shows
    {
        "folke/tokyonight.nvim",
        priority = 1000,
        opts = {
            style = "night",
            transparent = true,
            styles = { sidebars = "transparent", floats = "transparent" },
        },
        config = function(_, opts)
            require("tokyonight").setup(opts)
            vim.cmd.colorscheme("tokyonight")
        end,
    },

    -- statusline with rounded separators
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            options = {
                theme = "tokyonight",
                section_separators = { left = "", right = "" },
                component_separators = "",
                globalstatus = true,
            },
            sections = {
                lualine_a = { { "mode", separator = { left = "" } } },
                lualine_z = { { "location", separator = { right = "" } } },
            },
        },
    },

    -- a start screen
    {
        "goolord/alpha-nvim",
        config = function()
            local dash = require("alpha.themes.dashboard")
            dash.section.header.val = {
                "                                   ",
                "   ┏┓╻┏━╸┏━┓╻ ╻╻┏┳┓                ",
                "   ┃┗┫┣╸ ┃ ┃┃┏┛┃┃┃┃                ",
                "   ╹ ╹┗━╸┗━┛┗┛ ╹╹ ╹                ",
                "                                   ",
            }
            dash.section.buttons.val = {
                dash.button("f", "󰍉  Find file", ":Telescope find_files<CR>"),
                dash.button("r", "󰋚  Recent", ":Telescope oldfiles<CR>"),
                dash.button("c", "󰒓  Config", ":e $MYVIMRC<CR>"),
                dash.button("q", "󰩈  Quit", ":qa<CR>"),
            }
            require("alpha").setup(dash.config)
        end,
    },

    -- fuzzy finder
    { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

    -- indent guides
    { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = { indent = { char = "│" } } },
})

-- ── A few keys ───────────────────────────────────────────────────────────
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Search text" })
vim.keymap.set("n", "<leader>e", "<cmd>Explore<cr>", { desc = "File explorer" })
