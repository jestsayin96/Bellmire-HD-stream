"""_sheen_grid_ab - THE BAND'S EDGE IS GEOMETRY, AND THE PICTURE SAID SO FIRST.

  blender -b -noaudio -P tools/art/_sheen_grid_ab.py -- --repo <repo>

WHY THIS RUN EXISTS. _sheen_ab measured the band's COLOUR and the numbers moved
monotonically the whole way - side-view body_sat 0.3091 -> 0.4308, cream_share
0.4206 -> 0.2920. Then the 4x crop of the side view was looked at and it showed
something no number in that table asks about: THE BAND IS A HARD VERTICAL STRIPE
WITH A STAIR-STEPPED BOTTOM EDGE. It reads as a drip of paint, and it reads that
way under EVERY band colour, because the thing that makes it read as paint is
not its hue - it is that a sheen with square corners is not a sheen.

THE CAUSE IS ARITHMETIC AND IT IS NOT A JUDGEMENT CALL. `_leaf` builds the sheet
on a 4 x 5 grid: 5 columns and 6 rows of vertices per face, 60 vertices a leaf.
The vertex colours are INTERPOLATED ACROSS FACES BY THE RASTERISER, so the band's
whole gradient has to be carried by five columns. A smooth falloff cannot exist
at that resolution - `_smooth` is evaluated at five places and the renderer draws
straight lines between them. The ramp's maths was never the problem; it was being
sampled too coarsely to be seen.

SO THIS SWEEPS THE TESSELLATION, with the band colour HELD at the `cu` value the
colour sweep selected, and changes nothing else. SILHOUETTE IS UNCHANGED BY
CONSTRUCTION: every vertex still lies on the same analytic bowed surface
Y = 0.085 sin(pi tx)(0.45 + 0.55 tz), so a finer grid adds vertices ON the sheet
and moves none of its outline. That is asserted here, not assumed - the world
bounds of the whole body must agree across arms to 1e-4, or the arm is an ERROR
and not a smoother band.

IT GOES RED THE SAME WAYS _sheen_ab DOES, and the metric functions are IMPORTED
from it rather than copied: two readers in this tree drifted apart once because
each kept its own copy of a statistic.
"""
import os
import sys
import math
import json
import argparse

import bpy
import numpy as np
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordlib as L            # noqa: E402
import lordgen as G            # noqa: E402
import minibosses as M         # noqa: E402
import _sheen_ab as S          # noqa: E402

# held at the colour sweep's selection, so exactly one thing moves here
CU = (1.000, 0.6670, 0.5634)
ARMS = (("g4x5", 4, 5), ("g8x10", 8, 10), ("g14x18", 14, 18))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--key", default="greener")
    ap.add_argument("--span", default="plates")
    ap.add_argument("--slot", default="bone")
    args = ap.parse_args(argv)
    key, span, slot = args.key, args.span, args.slot
    out = os.path.join(args.repo, "renders", "art", "minibosses")
    tmp = os.path.join(out, "_sheen_grid_tmp")
    os.makedirs(tmp, exist_ok=True)
    rep = {"ok": True, "errors": [], "key": key, "held_sheen": list(CU),
           "shipped_grid": [M.LEAF_NX, M.LEAF_NZ], "arms": {}, "look": {},
           "bounds": {}}

    o_sheen, o_nx, o_nz = M.COPPER_SHEEN, M.LEAF_NX, M.LEAF_NZ
    builds = {}
    for nm, nx, nz in ARMS:
        M.COPPER_SHEEN, M.LEAF_NX, M.LEAF_NZ = CU, nx, nz
        S._clear()
        P = M.BUILDERS[key]()
        i0, i1 = P.spans[span]
        tgt = [j for j in range(i0, i1) if P.items[j][2] == slot]
        if not tgt:
            rep["ok"] = False
            rep["errors"].append("%s: span %r slot %r EMPTY - RED ON EMPTY"
                                 % (key, span, slot))
            print("SHEENGRID " + json.dumps(rep))
            return
        verts = sum(len(P.items[j][0]) for j in tgt)
        painted = [P.vcols.get(id(P.items[j])) for j in tgt]
        if any(p is None for p in painted):
            rep["ok"] = False
            rep["errors"].append("arm %s: an item in the span carries NO vertex "
                                 "colour - the paint never reached the build" % nm)
            print("SHEENGRID " + json.dumps(rep))
            return
        rep["arms"][nm] = {"grid": [nx, nz], "leaf_verts": verts,
                           "verts_per_leaf": verts // max(1, len(tgt)),
                           "by_view": {}}
        builds[nm] = (P, tgt)
    M.COPPER_SHEEN, M.LEAF_NX, M.LEAF_NZ = o_sheen, o_nx, o_nz

    mats = S._mats(key)
    height = M.CANON[key][1]

    # rig off the SHIPPED-GRID arm, reused for all three
    P0, tgt0 = builds["g4x5"]
    S._clear()
    probe = M.merge_objs(key, P0.items, mats, suffix="gprobe",
                         vcols=getattr(P0, "vcols", None))
    mn, mx, _ = G.world_bounds(probe)
    cur = mx.z - mn.z
    k = height / cur if cur > 1e-6 else 1.0
    S._drop_meshes()
    full = S._scaled_free(P0, P0.items, "grig", mats, k, key)
    mn, mx, _ = G.world_bounds(full)
    camob, ctr, d, lights = S._rig(mn, mx, S.RES, 1.34)
    S._drop_meshes()

    # *** THE SILHOUETTE MUST NOT MOVE. A finer grid that changed the outline
    # *** would be a different body wearing the same argument.
    for nm, _nx, _nz in ARMS:
        P, _t = builds[nm]
        S._drop_meshes()
        obs = S._scaled_free(P, P.items, "gb_%s" % nm, mats, k, key)
        bmn, bmx, _ = G.world_bounds(obs)
        rep["bounds"][nm] = [round(float(v), 6) for v in
                             (bmn.x, bmn.y, bmn.z, bmx.x, bmx.y, bmx.z)]
        S._drop_meshes()
    ref = rep["bounds"]["g4x5"]
    for nm in rep["bounds"]:
        if max(abs(a - b) for a, b in zip(ref, rep["bounds"][nm])) > 1e-4:
            rep["ok"] = False
            rep["errors"].append("arm %s moved the body's world bounds (%s vs %s) - "
                                 "a finer grid must add vertices ON the sheet and "
                                 "move none of its outline. NOT a smoother band."
                                 % (nm, rep["bounds"][nm], ref))

    for vname, yaw, pitch in S.VIEWS:
        S._place(camob, ctr, d, yaw, pitch)
        for nm, _nx, _nz in ARMS:
            P, tgt = builds[nm]
            cell, npx = S._measure_free(P, tgt, mats, lights, k, key, tmp,
                                        "%s_%s" % (nm, vname))
            if cell is None:
                rep["ok"] = False
                rep["errors"].append("%s/%s: visible mask %d px - FAILED RENDER"
                                     % (nm, vname, npx))
                continue
            rep["arms"][nm]["by_view"][vname] = cell

    # THE PICTURE, and it is the side view at the crop that found the fault.
    S._clear()
    grid_imgs = {}
    lcam = None
    for nm, _nx, _nz in ARMS:
        P, _t = builds[nm]
        S._drop_meshes()
        obs = S._scaled_free(P, P.items, "glook_%s" % nm, mats, k, key)
        if lcam is None:
            lmn, lmx, _ = G.world_bounds(obs)
            lcam, lctr, ld, _ll = S._rig(lmn, lmx, S.TILE, 1.50)
        for vname, yaw, pitch in S.VIEWS:
            S._place(lcam, lctr, ld, yaw, pitch)
            img = S._shoot(os.path.join(tmp, "glook_%s_%s.png" % (nm, vname)))
            al = img[..., 3]
            opaque = int((al > 0.02).sum())
            b = 3
            border = float(max(al[:b, :].max(), al[-b:, :].max(),
                               al[:, :b].max(), al[:, -b:].max()))
            ck = "%s/%s" % (nm, vname)
            rep["look"][ck] = {"opaque_px": opaque, "border_alpha": round(border, 4)}
            if opaque < 2000:
                rep["ok"] = False
                rep["errors"].append("%s: %d opaque px - BLANK OR NEAR-BLANK" % (ck, opaque))
            if border > 0.02:
                rep["ok"] = False
                rep["errors"].append("%s: border alpha %.3f - BODY CLIPPED BY THE FRAME"
                                     % (ck, border))
            grid_imgs[(nm, vname)] = img
        S._drop_meshes()

    h, w = S.TILE[1], S.TILE[0]
    sheet = np.zeros((h * len(ARMS), w * len(S.VIEWS), 4), dtype=np.float32)
    sheet[..., 0:3] = 0.08
    sheet[..., 3] = 1.0
    for ri, (nm, _a, _b2) in enumerate(ARMS):
        for ci, (vname, _y, _p) in enumerate(S.VIEWS):
            img = grid_imgs.get((nm, vname))
            if img is None:
                continue
            al = img[..., 3:4]
            sheet[ri * h:(ri + 1) * h, ci * w:(ci + 1) * w, 0:3] = (
                img[..., 0:3] * al + 0.08 * (1.0 - al))
    for ri in range(1, len(ARMS)):
        sheet[ri * h - 1:ri * h + 1, :, 0:3] = 0.55
    for ci in range(1, len(S.VIEWS)):
        sheet[:, ci * w - 1:ci * w + 1, 0:3] = 0.55
    spath = os.path.join(out, "_sheen_grid_sheet.png")
    G.write_png(spath, sheet)
    rep["sheet"] = spath
    rep["sheet_layout"] = ("rows top->bottom: %s ; cols left->right: %s"
                           % (", ".join(a[0] for a in ARMS),
                              ", ".join(v[0] for v in S.VIEWS)))
    with open(os.path.join(out, "_sheen_grid_ab.json"), "w") as f:
        json.dump(rep, f, indent=1)
    S._clear()
    print("SHEENGRID " + json.dumps(rep))


if __name__ == "__main__":
    main()
