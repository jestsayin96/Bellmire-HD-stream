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
  not_measurable - in the register, builder has NO `man` span at all: nothing
                   to split, so NOTHING IS CLAIMED. Absent, not green.
  build_failed   - the builder raised. That is RED, never "unmeasurable".

*** THE SECOND FAULT, CAUGHT 24 Nov 11:5x CT BEFORE IT SHIPPED. *** The first
cut of this census tested only `"man" in spans`, so it called `panner`
MEASURABLE, and the coverage rule in minibossfit.derive_self_seen() then
turned the whole register RED on it - AN UNEARNED FAIL on a body that is
correct. An instrument that cannot report an unearned PASS can still report an
unearned FAIL, and both are the same fault. It was found by opening the
builder and reading the comment rather than trusting my own red.

  blender -b -noaudio -P tools/art/_selfseen_census.py -- --repo <repo>
"""
import os
import sys
import json
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
                r["has_man_span"] = "man" in spans
                r["items"] = len(getattr(P, "items", []) or [])
                span = spans.get("man")
                r["man_span"] = list(span) if span else None
                # AN EMPTY SPAN IS A STATEMENT, NOT AN OMISSION. See the
                # docstring: this is what stopped an unearned RED on panner.
                r["man_span_empty"] = (bool(span is not None)
                                       and span[0] >= span[1])
            except Exception as exc:
                r["error"] = "%s: %s" % (type(exc).__name__, exc)
                r["has_man_span"] = None
                errs.append("%s: builder raised: %s" % (key, exc))
        else:
            r["has_man_span"] = None
            if key in pairs:
                errs.append("%s: in the register with NO builder" % key)
        rows[key] = r

    out = {
        "rows": rows,
        "errors": errs,
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
          "build_failed=%d"
          % (out["register_pairs"], len(out["measurable"]), len(out["no_man"]),
             len(out["not_measurable"]), len(out["build_failed"])), flush=True)
    print("[census] wrote %s" % p, flush=True)


main()
