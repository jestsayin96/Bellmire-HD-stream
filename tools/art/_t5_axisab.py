"""_t5_axisab - WHICH SLOT CONVENTION IS THE ONE THE VIEWER SEES.

Found by artifactfit's basis selftest, 27 Nov 16:4x CT: weaponfit's two
hand-calibrated bases translate their gear.gd euler triples by TWO DIFFERENT
RULES. For the staff, SLOT_ROT == C.R.C^-1 (both sides converted). For the
crossbow, SLOT_ROT == R.C^-1 (the mesh side converted, the slot side left in
Godot axes). They cannot both be a consistent reading of their own euler.

ALGEBRA CANNOT SETTLE IT - the picture can, and gear.gd states its intent in
words for the crossbow: "stock forward, mesh +Y up, prod across". gear.gd's own
measurement of the mesh: dim (0.691, 0.638, 0.194) in Blender, PROD along X,
STOCK along Y, THIN along Z.

So this file carries the DUN crossbow and the DUN staff to the real posed hand
under BOTH conventions and reports, per convention:
  - where each Blender mesh axis LANDS in world
  - the angle between the stock axis and the body's forward
  - the angle between the thin axis and world up
and renders both so the call is made by looking, not by preference.
RED ON EMPTY: a cell whose mesh did not import is a FAIL, not a skipped row.
"""
import os, sys, json, math, argparse
import bpy
import numpy as np
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lordgen as G
import minibossfit as MF
import weaponfit as WF
import gearcarry as GC
import artifactfit as AF

# the body faces -Y in Blender (WF.make_cam az=0 stands the camera at -Y), up +Z
FWD = Vector((0, -1, 0))
UP = Vector((0, 0, 1))


def conv_A(deg, order):           # both sides converted
    return AF.C4 @ AF.godot_rot(deg, order) @ AF.C4.inverted()


def conv_B(deg, order):           # mesh side only - weaponfit's crossbow
    return AF.godot_rot(deg, order) @ AF.C4.inverted()


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--gear", required=True)
    a = ap.parse_args(argv)
    outdir = os.path.join(a.repo, "renders", "art", "gear_t5", "_axisab")
    os.makedirs(outdir, exist_ok=True)

    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next(o for o in roots if o.type == 'ARMATURE')
    assert hinfo["posed"], "hero in REST pose"
    bpy.context.view_layer.update()
    base = rig.matrix_world @ rig.pose.bones["handslot.r"].matrix

    scene = bpy.context.scene
    G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = WF.CELL_X, WF.CELL_Y
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    for nm, rot, en in (("key", (-0.95, 0.0, 0.7), 3.2), ("fill", (-1.2, 0.0, -2.1), 1.3)):
        if nm not in bpy.data.objects:
            ld = bpy.data.lights.new(nm, 'SUN'); ld.energy = en
            lo = bpy.data.objects.new(nm, ld); lo.rotation_euler = rot
            bpy.context.collection.objects.link(lo)
    bmn, bmx, bpts = G.world_bounds(body)
    cz = (WF.FRAME_H / 2.0) - WF.GROUND_UP

    out = {}
    for fam, res in (("crossbow", "res://assets/gear/dungeon/crossbow_common.glb"),
                     ("staff", "res://assets/gear/dungeon/staff_common.glb")):
        cr = GC.carry(a.gear, res)
        deg = [float(d) for d in cr["held_rot_deg"]]
        cal = [float(x) for x in WF.SLOT_ROT_CAL[fam]]
        for cname, fn in (("A_conjugated", conv_A), ("B_half", conv_B)):
            objs, path = AF.load_res(a.repo, res)
            meshes = [o for o in objs if o.type == 'MESH']
            assert meshes, "RED ON EMPTY - no mesh from %s" % res
            # scored at the CALIBRATION angles so the comparison is to the
            # value weaponfit's table was derived at, not to a later roll.
            R = fn(cal, "YXZ")
            S = Matrix.Diagonal((cr["hand_scale"],) * 3).to_4x4()
            for o in objs:
                if o.parent is None:
                    o.matrix_world = base @ R @ S @ o.matrix_world
            bpy.context.view_layer.update()
            M3 = (base @ R).to_3x3()
            ax = {n: (M3 @ Vector(v)).normalized()
                  for n, v in (("meshX_prod", (1, 0, 0)),
                               ("meshY_stock", (0, 1, 0)),
                               ("meshZ_thin", (0, 0, 1)))}
            rec = {n: [round(c, 3) for c in v] for n, v in ax.items()}
            rec["stock_vs_forward_deg"] = round(math.degrees(
                math.acos(min(1, max(-1, abs(ax["meshY_stock"].dot(FWD)))))), 1)
            rec["thin_vs_up_deg"] = round(math.degrees(
                math.acos(min(1, max(-1, abs(ax["meshZ_thin"].dot(UP)))))), 1)
            rec["prod_vs_across_deg"] = round(math.degrees(
                math.acos(min(1, max(-1, abs(ax["meshX_prod"].dot(Vector((1, 0, 0)))))))), 1)
            wv = WF.world_verts(meshes)
            assert wv, "RED ON EMPTY - zero verts"
            rec["held_rot_deg"] = deg
            rec["scored_at_cal"] = cal
            rec["hand_scale"] = cr["hand_scale"]
            for vname, az in (("front", 0.0), ("side", -90.0)):
                cam = WF.make_cam(az, cz, bpts + wv)
                png = os.path.join(outdir, "%s_%s_%s.png" % (fam, cname, vname))
                B = WF.render_to(png)
                rec.setdefault("opaque", {})[vname] = int((B[:, :, 3] > WF.DIFF_EPS).sum())
                b = max(float(B[0, :, 3].max()), float(B[-1, :, 3].max()),
                        float(B[:, 0, 3].max()), float(B[:, -1, 3].max()))
                rec.setdefault("border", {})[vname] = round(b, 4)
                bpy.data.objects.remove(cam, do_unlink=True)
            out["%s_%s" % (fam, cname)] = rec
            print("  %-10s %-14s stock_vs_fwd=%5.1f thin_vs_up=%5.1f prod_vs_across=%5.1f"
                  % (fam, cname, rec["stock_vs_forward_deg"], rec["thin_vs_up_deg"],
                     rec["prod_vs_across_deg"]))
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)

    rp = os.path.join(outdir, "_axisab.json")
    with open(rp, "w") as f:
        json.dump(out, f, indent=1)
    print("AXISAB_DONE", rp)


if __name__ == "__main__":
    main()
