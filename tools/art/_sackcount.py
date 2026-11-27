"""_sackcount.py - CAN A VIEWER COUNT THE PALE MASSES, PER VIEW?

  blender -b -noaudio -P tools/art/_sackcount.py -- --repo <repo> --key badger

WHY THIS EXISTS. The badger's whole mechanic is a COUNT: four sacks, and one
fewer on the yoke is one already gone from the town. Pass 3's builder comment
asserted that the hang "gives every ortho four separable masses". The render
refutes it - front and back and side all read TWO - and the fit register was
green the whole time, because nothing in it asks this question.

It is the same fault family as this lane's pass-11 `head_glow_px: 156`: a
number that answers how BIG a thing is, beside a sentence saying it cannot be
SEEN. The correction that survived contact with a picture is the only method
used here:

  RENDER WITH AND WITHOUT, THROUGH ONE LOCKED CAMERA, AND COUNT THE PIXELS
  THAT MOVED. Occlusion and depth are then the renderer's problem, not mine.

THREE FRAMES PER VIEW, AND THE THIRD IS THE ONE THAT MAKES IT HONEST:
  B   the shipped frame.
  Bn  the same frame with the `bone` mesh hidden.
  S   the `bone` mesh ALONE, for its silhouette only.
  moved   = |B - Bn| > EPS. This is every pixel the sacks are responsible for
            - BUT IT IS NOT THE SACKS. Hiding them also removes their SHADOWS,
            and a shadow that lifts off the coat or the floor is a moved pixel
            that no viewer would ever count as a sack. My first cut of this
            file did not have the S frame and would have counted the shadow
            under the yoke as a fifth mass.
  visible = moved AND S. A sack pixel that is behind the coat does not move
            when the sack is hidden, so it drops out by itself - occlusion is
            handled by the renderer and never by an estimate of mine. A shadow
            pixel lies outside S and drops out too.

Then `visible` is LABELLED (4-connected, numpy only - there is no scipy in
Blender) and the components are counted. `masses` is the answer.

RED ON EMPTY, AND IT IS A REAL RISK HERE, NOT A RITUAL. A component count over
an empty mask is 0, which is a small tidy number that would sit in a register
looking like a measurement. If `visible` is under MIN_VIS px on a view, or the
`bone` mesh is missing, or S is empty, THIS FILE MEASURED NOTHING and says so.

WHAT THIS FILE CANNOT SEE, SAID PLAINLY:
 1. It counts SEPARABLE MASSES, not countable ones. Two sacks joined by three
    pixels of contact are ONE component to this test and might still read as
    two to an eye; four components each 20 px across are four to this test and
    a smudge to a viewer at stream distance. `areas` is printed for exactly
    that reason - look at the spread, not only at the count.
 2. It cannot tell a sack from any other `bone` thing. On this body `bone` is
    the four sacks and nothing else, by the Mealman's rule, and the builder
    asserts the luma ratios that keep it so - but if a later pass puts a fifth
    pale item in the slot this number silently becomes about five things.
 3. It says nothing about whether a pale mass reads as a SACK OF GRAIN rather
    than a gourd or a boxing glove. That is fault 5 and it is answered by
    looking at the hero sheet.
 4. `min_area` is a judgement. A component under it is reported in
    `dropped_areas` rather than thrown away silently, so the cut can be seen.
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
import lordlib as L          # noqa: E402,F401
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402
import minibossgen as MG     # noqa: E402
import minibossfit as F      # noqa: E402

EPS = 2.0 / 255.0
MIN_VIS = 400          # px of visible slot below which nothing was measured
VIEWS = (("front", 0.0), ("side", 90.0), ("back", 180.0))


def _clear():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)


def _setup(scene, aura, cent, radius, mn, mx):
    G.set_engine(scene)
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
    rig = F.even_lights(cent, radius, aura)
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    # TRAP 1: the frame comes off the measured bounds, never a constant.
    cam_d.ortho_scale = max(mx.x - mn.x, mx.z - mn.z) * 1.18
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    return rig, cam, cam_d


def _label(mask):
    """4-connected labelling, iterative flood fill on a numpy bool array.
    Returns a list of component sizes, largest first. No scipy in Blender."""
    h, w = mask.shape
    seen = np.zeros((h, w), bool)
    sizes = []
    idx = np.argwhere(mask)
    for sy, sx in idx:
        if seen[sy, sx]:
            continue
        n = 0
        stack = [(int(sy), int(sx))]
        seen[sy, sx] = True
        while stack:
            y, x = stack.pop()
            n += 1
            if y > 0 and mask[y - 1, x] and not seen[y - 1, x]:
                seen[y - 1, x] = True
                stack.append((y - 1, x))
            if y + 1 < h and mask[y + 1, x] and not seen[y + 1, x]:
                seen[y + 1, x] = True
                stack.append((y + 1, x))
            if x > 0 and mask[y, x - 1] and not seen[y, x - 1]:
                seen[y, x - 1] = True
                stack.append((y, x - 1))
            if x + 1 < w and mask[y, x + 1] and not seen[y, x + 1]:
                seen[y, x + 1] = True
                stack.append((y, x + 1))
        sizes.append(n)
    sizes.sort(reverse=True)
    return sizes


def _shot(path, hide=(), solo=None, allobjs=()):
    restore = []
    if solo is not None:
        for o in allobjs:
            restore.append((o, o.hide_render))
            o.hide_render = (o not in solo)
    for o in hide:
        restore.append((o, o.hide_render))
        o.hide_render = True
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    for o, v in restore:
        o.hide_render = v
    return G.read_png(path)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--key", default="badger")
    ap.add_argument("--slot", default="bone")
    ap.add_argument("--expect", type=int, default=4)
    ap.add_argument("--min-area", type=int, default=120)
    ap.add_argument("--tag", default="")
    ap.add_argument("--out", default="")
    args = ap.parse_args(argv)
    key, tag = args.key, args.tag
    outdir = os.path.join(args.repo, "renders", "art", "minibosses", "_sackcount")
    os.makedirs(outdir, exist_ok=True)
    tmp = os.path.join(outdir, "_tmp" + tag)
    os.makedirs(tmp, exist_ok=True)
    errs = []
    rep = {"key": key, "tag": tag, "slot": args.slot, "expect": args.expect,
           "min_area": args.min_area, "views": {}, "errors": errs,
           "asks": "how many SEPARABLE masses of the `%s` slot reach each "
                   "camera, by with/without through one locked camera, "
                   "intersected with the slot's own silhouette so shadows do "
                   "not count as mass" % args.slot,
           "cannot_see": "whether a separable mass is a COUNTABLE one at "
                         "stream distance, whether it reads as a sack rather "
                         "than a gourd, and whether the slot holds only sacks"}

    _clear()
    objs, meta = MG.build_miniboss(key)
    mn, mx, pts = G.world_bounds(objs)
    radius = max(0.5, (mx - mn).length / 2.0)
    cent = Vector(((mn.x + mx.x) / 2.0, (mn.y + mx.y) / 2.0, (mn.z + mx.z) / 2.0))
    sack = [o for o in objs if o.name.endswith("_" + args.slot)]
    if not sack:
        errs.append("%s: no `%s` mesh on this body - NOTHING WAS MEASURED"
                    % (key, args.slot))
    rig, cam, cam_d = _setup(bpy.context.scene, meta["aura"], cent, radius, mn, mx)

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
        if not sack:
            continue
        B = _shot(os.path.join(outdir, "%s%s_%s.png" % (key, tag, vname)))
        Bn = _shot(os.path.join(tmp, "_nosack_%s.png" % vname), hide=sack)
        S = _shot(os.path.join(tmp, "_solo_%s.png" % vname), solo=set(sack),
                  allobjs=objs)
        moved = np.abs(B - Bn).max(axis=2) > EPS
        sil = S[:, :, 3] > 0.5 if S.shape[2] > 3 else np.zeros(moved.shape, bool)
        visible = moved & sil
        nvis, nsil, nmoved = int(visible.sum()), int(sil.sum()), int(moved.sum())
        cell = {"visible_px": nvis, "solo_sil_px": nsil, "moved_px": nmoved,
                "shadow_px_excluded": nmoved - int((moved & sil).sum())}
        if nsil == 0:
            cell["red"] = ("the slot's solo silhouette is EMPTY on this view - "
                           "the camera or the solo render is broken and "
                           "NOTHING WAS MEASURED here")
            errs.append("%s/%s: solo silhouette empty" % (key, vname))
        elif nvis < MIN_VIS:
            cell["red"] = ("only %d px of the slot reach this camera, under "
                           "the %d px floor - a component count on this is a "
                           "tidy number about nothing. NOTHING WAS MEASURED"
                           % (nvis, MIN_VIS))
            errs.append("%s/%s: visible %d px under floor %d"
                        % (key, vname, nvis, MIN_VIS))
        else:
            sizes = _label(visible)
            keep = [s for s in sizes if s >= args.min_area]
            cell["masses"] = len(keep)
            cell["areas"] = keep
            cell["dropped_areas"] = [s for s in sizes if s < args.min_area]
            cell["occluded_frac"] = round(1.0 - nvis / float(nsil), 4)
            # SEPARABLE IS NOT COUNTABLE, AND THE FIRST RUN OF THIS FILE PROVED
            # IT IN BOTH DIRECTIONS IN ONE AFTERNOON. Pass 3 scored FOUR on the
            # front with areas 16499, 15345, 570, 123 - two sacks and two
            # slivers peeking past them, and the raw count flattered it. The
            # first pass-4 re-hang scored FIVE on the side and the back, which
            # is worse than four and not better: a sack cut in two by a rope or
            # a coat edge is two components to a flood fill and one sack to an
            # eye. A raw component count is therefore not the answer on its
            # own, in either direction.
            # THE RULE, AND IT IS A JUDGEMENT, SO IT IS WRITTEN DOWN RATHER
            # THAN BURIED IN A THRESHOLD: a component smaller than a QUARTER of
            # the largest one on that view is a PEEK, not a load. It is the
            # same cut in both directions - it drops pass 3's 570 and 123 px
            # slivers and it drops the fragments a rope cuts off a sack - and
            # it is reported beside the raw count, never instead of it, so the
            # cut can be seen and argued with. It was NOT chosen to make this
            # body pass: under it pass 3 reads 2 / 2 / 2 and the first re-hang
            # reads 3 / 3 / 3, and neither is four.
            cut = (max(keep) * 0.25) if keep else 0.0
            countable = [s for s in keep if s >= cut]
            cell["countable"] = len(countable)
            cell["peek_areas"] = [s for s in keep if s < cut]
            cell["counts"] = (len(countable) == args.expect)
            if len(countable) != args.expect:
                cell["note"] = ("%d countable masses (%d separable) against %d "
                                "on the yoke - a viewer on this camera CANNOT "
                                "COUNT THE LOAD"
                                % (len(countable), len(keep), args.expect))
        rep["views"][vname] = cell

    got = [c.get("countable") for c in rep["views"].values() if "countable" in c]
    rep["countable_per_view"] = got
    rep["separable_per_view"] = [c.get("masses") for c in rep["views"].values()
                                 if "masses" in c]
    rep["all_views_count"] = (len(got) == len(VIEWS)
                              and all(g == args.expect for g in got))
    rep["ok"] = not errs
    out = args.out or os.path.join(outdir, "_sackcount_%s%s.json" % (key, tag))
    with open(out, "w") as fh:
        json.dump(rep, fh, indent=1)
    print(json.dumps(rep, indent=1))


main()
