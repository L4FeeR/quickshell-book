# Setting Up Your Editor

You can write QML in any text editor, but autocomplete and inline errors make learning much faster. QML has a language server, **qmlls**, and Quickshell can feed it everything it needs to know about Quickshell's types.

## Step 1: tell Quickshell to help qmlls

Create an **empty** file called `.qmlls.ini` next to your `shell.qml`:

```bash
touch ~/.config/quickshell/playground/.qmlls.ini
```

Now start (or restart) `qs -c playground`. Quickshell sees the file and writes the correct import paths into it. Leave it alone after that, and add it to `.gitignore` if you use git, because its contents are machine-specific.

## Step 2: install qmlls

It ships with Qt's declarative module:

```bash
sudo pacman -S qt6-declarative          # provides /usr/lib/qt6/bin/qmlls
ls /usr/lib/qt6/bin/qmlls               # some distros name it qmlls6
```

If your editor can't find it, add Qt's bin folder to your `PATH` or point the editor at the full path.

## Step 3: configure your editor

### VS Code / VSCodium
1. Install the official **Qt Qml** extension (publisher: `theqtcompany`).
2. In settings, enable its qmlls option and, if needed, set the qmlls path to `/usr/lib/qt6/bin/qmlls`.
3. Open your config **folder** (not a single file).

### Neovim
```lua file="~/.config/nvim/lua/lsp.lua"
-- with nvim-lspconfig
require("lspconfig").qmlls.setup({
  cmd = { "/usr/lib/qt6/bin/qmlls" },
})
-- Neovim 0.11+ built-in:
-- vim.lsp.config("qmlls", { cmd = { "/usr/lib/qt6/bin/qmlls" } }); vim.lsp.enable("qmlls")
```
Install the Treesitter parser `qmljs` for syntax highlighting.

### Helix
```toml file="~/.config/helix/languages.toml"
[language-server.qmlls]
command = "/usr/lib/qt6/bin/qmlls"

[[language]]
name = "qml"
language-servers = ["qmlls"]
```

### Zed, Kate, Emacs
Each supports LSP. Register `qmlls` for `*.qml` files. Kate ships with QML support enabled.

## What you get

- Autocomplete for properties: type `Rect` and get `Rectangle`; inside it, type `col` and get `color`.
- Red squiggles for unknown types and typos.
- "Go to definition" for your own components.
- Hover documentation for many types.

> [!WARN] qmlls is not the judge
> qmlls sometimes marks valid Quickshell code as an error, especially singletons, `import qs.…` paths and attached properties. If `qs` runs your config without complaint, the code is fine. The `qs` terminal output is the source of truth.

## Formatting

Qt ships `qmlformat` to auto-format QML:

```bash
/usr/lib/qt6/bin/qmlformat -i shell.qml     # -i = edit in place
```

Most editor QML extensions can run it on save. Consistent formatting makes braces easy to match, which prevents the most common beginner error.

## A comfortable layout

Put your editor and a terminal running `qs -c playground` side by side, with the bar visible on screen. Edit, save, glance. That loop, measured in seconds, is how every rice in this book was built.

> [!TRY] Check your setup
> In `shell.qml`, type `PanelW` and confirm autocomplete offers `PanelWindow`. Then type a wrong property name like `colr: "red"` and confirm both your editor and `qs` complain.
