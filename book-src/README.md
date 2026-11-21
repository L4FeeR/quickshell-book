# The Quickshell Book: sources

The built book is in `../quickshell-book/`. Open `../quickshell-book/index.html` in a browser; no server is needed.

## Layout

- `manifest.py`: parts and chapter order
- `chapters/*.md`: tutorial chapters (Markdown plus `[[Type.member]]`, `[[ch:slug]]` and `[[g:term]]` links, and `> [!TIP]` callouts)
- `ref/_*.md`: hand-written notes and examples per API type (`=== TypeName`, then `@@@ intro`, `@@@ example Title`, `@@@ member name`, `@@@ notes`, `@@@ see`)
- `api.json`: the API extracted from the Quickshell source by `extract.py`
- `glossary.md`, `cover.md`, `cheatsheet.md`
- `assets/`: CSS and JS (works offline)

## Rebuild

```bash
python3 build.py                 # needs python-markdown
```

## Update the API for a new Quickshell version

```bash
git clone --depth 1 https://github.com/quickshell-mirror/quickshell.git /tmp/claude-1000/qsrc/upstream
python3 extract.py api.json      # edit ROOTS at the top of extract.py if the paths differ
python3 build.py
```
