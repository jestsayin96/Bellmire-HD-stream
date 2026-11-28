"""_t5_dagger_basis_recheck - DOES THE DAGGER PRESCRIPTION SURVIVE THE BASIS FIX?

  blender -b -noaudio -P tools/art/_t5_dagger_basis_recheck.py -- --repo <R> --out <W5>

WHY, AND IT IS URGENT RATHER THAN TIDY. `_wf_basis_audit` measured, against the
game build's own Godot captures, that the carry basis the engine ships is
`C . R_godot . C^-1` for all eight DUN families - and that artifactfit's tier-5
rule, `R_godot . C^-1`, is the one family's rule that does NOT match. The two
differ by `C^-1`: a 90 degree YAW about the slot's near-vertical X.

A YAW IS EXACTLY WHAT THE DAGGER PRESCRIPTION IS ABOUT. artifactfit measured
the tier-5 dagger reading BLIND (13 px minor, blade edge-on) and prescribed
`held_rot (0, 0, 90)` + `hand_scale 0.60` to turn its FACE to the front. If
that was measured in a frame yawed 90 degrees from the engine's, the fix may
land the engine on the very orientation it was meant to cure. The team lead
routed those two values to the game build at 18:58 to be applied WITHOUT
re-derivation, so this has to be checked before it lands, not after.

ONE THING CHANGES AT A TIME. A and B share hand_scale 0.60 and held_rot
(0,0,90) and differ ONLY in the basis. C is what the engine ships today.
The metric is the one the prescription was written in - the MINOR extent of
the weapon's own visible silhouette in the front view, taken from the pixels
the weapon ADDS to the body (the viewer's question), not from a mask rendered
alone, which answers how big a thing is and not whether it can be seen.
RED ON EMPTY: zero added pixels in any arm fails loudly.
"""
import os
import sys
import json
import math
import argparse

import bpy
import numpy as np
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lordgen as G            # noqa: E402
import minibossfit as MF       # noqa: E402
import weaponfit as WF         # noqa: E402

C4 = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0))).to_4x4()
MODEL = os.path.join("assets", "gear", "artifact", "dagger_golden.glb")
EPS = 0.02


def godot_rot(d):
    M = Matrix.Identity(4)
    ax = {"X": Matrix.Rotation(math.radians(float(d[0])), 4, 'X'),
          "Y": Matrix.Rotation(math.radians(float(d[1])), 4, 'Y'),
          "Z": Matrix.Rotation(math.radians(float(d[2])), 4, 'Z')}
    for k in "YXZ":
        M = M @ ax[k]
    return M


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args(argv)

    outdir = os.path.join(a.out, "renders", "art", "_wf_basis", "_dagger")
    os.makedirs(outdir, exist_ok=True)
    path = os.path.join(a.repo, MODEL)
    if not os.path.isfile(path):
        raise SystemExit("RECHECK FAIL - no tier-5 dagger at %s" % path)

    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next((o for o in roots if o.type == 'ARMATURE'), None)
    assert rig is not None and hinfo["posed"], "hero missing or in REST pose"
    bpy.context.view_layer.update()
    base = rig.matrix_world @ rig.pose.bones["handslot.r"].matrix

    scene = bpy.context.scene
    G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = WF.CELL_X, WF.CELL_Y
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
    bmn, bmx, bpts = G.world_bounds(body)
    cz = (WF.FRAME_H / 2.0) - WF.GROUND_UP

    ARMS = [
        ("A_artifactfit_rule_hr90_hs060", "R . C^-1", (0, 0, 90), 0.60),
        ("B_engine_rule_hr90_hs060",      "C . R . C^-1", (0, 0, 90), 0.60),
        ("C_engine_rule_shipped_hr0_hs05", "C . R . C^-1", (0, 0, 0), 0.50),
        ("D_artifactfit_rule_hr0_hs05",   "R . C^-1", (0, 0, 0), 0.50),
    ]

    loaded = {}
    allpts = list(bpts)
    for name, rule, hr, hs in ARMS:
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=path)
        objs = [o for o in bpy.data.objects if o not in before]
        meshes = [o for o in objs if o.type == 'MESH']
        if not meshes:
            raise SystemExit("RECHECK FAIL - no mesh in %s" % path)
        Rg = godot_rot(hr)
        Rslot = (Rg @ C4.inverted()) if rule == "R . C^-1" else (C4 @ Rg @ C4.inverted())
        S = Matrix.Diagonal((hs,) * 3).to_4x4()
        for o in objs:
            if o.parent is None:
                o.matrix_world = base @ Rslot @ S @ o.matrix_world
        bpy.context.view_layer.update()
        wv = WF.world_verts(meshes)
        if not wv:
            raise SystemExit("RECHECK FAIL - %s carried zero vertices" % name)
        loaded[name] = (objs, wv)
        allpts += list(wv)

    for objs, _ in loaded.values():
        WF.show(objs, False)

    reg, errors = {}, []
    sheet = {}
    for vname, az in WF.VIEWS:
        cam = WF.make_cam(az, cz, allpts)
        body_img = WF.render_to(os.path.join(outdir, "_body_%s.png" % vname))
        for name, rule, hr, hs in ARMS:
            objs, wv = loaded[name]
            WF.show(objs, True)
            img = WF.render_to(os.path.join(outdir, "%s_%s.png" % (name, vname)))
            WF.show(objs, False)
            d = np.abs(img - body_img).max(axis=2)
            mask = d > EPS
            n = int(mask.sum())
            rec = reg.setdefault(name, {"rule": rule, "held_rot": list(hr),
                                        "hand_scale": hs, "views": {}})
            if n == 0:
                errors.append("%s/%s: the dagger adds ZERO pixels - this arm proves "
                              "nothing" % (name, vname))
                rec["views"][vname] = {"added_px": 0, "minor_px": 0, "major_px": 0}
                continue
            ys, xs = np.nonzero(mask)
            h = int(ys.max() - ys.min() + 1)
            w = int(xs.max() - xs.min() + 1)
            rec["views"][vname] = {"added_px": n,
                                   "minor_px": int(min(h, w)),
                                   "major_px": int(max(h, w)),
                                   "bbox_h": h, "bbox_w": w,
                                   "fill_frac": round(n / float(h * w), 3)}
            if vname == "front":
                sheet[name] = img
        bpy.data.objects.remove(cam, do_unlink=True)

    # contact sheet of the four front views, full size, side by side
    if sheet:
        order = [n for n, _, _, _ in ARMS if n in sheet]
        H = WF.CELL_Y
        W = WF.CELL_X * len(order)
        canvas = np.zeros((H, W, 4), dtype=np.float32)
        for i, n in enumerate(order):
            canvas[:, i * WF.CELL_X:(i + 1) * WF.CELL_X] = sheet[n]
        im = bpy.data.images.new("dsheet", width=W, height=H, alpha=True)
        im.pixels = canvas.reshape(-1).tolist()
        im.filepath_raw = os.path.join(outdir, "_sheet_dagger_front.png")
        im.file_format = 'PNG'
        im.save()

    for name in reg:
        f = reg[name]["views"].get("front", {})
        print("RECHECK %-32s minor=%4d major=%4d added=%6d" %
              (name, f.get("minor_px", -1), f.get("major_px", -1), f.get("added_px", -1)))
    out = dict(tool="_t5_dagger_basis_recheck", model=MODEL, errors=errors,
               register=reg, order="YXZ",
               sheet="renders/art/_wf_basis/_dagger/_sheet_dagger_front.png")
    with open(os.path.join(outdir, "_t5_dagger_basis_recheck.json"), "w",
              encoding="utf-8") as fh:
        json.dump(out, fh, indent=1, sort_keys=True)
    print("RECHECK errors=%d" % len(errors))
    for e in errors:
        print("  ERR %s" % e)
    print("RECHECK DONE")


main()
