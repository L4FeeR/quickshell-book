/* The Quickshell Book — navigation, search, highlighting. No dependencies. */
(function () {
  var rel = document.body.dataset.rel || "";
  var root = document.documentElement;

  /* ---------- theme ---------- */
  document.getElementById("themeBtn").onclick = function () {
    var dark = root.dataset.theme ? root.dataset.theme === "dark" : matchMedia("(prefers-color-scheme: dark)").matches;
    root.dataset.theme = dark ? "light" : "dark";
    try { localStorage.setItem("qsb-theme", root.dataset.theme); } catch (e) {}
  };
  document.getElementById("menuBtn").onclick = function () { document.body.classList.toggle("menu"); };
  document.addEventListener("click", function (e) {
    if (document.body.classList.contains("menu") && !e.target.closest(".side") && !e.target.closest("#menuBtn"))
      document.body.classList.remove("menu");
  });

  /* ---------- sidebar: scroll active into view ---------- */
  var act = document.querySelector(".side a.active");
  if (act) act.scrollIntoView({ block: "center" });

  /* ---------- syntax highlighting (QML / JS / shell / ini) ---------- */
  var KW = "import|property|readonly|required|default|alias|signal|function|return|if|else|for|while|do|switch|case|break|continue|new|var|let|const|true|false|null|undefined|this|typeof|instanceof|in|of|pragma|as|on|component|enum|try|catch|finally|throw|delete|void|async|await|yield|class|extends|super";
  var TY = "int|real|double|bool|string|color|url|list|date|point|size|rect|font|vector2d|vector3d|matrix4x4";
  function hl(code, lang) {
    var out = "", i = 0, n = code.length, m;
    var rules;
    if (lang === "sh") rules = [
      [/^#[^\n]*/, "c"], [/^("([^"\\]|\\.)*"|'[^']*')/, "s"], [/^\$\{?[\w@#?*]+\}?/, "p"],
      [/^\b(if|then|else|fi|for|do|done|while|case|esac|function|in|export|sudo|set|local|return|echo|exec|source)\b/, "k"],
      [/^-{1,2}[\w-]+/, "f"], [/^\b\d+\b/, "n"]];
    else if (lang === "ini") rules = [
      [/^[#;][^\n]*/, "c"], [/^("([^"\\]|\\.)*"|'[^']*')/, "s"], [/^\[[^\]\n]+\]/, "t"],
      [/^\b[\w.-]+(?=\s*=)/, "p"], [/^\b\d+(\.\d+)?\b/, "n"], [/^\b(true|false|bind[a-z]*|exec-once|exec|layerrule|windowrule[v2]*)\b/, "k"]];
    else if (lang === "text") rules = [];
    else rules = [
      [/^\/\/[^\n]*/, "c"], [/^\/\*[\s\S]*?\*\//, "c"],
      [/^`(?:[^`\\]|\\.)*`/, "s"], [/^"(?:[^"\\\n]|\\.)*"/, "s"], [/^'(?:[^'\\\n]|\\.)*'/, "s"],
      [/^\b0x[0-9a-fA-F]+\b|^\b\d+(\.\d+)?(e[+-]?\d+)?\b/, "n"],
      [new RegExp("^\\b(" + KW + ")\\b"), "k"],
      [new RegExp("^\\b(" + TY + ")\\b(?=\\s+\\w)"), "t"],
      [/^\b[A-Z][\w]*\b/, "t"],
      [/^\b[a-z_][\w]*(?=\s*:(?!:))/, "p"],
      [/^\b[a-z_][\w]*(?=\s*\()/, "f"]];
    while (i < n) {
      var rest = code.slice(i), hit = false;
      for (var r = 0; r < rules.length; r++) {
        m = rules[r][0].exec(rest);
        if (m && m[0].length) {
          out += '<span class="t-' + rules[r][1] + '">' + esc(m[0]) + "</span>";
          i += m[0].length; hit = true; break;
        }
      }
      if (!hit) {
        var w = /^[\w$]+|^\s+|^./.exec(rest)[0];
        out += esc(w); i += w.length;
      }
    }
    return out;
  }
  function esc(s) { return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"); }
  Array.prototype.forEach.call(document.querySelectorAll("pre.code"), function (pre) {
    var c = pre.querySelector("code"), raw = c.textContent;
    if (raw.length < 60000) c.innerHTML = hl(raw, pre.dataset.lang);
    var b = document.createElement("button");
    b.className = "copy"; b.textContent = "copy";
    b.onclick = function () {
      var done = function () { b.textContent = "copied ✓"; setTimeout(function () { b.textContent = "copy"; }, 1200); };
      if (navigator.clipboard) navigator.clipboard.writeText(raw).then(done, function () {});
      else { var t = document.createElement("textarea"); t.value = raw; document.body.appendChild(t); t.select(); try { document.execCommand("copy"); done(); } catch (e) {} t.remove(); }
    };
    pre.parentNode.appendChild(b);
  });

  /* ---------- on-this-page scroll spy ---------- */
  var otp = Array.prototype.slice.call(document.querySelectorAll(".otp a"));
  var heads = otp.map(function (a) { return document.getElementById(decodeURIComponent(a.hash.slice(1))); });
  function spy() {
    var cur = -1;
    for (var i = 0; i < heads.length; i++) { if (heads[i] && heads[i].getBoundingClientRect().top < 110) cur = i; else break; }
    otp.forEach(function (a, i) { a.classList.toggle("active", i === cur); });
  }
  if (otp.length) { document.addEventListener("scroll", spy, { passive: true }); spy(); }

  /* ---------- search ---------- */
  var q = document.getElementById("q"), box = document.getElementById("qres");
  var DATA = window.QSB_SEARCH || [], sel = 0, shown = [];
  var KORDER = { type: 0, chapter: 1, module: 2, property: 3, function: 4, signal: 5, "enum value": 6, glossary: 7, section: 8 };
  function score(item, terms, raw) {
    var t = item[0].toLowerCase(), s = 0;
    if (t === raw) s += 100;
    else if (t.indexOf(raw) === 0) s += 60;
    else if (t.split(".").pop().indexOf(raw) === 0) s += 50;
    for (var i = 0; i < terms.length; i++) {
      var p = t.indexOf(terms[i]);
      if (p < 0) { if ((item[3] || "").toLowerCase().indexOf(terms[i]) < 0) return -1; s += 2; }
      else s += 20 - Math.min(p, 15);
    }
    return s - (KORDER[item[2]] || 0) * 2 - t.length * 0.15;
  }
  function run() {
    var raw = q.value.trim().toLowerCase();
    if (!raw) { box.classList.remove("show"); return; }
    var terms = raw.split(/\s+/), res = [];
    for (var i = 0; i < DATA.length; i++) { var s = score(DATA[i], terms, raw); if (s > -1) res.push([s, DATA[i]]); }
    res.sort(function (a, b) { return b[0] - a[0]; });
    shown = res.slice(0, 40).map(function (r) { return r[1]; });
    sel = 0;
    box.innerHTML = shown.length ? shown.map(function (d, i) {
      return '<a href="' + rel + d[1] + '"' + (i === 0 ? ' class="sel"' : "") + '><span class="k">' + esc(d[2]) + "</span><b>" + esc(d[0]) + '</b><span class="c">' + esc(d[3] || "") + "</span></a>";
    }).join("") : '<a><span class="k">—</span>No results</a>';
    box.classList.add("show");
  }
  q.addEventListener("input", run);
  q.addEventListener("focus", run);
  q.addEventListener("keydown", function (e) {
    var links = box.querySelectorAll("a");
    if (e.key === "ArrowDown" || e.key === "ArrowUp") {
      e.preventDefault();
      if (!links.length) return;
      links[sel].classList.remove("sel");
      sel = (sel + (e.key === "ArrowDown" ? 1 : -1) + links.length) % links.length;
      links[sel].classList.add("sel"); links[sel].scrollIntoView({ block: "nearest" });
    } else if (e.key === "Enter") { if (links[sel] && links[sel].href) location.href = links[sel].href; }
    else if (e.key === "Escape") { q.blur(); box.classList.remove("show"); }
  });
  document.addEventListener("click", function (e) { if (!e.target.closest(".search")) box.classList.remove("show"); });

  /* ---------- keyboard shortcuts ---------- */
  document.addEventListener("keydown", function (e) {
    if (e.target.closest("input,textarea")) return;
    if (e.key === "/") { e.preventDefault(); q.focus(); q.select(); }
    else if (e.key === "ArrowLeft" && e.altKey) { var p = document.querySelector(".pn-prev"); if (p) location.href = p.href; }
    else if (e.key === "ArrowRight" && e.altKey) { var n = document.querySelector(".pn-next"); if (n) location.href = n.href; }
  });
})();
