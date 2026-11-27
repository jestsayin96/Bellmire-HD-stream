"""_fanner_vane_ab.py - THE VANE COUNT GAUGE THAT CAN SEE. Pass 4 of the FANNER.

  blender -b -noaudio -P tools/art/_fanner_vane_ab.py -- --repo <repo>

WHY THIS FILE EXISTS, AND IT IS THE SAME LESSON TWICE IN ONE BODY.

The Fanner's whole mechanic is a COUNT: four pale vanes on the basket rim, one
vane is one draught it can still take, "you can count them from the door". Three
passes tried to close that gauge and every one of them was judged BY EYE off a
contact sheet - "front 4, side 3", then "front 4, side 2", then "front 3,
side 4". Every one of those passes ALSO came back `ok: true`, `errors: []`,
`blank: []`, border clean. The numbers were green and the gauge was broken,
because a vane hidden behind another vane - or behind the bowl, or behind the
man's own skull - IS NOT A BLANK, NOT A CLIP AND NOT A HAIRLINE. Nothing in
minibossfit asks the viewer's question, so nothing in minibossfit could ever
have caught it.

THE INSTRUMENT, and it is the Hurdleman's pass-11 method applied to a count:
ask what the VIEWER can see, by rendering through ONE LOCKED CAMERA and letting
the renderer do the depth.

  1. EACH VANE'S PIXELS ARE FOUND BY GEOMETRY, NOT BY A TYPED BOX. One vane's
     own item is re-slotted to a probe material and the body is re-rendered
     through the SAME camera. The pixels that changed are that vane's VISIBLE
     FOOTPRINT - the pixels where that vane is the FRONT-MOST thing - not its
     size. A "render it alone" mask answers how BIG a vane is and says NOTHING
     about whether it can be seen; that is the exact error that once shipped
     `head_glow_px: 156` beside the sentence "the head now has no face at all".
  2. GEOMETRY IS NEVER DROPPED. Re-slotting leaves every vertex in place, so the
     bounds cannot move and build_miniboss cannot re-normalise the body under a
     locked camera. Dropping the topmost geometry is what made a sibling harness
     report a 59,576 px mask for four pegs - a number about nothing.
  3. A COUNT NEEDS SEPARATION, NOT JUST PRESENCE. Two vanes whose footprints
     touch read as ONE shape to a viewer however many pixels each owns, so the
     masks are dilated and tested PAIRWISE, and a fused pair counts ONCE. This
     is the fault pass 2 and pass 3 both had and neither measured.

AND IT GOES RED, NOT BLIND, ON EVERY WAY IT CAN FAIL:
  - probe took != 1 item for a vane      -> RED (grabbed the wrong geometry)
  - a vane span that is not 4 items      -> RED (the body changed under it)
  - BOUNDS MOVED between base and probe  -> RED (the locked camera is a lie and
                                            every moved pixel is about nothing)
  - base body mask under 2000 px         -> RED (the render is empty/mis-aimed)
  - ZERO vanes resolved in a view        -> RED, never green-on-empty: a metric
                                            computed over no pairs reads clean
                                            and means nothing.
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
SPAN = "vanes"
NVANE = 4
PROBE = [None]
PROBE_N = [0]
_REAL_BUILDER = M.BUILDERS[KEY]
_REAL_MERGE = M.merge_objs

MIN_PX = 60               # absolute floor: under this it is a speck
MIN_FRAC = 0.22           # and at least this share of the median vane
SEP_DILATE = 2            # px: footprints this close read as one shape


def _builder():
    """Re-slot ONE VANE - every item that vane is built from - to 'probe'.
    Geometry is untouched.

    PASS 5 MADE A VANE MORE THAN ONE ITEM. It is a narrow STEM plus a broad
    BLADE now, so the span holds NVANE * k items and probing a single item
    would have measured a vane's TOP HALF and called it the vane. The count is
    derived from the span and asserted to divide exactly, so a body that grows
    a third piece per vane goes RED here instead of quietly reporting a
    fraction of each footprint.
    """
    P = _REAL_BUILDER()
    which = PROBE[0]
    PROBE_N[0] = 0
    a, b = P.spans[SPAN]
    n = b - a
    if n <= 0 or n % NVANE:
        raise ValueError("%s: span %r holds %d items, which is not a whole "
                         "number of %d vanes - the body changed under this "
                         "harness" % (KEY, SPAN, n, NVANE))
    per = n // NVANE
    if which is not None:
        for j in range(per):
            i = a + which * per + j
            verts, faces, _slot = P.items[i]
            P.items[i] = (verts, faces, 'probe')
            PROBE_N[0] += 1
    return P


ITEMS_PER_VANE = [1]


def _merge(key, items, mats, suffix=None, vcols=None):
    """The probe group becomes its OWN object, because minibosses.merge_objs
    iterates a HARD-CODED slot tuple ('body','dark','bone','glow') and a
    'probe' group handed to it is SILENTLY DROPPED - no object, nothing
    raised. That silent drop is how a sibling harness rendered the body with
    its feature MISSING and measured the difference as the feature."""
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


def build(probe=None):
    G.purge()
    PROBE[0] = probe
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
    """The pixels where THIS vane is the front-most thing."""
    A, B = G.read_png(p_base), G.read_png(p_probe)
    assert A.shape == B.shape, "render sizes differ - cameras are not locked"
    d = np.max(np.abs(A[..., :3] - B[..., :3]), axis=-1)
    return (d > thr) & (B[..., 3] > 0.5)


VIEWS = [("front", 0.0, 0.0), ("side", 90.0, 0.0),
         ("three_quarter", 45.0, 0.0), ("back", 180.0, 0.0)]


def main():
    args = _args()
    resx, resy = [int(v) for v in args.res.lower().split("x")]
    outdir = os.path.join(args.repo, "renders", "art", "minibosses", "_vane_ab")
    os.makedirs(outdir, exist_ok=True)
    tag = args.tag
    # `aura` is the RIM LIGHT COLOUR, an rgb triple off CANON - NOT a scalar.
    # Passing 0.0 raised inside lordgen.add_lights and Blender still exited 0,
    # so the RC of a crashed render is worth nothing: this harness is trusted
    # only when its json exists.
    aura = M.CANON[KEY][3]

    errors = []
    objs, info, base_bounds = build(None)
    mn, mx, _ = G.world_bounds(objs)
    ortho = (Vector(mx) - Vector(mn)).length * 1.12

    views = {}
    for vname, az, el in VIEWS:
        base_p = os.path.join(outdir, "%s_base_%s%s.png" % (KEY, vname, tag))
        objs, info, bb = build(None)
        mnv, mxv, _ = G.world_bounds(objs)
        cen = (Vector(mnv) + Vector(mxv)) * 0.5
        rad = max((Vector(mxv) - Vector(mnv)).length * 0.5, 0.5)
        rig(bpy.context.scene, cen, rad, resx, resy, aura)
        shoot(base_p, cen, rad, az, el, ortho)
        A = G.read_png(base_p)
        body_px = int((A[..., 3] > 0.5).sum())
        if body_px < 2000:
            errors.append("%s/%s: base body only %d opaque px - the render is "
                          "empty or mis-aimed, so nothing below is evidence"
                          % (KEY, vname, body_px))

        masks, raw = {}, {}
        for i in range(NVANE):
            objs2, info2, pb = build(i)
            if PROBE_N[0] < 1:
                errors.append("%s/%s vane %d: probe took %d items, expected at "
                              "least 1 - the vane was never re-slotted and the "
                              "diff below is about nothing"
                              % (KEY, vname, i, PROBE_N[0]))
            elif ITEMS_PER_VANE[0] in (1, PROBE_N[0]):
                ITEMS_PER_VANE[0] = PROBE_N[0]
            else:
                errors.append("%s/%s vane %d: probe took %d items but a "
                              "previous vane took %d - the vanes are not built "
                              "alike and their footprints are not comparable"
                              % (KEY, vname, i, PROBE_N[0], ITEMS_PER_VANE[0]))
            if pb != bb:
                errors.append("%s/%s vane %d: BOUNDS MOVED %r -> %r - the "
                              "locked camera is a lie and every moved pixel "
                              "is about nothing" % (KEY, vname, i, bb, pb))
            mn2, mx2, _ = G.world_bounds(objs2)
            cen2 = (Vector(mn2) + Vector(mx2)) * 0.5
            rad2 = max((Vector(mx2) - Vector(mn2)).length * 0.5, 0.5)
            rig(bpy.context.scene, cen2, rad2, resx, resy, aura)
            pp = os.path.join(outdir, "%s_v%d_%s%s.png" % (KEY, i, vname, tag))
            shoot(pp, cen2, rad2, az, el, ortho)
            m = probe_mask(base_p, pp)
            masks[i] = m
            raw[i] = int(m.sum())

        fused = []
        for i in range(NVANE):
            for j in range(i + 1, NVANE):
                if raw[i] <= 0 or raw[j] <= 0:
                    continue
                if (dilate(masks[i], SEP_DILATE) & dilate(masks[j], SEP_DILATE)).any():
                    fused.append([i, j])

        present = [i for i in range(NVANE) if raw[i] > 0]
        med = float(np.median([raw[i] for i in present])) if present else 0.0
        bar = max(MIN_PX, MIN_FRAC * med)
        big = [i for i in present if raw[i] >= bar]
        groups = []
        for i in big:
            hit = None
            for g in groups:
                if any([min(i, k), max(i, k)] in fused for k in g):
                    hit = g
                    break
            if hit is None:
                groups.append([i])
            else:
                hit.append(i)
        count = len(groups)
        if count == 0:
            errors.append("%s/%s: ZERO vanes resolved - RED ON EMPTY, not a "
                          "pass" % (KEY, vname))
        views[vname] = {
            "body_px": body_px,
            "vane_px": raw,
            "median_px": round(med, 1),
            "bar_px": round(bar, 1),
            "countable": big,
            "too_small": [i for i in present if raw[i] < bar],
            "invisible": [i for i in range(NVANE) if raw[i] <= 0],
            "fused_pairs": fused,
            "count_read": count,
            "ok": (count == NVANE and not fused),
        }

    worst = min([v["count_read"] for v in views.values()]) if views else 0
    rep = {
        "key": KEY,
        "asks": "HOW MANY VANES CAN A VIEWER COUNT, per view - a VISIBLE-"
                "FOOTPRINT measure through one locked camera, with fused "
                "footprints collapsed. NOT how big a vane is.",
        "instrument": "tools/art/_fanner_vane_ab.py",
        "method": "re-slot ONE vane to a probe material, re-render through the "
                  "SAME camera, changed pixels = that vane's front-most "
                  "footprint. Geometry never dropped, so bounds cannot move.",
        "bars": {"min_px": MIN_PX, "min_frac_of_median": MIN_FRAC,
                 "sep_dilate_px": SEP_DILATE},
        "res": [resx, resy],
        "views": views,
        "count_min": worst,
        "errors": errors,
        "ok": (not errors) and worst == NVANE,
    }
    rep["verdict"] = "GREEN" if rep["ok"] else "RED"
    out = os.path.join(outdir, "_vane_ab%s.json" % (tag or ""))
    with open(out, "w") as fh:
        json.dump(rep, fh, indent=1)
    print("[vane_ab] wrote %s verdict=%s count_min=%d errors=%d"
          % (out, rep["verdict"], worst, len(errors)), flush=True)
    for vn, v in views.items():
        print("[vane_ab] %-14s count=%d px=%s fused=%s"
              % (vn, v["count_read"], v["vane_px"], v["fused_pairs"]), flush=True)


# Guarded so the SEARCH can import this file as a library and re-use the probe
# rather than keeping a second copy of it. Blender's -P runs this as __main__.
if __name__ == "__main__":
    main()
