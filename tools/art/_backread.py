"""_backread.py - THE INSTRUMENT FOR THE 21 NOV 01:34 ART ROW: "A VIEW WITH NO
READABLE CREATURE IN IT IS WORSE THAN A FLAT ONE."

  blender -b -noaudio -P tools/art/_backread.py -- --repo <repo> --keys dyer,greener

WHY THE REGISTER COULD NOT SEE EITHER FAULT, MEASURED NOT REMEMBERED. The
register's occlusion cell asks "how much of THE CREATURE survives the hero",
and the creature is the man AND his apparatus. On the dyer's back view that
cell reads `seen: 1.0` on all three views - and it is not lying: every pixel of
the set piece is visible. The thing hidden is the MAN, and he is hidden BY HIS
OWN PROPS, which the cell counts as creature. A number that treats the thing
doing the hiding and the thing being hidden as one subject can never go red on
this fault. That is trap 5 in a new coat.

SO THIS FILE ASKS THE VIEWER'S TWO QUESTIONS, PER VIEW:

  1. CAN YOU SEE THE CREATURE AT ALL? The figure - the `man` span, or the
     spans the builder names in its own `man_parts` - is merged into its own
     objects - SAME VERTS, SAME SLOTS, SAME MATERIALS, so the bounds and
     therefore the camera cannot move - and three frames go through ONE locked
     camera: everything (B), the man hidden (X), the man alone (Mo). A man
     pixel counts as SEEN where the man's own alpha is set AND B differs from
     X, i.e. where the man is the front-most thing. That is the with/without
     delta test through one camera, which is the only version of this question
     that has ever survived contact with a picture.

  2. IS WHAT YOU SEE ONE FLAT MASS? Luma over the pixels that are actually
     visible, in the sRGB the viewer gets, reported as p5/p50/p95, the near-
     black fraction, and how many eighths of the range hold at least 5% of the
     pixels. One flat mass scores 1 band; a body that reads scores three or
     more.

*** THE THIRD STATE, ADDED 26 Nov 2026 18:4x CT - AND IT CLOSES A RED OF MY
*** OWN THAT STOOD FOR TWO DAYS. `panner` has read
*** `panner: the man span merged to no object` in `_selfseen_all.json` since
*** 24 Nov 11:3x, holding that whole file at `ok: false`, and the body is
*** CORRECT: panner pass 4 removed its operator deliberately after an A/B it
*** documents in full, and left `P.spans["man"] = (len(P.items), len(P.items))`
*** - an EMPTY span - as the marker. `minibosses.man_ranges` honours that and
*** so does the register's census (`no_man`, GREEN, see
*** docs/art/SELFSEEN_AUDIT_24NOV.md section 6, where the same unearned red
*** was caught one level up). THIS FILE never got the matching branch, so the
*** instrument kept reporting a fault in a body the house had already ruled
*** right. An instrument that cannot report an unearned PASS can still report
*** an unearned FAIL, and they are the same fault.
***
*** WHAT NO_MAN CLAIMS: NOTHING. It is not a pass. No view is rendered, no
*** cell is written, nothing goes in `views`, and the register goes on
*** counting panner in `no_man` and not in `measured_bodies`. It is the
*** honest absence, stated out loud, in place of a wrong red.
***
*** AND WHAT THIS BRANCH CANNOT SEE, SAID PLAINLY: an empty span is a
*** DECLARATION, and this file cannot read a builder's mind. A body that
*** meant to split a figure and wrapped zero items would also declare an
*** empty span. The one discriminator available is WHERE the empty span
*** sits: the marker is written as the last statement of the builder, so
*** `a == b == len(P.items)`, while an `_open()/_close("man")` pair that
*** wrapped nothing leaves `a == b < len(P.items)` with items authored after
*** it. The mid-build form is therefore RED, and only the end-of-build form
*** is NO_MAN. That is a real discriminator and it is not mind-reading, but
*** it does NOT catch a builder whose accidental empty `_close("man")` is its
*** final statement. Both branches were fired and watched before shipping -
*** see `--prove-empty-mid`.

IT GOES RED, NOT BLIND, ON EVERY WAY IT CAN FAIL:
  - no `man` span and no `man_parts`          -> RED (nothing to measure)
  - an EMPTY `man` span NOT at the end of the
    builder's items                           -> RED (a `_close("man")` that
                                                 wrapped zero items; the
                                                 deliberate no-operator marker
                                                 is the end-of-build form and
                                                 reads NO_MAN, not red)
  - a `man_parts` naming a span the builder
    does not declare                          -> RED (a declaration that misses
                                                 is a lie, not an absence)
  - man-alone mask under 500 px               -> RED (the split grabbed nothing)
  - creature alpha under 2000 px              -> RED (blank or mis-aimed render)
  - item count not conserved across the split -> RED (geometry lost in the merge,
                                                 which is the exact bug the
                                                 Beadle probe hit at pass 13)
  - bounds differ between the split build and
    the unsplit build by more than 1e-4       -> RED (the camera moved, so every
                                                 pixel moved and no count means
                                                 anything)
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
_REAL_MERGE = M.merge_objs
SPLIT = {"span": None, "ids": set(), "counts": {}}
PROVE_EMPTY_MID = ""


def _split_merge(key, items, mats, suffix=None, vcols=None):
    """Merge twice over a PARTITION of the items - once for the span, once for
    everything else - with the same mats and the same verts. Nothing is dropped
    and nothing is moved, so world bounds are identical to the real merge."""
    span = SPLIT["span"]
    if span is None:
        return _REAL_MERGE(key, items, mats, suffix=suffix, vcols=vcols)
    # RANGES, not one range, from 24 Nov 2026 16:5x CT. Three of the six bodies
    # this closed author their arms AFTER the apparatus the arms must reach, so
    # the figure is two ranges, not one. The partition is still a partition -
    # the conservation assertion below counts it - and nothing moves.
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


def _luma(a):
    return 0.2126 * a[:, :, 0] + 0.7152 * a[:, :, 1] + 0.0722 * a[:, :, 2]


def _value_stats(lum, mask):
    n = int(mask.sum())
    if n < 2000:
        return dict(px=n, red="mask under 2000 px - blank or mis-aimed")
    v = lum[mask]
    hist, _ = np.histogram(v, bins=8, range=(0.0, 1.0))
    frac = hist / float(n)
    return dict(px=n,
                p5=round(float(np.percentile(v, 5)), 4),
                p50=round(float(np.percentile(v, 50)), 4),
                p95=round(float(np.percentile(v, 95)), 4),
                spread=round(float(np.percentile(v, 95) - np.percentile(v, 5)), 4),
                dark_frac=round(float((v < 0.20).mean()), 4),
                bands=[round(float(f), 4) for f in frac],
                bands_5pct=int((frac >= 0.05).sum()))


def measure(repo, key, outdir, tag=""):
    rep = {"key": key, "errors": [], "views": {}}
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
        # A DECLARATION THAT MISSES IS A LIE, NOT AN ABSENCE. A `man_parts`
        # naming a span the builder does not declare goes RED here; it must
        # never read as "nothing to measure", which is the quiet outcome.
        rep["errors"].append("%s: %s" % (key, e))
    if rerrs:
        return rep
    if not source:
        rep["errors"].append("%s: no `man` span and no `man_parts` - nothing "
                             "to measure" % key)
        return rep
    # *** DECLARED-AND-EMPTY IS NOT BROKEN, AND IT IS NOT A PASS EITHER. ***
    # See the third-state block at the top of this file. The marker is the
    # LAST statement of the builder, so it sits at the end of the item list;
    # an empty span with items authored after it is a `_close("man")` that
    # wrapped nothing, and that is RED.
    n_items = len(P.items)
    empty = [r for r in ranges if r[1] <= r[0]]
    if len(empty) == len(ranges):
        at_end = all(r[0] >= n_items for r in ranges)
        if PROVE_EMPTY_MID == key:
            at_end = False
            rep["prove_empty_mid"] = True
        rep["items"] = n_items
        rep["empty_ranges"] = ranges
        if not at_end:
            # SAY WHAT THE NUMBER IS. The first cut of this message printed
            # `n_items` under the label "items authored after it", which is
            # the total, not the tail - a number that means something other
            # than its label, which is the fault class this lane keeps
            # catching. The tail is what makes the span mid-build, so the
            # tail is what gets printed.
            after = n_items - max(r[0] for r in ranges)
            rep["items_after_span"] = after
            rep["verdict"] = "RED"
            rep["errors"].append(
                "%s: an EMPTY `man` span at %s in a builder of %d items, with "
                "%d authored after it - a `_close(\"man\")` that wrapped zero "
                "items, not the end-of-build no-operator marker"
                % (key, ranges, n_items, after))
            return rep
        rep["no_man"] = True
        rep["verdict"] = "NO_MAN"
        rep["no_man_reason"] = (
            "the builder declares an EMPTY `man` span as its last statement - "
            "a deliberate marker that this body has no operator at all. A "
            "machine with no man cannot fail a can-you-see-the-man test. "
            "NOTHING IS CLAIMED: no view is rendered and no cell is written, "
            "so this row is an honest absence and NOT a pass. Matches "
            "`minibosses.man_ranges` and the register census's `no_man` "
            "state (docs/art/SELFSEEN_AUDIT_24NOV.md section 6).")
        return rep
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
        return rep
    c = SPLIT["counts"]
    if c.get("inside", 0) + c.get("outside", 0) != c.get("total", -1):
        rep["errors"].append("%s: item count not conserved by the split" % key)
        return rep
    man = [o for o in objs if id(o) in SPLIT["ids"]]
    rest = [o for o in objs if id(o) not in SPLIT["ids"]]
    if not man:
        rep["errors"].append("%s: the man span merged to no object" % key)
        return rep
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
    tmp = os.path.join(outdir, "_tmp")
    os.makedirs(tmp, exist_ok=True)

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
        X = _shot(os.path.join(tmp, "_nomam_%s.png" % vname), hide=man)
        Mo = _shot(os.path.join(tmp, "_manonly_%s.png" % vname), hide=rest)
        alone = Mo[:, :, 3] > EPS
        n_alone = int(alone.sum())
        changed = np.abs(B - X).max(axis=2) > EPS
        seen_px = int((changed & alone).sum())
        cell = dict(man_alone_px=n_alone, man_seen_px=seen_px,
                    man_seen=round(seen_px / float(n_alone), 4) if n_alone else 0.0)
        if n_alone < 500:
            cell["red"] = "man-alone mask under 500 px - the split grabbed nothing"
            rep["errors"].append("%s %s: man-alone mask %d px" % (key, vname, n_alone))
        lum = _luma(B)
        cell["value_creature"] = _value_stats(lum, B[:, :, 3] > EPS)
        cell["value_man_visible"] = _value_stats(lum, changed & alone)
        rep["views"][vname] = cell
    return rep


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--keys", default="dyer,greener")
    ap.add_argument("--tag", default="")
    ap.add_argument("--out", default="")
    # An assertion nobody has seen fire is not an assertion. This moves the
    # declared-empty `man` marker from the END of the item list into the
    # MIDDLE, in memory only, so the mid-build RED can be WATCHED to fire on
    # the very body the NO_MAN branch exists for.
    ap.add_argument("--prove-empty-mid", default="")
    args = ap.parse_args(argv)
    global PROVE_EMPTY_MID
    PROVE_EMPTY_MID = args.prove_empty_mid
    outdir = os.path.join(args.repo, "renders", "art", "minibosses", "_backread")
    os.makedirs(outdir, exist_ok=True)
    rows = {}
    for key in [k for k in args.keys.split(",") if k]:
        rows[key] = measure(args.repo, key, outdir, tag=args.tag)
        print("[backread] %s done" % key, flush=True)
    out = args.out or os.path.join(outdir, "_backread%s.json" % (args.tag or ""))
    rep = {"rows": rows,
           "errors": sum([r.get("errors", []) for r in rows.values()], [])}
    rep["ok"] = not rep["errors"]
    with open(out, "w") as fh:
        json.dump(rep, fh, indent=1)
    print("[backread] wrote %s ok=%s" % (out, rep["ok"]), flush=True)


main()
