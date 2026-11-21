"""SYSTEM 2 - THE CROSSBOW PROD, FIXED IN THE ASSET INSTEAD OF IN THE CARRY.

THE DEFECT, PROVED BY THE PREVIOUS PASS AND NOT RE-ARGUED HERE:
`crossbow_{common,uncommon,rare}` score `show` 0.39 / 0.37 / 0.40 against a
SHOW_MIN of 0.70, and a viewer sees a flat tray forward of the fist. The cause
is that the prod is a flat slab lying in the mesh XY plane, the carry lays that
plane level, and all three cameras are level, so every one of them catches it
edge-on. The scale is NOT the fault - 140 px at 200 px/m IS the full 0.691 m.

WHY THIS IS A DIFFERENT FIX FROM THE ONE ALREADY HANDED OVER, AND WHY BOTH CAN
EXIST. The previous pass handed the GAME BUILD a ~35 deg roll about the hand
slot's forward axis, in gear.gd, which I do not own and have not touched. This
pass asks a question that lane cannot answer for me: IS THE MESH ITSELF GOOD
ART? A crossbow prod modelled as a dead-flat plank is poor geometry whatever
angle you hold it at. Real prods are CAMBERED - the limbs sweep up out of the
stock's plane - and a cambered prod turns part of its broad face to a level
camera from any roll, including the shipped one.

AND IT CANNOT DOUBLE UP, WHICH IS WHY I CHOSE IT OVER THE OBVIOUS HACK.
The obvious art-side shortcut is to BAKE the 35 deg roll into the glb, which
would make the shipped carry read with no engine change at all. I REFUSE IT:
if the game build later lands the roll it was handed, a pre-rolled mesh gives
70 deg and nobody would know where the second 35 came from. Camber is a change
to the weapon's SHAPE, composes with any carry, and leaves the object correct
when it is displayed flat - which a rolled mesh does not.

WHAT IS MEASURED. One camera per view, built before any weapon exists and
shared by every angle and by the body-only plate, exactly as _s2_roll.py does,
so a pixel that moves is the weapon and not the camera. Per angle:
  minor/major   the weapon-alone silhouette's extents, per view
  vis/seen      moved-pixel visibility (the pass-11 cure), per view
  show          best view's minor / the mid world extent in px - the gate
  clip/ground   verts inside the body, verts below the floor

RED ON EMPTY, KEPT AND WIDENED FOR THIS SCRIPT'S OWN NEW FAILURE MODE:
a camber of N>0 degrees that MOVES ZERO VERTICES is an error, not a zero. That
is the way this particular instrument would lie - a ramp whose threshold sits
past the mesh's own extent silently measures the shipped mesh five times and
reports a flat sweep, which would read as "camber does nothing".

I DO NOT EDIT gear.gd AND THIS SCRIPT WRITES NO ASSET. It measures. Writing
the chosen camber into the glb is a separate, deliberate step.
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
    m = a[:, :, 3] > EPS
    n = int(m.sum())
    if n < 2:
        return None
    ys, xs = np.nonzero(m)
    w = int(xs.max() - xs.min() + 1)
    h = int(ys.max() - ys.min() + 1)
    return dict(area=n, w=w, h=h, minor=min(w, h), major=max(w, h),
                aspect=round(max(w, h) / float(min(w, h)), 2))


def camber(objs, deg, x0_frac):
    """Sweep the prod limbs up out of the stock's plane.

    The ramp is on |x| - the mesh's prod axis, measured not assumed - starting
    at x0_frac of the half-span so the STOCK, which lives at x ~ 0, is never
    touched. Rotation is about the prod's own centreline (the mesh Y axis at
    the prod's mid z), so the limbs bend rather than the whole weapon tilting:
    a vertex at the tip rises by sin(deg) * its own x, and a vertex at the
    stock does not move at all. smoothstep on t, so there is no crease where
    the ramp starts."""
    meshes = [o for o in objs if o.type == 'MESH']
    allv = []
    for o in meshes:
        M = o.matrix_world
        allv.extend([M @ v.co for v in o.data.vertices])
    assert allv, "S2_CAMBER FAIL - no vertices to camber; red on empty"
    xmax = max(abs(v.x) for v in allv)
    x0 = x0_frac * xmax
    zs = [v.z for v in allv if abs(v.x) >= x0]
    assert zs, ("S2_CAMBER FAIL - the ramp start x0=%.4f is past the mesh half-span "
                "%.4f, so NOTHING would bend and the sweep would silently measure "
                "the shipped mesh at every angle" % (x0, xmax))
    z0 = 0.5 * (min(zs) + max(zs))
    moved, tip = 0, 0.0
    for o in meshes:
        M = o.matrix_world.copy()
        Mi = M.inverted()
        for v in o.data.vertices:
            w = M @ v.co
            t = (abs(w.x) - x0) / max(xmax - x0, 1e-9)
            if t <= 0.0:
                continue
            t = min(1.0, t)
            t = t * t * (3.0 - 2.0 * t)
            ang = math.radians(deg) * t * (-1.0 if w.x > 0 else 1.0)
            p = Matrix.Rotation(ang, 4, 'Y') @ Vector((w.x, w.y, w.z - z0))
            nw = Vector((p.x, p.y, p.z + z0))
            tip = max(tip, (nw - w).length)
            v.co = Mi @ nw
            moved += 1
        o.data.update()
    if deg > 0.0:
        assert moved > 0, ("S2_CAMBER FAIL - camber %g deg moved ZERO vertices. A sweep "
                           "that cannot move is not a sweep." % deg)
        assert tip > 1e-4, ("S2_CAMBER FAIL - camber %g deg moved %d verts by at most "
                            "%.6f m, which is nothing." % (deg, moved, tip))
    return dict(xmax=round(xmax, 4), x0=round(x0, 4), z0=round(z0, 4),
                moved=moved, total=len(allv), max_disp=round(tip, 4))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--tier", default="common")
    ap.add_argument("--angles", default="0,20,30,40,55")
    ap.add_argument("--rolls", default="0")
    ap.add_argument("--x0", type=float, default=0.35)
    ap.add_argument("--out", default="camber")
    a = ap.parse_args(argv)
    angles = [float(x) for x in a.angles.split(",") if x != ""]
    rolls = [float(x) for x in a.rolls.split(",") if x != ""]
    assert angles, "S2_CAMBER FAIL - empty angle list"
    assert rolls, "S2_CAMBER FAIL - empty roll list"
    cells = [(c, r) for c in angles for r in rolls]

    outdir = os.path.join(a.repo, "renders", "art", "system2", "_camber")
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
    PXM = W.CELL_Y / W.FRAME_H

    cams, body_only = {}, {}
    for vname, az in VIEWS:
        cams[vname] = W.make_cam(az, cz, bpts)
        scene.camera = cams[vname]
        body_only[vname] = W.render_to(os.path.join(outdir, "_body_%s.png" % vname))
        s = sil(body_only[vname])
        assert s and s["area"] > 10000, "body-only plate for %s is empty or tiny" % vname

    Rslot = W.slot_matrix("crossbow")
    hs = 1.0
    rows, errors, sheet_cells = [], [], {}

    ref_mid_px = None
    for ang, roll in cells:
        objs, path = W.load_model(a.repo, "crossbow", a.tier)
        meshes = [o for o in objs if o.type == 'MESH']
        if not meshes:
            errors.append("camber %g roll %g: no mesh imported from %s" % (ang, roll, path))
            continue
        try:
            cinfo = camber(objs, ang, a.x0)
        except AssertionError as e:
            errors.append(str(e))
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)
            continue
        S = Matrix.Diagonal((hs,) * 3).to_4x4()
        Rroll = Matrix.Rotation(math.radians(roll), 4, 'Y')
        for o in objs:
            if o.parent is None:
                o.matrix_world = base @ Rroll @ Rslot @ S @ o.matrix_world
        bpy.context.view_layer.update()
        wv = W.world_verts(meshes)
        if not wv:
            errors.append("camber %g roll %g: zero vertices" % (ang, roll))
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)
            continue
        ext = sorted([max(v[i] for v in wv) - min(v[i] for v in wv) for i in range(3)])
        mid_px = ext[1] * PXM
        # *** THE DENOMINATOR MUST NOT MOVE, AND AT 17:43 CT IT DID. ***
        # `show` divides the best view's minor extent by the px the weapon's
        # MIDDLE world extent subtends. Bending the limbs up pulls the tips in
        # on x and shortens that middle extent - mid_px fell 130.7 -> 93.1 over
        # a 0..55 deg camber - so the raw ratio rises from BOTH ends and a
        # cambered weapon scores a pass it has not earned. The reference is
        # therefore pinned to the SHIPPED, UNDEFORMED, UNROLLED mesh: the
        # question is "does this carry turn the broad face THIS WEAPON HAS",
        # and deforming the weapon must not be allowed to shrink the bar.
        if ang == 0.0 and roll == 0.0:
            ref_mid_px = mid_px
        far = [v for v in wv if (v - slot).length > W.FIST_R]
        if not far:
            errors.append("angle %g: every vertex inside the fist - clip test empty" % ang)
        n_clip = sum(1 for v in far if W.inside(body_trees, v))
        n_ground = sum(1 for v in wv if v.z < -0.002)
        rec = dict(angle=ang, roll=roll, camber=cinfo, clip=n_clip, ground=n_ground,
                   ext=[round(e, 4) for e in ext], mid_px=round(mid_px, 1),
                   reach=round(max(v.z for v in wv) - slot.z, 3),
                   drop=round(slot.z - min(v.z for v in wv), 3))
        for vname, az in VIEWS:
            scene.camera = cams[vname]
            A = body_only[vname]
            B = W.render_to(os.path.join(outdir, "c%03dr%03d_%s.png" % (int(round(ang)), int(round(roll)), vname)))
            W.show(body, False)
            C = W.render_to(os.path.join(outdir, "_w_c%03dr%03d_%s.png" % (int(round(ang)), int(round(roll)), vname)))
            W.show(body, True)
            s = sil(C)
            if s is None:
                errors.append("angle %g / %s: the weapon renders EMPTY alone" % (ang, vname))
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
            rec.setdefault("alone", {})[vname] = s["area"]
            rec.setdefault("vis", {})[vname] = covered
            rec.setdefault("seen", {})[vname] = round(covered / float(s["area"]), 4)
            sheet_cells[(ang, roll, vname)] = B
        if "minor" in rec and len(rec["minor"]) == len(VIEWS):
            rec["best_minor"] = max(rec["minor"].values())
            rec["worst_minor"] = min(rec["minor"].values())
            rec["show_live"] = round(rec["best_minor"] / mid_px, 3) if mid_px > 1 else None
            rec["show"] = (round(rec["best_minor"] / ref_mid_px, 3)
                           if ref_mid_px and ref_mid_px > 1 else None)
        rows.append(rec)
        for o in objs:
            bpy.data.objects.remove(o, do_unlink=True)

    if len(rows) != len(cells):
        errors.append("sweep measured %d of %d cells" % (len(rows), len(cells)))
    if ref_mid_px is None:
        errors.append("no camber=0 roll=0 control cell was measured, so `show` has NO "
                      "fixed reference denominator - red on empty")
    shown = [r for r in rows if r.get("show") is not None]
    if len(shown) > 1 and len(set(r["show"] for r in shown)) == 1:
        errors.append("every angle returned the SAME show %.3f - an instrument that "
                      "cannot move is not a pass" % shown[0]["show"])

    if sheet_cells:
        step = 2
        ch, cw = W.CELL_Y // step, W.CELL_X // step
        sheet = np.ones((ch * len(cells), cw * len(VIEWS), 4), dtype=np.float32)
        for ri, cl in enumerate(cells):
            for ci, (vname, _) in enumerate(VIEWS):
                B = sheet_cells.get((cl[0], cl[1], vname))
                if B is None:
                    continue
                sub = B[::step, ::step, :]
                al = sub[:, :, 3:4]
                sheet[ri * ch:(ri + 1) * ch, ci * cw:(ci + 1) * cw, :3] = sub[:, :, :3] * al + (1.0 - al)
        img = bpy.data.images.new("sheet", width=sheet.shape[1], height=sheet.shape[0], alpha=True)
        img.pixels = sheet.reshape(-1)
        sp = os.path.join(outdir, "_sheet_%s.png" % a.out)
        img.filepath_raw = sp
        img.file_format = 'PNG'
        img.save()
        print("S2_CAMBER sheet", sp)

    out = dict(ok=not errors, tier=a.tier, hand_scale=hs, x0_frac=a.x0,
               angles=angles, rolls=rolls, ref_mid_px=ref_mid_px,
               views=[v for v, _ in VIEWS], hero=hinfo,
               show_min=W.SHOW_MIN, errors=errors, rows=rows)
    rp = os.path.join(outdir, "_camber_%s.json" % a.out)
    with open(rp, "w") as f:
        json.dump(out, f, indent=1)
    print("S2_CAMBER ok=%s angles=%d errors=%d" % (out["ok"], len(rows), len(errors)))
    for r in rows:
        print("  camber %5.1f roll %5.1f  show %s (live %s)  minor %s  clip %d ground %d"
              % (r["angle"], r["roll"], r.get("show"), r.get("show_live"),
                 r.get("minor"), r["clip"], r["ground"]))
    for e in errors:
        print("  ERROR", e)
    print("S2_CAMBER_DONE", rp)


if __name__ == "__main__":
    main()
