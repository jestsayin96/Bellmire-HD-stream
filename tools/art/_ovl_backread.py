#!/usr/bin/env python3
"""THE OVERLOOKER'S BACK - DOES THE NEW MARKER ACTUALLY CHANGE THE PICTURE?

WHY THIS IS AN ABLATION AND NOT A MEASUREMENT OF THE THING ITSELF. Trap 5 in
my own prompt, found at pass 11 on 17 Nov: `mask_of` renders a group ALONE,
which answers how BIG a thing is and says NOTHING about whether it can be
SEEN. I shipped `head_glow_px: 156` beside my own sentence "the head now has
no face at all" and both were true. The test that works asks the VIEWER'S
question - render with and without through ONE camera and count the pixels
that MOVED, letting the renderer do the depth.

THE CAMERA IS PINNED, AND THAT IS THE WHOLE REASON THIS FILE EXISTS RATHER
THAN TWO RUNS OF minibossgen. `lordgen.render_views` derives center, radius
AND ortho_scale from the built objects' own bounds. The back span stands
0.027 proud of the coat, so it MOVES THE BOUNDS - two generator runs would be
framed differently and a pixel diff between them would report a huge moved
count for the wrong reason entirely. Here the camera is computed ONCE off the
WITH-BACK build (which is a geometric superset of the WITHOUT one, so it
frames and clips both) and both arms are rendered through it unchanged.

TWO NUMBERS, AND THE SECOND IS THE ONE THAT ANSWERS THE COMPLAINT.
  1. MOVED PX, per view, between the two arms. The BACK view must move a lot.
     THE FRONT VIEW MUST MOVE ZERO - if the front moves, this is not a facing
     cue, it is just more coat, and the claim is false.
  2. FRONT vs MIRRORED-BACK distance, per arm. This is the team lead's own
     test restated as arithmetic: he staged hero_front and hero_back side by
     side and said "the two reads are the same grey slab". A figure with no
     facing scores near zero here. The number has to go UP.

RED ON EMPTY, because a metric computed over zero pixels reads green and
means nothing: every render is asserted to carry opaque pixels, both arms are
asserted to be the same shape, and the mirrored-back overlap is asserted
non-empty before its mean is taken.
"""
import os
import sys
import json
import math

import bpy
import numpy as np
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import lordgen as G          # noqa: E402
import minibossgen as MG     # noqa: E402

KEY = "overlooker"
RESX, RESY = 700, 980
# az, el - lordgen's own convention, plus the BACK that lordgen does not ship.
MYVIEWS = (("front", 0.0, 12.0), ("back", 180.0, 12.0), ("side", 90.0, 11.0))


def _build(on):
    os.environ["OVL_BACK"] = "1" if on else "0"
    G.purge()
    return MG.build_miniboss(KEY)


def _campars(objs, info):
    """Compute center/radius/ortho/clip per view ONCE, off the given build."""
    scene = bpy.context.scene
    mn, mx, pts = G.world_bounds(objs)
    center = (mn + mx) / 2.0
    radius = max(0.35, (mx - mn).length / 2.0)
    pars = {}
    cam_d = bpy.data.cameras.new("probe")
    cam = bpy.data.objects.new("probe", cam_d)
    bpy.context.collection.objects.link(cam)
    cam_d.type = 'ORTHO'
    for vname, az, el in MYVIEWS:
        a, e = math.radians(az), math.radians(el)
        dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e),
                       math.sin(e))).normalized()
        dist = radius * 4.0 + 2.0
        cam.location = center + dirv * dist
        cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
        bpy.context.view_layer.update()
        mw = cam.matrix_world
        right = (mw.to_3x3() @ Vector((1, 0, 0))).normalized()
        up = (mw.to_3x3() @ Vector((0, 1, 0))).normalized()
        fwd = (mw.to_3x3() @ Vector((0, 0, -1))).normalized()
        ru = [abs((p - center).dot(right)) for p in pts]
        uu = [abs((p - center).dot(up)) for p in pts]
        depth = [(p - cam.location).dot(fwd) for p in pts]
        wide, tall = max(ru) * 2.0, max(uu) * 2.0
        need = max(tall, wide * (RESY / float(RESX)))
        pars[vname] = dict(
            loc=tuple(cam.location), rot=tuple(cam.rotation_euler),
            ortho=need * 1.10,
            clip=(max(0.01, min(depth) - radius * 0.5),
                  max(depth) + radius * 2.0 + 5.0))
    pars["_center"] = tuple(center)
    pars["_radius"] = radius
    return pars


def _render(objs, info, pars, outdir, tag):
    scene = bpy.context.scene
    eng = G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = RESX, RESY
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes
               if n.type == 'BACKGROUND'), None)
    if bg:
        bg.inputs['Color'].default_value = (0.045, 0.05, 0.065, 1.0)
        bg.inputs['Strength'].default_value = 1.0
    # lights pinned to the SAME centre/radius for both arms
    G.add_lights(Vector(pars["_center"]), pars["_radius"], info['aura'])
    cam_d = bpy.data.cameras.new("cam_" + tag)
    cam_d.type = 'ORTHO'
    cam = bpy.data.objects.new("cam_" + tag, cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    out = {}
    for vname, _az, _el in MYVIEWS:
        p = pars[vname]
        cam.location = Vector(p["loc"])
        cam.rotation_euler = p["rot"]
        cam_d.ortho_scale = p["ortho"]
        cam_d.clip_start, cam_d.clip_end = p["clip"]
        bpy.context.view_layer.update()
        path = os.path.join(outdir, "%s_%s.png" % (tag, vname))
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        out[vname] = path
    return out, eng


def _load(path):
    a = G.read_png(path)
    return np.asarray(a, dtype=np.float64)


def main():
    repo = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "."
    outdir = os.path.join(repo, "renders", "art", "minibosses",
                          "_ovl_backread")
    os.makedirs(outdir, exist_ok=True)
    rep = {"ok": True, "errors": [], "key": KEY}

    # ARM ON first - it is the geometric superset, so its camera frames both.
    objs_on, info = _build(True)
    rep["parts_on"] = len(objs_on)
    pars = _campars(objs_on, info)
    on, eng = _render(objs_on, info, pars, outdir, "on")
    rep["engine"] = eng

    objs_off, info2 = _build(False)
    rep["parts_off"] = len(objs_off)
    off, _ = _render(objs_off, info2, pars, outdir, "off")

    rep["views"] = {}
    for vname, _a, _e in MYVIEWS:
        A, B = _load(on[vname]), _load(off[vname])
        if A.shape != B.shape:
            rep["ok"] = False
            rep["errors"].append("%s: arm shapes differ %s vs %s"
                                 % (vname, A.shape, B.shape))
            continue
        opA = int((A[..., 3] > 0.5).sum())
        opB = int((B[..., 3] > 0.5).sum())
        # RED ON EMPTY - a blank render scores a perfect zero moved.
        if opA == 0 or opB == 0:
            rep["ok"] = False
            rep["errors"].append(
                "%s: BLANK ARM - opaque px on=%d off=%d" % (vname, opA, opB))
            continue
        d = np.abs(A[..., :3] - B[..., :3]).max(axis=-1)
        moved = int((d > (2.0 / 255.0)).sum())
        moved_hard = int((d > (12.0 / 255.0)).sum())
        # THE ALPHA CHANNEL IS THE ONE THAT ANSWERS "CAN THIS CAMERA SEE IT".
        # RGB moving tells me a photon changed somewhere; ALPHA moving tells
        # me GEOMETRY ENTERED THIS VIEW'S OUTLINE. Pass 1 taught me the
        # difference the hard way - see the front-view note below.
        alpha_moved = int((np.abs(A[..., 3] - B[..., 3]) > 0).sum())
        rep["views"][vname] = dict(
            opaque_on=opA, opaque_off=opB, moved_px=moved,
            moved_px_hard=moved_hard, alpha_moved_px=alpha_moved,
            moved_pct_of_body=round(100.0 * moved / float(opA), 3))

    # ---- the team lead's own test, as arithmetic: FRONT vs MIRRORED BACK.
    rep["facing"] = {}
    for tag, src in (("off", off), ("on", on)):
        F = _load(src["front"])
        Bk = _load(src["back"])[:, ::-1, :]        # mirrored, so it overlays
        mask = (F[..., 3] > 0.5) & (Bk[..., 3] > 0.5)
        n = int(mask.sum())
        if n == 0:
            rep["ok"] = False
            rep["errors"].append(
                "%s: front/mirrored-back overlap is EMPTY - the distance "
                "below would be a mean of nothing" % tag)
            continue
        diff = np.abs(F[..., :3] - Bk[..., :3]).mean(axis=-1)
        rep["facing"][tag] = dict(
            overlap_px=n,
            mean_abs_diff=round(float(diff[mask].mean()), 5),
            frac_over_0p05=round(float((diff[mask] > 0.05).mean()), 5))
    if "off" in rep["facing"] and "on" in rep["facing"]:
        a = rep["facing"]["off"]["mean_abs_diff"]
        b = rep["facing"]["on"]["mean_abs_diff"]
        rep["facing"]["delta"] = round(b - a, 5)
        rep["facing"]["ratio"] = round(b / max(1e-9, a), 3)

    # ---- the two assertions this run actually stands on.
    v = rep.get("views", {})
    if v.get("back", {}).get("moved_px", 0) <= 0:
        rep["ok"] = False
        rep["errors"].append(
            "BACK VIEW DID NOT MOVE - the marker is not visible from behind")
    # THE FRONT GATE, AND PASS 1 MOVED IT ONTO THE RIGHT CHANNEL. Pass 1
    # failed its own front gate on `moved_px != 0`: NINE pixels, scattered
    # over the torso, worst delta 5/255, zero of them over the hard
    # threshold. I went to narrow the yoke and checked the cause first
    # instead, and the cause was not geometry at all - the front view's
    # ALPHA was untouched on every one of 686,000 pixels, so nothing of the
    # back span entered the front outline. Those nine pixels are the
    # LIGHTING SOLUTION: new dark geometry behind him changes what bounces,
    # by up to 5/255, on nine pixels. A gate that demands no photon anywhere
    # changed is not testing what I claimed; the claim is that the front
    # CAMERA CANNOT SEE IT, and alpha is the channel that answers it.
    # So the bar is now: ZERO alpha moved AND ZERO hard-threshold pixels,
    # with the soft count published rather than hidden.
    fv = v.get("front")
    if fv is None:
        rep["ok"] = False
        rep["errors"].append("front view produced no number at all")
    else:
        if fv["alpha_moved_px"] != 0:
            rep["ok"] = False
            rep["errors"].append(
                "FRONT OUTLINE MOVED on %d px - back-span geometry has "
                "entered the FRONT silhouette, so this is not a facing cue, "
                "it is more coat" % fv["alpha_moved_px"])
        if fv["moved_px_hard"] != 0:
            rep["ok"] = False
            rep["errors"].append(
                "FRONT VIEW MOVED %d px BY MORE THAN 12/255 - too big to be "
                "the light bouncing; something is visible from the front"
                % fv["moved_px_hard"])

    with open(os.path.join(outdir, "_ovl_backread.json"), "w") as f:
        json.dump(rep, f, indent=1)
    print("OVL_BACKREAD " + json.dumps(rep))


if __name__ == "__main__":
    main()
