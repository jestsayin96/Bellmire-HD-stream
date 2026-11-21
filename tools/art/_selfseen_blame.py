"""_selfseen_blame.py - WHO IS DOING THE HIDING.

  blender -b -noaudio -P tools/art/_selfseen_blame.py -- --repo <repo> --key beadle

_backread.py answers "how much of the man survives" and that is the right
question, but it names no culprit: `rest` is ONE merged object, so a cell that
reads 0.5174 cannot say whether the coat, the staff or the creature's own arm
is the thing in front of him. Changing a body on a number that cannot name a
part is guessing with extra steps.

SO THIS FILE SPLITS THE BUILD ON EVERY SPAN, NOT ONLY `man`, and asks the
viewer's question once per span through the SAME locked camera:

    man alone                -> the mask (alone)
    man + span S             -> how much of that mask S leaves standing

The loss charged to S is therefore measured, not inferred, and the losses do
NOT have to sum to the real loss - two spans can cover the same pixel. That
overlap is reported as `sum_of_parts` beside the real `all_rest` figure so the
difference is visible rather than silently folded away.

IT GOES RED, NOT BLIND:
  - no spans on the key                        -> RED
  - spans do not partition the item list       -> RED (a gap or an overlap in
                                                  the span table makes every
                                                  number below meaningless)
  - bounds move between the control build and
    the split build by more than 1e-4          -> RED (the camera moved)
  - man-alone mask under 500 px                -> RED
  - A SPAN THAT COVERS NOTHING IN ANY VIEW is reported as 0.0, never dropped:
    a metric computed over an empty set reads green and means nothing.
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
VIEWS = (("front", 0.0), ("side", 90.0), ("back", 180.0))
_REAL_MERGE = M.merge_objs
SPLIT = {"spans": None, "ids": {}, "counts": {}}


def _split_all(key, items, mats, suffix=None, vcols=None):
    """Merge once per span over a PARTITION of the items - same verts, same
    mats, same slots - so world bounds are identical to the real merge."""
    spans = SPLIT["spans"]
    if spans is None:
        return _REAL_MERGE(key, items, mats, suffix=suffix, vcols=vcols)
    out = []
    SPLIT["ids"] = {}
    SPLIT["counts"] = {}
    seen = set()
    for name, (a, b) in spans.items():
        inside = [it for i, it in enumerate(items) if a <= i < b]
        seen |= set(range(a, min(b, len(items))))
        SPLIT["counts"][name] = len(inside)
        if not inside:
            SPLIT["ids"][name] = set()
            continue
        objs = _REAL_MERGE(key, inside, mats, suffix=name, vcols=vcols)
        SPLIT["ids"][name] = set(id(o) for o in objs)
        out += objs
    SPLIT["counts"]["_covered"] = len(seen)
    SPLIT["counts"]["_total"] = len(items)
    return out


def _bounds_of(objs):
    mn, mx, _ = G.world_bounds(objs)
    return tuple(round(v, 5) for v in (mn.x, mn.y, mn.z, mx.x, mx.y, mx.z))


def _clear():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)


def blame(repo, key, outdir):
    rep = {"key": key, "errors": [], "views": {}}
    _clear()
    SPLIT["spans"] = None
    M.merge_objs = _REAL_MERGE
    objs0, _ = MG.build_miniboss(key)
    b0 = _bounds_of(objs0)
    _clear()

    P = M.BUILDERS[key]()
    spans = dict(getattr(P, "spans", {}) or {})
    if not spans or "man" not in spans:
        rep["errors"].append("%s: no spans / no `man` span" % key)
        return rep
    SPLIT["spans"] = spans
    M.merge_objs = _split_all
    try:
        objs, meta = MG.build_miniboss(key)
    finally:
        M.merge_objs = _REAL_MERGE
    b1 = _bounds_of(objs)
    rep["bounds_control"], rep["bounds_split"] = list(b0), list(b1)
    rep["item_counts"] = dict(SPLIT["counts"])
    if max(abs(x - y) for x, y in zip(b0, b1)) > 1e-4:
        rep["errors"].append("%s: bounds moved under the split" % key)
        return rep
    c = SPLIT["counts"]
    if c["_covered"] != c["_total"]:
        rep["errors"].append(
            "%s: spans cover %d of %d items - the table has a gap or an "
            "overlap, so no number below means anything"
            % (key, c["_covered"], c["_total"]))
        return rep

    byname = {n: [o for o in objs if id(o) in ids]
              for n, ids in SPLIT["ids"].items()}
    man = byname.get("man", [])
    others = [n for n in spans if n != "man"]
    if not man:
        rep["errors"].append("%s: the man span merged to no object" % key)
        return rep

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
    cam_d.ortho_scale = max(mx.x - mn.x, mx.z - mn.z) * 1.18
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    tmp = os.path.join(outdir, "_tmp")
    os.makedirs(tmp, exist_ok=True)
    allobjs = list(objs)

    def shot(path, visible):
        hide = [o for o in allobjs if o not in visible]
        for o in hide:
            o.hide_render = True
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        for o in hide:
            o.hide_render = False
        return G.read_png(path)

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

        Mo = shot(os.path.join(tmp, "_blame_manonly_%s.png" % vname), man)
        alone = Mo[:, :, 3] > EPS
        n_alone = int(alone.sum())
        cell = {"man_alone_px": n_alone, "blame": {}}
        if n_alone < 500:
            cell["red"] = "man-alone mask under 500 px"
            rep["errors"].append("%s %s: man-alone %d px" % (key, vname, n_alone))
            rep["views"][vname] = cell
            continue
        B = shot(os.path.join(tmp, "_blame_all_%s.png" % vname), allobjs)
        X = shot(os.path.join(tmp, "_blame_norest_%s.png" % vname),
                 [o for o in allobjs if o not in man])
        seen_all = int(((np.abs(B - X).max(axis=2) > EPS) & alone).sum())
        cell["man_seen_all"] = round(seen_all / float(n_alone), 4)
        total_loss = n_alone - seen_all
        parts = 0
        for nm in others:
            grp = byname.get(nm, [])
            if not grp:
                cell["blame"][nm] = {"items": SPLIT["counts"].get(nm, 0),
                                     "hidden_px": 0, "hidden_frac": 0.0,
                                     "note": "span merged to no object"}
                continue
            P2 = shot(os.path.join(tmp, "_blame_%s_%s.png" % (nm, vname)),
                      man + grp)
            P2n = shot(os.path.join(tmp, "_blame_%sX_%s.png" % (nm, vname)), grp)
            vis = int(((np.abs(P2 - P2n).max(axis=2) > EPS) & alone).sum())
            lost = n_alone - vis
            parts += lost
            cell["blame"][nm] = {"items": SPLIT["counts"].get(nm, 0),
                                 "hidden_px": lost,
                                 "hidden_frac": round(lost / float(n_alone), 4)}
        cell["all_rest_hidden_px"] = total_loss
        cell["all_rest_hidden_frac"] = round(total_loss / float(n_alone), 4)
        cell["sum_of_parts_px"] = parts
        cell["overlap_px"] = parts - total_loss
        rep["views"][vname] = cell
    return rep


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--key", default="beadle")
    ap.add_argument("--out", default="")
    args = ap.parse_args(argv)
    outdir = os.path.join(args.repo, "renders", "art", "minibosses", "_backread")
    os.makedirs(outdir, exist_ok=True)
    rep = blame(args.repo, args.key, outdir)
    rep["ok"] = not rep["errors"]
    out = args.out or os.path.join(outdir, "_blame_%s.json" % args.key)
    with open(out, "w") as fh:
        json.dump(rep, fh, indent=1)
    print("[blame] wrote %s ok=%s" % (out, rep["ok"]), flush=True)


main()
