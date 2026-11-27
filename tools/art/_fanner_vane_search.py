"""_fanner_vane_search.py - PICK THE FANNER'S VANE LAYOUT BY MEASUREMENT.

  blender -b -noaudio -P tools/art/_fanner_vane_search.py -- --repo <repo>

Pass 4. Three passes chose this layout by argument and by eye and all three
were wrong in a different way; the per-vane probe in `_fanner_vane_ab.py`
finally measured it and found one vane at ONE PIXEL. So the layout is chosen
the only way that has ever worked on this gauge: run candidates through the
PROBE and keep one that reads FOUR in every view with no fused pair.

It drives `minibosses._FANNER_VANES`, the real builder's own hook, so the
layout that wins is measured through the builder that ships. A layout measured
through a copy of the builder is a number about nothing.

RED ON EMPTY is inherited from the probe and re-asserted here: a candidate
that renders nothing scores 0 and can never win, and if NO candidate reaches
four the script says so and exits without writing a winner.
"""
import os
import sys
import json
import math
import argparse

import bpy
import numpy as np
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordlib as L          # noqa: E402
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402
import minibossgen as MG     # noqa: E402
import _fanner_vane_ab as AB  # noqa: E402  (the probe, re-used not re-written)

KEY = "fanner"

# Candidates. Every one puts all four vanes on the FORWARD arc, because the
# measurement showed the back of the ring is where the man is; they differ in
# how they answer LATERAL CROWDING, which is the fault that remains once the
# body can no longer occlude anything.
CANDIDATES = [
    # ROUND 3 - NARROW THE BLADE. Round 2 solved occlusion outright (weakest
    # vane went from 1 px to 880-1814 px) and every failure that remained was
    # FUSION. The arithmetic says why and no angle set can argue with it: the
    # projected ring is about 0.74 m across, and four blades 0.168 m wide fill
    # 0.67 m of that, so neighbouring footprints MUST touch. Width is the only
    # free variable left, so it is the one that moves - one change at a time.
    ("ring_a_w110", ((79.0, 0.300, 0.110), (134.0, 0.300, 0.110), (262.0, 0.300, 0.110), (310.0, 0.300, 0.110))),
    ("ring_a_w090", ((79.0, 0.300, 0.090), (134.0, 0.300, 0.090), (262.0, 0.300, 0.090), (310.0, 0.300, 0.090))),
    ("ring_a_w075", ((79.0, 0.300, 0.075), (134.0, 0.300, 0.075), (262.0, 0.300, 0.075), (310.0, 0.300, 0.075))),
    ("ring_c_w090", ((34.0, 0.300, 0.090), (85.0, 0.300, 0.090), (127.0, 0.300, 0.090), (299.0, 0.300, 0.090))),
    ("ring_c_w075", ((34.0, 0.300, 0.075), (85.0, 0.300, 0.075), (127.0, 0.300, 0.075), (299.0, 0.300, 0.075))),
    ("ring_d_w075", ((74.0, 0.300, 0.075), (148.0, 0.300, 0.075), (266.0, 0.300, 0.075), (306.0, 0.300, 0.075))),
]


def _args():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--res", default="760x1040")
    return ap.parse_args(a)


def score(repo, resx, resy, outdir, name, aura):
    """The probe, per view, for ONE layout. Returns the per-view counts."""
    views = {}
    errors = []
    for vname, az, el in AB.VIEWS:
        objs, info, bb = AB.build(None)
        mnv, mxv, _ = G.world_bounds(objs)
        cen = (Vector(mnv) + Vector(mxv)) * 0.5
        rad = max((Vector(mxv) - Vector(mnv)).length * 0.5, 0.5)
        ortho = (Vector(mxv) - Vector(mnv)).length * 1.12
        AB.rig(bpy.context.scene, cen, rad, resx, resy, aura)
        base_p = os.path.join(outdir, "s_%s_base_%s.png" % (name, vname))
        AB.shoot(base_p, cen, rad, az, el, ortho)
        A = G.read_png(base_p)
        body_px = int((A[..., 3] > 0.5).sum())
        if body_px < 2000:
            errors.append("%s/%s: base body %d px - empty or mis-aimed"
                          % (name, vname, body_px))
        masks, raw = {}, {}
        for i in range(AB.NVANE):
            objs2, _i2, pb = AB.build(i)
            if AB.PROBE_N[0] != 1:
                errors.append("%s/%s vane %d: probe took %d items"
                              % (name, vname, i, AB.PROBE_N[0]))
            if pb != bb:
                errors.append("%s/%s vane %d: BOUNDS MOVED - camera not locked"
                              % (name, vname, i))
            mn2, mx2, _ = G.world_bounds(objs2)
            cen2 = (Vector(mn2) + Vector(mx2)) * 0.5
            rad2 = max((Vector(mx2) - Vector(mn2)).length * 0.5, 0.5)
            AB.rig(bpy.context.scene, cen2, rad2, resx, resy, aura)
            pp = os.path.join(outdir, "s_%s_v%d_%s.png" % (name, i, vname))
            AB.shoot(pp, cen2, rad2, az, el, ortho)
            m = AB.probe_mask(base_p, pp)
            masks[i], raw[i] = m, int(m.sum())
        fused = []
        for i in range(AB.NVANE):
            for j in range(i + 1, AB.NVANE):
                if raw[i] <= 0 or raw[j] <= 0:
                    continue
                if (AB.dilate(masks[i], AB.SEP_DILATE)
                        & AB.dilate(masks[j], AB.SEP_DILATE)).any():
                    fused.append([i, j])
        present = [i for i in range(AB.NVANE) if raw[i] > 0]
        med = float(np.median([raw[i] for i in present])) if present else 0.0
        bar = max(AB.MIN_PX, AB.MIN_FRAC * med)
        big = [i for i in present if raw[i] >= bar]
        groups = []
        for i in big:
            hit = None
            for g in groups:
                if any([min(i, k), max(i, k)] in fused for k in g):
                    hit = g
                    break
            if hit is None:
                groups.append([i])
            else:
                hit.append(i)
        views[vname] = {"vane_px": raw, "bar_px": round(bar, 1),
                        "fused_pairs": fused, "count_read": len(groups),
                        "min_px": (min(raw.values()) if raw else 0)}
    worst = min(v["count_read"] for v in views.values())
    weakest = min(v["min_px"] for v in views.values())
    return {"views": views, "count_min": worst, "weakest_vane_px": weakest,
            "errors": errors}


def main():
    args = _args()
    resx, resy = [int(v) for v in args.res.lower().split("x")]
    outdir = os.path.join(args.repo, "renders", "art", "minibosses",
                          "_vane_search")
    os.makedirs(outdir, exist_ok=True)
    aura = M.CANON[KEY][3]
    rows = {}
    for name, layout in CANDIDATES:
        M._FANNER_VANES = layout
        r = score(args.repo, resx, resy, outdir, name, aura)
        r["layout"] = layout
        rows[name] = r
        print("[search] %-18s count_min=%d weakest=%5d errs=%d  %s"
              % (name, r["count_min"], r["weakest_vane_px"],
                 len(r["errors"]),
                 {k: v["count_read"] for k, v in r["views"].items()}),
              flush=True)
    # a winner must read FOUR EVERYWHERE and carry no error; among those, the
    # one whose WEAKEST vane is strongest, because that is the margin a
    # viewer at stream distance actually has.
    ok = [(n, r) for n, r in rows.items()
          if r["count_min"] == AB.NVANE and not r["errors"]]
    ok.sort(key=lambda kv: -kv[1]["weakest_vane_px"])
    rep = {"key": KEY, "candidates": rows,
           "winner": (ok[0][0] if ok else None),
           "winner_layout": (ok[0][1]["layout"] if ok else None),
           "rule": "count_read == 4 in front, side, three_quarter AND back, "
                   "no fused pair, no error; tie-broken on the WEAKEST vane's "
                   "visible footprint - the margin a viewer actually has.",
           "ok": bool(ok)}
    out = os.path.join(outdir, "_vane_search.json")
    with open(out, "w") as fh:
        json.dump(rep, fh, indent=1)
    print("[search] winner=%r wrote %s" % (rep["winner"], out), flush=True)
    if not ok:
        print("[search] NO CANDIDATE READS FOUR EVERYWHERE - nothing to apply",
              flush=True)


main()
