"""_selfseen_merge.py - MERGE A _backread ROW INTO `_selfseen_all.json`.

*** WHY THIS FILE EXISTS, AND IT IS A FAULT OF THIS LANE'S SHIPPING PATH AND
*** NOT OF ANY INSTRUMENT. *** Found 27 Nov 2026 01:4x CT, by this lane, in
*** its own work, after the team lead charged it for the SECOND TIME IN FOUR
*** HOURS.

The self_seen chain has four links and until now only three were scripts:

  1. tools/art/_backread.py          measures one body  -> _backread_<tag>.json
  2. ** merge that row into _selfseen_all.json **       <- BY HAND. NO SCRIPT.
  3. tools/art/_selfseen_census.py   coverage           -> _selfseen_census.json
  4. tools/art/minibossfit.py        derives the block  -> _fit_report.json

Link 2 was a hand edit. A hand step in a shipping path is a step that gets
skipped, and it was skipped on the 64th body (`fanner`, 21:58 CT) and again on
the 65th (`mealman`, 00:34 CT) - both shipped, both called GREEN in their
commit subjects, both with a register that correctly read RED on the missing
cell. THE INSTRUMENTS WERE NEVER WRONG. `minibossfit.derive_self_seen` caught
it both times, named the body, and printed the command to run. What failed
twice is that a human-shaped step sat between measuring a body and being able
to read its number, and the lane shipped before taking it.

So the fix is not another assertion - there is already a correct one - it is to
DELETE THE HAND STEP. This file is link 2.

WHAT IT REFUSES TO DO, because a merge tool that can quietly lose a row would
be a worse fault than the one it fixes:
  - it never drops a row: the output row count is >= the input row count, and
    that is asserted, not hoped for;
  - it refuses a source row carrying `errors`, because a failed measurement
    merged as data is an unearned pass;
  - it refuses a row with no view carrying `man_seen` UNLESS the body is a
    declared no-man (an EMPTY man span - see _selfseen_census.py's docstring
    on `panner`), which is a statement and not an omission;
  - it STAMPS each merged row with `measured_at` if the row has none.
    `_backread.py` does not write one, and derive_self_seen reads it; an
    unstamped row is the un-ageable snapshot that started this whole family of
    faults, one level down again.
  - it appends to `provenance` rather than replacing it.

Runs with or without Blender - it imports no bpy on purpose, so it can be the
one link in the chain that does not need a 30-second Blender start:
  python3 tools/art/_selfseen_merge.py --repo <repo> --src <_backread_x.json>
  blender -b -noaudio -P tools/art/_selfseen_merge.py -- --repo <repo> --src ...
"""
import os
import sys
import json
import time
import argparse


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--src", required=True,
                    help="a _backread*.json written by tools/art/_backread.py")
    ap.add_argument("--note", default="",
                    help="one line appended to `provenance`")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args(argv)

    allp = os.path.join(args.repo, "renders", "art", "minibosses", "_backread",
                        "_selfseen_all.json")
    with open(allp) as fh:
        dst = json.load(fh)
    with open(args.src) as fh:
        src = json.load(fh)

    before = len(dst.get("rows") or {})
    # *** THE STAMP CARRIES ITS OWN OFFSET AND ZONE NAME ON PURPOSE. ***
    # cruzader's clock is CT, so localtime is CT when this runs on the machine
    # - but this file also runs on the Linux bridge, whose clock is UTC, and a
    # UTC stamp written under a sentence claiming Central is exactly the
    # future-stamp fault several lanes have now made. %z makes a wrong zone
    # VISIBLE to the reader (-0600 vs +0000) instead of plausible.
    stamp = time.strftime("%Y-%m-%dT%H:%M:%S%z", time.localtime())
    zone = time.strftime("%Z", time.localtime())

    merged, refused = [], []
    for key, row in (src.get("rows") or {}).items():
        rerrs = list(row.get("errors") or [])
        if rerrs:
            refused.append("%s: source row carries errors %s - a failed "
                           "measurement merged as data is an unearned pass"
                           % (key, rerrs))
            continue
        views = row.get("views") or {}
        cells = [v for v, c in views.items() if "man_seen" in c]
        ranges = row.get("man_ranges") or []
        empty_span = bool(row.get("man_from")) and not sum(
            max(0, b - a) for a, b in ranges)
        if not cells and not empty_span:
            refused.append("%s: no view carries `man_seen` and the body is "
                           "not a declared no-man - nothing to merge" % key)
            continue
        row = dict(row)
        if not row.get("measured_at"):
            row["measured_at"] = stamp
            row["measured_at_tz"] = zone
            row["measured_at_from"] = ("stamped by _selfseen_merge.py - "
                                       "_backread.py writes no stamp")
        dst.setdefault("rows", {})[key] = row
        merged.append("%s (%s)" % (key, ", ".join(
            "%s %.4f" % (v, views[v]["man_seen"]) for v in sorted(cells))
            or "declared no-man"))

    after = len(dst.get("rows") or {})
    # *** THE ASSERTION THAT MAKES THIS TOOL SAFE TO TRUST. *** A merge that
    # can lose a row is worse than the hand step it replaces. It cannot fire
    # as the loop stands - the loop only adds - and it is here so that a later
    # edit that makes it possible fails loudly instead of silently.
    if after < before:
        raise SystemExit("[merge] REFUSED: row count fell %d -> %d. Nothing "
                         "written." % (before, after))

    note = args.note or ("merged by tools/art/_selfseen_merge.py from %s"
                         % os.path.basename(args.src))
    dst["provenance"] = ("%s ; %s %s %s: %s"
                         % (dst.get("provenance") or "", stamp, zone, note,
                            "; ".join(merged) if merged else "nothing merged"))
    dst["errors"] = list(dst.get("errors") or []) + refused
    dst["ok"] = not dst["errors"]

    print("[merge] rows %d -> %d" % (before, after), flush=True)
    for m in merged:
        print("[merge] merged %s" % m, flush=True)
    for r in refused:
        print("[merge] REFUSED %s" % r, flush=True)
    if args.dry_run:
        print("[merge] --dry-run: nothing written", flush=True)
        return
    if refused:
        raise SystemExit("[merge] REFUSED %d row(s); nothing written. See "
                         "above." % len(refused))
    with open(allp, "w") as fh:
        json.dump(dst, fh, indent=1)
    print("[merge] wrote %s ok=%s" % (allp, dst["ok"]), flush=True)


main()
