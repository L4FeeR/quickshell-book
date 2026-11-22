// Fuzzy matching for the launcher: "ffx" finds "Firefox".
// The query's letters must appear in order; the score rewards letters that
// start a word, letters that follow each other, and a match at the start.
.pragma library

// returns a score (higher = better) or -1 when the query doesn't match
function score(query, text) {
    query = query.toLowerCase();
    const lower = text.toLowerCase();
    if (query === "")
        return 0;
    if (lower.startsWith(query))
        return 1000 - text.length;            // a prefix beats everything; shorter wins
    let total = 0, last = -2, from = 0;
    for (const ch of query) {
        const i = lower.indexOf(ch, from);
        if (i < 0)
            return -1;                        // a letter is missing: no match
        const wordStart = i === 0 || " -_.".includes(lower[i - 1]);
        total += 10 + (wordStart ? 30 : 0) + (i === last + 1 ? 20 : 0);
        last = i;
        from = i + 1;
    }
    return total - lower.length * 0.5;        // shorter names win ties
}

// the best score over several fields (name, generic name, keywords…)
function best(query, fields) {
    let top = -1;
    for (const f of fields)
        if (f) top = Math.max(top, score(query, f));
    return top;
}
