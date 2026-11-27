"""_emptyspan_census.py - HOW GENERAL IS THE NO_MAN BRANCH? MEASURED, NOT ASSUMED.

  blender -b -noaudio -P tools/art/_emptyspan_census.py -- --repo <repo>

_backread.py gained two branches on 26 Nov 2026: a declared-EMPTY `man` span at
the END of a builder's items reads NO_MAN (an honest absence that claims
NOTHING), and an empty span with items authored after it goes RED. Writing a
branch and SAYING how many bodies reach it are different acts, and the second
one is the only one that can be checked. So this walks every builder in
M.ORDER, calls the shipped `M.man_ranges`, and reports which bodies declare an
empty range and which shape it takes - end-of-build (NO_MAN) or mid-build (RED).

It renders nothing and asserts nothing about readability. It answers one
question: WHICH BODIES CAN REACH EITHER BRANCH.
"""
import os
import sys
import json
import argparse

import bpy  # noqa: F401

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import minibosses as M  # noqa: E402


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    args = ap.parse_args(argv)
    rep = {"no_man": [], "empty_mid": [], "nonempty": [], "no_declaration": [],
           "declaration_errors": {}, "build_failed": {}, "rows": {}}
    for key in list(M.ORDER):
        try:
            P = M.BUILDERS[key]()
        except Exception as exc:
            rep["build_failed"][key] = repr(exc)
            continue
        ranges, source, errs = M.man_ranges(P)
        n = len(P.items)
        row = {"source": source, "ranges": ranges, "items": n}
        rep["rows"][key] = row
        if errs:
            rep["declaration_errors"][key] = errs
            continue
        if not source:
            rep["no_declaration"].append(key)
            continue
        empty = [r for r in ranges if r[1] <= r[0]]
        if len(empty) != len(ranges):
            rep["nonempty"].append(key)
            continue
        at_end = all(r[0] >= n for r in ranges)
        row["items_after_span"] = n - max(r[0] for r in ranges)
        (rep["no_man"] if at_end else rep["empty_mid"]).append(key)
    rep["counts"] = {k: len(rep[k]) for k in
                     ("no_man", "empty_mid", "nonempty", "no_declaration")}
    rep["counts"]["declaration_errors"] = len(rep["declaration_errors"])
    rep["counts"]["build_failed"] = len(rep["build_failed"])
    rep["counts"]["bodies"] = len(M.ORDER)
    out = os.path.join(args.repo, "renders", "art", "minibosses", "_backread",
                       "_emptyspan_census.json")
    with open(out, "w") as fh:
        json.dump(rep, fh, indent=1)
    print("[emptyspan] %s" % json.dumps(rep["counts"]), flush=True)
    print("[emptyspan] no_man=%s empty_mid=%s" % (rep["no_man"], rep["empty_mid"]),
          flush=True)


main()
