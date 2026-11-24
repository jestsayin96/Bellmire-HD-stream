"""_selfseen_census.py - WHICH BODIES THE self_seen INSTRUMENT CAN SEE AT ALL.

THE DEFECT THIS EXISTS TO MAKE IMPOSSIBLE, found 24 Nov 11:4x CT by this lane
in its own shipped work. The top-level `self_seen` block in `_fit_report.json`
was written BY HAND on 21 Nov over a 46-body house and has been CARRIED
FORWARD unchanged every run since, by minibossfit.main()'s carry-anything-not-
run-owned rule (the same rule that correctly saved `ground` from being nulled -
it is not the rule that is wrong, it is trusting a HAND-WRITTEN block to it).
The register has since grown to 55 rows. So the block states
`measured_bodies: 25`, `unmeasured_bodies: 21`, "21 of 46" - and NINE bodies,
every one shipped after 21 Nov and including the three newest in the cascade
(panner 51st, stiltman 52nd, nightman 53rd), are in `pairs` and in NEITHER
list. Not measured, and not even in the "nothing is claimed for these" list.
ABSENT, while the file reads GREEN and `unproved_cells` reads [].

That is the coverage version of trap 4: an instrument that cannot move is not
a pass, and an instrument that was never ASKED about a body cannot be cited
for it either. A hand-written census is a snapshot; this file makes it a
MEASUREMENT, taken off the builders themselves every time it runs.

THE THREE OUTCOMES ARE KEPT APART ON PURPOSE, because conflating the last two
is exactly how the nine went missing:
  measurable     - in the register, the builder declares a `man` span AND
                   that span is NON-EMPTY: there is a man to find.
  no_man         - the builder declares a `man` span that is EMPTY. THAT IS A
                   DELIBERATE MARKER, NOT A BUG, and reading the builder is
                   the only way to know it. `panner` pass 4 removed its
                   operator after an A/B - "a part whose removal changes a
                   view by nothing was contributing nothing to that view" -
                   and left `P.spans["man"] = (len(P.items), len(P.items))` to
                   say so. A machine with no operator CANNOT fail a
                   can-you-see-the-man test. Nothing claimed, NOT red.
  not_measurable - in the register, and the builder names NO figure at all -
                   no `man` span and no `man_parts`: nothing to split, so
                   NOTHING IS CLAIMED. Absent, not green. READ THE FOURTH
                   FAULT BELOW BEFORE TRUSTING THIS LIST: it has already been
                   wrong about six bodies, and being wrong in THIS direction
                   is silent.
  build_failed   - the builder raised. That is RED, never "unmeasurable".

*** THE SECOND FAULT, CAUGHT 24 Nov 11:5x CT BEFORE IT SHIPPED. *** The first
cut of this census tested only `"man" in spans`, so it called `panner`
MEASURABLE, and the coverage rule in minibossfit.derive_self_seen() then
turned the whole register RED on it - AN UNEARNED FAIL on a body that is
correct. An instrument that cannot report an unearned PASS can still report an
unearned FAIL, and both are the same fault. It was found by opening the
builder and reading the comment rather than trusting my own red.

*** THE THIRD FAULT, HANDED TO THIS LANE BY THE TEAM LEAD 24 Nov 12:34 CT,
*** AND IT IS A FAULT OF THIS FILE AND NOT ONLY OF ITS READER. *** The first
cut of this census wrote NO STAMP. `minibossfit.derive_self_seen` therefore
published `census_measured_at: "run tools/art/_selfseen_census.py"` - an
INSTRUCTION standing where a measurement time belongs. A census with no time
on it cannot be told from a fresh one, which is the same un-ageable snapshot
this file was written to abolish, one level down. It now stamps itself in
CENTRAL TIME, records the register's own mtime beside it so a reader can see
which of the two is older, and `register_pairs` lets the reader catch a census
taken over a smaller house than the one being judged.

  blender -b -noaudio -P tools/art/_selfseen_census.py -- --repo <repo>
"""
import os
import sys
import json
import time
import argparse

import bpy  # noqa: F401  (required: this module only runs inside Blender)

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import minibosses as M  # noqa: E402


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    args = ap.parse_args(argv)

    reg = os.path.join(args.repo, "renders", "art", "minibosses",
                       "_fit_report.json")
    pairs = sorted(json.load(open(reg))["pairs"].keys())

    rows, errs = {}, []
    for key in sorted(set(pairs) | set(M.BUILDERS.keys())):
        r = {"in_register": key in pairs, "in_builders": key in M.BUILDERS}
        if key in M.BUILDERS:
            try:
                P = M.BUILDERS[key]()
                spans = getattr(P, "spans", {}) or {}
                r["spans"] = sorted(spans.keys())
                r["items"] = len(getattr(P, "items", []) or [])
                # *** THE FOURTH FAULT, FOUND 24 Nov 2026 16:4x CT BY THIS LANE
                # *** IN ITS OWN SHIPPED CENSUS, ONE HOUR AFTER IT SHIPPED. ***
                # This test was `"man" in spans`, and the list it fed said of
                # 25 bodies "no `man` span at all: nothing to split, so
                # NOTHING IS CLAIMED". For SIX of them that was false and the
                # FOUR NEWEST BODIES IN THE HOUSE were among them - iceman the
                # 54th and straker the 55th, ticked this very hour. Their
                # builders split the figure from the gear seven ways, under
                # `trunk`/`head`/`arms`/`legs` or `man_lower`/`tool_arms`
                # instead of `man`, and a span-name match cannot see it.
                # The resolution now lives in ONE place, minibosses.man_ranges,
                # read by this census and by _backread's splitter, so the
                # instrument and its coverage report can never disagree about
                # what the figure is. The builder states its own parts; this
                # file guesses no names.
                ranges, source, rerrs = M.man_ranges(P)
                r["man_from"] = source
                r["man_ranges"] = ranges
                r["man_parts"] = list(getattr(P, "man_parts", None) or [])
                r["has_man_span"] = bool(source)
                span = spans.get("man")
                r["man_span"] = list(span) if span else None
                # AN EMPTY SPAN IS A STATEMENT, NOT AN OMISSION. See the
                # docstring: this is what stopped an unearned RED on panner.
                r["man_span_empty"] = bool(source) and not sum(
                    max(0, b - a) for a, b in ranges)
                for e in rerrs:
                    # A BAD DECLARATION IS RED, NOT ABSENT. `has_man_span`
                    # False would file it under not_measurable, where nothing
                    # is claimed and nothing is reported - the quiet outcome
                    # this census exists to abolish. It goes in errors, which
                    # turns `ok` False and raises it in derive_self_seen.
                    r["error"] = e
                    errs.append("%s: %s" % (key, e))
            except Exception as exc:
                r["error"] = "%s: %s" % (type(exc).__name__, exc)
                r["has_man_span"] = None
                errs.append("%s: builder raised: %s" % (key, exc))
        else:
            r["has_man_span"] = None
            if key in pairs:
                errs.append("%s: in the register with NO builder" % key)
        rows[key] = r

    # *** A REAL STAMP, IN CENTRAL TIME. *** cruzader's clock is CT, so
    # localtime is CT; the offset is written out so no reader has to assume
    # it, and the register's own mtime sits beside it so "which is older" is
    # answerable without a second command.
    now = time.time()
    try:
        reg_m = os.path.getmtime(reg)
    except OSError:
        reg_m = None
    out = {
        "rows": rows,
        "errors": errs,
        "measured_at": time.strftime("%Y-%m-%dT%H:%M:%S%z", time.localtime(now)),
        "measured_at_tz": time.strftime("%Z", time.localtime(now)),
        "measured_at_epoch": now,
        "register_mtime_epoch": reg_m,
        "register_mtime": (time.strftime("%Y-%m-%dT%H:%M:%S%z",
                                         time.localtime(reg_m))
                           if reg_m else None),
        "register_pairs": len(pairs),
        "measurable": sorted(k for k, r in rows.items()
                             if r["in_register"] and r.get("has_man_span") is True
                             and not r.get("man_span_empty")),
        "no_man": sorted(k for k, r in rows.items()
                         if r["in_register"] and r.get("man_span_empty")),
        "not_measurable": sorted(k for k, r in rows.items()
                                 if r["in_register"] and r.get("has_man_span") is False),
        "build_failed": sorted(k for k, r in rows.items()
                               if r["in_register"] and r.get("has_man_span") is None),
    }
    out["ok"] = not errs
    p = os.path.join(args.repo, "renders", "art", "minibosses", "_backread",
                     "_selfseen_census.json")
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w") as fh:
        json.dump(out, fh, indent=1)
    print("[census] pairs=%d measurable=%d no_man=%d not_measurable=%d "
          "build_failed=%d at=%s"
          % (out["register_pairs"], len(out["measurable"]), len(out["no_man"]),
             len(out["not_measurable"]), len(out["build_failed"]),
             out["measured_at"]), flush=True)
    covered = (set(out["measurable"]) | set(out["no_man"])
               | set(out["not_measurable"]) | set(out["build_failed"]))
    missing = sorted(set(pairs) - covered)
    print("[census] pairs in NO list: %d %s"
          % (len(missing), missing if missing else ""), flush=True)
    print("[census] wrote %s" % p, flush=True)


main()
