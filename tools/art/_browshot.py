"""_browshot.py - THE BLENDER HALF OF THE 25 NOV 13:58 CT ART ROW: "THE 360p
BROW, WHICH IS THE ONE THING STILL UNRESOLVED ON THE COLLIER."

  blender -b -noaudio -P tools/art/_browshot.py -- --repo <W5>

THE QUESTION, AND WHY PASS 16's ANSWER CANNOT BE TRUSTED NOW. Pass 16 shipped
COLLIER_FACE_SKIN=0.6 with the sentence "the brow is still one solid bar at
360p", and the team lead said plainly in that tick that the sheet DOES NOT
RESOLVE IT AT THAT SCALE - the half was this lane's measurement, not his.

*** AND THEN PASS 17 MOVED THE GROUND UNDER IT, WHICH IS THE REAL FINDING. ***
Pass 17 (mine, 13:56 CT) added `_collier_soot`: the man's `body` geometry is
painted 0.55x the clamp's earth so he separates from the mound he stands on.
THE POT HEAD IS `body`. THE BROW IS `dark`. So the brow is a dark bar lying on
a head that pass 17 pulled DOWN toward the brow's own colour, and the authored
luma says what that costs:

    head `body`   (0.165,0.132,0.104) -> luma 0.1370
    sooted head   x0.55               -> luma 0.0753
    brow `dark`   (0.042,0.046,0.054) -> luma 0.0457

    brow-vs-head contrast BEFORE soot: 0.0913 = 23.3/255
    brow-vs-head contrast AFTER  soot: 0.0296 =  7.5/255   <- UNDER the 8/255
                                                              house threshold

Pass 17's own source carries the warning in its own comment - "a man taken far
enough down stops reading as a man and becomes one black lump with the cues
inside him gone" - and then nobody re-asked the brow. Authored luma is not
rendered luma (view transform and lighting both move dark values), so the
number above is a PREDICTION and this file exists to settle it on pixels.

HOW IT ASKS, AND IT IS THE TRAP-5 TEST AND NOT `mask_of`. Rendering the brow
alone answers how BIG it is and says nothing about whether it can be SEEN - the
exact fault this lane shipped at pass 11 (`head_glow_px: 156` beside "the head
now has no face at all", honest answer ZERO). So: the brow is split into its
own object by its own declared `face_brow` span, and rendered WITH and WITHOUT
through ONE camera that was locked before either frame, letting the renderer do
the depth. What moved is what the viewer gains from having a brow at all.

ONE CAMERA FOR EVERY ARM, NOT ONE PER ARM. The sweep changes geometry, so a
camera derived per arm would differ by a hair in `ortho_scale` and every pixel
would land somewhere else - which is precisely what is being judged at a rung
where the whole head is about twenty pixels. The camera is derived ONCE from
the shipped build and reused verbatim; it is recorded in the report so it can
be checked.

IT GOES RED, NOT BLIND. Kept from `_opshot`/`_backread`, each paid for by a
real bug, plus two of this file's own:
  - no `face_brow` span                     -> RED (nothing to split)
  - span merged to no object, or no verts   -> RED
  - item count not conserved by the split   -> RED (geometry lost)
  - bounds moved between split and control   -> RED (the camera moved)
  - any frame blank, or alpha on the border  -> RED (trap 2, both halves: a
                                                clipped icon is not a blank one)
  - ZERO pixels moved by the ablation at FULL res -> RED, never 'fine'. A brow
    that changes nothing at 760 px is a brow that is not being rendered, and a
    metric computed over no moved pixels reads perfect and means nothing
    (trap 4, the metric-over-zero-pairs fault in its exact shape).
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
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402
import minibossgen as MG     # noqa: E402
import minibossfit as F      # noqa: E402

EPS = 2.0 / 255.0
KEY = "collier"
SPAN = "face_brow"
VIEWS = (("front", 0.0), ("side", 90.0))
_REAL_MERGE = M.merge_objs
SPLIT = {"span": None, "ids": set(), "counts": {}}

# THE SWEEP. SKIN is the lever pass 16 chose 0.6 on; `soot100` is the pass-16
# HEAD VALUE carried forward at the shipped skin, so the sheet shows what the
# soot itself cost the brow with nothing else moved. Keep the shipped arm in
# the set - a sweep without its own control is an opinion.
SETS = {
    # THE SKIN LADDER - the lever pass 16 swept and chose 0.6 on.
    "skin": [
        ("_bs00",    {"COLLIER_FACE_SKIN": "0.0"}),
        ("_bs20",    {"COLLIER_FACE_SKIN": "0.2"}),
        ("_bs40",    {"COLLIER_FACE_SKIN": "0.4"}),
        ("_bs60",    {}),                               # SHIPPED: skin 0.6
        ("_bs80",    {"COLLIER_FACE_SKIN": "0.8"}),
        ("_bsoot100", {"COLLIER_SOOT": "1.0"}),         # pass-16 head, shipped skin
    ],
    # *** THE SOOT LADDER, AND IT IS THE ONE THAT MATTERS. *** The skin ladder
    # moved the brow's rung contrast only 17.8 -> 14.6/255 across its WHOLE
    # range while soot alone moved it 15.0 -> 30.5, so the lever pass 16 swept
    # is not the lever that is holding the brow down. Swept here against the
    # SHIPPED value so the cost side (the operator/clamp separation pass 17
    # bought with this same number) can be read off `_opshot`/`_brownread` at
    # the same rung.
    "soot": [
        ("_bk055", {}),                                 # SHIPPED: soot 0.55
        ("_bk065", {"COLLIER_SOOT": "0.65"}),
        ("_bk075", {"COLLIER_SOOT": "0.75"}),
        ("_bk085", {"COLLIER_SOOT": "0.85"}),
        ("_bk100", {"COLLIER_SOOT": "1.0"}),            # no soot: pass-16 head
    ],
    # THE HEAD LADDER - trunk soot stays at the SHIPPED 0.55 on every arm, so
    # the only thing moving is the pot head the face lies on. `_bh055` IS pass
    # 17 byte for byte and is the control: if the operator/clamp numbers move
    # between it and the others, the head is NOT separable from the mound and
    # the exemption does not ship.
    "head": [
        ("_bh055", {"COLLIER_SOOT_HEAD": "0.55"}),      # = pass 17 exactly
        ("_bh075", {"COLLIER_SOOT_HEAD": "0.75"}),
        ("_bh085", {"COLLIER_SOOT_HEAD": "0.85"}),
        ("_bh100", {"COLLIER_SOOT_HEAD": "1.0"}),       # head clean of soot
    ],
}
ARMS = SETS[os.environ.get("BROW_SET", "skin")]


def _split_merge(key, items, mats, suffix=None, vcols=None):
    """`_opshot`'s partition merge, unchanged in shape: once for the brow's
    range, once for everything else, SAME mats and SAME verts, so world bounds
    are identical to the real merge and the camera cannot move."""
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
    brow = _REAL_MERGE(key, inside, mats, suffix="brow", vcols=vcols) if inside else []
    SPLIT["ids"] = set(id(o) for o in brow)
    return out + brow


def _bounds_of(objs):
    mn, mx, _ = G.world_bounds(objs)
    return (round(mn.x, 5), round(mn.y, 5), round(mn.z, 5),
            round(mx.x, 5), round(mx.y, 5), round(mx.z, 5))


def _clear():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)


def _apply(env):
    """Set this arm's env and return the previous values so it can be undone.
    A sweep that leaks one arm's env into the next measures neither."""
    prev = {}
    for k, v in env.items():
        prev[k] = os.environ.get(k)
        os.environ[k] = v
    return prev


def _restore(prev):
    for k, v in prev.items():
        if v is None:
            os.environ.pop(k, None)
        else:
            os.environ[k] = v


def _shot(path, hide=()):
    for o in hide:
        o.hide_render = True
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    for o in hide:
        o.hide_render = False
    return G.read_png(path)


def _frame_guard(a, name, errs):
    """TRAP 2, BOTH HALVES. Opaque pixels must exist (not blank) AND the border
    must be empty (not clipped) - a clipped frame is not a blank one and the
    blank check cannot see it."""
    al = a[:, :, 3]
    n = int((al > EPS).sum())
    border = max(float(al[0, :].max()), float(al[-1, :].max()),
                 float(al[:, 0].max()), float(al[:, -1].max()))
    if n == 0:
        errs.append("%s: BLANK frame (0 opaque px)" % name)
    if border > EPS:
        errs.append("%s: alpha %.3f on the frame border - the body is clipped"
                    % (name, border))
    return dict(opaque_px=n, border_alpha=round(border, 4))


def build_split(errs):
    """Build this arm with the brow split out. Returns (brow_objs, rest_objs,
    all_objs, meta, info) or (None, ...) on RED."""
    _clear()
    SPLIT["span"] = None
    M.merge_objs = _REAL_MERGE
    objs0, meta0 = MG.build_miniboss(KEY)
    b0, n0 = _bounds_of(objs0), len(objs0)
    _clear()

    P = M.BUILDERS[KEY]()
    spans = dict(getattr(P, "spans", {}) or {})
    if SPAN not in spans:
        errs.append("%s: builder declares no `%s` span - nothing to split"
                    % (KEY, SPAN))
        return None, None, None, None, {}
    a, b = spans[SPAN]
    rng = [[int(a), int(b)]]
    SPLIT["span"] = rng
    M.merge_objs = _split_merge
    try:
        objs, meta = MG.build_miniboss(KEY)
    finally:
        M.merge_objs = _REAL_MERGE
    b1 = _bounds_of(objs)
    info = dict(span=rng, bounds_control=b0, bounds_split=b1,
                objs_control=n0, objs_split=len(objs),
                item_counts=dict(SPLIT["counts"]))
    if max(abs(x - y) for x, y in zip(b0, b1)) > 1e-4:
        errs.append("%s: bounds moved under the split - every pixel moved, so "
                    "no count below means anything" % KEY)
        return None, None, None, None, info
    c = SPLIT["counts"]
    if c.get("inside", 0) + c.get("outside", 0) != c.get("total", -1):
        errs.append("%s: item count not conserved by the split" % KEY)
        return None, None, None, None, info
    brow = [o for o in objs if id(o) in SPLIT["ids"]]
    rest = [o for o in objs if id(o) not in SPLIT["ids"]]
    if not brow:
        errs.append("%s: the `%s` span merged to no object" % (KEY, SPAN))
        return None, None, None, None, info
    nv = sum(len(o.data.vertices) for o in brow if o.type == 'MESH')
    info["brow_objs"] = [o.name for o in brow]
    info["brow_verts"] = nv
    if nv == 0:
        errs.append("%s: the brow object carries 0 vertices" % KEY)
        return None, None, None, None, info
    return brow, rest, objs, meta, info


def lock_camera(objs, meta):
    """Derive the camera ONCE, from the shipped build, and hand back the exact
    numbers so every arm is shot through the same frame. TRAP 1: every value
    comes from the measured evaluated bounds, never a constant."""
    scene = bpy.context.scene
    eng = G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = 760, 760
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    mn, mx, pts = G.world_bounds(objs)
    radius = max(0.5, (mx - mn).length / 2.0)
    cent = Vector(((mn.x + mx.x) / 2.0, (mn.y + mx.y) / 2.0, (mn.z + mx.z) / 2.0))
    return dict(engine=eng, radius=radius, cent=tuple(cent),
                ortho=max(mx.x - mn.x, mx.z - mn.z) * 1.18,
                aura=meta["aura"])


def shoot_arm(repo, tag, cam_lock, errs):
    brow, rest, objs, meta, info = build_split(errs)
    if brow is None:
        return dict(tag=tag, red=True, info=info)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 760, 760
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    G.set_engine(scene)
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes if n.type == 'BACKGROUND'), None)
    if bg:
        bg.inputs['Color'].default_value = (0.045, 0.05, 0.065, 1.0)
        bg.inputs['Strength'].default_value = 1.0

    cent = Vector(cam_lock["cent"])
    radius = cam_lock["radius"]
    rig = F.even_lights(cent, radius, cam_lock["aura"])
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam_d.ortho_scale = cam_lock["ortho"]
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam

    outdir = os.path.join(repo, "renders", "art", "minibosses", "_brow", KEY + tag)
    os.makedirs(outdir, exist_ok=True)
    cell = dict(tag=tag, outdir=outdir, info=info, views={})
    _mn, _mx, pts = G.world_bounds(objs)
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
        X = _shot(os.path.join(outdir, "X_%s.png" % vname), hide=brow)
        g = {"B": _frame_guard(B, "%s %s B" % (tag, vname), errs),
             "X": _frame_guard(X, "%s %s X" % (tag, vname), errs)}
        moved = np.abs(B - X).max(axis=2) > EPS
        nm = int(moved.sum())
        vcell = dict(guard=g, moved_px_full=nm)
        if nm == 0:
            vcell["red"] = ("ZERO px moved by hiding the brow at FULL res - "
                            "the brow is not being rendered at all, and every "
                            "rung number below would be a metric over no pairs")
            errs.append("%s %s: 0 px moved by the brow ablation at full res"
                        % (tag, vname))
        else:
            ys, xs = np.where(moved)
            vcell["moved_bbox"] = [int(xs.min()), int(ys.min()),
                                   int(xs.max()), int(ys.max())]
        cell["views"][vname] = vcell
    return cell


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    args = ap.parse_args(argv)
    errs = []
    rep = {"key": KEY, "span": SPAN, "arms": {}, "errors": errs,
           "arm_env": {t: e for t, e in ARMS}}

    # the camera is locked off the SHIPPED build, before any arm is shot
    _clear()
    SPLIT["span"] = None
    M.merge_objs = _REAL_MERGE
    objs, meta = MG.build_miniboss(KEY)
    cam_lock = lock_camera(objs, meta)
    rep["camera"] = {k: v for k, v in cam_lock.items() if k != "aura"}
    print("[browshot] camera locked: %s" % rep["camera"], flush=True)
    _clear()

    for tag, env in ARMS:
        prev = _apply(env)
        try:
            cell = shoot_arm(args.repo, tag, cam_lock, errs)
        finally:
            _restore(prev)
            _clear()
        rep["arms"][tag] = cell
        print("[browshot] %s env=%s front_moved=%s side_moved=%s" % (
            tag, env,
            cell.get("views", {}).get("front", {}).get("moved_px_full"),
            cell.get("views", {}).get("side", {}).get("moved_px_full")), flush=True)

    rep["ok"] = not errs
    base = os.path.join(args.repo, "renders", "art", "minibosses", "_brow")
    os.makedirs(base, exist_ok=True)
    out = os.path.join(base, "_browshot.json")
    with open(out, "w") as fh:
        json.dump(rep, fh, indent=1)
    print("[browshot] wrote %s ok=%s" % (out, rep["ok"]), flush=True)
    for e in errs:
        print("[browshot] RED %s" % e, flush=True)


main()
