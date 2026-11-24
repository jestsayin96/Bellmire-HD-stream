"""_spanprobe.py - WHAT EVERY BUILDER'S SPANS ACTUALLY COVER, BY INDEX.

Written 24 Nov 2026 16:4x CT for one question the census cannot answer:
`_selfseen_census.py` asks only `"man" in spans`. Six of the 25 bodies it
calls `not_measurable` - "no `man` span at all, so there is nothing to split"
- hand it a FULL body decomposition under other names (trunk/head/arms/legs,
or man_lower/head/tool_arms). For those the census's own sentence is false:
there IS something to split. This prints, per key, every span with its index
range, the item count, which indices NO span covers, and whether a candidate
body set is CONTIGUOUS - because `_backread.py` takes a single (i0, i1) range
and a non-contiguous union cannot be declared as one.

  blender -b -noaudio -P tools/art/_spanprobe.py -- --repo <repo> [--keys a,b]
"""
import os
import sys
import json
import argparse

import bpy  # noqa: F401

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import minibosses as M  # noqa: E402

# Names that have been used for PARTS OF THE FIGURE in this file. This list is
# a CANDIDATE set only: contiguity is measured, never assumed, and a key whose
# candidate union is not one range is reported as such rather than merged.
BODY = ("man", "man_lower", "trunk", "head", "arms", "legs", "cuffs",
        "tool_arms")


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--keys", default="")
    args = ap.parse_args(argv)

    keys = ([k for k in args.keys.split(",") if k] or sorted(M.BUILDERS.keys()))
    rows = {}
    for key in keys:
        if key not in M.BUILDERS:
            rows[key] = {"error": "no builder"}
            continue
        try:
            P = M.BUILDERS[key]()
        except Exception as exc:
            rows[key] = {"error": "%s: %s" % (type(exc).__name__, exc)}
            continue
        spans = dict(getattr(P, "spans", {}) or {})
        n = len(getattr(P, "items", []) or [])
        cov = set()
        for a, b in spans.values():
            cov |= set(range(a, b))
        body = {k: list(v) for k, v in spans.items() if k in BODY}
        idx = set()
        for a, b in body.values():
            idx |= set(range(a, b))
        lo, hi = (min(idx), max(idx) + 1) if idx else (0, 0)
        contig = bool(idx) and idx == set(range(lo, hi))
        rows[key] = {
            "items": n,
            "spans": {k: list(v) for k, v in sorted(spans.items())},
            "uncovered_idx": sorted(set(range(n)) - cov),
            "body_spans": body,
            "body_union": [lo, hi] if idx else None,
            "body_contiguous": contig,
            "body_px_count": len(idx),
            "has_man": "man" in spans,
        }
        print("[span] %-16s items=%-3d body=%-28s union=%s contig=%s"
              % (key, n, ",".join(sorted(body)) or "-",
                 [lo, hi] if idx else None, contig), flush=True)
    p = os.path.join(args.repo, "renders", "art", "minibosses", "_backread",
                     "_spanprobe.json")
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w") as fh:
        json.dump(rows, fh, indent=1)
    print("[span] wrote %s" % p, flush=True)


main()
