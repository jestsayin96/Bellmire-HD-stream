"""_s2_cal - WHICH TRANSFORM IS THE ENGINE'S? Four candidates, one picture.

The first fit pass carried the weapon to the fist UPRIGHT. The picture showed
the blade buried in the torso while the register read GREEN - the same family
of fault this lane found at pass 11: a number that cannot see what the viewer
sees. The engine parents to a BoneAttachment3D, which takes the bone's FULL
posed basis, and Blender's glTF importer re-axes bones on import, so the
correction between the two has to be MEASURED, not assumed.

So: the same model, four candidate corrections, one sheet, and the engine's own
s17 close-up is the control - the axe hangs from the fist with the haft along
the hand, head down by the knee.
"""
import os, sys, math, json, argparse
import bpy, numpy as np
from mathutils import Vector, Matrix

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G
import minibossfit as MF
import weaponfit as WF

CANDS = [("ident", Matrix.Identity(4)),
         ("rx-90", Matrix.Rotation(math.radians(-90), 4, 'X')),
         ("rx+90", Matrix.Rotation(math.radians(90), 4, 'X')),
         ("rx180", Matrix.Rotation(math.radians(180), 4, 'X'))]


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--model", default="axe_uncommon")
    a = ap.parse_args(argv)
    outdir = os.path.join(a.repo, "renders", "art", "system2", "_cal")
    os.makedirs(outdir, exist_ok=True)
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next(o for o in roots if o.type == 'ARMATURE')
    bpy.context.view_layer.update()
    pb = rig.pose.bones["handslot.r"]
    base = rig.matrix_world @ pb.matrix

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

    rep = {}
    for nm, C in CANDS:
        objs, path = WF.load_model(a.repo, *a.model.rsplit("_", 1))
        meshes = [o for o in objs if o.type == 'MESH']
        S = Matrix.Diagonal((WF.HAND_SCALE,) * 3).to_4x4()
        for o in objs:
            if o.parent is None:
                o.matrix_world = base @ C @ S @ o.matrix_world
        bpy.context.view_layer.update()
        wv = WF.world_verts(meshes)
        for vname, az in (("front", 0.0), ("side", 90.0)):
            p = os.path.join(outdir, "%s_%s_%s.png" % (a.model, nm, vname))
            WF.shoot(list(body) + meshes, bpts + wv, p, az, cz)
        rep[nm] = dict(tip_z=round(max(v.z for v in wv), 3),
                       min_z=round(min(v.z for v in wv), 3),
                       x=[round(min(v.x for v in wv), 3), round(max(v.x for v in wv), 3)],
                       y=[round(min(v.y for v in wv), 3), round(max(v.y for v in wv), 3)])
        for o in objs:
            bpy.data.objects.remove(o, do_unlink=True)
    print("CAL", json.dumps(rep))


main()
