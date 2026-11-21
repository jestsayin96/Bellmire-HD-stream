"""SYSTEM 2 - THE CROSSBOW CARRY, SWEPT ON THE ONE AXIS THE PICTURE BLAMES.

WHY THIS EXISTS. The weaponfit register reads GREEN on all 24 cells and the
team lead, looking at crossbow_common_side.png, still sees "a flat plank
forward of the hand and nothing a viewer would call a crossbow". Both are
true, and the instrument is the thing at fault - again in the pass-11 family.

WHAT THE NUMBERS ALREADY IN THE REGISTER PROVE, BEFORE ONE PIXEL IS RENDERED:
    crossbow_common front  vis 2610  seen 0.94
    axe_common      front  vis 2954  seen 0.82
The crossbow scores BETTER than the axe on `seen` and within 12% on `vis`,
and the axe reads as an axe while the crossbow reads as a tray. So `vis` and
`seen` CANNOT separate a weapon that reads from one that does not, and no
amount of raising VIS_MIN would have caught this - it would only have failed
the dagger.

WHAT THE SILHOUETTE SAYS, MEASURED OFF THE SHIPPED _w_ RENDERS:
    _w_crossbow_common_front   bbox 140 x 35 px
    _w_crossbow_common_side    bbox 132 x 41 px
At FRAME_H 3.80 m over 760 px the scale is 200 px/m, so that 140 px IS the
full 0.691 m prod. THE SCALE IS NOT THE FAULT. The fault is the 35: a level
crossbow lies in a HORIZONTAL plane, so every horizontal camera catches it
edge-on and it is a 4:1 lath from the front, from the side and from the back.
It is geometrically a correct crossbow and visually a plank.

SO THE AXIS TO SWEEP IS ROLL ABOUT THE CARRY'S OWN FORWARD AXIS - the one
rotation that tilts the prod plane out of horizontal without changing where
the weapon points, how long it is, or where it is anchored. Everything else
is frozen: one camera per view, built once, shared by every angle and by the
body-only plate, so a pixel that moves is the weapon and not the camera.

RED ON EMPTY IS KEPT AND WIDENED. A view whose weapon-alone mask is empty is
an error, not a zero; a sweep that measures fewer angles than it was asked
for is an error; and `minor` over a mask of one pixel is refused.

I DO NOT EDIT gear.gd. This script measures; the winning angle is handed to
the game build lane as a Godot euler DERIVED from the shipped one, never
transcribed - see _s2_godot_euler() and its self-check.
"""
import argparse
import json
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Vector, Matrix, bvhtree

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibossfit as MF     # noqa: E402
import weaponfit as W        # noqa: E402

VIEWS = [("front", 0.0), ("side", -90.0), ("back", 180.0)]
EPS = 0.02


def sil(a):
    """bbox, area and MINOR EXTENT of an alpha mask. The minor extent is the
    number the register never had: the thinner side of the silhouette's box,
    in pixels. A lath has a big area, a big major extent and a tiny minor one."""
    m = a[:, :, 3] > EPS
    n = int(m.sum())
    if n < 2:
        return None
    ys, xs = np.nonzero(m)
    w = int(xs.max() - xs.min() + 1)
    h = int(ys.max() - ys.min() + 1)
    return dict(area=n, w=w, h=h, minor=min(w, h), major=max(w, h),
                fill=round(n / float(w * h), 3),
                aspect=round(max(w, h) / float(min(w, h)), 2))


def godot_euler_from_slot(M3):
    """Return the gear.gd `held_rot` Vector3 that would produce the Blender
    slot rotation M3, derived from the one correspondence we KNOW:

        gear.gd ships Vector3(-90, 0, 90) for the crossbow, and
        weaponfit.SLOT_ROT['crossbow'] is the Blender slot matrix measured
        to match it (tools/art/_s2_axisprobe.py, 21 Nov 14:4x CT).

    So the unknown change of basis B satisfies  Blender = B @ Godot @ B^-1 .
    B is solved from that single shipped pair and then CHECKED against the
    staff pair, which was measured independently. If the check fails this
    raises rather than returning a number nobody can trust - copying three
    numbers across this convention boundary is exactly how the last wrong
    carry read green.
    """
    def gmat(dx, dy, dz):
        # Godot Vector3 held_rot is applied as a YXZ euler in Godot's axes.
        return (Matrix.Rotation(math.radians(dy), 3, 'Y')
                @ Matrix.Rotation(math.radians(dx), 3, 'X')
                @ Matrix.Rotation(math.radians(dz), 3, 'Z'))

    def bmat(fam):
        c = W.SLOT_ROT[fam]
        return Matrix(((c[0][0], c[1][0], c[2][0]),
                       (c[0][1], c[1][1], c[2][1]),
                       (c[0][2], c[1][2], c[2][2])))

    # B from the crossbow pair: B = Blender_x @ (Godot_x)^-1 is NOT unique in
    # general, so B is instead searched over the 24 signed axis permutations -
    # the only basis changes a glTF importer can introduce - and the one that
    # also reproduces the staff pair is kept.
    gx, bx = gmat(-90.0, 0.0, 90.0), bmat("crossbow")
    gs, bs = gmat(0.0, 0.0, 90.0), bmat("staff")
    cands = []
    for perm in ((0, 1, 2), (0, 2, 1), (1, 0, 2), (1, 2, 0), (2, 0, 1), (2, 1, 0)):
        for sgn in range(8):
            s = [1 if (sgn >> i) & 1 == 0 else -1 for i in range(3)]
            B = Matrix(((0,) * 3,) * 3)
            B = B.copy()
            for col in range(3):
                v = [0.0, 0.0, 0.0]
                v[perm[col]] = float(s[col])
                for row in range(3):
                    B[row][col] = v[row]
            if abs(B.determinant() - 1.0) > 1e-6:
                continue
            Bi = B.inverted()
            if max(abs((B @ gx @ Bi)[r][c] - bx[r][c]) for r in range(3) for c in range(3)) > 1e-6:
                continue
            if max(abs((B @ gs @ Bi)[r][c] - bs[r][c]) for r in range(3) for c in range(3)) > 1e-6:
                continue
            cands.append(B)
    if not cands:
        raise SystemExit("S2_ROLL FAIL - no signed axis permutation reproduces BOTH "
                         "shipped gear.gd carries. The Godot euler cannot be derived "
                         "and will NOT be guessed.")
    B = cands[0]
    Gm = B.inverted() @ Matrix(M3) @ B
    e = Gm.to_euler('YXZ')
    return [round(math.degrees(e.x), 1), round(math.degrees(e.y), 1), round(math.degrees(e.z), 1)], len(cands)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--tier", default="common")
    ap.add_argument("--angles", default="0,20,35,50,65,80,90")
    ap.add_argument("--out", default="roll")
    a = ap.parse_args(argv)
    angles = [float(x) for x in a.angles.split(",") if x != ""]
    assert angles, "S2_ROLL FAIL - empty angle list; a sweep over nothing is not a sweep"

    outdir = os.path.join(a.repo, "renders", "art", "system2", "_roll")
    os.makedirs(outdir, exist_ok=True)

    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next((o for o in roots if o.type == 'ARMATURE'), None)
    assert rig is not None, "no armature in the hero glb"
    assert hinfo["posed"], "hero is in REST pose - the idle action did not take"
    bpy.context.view_layer.update()

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

    dg = bpy.context.evaluated_depsgraph_get()
    body_trees = []
    for ob in body:
        try:
            body_trees.append(bvhtree.BVHTree.FromObject(ob, dg))
        except Exception:
            pass
    assert body_trees, "no BVH built from the body - the clip test would read 0 over nothing"

    bmn, bmx, bpts = G.world_bounds(body)
    cz = (W.FRAME_H / 2.0) - W.GROUND_UP
    pb = rig.pose.bones["handslot.r"]
    base = rig.matrix_world @ pb.matrix
    slot = base @ Vector((0, 0, 0))

    # ONE camera per view for the WHOLE sweep, built before any weapon exists
    # and never rebuilt. If it moved between angles the diff would be the camera.
    cams, body_only = {}, {}
    for vname, az in VIEWS:
        cams[vname] = W.make_cam(az, cz, bpts)
        scene.camera = cams[vname]
        body_only[vname] = W.render_to(os.path.join(outdir, "_body_%s.png" % vname))
        s = sil(body_only[vname])
        assert s and s["area"] > 10000, "body-only plate for %s is empty or tiny - red on empty" % vname

    Rslot = W.slot_matrix("crossbow")
    hs = 1.0  # gear.gd ships the crossbow at x1.0; the sweep does not touch scale
    rows, errors = [], []
    sheet_cells = {}

    for ang in angles:
        objs, path = W.load_model(a.repo, "crossbow", a.tier)
        meshes = [o for o in objs if o.type == 'MESH']
        if not meshes:
            errors.append("angle %g: no mesh imported from %s" % (ang, path))
            continue
        # roll about the SLOT'S OWN FORWARD axis (slot +Y, measured FORWARD).
        Rroll = Matrix.Rotation(math.radians(ang), 4, 'Y')
        S = Matrix.Diagonal((hs,) * 3).to_4x4()
        for o in objs:
            if o.parent is None:
                o.matrix_world = base @ Rroll @ Rslot @ S @ o.matrix_world
        bpy.context.view_layer.update()
        wv = W.world_verts(meshes)
        if not wv:
            errors.append("angle %g: zero vertices" % ang)
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)
            continue
        far = [v for v in wv if (v - slot).length > W.FIST_R]
        if not far:
            errors.append("angle %g: every vertex inside the fist - clip test empty" % ang)
        n_clip = sum(1 for v in far if W.inside(body_trees, v))
        n_ground = sum(1 for v in wv if v.z < -0.002)
        rec = dict(angle=ang, clip=n_clip, ground=n_ground,
                   reach=round(max(v.z for v in wv) - slot.z, 3),
                   drop=round(slot.z - min(v.z for v in wv), 3))
        for vname, az in VIEWS:
            scene.camera = cams[vname]
            A = body_only[vname]
            png = os.path.join(outdir, "x%03d_%s.png" % (int(round(ang)), vname))
            B = W.render_to(png)
            W.show(body, False)
            C = W.render_to(os.path.join(outdir, "_w_x%03d_%s.png" % (int(round(ang)), vname)))
            W.show(body, True)
            s = sil(C)
            if s is None:
                errors.append("angle %g / %s: the weapon renders EMPTY alone - "
                              "every number for this cell would be over nothing" % (ang, vname))
                continue
            border = max(float(B[0, :, 3].max()), float(B[-1, :, 3].max()),
                         float(B[:, 0, 3].max()), float(B[:, -1, 3].max()))
            if border > EPS:
                errors.append("angle %g / %s: FRAME CLIP, border alpha %.3f" % (ang, vname, border))
            if int((B[:, :, 3] > EPS).sum()) == 0:
                errors.append("angle %g / %s: BLANK cell" % (ang, vname))
            changed = np.abs(B - A).max(axis=2) > EPS
            mask = C[:, :, 3] > EPS
            covered = int((changed & mask).sum())
            rec.setdefault("minor", {})[vname] = s["minor"]
            rec.setdefault("major", {})[vname] = s["major"]
            rec.setdefault("aspect", {})[vname] = s["aspect"]
            rec.setdefault("alone", {})[vname] = s["area"]
            rec.setdefault("vis", {})[vname] = covered
            rec.setdefault("seen", {})[vname] = round(covered / float(s["area"]), 4)
            sheet_cells[(ang, vname)] = B
        if "minor" in rec and len(rec["minor"]) == len(VIEWS):
            rec["worst_minor"] = min(rec["minor"].values())
            rec["worst_aspect"] = max(rec["aspect"].values())
        rows.append(rec)
        for o in objs:
            bpy.data.objects.remove(o, do_unlink=True)

    if len(rows) != len(angles):
        errors.append("sweep measured %d of %d angles" % (len(rows), len(angles)))

    # contact sheet: one row per angle, three views across, half resolution
    if sheet_cells:
        step = 2
        ch, cw = W.CELL_Y // step, W.CELL_X // step
        sheet = np.ones((ch * len(angles), cw * len(VIEWS), 4), dtype=np.float32)
        for ri, ang in enumerate(angles):
            for ci, (vname, _) in enumerate(VIEWS):
                B = sheet_cells.get((ang, vname))
                if B is None:
                    continue
                sub = B[::step, ::step, :]
                al = sub[:, :, 3:4]
                rgb = sub[:, :, :3] * al + (1.0 - al)
                sheet[ri * ch:(ri + 1) * ch, ci * cw:(ci + 1) * cw, :3] = rgb
        img = bpy.data.images.new("sheet", width=sheet.shape[1], height=sheet.shape[0], alpha=True)
        img.pixels = sheet.reshape(-1)
        sp = os.path.join(outdir, "_sheet_%s.png" % a.out)
        img.filepath_raw = sp
        img.file_format = 'PNG'
        img.save()
        print("S2_ROLL sheet", sp)

    best = None
    for r in rows:
        if "worst_minor" in r and (best is None or r["worst_minor"] > best["worst_minor"]):
            best = r
    # THE GODOT EULER IS REFUSED, AND THE REFUSAL IS THE HONEST RESULT.
    # godot_euler_from_slot() models the Blender<->Godot boundary as a
    # CONJUGATION, B @ G @ B^-1. That model is WRONG: the glTF importer changes
    # the MESH basis only, which COMPOSES (M_blender = C @ P) and does not
    # conjugate, so rotation angle is not preserved and no B can exist. I found
    # that by checking the model instead of the number - gear.gd's shipped
    # Vector3(-90, 0, 90) is a 120 deg rotation and weaponfit's crossbow slot
    # matrix is 180 deg, which under conjugation would have been a proof that
    # the register mirrors the wrong carry. IT IS NOT ONE, because conjugation
    # is not the right model, and I am not publishing it as one.
    # So this script hands the game build lane a ROLL IN THE SLOT FRAME and the
    # pictures behind it, and leaves the euler to be solved the way S20's own
    # comment says it was solved - off the matrix, gated by tools/_s20_hand.gd.
    derived = None
    refusal = None
    if best is not None:
        M = (Matrix.Rotation(math.radians(best["angle"]), 3, 'Y') @ Rslot.to_3x3())
        try:
            derived, ncand = godot_euler_from_slot(M)
            print("S2_ROLL derived godot held_rot for %g deg: %s (candidates %d)"
                  % (best["angle"], derived, ncand))
        except SystemExit as e:
            refusal = str(e)
            print("S2_ROLL godot euler REFUSED:", refusal)

    out = dict(ok=not errors, tier=a.tier, hand_scale=hs, angles=angles,
               views=[v for v, _ in VIEWS], hero=hinfo,
               shipped_angle=0.0, best_angle=(best or {}).get("angle"),
               best_godot_held_rot=derived, godot_derivation_refused=refusal,
               errors=errors, rows=rows)
    rp = os.path.join(outdir, "_roll_%s.json" % a.out)
    with open(rp, "w") as f:
        json.dump(out, f, indent=1)
    print("S2_ROLL ok=%s angles=%d errors=%d" % (out["ok"], len(rows), len(errors)))
    for e in errors:
        print("  ERROR", e)
    print("S2_ROLL_DONE", rp)


if __name__ == "__main__":
    main()
