"""_opshot.py - THE BLENDER HALF OF THE 25 NOV 13:34 CT ART ROW: "THE OPERATOR,
BROWN-ON-BROWN WITH HIS CLAMP."

  blender -b -noaudio -P tools/art/_opshot.py -- --repo <W5> --key collier --tag _opCtl

WHAT THE SHIPPED HARNESSES CANNOT SEE, AND WHY THIS FILE EXISTS. The collier's
pass-14/15/16 fault list carries the same line three times: "the operator is
brown-on-brown with the clamp he stands on. From the side he separates from the
mound only by silhouette against the background." Pass 15 said in its own words
why no number in this lane reports it: every arm renders against the SAME DARK
BACKGROUND and measures the CUE, not the man. `_streamscale` counts marks an
A/B moved. `_nubread` counts silhouette px added outside a control outline.
`_backread` is the closest - it already asks the viewer's question through one
locked camera - but its value cell measures the man's OWN luma spread and never
once compares him to WHAT IS BEHIND HIM.

THE MEASUREMENT THIS FILE SETS UP, AND IT IS BACKGROUND-INDEPENDENT BY
CONSTRUCTION. Three frames per view through ONE locked camera, exactly
_backread's split (same verts, same slots, same materials, so the bounds and
therefore the camera cannot move):

    B  = everything            X  = the man hidden            Mo = the man alone

A man pixel is SEEN where Mo's alpha is set AND B differs from X - the man is
the front-most thing there. Then, and this is the whole point, every seen pixel
is PARTITIONED BY WHAT IS BEHIND IT, read off X at that same pixel:

    ON-MOUND  X has alpha -> the man is standing in front of his own apparatus,
              and the viewer must tell him from it BY COLOUR AND VALUE ALONE.
    ON-AIR    X has no alpha -> the man's edge is against the background, where
              the silhouette does the work for free. This is the kindness the
              pane gives him and a lit floor takes away.

`_brownread.py` does the arithmetic on the PNGs this file writes, at
`_streamscale`'s own rungs (760 -> 160 BOX for 360p), because the rung and the
filter have to match the numbers pass 16 shipped or they are not comparable.

IT GOES RED, NOT BLIND. Every guard _backread earned is kept, because they were
all paid for by a real bug:
  - no `man` span and no `man_parts`        -> RED (nothing to measure)
  - `man_parts` naming an undeclared span   -> RED (a declaration that misses is
                                               a lie, not an absence)
  - man-alone mask under 500 px             -> RED (the split grabbed nothing)
  - item count not conserved by the split   -> RED (geometry lost in the merge)
  - bounds moved by more than 1e-4          -> RED (the camera moved, so every
                                               pixel moved and nothing counts)
AND ONE OF ITS OWN, WHICH IS THE TRAP-4 ARM: a view whose ON-MOUND partition is
under 300 px is RED and NOT 'separated'. A contrast computed over no overlap
reads perfect and means nothing - that is the metric-over-zero-pairs fault in
its exact shape, and on this body it is not hypothetical: the man sits ON the
crown, so a camera that catches no overlap is a camera that answers nothing.
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
import lordlib as L          # noqa: E402  (imported for parity with _backread)
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402
import minibossgen as MG     # noqa: E402
import minibossfit as F      # noqa: E402

EPS = 2.0 / 255.0
VIEWS = (("front", 0.0), ("side", 90.0), ("back", 180.0))
_REAL_MERGE = M.merge_objs
SPLIT = {"span": None, "ids": set(), "counts": {}}


def _split_merge(key, items, mats, suffix=None, vcols=None):
    """_backread's partition merge, unchanged: once for the man's ranges, once
    for everything else, same mats and same verts, so world bounds are
    identical to the real merge and the camera cannot move."""
    span = SPLIT["span"]
    if span is None:
        return _REAL_MERGE(key, items, mats, suffix=suffix, vcols=vcols)
    inside = [it for i, it in enumerate(items) if M.in_ranges(i, span)]
    outside = [it for i, it in enumerate(items) if not M.in_ranges(i, span)]
    SPLIT["counts"] = dict(inside=len(inside), outside=len(outside),
                           total=len(items))
    out = []
    if outside:
        out += _REAL_MERGE(key, outside, mats, suffix="rest", vcols=vcols)
    man = _REAL_MERGE(key, inside, mats, suffix="man", vcols=vcols) if inside else []
    SPLIT["ids"] = set(id(o) for o in man)
    return out + man


def _bounds_of(objs):
    mn, mx, _ = G.world_bounds(objs)
    return (round(mn.x, 5), round(mn.y, 5), round(mn.z, 5),
            round(mx.x, 5), round(mx.y, 5), round(mx.z, 5))


def _clear():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)


def _shot(path, hide=()):
    for o in hide:
        o.hide_render = True
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    for o in hide:
        o.hide_render = False
    return G.read_png(path)


def shoot(repo, key, tag):
    rep = {"key": key, "tag": tag, "errors": [], "views": {},
           "env": {k: v for k, v in sorted(os.environ.items())
                   if k.startswith("COLLIER_") or k.startswith("MB_")
                   or k.startswith("OP_")}}
    outdir = os.path.join(repo, "renders", "art", "minibosses", "_brown", key + tag)
    os.makedirs(outdir, exist_ok=True)
    rep["outdir"] = outdir

    # --- control build: the real merge, for the bounds assertion -------------
    _clear()
    SPLIT["span"] = None
    M.merge_objs = _REAL_MERGE
    objs0, _ = MG.build_miniboss(key)
    b0 = _bounds_of(objs0)
    n0 = len(objs0)
    _clear()

    # --- split build ---------------------------------------------------------
    P = M.BUILDERS[key]()
    ranges, source, rerrs = M.man_ranges(P)
    rep["man_from"] = source
    rep["man_ranges"] = ranges
    for e in rerrs:
        rep["errors"].append("%s: %s" % (key, e))
    if rerrs:
        return rep, None
    if not source:
        rep["errors"].append("%s: no `man` span and no `man_parts` - nothing "
                             "to measure" % key)
        return rep, None
    SPLIT["span"] = ranges
    M.merge_objs = _split_merge
    try:
        objs, meta = MG.build_miniboss(key)
    finally:
        M.merge_objs = _REAL_MERGE
    b1 = _bounds_of(objs)
    rep["bounds_control"], rep["bounds_split"] = b0, b1
    rep["objs_control"], rep["objs_split"] = n0, len(objs)
    rep["item_counts"] = dict(SPLIT["counts"])
    if max(abs(x - y) for x, y in zip(b0, b1)) > 1e-4:
        rep["errors"].append("%s: bounds moved under the split - every pixel "
                             "moved, no count below means anything" % key)
        return rep, None
    c = SPLIT["counts"]
    if c.get("inside", 0) + c.get("outside", 0) != c.get("total", -1):
        rep["errors"].append("%s: item count not conserved by the split" % key)
        return rep, None
    man = [o for o in objs if id(o) in SPLIT["ids"]]
    rest = [o for o in objs if id(o) not in SPLIT["ids"]]
    if not man:
        rep["errors"].append("%s: the man span merged to no object" % key)
        return rep, None
    rep["man_objs"] = [o.name for o in man]

    # --- one camera per view, even light carried round with it ---------------
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
    # TRAP 1: the frame is derived from the measured bounds, never a constant.
    cam_d.ortho_scale = max(mx.x - mn.x, mx.z - mn.z) * 1.18
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam

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
        B = _shot(os.path.join(outdir, "B_%s.png" % vname))
        X = _shot(os.path.join(outdir, "X_%s.png" % vname), hide=man)
        Mo = _shot(os.path.join(outdir, "Mo_%s.png" % vname), hide=rest)
        alone = Mo[:, :, 3] > EPS
        n_alone = int(alone.sum())
        changed = np.abs(B - X).max(axis=2) > EPS
        seen = changed & alone
        on_mound = seen & (X[:, :, 3] > EPS)
        cell = dict(man_alone_px=n_alone,
                    man_seen_px=int(seen.sum()),
                    on_mound_px=int(on_mound.sum()),
                    on_air_px=int((seen & ~(X[:, :, 3] > EPS)).sum()))
        cell["man_seen"] = (round(cell["man_seen_px"] / float(n_alone), 4)
                            if n_alone else 0.0)
        if n_alone < 500:
            cell["red"] = "man-alone mask under 500 px - the split grabbed nothing"
            rep["errors"].append("%s %s: man-alone mask %d px" % (key, vname, n_alone))
        rep["views"][vname] = cell
    return rep, outdir


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--key", default="collier")
    ap.add_argument("--tag", default="_opCtl")
    args = ap.parse_args(argv)
    rep, outdir = shoot(args.repo, args.key, args.tag)
    rep["ok"] = not rep["errors"]
    base = os.path.join(args.repo, "renders", "art", "minibosses", "_brown")
    os.makedirs(base, exist_ok=True)
    out = os.path.join(base, "_opshot%s.json" % args.tag)
    with open(out, "w") as fh:
        json.dump(rep, fh, indent=1)
    print("[opshot] wrote %s ok=%s" % (out, rep["ok"]), flush=True)
    for e in rep["errors"]:
        print("[opshot] RED %s" % e, flush=True)


main()
