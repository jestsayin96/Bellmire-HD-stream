"""_s118_sheet.py - LOOK AT THE SPLIT, DO NOT ONLY SCORE IT.

S118 declared `man_parts` in seventeen builders that had never named a figure.
`_backread.py` scores that declaration per view; THIS file is the picture the
score is checked against, which is the standing rule on this lane: when a
number and a picture disagree, the picture is the evidence.

Per body, one row of three tiles through ONE camera, same frame:
  B   everything
  X   the figure hidden      - what is left is the gear alone
  Mo  the figure alone       - what the declaration actually grabbed

If Mo shows gear, the declaration is too wide. If X still shows a figure, it
is too narrow. Both faults are invisible in `man_seen`, which only ever
compares the two masks the declaration itself produced.

  blender -b -noaudio -P tools/art/_s118_sheet.py -- --repo <R> --keys a,b [--view front]
"""
import os
import sys
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

TILE = 300
VIEW_AZ = {"front": 0.0, "side": 90.0, "back": 180.0}
_REAL_MERGE = M.merge_objs
SPLIT = {"span": None, "ids": set()}


def _split_merge(key, items, mats, suffix=None, vcols=None):
    span = SPLIT["span"]
    if span is None:
        return _REAL_MERGE(key, items, mats, suffix=suffix, vcols=vcols)
    inside = [it for i, it in enumerate(items) if M.in_ranges(i, span)]
    outside = [it for i, it in enumerate(items) if not M.in_ranges(i, span)]
    out = []
    if outside:
        out += _REAL_MERGE(key, outside, mats, suffix="rest", vcols=vcols)
    man = _REAL_MERGE(key, inside, mats, suffix="man", vcols=vcols) if inside else []
    SPLIT["ids"] = set(id(o) for o in man)
    return out + man


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


def _box(a, n):
    """Area-average down to n x n. No PIL on this machine, so numpy does it."""
    h, w = a.shape[0], a.shape[1]
    k = max(1, h // n)
    a = a[:k * n, :k * n]
    return a.reshape(n, k, n, k, a.shape[2]).mean(axis=(1, 3))


def row(repo, key, tmp, az):
    _clear()
    P = M.BUILDERS[key]()
    ranges, source, errs = M.man_ranges(P)
    if errs or not source:
        return None, "%s: no usable figure (%s)" % (key, errs or "undeclared")
    SPLIT["span"] = ranges
    M.merge_objs = _split_merge
    try:
        objs, meta = MG.build_miniboss(key)
    finally:
        M.merge_objs = _REAL_MERGE
    man = [o for o in objs if id(o) in SPLIT["ids"]]
    rest = [o for o in objs if id(o) not in SPLIT["ids"]]
    scene = bpy.context.scene
    G.set_engine(scene)
    scene.render.resolution_x = scene.render.resolution_y = 600
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
    import math
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
    B = _shot(os.path.join(tmp, "b.png"))
    X = _shot(os.path.join(tmp, "x.png"), hide=man)
    Mo = _shot(os.path.join(tmp, "m.png"), hide=rest)
    tiles = [_box(t, TILE) for t in (B, X, Mo)]
    strip = np.concatenate(tiles, axis=1)
    return strip, None


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--keys", required=True)
    ap.add_argument("--view", default="front")
    ap.add_argument("--out", default="")
    args = ap.parse_args(argv)
    outdir = os.path.join(args.repo, "renders", "art", "minibosses", "_backread")
    tmp = os.path.join(outdir, "_tmp_s118")
    os.makedirs(tmp, exist_ok=True)
    rows, bad = [], []
    for key in [k for k in args.keys.split(",") if k]:
        strip, err = row(args.repo, key, tmp, VIEW_AZ[args.view])
        if err:
            bad.append(err)
            print("[sheet] %s" % err, flush=True)
            continue
        rows.append(strip)
        print("[sheet] %s ok" % key, flush=True)
    if not rows:
        raise SystemExit("no rows: %s" % bad)
    sheet = np.concatenate(rows, axis=0)
    # BLANK AND BORDER, the standing two checks. A tile of pure background is
    # a failed render that scores nothing, and a figure touching the frame is
    # clipped - which a blank check cannot see.
    opaque = (sheet[:, :, 3] > 2.0 / 255.0)
    per_row = [int(opaque[i * TILE:(i + 1) * TILE].sum()) for i in range(len(rows))]
    border = int(opaque[:, :2].sum() + opaque[:, -2:].sum()
                 + opaque[:2, :].sum() + opaque[-2:, :].sum())
    path = args.out or os.path.join(outdir, "_s118_sheet_%s.png" % args.view)
    G.write_png(path, sheet)
    print("[sheet] wrote %s rows=%d min_row_px=%d border_px=%d bad=%s"
          % (path, len(rows), min(per_row), border, bad), flush=True)


main()
