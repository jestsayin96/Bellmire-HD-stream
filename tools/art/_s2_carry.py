"""_s2_carry - the three families that do not read in a plain attach, and the
number that fixes them.

sword, axe, hammer, dagger and axeDouble are authored blade-up about the grip,
and the handslot basis lays that axis out sideways from the fist - which is the
carry the engine already ships and which the s17 close-up shows. THREE FAMILIES
ARE NOT AUTHORED THAT WAY and the picture says so:

  staff     authored about the MIDDLE of the shaft (-0.43 .. +0.47 local z), so
            laid sideways half the shaft goes back through the hero. Only the
            finial shows. The clip count did NOT catch this - the shaft sits
            behind the cape where a six-ray inside test finds a way out - which
            is the second time this lane has had a number miss what the eye
            sees, so the picture is the verdict and the number is the suspect.
  crossbow  authored FLAT (x 0.69 / y 0.64 / z 0.19): it has no up axis at all
            in the sword's sense, and in the fist it lies along the hip, inside
            the body. Clip 40-50% of its own vertices, and here the number and
            the picture agree.
  shield    authored about its own centre, so it is held through the hip rather
            than off the forearm.

WHAT THIS FILE PRODUCES: for each, the LOCAL rotation that has to sit between
the BoneAttachment3D and the model for the piece to be carried the way a person
carries it - staff upright, crossbow levelled across the body, shield face out -
and a render WITH that rotation applied, so the fix is judged as a picture and
not as a quaternion. THE ROTATION IS NOT BAKED INTO THE MESH: baking it would
hide a pose correction inside an asset, and it would be silently wrong the
moment the idle pose or the attach bone changed. It belongs in gear.gd's
equip(), which is the game build's file - so this file hands over the number
and the proof, and does not reach for it.
"""
import os, sys, json, math, argparse
import bpy
from mathutils import Vector, Matrix

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G
import minibossfit as MF
import weaponfit as WF

# family -> (the model axis that should end up pointing WORLD UP, extra spin)
WANT = {
    "staff":    ("z", 0.0),      # the shaft stands up out of the fist
    "crossbow": ("y", 0.0),      # the stock levels forward, bow across the body
    "shield":   ("y", 0.0),      # the face turns outward instead of into the hip
}
AX = {"x": Vector((1, 0, 0)), "y": Vector((0, 1, 0)), "z": Vector((0, 0, 1))}


def correction(base, axis_name):
    """The LOCAL rotation that sends the model's chosen axis to world up.

    Local, not world: it is what a child node of the BoneAttachment3D would
    carry, so it is the number gear.gd can actually use."""
    R = base.to_3x3()
    cur = (R @ AX[axis_name]).normalized()          # where that axis points now
    want = Vector((0, 0, 1))
    q = cur.rotation_difference(want)               # world-space correction
    Rw = q.to_matrix()
    local = R.inverted() @ Rw @ R                   # same rotation, local frame
    return local.to_4x4(), local.to_euler(), local.to_quaternion()


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--fams", default="staff,crossbow,shield")
    ap.add_argument("--scale", type=float, default=WF.HAND_SCALE)
    ap.add_argument("--prefix", default="fixed_")
    a = ap.parse_args(argv)
    outdir = os.path.join(a.repo, "renders", "art", "system2")
    os.makedirs(outdir, exist_ok=True)
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next(o for o in roots if o.type == 'ARMATURE')
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
        ld = bpy.data.lights.new(nm, 'SUN'); ld.energy = en
        lo = bpy.data.objects.new(nm, ld); lo.rotation_euler = rot
        bpy.context.collection.objects.link(lo)
    bmn, bmx, bpts = G.world_bounds(body)
    cz = (WF.FRAME_H / 2.0) - WF.GROUND_UP

    dg = bpy.context.evaluated_depsgraph_get()
    from mathutils import bvhtree
    trees = []
    for ob in body:
        try:
            trees.append(bvhtree.BVHTree.FromObject(ob, dg))
        except Exception:
            pass
    assert trees, "no body BVH - the before/after clip numbers would be empty"

    out, blanks, clips = {}, [], []
    for fam in [f for f in a.fams.split(",") if f]:
        axis, _spin = WANT[fam]
        C, eul, quat = correction(base, axis)
        rec = dict(axis_to_up=axis, scale=a.scale,
                   local_euler_deg=[round(math.degrees(v), 2) for v in eul],
                   local_quat=[round(v, 5) for v in quat])
        for tier in WF.TIERS:
            objs, path = WF.load_model(a.repo, fam, tier)
            meshes = [o for o in objs if o.type == 'MESH']
            S = Matrix.Diagonal((a.scale,) * 3).to_4x4()
            for o in objs:
                if o.parent is None:
                    o.matrix_world = base @ C @ S @ o.matrix_world
            bpy.context.view_layer.update()
            wv = WF.world_verts(meshes)
            slot = base @ Vector((0, 0, 0))
            far = [v for v in wv if (v - slot).length > WF.FIST_R]
            assert far, "%s %s: every vertex inside the fist - empty test" % (fam, tier)
            n_clip = sum(1 for v in far if WF.inside(trees, v))
            for vname, az in WF.VIEWS:
                p = os.path.join(outdir, "%s%s_%s_%s.png" % (a.prefix, fam, tier, vname))
                WF.shoot(list(body) + meshes, bpts + wv, p, az, cz)
                arr = WF.read_png(p)
                if int((arr[:, :, 3] > 0.02).sum()) == 0:
                    blanks.append(os.path.basename(p))
                b = max(float(arr[0, :, 3].max()), float(arr[-1, :, 3].max()),
                        float(arr[:, 0, 3].max()), float(arr[:, -1, 3].max()))
                if b > 0.02:
                    clips.append(os.path.basename(p))
            rec[tier] = dict(clip_after=n_clip, checked=len(far),
                             tip_z=round(max(v.z for v in wv), 3),
                             low_z=round(min(v.z for v in wv), 3))
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)
        out[fam] = rec
    rp = os.path.join(outdir, "_carry_fix%s.json" % ("" if a.prefix == "fixed_" else "_" + a.prefix.strip("_")))
    with open(rp, "w") as f:
        json.dump(dict(blanks=blanks, frame_clips=clips, families=out), f, indent=1)
    print("CARRY blanks=%d frameclips=%d" % (len(blanks), len(clips)))
    print("CARRY_JSON", json.dumps(out))


if __name__ == "__main__":
    main()
