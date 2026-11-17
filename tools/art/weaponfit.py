"""weaponfit - ART'S HALF OF SYSTEM 2: the 24 KayKit dungeon weapons, in a hand.

  blender -b -noaudio -P tools/art/weaponfit.py -- --repo <repo> [--fams ...]

System 2 is "named weapons wired live". The GAME BUILD wires gear.gd; the art
half is the models themselves and the only thing that makes them shippable:
PROOF THEY SIT IN A HAND. Nine of the 24 (sword, axe, hammer) are already in
the repo and already wired. Fifteen were still sitting in the pack. This file
puts all 24 on the same body at the same framing and MEASURES each one, so the
three that are wired and the five families that are not are judged by one
instrument.

WHAT IS MEASURED, PER MODEL:
  reach      tip height above the fist, in metres, on a 2.45 m hero
  drop       how far the pommel hangs below the fist
  clip       weapon vertices INSIDE the body surface, excluding the fist
             sphere - the grip is inside the fist BY DESIGN and is not a fault
  ground     vertices below z=0 (the weapon dragging through the floor)
  frame      vertices outside the fixed camera frame (a crop is a fault)

AND THE INSTRUMENT GOES RED ON EMPTY. A clip count taken over zero vertices,
or a cell whose model failed to import, is a FAIL and not a silent green - the
lane has shipped a metric computed over nothing before and it read green.

THE CARRY IS THE ENGINE'S, AND IT HAD TO BE CALIBRATED BEFORE IT COULD BE
TRUSTED. Pass 1 carried the weapon to the fist UPRIGHT - showcasegen's
hand_delta convention, which is right for a procedural blade authored world-up
and WRONG for these. The register read GREEN and the picture showed the sword
buried in the torso: the same family of fault this lane found at pass 11, a
number that cannot see what a viewer sees. The engine parents to a
BoneAttachment3D, which takes the bone's FULL posed basis, so this driver now
uses `rig.matrix_world @ pose_bone("handslot.r").matrix` - measured against the
four candidate axis corrections in _s2_cal.py and against the game build's own
s17 close-up, where the axe hangs from the fist with the haft along the hand.
Identity is the correction; the other three lay the haft through the legs or
out the back.
"""
import os
import sys
import json
import math
import argparse

import bpy
import numpy as np
from mathutils import Vector, Matrix, bvhtree

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibossfit as MF     # noqa: E402

FAMS = ["sword", "axe", "hammer", "dagger", "staff", "crossbow", "axeDouble", "shield"]
TIERS = ["common", "uncommon", "rare"]
HAND_SCALE = 0.8             # gear.gd:205, measured at S16 for the DUN pack
FIST_R = 0.16                # the mitt: 0.15 across plus a margin. Inside = by design.
CELL_X, CELL_Y = 760, 760   # square: pass 2 cropped three swords and two daggers
                            # off a 520-wide cell once the carry went horizontal
FRAME_H = 3.80               # metres of world height in the cell, fixed for all 24.
                             # 3.30 still cropped sword_rare (1.50 m of blade held out); this does not.
GROUND_UP = 0.18
VIEWS = [("front", 0.0), ("side", 90.0), ("back", 180.0)]
ELEV = 6.0


def world_verts(objs):
    dg = bpy.context.evaluated_depsgraph_get()
    out = []
    for ob in objs:
        ev = ob.evaluated_get(dg)
        me = ev.to_mesh()
        m = ob.matrix_world
        out.extend([m @ v.co.copy() for v in me.vertices])
        ev.to_mesh_clear()
    return out


def inside(trees, p):
    """Six rays. All six hit something -> the point is inside a closed body."""
    dirs = [Vector(d) for d in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))]
    for t in trees:
        if all(t.ray_cast(p, d, 3.0)[0] is not None for d in dirs):
            return True
    return False


def load_model(repo, fam, tier):
    p = os.path.join(repo, "assets", "gear", "dungeon", "%s_%s.glb" % (fam, tier))
    if not os.path.isfile(p):
        return [], p
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=p)
    new = [o for o in bpy.data.objects if o not in before]
    bpy.context.view_layer.update()
    return new, p


def shoot(objs, pts, path, az, cz):
    scene = bpy.context.scene
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    a, e = math.radians(az), math.radians(ELEV)
    dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e))).normalized()
    centre = Vector((0.0, 0.0, cz))
    cam.location = centre + dirv * 9.0
    cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
    bpy.context.view_layer.update()
    fwd = (cam.matrix_world.to_3x3() @ Vector((0, 0, -1))).normalized()
    depth = [(p - cam.location).dot(fwd) for p in pts] or [8.0]
    cam_d.ortho_scale = FRAME_H
    cam_d.clip_start = max(0.01, min(depth) - 1.0)
    cam_d.clip_end = max(depth) + 4.0
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    mwi = cam.matrix_world.inverted()
    half_v = FRAME_H / 2.0
    half_h = FRAME_H * (CELL_X / float(CELL_Y)) / 2.0
    outside = sum(1 for p in pts if abs((mwi @ p).y) > half_v or abs((mwi @ p).x) > half_h)
    bpy.data.objects.remove(cam, do_unlink=True)
    return outside


def read_png(path):
    im = bpy.data.images.load(path, check_existing=False)
    w, h = im.size
    a = np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4)
    bpy.data.images.remove(im)
    return a


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--fams", default=",".join(FAMS))
    a = ap.parse_args(argv)
    fams = [f for f in a.fams.split(",") if f]
    outdir = os.path.join(a.repo, "renders", "art", "system2")
    os.makedirs(outdir, exist_ok=True)

    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)

    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next((o for o in roots if o.type == 'ARMATURE'), None)
    assert rig is not None, "no armature in the hero glb"
    assert hinfo["posed"], "hero is in REST pose - the idle action did not take"
    bpy.context.view_layer.update()
    pb = rig.pose.bones["handslot.r"]
    base = rig.matrix_world @ pb.matrix
    slot = base @ Vector((0, 0, 0))

    scene = bpy.context.scene
    G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = CELL_X, CELL_Y
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

    body_trees = []
    dg = bpy.context.evaluated_depsgraph_get()
    for ob in body:
        try:
            body_trees.append(bvhtree.BVHTree.FromObject(ob, dg))
        except Exception:
            pass
    assert body_trees, "no BVH built from the body - the clip test would read 0 over nothing"

    bmn, bmx, bpts = G.world_bounds(body)
    cz = (FRAME_H / 2.0) - GROUND_UP

    reg, errors, blanks, clipped_frames = {}, [], [], []
    for fam in fams:
        for tier in TIERS:
            key = "%s_%s" % (fam, tier)
            objs, path = load_model(a.repo, fam, tier)
            meshes = [o for o in objs if o.type == 'MESH']
            if not meshes:
                errors.append("%s: no mesh imported from %s" % (key, path))
                for o in objs:
                    bpy.data.objects.remove(o, do_unlink=True)
                continue
            S = Matrix.Diagonal((HAND_SCALE,) * 3).to_4x4()
            for o in objs:
                if o.parent is None:
                    o.matrix_world = base @ S @ o.matrix_world
            bpy.context.view_layer.update()
            wv = world_verts(meshes)
            if not wv:
                errors.append("%s: zero vertices - the clip test would be empty" % key)
                for o in objs:
                    bpy.data.objects.remove(o, do_unlink=True)
                continue
            zs = [v.z for v in wv]
            far = [v for v in wv if (v - slot).length > FIST_R]
            if not far:
                errors.append("%s: every vertex is inside the fist sphere - clip test empty" % key)
            n_clip = sum(1 for v in far if inside(body_trees, v))
            n_ground = sum(1 for v in wv if v.z < -0.002)
            rec = dict(model=os.path.relpath(path, a.repo).replace("\\", "/"),
                       verts=len(wv), checked=len(far),
                       reach=round(max(zs) - slot.z, 3), drop=round(slot.z - min(zs), 3),
                       span=round(max(v.x for v in wv) - min(v.x for v in wv), 3),
                       tip_z=round(max(zs), 3), hero_h=round(hinfo["h"], 3),
                       clip=n_clip, ground=n_ground, hand_scale=HAND_SCALE)
            allpts = bpts + wv
            outs = {}
            for vname, az in VIEWS:
                png = os.path.join(outdir, "%s_%s.png" % (key, vname))
                outs[vname] = shoot(list(body) + meshes, allpts, png, az, cz)
                arr = read_png(png)
                op = int((arr[:, :, 3] > 0.02).sum())
                if op == 0:
                    blanks.append(os.path.basename(png))
                b = max(float(arr[0, :, 3].max()), float(arr[-1, :, 3].max()),
                        float(arr[:, 0, 3].max()), float(arr[:, -1, 3].max()))
                if b > 0.02:
                    clipped_frames.append(os.path.basename(png))
                rec.setdefault("opaque", {})[vname] = op
                rec.setdefault("border", {})[vname] = round(b, 4)
            rec["outside"] = outs
            reg[key] = rec
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)

    want = len(fams) * len(TIERS)
    if len(reg) != want:
        errors.append("register has %d of %d cells" % (len(reg), want))
    if not reg:
        errors.append("EMPTY REGISTER - nothing was measured, this is a FAIL not a pass")
    ok = (not errors) and (not blanks) and (not clipped_frames)
    out = dict(verdict="GREEN" if ok else "FAIL", ok=ok, hero=hinfo,
               handslot=[round(v, 4) for v in slot], cells=len(reg),
               blanks=blanks, frame_clips=clipped_frames, errors=errors, models=reg)
    rp = os.path.join(outdir, "_fit_register.json")
    with open(rp, "w") as f:
        json.dump(out, f, indent=1)
    print("WEAPONFIT verdict=%s cells=%d blanks=%d frameclips=%d errors=%d"
          % (out["verdict"], len(reg), len(blanks), len(clipped_frames), len(errors)))
    for e in errors:
        print("  ERROR", e)
    print("WEAPONFIT_DONE", rp)


if __name__ == "__main__":
    main()
