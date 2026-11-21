#!/usr/bin/env python3
"""Builds the Quickshell Book (multi-page static HTML) from:
   manifest.py, chapters/*.md, ref/*.md (hand-written notes/examples), glossary.md, api.json
   Output: ../quickshell-book/"""
import html, json, os, re, shutil, sys
import markdown
from manifest import PARTS, MODULE_ORDER

SRC = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(SRC), "quickshell-book")
API = json.load(open(os.path.join(SRC, "api.json")))
BOOK_TITLE = "The Quickshell Book"
VERSION_NOTE = "Quickshell 0.3.x (upstream) · Niri/DWL modules from the noctalia-qs fork"

# ---------------------------------------------------------------- API model
TYPES = []
for mname in MODULE_ORDER:
    m = API.get(mname)
    if not m: continue
    for t in m["types"]:
        if t["kind"] == "internal": continue
        if t["name"] in ("FileViewInternal",): continue
        TYPES.append(t)
BYNAME = {}
for t in TYPES:
    if t["name"] in BYNAME:
        t["slug"] = t["module"].split(".")[-1] + "-" + t["name"]
    else:
        t["slug"] = t["name"]
    BYNAME.setdefault(t["name"], t)
BYCNAME = {}
for t in TYPES:
    BYCNAME.setdefault(t.get("cname") or t["name"], t)
    BYCNAME.setdefault(t["name"], t)
TYPE_ALIASES = {"UntypedObjectModel": "ObjectModel", "PwNodeIface": "PwNode", "PwNodeAudioIface": "PwNodeAudio",
                "PwLinkGroupIface": "PwLinkGroup", "QuickshellScreenInfo": "ShellScreen", "PendingRegion": "Region",
                "ProxyWindowBase": "QsWindow", "WindowInterface": "QsWindow", "PanelWindowInterface": "PanelWindow"}
def norm_type(s):
    def rep(m):
        w = m.group(0)
        if w in TYPE_ALIASES: return TYPE_ALIASES[w]
        if w not in BYNAME and w in BYCNAME: return BYCNAME[w]["name"]
        return w
    s = re.sub(r'[A-Za-z_]\w*', rep, s)
    return s + ">" * (s.count("<") - s.count(">"))
for _t in TYPES:
    for _p in _t["properties"]: _p["type"] = norm_type(_p["type"])
    for _f in _t["functions"]:
        _f["ret"] = norm_type(_f["ret"])
        for _x in _f["params"]: _x["type"] = norm_type(_x["type"])
    for _s in _t["signals"]:
        for _x in _s["params"]: _x["type"] = norm_type(_x["type"])
QT_TYPES = {"QtObject": "qml-qtqml-qtobject", "Item": "qml-qtquick-item", "Rectangle": "qml-qtquick-rectangle",
            "Image": "qml-qtquick-image", "MouseArea": "qml-qtquick-mousearea", "Component": "qml-qtqml-component",
            "QtWindow": "qml-qtquick-window", "Window": "qml-qtquick-window", "Text": "qml-qtquick-text"}
ALL_MODULES = [m for m in MODULE_ORDER if m in API]

def is_enum_type(t):
    return t["kind"] == "enum-namespace" or (t["enums"] and not t["properties"] and not t["signals"]
                                            and all(f["name"] == "toString" for f in t["functions"]))

def chain(t):
    out, seen = [], set()
    b = t.get("base")
    while b and b not in seen:
        seen.add(b)
        bt = BYCNAME.get(b)
        if bt is None or bt is t:
            out.append(("qt", b)); break
        out.append(("qs", bt)); b = bt.get("base")
    return out

def notify_names(t):
    names = {p["name"] for p in t["properties"]}
    for kind, b in chain(t):
        if kind == "qs": names |= {p["name"] for p in b["properties"]}
    return names

def user_signals(t):
    names = notify_names(t)
    return [s for s in t["signals"] if not (s["name"].endswith("Changed") and (s["name"][:-7] in names or not s["doc"]))]

# reverse references: which members mention this type
USED_BY = {}
for t in TYPES:
    for p in t["properties"]:
        for w in re.findall(r'\w+', p["type"]):
            if w in BYNAME and w != t["name"]:
                USED_BY.setdefault(w, []).append((t, p["name"], "property"))
    for f in t["functions"]:
        for w in re.findall(r'\w+', f["ret"] + " " + " ".join(x["type"] for x in f["params"])):
            if w in BYNAME and w != t["name"]:
                USED_BY.setdefault(w, []).append((t, f["name"], "function"))
    for s in t["signals"]:
        for w in re.findall(r'\w+', " ".join(x["type"] for x in s["params"])):
            if w in BYNAME and w != t["name"]:
                USED_BY.setdefault(w, []).append((t, s["name"], "signal"))

# ---------------------------------------------------------------- chapters
CHAPTERS = []
for pnum, ptitle, chs in PARTS:
    for slug, title in chs:
        CHAPTERS.append({"slug": slug, "title": title, "part": pnum, "ptitle": ptitle,
                         "url": f"ch/{slug}.html", "file": os.path.join(SRC, "chapters", slug + ".md")})
CH_BY_SLUG = {c["slug"]: c for c in CHAPTERS}
for c in CHAPTERS:  # allow short slug refs like ch:bindings
    short = c["slug"].split("-", 1)[1] if "-" in c["slug"] else c["slug"]
    CH_BY_SLUG.setdefault(short, c)

GLOSSARY = []  # (term, slug, html)

def slugify(s):
    s = re.sub(r'<[^>]+>', '', s)
    s = html.unescape(s).lower()
    s = re.sub(r'[^a-z0-9]+', '-', s).strip('-')
    return s or "x"

# ---------------------------------------------------------------- markdown
def ref_url(tname, member=None):
    t = BYNAME.get(tname)
    if not t: return None
    return f"ref/{t['slug']}.html" + (f"#m-{member}" if member else "")

def member_names(t):
    names = {p["name"] for p in t["properties"]} | {f["name"] for f in t["functions"]} | {s["name"] for s in t["signals"]}
    names |= {v["name"] for e in t["enums"] for v in e["values"]}
    for kind, bt in chain(t):
        if kind == "qs":
            names |= {p["name"] for p in bt["properties"]} | {f["name"] for f in bt["functions"]} | {s["name"] for s in bt["signals"]}
    return names

def member_anchor(t, m):
    m = m.replace("()", "")
    names = member_names(t)
    if m in names:
        # signals filtered out of the page: link the property instead
        if m.endswith("Changed") and m[:-7] in {p["name"] for p in t["properties"]}:
            return m[:-7]
        return m
    if m.endswith("Changed") and m[:-7] in names: return m[:-7]
    return None

def resolve_at(token, ctx):
    """resolve @@Foo.Bar.Type.member style refs -> (url, label)"""
    token = re.sub(r'\$s?$', '', token)
    parts = [re.sub(r'\$s?$', '', p) for p in token.split(".")]
    if parts and parts[0] == "Quickshell" and len(parts) > 1 and parts[1] not in BYNAME and parts[1][:1].islower() and ".".join(parts[:2]) not in API:
        pass  # Quickshell.<member> of the singleton
    else:
        for n in range(len(parts), 0, -1):
            if ".".join(parts[:n]) in API:
                parts = parts[n:]; break
    if parts and parts[0] in ("QtQuick", "QtQml", "QtQuick.Controls"):
        parts = parts[1:]
        if parts and parts[0] == "Controls": parts = parts[1:]
        if not parts: return None, token
        qt = parts[0]
        anchor = QT_TYPES.get(qt, "qml-qtquick-" + qt.lower())
        return f"https://doc.qt.io/qt-6/{anchor}.html", ".".join(parts)
    if not parts: return None, token
    if parts[0] == "$": parts = parts[1:]
    if parts and parts[0] in BYNAME:
        t = BYNAME[parts[0]]
        if len(parts) > 1:
            a = member_anchor(t, parts[1])
            return (ref_url(parts[0], a) if a else ref_url(parts[0])), ".".join(parts)
        return ref_url(parts[0]), parts[0]
    if parts and parts[0][:1].isupper():
        if parts[0] in QT_TYPES:
            return f"https://doc.qt.io/qt-6/{QT_TYPES[parts[0]]}.html", ".".join(parts)
        return None, ".".join(parts)
    if ctx and parts:
        a = member_anchor(ctx, parts[0])
        if a: return ref_url(ctx["name"], a), parts[0]
    return None, ".".join(parts)

CALL_KINDS = {"TIP": "tip", "NOTE": "note", "INFO": "note", "WARNING": "warn", "WARN": "warn", "CAUTION": "warn",
              "DANGER": "bad", "IMPORTANT": "warn", "TRY": "try", "EXERCISE": "try", "WILD": "wild", "WHY": "why"}
CALL_TITLES = {"tip": "Tip", "note": "Note", "warn": "Watch out", "bad": "Danger", "try": "Try it yourself",
               "wild": "In the wild", "why": "Why it works"}

def esc(s): return html.escape(s, quote=False)

def render_code(lang, meta, code):
    fname = ""
    m = re.search(r'(?:file|title)="([^"]+)"', meta or "")
    if m: fname = m.group(1)
    lang = (lang or "text").strip()
    cls = {"qml": "qml", "js": "js", "javascript": "js", "bash": "sh", "sh": "sh", "ini": "ini", "conf": "ini",
           "toml": "ini", "json": "js", "kdl": "ini", "lua": "js", "text": "text", "css": "js", "python": "js", "cpp": "js", "c++": "js"}.get(lang, "text")
    f = f'<span class="fname">{esc(fname)}</span>' if fname else ""
    return f'<div class="codewrap"><pre class="code" data-lang="{cls}">{f}<code>{esc(code)}</code></pre></div>'

def md(text, rel="", ctx=None, inline=False):
    if not text: return ""
    holders = []
    def hold(h):
        holders.append(h); return f"\x00{len(holders)-1}\x00"
    # code fences (also indented ones inside lists)
    def fence(m):
        return "\n" + hold(render_code(m.group(2), m.group(3), m.group(4))) + "\n"
    text = re.sub(r'(?m)^([ \t]*)```(\w+)?([^\n]*)\n(.*?)\n\1```[ \t]*$',
                  lambda m: fence(m) if True else "", text, flags=re.S)
    # callouts
    lines = text.split("\n"); out = []; i = 0
    while i < len(lines):
        mm = re.match(r'^>\s*\[!(\w+)\]\s*(.*)$', lines[i])
        if mm and mm.group(1).upper() in CALL_KINDS:
            kind = CALL_KINDS[mm.group(1).upper()]
            title = mm.group(2).strip()
            body = []
            i += 1
            while i < len(lines) and lines[i].startswith(">"):
                body.append(re.sub(r'^>\s?', '', lines[i])); i += 1
            # source docs put text on the first line instead of a title
            if title and not body and len(title) > 60:
                body = [title]; title = ""
            elif title and body and mm.group(2).strip().endswith((".", ",")):
                body = [title] + body; title = ""
            inner = md("\n".join(body), rel, ctx)
            t = title or CALL_TITLES[kind]
            out.append(hold(f'<div class="box {kind}"><div class="bt">{md(t, rel, ctx, inline=True)}</div>{inner}</div>'))
            continue
        out.append(lines[i]); i += 1
    text = "\n".join(out)
    # inline code: protect
    text = re.sub(r'(`+)(.+?)\1', lambda m: hold("<code>" + esc(m.group(2)) + "</code>"), text)
    # wiki links
    def wl(m):
        target, label = m.group(1), m.group(2)
        if target.startswith("ch:"):
            c = CH_BY_SLUG.get(target[3:])
            if not c: print("WARN missing chapter link", target, file=sys.stderr); return label or target
            anchor = ""
            return hold(f'<a class="xref" href="{rel}{c["url"]}{anchor}">{esc(label or c["title"])}</a>')
        if target.startswith("g:"):
            return hold(f'<a class="gloss" href="{rel}glossary.html#g-{slugify(target[2:])}">{esc(label or target[2:])}</a>')
        if target.startswith("ref:"):
            target = target[4:]
        parts = target.split(".")
        t = BYNAME.get(parts[0])
        if t:
            u = ref_url(parts[0], parts[1].replace("()", "") if len(parts) > 1 else None)
            return hold(f'<a class="api" href="{rel}{u}"><code>{esc(label or target)}</code></a>')
        if parts[0] in QT_TYPES or parts[0][:1].isupper():
            q = slugify(parts[0])
            return hold(f'<a class="api qt" href="{rel}qt-index.html#{q}"><code>{esc(label or target)}</code></a>')
        print("WARN unresolved link", target, file=sys.stderr)
        return label or target
    text = re.sub(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]', wl, text)
    def at(m):
        tok = m.group(1)
        u, label = resolve_at(tok, ctx)
        if not u: return hold(f"<code>{esc(label)}</code>")
        if u.startswith("http"):
            return hold(f'<a class="api qt" href="{u}"><code>{esc(label)}</code></a>')
        return hold(f'<a class="api" href="{rel}{u}"><code>{esc(label)}</code></a>')
    text = re.sub(r'@@([\w$]+(?:\.[\w$]+)*)', at, text)
    text = re.sub(r'\]\(#(?:prop|func|signal)\.(\w+)\)', lambda m: f"](#m-{m.group(1)})", text)
    if ctx:   # upstream relative doc links
        modslug = slugify(ctx["module"])
        text = text.replace("](../)", f"]({rel}ref/mod-{modslug}.html)")
        text = text.replace("]: ../../quickshell/quickshell#prop.workingDirectory", f"]: {rel}ref/Quickshell.html#m-workingDirectory")
    h = markdown.markdown(text, extensions=["tables", "sane_lists", "attr_list", "md_in_html"])
    for _ in range(3):
        h = re.sub(r'<p>\s*\x00(\d+)\x00\s*</p>', lambda m: holders[int(m.group(1))], h)
        h = re.sub(r'\x00(\d+)\x00', lambda m: holders[int(m.group(1))], h)
    if inline:
        h = re.sub(r'^<p>(.*)</p>$', r'\1', h.strip(), flags=re.S)
    return h

def add_heading_ids(h):
    toc = []; used = set()
    def rep(m):
        lvl, attrs, inner = m.group(1), m.group(2) or "", m.group(3)
        mid = re.search(r'id="([^"]+)"', attrs)
        if mid: hid = mid.group(1)
        else:
            hid = slugify(inner); base = hid; n = 2
            while hid in used: hid = f"{base}-{n}"; n += 1
            attrs += f' id="{hid}"'
        used.add(hid)
        toc.append((int(lvl), hid, re.sub(r'<[^>]+>', '', inner)))
        return f'<h{lvl}{attrs}>{inner}<a class="hlink" href="#{hid}">#</a></h{lvl}>'
    h = re.sub(r'<h([23])([^>]*)>(.*?)</h\1>', rep, h)
    return h, toc

# ---------------------------------------------------------------- page shell
SEARCH = []
import hashlib
ASSET_V = hashlib.md5((open(os.path.join(SRC, "assets", "style.css")).read() + open(os.path.join(SRC, "assets", "book.js")).read()).encode()).hexdigest()[:8]

def sidebar(rel, active):
    o = ['<nav class="side-nav">']
    o.append(f'<a class="home{" active" if active == "index" else ""}" href="{rel}index.html">⌂ Cover &amp; Contents</a>')
    for pnum, ptitle, chs in PARTS:
        is_open = any(active == "ch:" + s for s, _ in chs)
        o.append(f'<details{" open" if is_open else ""}><summary><span class="pn">{pnum}</span>{esc(ptitle)}</summary>')
        for slug, title in chs:
            num = slug.split("-")[0]
            a = " active" if active == "ch:" + slug else ""
            o.append(f'<a class="ch{a}" href="{rel}ch/{slug}.html"><span class="num">{num}</span>{esc(title)}</a>')
        o.append('</details>')
    is_ref = active.startswith("ref:") or active.startswith("mod:") or active == "api"
    o.append(f'<details{" open" if is_ref else ""}><summary><span class="pn">API</span>Quickshell API Reference</summary>')
    o.append(f'<a class="ch{" active" if active == "api" else ""}" href="{rel}ref/index.html"><span class="num">★</span>All modules</a>')
    for mname in ALL_MODULES:
        ts = [t for t in TYPES if t["module"] == mname]
        mopen = active == "mod:" + mname or any(active == "ref:" + t["slug"] for t in ts)
        o.append(f'<details class="mod"{" open" if mopen else ""}><summary>{esc(mname)}</summary>')
        o.append(f'<a class="ty{" active" if active == "mod:" + mname else ""}" href="{rel}ref/mod-{slugify(mname)}.html">Module overview</a>')
        for t in ts:
            a = " active" if active == "ref:" + t["slug"] else ""
            badge = "S" if "singleton" in t["flags"] and not is_enum_type(t) else ("E" if is_enum_type(t) else "")
            b = f'<span class="tb tb-{badge}">{badge}</span>' if badge else ""
            o.append(f'<a class="ty{a}" href="{rel}ref/{t["slug"]}.html">{esc(t["name"])}{b}</a>')
        o.append('</details>')
    o.append('</details>')
    o.append('<div class="side-sep">Appendices</div>')
    for key, url, label in [("qt", "qt-index.html", "Qt Type Index"), ("gloss", "glossary.html", "Glossary"),
                            ("az", "az.html", "A–Z Index"), ("cheat", "cheatsheet.html", "Cheat Sheet"),
                            ("print", "print.html", "Whole Book (print / PDF)")]:
        o.append(f'<a class="ch{" active" if active == key else ""}" href="{rel}{url}">{label}</a>')
    o.append('</nav>')
    return "\n".join(o)

def page(path, title, body, active, toc=None, prev=None, nxt=None, crumbs=None, desc=""):
    rel = "../" * path.count("/")
    toc_html = ""
    if toc:
        items = "".join(f'<a class="l{l}" href="#{i}">{esc(html.unescape(t))}</a>' for l, i, t in toc)
        toc_html = f'<aside class="otp"><div class="otp-t">On this page</div>{items}</aside>'
    nav = ""
    if prev or nxt:
        p = f'<a class="pn-prev" href="{rel}{prev[0]}"><small>← Previous</small><span>{esc(prev[1])}</span></a>' if prev else "<span></span>"
        n = f'<a class="pn-next" href="{rel}{nxt[0]}"><small>Next →</small><span>{esc(nxt[1])}</span></a>' if nxt else "<span></span>"
        nav = f'<nav class="prevnext">{p}{n}</nav>'
    cr = ""
    if crumbs:
        cr = '<div class="crumbs">' + " › ".join(
            (f'<a href="{rel}{u}">{esc(l)}</a>' if u else esc(l)) for l, u in crumbs) + "</div>"
    doc = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{esc(re.sub(r'<[^>]+>', '', title))} · {BOOK_TITLE}</title>
<meta name="description" content="{html.escape(desc or title)}">
<link rel="stylesheet" href="{rel}assets/style.css?v={ASSET_V}">
<script>try{{var t=localStorage.getItem('qsb-theme');if(t)document.documentElement.dataset.theme=t;}}catch(e){{}}</script>
</head><body data-rel="{rel}">
<header class="top">
 <button class="ib" id="menuBtn" aria-label="Menu">☰</button>
 <a class="brand" href="{rel}index.html">The <b>Quickshell</b> Book</a>
 <div class="search"><input id="q" type="search" placeholder="Search types, properties, chapters…  ( / )" autocomplete="off"><div id="qres"></div></div>
 <button class="ib" id="themeBtn" title="Toggle theme">◐</button>
</header>
<div class="layout">
<aside class="side" id="side">{sidebar(rel, active)}</aside>
<main class="content">{cr}<article>{body}</article>{nav}
<footer class="foot">{BOOK_TITLE} · {VERSION_NOTE}</footer></main>
{toc_html}
</div>
<script src="{rel}assets/search-index.js"></script>
<script src="{rel}assets/book.js?v={ASSET_V}"></script>
</body></html>"""
    full = os.path.join(OUT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    open(full, "w", encoding="utf-8").write(doc)

# ---------------------------------------------------------------- reference pages
REF_TEXT = {}
for _f in sorted(os.listdir(os.path.join(SRC, "ref"))):
    _p = os.path.join(SRC, "ref", _f)
    _t = open(_p, encoding="utf-8").read()
    if _f.startswith("_"):
        for _chunk in re.split(r'(?m)^=== ', _t)[1:]:
            _name, _, _body = _chunk.partition("\n")
            REF_TEXT[_name.strip()] = _body
    elif not _f.startswith(("mod-", "index-")):
        REF_TEXT[_f[:-3]] = _t

def load_ref_notes(name):
    if name not in REF_TEXT: return {}
    secs = {}; cur = None; buf = []
    order = []
    for line in REF_TEXT[name].split("\n"):
        m = re.match(r'^@@@\s*(\w+)\s*(.*)$', line)
        if m:
            if cur: secs[cur] = "\n".join(buf).strip()
            kind, arg = m.group(1), m.group(2).strip()
            cur = kind + (":" + arg if arg else ""); buf = []
            order.append(cur)
            continue
        buf.append(line)
    if cur: secs[cur] = "\n".join(buf).strip()
    secs["__order"] = order
    return secs

def type_link(tstr, rel):
    def rep(m):
        w = m.group(0)
        if w in BYNAME: return f'<a href="{rel}ref/{BYNAME[w]["slug"]}.html">{w}</a>'
        return w
    return re.sub(r'[A-Za-z_]\w*', rep, esc(tstr))

def sig_params(params, rel):
    return ", ".join(f'{esc(p["name"])}: <span class="ty">{type_link(p["type"], rel)}</span>' for p in params)

def access_badge(p):
    if p.get("required"): return '<span class="acc req">required</span>'
    if p.get("constant"): return '<span class="acc const">constant</span>'
    if p["readonly"]: return '<span class="acc ro">read-only</span>'
    return '<span class="acc rw">read / write</span>'

def how_to_get(t, rel):
    name = t["name"]
    if is_enum_type(t):
        e = t["enums"][0] if t["enums"] else None
        ex = f"{name}.{e['values'][0]['name']}" if e and e["values"] else name
        s = f"This is an <b>enum</b> (a fixed list of named values). You never create it; you compare against or assign its values, e.g. <code>{esc(ex)}</code>."
        if any(f["name"] == "toString" for f in t["functions"]):
            s += f" Turn a value into readable text with <code>{esc(name)}.toString(value)</code>."
        return s
    if "singleton" in t["flags"]:
        return f"This is a <b>singleton</b>: exactly one exists, created by Quickshell. Use it from anywhere by its name, e.g. <code>{esc(name)}.{esc(t['properties'][0]['name']) if t['properties'] else ''}</code>. Never write <code>{esc(name)} {{ }}</code>."
    if any(f.startswith("attached:") for f in t["flags"]) and "uncreatable" in t["flags"]:
        return f"This is an <b>attached</b> type: you use it as <code>{esc(name)}.property</code> on another object."
    if "uncreatable" in t["flags"]:
        refs = USED_BY.get(name, [])
        src = ", ".join(sorted({f'<a href="{rel}ref/{o["slug"]}.html#m-{m}"><code>{o["name"]}.{m}</code></a>' for o, m, k in refs})[:12])
        r = f" ({esc(t['uncreatable_reason'])})" if t.get("uncreatable_reason") else ""
        return (f"You <b>cannot create</b> this type yourself{r}. Quickshell gives you instances"
                + (f" through: {src}." if src else "."))
    return f"You <b>create</b> this type in QML: <code>{esc(name)} {{ … }}</code>."

def import_line(t):
    return f"import {t['module']}"

def render_type(t):
    rel = "../"
    name = t["name"]
    notes = load_ref_notes(name)
    ctx = t
    body = []
    badges = []
    if is_enum_type(t): badges.append('<span class="badge b-enum">enum</span>')
    elif "singleton" in t["flags"]: badges.append('<span class="badge b-single">singleton</span>')
    elif "uncreatable" in t["flags"]: badges.append('<span class="badge b-prov">provided by Quickshell</span>')
    else: badges.append('<span class="badge b-create">creatable</span>')
    if any(f.startswith("attached") for f in t["flags"]): badges.append('<span class="badge b-att">has attached properties</span>')
    if "qml" in t["flags"]: badges.append('<span class="badge b-qml">QML widget</span>')
    if API[t["module"]].get("fork_only"): badges.append('<span class="badge b-fork">noctalia-qs fork only</span>')
    body.append(f'<div class="ref-head"><div class="mod-line"><a href="{rel}ref/mod-{slugify(t["module"])}.html">{esc(t["module"])}</a></div>'
                f'<h1>{esc(name)}</h1><div class="badges">{"".join(badges)}</div></div>')
    summary_src = t["doc"].split("\n")[0] if t["doc"] else ""
    if summary_src: body.append(f'<p class="lede">{md(summary_src, rel, ctx, inline=True)}</p>')
    # import + chain
    ch = chain(t)
    chain_html = f'<code>{esc(name)}</code>'
    for kind, b in ch:
        if kind == "qs": chain_html += f' → <a href="{rel}ref/{b["slug"]}.html"><code>{esc(b["name"])}</code></a>'
        else:
            qn = {"QObject": "QtObject", "QQuickItem": "Item"}.get(b, b)
            if qn in ("PostReloadHook", "Reloadable"): continue
            chain_html += f' → <code>{esc(qn)}</code>'
    body.append('<div class="facts">'
                f'<div><span>Import</span><div class="v"><code>{esc(import_line(t))}</code></div></div>'
                f'<div><span>Inherits</span><div class="v">{chain_html}</div></div>'
                f'<div><span>How to get one</span><div class="v">{how_to_get(t, rel)}</div></div>'
                + (f'<div><span>Default property</span><div class="v"><code>{esc(t["default_property"])}</code> — children you write inside <code>{esc(name)} {{ }}</code> go here</div></div>' if t.get("default_property") else "")
                + '</div>')
    # long description from source
    rest = "\n".join(t["doc"].split("\n")[1:]).strip() if t["doc"] else ""
    first = summary_src.strip().rstrip(".")
    if first and rest.startswith(first):
        rest = rest[len(first):].lstrip(".").strip()
    if notes.get("intro"):
        body.append('<h2 id="overview">Overview</h2>')
        body.append(md(notes["intro"], rel, ctx))
    if rest:
        body.append('<h2 id="upstream">From the upstream documentation</h2>' if notes.get("intro") else '<h2 id="overview">Overview</h2>')
        body.append(f'<div class="upstream">{md(rest, rel, ctx)}</div>')
    # examples
    for key in notes.get("__order", []):
        if key.startswith("example"):
            title = key.split(":", 1)[1] if ":" in key else "Example: using every property"
            body.append(f'<h2>{esc(title)}</h2>')
            body.append(md(notes[key], rel, ctx))
    # properties
    def prop_rows(props, owner):
        rows = []
        for p in props:
            extra = notes.get("member:" + p["name"], "") if owner is t else ""
            d = md(p["doc"], rel, owner) if p["doc"] else '<span class="muted">No upstream description.</span>'
            if extra: d += f'<div class="mnote">{md(extra, rel, owner)}</div>'
            rows.append(f'<tr id="m-{p["name"]}" class="mrow"><td class="mn"><a href="#m-{p["name"]}">{esc(p["name"])}</a></td>'
                        f'<td class="mt">{type_link(p["type"], rel)}</td><td>{access_badge(p)}</td><td class="md">{d}</td></tr>')
            SEARCH.append([f"{t['name']}.{p['name']}", f"ref/{t['slug']}.html#m-{p['name']}", "property", f"{p['type']} · {t['module']}"]) if owner is t else None
        return rows
    if t["properties"] or any(k == "qs" and b["properties"] for k, b in ch):
        body.append('<h2 id="properties">Properties</h2>')
        if t["properties"]:
            body.append('<p class="hint">Every property also emits a <code>&lt;name&gt;Changed</code> signal; handle it with <code>on&lt;Name&gt;Changed</code> (e.g. <code>on' + esc(t["properties"][0]["name"][:1].upper() + t["properties"][0]["name"][1:]) + 'Changed: …</code>).</p>')
            body.append('<div class="tablewrap"><table class="members"><thead><tr><th>Name</th><th>Type</th><th>Access</th><th>Description</th></tr></thead><tbody>'
                        + "".join(prop_rows(t["properties"], t)) + '</tbody></table></div>')
        for kind, b in ch:
            if kind == "qs" and b["properties"]:
                body.append(f'<details class="inh"><summary>Inherited from <a href="{rel}ref/{b["slug"]}.html">{esc(b["name"])}</a> ({len(b["properties"])} properties)</summary>'
                            '<div class="tablewrap"><table class="members"><tbody>' + "".join(prop_rows(b["properties"], b)) + '</tbody></table></div></details>')
    # functions
    if t["functions"]:
        body.append('<h2 id="functions">Functions</h2>')
        for f in t["functions"]:
            extra = notes.get("member:" + f["name"] + "()", "") or notes.get("member:" + f["name"], "")
            body.append(f'<div class="fn" id="m-{f["name"]}"><div class="sig"><b>{esc(f["name"])}</b>({sig_params(f["params"], rel)})'
                        f'<span class="ret">: {type_link(f["ret"], rel)}</span></div>'
                        f'<div class="md">{md(f["doc"], rel, t) if f["doc"] else "<span class=muted>No upstream description.</span>"}'
                        f'{"<div class=mnote>" + md(extra, rel, t) + "</div>" if extra else ""}</div></div>')
            SEARCH.append([f"{t['name']}.{f['name']}()", f"ref/{t['slug']}.html#m-{f['name']}", "function", t["module"]])
    sigs = user_signals(t)
    if sigs:
        body.append('<h2 id="signals">Signals</h2>')
        for s in sigs:
            handler = "on" + s["name"][:1].upper() + s["name"][1:]
            extra = notes.get("member:" + s["name"], "")
            body.append(f'<div class="fn sigl" id="m-{s["name"]}"><div class="sig"><b>{esc(s["name"])}</b>({sig_params(s["params"], rel)})'
                        f'<span class="ret">handler: <code>{esc(handler)}</code></span></div>'
                        f'<div class="md">{md(s["doc"], rel, t) if s["doc"] else "<span class=muted>No upstream description.</span>"}'
                        f'{"<div class=mnote>" + md(extra, rel, t) + "</div>" if extra else ""}</div></div>')
            SEARCH.append([f"{t['name']}.{s['name']}", f"ref/{t['slug']}.html#m-{s['name']}", "signal", t["module"]])
    if t["enums"]:
        body.append('<h2 id="enums">Enum values</h2>')
        for e in t["enums"]:
            qual = name if e["name"] in ("Enum", "Flags") or is_enum_type(t) else f"{name}"
            if e["doc"]: body.append(md(e["doc"], rel, t))
            if not is_enum_type(t): body.append(f'<p class="hint">Enum <code>{esc(e["name"])}</code> — values are written <code>{esc(name)}.Value</code>.</p>')
            rows = "".join(f'<tr id="m-{v["name"]}"><td class="mn"><code>{esc(qual)}.{esc(v["name"])}</code></td><td class="mt">{esc(v["value"])}</td>'
                           f'<td class="md">{md(v["doc"], rel, t) if v["doc"] else ""}{("<div class=mnote>" + md(notes["member:" + v["name"]], rel, t) + "</div>") if notes.get("member:" + v["name"]) else ""}</td></tr>' for v in e["values"])
            body.append(f'<div class="tablewrap"><table class="members enum"><thead><tr><th>Value</th><th>Number</th><th>Meaning</th></tr></thead><tbody>{rows}</tbody></table></div>')
            for v in e["values"]:
                SEARCH.append([f"{name}.{v['name']}", f"ref/{t['slug']}.html#m-{v['name']}", "enum value", t["module"]])
    if is_enum_type(t) and t["enums"] and not any(k.startswith("example") for k in notes.get("__order", [])):
        e = t["enums"][0]; vals = e["values"]
        users = sorted({(o["name"], m) for o, m, k in USED_BY.get(name, []) if k == "property"})
        src = f"{users[0][0]}.{users[0][1]}" if users else "someObject.someProperty"
        has_ts = any(f["name"] == "toString" for f in t["functions"])
        flags = e["name"] in ("Flag", "Flags") or name in ("Edges", "PwNodeType")
        ex = [f"import {t['module']}", "", "// compare a value"]
        if flags and len(vals) > 2:
            ex.append(f"if ({src} & {name}.{vals[1]['name']}) console.log(\"has {vals[1]['name']}\")")
            ex.append(f"// combine flags with |: {name}.{vals[1]['name']} | {name}.{vals[-1]['name']}")
        else:
            ex.append(f"if ({src} === {name}.{vals[min(1, len(vals)-1)]['name']}) console.log(\"it is {vals[min(1, len(vals)-1)]['name']}\")")
        if has_ts:
            ex += ["", "// show a value as text", f"Text {{ text: {name}.toString({src}) }}"]
        if users:
            ex += ["", f"// used by: " + ", ".join(f"{a}.{m}" for a, m in users[:4])]
        body.append('<h2 id="example">Example</h2>')
        body.append(render_code("qml", "", "\n".join(ex)))
    if notes.get("notes"):
        body.append('<h2 id="notes">Notes, tips and gotchas</h2>')
        body.append(md(notes["notes"], rel, ctx))
    used = USED_BY.get(name, [])
    if used:
        items = sorted({(o["name"], m, k, o["slug"]) for o, m, k in used})
        body.append('<h2 id="used-by">Where this type appears</h2><ul class="usedby">' + "".join(
            f'<li><a href="{rel}ref/{s}.html#m-{m}"><code>{esc(on)}.{esc(m)}</code></a> <span class="muted">({k})</span></li>' for on, m, k, s in items) + '</ul>')
    if notes.get("see"):
        body.append('<h2 id="see-also">See also</h2>' + md(notes["see"], rel, ctx))
    h, toc = add_heading_ids("\n".join(body))
    return h, toc

def build_reference():
    order = [t for t in TYPES]
    for i, t in enumerate(order):
        h, toc = render_type(t)
        prev = (f"ref/{order[i-1]['slug']}.html", order[i-1]["name"]) if i else None
        nxt = (f"ref/{order[i+1]['slug']}.html", order[i+1]["name"]) if i + 1 < len(order) else None
        page(f"ref/{t['slug']}.html", t["name"], h, "ref:" + t["slug"], toc, prev, nxt,
             [("API Reference", "ref/index.html"), (t["module"], f"ref/mod-{slugify(t['module'])}.html"), (t["name"], None)],
             desc=f"{t['name']} — {t['module']}: every property, function, signal and enum, with examples.")
        SEARCH.append([t["name"], f"ref/{t['slug']}.html", "type", t["module"]])
    # module pages
    for mname in ALL_MODULES:
        m = API[mname]
        ts = [t for t in TYPES if t["module"] == mname]
        notes_p = os.path.join(SRC, "ref", "mod-" + slugify(mname) + ".md")
        body = [f'<div class="ref-head"><div class="mod-line">Module</div><h1>{esc(mname)}</h1></div>',
                f'<p class="lede">{esc(m["description"])}</p>',
                f'<div class="facts"><div><span>Import</span><div class="v"><code>import {esc(mname)}</code></div></div>'
                f'<div><span>Types</span><div class="v">{len(ts)}</div></div></div>']
        if os.path.exists(notes_p):
            body.append(md(open(notes_p, encoding="utf-8").read(), "../"))
        if m["body"]:
            body.append('<h2>Upstream notes</h2><div class="upstream">' + md(m["body"], "../") + '</div>')
        body.append('<h2>Types in this module</h2><div class="cards">')
        for t in ts:
            kind = "enum" if is_enum_type(t) else "singleton" if "singleton" in t["flags"] else "provided" if "uncreatable" in t["flags"] else "creatable"
            s = md(t["doc"].split("\n")[0], "../", t, inline=True) if t["doc"] else ""
            body.append(f'<a class="card" href="{t["slug"]}.html"><b>{esc(t["name"])}</b><span class="k k-{kind}">{kind}</span><p>{re.sub(r"<a [^>]*>|</a>", "", s)}</p></a>')
        body.append('</div>')
        h, toc = add_heading_ids("\n".join(body))
        page(f"ref/mod-{slugify(mname)}.html", mname, h, "mod:" + mname, toc, crumbs=[("API Reference", "ref/index.html"), (mname, None)])
        SEARCH.append([mname, f"ref/mod-{slugify(mname)}.html", "module", m["description"]])
    # reference index
    body = ['<h1>Quickshell API Reference</h1>',
            f'<p class="lede">Every QML type Quickshell provides: {len(TYPES)} types, '
            f'{sum(len(t["properties"]) for t in TYPES)} properties, {sum(len(t["functions"]) for t in TYPES)} functions, '
            f'{sum(len(user_signals(t)) for t in TYPES)} signals and {sum(len(e["values"]) for t in TYPES for e in t["enums"])} enum values. '
            'Each page explains how to get the object, shows a complete example, and documents every member.</p>',
            md(open(os.path.join(SRC, "ref", "index-intro.md")).read(), "../") if os.path.exists(os.path.join(SRC, "ref", "index-intro.md")) else ""]
    for mname in ALL_MODULES:
        ts = [t for t in TYPES if t["module"] == mname]
        body.append(f'<h2><a href="mod-{slugify(mname)}.html">{esc(mname)}</a></h2><p class="muted">{esc(API[mname]["description"])}</p><div class="pills">'
                    + "".join(f'<a class="pill" href="{t["slug"]}.html">{esc(t["name"])}</a>' for t in ts) + '</div>')
    h, toc = add_heading_ids("\n".join(body))
    page("ref/index.html", "API Reference", h, "api", toc, crumbs=[("API Reference", None)])

# ---------------------------------------------------------------- chapters
def build_chapters():
    missing = []
    for i, c in enumerate(CHAPTERS):
        if os.path.exists(c["file"]):
            src = open(c["file"], encoding="utf-8").read()
        else:
            missing.append(c["slug"]); src = f"# {c['title']}\n\n> [!NOTE] This chapter is still being written."
        # first H1 is the title
        m = re.match(r'#\s+(.+)\n', src)
        title = c["title"]
        if m: src = src[m.end():]
        h = md(src, "../")
        h, toc = add_heading_ids(h)
        head = (f'<div class="ch-head"><div class="ch-part">Part {c["part"]} · {esc(c["ptitle"])}</div>'
                f'<h1><span class="ch-num">{c["slug"].split("-")[0]}</span>{esc(title)}</h1></div>')
        prev = (CHAPTERS[i-1]["url"], CHAPTERS[i-1]["title"]) if i else None
        nxt = (CHAPTERS[i+1]["url"], CHAPTERS[i+1]["title"]) if i + 1 < len(CHAPTERS) else ("ref/index.html", "API Reference")
        page(c["url"], title, head + h, "ch:" + c["slug"], toc, prev, nxt,
             [(f"Part {c['part']}: {c['ptitle']}", "index.html#part-" + slugify(c["part"])), (title, None)])
        SEARCH.append([title, c["url"], "chapter", f"Part {c['part']}"])
        for lvl, hid, txt in toc:
            SEARCH.append([html.unescape(txt), f"{c['url']}#{hid}", "section", title])
        c["toc"] = toc; c["html"] = h
    if missing: print(f"chapters missing: {len(missing)}", file=sys.stderr)

# ---------------------------------------------------------------- glossary / az / index / misc
def build_glossary():
    p = os.path.join(SRC, "glossary.md")
    if not os.path.exists(p): return
    text = open(p, encoding="utf-8").read()
    entries = re.split(r'(?m)^## ', text)[1:]
    for e in entries:
        term, _, d = e.partition("\n")
        GLOSSARY.append((term.strip(), slugify(term), md(d.strip(), "")))
    GLOSSARY.sort(key=lambda x: x[0].lower())
    letters = sorted({g[0][0].upper() for g in GLOSSARY})
    body = ['<h1>Glossary</h1><p class="lede">Every word you might stumble on while ricing, in plain language.</p>',
            '<div class="letters">' + "".join(f'<a href="#L-{l}">{l}</a>' for l in letters) + '</div>']
    cur = None
    for term, s, d in GLOSSARY:
        L = term[0].upper()
        if L != cur:
            if cur: body.append('</dl>')
            body.append(f'<h2 id="L-{L}">{L}</h2><dl class="gloss">'); cur = L
        body.append(f'<dt id="g-{s}">{esc(term)}</dt><dd>{d}</dd>')
        SEARCH.append([term, f"glossary.html#g-{s}", "glossary", re.sub(r"<[^>]+>", "", d)[:80]])
    body.append('</dl>')
    page("glossary.html", "Glossary", "\n".join(body), "gloss", crumbs=[("Glossary", None)])

def build_az():
    entries = []
    for t in TYPES:
        entries.append((t["name"], f"ref/{t['slug']}.html", "type · " + t["module"]))
        for p in t["properties"]: entries.append((p["name"], f"ref/{t['slug']}.html#m-{p['name']}", f"property of {t['name']}"))
        for f in t["functions"]: entries.append((f["name"] + "()", f"ref/{t['slug']}.html#m-{f['name']}", f"function of {t['name']}"))
        for s in user_signals(t): entries.append((s["name"], f"ref/{t['slug']}.html#m-{s['name']}", f"signal of {t['name']}"))
        for e in t["enums"]:
            for v in e["values"]: entries.append((v["name"], f"ref/{t['slug']}.html#m-{v['name']}", f"value of {t['name']}"))
    for term, s, d in GLOSSARY: entries.append((term, f"glossary.html#g-{s}", "glossary"))
    for c in CHAPTERS:
        for lvl, hid, txt in c.get("toc", []):
            if lvl == 2: entries.append((html.unescape(txt), f"{c['url']}#{hid}", f"chapter {c['slug'].split('-')[0]}"))
    entries.sort(key=lambda x: (x[0].lower().lstrip("_"), x[2]))
    letters = []
    body = ['<h1>A–Z Index</h1>', f'<p class="lede">{len(entries)} entries: every type, property, function, signal, enum value, glossary term and chapter section.</p>']
    groups = {}
    for e in entries:
        L = e[0][:1].upper()
        if not L.isalpha(): L = "#"
        groups.setdefault(L, []).append(e)
    body.append('<div class="letters">' + "".join(f'<a href="#L-{L}">{L}</a>' for L in groups) + '</div>')
    for L, es in groups.items():
        body.append(f'<h2 id="L-{L}">{L}</h2><ul class="az">')
        for n, u, k in es:
            body.append(f'<li><a href="{u}">{esc(n)}</a> <span class="muted">{esc(k)}</span></li>')
        body.append('</ul>')
    page("az.html", "A–Z Index", "\n".join(body), "az", crumbs=[("A–Z Index", None)])

QT_INDEX = {
 "q1-qt-visual": "Item Rectangle Gradient GradientStop Text Image AnimatedImage BorderImage TextInput TextEdit Canvas ShaderEffect ShaderEffectSource ParticleSystem Video MediaPlayer VideoOutput FontLoader",
 "q2-qt-layout": "Row Column Grid Flow RowLayout ColumnLayout GridLayout StackLayout Layout Flickable Loader anchors",
 "q3-qt-input": "MouseArea HoverHandler TapHandler WheelHandler DragHandler PinchHandler PointHandler Keys KeyNavigation FocusScope Shortcut Drag DropArea IntValidator DoubleValidator RegularExpressionValidator",
 "q4-qt-views": "Repeater ListView GridView PathView ListModel ListElement DelegateModel Instantiator WorkerScript",
 "q5-qt-animation": "Animation PropertyAnimation NumberAnimation ColorAnimation RotationAnimation SmoothedAnimation SpringAnimation SequentialAnimation ParallelAnimation PauseAnimation ScriptAction PropertyAction AnchorAnimation Behavior OpacityAnimator ScaleAnimator RotationAnimator XAnimator YAnimator State PropertyChanges AnchorChanges ParentChange StateChangeScript Transition Timer FrameAnimation Easing",
 "q6-qt-controls": "Control Button RoundButton ToolButton CheckBox RadioButton Switch ButtonGroup Slider RangeSlider Dial SpinBox ProgressBar BusyIndicator TextField TextArea ComboBox Label ScrollView ScrollBar TabBar TabButton StackView SwipeView PageIndicator Popup Menu Dialog ToolTip",
 "q7-qt-effects": "MultiEffect RectangularShadow Shape ShapePath PathLine PathMove PathArc PathAngleArc PathQuad PathCubic PathSvg PathRectangle LinearGradient RadialGradient ConicalGradient",
 "q8-qt-globals": "Qt console Math JSON Date XMLHttpRequest Component QtObject Connections Binding",
}
QT_LOOKUP = {}
for _slug, _names in QT_INDEX.items():
    for _n in _names.split():
        QT_LOOKUP.setdefault(_n, _slug)

def build_qt_index():
    body = ['<h1>Qt Type Index</h1><p class="lede">Every Qt type mentioned in this book and where it is described. Quickshell types are in the <a href="ref/index.html">API Reference</a>.</p>']
    items = sorted(QT_LOOKUP.items(), key=lambda x: x[0].lower())
    body.append('<ul class="az">')
    for name, slug in items:
        c = CH_BY_SLUG[slug]
        anchor = ""
        for lvl, hid, t in c.get("toc", []):
            if html.unescape(t).split()[0] == name or html.unescape(t).startswith(name + " "):
                anchor = "#" + hid; break
        body.append(f'<li id="{slugify(name)}"><a href="{c["url"]}{anchor}"><code>{esc(name)}</code></a> <span class="muted">{esc(c["title"].replace("Qt Reference: ", ""))}</span></li>')
        SEARCH.append([name, f"{c['url']}{anchor}", "qt type", c["title"]])
    body.append('</ul>')
    page("qt-index.html", "Qt Type Index", "\n".join(body), "qt", crumbs=[("Qt Type Index", None)])

def build_simple(name, path, active, title):
    p = os.path.join(SRC, name)
    if not os.path.exists(p): return
    src = open(p, encoding="utf-8").read()
    m = re.match(r'#\s+(.+)\n', src)
    h, toc = add_heading_ids(md(src, ""))
    page(path, title, h, active, toc, crumbs=[(title, None)])
    for lvl, hid, txt in toc:
        SEARCH.append([html.unescape(txt), f"{path}#{hid}", "section", title])

def build_index():
    intro = open(os.path.join(SRC, "cover.md"), encoding="utf-8").read() if os.path.exists(os.path.join(SRC, "cover.md")) else ""
    body = [md(intro, "")]
    body.append('<h2 id="contents">Contents</h2>')
    for pnum, ptitle, chs in PARTS:
        body.append(f'<div class="toc-part" id="part-{slugify(pnum)}"><div class="tp-h"><span>Part {pnum}</span>{esc(ptitle)}</div><ol class="toc-ch">')
        for slug, title in chs:
            c = CH_BY_SLUG[slug]
            subs = "".join(f'<a href="{c["url"]}#{hid}">{esc(html.unescape(t))}</a>' for l, hid, t in c.get("toc", []) if l == 2)
            body.append(f'<li><a class="tc" href="{c["url"]}"><span>{slug.split("-")[0]}</span>{esc(title)}</a><div class="subs">{subs}</div></li>')
        body.append('</ol></div>')
    body.append('<div class="toc-part"><div class="tp-h"><span>API</span>Quickshell API Reference</div><div class="pills">'
                + "".join(f'<a class="pill" href="ref/mod-{slugify(m)}.html">{esc(m)}</a>' for m in ALL_MODULES) + '</div></div>')
    body.append('<div class="toc-part"><div class="tp-h"><span>+</span>Appendices</div><div class="pills">'
                '<a class="pill" href="qt-index.html">Qt Type Index</a><a class="pill" href="glossary.html">Glossary</a>'
                '<a class="pill" href="az.html">A–Z Index</a><a class="pill" href="cheatsheet.html">Cheat Sheet</a>'
                '<a class="pill" href="print.html">Whole book for printing</a></div></div>')
    page("index.html", BOOK_TITLE, "\n".join(body), "index", crumbs=None,
         desc="A complete beginner-to-expert book on Quickshell and QML for Linux ricing.")

def build_print():
    parts = ['<h1>The Quickshell Book: Complete Edition</h1><p class="lede">All chapters on one page. Use your browser\'s Print → Save as PDF.</p>']
    for c in CHAPTERS:
        parts.append(f'<section class="print-ch"><div class="ch-part">Part {c["part"]} · {esc(c["ptitle"])}</div><h1>{esc(c["title"])}</h1>{c.get("html","")}</section>')
    for t in TYPES:
        h, _ = render_type(t)
        parts.append(f'<section class="print-ch">{h}</section>')
    html_all = "\n".join(parts)
    html_all = html_all.replace('href="../', 'href="')
    page("print.html", "Whole Book", html_all, "print", crumbs=[("Whole book", None)])

def main():
    if os.path.exists(OUT): shutil.rmtree(OUT)
    os.makedirs(OUT)
    shutil.copytree(os.path.join(SRC, "assets"), os.path.join(OUT, "assets"))
    build_glossary()
    build_chapters()
    build_reference()
    build_qt_index()
    build_simple("cheatsheet.md", "cheatsheet.html", "cheat", "Cheat Sheet")
    build_az()
    build_index()
    n_search = len(SEARCH)
    build_print()
    SEARCH[n_search:] = []
    open(os.path.join(OUT, "assets", "search-index.js"), "w", encoding="utf-8").write(
        "window.QSB_SEARCH=" + json.dumps(SEARCH, separators=(",", ":")) + ";")
    words = 0
    for c in CHAPTERS:
        if os.path.exists(c["file"]): words += len(open(c["file"]).read().split())
    for f in os.listdir(os.path.join(SRC, "ref")): words += len(open(os.path.join(SRC, "ref", f)).read().split())
    print(f"built {len(CHAPTERS)} chapters, {len(TYPES)} type pages, {len(SEARCH)} search entries, ~{words} hand-written words")

if __name__ == "__main__":
    main()
