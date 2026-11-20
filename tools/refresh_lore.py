#!/usr/bin/env python3
"""refresh_lore.py - regenerate web/app.js's LORE_FROZEN from data/lore_lines.json.

INERT AND OFFLINE. It reads two local files and (only with --write) rewrites three
lines of one local file. No network, no subprocess, no eval, no import of the page.
Run it from the repo root (or pass --repo):

    python3 web/tools/refresh_lore.py --check                 # report drift, write nothing
    python3 web/tools/refresh_lore.py --write --sha 1a2b3c4 --date 2026-11-19

The source SHA/date are passed in on purpose (the commit that last changed
data/lore_lines.json: `git log -1 --format="%h %cs" -- data/lore_lines.json`), so the
tool itself never shells out. --check exits 1 when the page is behind the data.

WHAT IT KEEPS - an explicit per-section whitelist of exactly the fields app.js reads
(loreTownLife, loreGrowth, loreE3po, loreLords, loreTales). Everything else is dropped:
every key starting with "_" (the `_note*` authoring notes would otherwise render as
tale cards, since loreTales walks Object.keys), the *_alt variant pools (no hub reader),
and the Phase-2 keys that have no reader anywhere. Every kept value must be a string
(or a list of strings); anything else is a hard error, never a silent coercion. The text
is still attacker-shaped in principle, so it keeps reaching the DOM ONLY through el().
Output is ASCII-only JSON (ensure_ascii) so no U+2028/2029 can ride in on a line.
"""
import argparse, json, os, re, sys

# field whitelist per section. "S" = string, "L" = list of strings.
TOWN_LIFE = {"crier": "L", "market": "L", "growth": "L"}
E3PO = {"intro": "L", "says": "L", "town_talk": "L"}
TIER = {"name": "S", "crier": "S", "see": "S"}
DISASTER = {"begin": "S", "during": "SL", "pass": "S", "cost": "S"}
CAMP = {"name": "S", "leader": "S", "of": "S", "appears": "S", "while": "S", "cleared": "S"}
BOSS = {"name": "S", "appears": "S", "while": "S", "cleared": "S", "note": "S"}


def fail(msg):
    sys.stderr.write("RED: " + msg + "\n")
    sys.exit(2)


def s(v, where):
    if not isinstance(v, str):
        fail("%s is %s, expected a string" % (where, type(v).__name__))
    return v


def pick(obj, spec, where):
    if not isinstance(obj, dict):
        fail("%s is not an object" % where)
    out = {}
    for k, kind in spec.items():
        if k not in obj:
            continue
        v = obj[k]
        w = where + "." + k
        if kind == "S":
            out[k] = s(v, w)
        elif kind == "L":
            if not isinstance(v, list):
                fail(w + " is not a list")
            out[k] = [s(x, "%s[%d]" % (w, i)) for i, x in enumerate(v)]
        else:  # "SL": a string or a list of strings (disaster `during`)
            out[k] = [s(x, "%s[%d]" % (w, i)) for i, x in enumerate(v)] if isinstance(v, list) else s(v, w)
    return out


def public_keys(d, where):
    if not isinstance(d, dict):
        fail(where + " is not an object")
    return [k for k in d if not k.startswith("_")]


def build(data):
    out = {}
    out["town_life"] = pick(data["town_life"], TOWN_LIFE, "town_life")
    tiers = data["growth_tiers"]["tiers"]
    if not isinstance(tiers, list):
        fail("growth_tiers.tiers is not a list")
    out["growth_tiers"] = {"tiers": [pick(t, TIER, "growth_tiers.tiers[%d]" % i) for i, t in enumerate(tiers)]}
    out["e3po"] = pick(data["e3po"], E3PO, "e3po")
    for sec in ("lord_intros", "unique_intros"):
        out[sec] = {k: s(data[sec][k], sec + "." + k) for k in public_keys(data[sec], sec)}
    out["disasters"] = {k: pick(data["disasters"][k], DISASTER, "disasters." + k)
                        for k in public_keys(data["disasters"], "disasters")}
    ev = data["events"]
    out["events"] = {}
    for k in ("bandit_camps", "monster_camps"):
        lst = ev[k]
        if not isinstance(lst, list):
            fail("events.%s is not a list" % k)
        out["events"][k] = [pick(c, CAMP, "events.%s[%d]" % (k, i)) for i, c in enumerate(lst)]
    out["events"]["wandering_boss"] = pick(ev["wandering_boss"], BOSS, "events.wandering_boss")
    return out


def count(o):
    if isinstance(o, str):
        return 1
    if isinstance(o, list):
        return sum(count(x) for x in o)
    if isinstance(o, dict):
        return sum(count(x) for x in o.values())
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=".")
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--sha")
    ap.add_argument("--date")
    a = ap.parse_args()
    if a.check == a.write:
        fail("pass exactly one of --check / --write")
    src = os.path.join(a.repo, "data", "lore_lines.json")
    app = os.path.join(a.repo, "web", "app.js")
    with open(src, encoding="utf-8") as f:
        data = json.load(f)
    new = build(data)
    body = json.dumps(new, separators=(",", ":"), ensure_ascii=True)
    json.loads(body)  # round-trip proof
    with open(app, encoding="utf-8", newline="") as f:
        js = f.read()
    m = re.search(r"^const LORE_FROZEN = (.*);$", js, re.M)
    ms = re.search(r'^const LORE_SRC_SHA  = "([0-9a-f]{7,40})";$', js, re.M)
    md = re.search(r'^const LORE_SRC_DATE = "(\d{4}-\d{2}-\d{2})";$', js, re.M)
    if not (m and ms and md):
        fail("could not find the three LORE_* lines in app.js")
    old = json.loads(m.group(1))
    print("page pin: %s %s | strings on page %d -> from data %d" % (ms.group(1), md.group(1), count(old), count(new)))
    for k in new:
        o, n = count(old.get(k)), count(new[k])
        print("  %-13s %5d -> %5d %s" % (k, o, n, "" if o == n else "(+%d)" % (n - o)))
    stale = (old != new)
    print("STALE: the page is behind data/lore_lines.json" if stale else "CURRENT: the page equals the data")
    if a.check:
        sys.exit(1 if stale else 0)
    if not (a.sha and re.fullmatch(r"[0-9a-f]{7,40}", a.sha) and a.date and re.fullmatch(r"\d{4}-\d{2}-\d{2}", a.date)):
        fail("--write needs --sha (hex) and --date (YYYY-MM-DD)")
    js = js[:m.start(1)] + body + js[m.end(1):]
    js = re.sub(r'^(const LORE_SRC_SHA  = ")[0-9a-f]+(";)$', lambda x: x.group(1) + a.sha + x.group(2), js, flags=re.M)
    js = re.sub(r'^(const LORE_SRC_DATE = ")[\d-]+(";)$', lambda x: x.group(1) + a.date + x.group(2), js, flags=re.M)
    with open(app, "w", encoding="utf-8", newline="") as f:
        f.write(js)
    print("wrote %s (pin %s %s)" % (app, a.sha, a.date))


if __name__ == "__main__":
    main()
