"""_beadle_value_ab.py - PASS 13 A/B for THE BEADLE, measuring the TWO VALUE
FAULTS I wrote up at 16:34 and deliberately left unfixed under the one-change-
at-a-time rule. The team lead's 17:58 row took them, in order.

  blender -b -noaudio -P tools/art/_beadle_value_ab.py -- --repo <repo>

THE FAULTS, BOTH IN MY OWN SHIPPED WORK AND BOTH THE SAME FAMILY:
  (a) the four brass pegs (luma 172) on the limewashed oak board (luma 167).
      FIVE luma out of 255. The gauge a viewer must count from the door is
      carried by HUE alone.
  (b) the amber staff knob (luma 172) projected onto the pale skull (luma 162)
      in the side view. TEN luma. It reads as a smudge on the cheek.

WHAT THIS HARNESS DOES THAT `_beadle_ab.py` COULD NOT. That one asked "did any
pixel move?" and then tried to say something about CONTRAST with a luminance
histogram over a 16,000 px window around a knob of a few hundred - and said so
itself, in its own report, as TOO COARSE TO BE EVIDENCE. The number that
answers a value fault is the gap ACROSS THE FEATURE'S OWN BOUNDARY, so:

  1. THE FEATURE'S PIXELS ARE FOUND BY GEOMETRY, NOT BY A TYPED BOX. The
     feature's items are re-slotted to a probe material and the body is
     re-rendered through the SAME camera; the pixels that change by a lot ARE
     the feature. A typed window is what went blind at pass 12.
  2. THE RING IS DERIVED FROM THE MASK. Dilate the feature by 3 px, subtract
     the feature: that is the ground the feature is read against.
  3. THE GAP IS MEASURED IN LUMA ON THE DESATURATED IMAGE, because the fault is
     that chroma carries it and chroma is the first thing a stream throws away.

AND IT GOES RED, NOT BLIND, ON ALL FOUR WAYS IT CAN FAIL:
  - feature mask under 40 px            -> RED (the probe found nothing)
  - ring under 40 px                    -> RED (nothing to read it against)
  - item count not the expected 4 and 2 -> RED (the probe grabbed the wrong
                                          geometry, which is the fault class
                                          that nearly cost me the Hooper)
  - BOUNDS MOVED between base and variant -> RED, because the whole method
    rests on one locked camera, and if the body re-normalised under it then
    every pixel moved and the moved-pixel counts are about nothing.
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

KEY = "beadle"
ZSPLIT = 1.90          # author-space z between the staff knob and the board
PROBE = [None]         # "pegs" | "knob" | None
_REAL_BUILDER = M.BUILDERS[KEY]
_REAL_MERGE = M.merge_objs
PROBE_N = [0]


def _centroid_z(verts):
    return sum(v[2] for v in verts) / max(1, len(verts))


def _builder():
    """Re-slot the feature's own items to 'probe'. GEOMETRY IS UNTOUCHED, so
    the bounds, the scaling and therefore the camera are identical - which is
    the thing that makes the moved pixels mean the feature and not the body."""
    P = _REAL_BUILDER()
    which = PROBE[0]
    PROBE_N[0] = 0
    if which:
        a, b = P.spans["pegs"] if which == "pegs" else (0, len(P.items))
        rng = range(a, b) if which == "pegs" else range(len(P.items))
        for i in rng:
            verts, faces, slot = P.items[i]
            if slot != 'glow':
                continue
            z = _centroid_z(verts)
            take = (z > ZSPLIT) if which == "pegs" else (z <= ZSPLIT)
            if take:
                P.items[i] = (verts, faces, 'probe')
                PROBE_N[0] += 1
    return P


def _merge(key, items, mats, suffix=None, vcols=None):
    """*** THE FIRST VERSION OF THIS WRAPPER WAS WRONG AND MY OWN BOUNDS GUARD
    *** CAUGHT IT, WHICH IS THE ONLY REASON A FICTION IS NOT IN THIS REPORT. ***
    It just added mats['probe'] and handed the items to the real merge. But
    `minibosses.merge_objs` iterates a HARD-CODED slot tuple - ('body', 'dark',
    'bone', 'glow') - so a 'probe' group is silently DROPPED: no object, no
    geometry, nothing raised. The probe render was therefore the body with the
    PEGS MISSING, and because the pegs are the topmost thing on this body,
    build_miniboss re-normalised the whole creature to 2.95 under the locked
    camera. Every pixel moved. The run came back with a peg gap of 0.065 and
    a feature mask of 59,576 px - 22% of the body - for four pegs, and both
    numbers were about nothing.

    The knob probe did NOT trip the guard, because the knob is interior
    geometry and dropping it moves no bound - so that half of the run looked
    perfectly healthy while resting on the same bug. A guard that fires on one
    arm and not the other is exactly why the assert is per-variant.

    This version merges the non-probe items through the REAL merge, untouched,
    and makes the probe geometry into its own object. The verts are identical
    and in place, so the bounds cannot move, and a probe pixel is a pixel where
    the feature is the FRONT-MOST thing - the feature's VISIBLE footprint, not
    its size. That distinction is the Hurdleman's pass-11 lesson."""
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
    ap.add_argument("--res", default="700x980")
    return ap.parse_args(a)


def build(rail, plate, probe=None):
    G.purge()
    M._BEADLE_RAIL = bool(rail)
    M._BEADLE_PLATE = bool(plate)
    PROBE[0] = probe
    objs, info = MG.build_miniboss(KEY)
    mn, mx, _ = G.world_bounds(objs)
    return objs, info, (tuple(round(c, 6) for c in mn),
                        tuple(round(c, 6) for c in mx))


def rig(scene, center, radius, aura, resx, resy):
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


def lum(a):
    """sRGB-byte luma, the space the fault was measured in: read_png is
    Non-Color so these round-trip as the bytes on disk, and a gap of 0.0196
    here is the five-luma-out-of-255 I wrote up."""
    return 0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]


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


def feature_mask(p_base, p_probe, thr=0.20):
    A, B = G.read_png(p_base), G.read_png(p_probe)
    assert A.shape == B.shape
    d = np.max(np.abs(A[..., :3] - B[..., :3]), axis=-1)
    return (d > thr) & (A[..., 3] > 0.5)


def value_gap(path, mask, ringpx=3):
    """THE VIEWER'S QUESTION, IN LUMA ONLY: how far is this feature from the
    thing it sits on, with the colour thrown away?"""
    a = G.read_png(path)
    li = lum(a)
    op = a[..., 3] > 0.5
    ring = (dilate(mask, ringpx) & ~dilate(mask, 0)) & op
    nf, nr = int(mask.sum()), int(ring.sum())
    if nf < 40 or nr < 40:
        return {"RED": "empty", "feature_px": nf, "ring_px": nr}
    f = li[mask]
    r = li[ring]
    # *** AND A RING MEAN CANNOT SEE A DIRECTIONAL FAULT, WHICH IS EXACTLY THE
    # *** SHAPE OF FAULT (b). *** Pass 12 put a dark ferrule UNDER the knob and
    # a dark cap OVER it, so the ring above and below was already dark and the
    # mean came out healthy - while the fault, in writing, was that the ball is
    # pale against pale TO ITS SIDES, where the skull is. A single mean over
    # the whole ring averages the fixed half with the broken half and reports
    # a pass. So the ring is SPLIT by where each pixel lies relative to the
    # feature's own centroid, and the number that decides is the WORST side.
    ys, xs = np.nonzero(mask)
    cy, cx = float(ys.mean()), float(xs.mean())
    ry, rx = np.nonzero(ring)
    dy, dx = ry - cy, rx - cx
    vert = np.abs(dy) >= np.abs(dx)
    sides = {"above": vert & (dy < 0), "below": vert & (dy > 0),
             "left": (~vert) & (dx < 0), "right": (~vert) & (dx > 0)}
    fm = float(f.mean())
    per = {}
    for nm, sel in sides.items():
        n = int(sel.sum())
        per[nm] = {"px": n,
                   "gap": round(fm - float(li[ring][sel].mean()), 4) if n >= 20
                   else None}
    live = [v["gap"] for v in per.values() if v["gap"] is not None]
    return {"feature_px": nf, "ring_px": nr,
            "feature_lum_mean": round(fm, 4),
            "ring_lum_mean": round(float(r.mean()), 4),
            "gap": round(fm - float(r.mean()), 4),
            "gap_bytes_255": round(float((fm - float(r.mean())) * 255.0), 1),
            "per_side_gap": per,
            "worst_side_gap": round(min(live), 4) if live else None,
            "worst_side_bytes_255": round(min(live) * 255.0, 1) if live else None,
            "feature_lum_p50": round(float(np.percentile(f, 50)), 4),
            "ring_lum_p50": round(float(np.percentile(r, 50)), 4)}


def opaque_and_border(path):
    a = G.read_png(path)
    al = a[..., 3]
    return (int((al > 0.5).sum()),
            max(float(al[0, :].max()), float(al[-1, :].max()),
                float(al[:, 0].max()), float(al[:, -1].max())))


def main():
    ns = _args()
    resx, resy = (int(v) for v in ns.res.lower().split("x"))
    out = os.path.join(ns.repo, "renders", "art", "minibosses", "_ab_beadle_value")
    os.makedirs(out, exist_ok=True)
    rep = {"res": [resx, resy], "errors": [], "checks": {}, "probe_items": {}}
    scene = bpy.context.scene
    MG.G.set_engine(scene)

    # ---- the camera is measured ONCE off the PASS-12 body and locked ----
    objs, info, bounds0 = build(0, 0)
    mn, mx, _ = G.world_bounds(objs)
    center = (mn + mx) / 2.0
    radius = max(0.35, (mx - mn).length / 2.0)
    ORTHO = max((mx - mn).x, (mx - mn).y, (mx - mn).z) * 1.18
    rep["camera"] = {"center": [round(c, 4) for c in center],
                     "ortho": round(ORTHO, 4), "locked": True}
    rep["bounds_base"] = bounds0
    VIEWS = {"front": (0.0, 12.0), "side": (90.0, 11.0)}

    def render_set(tag, rail, plate, probe=None, views=("front", "side")):
        _, inf, bnd = build(rail, plate, probe)
        if bnd != bounds0:
            rep["errors"].append(
                "BOUNDS MOVED on %s: %s vs base %s - the locked camera is "
                "invalid and every moved pixel below is meaningless"
                % (tag, bnd, bounds0))
        if probe:
            rep["probe_items"][tag] = PROBE_N[0]
        rig(scene, center, radius, inf["aura"], resx, resy)
        got = {}
        for v in views:
            az, el = VIEWS[v]
            got[v] = shoot(os.path.join(out, "%s_%s.png" % (tag, v)),
                           center, radius, az, el, ORTHO)
        return got

    base = render_set("base", 0, 0)
    base_pp = render_set("base_probepegs", 0, 0, "pegs", ("front",))
    base_pk = render_set("base_probeknob", 0, 0, "knob", ("side",))
    fixed = render_set("fixed", 1, 1)
    fix_pp = render_set("fixed_probepegs", 1, 1, "pegs", ("front",))
    fix_pk = render_set("fixed_probeknob", 1, 1, "knob", ("side",))
    # each fix ALONE, so neither can be credited with the other's effect
    rail_only = render_set("railonly", 1, 0, None, ("front",))
    plate_only = render_set("plateonly", 0, 1, None, ("side",))

    # the probe must have grabbed FOUR pegs and TWO knob pieces, or it is
    # measuring something else and the whole report is void.
    want = {"base_probepegs": 4, "fixed_probepegs": 4,
            "base_probeknob": 2, "fixed_probeknob": 2}
    for k, n in want.items():
        got = rep["probe_items"].get(k)
        if got != n:
            rep["errors"].append("probe %s grabbed %s items, expected %s" % (k, got, n))

    mb = feature_mask(base["front"], base_pp["front"])
    mf = feature_mask(fixed["front"], fix_pp["front"])
    kb = feature_mask(base["side"], base_pk["side"])
    kf = feature_mask(fixed["side"], fix_pk["side"])
    rep["checks"]["a_pegs_on_board"] = {
        "pass12_shipped": value_gap(base["front"], mb),
        "pass13_dark_rail": value_gap(fixed["front"], mf),
        "rail_alone": value_gap(rail_only["front"], mf),
    }
    rep["checks"]["b_knob_on_skull"] = {
        "pass12_shipped": value_gap(base["side"], kb),
        "pass13_dark_plate": value_gap(fixed["side"], kf),
        "plate_alone": value_gap(plate_only["side"], kf),
    }

    # ---- WHAT FIX (b) COSTS THE FRONT VIEW. The plate is flattened in x so
    # the front and back cameras see it edge-on, but "thin" is a claim and a
    # claim needs a number: railonly and fixed differ by the plate ALONE in
    # the front view, so the moved pixels there ARE the plate's front-view
    # footprint, as a fraction of the body.
    a_r = G.read_png(rail_only["front"])
    a_f = G.read_png(fixed["front"])
    dd = np.max(np.abs(a_r[..., :3] - a_f[..., :3]), axis=-1)
    dda = np.abs(a_r[..., 3] - a_f[..., 3])
    plate_front = int((np.maximum(dd, dda) > 0.02).sum())
    body_front = int((a_f[..., 3] > 0.5).sum())
    rep["checks"]["b_plate_cost_in_front_view"] = {
        "plate_front_px": plate_front, "body_front_px": body_front,
        "frac_of_body": round(plate_front / max(1, body_front), 5)}

    # ---- a picture of the thing, and a DESATURATED one beside it ----
    cells = [("a  pegs  BEFORE", base["front"]), ("a  pegs  AFTER", fixed["front"]),
             ("b  knob  BEFORE", base["side"]), ("b  knob  AFTER", fixed["side"])]
    ims = [G.read_png(p) for _, p in cells]
    h, w = ims[0].shape[0], ims[0].shape[1]
    sheet = np.zeros((h * 2, w * len(ims), 4), dtype=np.float32)
    for i, a in enumerate(ims):
        sheet[0:h, i * w:(i + 1) * w] = a
        g = lum(a)
        gray = np.stack([g, g, g, a[..., 3]], axis=-1)
        sheet[h:h * 2, i * w:(i + 1) * w] = gray
    bgc = np.array([0.045, 0.05, 0.065, 1.0], dtype=np.float32)
    al = sheet[..., 3:4]
    sheet = sheet * al + bgc * (1.0 - al)
    sheet[..., 3] = 1.0
    sheet_p = os.path.join(out, "_value_sheet.png")
    G.write_png(sheet_p, sheet)
    rep["sheet"] = sheet_p
    rep["sheet_note"] = ("top row COLOUR, bottom row the same four frames with "
                         "CHROMA THROWN AWAY. cells left to right: " +
                         ", ".join(c[0] for c in cells))

    blanks, clips = [], []
    allp = {}
    for d in (base, base_pp, base_pk, fixed, fix_pp, fix_pk, rail_only, plate_only):
        allp.update({p: p for p in d.values()})
    for p in sorted(allp):
        op, edge = opaque_and_border(p)
        rep["checks"].setdefault("renders", {})[os.path.basename(p)] = \
            {"opaque": op, "border_alpha": round(edge, 4)}
        if op < 500:
            blanks.append(os.path.basename(p))
        if edge > 0.02:
            clips.append(os.path.basename(p))
    rep["blanks"], rep["frame_clips"] = blanks, clips

    def _g(d):
        return d.get("gap") if isinstance(d, dict) and "gap" in d else None
    ga_b = _g(rep["checks"]["a_pegs_on_board"]["pass12_shipped"])
    ga_f = _g(rep["checks"]["a_pegs_on_board"]["pass13_dark_rail"])
    gb_b = _g(rep["checks"]["b_knob_on_skull"]["pass12_shipped"])
    gb_f = _g(rep["checks"]["b_knob_on_skull"]["pass13_dark_plate"])
    def _w(d):
        return d.get("worst_side_gap") if isinstance(d, dict) else None
    wa_b = _w(rep["checks"]["a_pegs_on_board"]["pass12_shipped"])
    wa_f = _w(rep["checks"]["a_pegs_on_board"]["pass13_dark_rail"])
    wb_b = _w(rep["checks"]["b_knob_on_skull"]["pass12_shipped"])
    wb_f = _w(rep["checks"]["b_knob_on_skull"]["pass13_dark_plate"])
    rep["worst_side"] = {"a_before": wa_b, "a_after": wa_f,
                         "b_before": wb_b, "b_after": wb_f}
    # THE VERDICT RIDES THE WORST SIDE, not the ring mean. A fix that improves
    # the average while leaving one side of the feature pale-on-pale has not
    # fixed a legibility fault, it has moved it.
    ok = (None not in (ga_b, ga_f, gb_b, gb_f, wa_b, wa_f, wb_b, wb_f)
          and ga_f > ga_b and gb_f > gb_b and wa_f > wa_b and wb_f > wb_b
          and not blanks and not clips and not rep["errors"])
    rep["verdict"] = "GREEN" if ok else "RED"
    with open(os.path.join(out, "_value_ab.json"), "w") as fh:
        json.dump(rep, fh, indent=1)
    print("VAB_JSON_BEGIN")
    print(json.dumps(rep))
    print("VAB_JSON_END")


main()
