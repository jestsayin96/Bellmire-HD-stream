"""_cuevalue.py - DOES THE PALE CUE STILL OUTRANK THE REST OF THE BODY, IN THE
VALUE THE VIEWER ACTUALLY GETS?

  blender -b -noaudio -P tools/art/_cuevalue.py -- --repo <repo> --key thatcher

WHY THIS EXISTS, AND IT IS A CORRECTION OF MY OWN INSTRUMENT. The thatcher's
builder asserts `bone_l / body_l >= 1.30` and, from pass 7, `bone_l / lap_l >=
2.00`. BOTH ARE COMPUTED ON ALBEDO - the rgb in the OVERRIDE table - and
**pass 6 of that body proved, by measurement, that albedo is not value in this
rig**: re-slotting the skirt from `body` (albedo luma 0.142) to `dark` (0.049),
a 2.9x albedo step, moved the rendered p50 by 0.037 and did not move
`bands_5pct` at all. The even light rig plus the world term lift everything, so
an albedo ratio OVERSTATES the separation a viewer gets, by a lot.

SO THE BUILD-TIME ASSERTION GUARDS THE CUE IN THE WRONG SPACE. It is the
pass-11 fault in a new coat: a number that answers a question the picture was
never asked. The Beadle shipped `seen: 1.0` with no face; this body could ship
`bone/lap 2.29` with a lap that argues with the reed, and every number would
pass. THIS FILE ASKS THE VIEWER'S QUESTION INSTEAD - the only version of it
that has survived contact with a picture in this lane:

  RENDER WITH AND WITHOUT, THROUGH ONE LOCKED CAMERA, AND COUNT THE PIXELS
  THAT MOVED. Luma is then read off the SHIPPED frame at those pixels.

  reed  = pixels where B differs from the frame with the `bone` mesh hidden,
          i.e. where the reed is the FRONT-MOST thing. Not `mask_of`, which
          renders a group alone and answers how BIG it is, never whether it
          can be SEEN.
  lap   = pixels where B differs from a frame built with the lap painted the
          slot's own FILL colour. Geometry is byte-identical between the two
          builds, so the camera, the lights and the bounds cannot move and the
          only thing that can differ is the lap's colour.

WHAT THIS FILE CANNOT SEE, SAID PLAINLY. It measures VALUE and nothing else.
Two masses can be well separated in luma and still argue, through hue, through
touching silhouettes, or through one being shaped like the other. It also says
nothing about whether either mass READS AS WHAT IT IS - the reed reading as
reed is answered by looking, as it was at passes 1-3, and by nothing here.
AND IT GOES RED ON EMPTY: a margin computed over zero pixels reads green and
means nothing, so a mask under 500 px is an ERROR and not a pass.
"""
import os
import sys
import json
import math
import argparse

import bpy
import numpy as np
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordlib as L          # noqa: E402
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402
import minibossgen as MG     # noqa: E402
import minibossfit as F      # noqa: E402

EPS = 2.0 / 255.0
VIEWS = (("front", 0.0), ("side", 90.0), ("back", 180.0))


def _clear():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)


def _luma(a):
    return 0.2126 * a[:, :, 0] + 0.7152 * a[:, :, 1] + 0.0722 * a[:, :, 2]


def _stats(lum, mask, name, errs, key):
    n = int(mask.sum())
    if n < 500:
        errs.append("%s: %s mask is %d px - nothing was measured, and a "
                    "margin over no pixels is not a pass" % (key, name, n))
        return dict(px=n, red="mask under 500 px")
    v = lum[mask]
    # PASS 8 ADDS THE SPREAD, AND IT IS HERE BECAUSE A p50 CANNOT ANSWER THE
    # QUESTION THIS INSTRUMENT WAS BUILT FOR. Two masses at the SAME median do
    # not argue equally: a flat mass beside a flat mass is one shape, and a
    # MODULATED mass beside a flat one still separates - the eye reads the
    # internal variation as a different material even where the medians sit on
    # top of each other. The thatcher's side view is exactly that case, so a
    # pass judged on p50 alone could move the picture and measure nothing, or
    # move the number and change nothing a viewer sees. p5/p95 are reported for
    # BOTH masses so the comparison is like for like.
    return dict(px=n,
                p50=round(float(np.percentile(v, 50)), 4),
                p90=round(float(np.percentile(v, 90)), 4),
                p5=round(float(np.percentile(v, 5)), 4),
                p95=round(float(np.percentile(v, 95)), 4),
                spread=round(float(np.percentile(v, 95) - np.percentile(v, 5)), 4),
                mean=round(float(v.mean()), 4))


def _shot(path, hide=()):
    for o in hide:
        o.hide_render = True
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    for o in hide:
        o.hide_render = False
    return G.read_png(path)


def _build(key, flatten_lap):
    """Build the body. flatten_lap repaints the lap with the slot FILL, which
    is what every unpainted `body` item already gets, so the two builds differ
    in exactly one colour and in no vertex."""
    _clear()
    if flatten_lap:
        # THE FIRST CUT OF THIS PATCHED `Parts._vc` AND MEASURED 0 PIXELS, AND
        # THE RED-ON-EMPTY GUARD BELOW IS THE ONLY REASON I KNOW. The thatcher
        # writes `P.vcols[id(item)]` DIRECTLY - the Collier's pattern - and
        # never goes through `_vc` at all, so the "flattened" build was
        # byte-identical to the real one and the margin would have been
        # computed over nothing. A metric over zero pairs reads green and
        # means nothing; this one went red and named the mask size.
        # The hook that cannot be dodged is the MERGE, because that is where
        # `vcols` is consumed, and dropping it is exactly the documented
        # unpainted path: every item is painted the slot's declared fill.
        real = M.merge_objs

        def _flat(k, items, mats, suffix=None, vcols=None):
            return real(k, items, mats, suffix=suffix, vcols=None)
        M.merge_objs = _flat
        try:
            objs, meta = MG.build_miniboss(key)
        finally:
            M.merge_objs = real
    else:
        objs, meta = MG.build_miniboss(key)
    return objs, meta


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--key", default="thatcher")
    ap.add_argument("--cue-slot", default="bone")
    ap.add_argument("--out", default="")
    # A/B ARMS MUST NOT OVERWRITE EACH OTHER. Pass 8 sweeps one parameter over
    # three arms and compares them; without a tag the second arm silently eats
    # the first and the "comparison" is one render against itself.
    ap.add_argument("--tag", default="")
    args = ap.parse_args(argv)
    key = args.key
    tag = args.tag
    outdir = os.path.join(args.repo, "renders", "art", "minibosses", "_cuevalue")
    os.makedirs(outdir, exist_ok=True)
    tmp = os.path.join(outdir, "_tmp" + tag)
    os.makedirs(tmp, exist_ok=True)
    errs = []
    rep = {"key": key, "tag": tag, "cue_slot": args.cue_slot, "views": {}, "errors": errs,
           "asks": "the SHIPPED screen luma of the pale cue against the lap, "
                   "per view, measured by with/without through one locked "
                   "camera - NOT an albedo ratio",
           "cannot_see": "hue, touching silhouettes, and whether either mass "
                         "reads as what it IS. Those are answered by looking."}

    objs, meta = _build(key, False)
    cue = [o for o in objs if o.name.endswith("_" + args.cue_slot)]
    if not cue:
        errs.append("%s: no `%s` mesh in the build - the cue cannot be "
                    "isolated and nothing here is a pass" % (key, args.cue_slot))

    scene = bpy.context.scene
    rep["engine"] = G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = 760, 760
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
    mn, mx, pts = G.world_bounds(objs)
    radius = max(0.5, (mx - mn).length / 2.0)
    cent = Vector(((mn.x + mx.x) / 2.0, (mn.y + mx.y) / 2.0, (mn.z + mx.z) / 2.0))
    rig = F.even_lights(cent, radius, meta["aura"])
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    # TRAP 1: the frame comes off the measured bounds, never a constant.
    cam_d.ortho_scale = max(mx.x - mn.x, mx.z - mn.z) * 1.18
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam

    frames = {}
    for vname, az in VIEWS:
        F.aim_lights(rig, cent, radius, az)
        a, e = math.radians(az), math.radians(6.0)
        dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e),
                       math.sin(e))).normalized()
        cam.location = cent + dirv * (radius * 4.0 + 4.0)
        cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
        bpy.context.view_layer.update()
        fwd = (cam.matrix_world.to_3x3() @ Vector((0, 0, -1))).normalized()
        depth = [(p - cam.location).dot(fwd) for p in pts]
        cam_d.clip_start = max(0.01, min(depth) - radius * 0.5)
        cam_d.clip_end = max(depth) + radius * 2.0 + 8.0
        B = _shot(os.path.join(outdir, "%s%s_%s.png" % (key, tag, vname)))
        Xc = _shot(os.path.join(tmp, "_nocue_%s.png" % vname), hide=cue)
        frames[vname] = (B, Xc, cam.location.copy(), cam.rotation_euler.copy(),
                         cam_d.clip_start, cam_d.clip_end)

    # second build: identical verts, lap painted the slot FILL. Same camera
    # poses replayed, so nothing but the lap's colour can differ.
    _build(key, True)
    scene = bpy.context.scene
    rep["engine2"] = G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = 760, 760
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
    rig2 = F.even_lights(cent, radius, meta["aura"])
    cam_d2 = bpy.data.cameras.new("cam2")
    cam_d2.type = 'ORTHO'
    cam_d2.ortho_scale = max(mx.x - mn.x, mx.z - mn.z) * 1.18
    cam2 = bpy.data.objects.new("cam2", cam_d2)
    bpy.context.collection.objects.link(cam2)
    scene.camera = cam2

    for vname, az in VIEWS:
        B, Xc, loc, rot, cs, ce = frames[vname]
        F.aim_lights(rig2, cent, radius, az)
        cam2.location = loc
        cam2.rotation_euler = rot
        cam_d2.clip_start, cam_d2.clip_end = cs, ce
        bpy.context.view_layer.update()
        Xl = _shot(os.path.join(tmp, "_flatlap_%s.png" % vname))
        lum = _luma(B)
        cue_m = np.abs(B - Xc).max(axis=2) > EPS
        lap_m = np.abs(B - Xl).max(axis=2) > EPS
        cell = {"cue": _stats(lum, cue_m, "cue", errs, key),
                "lap": _stats(lum, lap_m, "lap", errs, key)}
        if "p50" in cell["cue"] and "p50" in cell["lap"]:
            cell["screen_margin"] = round(cell["cue"]["p50"] - cell["lap"]["p50"], 4)
            cell["screen_ratio"] = round(
                cell["cue"]["p50"] / max(1e-6, cell["lap"]["p50"]), 3)
        rep["views"][vname] = cell

    # THE ARM MUST NAME ITSELF. A sweep whose report does not carry the value
    # it was built at is a sweep you can read against the wrong arm.
    rep["thatcher_twist_env"] = os.environ.get("THATCHER_TWIST", "(unset)")
    rep["ok"] = not errs
    out = args.out or os.path.join(outdir, "_cuevalue_%s%s.json" % (key, tag))
    with open(out, "w") as fh:
        json.dump(rep, fh, indent=1)
    print("[cuevalue] wrote %s ok=%s" % (out, rep["ok"]), flush=True)


main()
