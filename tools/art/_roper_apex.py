"""_roper_apex.py - DOES THE APEX READ AS AN OBJECT, HEAD-ON, AT HERO SCALE.

  blender -b -noaudio -P tools/art/_roper_apex.py -- --repo <repo> [--key roper]
                                                     [--tag _p7] [--out <json>]

WHY THIS FILE EXISTS, AND WHY IT IS NOT `mask_of`. The team lead opened
hero_front.png and would not tick "the tripod is gone", and the lane's own
fault (1) says why: head-on the top "reads as a pale BOWL, not as a grooved
former". The temptation is to answer that by rendering the top ALONE and
printing how many pixels it covers. That number is trap 5 in this lane's
header wearing a new coat - it says how BIG a thing is and NOTHING about
whether a viewer can see it, because the strands, the arms and the hands all
cross it in projection.

SO EVERY NUMBER HERE IS A WITH/WITHOUT THROUGH ONE LOCKED CAMERA. The build is
split on its own span table into real merged objects, the full build is
rendered once, and then one span at a time is taken OUT and the pixels that
MOVED are counted. A pixel that moves when the top is removed is a pixel the
top actually owns on screen. The renderer does the depth; no arithmetic of
mine decides what is in front of what, which is the mistake that has now cost
this body three passes (the laid rope across the face, the sag proved in the
axis the front camera throws away, and pass 1's top over the head).

AT HERO SCALE, NOT AT SHOWCASE SCALE. The ortho frame is minibossfit's own
FRAME_W over its own 760 px cell, so one pixel here is one pixel there and
`apex_px` is literally what a viewer gets beside a hero.

THE TRIPOD IN ONE NUMBER: `apex_share` = apex_px / (apex_px + strand_px). A
surveyor's tripod is three legs and a negligible head; an object carried by a
man is the other way round. The grooves get their own number - `apex_dark_px`,
the dark pixels inside the apex's own owned region - because a blank pale disc
and a grooved former cover the SAME pixels and only one of them reads.

IT GOES RED, NOT BLIND:
  - no span table, or a table that does not partition the items  -> RED
  - bounds move between control build and split build            -> RED
  - ANY span owning ZERO pixels in a view is reported as 0 and
    flagged, never dropped: a metric over an empty set reads
    green and means nothing.
  - a view whose full-build mask touches the frame border        -> RED
    (a clipped subject is not a blank one - the ladder's lesson)
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
CELL_X, CELL_Y = 760, 520
FRAME_W = F.FRAME_W                      # the hero-scale frame, not a new one
PX_PER_M = CELL_X / float(FRAME_W)
_REAL_MERGE = M.merge_objs
SPLIT = {"spans": None, "ids": {}, "counts": {}}


def _split_all(key, items, mats, suffix=None, vcols=None):
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


def probe(repo, key, outdir):
    rep = {"key": key, "errors": [], "empty_spans": [], "views": {},
           "px_per_m": round(PX_PER_M, 3), "frame_w": FRAME_W}
    _clear()
    SPLIT["spans"] = None
    M.merge_objs = _REAL_MERGE
    objs0, _ = MG.build_miniboss(key)
    b0 = _bounds_of(objs0)
    _clear()

    P = M.BUILDERS[key]()
    spans = dict(getattr(P, "spans", {}) or {})
    if not spans:
        rep["errors"].append("%s: no span table" % key)
        return rep
    SPLIT["spans"] = spans
    M.merge_objs = _split_all
    try:
        objs, meta = MG.build_miniboss(key)
    finally:
        M.merge_objs = _REAL_MERGE
    b1 = _bounds_of(objs)
    rep["bounds"] = list(b1)
    rep["height_m"] = round(b1[5] - b1[2], 4)
    if max(abs(x - y) for x, y in zip(b0, b1)) > 1e-4:
        rep["errors"].append("%s: bounds moved under the split" % key)
        return rep
    c = SPLIT["counts"]
    if c["_covered"] != c["_total"]:
        rep["errors"].append("%s: spans cover %d of %d items" %
                             (key, c["_covered"], c["_total"]))
        return rep
    byname = {n: [o for o in objs if id(o) in ids]
              for n, ids in SPLIT["ids"].items()}

    scene = bpy.context.scene
    rep["engine"] = G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = CELL_X, CELL_Y
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    mn, mx, pts = G.world_bounds(objs)
    radius = max(0.5, (mx - mn).length / 2.0)
    cent = Vector(((mn.x + mx.x) / 2.0, (mn.y + mx.y) / 2.0,
                   (mn.z + mx.z) / 2.0))
    rig = F.even_lights(cent, radius, meta["aura"])
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam_d.ortho_scale = FRAME_W            # HERO SCALE. not fitted to the body
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

        FULL = shot(os.path.join(tmp, "_apex_full_%s.png" % vname), allobjs)
        alpha = FULL[:, :, 3] > EPS
        cell = {"subject_px": int(alpha.sum()), "owned": {}}
        if cell["subject_px"] < 500:
            rep["errors"].append("%s %s: subject under 500 px" % (key, vname))
            rep["views"][vname] = cell
            continue
        # THE BORDER. A clipped subject is not a blank one.
        edge = int(alpha[0, :].sum() + alpha[-1, :].sum() +
                   alpha[:, 0].sum() + alpha[:, -1].sum())
        cell["border_px"] = edge
        if edge:
            rep["errors"].append("%s %s: %d px on the frame border"
                                 % (key, vname, edge))
        lum = (0.2126 * FULL[:, :, 0] + 0.7152 * FULL[:, :, 1] +
               0.0722 * FULL[:, :, 2])
        for nm in spans:
            grp = byname.get(nm, [])
            if not grp:
                cell["owned"][nm] = {"px": 0, "note": "span merged to nothing"}
                rep["empty_spans"].append("%s/%s" % (vname, nm))
                continue
            WO = shot(os.path.join(tmp, "_apex_wo_%s_%s.png" % (nm, vname)),
                      [o for o in allobjs if o not in grp])
            AL = shot(os.path.join(tmp, "_apex_al_%s_%s.png" % (nm, vname)),
                      grp)
            # *** THE INSTRUMENT CORRECTION, AND I FOUND IT IN MY OWN FIRST
            # *** RUN. `moved` alone reported the top's bbox as 0.79 x 1.00 m
            # when the top is a 0.43 m object: removing a span also removes
            # the SHADOW it casts on the man, and those pixels move too. A
            # number that counts a thing's shadow as the thing would have let
            # a small apex pass for a big one. So the owned set is now
            # intersected with the span's OWN silhouette - a pixel is owned
            # only if the span is there AND taking it away changes what you
            # see. Shadow loss is still real and is reported separately.
            moved = (np.abs(FULL - WO).max(axis=2) > EPS)
            own = AL[:, :, 3] > EPS
            shadow = int((moved & ~own).sum())
            moved = moved & own
            n = int(moved.sum())
            ent = {"px": n, "frac": round(n / float(cell["subject_px"]), 4),
                   "alone_px": int(own.sum()), "shadow_px": shadow}
            if n == 0:
                ent["note"] = "owns no pixel in this view"
                rep["empty_spans"].append("%s/%s" % (vname, nm))
            else:
                ys, xs = np.nonzero(moved)
                w, h = int(xs.max() - xs.min() + 1), int(ys.max() - ys.min() + 1)
                ent["bbox_px"] = [w, h]
                ent["bbox_m"] = [round(w / PX_PER_M, 3), round(h / PX_PER_M, 3)]
                v = lum[moved]
                ent["dark_px"] = int((v < 0.26).sum())
                ent["pale_px"] = int((v > 0.55).sum())
                ent["dark_frac"] = round(ent["dark_px"] / float(n), 4)
            cell["owned"][nm] = ent
        ap = cell["owned"].get("top", {}).get("px", 0)
        st = cell["owned"].get("strands", {}).get("px", 0)
        if ap + st == 0:
            cell["apex_share"] = None
            rep["errors"].append("%s %s: apex and strands both own zero px - "
                                 "the share is computed over nothing" %
                                 (key, vname))
        else:
            cell["apex_share"] = round(ap / float(ap + st), 4)
        rep["views"][vname] = cell
    return rep


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--key", default="roper")
    ap.add_argument("--tag", default="")
    ap.add_argument("--out", default="")
    args = ap.parse_args(argv)
    outdir = os.path.join(args.repo, "renders", "art", "minibosses", "_apex")
    os.makedirs(outdir, exist_ok=True)
    rep = probe(args.repo, args.key, outdir)
    rep["tag"] = args.tag
    rep["ok"] = not rep["errors"]
    out = args.out or os.path.join(outdir, "_apex_%s%s.json" % (args.key, args.tag))
    with open(out, "w") as fh:
        json.dump(rep, fh, indent=1)
    print("APEX_REPORT " + json.dumps(rep), flush=True)
    print("[apex] wrote %s ok=%s" % (out, rep["ok"]), flush=True)


main()
