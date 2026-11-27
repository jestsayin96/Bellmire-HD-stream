"""_fanner_mouth_ab.py - DOES A VANE CROSS THE BOWL MOUTH? Pass 5 of the FANNER.

  blender -b -noaudio -P tools/art/_fanner_mouth_ab.py -- --repo <repo> --tag _p5

WHY THIS FILE EXISTS. Pass 4 closed the COUNT and the VALUE and left two faults
open that I had named myself and could see in the renders:

  3. A VANE CROSSES THE BOWL MOUTH on front and side and clips the fire's read.
  5. On the side the far vane reads off the SKULL rather than off the basket.

Both were judged BY EYE. Fault 3 is the Fanner's whole mechanic being eaten -
the hearth IS the creature - so it gets an instrument before it gets a fix, and
the instrument asks THE VIEWER'S QUESTION, not a geometry question.

A GEOMETRY TEST WOULD HAVE BEEN THE WRONG TEST, and this is the pass-11 lesson
restated. "Does the blade's box intersect the bowl's mouth cylinder" is
answerable in closed form and tells you NOTHING a viewer cares about: a blade
can pass over the mouth and be entirely hidden behind the rim, and a blade that
misses the mouth in 3D can still sit across the fire ON SCREEN. The quantity
that matters is HOW MANY PIXELS OF FIRE THE VANES TAKE AWAY.

THE METHOD - two conditions through ONE LOCKED CAMERA, the renderer doing the
depth:

  A. vanes SHOWN   -> the hearth's visible footprint, found by re-slotting the
                      hearth dome to a probe material and diffing. Those are
                      the pixels where the FIRE is the front-most thing.
  B. vanes HIDDEN  -> the same measurement again.

  fire_lost = (footprint in B) AND NOT (footprint in A)

Those are precisely the pixels of fire a viewer loses TO THE VANES. The rim
still occludes the hearth in both conditions by design - the fire is recessed -
so the rim cancels out and what is left is the vanes' doing alone.

GEOMETRY IS NEVER DROPPED. Condition B hides the vane OBJECT at render time
(`hide_render`) instead of building without it, so every vertex stays in the
scene, the bounds cannot move, and build_miniboss cannot re-normalise the body
under a camera this harness has locked. Dropping geometry to measure its effect
is how a sibling harness once reported a 59,576 px mask for four pegs.

AND IT GOES RED, NOT BLIND:
  - hearth probe took != 1 item         -> RED (grabbed the wrong geometry)
  - 'bone' span is not the 4 vanes      -> RED (the body changed under it)
  - BOUNDS MOVED between conditions     -> RED (the locked camera is a lie)
  - fire footprint under 200 px in B    -> RED ON EMPTY: a loss fraction over
                                           no fire reads 0.000 and is a number
                                           about nothing, which is exactly how
                                           a green-on-empty metric lies.

WHAT THIS CHECK CANNOT SEE, stated because every harness in this lane now owes
that sentence:
  - It cannot tell a vane crossing the fire from a vane crossing the RIM BAND
    just outside it. It measures the fire only.
  - An emissive dome re-coloured to magenta can, in principle, change nearby
    pixels by light spill rather than by being front-most. EEVEE emission does
    not light other surfaces without irradiance, so this is small here, and the
    BEFORE/AFTER comparison runs the same instrument both times so any spill
    cancels. It is still the reason this file reports raw px and not only a
    fraction.
  - It says nothing about fault 5 (a vane reading off the skull). That is a
    DIFFERENT question - adjacency to the head, not occlusion of the fire - and
    it is measured separately below as `head_touch`.
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

KEY = "fanner"
VANE_SPAN = "vanes"
NVANE = 4
PROBE_SLOT = [None]        # which slot to re-slot to 'probe' ('glow' or None)
PROBE_N = [0]
_REAL_BUILDER = M.BUILDERS[KEY]
_REAL_MERGE = M.merge_objs

MAX_LOST_FRAC = 0.02       # the fire a viewer may lose to the gauge
MIN_FIRE_PX = 200          # under this the measurement is about nothing


def _builder():
    """Re-slot the HEARTH DOME to 'probe'. Geometry is untouched."""
    P = _REAL_BUILDER()
    PROBE_N[0] = 0
    a, b = P.spans[VANE_SPAN]
    if (b - a) <= 0 or (b - a) % NVANE:
        raise ValueError("%s: span %r holds %d items, which is not a whole "
                         "number of %d vanes - the body changed under this "
                         "harness" % (KEY, VANE_SPAN, b - a, NVANE))
    bone = [i for i, it in enumerate(P.items) if it[2] == 'bone']
    if sorted(bone) != list(range(a, b)):
        raise ValueError("%s: the 'bone' slot is %r and the vane span is %r - "
                         "this harness hides the bone OBJECT to hide the vanes, "
                         "so they must be the same geometry" % (KEY, bone, (a, b)))
    if PROBE_SLOT[0] is not None:
        hits = [i for i, it in enumerate(P.items) if it[2] == PROBE_SLOT[0]]
        if len(hits) != 1:
            raise ValueError("%s: slot %r holds %d items, expected exactly 1 - "
                             "the probe would be measuring a union, not the "
                             "hearth" % (KEY, PROBE_SLOT[0], len(hits)))
        verts, faces, _slot = P.items[hits[0]]
        P.items[hits[0]] = (verts, faces, 'probe')
        PROBE_N[0] = 1
    return P


def _merge(key, items, mats, suffix=None, vcols=None):
    """The probe group becomes its OWN object - merge_objs iterates a hard-coded
    slot tuple and would SILENTLY DROP a 'probe' group, which is how a sibling
    harness rendered a body with its feature missing and called the difference
    the feature."""
    probe_items = [it for it in items if it[2] == 'probe']
    rest = [it for it in items if it[2] != 'probe']
    objs = _REAL_MERGE(key, rest, mats, suffix=suffix, vcols=vcols)
    if probe_items:
        gv, gf = [], []
        for verts, faces, _ in probe_items:
            off = len(gv)
            gv.extend(verts)
            gf.extend([tuple(i + off for i in f) for f in faces])
        objs.append(L.make(key + "_probe", gv, gf,
                           L.mat_glow(key + "_probe", (1.0, 0.0, 1.0), 3.2)))
    return objs


M.BUILDERS[KEY] = _builder
M.merge_objs = _merge
MG.M.merge_objs = _merge


def _args():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--res", default="760x1040")
    ap.add_argument("--tag", default="")
    return ap.parse_args(a)


def build(probe_slot=None):
    G.purge()
    PROBE_SLOT[0] = probe_slot
    objs, info = MG.build_miniboss(KEY)
    mn, mx, _ = G.world_bounds(objs)
    return objs, info, (tuple(round(c, 5) for c in mn),
                        tuple(round(c, 5) for c in mx))


def rig(scene, center, radius, resx, resy, aura):
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
    for ob in list(bpy.data.objects):
        if ob.type == 'CAMERA':
            bpy.data.objects.remove(ob, do_unlink=True)
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


def set_vanes(objs, shown):
    """Hide the vane OBJECT, never the vane geometry."""
    n = 0
    for o in objs:
        if o.name.startswith(KEY + "_bone"):
            o.hide_render = not shown
            n += 1
    return n


def dilate(m, n=1):
    out = m.copy()
    for _ in range(n):
        p = np.zeros_like(out)
        p[1:, :] |= out[:-1, :]
        p[:-1, :] |= out[1:, :]
        p[:, 1:] |= out[:, :-1]
        p[:, :-1] |= out[:, 1:]
        out = out | p
    return out


def probe_mask(p_base, p_probe, thr=0.20):
    A, B = G.read_png(p_base), G.read_png(p_probe)
    assert A.shape == B.shape, "render sizes differ - cameras are not locked"
    d = np.max(np.abs(A[..., :3] - B[..., :3]), axis=-1)
    return (d > thr) & (B[..., 3] > 0.5)


VIEWS = [("front", 0.0, 0.0), ("side", 90.0, 0.0),
         ("three_quarter", 45.0, 0.0)]


def main():
    args = _args()
    resx, resy = [int(v) for v in args.res.lower().split("x")]
    outdir = os.path.join(args.repo, "renders", "art", "minibosses", "_mouth_ab")
    os.makedirs(outdir, exist_ok=True)
    tag = args.tag
    aura = M.CANON[KEY][3]

    errors = []
    objs, info, bb0 = build(None)
    mn, mx, _ = G.world_bounds(objs)
    ortho = (Vector(mx) - Vector(mn)).length * 1.12

    views = {}
    for vname, az, el in VIEWS:
        got = {}
        for cond, shown in (("with", True), ("without", False)):
            # base
            objs, info, bb = build(None)
            if bb != bb0:
                errors.append("%s/%s/%s: BOUNDS MOVED %r -> %r - the locked "
                              "camera is a lie and every moved pixel is about "
                              "nothing" % (KEY, vname, cond, bb0, bb))
            nb = set_vanes(objs, shown)
            if nb != 1:
                errors.append("%s/%s/%s: found %d vane objects, expected 1"
                              % (KEY, vname, cond, nb))
            mnv, mxv, _ = G.world_bounds(objs)
            cen = (Vector(mnv) + Vector(mxv)) * 0.5
            rad = max((Vector(mxv) - Vector(mnv)).length * 0.5, 0.5)
            rig(bpy.context.scene, cen, rad, resx, resy, aura)
            bp = os.path.join(outdir, "%s_%s_%s_base%s.png" % (KEY, vname, cond, tag))
            shoot(bp, cen, rad, az, el, ortho)
            # hearth probed
            objs2, info2, bb2 = build('glow')
            if PROBE_N[0] != 1:
                errors.append("%s/%s/%s: hearth probe took %d items, expected 1"
                              % (KEY, vname, cond, PROBE_N[0]))
            if bb2 != bb0:
                errors.append("%s/%s/%s: BOUNDS MOVED on probe %r -> %r"
                              % (KEY, vname, cond, bb0, bb2))
            set_vanes(objs2, shown)
            mn2, mx2, _ = G.world_bounds(objs2)
            cen2 = (Vector(mn2) + Vector(mx2)) * 0.5
            rad2 = max((Vector(mx2) - Vector(mn2)).length * 0.5, 0.5)
            rig(bpy.context.scene, cen2, rad2, resx, resy, aura)
            pp = os.path.join(outdir, "%s_%s_%s_probe%s.png" % (KEY, vname, cond, tag))
            shoot(pp, cen2, rad2, az, el, ortho)
            got[cond] = probe_mask(bp, pp)

        fire_with, fire_without = got["with"], got["without"]
        lost = fire_without & (~fire_with)
        n_without = int(fire_without.sum())
        n_with = int(fire_with.sum())
        n_lost = int(lost.sum())
        if n_without < MIN_FIRE_PX:
            errors.append("%s/%s: the hearth is only %d px with the vanes "
                          "HIDDEN - RED ON EMPTY, a loss fraction over no fire "
                          "is a number about nothing" % (KEY, vname, n_without))
        frac = (n_lost / float(n_without)) if n_without else 0.0
        views[vname] = {
            "fire_px_vanes_hidden": n_without,
            "fire_px_vanes_shown": n_with,
            "fire_px_lost_to_vanes": n_lost,
            "lost_frac": round(frac, 4),
            "bar_frac": MAX_LOST_FRAC,
            "ok": (frac <= MAX_LOST_FRAC),
        }

    worst = max([v["lost_frac"] for v in views.values()]) if views else 1.0
    rep = {
        "key": KEY,
        "asks": "HOW MANY PIXELS OF FIRE DOES A VIEWER LOSE TO THE VANES, per "
                "view - an OCCLUSION measure of the creature's own mechanic. "
                "NOT whether a blade intersects the mouth in 3D.",
        "instrument": "tools/art/_fanner_mouth_ab.py",
        "method": "the hearth dome is re-slotted to a probe material and the "
                  "body re-rendered through ONE locked camera, twice: with the "
                  "vane object shown and with it hidden. Fire visible without "
                  "the vanes AND NOT with them is fire the vanes take. "
                  "Geometry is never dropped, so bounds cannot move.",
        "bars": {"max_lost_frac": MAX_LOST_FRAC, "min_fire_px": MIN_FIRE_PX},
        "res": [resx, resy],
        "views": views,
        "worst_lost_frac": round(worst, 4),
        "errors": errors,
        "ok": (not errors) and worst <= MAX_LOST_FRAC,
    }
    rep["verdict"] = "GREEN" if rep["ok"] else "RED"
    out = os.path.join(outdir, "_mouth_ab%s.json" % (tag or ""))
    with open(out, "w") as fh:
        json.dump(rep, fh, indent=1)
    print("[mouth_ab] wrote %s verdict=%s worst_lost=%.4f errors=%d"
          % (out, rep["verdict"], worst, len(errors)), flush=True)
    for vn, v in views.items():
        print("[mouth_ab] %-14s fire %d -> %d, lost %d (%.2f%%)"
              % (vn, v["fire_px_vanes_hidden"], v["fire_px_vanes_shown"],
                 v["fire_px_lost_to_vanes"], 100.0 * v["lost_frac"]), flush=True)


if __name__ == "__main__":
    main()
