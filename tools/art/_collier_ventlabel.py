#!/usr/bin/env python3
"""_collier_ventlabel.py - WHICH MARK IS A VENT AND WHICH IS A SEAM?

  blender -b -noaudio -P tools/art/_collier_ventlabel.py -- --repo <repo>

WHY THIS EXISTS, AND IT IS THE SAME FAULT AS 17 NOV PASS 11 FOR THE THIRD TIME.
Every collier reading since pass 7 comes off `MB_CUEOFF=glow`, which turns off
EVERY glow on this body at once: the four vent mouths AND the three ember
seams. So the front A/B's SEVEN marks have been divided into "four vents and
three somethings" BY EYE, and pass 8 ticked a count of four taken that way.
A number that needs an eye to attribute it is not labelled, it is guessed.

So this renders THREE arms through ONE LOCKED CAMERA:
    full      - the body as it ships
    glowoff   - MB_CUEOFF=glow, every glow swapped for body, no vertex moved
    seamoff   - COLLIER_SEAMOFF=1, the three seams gone, vents untouched
and takes two differences:
    full - glowoff  = every lit mark (vents AND seams), which is what every
                      previous pass measured and called "the vents"
    seamoff - glowoff = THE VENTS ALONE
    full - seamoff  = THE SEAMS ALONE
Each mark is then labelled by construction. The camera is measured ONCE off the
full body and LOCKED, because a camera that re-fits per arm moves every pixel
and the count reads green for nothing (the Beadle's pass-12 lesson).

*** THERE IS NO THRESHOLD IN IT. *** 05:58 ruling, 25 Nov: no lane invents a
MIN_CUE_PX. ZERO is the only reading that is a verdict on its own; everything
else goes beside a picture somebody looked at.

*** RED ON EMPTY, AND RED ON A DIFFERENCE THAT CANNOT EXIST. ***
  - any arm whose render is blank, or touches the frame border, is RED;
  - `seamoff - glowoff` reading ZERO marks is RED: that is either a body with
    no vents at all or an A/B that did not take;
  - `full - seamoff` reading ZERO marks is RED: COLLIER_SEAMOFF did nothing,
    so the labelling is a fiction and must not be believed;
  - a run that compared no pairs is RED.
"""
import os
import sys
import json
import math
import argparse
from collections import deque

import bpy
import numpy as np
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordlib as L          # noqa: E402,F401
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402,F401
import minibossgen as MG     # noqa: E402

KEY = "collier"
THRESH = 8.0 / 255.0
# The shipping front camera: minibossfit.shoot hard-codes elevation 6.0 and
# ortho_scale FRAME_W on a 760x520 cell. Matched here so a mark's screen x is
# comparable with `_vent_marks.json`.
FRONT_AZ, FRONT_EL = 0.0, 6.0
CELL_X, CELL_Y = 760, 520
FRAME_W = 5.60


def _args():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    return ap.parse_args(a)


def build(cueoff="", seamoff=False):
    G.purge()
    for k, v in (("MB_CUEOFF", cueoff),
                 ("COLLIER_SEAMOFF", "1" if seamoff else "")):
        if v:
            os.environ[k] = v
        else:
            os.environ.pop(k, None)
    return MG.build_miniboss(KEY)


def rig(scene, center, radius, aura):
    scene.render.resolution_x, scene.render.resolution_y = CELL_X, CELL_Y
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


def shoot(path, target, radius):
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam_d.ortho_scale = FRAME_W
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    bpy.context.scene.camera = cam
    a, e = math.radians(FRONT_AZ), math.radians(FRONT_EL)
    dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e),
                   math.sin(e))).normalized()
    dist = radius * 4.0 + 4.0
    cam.location = target + dirv * dist
    cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
    cam_d.clip_start = 0.01
    cam_d.clip_end = dist + radius * 3.0 + 8.0
    bpy.context.view_layer.update()
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam, do_unlink=True)
    return path


def marks(m):
    h, w = m.shape
    seen = np.zeros_like(m, bool)
    out = []
    for y in range(h):
        for x in range(w):
            if m[y, x] and not seen[y, x]:
                q = deque([(y, x)]); seen[y, x] = True; px = []
                while q:
                    cy, cx = q.popleft(); px.append((cy, cx))
                    for dy, dx in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)):
                        ny, nx = cy+dy, cx+dx
                        if 0 <= ny < h and 0 <= nx < w and m[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True; q.append((ny, nx))
                out.append(px)
    return sorted(out, key=len, reverse=True)


def diff_marks(pa, pb):
    A, B = G.read_png(pa), G.read_png(pb)
    assert A.shape == B.shape, "shape %s vs %s" % (A.shape, B.shape)
    d = np.max(np.abs(A[..., :3] - B[..., :3]), axis=-1)
    da = np.abs(A[..., 3] - B[..., 3])
    mk = marks(np.maximum(d, da) > THRESH)
    return [{"px": len(p),
             "cx": round(sum(q[1] for q in p) / len(p), 1),
             "cy": round(sum(q[0] for q in p) / len(p), 1)} for p in mk[:14]]


def blank_and_border(path):
    a = G.read_png(path)
    al = a[..., 3]
    return (int((al > 0.5).sum()),
            round(max(float(al[0, :].max()), float(al[-1, :].max()),
                      float(al[:, 0].max()), float(al[:, -1].max())), 4))


def main():
    ns = _args()
    out = os.path.join(ns.repo, "renders", "art", "minibosses", "collier_vlabel")
    os.makedirs(out, exist_ok=True)
    rep = {"key": KEY, "camera": {"az": FRONT_AZ, "el": FRONT_EL,
                                  "ortho": FRAME_W, "cell": [CELL_X, CELL_Y],
                                  "locked": True},
           "not_a_pass": "no threshold; ZERO is the only verdict on its own "
                         "(05:58 ruling, 25 Nov).",
           "arms": {}, "labels": {}, "errors": []}
    scene = bpy.context.scene
    MG.G.set_engine(scene)

    # ---- the camera is measured ONCE off the full body and then LOCKED ----
    objs, info = build()
    mn, mx, _ = G.world_bounds(objs)
    radius = max(0.5, (mx - mn).length / 2.0)
    target = Vector(((mn.x + mx.x) / 2.0, (mn.y + mx.y) / 2.0,
                     (mn.z + mx.z) / 2.0))
    rep["camera"]["target"] = [round(c, 4) for c in target]
    rig(scene, target, radius, info["aura"])
    paths = {"full": shoot(os.path.join(out, "full_front.png"), target, radius)}

    for name, kw in (("glowoff", dict(cueoff="glow")),
                     ("seamoff", dict(seamoff=True))):
        o2, i2 = build(**kw)
        rig(scene, target, radius, i2["aura"])
        paths[name] = shoot(os.path.join(out, "%s_front.png" % name),
                            target, radius)

    for name, p in paths.items():
        op, edge = blank_and_border(p)
        rep["arms"][name] = {"opaque_px": op, "border_alpha": edge}
        if op == 0:
            rep["errors"].append("%s render is BLANK - RED" % name)
        if edge > 0.02:
            rep["errors"].append("%s touches the frame border (alpha %.3f) - "
                                 "a clipped render is not a blank one and the "
                                 "blank check cannot see it. RED" % (name, edge))

    rep["labels"]["all_lit__full_minus_glowoff"] = diff_marks(
        paths["full"], paths["glowoff"])
    rep["labels"]["vents_only__seamoff_minus_glowoff"] = diff_marks(
        paths["seamoff"], paths["glowoff"])
    rep["labels"]["seams_only__full_minus_seamoff"] = diff_marks(
        paths["full"], paths["seamoff"])

    v = rep["labels"]["vents_only__seamoff_minus_glowoff"]
    s = rep["labels"]["seams_only__full_minus_seamoff"]
    if not v:
        rep["errors"].append("VENTS-ONLY difference is EMPTY - either this body "
                             "has no visible vents at all or the A/B did not "
                             "take. RED, never skipped.")
    if not s:
        rep["errors"].append("SEAMS-ONLY difference is EMPTY - COLLIER_SEAMOFF "
                             "changed nothing, so every label in this file is a "
                             "fiction. RED.")
    rep["vent_mark_count"] = len(v)
    rep["seam_mark_count"] = len(s)
    rep["ok"] = not rep["errors"]
    dst = os.path.join(out, "_ventlabel.json")
    json.dump(rep, open(dst, "w"), indent=1)
    print("WROTE %s ok=%s" % (dst, rep["ok"]))
    print("VENTS ONLY:", json.dumps(v))
    print("SEAMS ONLY:", json.dumps(s))
    print("ALL LIT   :", json.dumps(rep["labels"]["all_lit__full_minus_glowoff"]))
    print("ERRORS    :", rep["errors"])


main()
