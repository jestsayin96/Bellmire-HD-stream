# D94 GLOVES, PASS 7 PROBE - MEASURE, DO NOT GUESS.
# The team lead's 02:58 row: "pull the inboard wall of the small cuts out of
# the torso". Before I move anything I measure WHERE the glove sits against the
# posed body and HOW FAR OUTBOARD it would have to come to clear it. No render.
#
# WHAT IT ANSWERS, per cell and per side:
#   1. how much of the piece is inside the body, split CUFF (metal/leather/dark)
#      vs HAND SHELL (cloth) - because the two want different treatment
#   2. the posed OUTBOARD axis, derived from the hand bone's own delta matrix
#      applied to rest +Z (the axis showcase.acc_gloves already skews along)
#   3. an OFFSET SWEEP: inside_pct after translating the piece 0..60 mm along
#      that axis, so the fix size comes off the body and not off my head
#   4. the cuff's top z against hand.l and chest - fault 2's own number
import os, sys, json, math
import bpy
from mathutils import Vector
REPO = r"C:\hd adventure\bellmire-art"
sys.path.append(os.path.join(REPO, "tools", "art"))
import lordgen as G, e3pogen as EG, showcasegen as SG, showcase as SC, icons as IC
import d94proof as P

SWEEP = [0.0, 0.01, 0.02, 0.03, 0.04, 0.05, 0.06]

def verts_of(ob):
    dg = bpy.context.evaluated_depsgraph_get()
    ev = ob.evaluated_get(dg)
    me = ev.to_mesh()
    out = [ob.matrix_world @ v.co for v in me.vertices]
    ev.to_mesh_clear()
    return out

def inside_frac(vs, trees, shift=None):
    nin = 0
    n = 0
    pen = 0.0
    for v in vs:
        p = (v + shift) if shift is not None else v
        n += 1
        best = None
        for t in trees:
            loc, nor, idx, dist = t.find_nearest(p, 1.2)
            if loc is None:
                continue
            ins = (p - loc).dot(nor) < 0.0
            if best is None or dist < best[0]:
                best = (dist, ins)
        if best is None:
            continue
        if best[1]:
            nin += 1
            pen = max(pen, best[0])
    return (100.0 * nin / max(1, n)), pen, n

items = SG.load_items(REPO)
row = [r for r in P.acc_rows(items) if r["slot"] == "gloves"][0]
out = {"sweep_m": SWEEP, "cells": []}
for cell in row["cells"]:
    cell["view"] = "front"
    fp = os.path.join(REPO, "renders", "art", "_g7tmp_full.png")
    dp = os.path.join(REPO, "renders", "art", "_g7tmp_det.png")
    rec = P.build_cell(REPO, cell, 120, 170, fp, dp)
    arm = next((o for o in bpy.context.scene.objects if o.type == 'ARMATURE'), None)
    body = [o for o in bpy.context.scene.objects
            if o.type == 'MESH' and "Glove" not in o.name]
    torso = [o for o in body if any(w in o.name for w in ("_Body", "_Head"))]
    trees = SG.bvh_for(body)
    arms = [o for o in body if "Arm" in o.name or "Hand" in o.name]
    tors = [o for o in body if any(w in o.name for w in ("_Body", "_Head", "_Leg", "Torso"))]
    t_arm = SG.bvh_for(arms)
    t_tor = SG.bvh_for(tors)
    anc = {}
    for bn in ("hand.l", "hand.r", "wrist.l", "lowerarm.l", "upperarm.l", "chest", "spine"):
        pb = arm.pose.bones.get(bn) if arm else None
        if pb is not None:
            p = arm.matrix_world @ pb.head
            anc[bn] = [round(v, 4) for v in p]
    # THE OUTBOARD AXIS, DERIVED. rest +Z is the axis acc_gloves skews along;
    # the posed direction is that vector through the bone's own delta.
    axes = {}
    for side in ("l", "r"):
        d = EG.bone_delta(arm, "hand." + side)
        v = (d.to_3x3() @ Vector((0.0, 0.0, 1.0)))
        v.normalize()
        axes[side] = [round(c, 4) for c in v]
    gl = [o for o in bpy.context.scene.objects if o.type == 'MESH' and "Glove" in o.name]
    per = []
    for side in ("L", "R"):
        objs = [o for o in gl if ("Acc_Glove" + side) in o.name]
        if not objs:
            continue
        ax = Vector(axes[side.lower()])
        cuffv, shellv = [], []
        for o in objs:
            vs = verts_of(o)
            step = max(1, len(vs) // 240)
            vs = vs[::step]
            if "_cloth_" in o.name:
                shellv.extend(vs)
            else:
                cuffv.extend(vs)
        allv = cuffv + shellv
        ent = {"side": side, "axis": axes[side.lower()],
               "n_cuff": len(cuffv), "n_shell": len(shellv)}
        for nm, vs in (("cuff", cuffv), ("shell", shellv), ("all", allv)):
            if not vs:
                ent[nm] = None
                continue
            f, pen, n = inside_frac(vs, trees)
            fa = inside_frac(vs, t_arm)[0] if t_arm else None
            ft = inside_frac(vs, t_tor)[0] if t_tor else None
            # THE QUESTION THE 02:58 ROW TURNS ON: is the piece buried in the
            # TORSO (what the row says) or swallowed by the ARM MESH it wraps?
            # Those are opposite fixes, so they are measured apart.
            ent[nm] = {"inside_pct": round(f, 1), "pen_m": round(pen, 4), "n": n,
                       "in_arm_pct": (round(fa, 1) if fa is not None else None),
                       "in_torso_pct": (round(ft, 1) if ft is not None else None),
                       "zmin": round(min(v.z for v in vs), 4),
                       "zmax": round(max(v.z for v in vs), 4)}
        # the sweep, on the CUFF only and on the whole piece
        ent["sweep_cuff"] = [round(inside_frac(cuffv, trees, ax * s)[0], 1) for s in SWEEP] if cuffv else None
        ent["sweep_all"] = [round(inside_frac(allv, trees, ax * s)[0], 1) for s in SWEEP] if allv else None
        per.append(ent)
    out["cells"].append({"key": cell["key"], "cost": cell["cost"],
                         "variant": cell.get("variant"), "anchors": anc,
                         "body_meshes": sorted(o.name.split('.')[0] for o in body),
                         "sides": per,
                         "fit": [{k: f[k] for k in ("part", "inside_pct", "penetration_m", "min_z")}
                                 for f in rec["fit"]]})
    print("G7PROBE_CELL", cell["key"], json.dumps(per[0] if per else {}))
    sys.stdout.flush()
p = os.path.join(REPO, "renders", "art", "_g7_probe.json")
open(p, "w").write(json.dumps(out, indent=1))
print("G7PROBE_DONE", p)
