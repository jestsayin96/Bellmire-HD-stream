"""_selfseen_prove.py - FIRE THE CENSUS-COVERAGE RED, AND ITS THREE SIBLINGS.

A gate that has never been seen to fail is not known to be able to. On 24 Nov
2026 11:3x CT this lane shipped `minibossfit.derive_self_seen` to stop a
hand-written census going stale in silence, and one hour later the team lead
found the SAME fault one level down in it: the three census lists were
INTERSECTED with `pairs` and nothing asserted they COVERED it. Today they do,
all 55 rows - which is exactly how the hand-written block read on 21 Nov,
three days before nine bodies were found hiding behind it.

So the assertion that closes it is not believed here because it is written. It
is WATCHED TO FIRE, four ways, against the real register and the real census:

  A  CONTROL          real census, untouched           -> expect GREEN
  B  UNCENSUSED       one key dropped from every list  -> expect RED, that key
  C  UNSTAMPED        measured_at stripped off a copy  -> expect RED, stamp
  D  WRONG HOUSE      a 56th row the census never saw  -> expect RED x2
                      (that row uncensused, AND register_pairs 55 != 56)

Arms C and D work on a COPY of the census in a temp tree: nothing this script
runs touches a shipped file, and arm A proves that by running first and last.

  blender -b -noaudio -P tools/art/_selfseen_prove.py -- --repo <repo>
"""
import os
import sys
import json
import shutil
import tempfile
import argparse

import bpy  # noqa: F401  (required: minibossfit only imports inside Blender)

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import minibossfit as F  # noqa: E402

SUB = os.path.join("renders", "art", "minibosses", "_backread")


def _rep(repo):
    reg = os.path.join(repo, "renders", "art", "minibosses",
                       "_fit_report.json")
    pairs = json.load(open(reg))["pairs"]
    return {"ok": True, "errors": [], "pairs": pairs}


def _arm(name, repo, pairs_extra=None, prove_key="", strip_stamp=False):
    rep = _rep(repo)
    if pairs_extra:
        rep["pairs"].update(pairs_extra)
    F.PROVE_CENSUS_RED = prove_key
    use = repo
    tmp = None
    if strip_stamp:
        tmp = tempfile.mkdtemp(prefix="selfseen_prove_")
        d = os.path.join(tmp, SUB)
        os.makedirs(d)
        for fn in ("_selfseen_all.json", "_selfseen_census.json"):
            src = os.path.join(repo, SUB, fn)
            if os.path.exists(src):
                shutil.copy(src, os.path.join(d, fn))
        cp = os.path.join(d, "_selfseen_census.json")
        cj = json.load(open(cp))
        cj.pop("measured_at", None)
        json.dump(cj, open(cp, "w"), indent=1)
        use = tmp
    try:
        blk = F.derive_self_seen(rep, use)
    finally:
        F.PROVE_CENSUS_RED = ""
        if tmp:
            shutil.rmtree(tmp, ignore_errors=True)
    return {
        "arm": name,
        "verdict": blk.get("verdict"),
        "rep_ok": rep["ok"],
        "pairs_seen": len(rep["pairs"]),
        "census_measured_at": blk.get("census_measured_at"),
        "census_register_pairs": blk.get("census_register_pairs"),
        "census_covers_register": blk.get("census_covers_register"),
        "uncensused": blk.get("uncensused"),
        "uncovered": blk.get("uncovered"),
        "build_failed": blk.get("build_failed"),
        "measured_bodies": blk.get("measured_bodies"),
        "errors": rep["errors"],
    }


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--drop", default="",
                    help="key for arm B; default = the last register row")
    args = ap.parse_args(argv)

    reg = os.path.join(args.repo, "renders", "art", "minibosses",
                       "_fit_report.json")
    keys = sorted(json.load(open(reg))["pairs"].keys())
    drop = args.drop or keys[-1]

    arms = [
        _arm("A_control", args.repo),
        _arm("B_uncensused", args.repo, prove_key=drop),
        _arm("C_unstamped", args.repo, strip_stamp=True),
        _arm("D_wrong_house", args.repo,
             pairs_extra={"_prove_56th": {"ratio": 1.0}}),
        _arm("A_control_again", args.repo),
    ]
    by = {a["arm"]: a for a in arms}

    # WHAT EACH ARM MUST SHOW. An arm that comes back the wrong colour means
    # the assertion is not the assertion this file claims it is.
    checks = []

    def ck(name, ok, why):
        checks.append({"check": name, "pass": bool(ok), "why": why})

    a, b, c, d, a2 = (by["A_control"], by["B_uncensused"], by["C_unstamped"],
                      by["D_wrong_house"], by["A_control_again"])
    ck("A GREEN on the real census", a["verdict"] == "GREEN",
       "the shipped tree must pass its own gate: %s" % a["verdict"])
    ck("A carries a REAL stamp", bool(a["census_measured_at"])
       and "run tools" not in str(a["census_measured_at"]),
       "census_measured_at = %r" % (a["census_measured_at"],))
    ck("A says the census covers the register",
       a["census_covers_register"] is True,
       "census_covers_register = %r" % (a["census_covers_register"],))
    ck("B RED", b["verdict"] == "RED", "verdict = %s" % b["verdict"])
    ck("B names the dropped key and nothing else",
       b["uncensused"] == [drop],
       "uncensused = %r (dropped %r)" % (b["uncensused"], drop))
    ck("B reason string is the coverage one",
       any("in NO self_seen census list" in e and drop in e
           for e in b["errors"]),
       "errors = %r" % (b["errors"][:3],))
    ck("C RED on the missing stamp", c["verdict"] == "RED"
       and any("NO measured_at stamp" in e for e in c["errors"]),
       "verdict %s errors %r" % (c["verdict"], c["errors"][:3]))
    ck("D RED twice - the 56th row AND the row count",
       d["verdict"] == "RED" and d["uncensused"] == ["_prove_56th"]
       and any("different house" in e for e in d["errors"]),
       "uncensused %r errors %r" % (d["uncensused"], d["errors"][:4]))
    ck("the arms left the shipped tree alone",
       a2["verdict"] == a["verdict"] and a2["errors"] == a["errors"]
       and a2["census_measured_at"] == a["census_measured_at"],
       "A again = %s / %d errors" % (a2["verdict"], len(a2["errors"])))

    out = {"drop_key": drop, "register_rows": len(keys), "arms": arms,
           "checks": checks,
           "ok": all(ch["pass"] for ch in checks)}
    p = os.path.join(args.repo, SUB, "_selfseen_prove.json")
    os.makedirs(os.path.dirname(p), exist_ok=True)
    json.dump(out, open(p, "w"), indent=1)
    for ch in checks:
        print("[prove] %-4s %s | %s"
              % ("PASS" if ch["pass"] else "FAIL", ch["check"], ch["why"]),
              flush=True)
    print("[prove] %s  wrote %s" % ("ALL ARMS AS EXPECTED" if out["ok"]
                                    else "*** AN ARM IS WRONG ***", p),
          flush=True)


main()
