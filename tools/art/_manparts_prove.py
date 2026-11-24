"""_manparts_prove.py - WATCH THE `man_parts` RED FIRE, THREE WAYS.

Added 24 Nov 2026 17:0x CT with `minibosses.man_ranges`. That resolver widened
what the self_seen instrument can see - six bodies whose builders split the
figure from the gear under names other than `man` - and a widening is exactly
where an UNEARNED PASS gets in. The quiet failure to fear is not a crash: it
is a bad declaration landing in `not_measurable`, where NOTHING IS CLAIMED and
nothing is printed, so a body silently leaves measurement wearing a green file.

So the three error paths are not believed because they are written:

  A  CONTROL     every shipped builder resolved      -> 0 errors, 7 from parts
  B  MISSING     man_parts names a span that is not
                 declared                            -> RED, named, NOT absent
  C  AMBIGUOUS   a builder declares BOTH a `man`
                 span and man_parts                  -> RED (undefined figure)
  D  EMPTY       man_parts declared and empty        -> RED (claims a split
                                                       that is not there)

Arms B, C and D run against a STUB parts object, never a shipped builder, and
arm A runs first and last to prove nothing was left patched.

  blender -b -noaudio -P tools/art/_manparts_prove.py -- --repo <repo>
"""
import os
import sys
import json
import argparse

import bpy  # noqa: F401

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import minibosses as M  # noqa: E402


class _Stub(object):
    def __init__(self, spans, parts=None):
        self.spans = dict(spans)
        self.items = list(range(50))
        if parts is not None:
            self.man_parts = parts


def _control():
    rows, errs, by_src = {}, [], {"span": 0, "parts": 0, "": 0}
    for key in sorted(M.BUILDERS):
        try:
            P = M.BUILDERS[key]()
        except Exception as exc:
            errs.append("%s: builder raised: %s" % (key, exc))
            continue
        rng, src, e = M.man_ranges(P)
        by_src[src] = by_src.get(src, 0) + 1
        rows[key] = {"from": src, "ranges": rng, "errors": e,
                     "declares": hasattr(P, "man_parts")}
        errs += ["%s: %s" % (key, x) for x in e]
    return {"errors": errs, "by_source": by_src, "rows": rows,
            "declared_n": sum(1 for r in rows.values() if r["declares"]),
            "absent": sorted(k for k, r in rows.items() if r["from"] == "")}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    args = ap.parse_args(argv)

    a = _control()
    b = M.man_ranges(_Stub({"head": (0, 4)}, ("head", "trunk")))
    c = M.man_ranges(_Stub({"man": (0, 4), "head": (4, 8)}, ("head",)))
    d = M.man_ranges(_Stub({"head": (0, 4)}, ()))
    # A DELIBERATE EMPTY `man` SPAN IS NOT AN ERROR - it is the panner marker.
    e = M.man_ranges(_Stub({"man": (9, 9)}))
    a2 = _control()

    checks = []

    def ck(name, ok, why):
        checks.append({"check": name, "pass": bool(ok), "why": why})

    ck("A_control_clean", not a["errors"],
       "every shipped builder resolves with no error")
    # *** THIS CHECK WAS A LITERAL AND THE LITERAL WENT STALE IN ONE DAY. ***
    # It read `== 6` - the six bodies _spanprobe.py found on 24 Nov 17:0x - and
    # S118 then declared `man_parts` in seventeen more builders, so a CORRECT
    # widening would have turned this harness red. A count that has to be
    # hand-edited every time the thing it measures grows is the hand-written
    # census fault one level down (the `self_seen` block, 24 Nov 11:4x).
    # The invariant that does not go stale is the one this check was reaching
    # for: EVERY BUILDER THAT DECLARES A FIGURE MUST RESOLVE FROM IT. Both
    # sides are measured off the same tree in the same pass, so the check
    # cannot be satisfied by editing a number, and it goes red the moment a
    # declaration resolves to anything other than "parts" - including the
    # silent "" outcome this whole mechanism exists to abolish.
    ck("A_parts_seen", a["by_source"].get("parts", 0) == a["declared_n"],
       "every builder that declares man_parts resolves from parts: %d declared, "
       "%d resolved" % (a["declared_n"], a["by_source"].get("parts", 0)))
    ck("A_no_declaration_absent",
       not [k for k, r in a["rows"].items() if r["declares"] and r["from"] == ""],
       "and no declaring builder lands in the SILENT list: %s"
       % ([k for k, r in a["rows"].items() if r["declares"] and r["from"] == ""],))
    ck("B_missing_is_red", bool(b[2]) and b[1] == "" and not b[0],
       "a man_parts naming an undeclared span returns an ERROR and no "
       "ranges, so it CANNOT land in not_measurable: %s" % (b[2],))
    ck("B_names_the_span", bool(b[2]) and "'trunk'" in b[2][0],
       "and the error names the span that is missing")
    ck("C_ambiguous_is_red", bool(c[2]) and c[1] == "",
       "declaring both a `man` span and man_parts is an error: %s" % (c[2],))
    ck("D_empty_is_red", bool(d[2]) and d[1] == "",
       "an empty man_parts is an error, not an absence: %s" % (d[2],))
    ck("E_panner_marker_kept", e[1] == "span" and e[0] == [[9, 9]] and not e[2],
       "an EMPTY `man` span is still a deliberate marker and NOT an error - "
       "a machine with no operator cannot fail a can-you-see-the-man test")
    ck("A_control_again", not a2["errors"] and a2["by_source"] == a["by_source"],
       "nothing left patched by the stub arms")

    out = {"checks": checks, "by_source": a["by_source"],
           "declared_n": a["declared_n"],
           "absent_bodies": a["absent"],
           "parts_bodies": sorted(k for k, r in a["rows"].items()
                                  if r["from"] == "parts"),
           "span_bodies_n": a["by_source"].get("span", 0),
           "control_errors": a["errors"],
           "ok": all(c["pass"] for c in checks)}
    p = os.path.join(args.repo, "renders", "art", "minibosses", "_backread",
                     "_manparts_prove.json")
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w") as fh:
        json.dump(out, fh, indent=1)
    for c in checks:
        print("[manparts] %-20s %s  %s"
              % (c["check"], "PASS" if c["pass"] else "**FAIL**", c["why"]),
              flush=True)
    print("[manparts] by_source=%s parts=%s" % (out["by_source"],
                                                out["parts_bodies"]), flush=True)
    print("[manparts] VERDICT %s -> %s" % ("GREEN" if out["ok"] else "RED", p),
          flush=True)


main()
