#!/usr/bin/env python3
"""Convert a base16 colour scheme (YAML) into a theme file for the Quickshell theme switcher.

    python3 base16-to-theme.py ocean.yaml > ~/.config/theming/themes/base16-ocean.json

Thousands of base16 schemes exist (github.com/tinted-theming/schemes). base16 names its
16 colours base00..base0F and gives each a fixed job, which maps neatly onto our roles."""
import json
import re
import sys

ROLES = {
    "background": "base00", "surface": "base01", "surfaceHigh": "base02", "border": "base03",
    "text": "base05", "textMuted": "base04", "textFaint": "base03",
    "primary": "base0D", "onPrimary": "base00", "secondary": "base0E",
    "red": "base08", "orange": "base09", "yellow": "base0A", "green": "base0B",
    "cyan": "base0C", "blue": "base0D", "magenta": "base0E",
}


def parse(text):
    """Read the simple 'key: "value"' lines of a base16 YAML file (no YAML library needed)."""
    data = {}
    for line in text.splitlines():
        m = re.match(r'\s*([A-Za-z0-9_-]+)\s*:\s*"?([^"#]+?)"?\s*(#.*)?$', line)
        if m:
            data[m.group(1)] = m.group(2).strip()
    # newer schemes nest colours under "palette:"; the regex above already flattens them
    return data


def lightness(hexcolour):
    r, g, b = (int(hexcolour[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return (max(r, g, b) + min(r, g, b)) / 2


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    data = parse(open(sys.argv[1], encoding="utf-8").read())
    palette = {}
    for i in range(16):
        key = f"base0{i:X}"
        if key not in data:
            sys.exit(f"missing {key} in {sys.argv[1]}")
        palette[key] = "#" + data[key].lstrip("#").lower()
    name = data.get("scheme") or data.get("name") or "Base16 scheme"
    theme = {
        "id": "base16-" + re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-"),
        "name": name,
        "family": "Base16",
        "variant": "light" if lightness(palette["base00"][1:]) > 0.5 else "dark",
        "author": data.get("author", ""),
        "palette": palette,
        "roles": dict(ROLES),
    }
    print(json.dumps(theme, indent=2))


if __name__ == "__main__":
    main()
