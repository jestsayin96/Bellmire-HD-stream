"""_s2_stirrup_ab - DOES THE STIRRUP READ? Measured the way pass 11 taught.

THE TEST ASKS THE VIEWER'S QUESTION. A mask of the stirrup rendered ALONE
would answer how BIG it is and say nothing about whether it can be SEEN past
the body and past the crossbow's own stock. So every view is rendered three
times through ONE camera built once from the union of all three point sets:
    A  body alone
    B  body + the pack crossbow exactly as it ships
    C  body + the same crossbow with stirrup, string and bolt
and the number that matters is MOVED = pixels where B and C differ. A pixel
that moved is the new part, visible, in the shipped carry.

RED ON EMPTY IS KEPT: a view whose moved count is zero, or whose weapon-alone
mask is empty, or a cell whose parts failed to build, is a FAIL and not a
quiet zero. The border is asserted too - a part that reaches the frame edge is
a clip, and a clipped part is not a readable one.

`show` IS REPORTED FOR BOTH, with the LOCAL MIDDLE EXTENT printed before and
after, because that is the denominator and this change must be shown not to
have shrunk it. Adding geometry cannot shrink an extent, so the only honest
direction here is down - and the print is the proof, not this sentence.

THE 35 DEG ROLL IS A FORECAST ONLY. gear.gd on main still carries
Vector3(-90, 0, 90); the roll is the game build's to land. --roll measures
what the cell WILL read once it lands. Nothing here is baked into a mesh.

  blender -b -noaudio -P tools/art/_s2_stirrup_ab.py -- --repo R [--roll 35]
"""
import argparse
import json
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibossfit as MF     # noqa: E402
import weaponfit as W        # noqa: E402
import xbowparts as XP       # noqa: E402

TIERS = ("common", "uncommon", "rare")


def local_ext(meshes):
    lv = W.world_verts(meshes)
    return sorted([max(v[i] for v in lv) - min(v[i] for v in lv) for i in range(3)]), lv


def mask(a):
    return a[:, :, 3] > W.DIFF_EPS


def minor_of(m):
    if int(m.sum()) < 2:
        return 0
    ys, xs = np.nonzero(m)
    return int(min(xs.max() - xs.min() + 1, ys.max() - ys.min() + 1))


def border_hot(a):
    return max(float(a[0, :, 3].max()), float(a[-1, :, 3].max()),
               float(a[:, 0, 3].max()), float(a[:, -1, 3].max())) > W.DIFF_EPS


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--gear", default="")
    ap.add_argument("--roll", type=float, default=0.0,
                    help="forecast only: extra roll about the slot's forward axis")
    a = ap.parse_args(argv)

    outdir = os.path.join(a.repo, "renders", "art", "system2_stirrup")
    tmp = os.path.join(outdir, "_tmp")
    os.makedirs(tmp, exist_ok=True)
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)

    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next((o for o in roots if o.type == 'ARMATURE'), None)
    assert rig is not None, "no armature in the hero glb"
    assert hinfo["posed"], "hero is in REST pose"
    bpy.context.view_layer.update()
    gear_path = a.gear or os.path.join(os.path.dirname(os.path.abspath(a.repo)),
                                       "jests-hd-medieval-adventure", "scripts", "gear.gd")
    OVR = W.gear_overrides(gear_path)
    hs = OVR["crossbow"]["scale"]
    engine_rot = OVR["crossbow"]["engine_rot_deg"]

    scene = bpy.context.scene
    G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = W.CELL_X, W.CELL_Y
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    for nm, rot, en in (("key", (-0.95, 0.0, 0.7), 3.2), ("fill", (-1.2, 0.0, -2.1), 1.3)):
        if nm not in bpy.data.objects:
            ld = bpy.data.lights.new(nm, 'SUN')
            ld.energy = en
            lo = bpy.data.objects.new(nm, ld)
            lo.rotation_euler = rot
            bpy.context.collection.objects.link(lo)

    base = rig.matrix_world @ rig.pose.bones["handslot.r"].matrix
    bmn, bmx, bpts = G.world_bounds(body)
    cz = (W.FRAME_H / 2.0) - W.GROUND_UP
    Rslot = W.slot_matrix("crossbow")
    # roll about the SLOT's own forward axis (+Y of the slot frame), applied in
    # the slot frame exactly where gear.gd's euler would put it - never baked.
    Rroll = Matrix.Rotation(math.radians(a.roll), 4, 'Y')

    reg, errors = {}, []
    for tier in TIERS:
        key = "crossbow_%s" % tier
        rec = {"hand_scale": hs, "engine_rot_deg": engine_rot, "roll_forecast_deg": a.roll}
        variants = {}
        for vk in ("base", "parts"):
            objs, path = W.load_model(a.repo, "crossbow", tier)
            meshes = [o for o in objs if o.type == 'MESH']
            if not meshes:
                errors.append("%s/%s: no mesh imported" % (key, vk))
                continue
            if vk == "parts":
                try:
                    rec["built"] = XP.add_parts(meshes[0], tier)
                except Exception as exc:
                    errors.append("%s: add_parts failed: %s" % (key, exc))
                    for o in objs:
                        bpy.data.objects.remove(o, do_unlink=True)
                    continue
            ext, _ = local_ext(meshes)
            S = Matrix.Diagonal((hs,) * 3).to_4x4()
            for o in objs:
                if o.parent is None:
                    o.matrix_world = base @ Rroll @ Rslot @ S @ o.matrix_world
            bpy.context.view_layer.update()
            variants[vk] = {"objs": objs, "meshes": meshes,
                            "local_ext": [round(c, 4) for c in ext],
                            "wv": W.world_verts(meshes)}
        if len(variants) != 2:
            continue

        allpts = bpts + variants["base"]["wv"] + variants["parts"]["wv"]
        for vname, az in W.VIEWS:
            cam = W.make_cam(az, cz, allpts)
            W.show(variants["base"]["meshes"], False)
            W.show(variants["parts"]["meshes"], False)
            A = W.render_to(os.path.join(tmp, "_body_%s.png" % vname))
            plates = {}
            for vk in ("base", "parts"):
                W.show(variants[vk]["meshes"], True)
                plates[vk] = W.render_to(os.path.join(outdir, "%s_%s_%s.png" % (key, vk, vname)))
                W.show(body, False)
                plates[vk + "_alone"] = W.render_to(os.path.join(tmp, "_w_%s_%s_%s.png"
                                                                 % (key, vk, vname)))
                W.show(body, True)
                W.show(variants[vk]["meshes"], False)
            B, C = plates["base"], plates["parts"]
            moved = int((np.abs(B - C).max(axis=2) > W.DIFF_EPS).sum())
            mb, mc = mask(plates["base_alone"]), mask(plates["parts_alone"])
            if int(mb.sum()) == 0 or int(mc.sum()) == 0:
                errors.append("%s %s: weapon-alone mask EMPTY - metric over nothing"
                              % (key, vname))
            if moved == 0:
                errors.append("%s %s: ZERO pixels moved - the parts are invisible in "
                              "this view, which is the whole claim" % (key, vname))
            if border_hot(C):
                errors.append("%s %s: parts plate touches the frame border - a clip"
                              % (key, vname))
            rec.setdefault("views", {})[vname] = {
                "moved_px": moved,
                "minor_base": minor_of(mb), "minor_parts": minor_of(mc),
                "opaque_base": int(mb.sum()), "opaque_parts": int(mc.sum()),
                "opaque_cell_parts": int(mask(C).sum()),
            }
        for vk in ("base", "parts"):
            rec["mid_%s" % vk] = variants[vk]["local_ext"][1]
            rec["ext_%s" % vk] = variants[vk]["local_ext"]
            for o in variants[vk]["objs"]:
                bpy.data.objects.remove(o, do_unlink=True)
        mid_px_base = rec["mid_base"] * hs * W.PX_PER_M
        mid_px_parts = rec["mid_parts"] * hs * W.PX_PER_M
        if mid_px_base <= 1 or mid_px_parts <= 1:
            errors.append("%s: cannot compute show over a zero-width mesh" % key)
        else:
            bb = max(v["minor_base"] for v in rec["views"].values())
            bp = max(v["minor_parts"] for v in rec["views"].values())
            rec["show_base"] = round(bb / mid_px_base, 3)
            rec["show_parts"] = round(bp / mid_px_parts, 3)
            rec["denominator_grew"] = round(rec["mid_parts"] - rec["mid_base"], 4)
        reg[key] = rec

    rep = {"roll_forecast_deg": a.roll, "show_min": W.SHOW_MIN, "px_per_m": W.PX_PER_M,
           "hero_h": round(hinfo["h"], 3), "cells": reg, "errors": errors,
           "verdict": "GREEN" if not errors else "RED"}
    with open(os.path.join(outdir, "_ab_roll%d.json" % int(a.roll)), "w") as fh:
        json.dump(rep, fh, indent=1)
    print("STIRRUPAB " + json.dumps(rep))


main()
