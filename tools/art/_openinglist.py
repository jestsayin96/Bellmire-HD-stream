#!/usr/bin/env python3
"""_openinglist.py - the 88-OPENING LIST: every unbacked opening in shipped
town art, NAMED and PLACED, so the fix can be APPLIED instead of only counted.

Art lane, 28 Nov 2026, SEVENTH consecutive hour of the house-wide
Blender/Godot/git bridge outage. Rowed by the team lead's 05:58 block:
"Keep to the town building ladder on paper: the chapel/market tier specs and
the 88-opening list."

WHY THIS EXISTS. `docs/art/TOWN_LATTICE_AUDIT.md` finding 4 established the
COUNT - 672 wall-family openings swept, 88 with nothing behind them - but it
published only module x file totals. You cannot apply a fix to a total. A run
with a bridge needs to know WHICH node, in WHICH mesh, at WHICH world
coordinate, facing WHICH way, and how big the backing panel must be. That is
this file's whole job.

IT INVENTS NO GEOMETRY MATHS. Every number comes from `_modcover.throughlight`,
the instrument validated in that doc three ways (known-by-render lattice/solid
pair separating 1.0000 vs 0.6847, margin 0.3153; resolution-stable over grid
64-384; and 310 solid-wall instances reading hole_frac exactly 0.0000 as a
negative control). This adds a driver and a report, not a method.

*** WHAT IT CANNOT SEE - INHERITED IN FULL, AND THE LIMIT IS THE POINT. ***
It NEVER RENDERS. It is blind to colour and material; blind to whether a
progression reads at a glance; blind to assembly faults such as a gable hole,
which belong to no single node; blind to backface culling (a one-sided quad
reads covered and can still vanish); and deliberately blind deeper than
`depth` metres, because a solid far wall does not close a near hole - looking
into the building's inside IS the open-shed look.
*** A GREEN SHEET HERE IS NOT A FIT PROOF. The fix still needs a render that a
*** human eye looks at, and the row forbids touching a shipped .glb until then.

RED ON EMPTY, inherited: a sweep that finds zero openings is an ERROR, not a
clean pass. A list computed over nothing reads clean and means nothing.

THREE GUARDS OF ITS OWN:
 1. SELF-VALIDATION FROM THE EMITTED DATA. It recomputes the known-by-picture
    separation out of the very records it is about to print, and REFUSES to
    print the list if the margin falls under 0.20.
 2. REPRODUCTION CHECK. It re-derives finding 4's published per-module totals
    and says GREEN or DISAGREES. If this list and the published aggregate
    disagree, one of them is wrong and the disagreement is the finding - it is
    not smoothed over.
 3. THRESHOLD SENSITIVITY, because "unbacked" is a THRESHOLD and the count
    depends on it. The counts are reported at four thresholds, so nobody reads
    88 as a fact of nature.
"""
import sys, os, json, argparse, statistics

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _modcover import throughlight

WALL_MODULES = [
    "Wall_Plaster_WoodGrid",
    "Wall_UnevenBrick_Door_Round",
    "Wall_Plaster_Window_Wide_Round",
    "Wall_UnevenBrick_Window_Wide_Round",
    "Wall_Plaster_Door_Flat",
    "Wall_Plaster_Window_Wide_Flat",
    "Wall_UnevenBrick_Window_Thin_Round",
    "Wall_Plaster_Straight",
    "Wall_UnevenBrick_Straight",
]

PUBLISHED = {
    "Wall_Plaster_WoodGrid": (66, 61),
    "Wall_UnevenBrick_Door_Round": (17, 16),
    "Wall_Plaster_Window_Wide_Round": (79, 6),
    "Wall_UnevenBrick_Window_Wide_Round": (45, 4),
    "Wall_Plaster_Door_Flat": (1, 1),
    "Wall_Plaster_Window_Wide_Flat": (46, 0),
    "Wall_UnevenBrick_Window_Thin_Round": (108, 0),
    "Wall_Plaster_Straight": (80, 0),
    "Wall_UnevenBrick_Straight": (230, 0),
}
PUBLISHED_TOTAL = (672, 88)

THRESH = 0.18
THRESH_SWEEP = [0.05, 0.10, 0.18, 0.25]

BY_DESIGN_OPEN = {
    "Wall_UnevenBrick_Door_Round", "Wall_Plaster_Door_Flat",
    "Wall_Plaster_Window_Wide_Round", "Wall_UnevenBrick_Window_Wide_Round",
    "Wall_Plaster_Window_Wide_Flat", "Wall_UnevenBrick_Window_Thin_Round",
}


def sweep_all(files, grid=128, depth=1.0):
    rows, errors, absent = [], [], []
    for path in files:
        fn = os.path.basename(path)
        for mod in WALL_MODULES:
            try:
                r = throughlight(path, mod, grid=grid, depth=depth)
            except Exception as e:
                errors.append("EXCEPTION %s / %s: %s: %s"
                              % (fn, mod, type(e).__name__, e))
                continue
            if not r["bays"]:
                absent.append("%s / %s" % (fn, mod))
                continue
            for b in r["bays"]:
                if b.get("hole_frac") is None:
                    errors.append("RED: %s / %s node %s has no hole_frac: %s"
                                  % (fn, mod, b["node"], b.get("errors")))
                    continue
                rows.append({
                    "file": fn, "module": mod, "node": b["node"],
                    "name": b["name"], "hole_frac": b["hole_frac"],
                    "cover_self": b["cover_self"],
                    "centre": b["centre"], "band_y": b["band_y"],
                    "normal_axis": b["normal_axis"],
                    "normal_centre": b["normal_centre"],
                    "size_inplane": b["size_inplane"],
                    "axes_inplane": b["axes_inplane"],
                    "by_design_open": mod in BY_DESIGN_OPEN,
                    "bay_errors": b["errors"],
                })
            errors += [e for e in r["errors"] if "RED ON EMPTY: zero instances" not in e]
    return rows, errors, absent


def self_validate(rows):
    lat = [r["cover_self"] for r in rows
           if r["module"] == "Wall_Plaster_WoodGrid" and r["cover_self"] is not None]
    sol = [r["cover_self"] for r in rows
           if r["module"] == "Wall_Plaster_Straight" and r["cover_self"] is not None]
    if not lat or not sol:
        return {"verdict": "RED", "why": "RED ON EMPTY: the validation pair is "
                "absent from the emitted rows (lattice n=%d, solid n=%d), so the "
                "list cannot be checked against the one truth that came from a "
                "picture." % (len(lat), len(sol))}
    lm, sm = statistics.median(lat), statistics.median(sol)
    margin = round(sm - lm, 4)
    return {"verdict": "GREEN" if margin >= 0.20 else "RED",
            "lattice_cover_med": round(lm, 4), "solid_cover_med": round(sm, 4),
            "margin": margin, "lattice_n": len(lat), "solid_n": len(sol),
            "why": ("separates the pair whose truth came from a RENDER: solid "
                    "%.4f vs lattice %.4f, margin %.4f (>= 0.20 required)"
                    % (sm, lm, margin))}


def reproduce(rows, thresh=THRESH):
    got, disagree = {}, []
    for mod in WALL_MODULES:
        mr = [r for r in rows if r["module"] == mod]
        n = len(mr)
        ub = sum(1 for r in mr if r["hole_frac"] > thresh)
        got[mod] = (n, ub)
        if mod in PUBLISHED and PUBLISHED[mod] != (n, ub):
            disagree.append({"module": mod, "published": list(PUBLISHED[mod]),
                             "this_list": [n, ub]})
    tot = (sum(v[0] for v in got.values()), sum(v[1] for v in got.values()))
    if tot != PUBLISHED_TOTAL:
        disagree.append({"module": "TOTAL", "published": list(PUBLISHED_TOTAL),
                         "this_list": list(tot)})
    return {"verdict": "GREEN" if not disagree else "DISAGREES",
            "threshold": thresh, "per_module": {k: list(v) for k, v in got.items()},
            "total": list(tot), "published_total": list(PUBLISHED_TOTAL),
            "disagreements": disagree,
            "why": ("a list that cannot re-derive the aggregate it came from is "
                    "wrong somewhere, and which of the two is wrong is then the "
                    "finding - it is not smoothed over.")}


def sensitivity(rows):
    out = {}
    for t in THRESH_SWEEP:
        out["%.2f" % t] = sum(1 for r in rows if r["hole_frac"] > t)
    near = sorted((r["hole_frac"] for r in rows
                   if abs(r["hole_frac"] - THRESH) <= 0.02))
    return {"unbacked_at": out,
            "n_within_0.02_of_thresh": len(near),
            "their_hole_fracs": near[:40],
            "why": ("if many openings sit within a hair of the threshold, the "
                    "count is a choice and not a fact, and that must be visible.")}


def markdown(res):
    L = []
    L.append("# THE %d-OPENING LIST - every unbacked opening in shipped town art,"
             % res["n_unbacked"])
    L.append("# NAMED, PLACED and SIZED, so a bridge-up run can APPLY the fix.")
    L.append("")
    L.append("Generated by `tools/art/_openinglist.py` off `_modcover.throughlight`.")
    L.append("")
    L.append("`hole_frac` = fraction of the opening's own in-plane window with NO "
             "geometry within %.1f m. UNBACKED means hole_frac > %.2f "
             "(`hallgen.py`'s own solidity gate, so this list is comparable with "
             "the generator that will consume it)." % (res["depth_m"], res["threshold_unbacked"]))
    L.append("")
    L.append("**NOT A FIT PROOF.** %s" % res["blindness"])
    L.append("")
    v, rp = res["validation"], res["reproduction"]
    L.append("- self-validation: **%s** - %s" % (v["verdict"], v["why"]))
    L.append("- reproduction of finding 4's published aggregate: **%s** "
             "(total %s vs published %s)"
             % (rp["verdict"], rp["total"], rp["published_total"]))
    if rp["disagreements"]:
        L.append("")
        L.append("  *** DISAGREEMENTS - read these before trusting either number ***")
        L.append("")
        for d in rp["disagreements"]:
            L.append("  - `%s`: published %s, this list %s"
                     % (d["module"], d["published"], d["this_list"]))
    s = res["sensitivity"]
    L.append("- threshold sensitivity: " + ", ".join(
        "%s -> %d" % (k, n) for k, n in sorted(s["unbacked_at"].items())))
    L.append("- openings within 0.02 of the threshold: **%d**"
             % s["n_within_0.02_of_thresh"])
    L.append("")
    byfile = {}
    for r in res["openings"]:
        byfile.setdefault(r["file"], []).append(r)
    for fn in sorted(byfile, key=lambda f: (-len(byfile[f]), f)):
        rs = byfile[fn]
        L.append("## %s - %d unbacked" % (fn, len(rs)))
        L.append("")
        L.append("| node | module | hole | centre x,y,z | normal | in-plane WxH | open by design |")
        L.append("|---|---|---|---|---|---|---|")
        for r in sorted(rs, key=lambda r: -r["hole_frac"]):
            L.append("| %d `%s` | %s | **%.4f** | %.2f, %.2f, %.2f | %s @ %.3f | %.2f x %.2f | %s |"
                     % (r["node"], r["name"], r["module"].replace("Wall_", ""),
                        r["hole_frac"], r["centre"][0], r["centre"][1], r["centre"][2],
                        r["normal_axis"], r["normal_centre"],
                        r["size_inplane"][0], r["size_inplane"][1],
                        "yes" if r["by_design_open"] else "no"))
        L.append("")
    return "\n".join(L) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("glb", nargs="+")
    ap.add_argument("--grid", type=int, default=128)
    ap.add_argument("--depth", type=float, default=1.0)
    ap.add_argument("--out")
    ap.add_argument("--md")
    a = ap.parse_args()

    rows, errors, absent = sweep_all(a.glb, a.grid, a.depth)

    res = {"n_meshes": len(a.glb), "n_openings": len(rows),
           "threshold_unbacked": THRESH, "depth_m": a.depth, "grid": a.grid,
           "errors": errors, "absent_pairs": len(absent),
           "blindness": ("NEVER RENDERS. Blind to colour, material, whether a "
                         "progression reads, assembly faults such as a gable "
                         "hole, backface culling, and anything deeper than "
                         "depth_m. NOT a fit proof.")}

    if not rows:
        res["validation"] = {"verdict": "RED", "why": "RED ON EMPTY: zero "
                             "openings found across %d meshes. A list computed "
                             "over nothing reads clean and means nothing."
                             % len(a.glb)}
        res["openings"] = "WITHHELD"
    else:
        res["validation"] = self_validate(rows)
        res["reproduction"] = reproduce(rows)
        res["sensitivity"] = sensitivity(rows)
        if res["validation"]["verdict"] != "GREEN":
            res["openings"] = "WITHHELD - instrument failed self-validation"
        else:
            unb = [r for r in rows if r["hole_frac"] > THRESH]
            unb.sort(key=lambda r: (-r["hole_frac"], r["file"], r["node"]))
            res["n_unbacked"] = len(unb)
            res["backed_count"] = len(rows) - len(unb)
            res["openings"] = unb

    txt = json.dumps(res, indent=1)
    if a.out:
        d = os.path.dirname(a.out)
        if d:
            os.makedirs(d, exist_ok=True)
        open(a.out, "w").write(txt)
    if a.md and isinstance(res.get("openings"), list):
        open(a.md, "w").write(markdown(res))
    print(json.dumps({k: res[k] for k in res if k != "openings"}, indent=1)[:3500])
    return 0 if res["validation"]["verdict"] == "GREEN" else 2


if __name__ == "__main__":
    sys.exit(main())
