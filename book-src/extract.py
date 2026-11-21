#!/usr/bin/env python3
"""Extract the Quickshell QML API (types, properties, functions, signals, enums)
from C++ headers + QML files listed in each module.md. Output: api.json"""
import json, os, re, sys

ROOTS = [("/tmp/claude-1000/qsrc/upstream", None),
         ("/tmp/claude-1000/qsrc/noctalia", {"Quickshell.Niri", "Quickshell.DWL"})]

def parse_toml_lite(text):
    head, _, body = text.partition("-----")
    d = {}
    for m in re.finditer(r'(\w+)\s*=\s*"([^"]*)"', head):
        d[m.group(1)] = m.group(2)
    for key in ("headers", "qml_files"):
        m = re.search(key + r'\s*=\s*\[(.*?)\]', head, re.S)
        d[key] = re.findall(r'"([^"]+)"', m.group(1)) if m else []
    d["body"] = body.strip()
    return d

def strip_doc(lines):
    out = []
    for l in lines:
        l = l.strip()
        l = re.sub(r'^///!?\s?', '', l)
        out.append(l)
    return "\n".join(out).strip()

ACCESS = re.compile(r'^\s*(public|private|protected)(\s+slots)?\s*:|^\s*(signals|Q_SIGNALS)\s*:')

def find_block_end(lines, i):
    depth = 0; started = False
    for j in range(i, len(lines)):
        s = re.sub(r'//.*', '', lines[j])
        s = re.sub(r'"([^"\\]|\\.)*"', '""', s)
        for ch in s:
            if ch == '{': depth += 1; started = True
            elif ch == '}': depth -= 1
        if started and depth <= 0:
            return j
    return len(lines) - 1

def join_parens(lines, i):
    buf = lines[i].strip(); j = i
    while buf.count("(") > buf.count(")") and j + 1 < len(lines):
        j += 1; buf += " " + lines[j].strip()
    return buf, j

def join_until(lines, i, end_pat=';'):
    buf = lines[i]; j = i
    while end_pat not in re.sub(r'//.*', '', buf) and j + 1 < len(lines):
        j += 1; buf += " " + lines[j].strip()
    return buf, j

def clean_type(t):
    t = t.strip()
    t = re.sub(r'\bconst\b', '', t).replace('&', '').strip()
    t = t.replace('::Enum', '').replace('::Flags', '')
    t = re.sub(r'\b\w+::', '', t)
    t = re.sub(r'\s*\*\s*', '', t)
    m = {"QString": "string", "qreal": "real", "double": "real", "float": "real", "qint32": "int", "quint32": "int",
         "qint64": "int", "quint64": "int", "qint16": "int", "quint16": "int", "qint8": "int", "quint8": "int",
         "qsizetype": "int", "qlonglong": "int", "qulonglong": "int", "QColor": "color", "QUrl": "url", "QVariant": "var",
         "QJSValue": "var", "QVariantMap": "object", "QVariantList": "list<var>", "QStringList": "list<string>",
         "QDateTime": "date", "QObject": "QtObject", "QQuickItem": "Item", "QQmlComponent": "Component",
         "QQuickWindow": "QtWindow", "QSizeF": "size", "QSize": "size", "QPointF": "point", "QPoint": "point",
         "QRectF": "rect", "QRect": "rect", "QDate": "date", "QTime": "date", "QByteArray": "string", "QMargins": "margins",
         "unsigned int": "int", "uint": "int", "void": "void", "bool": "bool", "int": "int"}
    def conv(x):
        x = x.strip()
        mm = re.match(r'(QList|QVector|QQmlListProperty|ObjectModel|UntypedObjectModel)<(.+)>$', x)
        if mm:
            inner = conv(mm.group(2))
            if mm.group(1) == "ObjectModel": return f"ObjectModel<{inner}>"
            return f"list<{inner}>"
        mm = re.match(r'QMap<.*>|QHash<.*>', x)
        if mm: return "object"
        return m.get(x, x)
    return conv(t)

def parse_params(p):
    p = p.strip()
    if not p: return []
    parts, depth, cur = [], 0, ""
    for ch in p:
        if ch == '<': depth += 1
        elif ch == '>': depth -= 1
        if ch == ',' and depth == 0: parts.append(cur); cur = ""
        else: cur += ch
    parts.append(cur)
    out = []
    for x in parts:
        x = x.split('=')[0].strip()
        if not x: continue
        mm = re.match(r'(.*?)([A-Za-z_]\w*)$', x)
        if mm and mm.group(1).strip():
            out.append({"name": mm.group(2), "type": clean_type(mm.group(1))})
        else:
            out.append({"name": "arg", "type": clean_type(x)})
    return out

def parse_header(path, module):
    try:
        lines = open(path, encoding="utf-8").read().split("\n")
    except FileNotFoundError:
        return []
    types = []
    doc_buf = []
    i = 0
    # namespace-level enums (Q_NAMESPACE + QML_ELEMENT)
    while i < len(lines):
        line = lines[i]
        st = line.strip()
        if st.startswith("///"):
            doc_buf.append(st); i += 1; continue
        mns = re.match(r'\s*namespace\s+(\w+)\s*\{', line)
        if mns:
            # look ahead for Q_NAMESPACE + QML_ELEMENT
            look = "\n".join(lines[i:i+6])
            if "Q_NAMESPACE" in look and ("QML_ELEMENT" in look or "QML_NAMED_ELEMENT" in look):
                end = find_block_end(lines, i)
                name = mns.group(1)
                mn = re.search(r'QML_NAMED_ELEMENT\((\w+)\)', look)
                if mn: name = mn.group(1)
                t = {"name": name, "module": module, "doc": strip_doc(doc_buf), "kind": "enum-namespace",
                     "properties": [], "functions": [], "signals": [], "enums": [], "base": None,
                     "flags": [], "file": path}
                parse_body(lines, i + 1, end, t)
                types.append(t)
                doc_buf = []; i = end + 1; continue
            doc_buf = []; i += 1; continue
        mc = re.match(r'\s*class\s+(?:Q_DECL_EXPORT\s+)?(\w+)\s*(?:final\s*)?(?::\s*([^{]+))?\{?\s*$', line)
        if mc and not st.endswith(";"):
            end = find_block_end(lines, i)
            body = "\n".join(lines[i:end + 1])
            cname = mc.group(1)
            # base class
            base = None
            if mc.group(2):
                b = mc.group(2).split(",")[0]
                b = re.sub(r'\b(public|protected|private|virtual)\b', '', b).strip()
                base = clean_type(b)
            mb = re.search(r'QSDOC_BASECLASS\((\w+)\)', body)
            if mb: base = mb.group(1)
            # only look at class-level macros (not nested classes) - approximate
            name = None; flags = []
            m1 = re.search(r'^\s*QML_NAMED_ELEMENT\((\w+)\)', body, re.M)
            m2 = re.search(r'^\s*QSDOC_NAMED_ELEMENT\((\w+)\)', body, re.M)
            if m2: name = m2.group(1)
            elif m1: name = m1.group(1)
            elif re.search(r'^\s*(QML_ELEMENT|QSDOC_ELEMENT)\s*;?', body, re.M): name = cname
            if re.search(r'^\s*QML_SINGLETON', body, re.M): flags.append("singleton")
            mu = re.search(r'^\s*QML_UNCREATABLE\(\s*"((?:[^"\\]|\\.)*)"', body, re.M)
            if mu and "QSDOC_CREATABLE" not in body: flags.append("uncreatable");
            ma = re.search(r'^\s*QML_ATTACHED\((\w+)\)', body, re.M)
            if ma: flags.append("attached:" + ma.group(1))
            if re.search(r'^\s*QML_VALUE_TYPE', body, re.M) or "Q_GADGET" in body: flags.append("gadget")
            md = re.search(r'Q_CLASSINFO\("DefaultProperty",\s*"(\w+)"\)', body)
            t = {"name": name or cname, "cname": cname, "module": module, "doc": strip_doc(doc_buf),
                 "kind": "type" if name else "internal", "properties": [], "functions": [], "signals": [],
                 "enums": [], "base": base, "flags": flags, "file": path,
                 "uncreatable_reason": mu.group(1) if mu else None,
                 "default_property": md.group(1) if md else None}
            parse_body(lines, i + 1, end, t)
            types.append(t)
            doc_buf = []; i = end + 1; continue
        if st and not st.startswith("//") and not st.startswith("#") and not st.startswith("template"):
            doc_buf = []
        i += 1
    return types

def parse_body(lines, start, end, t):
    doc = []
    section = "private"
    hide = False
    tov = None
    i = start
    depth = 0
    while i < end:
        line = lines[i]; st = line.strip()
        if st.startswith("//@ "):
            line = line.replace("//@ ", "", 1); lines[i] = line; st = line.strip()
        # skip nested class/struct bodies
        if re.match(r'\s*(class|struct)\s+\w+[^;]*$', line) and "{" in "".join(lines[i:i+2]) and not st.endswith(";"):
            j = find_block_end(lines, i); i = j + 1; doc = []; continue
        if st.startswith("///"):
            doc.append(st); i += 1; continue
        ma = ACCESS.match(line)
        if ma:
            section = "signals" if ma.group(3) else ma.group(1) + ("-slots" if ma.group(2) else "")
            doc = []; i += 1; continue
        if "QSDOC_HIDE" in st and st.strip() in ("QSDOC_HIDE", "QSDOC_HIDE;"):
            hide = True; i += 1; continue
        if st.startswith("QSDOC_HIDE ") and ("Q_INVOKABLE" in st or "Q_PROPERTY" in st):
            hide = True; line = line.replace("QSDOC_HIDE", "", 1); lines[i] = line; st = line.strip()
        mt = re.match(r'QSDOC_TYPE_OVERRIDE\((.*)\);?\s*$', st)
        if mt:
            tov = mt.group(1); i += 1; continue
        if st.startswith("Q_PROPERTY("):
            buf, j = join_parens(lines, i)
            inner = re.search(r'Q_PROPERTY\((.*)\)', buf, re.S).group(1)
            toks = inner.split()
            kw = {"READ", "WRITE", "MEMBER", "NOTIFY", "BINDABLE", "CONSTANT", "FINAL", "RESET", "REVISION", "DESIGNABLE", "STORED", "SCRIPTABLE", "USER", "REQUIRED"}
            k = next((n for n, x in enumerate(toks) if x in kw), len(toks))
            name = toks[k - 1]; typ = " ".join(toks[:k - 1])
            rest = toks[k:]
            writable = ("WRITE" in rest or "MEMBER" in rest) and "CONSTANT" not in rest
            mo = re.search(r'QSDOC_TYPE_OVERRIDE\(([^)]*)\)', "\n".join(doc + [buf]))
            if mo: typ = mo.group(1)
            if tov: typ = tov; tov = None
            p = {"name": name, "type": clean_type(typ), "readonly": not writable,
                 "constant": "CONSTANT" in rest, "doc": strip_doc(doc), "required": "REQUIRED" in rest}
            if not hide: t["properties"].append(p)
            doc = []; hide = False; i = j + 1; continue
        if st.startswith("QSDOC_PROPERTY_OVERRIDE("):
            buf, j = join_parens(lines, i)
            inner = re.search(r'QSDOC_PROPERTY_OVERRIDE\((.*)\)', buf, re.S).group(1)
            toks = inner.split()
            name = toks[1] if len(toks) > 1 else toks[0]
            kw = {"READ", "WRITE", "MEMBER", "NOTIFY", "BINDABLE", "CONSTANT"}
            k = next((n for n, x in enumerate(toks) if x in kw), len(toks))
            name = toks[k - 1]; typ = " ".join(toks[:k - 1])
            t["properties"] = [x for x in t["properties"] if x["name"] != name]
            t["properties"].append({"name": name, "type": clean_type(typ), "readonly": "WRITE" not in toks[k:],
                                    "constant": False, "doc": strip_doc(doc), "required": False})
            doc = []; i = j + 1; continue
        if st.startswith("Q_INVOKABLE") or (section in ("public-slots",) and re.match(r'\s*[\w:<>*&\s]+\s+\w+\(.*', line) and not st.startswith("//")):
            buf, j = join_until(lines, i, ")")
            # get to end of declaration
            k2 = j
            while ";" not in buf and "{" not in buf and k2 + 1 < end:
                k2 += 1; buf += " " + lines[k2].strip()
            if "{" in buf and "}" not in buf:
                k2 = find_block_end(lines, i)
            mm = re.search(r'(?:Q_INVOKABLE\s+)?(?:\[\[nodiscard\]\]\s*)?(static\s+|virtual\s+)?([\w:<>*&,\s]+?)\s*\b(\w+)\s*\((.*?)\)\s*(const)?', buf.replace("Q_INVOKABLE", "", 1) if True else buf, re.S)
            if mm and mm.group(3) not in ("if", "for", "while", "return"):
                ret = mm.group(2).replace("[[nodiscard]]", "").replace("static", "").replace("virtual", "").strip()
                f = {"name": mm.group(3), "ret": clean_type(ret) if ret else "void",
                     "params": parse_params(mm.group(4)), "doc": strip_doc(doc)}
                if not hide and not f["name"].startswith("operator") and f["name"] != t.get("cname") and not re.match(r'on[A-Z]', f["name"]):
                    t["functions"].append(f)
            doc = []; hide = False; i = k2 + 1; continue
        if section == "signals" and re.match(r'\s*(QSDOC_HIDE\s+)?void\s+\w+\s*\(', line):
            buf, j = join_until(lines, i, ";")
            mm = re.search(r'(QSDOC_HIDE\s+)?void\s+(\w+)\s*\((.*?)\)', buf, re.S)
            if mm:
                hidden = hide or bool(mm.group(1))
                s = {"name": mm.group(2), "params": parse_params(mm.group(3)), "doc": strip_doc(doc)}
                if not hidden: t["signals"].append(s)
            doc = []; hide = False; i = j + 1; continue
        me = re.match(r'\s*enum\s+(?:class\s+)?(\w+)\s*(?::\s*[\w:]+)?\s*\{?', line)
        if me and not st.endswith(";"):
            j = find_block_end(lines, i)
            ebody = "\n".join(lines[i:j + 1])
            ebody = ebody[ebody.index("{") + 1: ebody.rindex("}")] if "{" in ebody else ""
            vals = []; vdoc = []
            for el in ebody.split("\n"):
                es = el.strip()
                if es.startswith("///"): vdoc.append(es); continue
                if es.startswith("//") or not es: continue
                for piece in es.split(","):
                    piece = piece.strip()
                    if not piece: continue
                    mv = re.match(r'(\w+)\s*(?:=\s*([^,]+))?', piece)
                    if mv:
                        vals.append({"name": mv.group(1), "value": (mv.group(2) or "").strip(), "doc": strip_doc(vdoc)})
                        vdoc = []
            t["enums"].append({"name": me.group(1), "values": vals, "doc": strip_doc(doc)})
            doc = []; i = j + 1; continue
        if st and not st.startswith("//"):
            doc = [] if not st.startswith("QSDOC") else doc
            hide = False if not st.startswith("QSDOC_HIDE") else hide
        i += 1

def parse_qml(path, module):
    try:
        text = open(path, encoding="utf-8").read()
    except FileNotFoundError:
        return []
    name = os.path.splitext(os.path.basename(path))[0]
    lines = text.split("\n")
    doc_buf = []; tdoc = ""; base = None; props = []; funcs = []; sigs = []
    depth = 0; root_seen = False
    for line in lines:
        st = line.strip()
        if st.startswith("///"):
            doc_buf.append(st); continue
        if not root_seen:
            mr = re.match(r'([A-Z][\w.]*)\s*\{', st)
            if mr:
                base = mr.group(1); tdoc = strip_doc(doc_buf); doc_buf = []; root_seen = True
                depth += st.count("{") - st.count("}"); continue
            if st and not st.startswith("import") and not st.startswith("pragma") and not st.startswith("//"):
                doc_buf = []
            continue
        if depth == 1:
            mp = re.match(r'(required\s+|readonly\s+|default\s+)*property\s+([\w<>.]+)\s+(\w+)', st)
            mal = re.match(r'(readonly\s+)?property\s+/\*\s*([\w<>.]+)\s*\*/\s*alias\s+(\w+)', st)
            if mal:
                props.append({"name": mal.group(3), "type": mal.group(2), "readonly": bool(mal.group(1)),
                              "constant": False, "doc": strip_doc(doc_buf), "required": False})
            elif mp and mp.group(2) == "alias":
                pass
            if mp and mp.group(2) != "alias":
                props.append({"name": mp.group(3), "type": mp.group(2), "readonly": "readonly" in (st.split("property")[0]),
                              "constant": False, "doc": strip_doc(doc_buf), "required": "required" in st.split("property")[0]})
            ma = re.match(r'(?:readonly\s+)?property\s+alias\s+(\w+)', st)
            mf = re.match(r'function\s+(\w+)\s*\((.*?)\)\s*(?::\s*(\w+))?', st)
            if mf:
                funcs.append({"name": mf.group(1), "ret": mf.group(3) or "void",
                              "params": [{"name": x.split(":")[0].strip(), "type": (x.split(":")[1].strip() if ":" in x else "var")} for x in mf.group(2).split(",") if x.strip()],
                              "doc": strip_doc(doc_buf)})
            ms = re.match(r'signal\s+(\w+)\s*(?:\((.*?)\))?', st)
            if ms:
                sigs.append({"name": ms.group(1), "params": [], "doc": strip_doc(doc_buf)})
            if not st.startswith("///"):
                doc_buf = [] if st else doc_buf
        depth += st.count("{") - st.count("}")
    return [{"name": name, "cname": name, "module": module, "doc": tdoc, "kind": "type", "properties": props,
             "functions": funcs, "signals": sigs, "enums": [], "base": base, "flags": ["qml"], "file": path}]

def main():
    modules = {}
    for root, only in ROOTS:
        for dp, dn, fn in os.walk(os.path.join(root, "src")):
            if "module.md" not in fn: continue
            md = parse_toml_lite(open(os.path.join(dp, "module.md")).read())
            mname = md["name"]
            if only is not None and mname not in only: continue
            if only is None and mname in modules: continue
            types = []
            for h in md["headers"]:
                types += parse_header(os.path.normpath(os.path.join(dp, h)), mname)
            for q in md["qml_files"]:
                types += parse_qml(os.path.join(dp, q), mname)
            modules[mname] = {"name": mname, "description": md.get("description", ""), "body": md["body"],
                              "fork_only": only is not None, "types": types}
    json.dump(modules, open(sys.argv[1] if len(sys.argv) > 1 else "api.json", "w"), indent=1)
    tot = 0
    for m in modules.values():
        vis = [t for t in m["types"] if t["kind"] != "internal"]
        tot += len(vis)
        print(f'{m["name"]:40} {len(vis):3} types  ' + ", ".join(t["name"] for t in vis))
    print("total", tot)

main()
