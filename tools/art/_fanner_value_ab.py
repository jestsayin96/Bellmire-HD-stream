"""_fanner_value_ab.py - DOES THE HEARTH OUT-READ THE FACE? Pass 4, fault 4.

  blender -b -noaudio -P tools/art/_fanner_value_ab.py -- --repo <repo>

THE FAULT, IN MY OWN WORDS FROM PASS 3: "THE EYES ARE THE SAME WARM TONE AS THE
HEARTH, so face and fire read as one material. The hearth should out-read the
eyes and currently ties."

IT WAS NOT A NEAR-MISS, IT WAS AN IDENTITY. Both features were slotted 'glow',
so they were THE SAME MATERIAL - same rgb, same emission strength. No render
could ever have separated them and no amount of looking would have fixed it by
moving geometry. The eyes now carry their own emissive slot, 'ember'.

AND THE ALBEDO RATIO IS NOT THE ANSWER EITHER. (1.000,0.520,0.180) against
(0.780,0.170,0.090) is a 2.03x luma step ON PAPER, and paper is not what a
viewer sees: these are EMISSIVE materials at different strengths, run through
a view transform, one of them recessed under a rim that shades it. So this
measures the PIXELS - each feature's own visible footprint, found by the probe,
and the mean luma inside it.

RED, NOT BLIND, ON EVERY WAY IT CAN FAIL:
  - either footprint under 40 px        -> RED (the probe found nothing, and a
                                           luma over an empty mask is a number
                                           about nothing)
  - probe item count not as expected    -> RED (grabbed the wrong geometry)
  - BOUNDS MOVED between variants       -> RED (the locked camera is a lie)
  - hearth luma <= eyes luma            -> RED, the fault unfixed: the mechanic
                                           must out-read the face.
"""
import os
import sys
import json
import argparse

import bpy
import numpy as np
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordlib as L          # noqa: E402
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402
import minibossgen as MG     # noqa: E402

KEY = "fanner"
WHICH = [None]              # "eyes" | "hearth" | None
PROBE_N = [0]
_REAL_BUILDER = M.BUILDERS[KEY]
_REAL_MERGE = M.merge_objs

# the eyes are the two 'ember' spheres in the head span; the hearth is the
# 'glow' dome in the basket span. Both counts are ASSERTED.
WANT = {"eyes": 2, "hearth": 1}


def _builder():
    P = _REAL_BUILDER()
    PROBE_N[0] = 0
    w = WHICH[0]
    if w is None:
        return P
    span, slot = ("head", 'ember') if w == "eyes" else ("basket", 'glow')
    a, b = P.spans[span]
    for i in range(a, b):
        verts, faces, sl = P.items[i]
        if sl != slot:
            continue
        P.items[i] = (verts, faces, 'probe')
        PROBE_N[0] += 1
    return P


def _merge(key, items, mats, suffix=None, vcols=None):
    probe_items = [it for it in items if it[2] == 'probe']
    rest = [it for it in items if it[2] != 'probe']
    objs = _REAL_MERGE(key, rest, mats, suffix=suffix, vcols=vcols)
    if probe_items:
        gv, gf = [], []
        for verts, faces, _ in probe_items:
            off = len(gv)
            gv.extend(verts)
            gf.extend([tuple(i + off for i in f) for f in faces])
        objs.append(L.make(key + "_probe", gv, gf,
                           L.mat_glow(key + "_probe", (1.0, 0.0, 1.0), 3.2)))
    return objs


M.BUILDERS[KEY] = _builder
M.merge_objs = _merge
MG.M.merge_objs = _merge


def _args():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--res", default="760x1040")
    return ap.parse_args(a)


def build(which=None):
    G.purge()
    WHICH[0] = which
    objs, info = MG.build_miniboss(KEY)
    mn, mx, _ = G.world_bounds(objs)
    return objs, info, (tuple(round(c, 5) for c in mn),
                        tuple(round(c, 5) for c in mx))


def lum(a):
    return 0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]


def main():
    args = _args()
    resx, resy = [int(v) for v in args.res.lower().split("x")]
    outdir = os.path.join(args.repo, "renders", "art", "minibosses", "_value_ab")
    os.makedirs(outdir, exist_ok=True)
    aura = M.CANON[KEY][3]
    import _fanner_vane_ab as AB
    errors = {}
    out = {}
    for vname, az, el in [("front", 0.0, 0.0), ("three_quarter", 45.0, 0.0)]:
        objs, info, bb = build(None)
        mn, mx, _ = G.world_bounds(objs)
        cen = (Vector(mn) + Vector(mx)) * 0.5
        rad = max((Vector(mx) - Vector(mn)).length * 0.5, 0.5)
        ortho = (Vector(mx) - Vector(mn)).length * 1.12
        AB.rig(bpy.context.scene, cen, rad, resx, resy, aura)
        base_p = os.path.join(outdir, "%s_base_%s.png" % (KEY, vname))
        AB.shoot(base_p, cen, rad, az, el, ortho)
        base = G.read_png(base_p)
        li = lum(base)
        row = {}
        errs = []
        for feat in ("eyes", "hearth"):
            objs2, _i, pb = build(feat)
            if PROBE_N[0] != WANT[feat]:
                errs.append("%s/%s: probe took %d items, expected %d"
                            % (vname, feat, PROBE_N[0], WANT[feat]))
            if pb != bb:
                errs.append("%s/%s: BOUNDS MOVED - locked camera is a lie"
                            % (vname, feat))
            mn2, mx2, _ = G.world_bounds(objs2)
            cen2 = (Vector(mn2) + Vector(mx2)) * 0.5
            rad2 = max((Vector(mx2) - Vector(mn2)).length * 0.5, 0.5)
            AB.rig(bpy.context.scene, cen2, rad2, resx, resy, aura)
            pp = os.path.join(outdir, "%s_%s_%s.png" % (KEY, feat, vname))
            AB.shoot(pp, cen2, rad2, az, el, ortho)
            m = AB.probe_mask(base_p, pp)
            n = int(m.sum())
            if n < 40:
                errs.append("%s/%s: footprint %d px - RED ON EMPTY, a luma "
                            "over this mask means nothing" % (vname, feat, n))
                row[feat] = {"px": n, "luma": None}
                continue
            row[feat] = {"px": n, "luma": round(float(li[m].mean()), 4),
                         "luma_p90": round(float(np.percentile(li[m], 90)), 4)}
        if (row.get("eyes", {}).get("luma") is not None
                and row.get("hearth", {}).get("luma") is not None):
            e, h = row["eyes"]["luma"], row["hearth"]["luma"]
            row["hearth_minus_eyes"] = round(h - e, 4)
            row["ratio"] = round(h / max(1e-6, e), 3)
            if h <= e:
                errs.append("%s: hearth luma %.4f does NOT out-read eyes "
                            "%.4f - fault 4 is unfixed" % (vname, h, e))
        out[vname] = row
        if errs:
            errors[vname] = errs
    rep = {"key": KEY,
           "asks": "does the HEARTH out-read the FACE in rendered luma, inside "
                   "each feature's OWN visible footprint - the viewer's "
                   "question, not the albedo on paper.",
           "instrument": "tools/art/_fanner_value_ab.py",
           "slots": {"hearth": "glow", "eyes": "ember"},
           "views": out, "errors": errors,
           "ok": not errors}
    rep["verdict"] = "GREEN" if rep["ok"] else "RED"
    p = os.path.join(outdir, "_value_ab.json")
    with open(p, "w") as fh:
        json.dump(rep, fh, indent=1)
    print("[value_ab] %s verdict=%s" % (p, rep["verdict"]), flush=True)
    for v, r in out.items():
        print("[value_ab] %-14s eyes=%s hearth=%s ratio=%s"
              % (v, r.get("eyes"), r.get("hearth"), r.get("ratio")), flush=True)
    for v, e in errors.items():
        for x in e:
            print("[value_ab] RED %s" % x, flush=True)


main()
