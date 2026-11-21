"""_bandblame.py - WHERE ON THE MAN IS HE BEING HIDDEN, AND BY WHAT.

  blender -b -noaudio -P tools/art/_bandblame.py -- --repo <repo> --key fuller
                                                     [--view side] [--bands 10]

WHY THIS FILE EXISTS. `_selfseen_blame.py` answers WHO hides the man - on
fuller/side it charges trough 0.2673, cloth 0.2004, stocks 0.1630. That is the
right culprit list and it is still not the viewer's question, because a man
whose SHINS are behind a waist-high vat is a man working at a vat, and a man
whose HEAD is behind one is a fault. 0.4611 is the same number either way.

So this file keeps the same locked camera and the same moved-pixel test, and
asks it PER HEIGHT BAND over the man-alone mask's own bounding box:

    band b survival = (man pixels in b that move when the man is removed)
                      / (man-alone pixels in b)

and charges each band to the span that takes the most pixels in it, measured
the same way, never inferred from z-order or from the model.

IT GOES RED, NOT BLIND:
  - no spans / no `man` span                      -> RED
  - spans do not partition the item list          -> RED
  - bounds move between control and split > 1e-4  -> RED (camera moved)
  - man-alone mask under 500 px                   -> RED
  - A BAND WITH NO MAN PIXELS reports survival null, never 1.0: a fraction
    over an empty set reads green and means nothing. Bands are counted and
    the empty ones are named.
  - THE NOISE FLOOR IS MEASURED, NOT ASSUMED. The moved-pixel test compares
    two separate renders, so a man pixel whose colour happens to match the
    man-removed render reads as hidden with nothing in front of it. The back
    view of the fuller charges 104 px of loss to spans totalling 13 - that
    residual IS the floor. This file renders the man-alone mask TWICE and
    reports `floor_px`, the disagreement between two identical renders, so no
    band difference smaller than the floor is read as a finding.

It also writes the picture the number is standing in for: the man-alone mask
with surviving pixels GREEN and hidden pixels RED, beside the plain view, with
the band grid drawn on both.
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
AZ = {"front": 0.0, "side": 90.0, "back": 180.0}
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


def run(repo, key, view, nbands, outdir):
    rep = {"key": key, "view": view, "bands": nbands, "errors": []}
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
        rep["errors"].append("%s: spans cover %d of %d items" % (key, c["_covered"], c["_total"]))
        return rep

    byname = {n: [o for o in objs if id(o) in ids] for n, ids in SPLIT["ids"].items()}
    man = byname.get("man", [])
    if not man:
        rep["errors"].append("%s: the man span merged to no object" % key)
        return rep
    others = [n for n in spans if n != "man"]

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

    az = AZ[view]
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

    Mo = shot(os.path.join(tmp, "_bb_manonly.png"), man)
    Mo2 = shot(os.path.join(tmp, "_bb_manonly2.png"), man)
    alone = Mo[:, :, 3] > EPS
    n_alone = int(alone.sum())
    rep["man_alone_px"] = n_alone
    if n_alone < 500:
        rep["errors"].append("%s %s: man-alone %d px" % (key, view, n_alone))
        return rep
    rep["floor_px"] = int(((np.abs(Mo - Mo2).max(axis=2) > EPS) & alone).sum())

    B = shot(os.path.join(tmp, "_bb_all.png"), allobjs)
    X = shot(os.path.join(tmp, "_bb_norest.png"), [o for o in allobjs if o not in man])
    moved = (np.abs(B - X).max(axis=2) > EPS) & alone
    rep["man_seen_all"] = round(int(moved.sum()) / float(n_alone), 4)

    per_span = {}
    for nm in others:
        grp = byname.get(nm, [])
        if not grp:
            per_span[nm] = None
            continue
        P2 = shot(os.path.join(tmp, "_bb_%s.png" % nm), man + grp)
        P2n = shot(os.path.join(tmp, "_bb_%sX.png" % nm), grp)
        vis = (np.abs(P2 - P2n).max(axis=2) > EPS) & alone
        per_span[nm] = ~vis & alone          # hidden-by-nm mask

    rows = np.where(alone.any(axis=1))[0]
    r0, r1 = int(rows.min()), int(rows.max()) + 1
    rep["man_rows"] = [r0, r1]
    edges = [r0 + int(round((r1 - r0) * i / float(nbands))) for i in range(nbands + 1)]
    rep["band_edges"] = edges
    rep["rows_top_is_crown"] = True
    out_bands = []
    for i in range(nbands):
        s = slice(edges[i], edges[i + 1])
        tot = int(alone[s].sum())
        cellb = {"band": i, "rows": [edges[i], edges[i + 1]], "man_px": tot}
        if tot == 0:
            cellb["survival"] = None
            cellb["note"] = "no man pixels in this band - not scored"
            out_bands.append(cellb)
            continue
        seen = int(moved[s].sum())
        cellb["survival"] = round(seen / float(tot), 4)
        cellb["hidden_px"] = tot - seen
        blame = {}
        for nm, msk in per_span.items():
            blame[nm] = 0 if msk is None else int(msk[s].sum())
        cellb["blame_px"] = blame
        top = sorted(blame.items(), key=lambda kv: -kv[1])
        cellb["culprit"] = top[0][0] if top and top[0][1] > rep["floor_px"] else None
        out_bands.append(cellb)
    rep["band_rows"] = out_bands

    # HIDDEN BY NOTHING. `_selfseen_blame` on fuller/back charged 104 px of
    # loss to spans totalling 13 px, and the obvious reading is render noise.
    # It is not: `floor_px` above is measured from two identical renders. A man
    # pixel that no span covers and that still fails the moved test is a pixel
    # the geometry leaves in plain sight and the VALUES bury - his colour and
    # the colour behind him agree to within EPS. That is a readability fault,
    # not an occlusion one, and it is invisible to every occupancy metric in
    # this tree, so it is counted and named here.
    union = np.zeros_like(alone)
    for nm, msk in per_span.items():
        if msk is not None:
            union |= msk
    nospan = alone & ~moved & ~union
    rep["hidden_px"] = int((alone & ~moved).sum())
    rep["hidden_by_a_span_px"] = int((alone & ~moved & union).sum())
    rep["hidden_by_no_span_px"] = int(nospan.sum())
    rep["hidden_by_no_span_frac"] = round(int(nospan.sum()) / float(n_alone), 5)

    # THE PICTURE. green = the man survives here, red = he is hidden here.
    tint = B.copy()
    g = moved
    r = alone & ~moved
    tint[g] = tint[g] * 0.35 + np.array([0.20, 0.95, 0.35, 1.0]) * 0.65
    tint[r] = tint[r] * 0.25 + np.array([0.98, 0.25, 0.14, 1.0]) * 0.75
    for ed in edges:
        if 0 <= ed < tint.shape[0]:
            tint[ed, :, :3] = np.array([1.0, 1.0, 1.0]) * 0.55
            tint[ed, :, 3] = 1.0
    sheet = np.concatenate([B, tint], axis=1)
    os.makedirs(os.path.join(repo, "renders", "art", "minibosses", key), exist_ok=True)
    pathA = os.path.join(outdir, "_bandblame_%s_%s_raw.png" % (key, view))
    G.write_png(pathA, sheet)
    rep["sheet_raw"] = pathA
    return rep


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--key", default="fuller")
    ap.add_argument("--view", default="side", choices=sorted(AZ))
    ap.add_argument("--bands", type=int, default=10)
    args = ap.parse_args(argv)
    outdir = os.path.join(args.repo, "renders", "art", "minibosses", "_backread")
    os.makedirs(outdir, exist_ok=True)
    rep = run(args.repo, args.key, args.view, args.bands, outdir)
    rep["ok"] = not rep["errors"]
    out = os.path.join(outdir, "_bandblame_%s_%s.json" % (args.key, args.view))
    with open(out, "w") as fh:
        json.dump(rep, fh, indent=1)
    print("[bandblame] wrote %s ok=%s" % (out, rep["ok"]), flush=True)


main()
