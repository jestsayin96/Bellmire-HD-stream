"""_reachread.py - CAN A VIEWER READ THE REACH? The one question the mower's
register cannot answer.

  blender -b -noaudio -P tools/art/_reachread.py -- --repo <repo>

WHY THIS EXISTS. The Mower's mechanic is a LENGTH: the party has to judge how
far the stroke goes in order to know how far in they must get. `_fit_report`
answers fits_frame, air_px, frame_edge, seen and blank for this body and NONE
of them is about that. `seen: 1.0` says the man is distinguishable from his
gear; it does not say the blade is long, level or low, and it would read 1.0
on a mower holding a knife.

THE PASS-11 LESSON IS BUILT IN. `mask_of` renders a group ALONE, which answers
how BIG a thing is and says nothing about whether it can be SEEN. So the
primary number here is an A/B THROUGH ONE CAMERA: the shipped front view is
measured against the same view with the blade span removed, and the pixels
that MOVED are counted - the renderer does the depth, not me.

AND IT CARRIES A MAGNITUDE FLOOR, which is the badger's pass-6 finding and the
third time this house has paid for its absence: a diff count with no floor
measures the renderer's anti-aliasing, not the geometry. 12/255 on any channel,
the same floor that took a "610-row waist belt" down to the 53 rows a waist
belt actually is.

RED ON EMPTY, which is trap 4: a metric computed over zero pixels reads green
and means nothing. Zero moved pixels is the loudest possible failure here - it
would mean the blade is not in the picture at all - so it is an ERROR and not
a 0.0.
"""
import os
import sys
import json
import argparse
import math

import bpy
import numpy as np
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402
import minibossgen as MG     # noqa: E402

FLOOR = 12.0 / 255.0
KEY = "mower"


def build(blade):
    G.purge()
    M._MOWER_NOBLADE = not blade
    objs, _meta = MG.build_miniboss(KEY)
    return objs


def rig(scene, center, radius, aura, resx, resy):
    scene.render.resolution_x, scene.render.resolution_y = resx, resy
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes if n.type == 'BACKGROUND'), None)
    if bg:
        bg.inputs['Color'].default_value = (0.045, 0.05, 0.065, 1.0)
        bg.inputs['Strength'].default_value = 1.0
    G.add_lights(center, radius, aura)


def shoot(path, center, radius, az, el, ortho):
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    bpy.context.scene.camera = cam
    a, e = math.radians(az), math.radians(el)
    dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e),
                   math.sin(e))).normalized()
    dist = radius * 4.0 + 2.0
    cam.location = center + dirv * dist
    cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
    cam_d.ortho_scale = ortho
    cam_d.clip_start = 0.01
    cam_d.clip_end = dist + radius * 3.0 + 5.0
    bpy.context.view_layer.update()
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    args = ap.parse_args(argv)
    out = os.path.join(args.repo, "renders", "art", "minibosses", "_ab_mower")
    os.makedirs(out, exist_ok=True)
    rep = {"key": KEY, "floor_255": 12, "errors": [], "ok": False}

    # THE FRAME IS FIXED BY THE FULL BODY AND USED FOR BOTH RENDERS. If the
    # cut body were allowed to re-frame itself the comparison would be of two
    # different pictures and every pixel would "move".
    objs = build(True)
    bpy.context.view_layer.update()
    lo, hi, _pts = G.world_bounds(objs)
    center = (lo + hi) * 0.5
    radius = (hi - lo).length * 0.5
    ortho = max((hi[0] - lo[0]), (hi[2] - lo[2])) * 1.18
    rep["bounds"] = {"w": round(hi[0] - lo[0], 3), "h": round(hi[2] - lo[2], 3),
                     "d": round(hi[1] - lo[1], 3)}
    aura = M.CANON[KEY][3]
    rig(bpy.context.scene, center, radius, aura, 700, 980)
    p_with = shoot(os.path.join(out, "front_with.png"), center, radius, 0.0, 0.0, ortho)

    build(False)
    bpy.context.view_layer.update()
    rig(bpy.context.scene, center, radius, aura, 700, 980)
    p_without = shoot(os.path.join(out, "front_without.png"), center, radius, 0.0, 0.0, ortho)
    M._MOWER_NOBLADE = False

    A, B = G.read_png(p_with), G.read_png(p_without)
    if A.shape != B.shape:
        rep["errors"].append("A/B frames differ in shape")
        print("REACHREAD " + json.dumps(rep)); return
    body = A[..., 3] > 0.5
    if not body.any():
        rep["errors"].append("the WITH render has no opaque pixels - blank")
        print("REACHREAD " + json.dumps(rep)); return
    d = np.max(np.abs(A[..., :3] - B[..., :3]), axis=-1)
    da = np.abs(A[..., 3] - B[..., 3])
    moved = (np.maximum(d, da) >= FLOOR)
    n = int(moved.sum())
    rep["body_px"] = int(body.sum())
    rep["moved_px"] = n
    if n == 0:
        rep["errors"].append(
            "RED ON EMPTY: removing the blade moved ZERO pixels above the "
            "floor. The reach is not in the picture at all, whatever its size.")
        print("REACHREAD " + json.dumps(rep)); return
    bx = np.where(body.any(axis=0))[0]
    by = np.where(body.any(axis=1))[0]
    mx = np.where(moved.any(axis=0))[0]
    my = np.where(moved.any(axis=1))[0]
    rep["moved_frac_of_body"] = round(n / float(body.sum()), 4)
    rep["reach_share"] = round((mx[-1] - mx[0]) / float(max(1, bx[-1] - bx[0])), 3)
    rep["blade_rows"] = int(my[-1] - my[0] + 1)
    rep["blade_row_frac"] = round(rep["blade_rows"] / float(max(1, by[-1] - by[0] + 1)), 3)
    mid = (my[0] + my[-1]) / 2.0
    rep["blade_height_frac"] = round((by[-1] - mid) / float(max(1, by[-1] - by[0])), 3)
    # THE SAME COUNT WITH NO FLOOR, printed beside it on purpose: the badger's
    # pass-6 finding was that the unfloored number is the renderer talking.
    rep["moved_px_nofloor"] = int((np.maximum(d, da) > 0.0).sum())
    rep["ok"] = not rep["errors"]
    print("REACHREAD " + json.dumps(rep))


if __name__ == "__main__":
    main()
