"""_faceseen.py - CAN THE VIEWER SEE THIS BODY'S FACE, AND WHAT IS COVERING IT?

  blender -b -noaudio -P tools/art/_faceseen.py -- --repo <repo> --key thatcher

WHY THIS EXISTS. Fault 3 on the thatcher has stood open for three passes with
no number attached to it, and the one sentence it carries - "from the side the
head is almost entirely behind the bundle" - is a GUESS AT A CAUSE written
while looking at a picture. This lane's pass-11 fault was shipping
`head_glow_px: 156` beside "the head now has no face at all"; its correction
is the only test that has survived contact with a picture here:

  RENDER WITH AND WITHOUT, THROUGH ONE LOCKED CAMERA, AND COUNT THE PIXELS
  THAT MOVED. Occlusion and depth are then the renderer's problem, not mine.

`mask_of` is the wrong tool twice over: it renders a group ALONE, so it answers
how BIG the face is and never whether it can be SEEN, and it cannot apportion
blame at all.

HOW THE FACE IS ISOLATED, AND WHY NO GEOMETRY IS REMOVED. The obvious cut -
build once without the face items - MOVES THE WORLD BOUNDS. The face oval is
the front-most thing on this body in -y, so dropping it changes the bounds,
which changes `build_miniboss`'s height normalisation `k`, which moves EVERY
VERTEX ON THE BODY. The diff would then be enormous, uniform and green, and it
would mean nothing. So this file follows MB_CUEOFF's proven pattern instead: it
REPAINTS the face oval into the hood's own `dark` slot, leaving every vertex
exactly where it was. The two builds are vertex-identical by construction, and
the bounds are ASSERTED equal anyway rather than hoped equal.

  face_seen  = pixels where the shipped frame differs from the repainted one,
               i.e. where the face's own value is the FRONT-MOST thing a
               viewer gets. This is the number.
  face_noreed= the same count with the `bone` mesh (the reed) hidden in BOTH
               arms. The camera is already locked by then, so hiding cannot
               move it.
  reed_cover = face_noreed - face_seen, the pixels of face the REED takes.
               What is left over after that is taken by something else on the
               body - the hood's own profile, the arm, the shoulder - and this
               file says so rather than naming a culprit it did not measure.

WHAT THIS FILE CANNOT SEE, SAID PLAINLY.
 1. It counts PIXELS, not legibility. A face can clear 400 px and still read as
    a blank plate, because eyes and mouth are `dark` on `dark` once the oval is
    repainted and are therefore INVISIBLE TO THIS INSTRUMENT BY CONSTRUCTION.
    It measures the face PLATE. Whether that plate has a face ON it is answered
    by looking at the hero sheet, as it was at pass 5, and by nothing here.
 2. The three ties are `dark` and stay in the `face_noreed` arm, so that arm is
    a FLOOR on the unoccluded face and not the true free area.
 3. It says nothing about value, hue or whether the face separates from the
    hood - only about how much of it reaches the camera.

RED ON EMPTY, AND THE FIRST CUT OF THIS FILE GOT THE DISTINCTION WRONG ON ITS
OWN FIRST RUN. A metric over zero pixels reads green and means nothing - but on
THIS question zero is often the RIGHT answer. I wrote `face_noreed < 300 px` as
a per-view instrument error, and the thatcher's BACK view came back 0/0 and was
reported as a fault in the instrument. It is nothing of the kind: this body's
hood is dark front AND back precisely so that a viewer behind him sees no face,
which is the Beadle's no-facing fault answered by construction. My guard called
a shipped design decision a broken camera.

So the control is global and the results are per view:
  CONTROL - if the face plate cannot be seen on ANY view with the reed hidden,
  then the camera, the build or the isolation is broken and NOTHING here was
  measured. That is the only instrument error this file can raise.
  RESULT  - a per-view count of 0, the control having passed, means exactly
  what it says: no pixel of the face reaches that camera.
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


def _clear():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)


def _build(key, group, repaint_to, errs):
    """Build the body. If repaint_to is set, the one `body`-slot item inside
    the named group is moved into that slot instead - same verts, same faces,
    same order, different material. Returns (objs, meta, n_repainted)."""
    _clear()
    cap = {}
    real_builder = M.BUILDERS[key]
    real_merge = M.merge_objs
    count = [0]

    def _b():
        P = real_builder()
        cap["P"] = P
        return P

    def _merge(k, items, mats, suffix=None, vcols=None):
        if repaint_to:
            P = cap.get("P")
            spans = getattr(P, "spans", None) or {}
            if group not in spans:
                errs.append("%s: no `%s` span on this builder - the face "
                            "cannot be isolated and nothing here is a pass"
                            % (k, group))
                return real_merge(k, items, mats, suffix=suffix, vcols=vcols)
            a, b = spans[group]
            hits = [i for i in range(a, b) if items[i][2] == 'body']
            # THE ISOLATION MUST BE EXACT OR THIS FILE IS MEASURING SOMETHING
            # ELSE. One `body` item in the head group is the face oval; two
            # would mean a later pass added a second pale shape and this
            # instrument would silently fold it in.
            if len(hits) != 1:
                errs.append("%s: expected exactly 1 `body` item in `%s`, "
                            "found %d - the face is not isolated and this "
                            "number would be about the wrong geometry"
                            % (k, group, len(hits)))
                return real_merge(k, items, mats, suffix=suffix, vcols=vcols)
            items = list(items)
            vcols = dict(vcols or {})
            i = hits[0]
            old = items[i]
            new = (old[0], old[1], repaint_to)
            if id(old) in vcols:          # carry any vertex paint across
                vcols[id(new)] = vcols.pop(id(old))
            items[i] = new
            count[0] = 1
        return real_merge(k, items, mats, suffix=suffix, vcols=vcols)

    M.BUILDERS[key] = _b
    M.merge_objs = _merge
    try:
        objs, meta = MG.build_miniboss(key)
    finally:
        M.BUILDERS[key] = real_builder
        M.merge_objs = real_merge
    return objs, meta, count[0]


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


def _dilate(m, n):
    """Binary dilation by n px, numpy only - there is no scipy in Blender."""
    out = m.copy()
    for _ in range(n):
        g = out.copy()
        g[1:, :] |= out[:-1, :]
        g[:-1, :] |= out[1:, :]
        g[:, 1:] |= out[:, :-1]
        g[:, :-1] |= out[:, 1:]
        out = g
    return out


def _local_contrast(B, fm, ring=6):
    """THE FACE PLATE'S SHIPPED SCREEN LUMA AGAINST WHAT IS RIGHT BESIDE IT.

    `face_seen` counts pixels and says nothing about whether those pixels can
    be TOLD APART from the hood they sit in - which is this body's whole
    contrast-sandwich argument, and the thing that fails at side where the
    front reads fine. A global p50 would not answer it either: the question is
    LOCAL, face against the few px of head around it.

    WHAT IT CANNOT SEE: the ring is whatever is within `ring` px of the face
    and opaque - usually hood, but at a boundary it can catch reed or
    background-adjacent rim pixels. It is a local read, not a hood mask, and
    it is reported as one. It also measures VALUE only; hue is not in it."""
    if int(fm.sum()) < 50:
        return {"red": "face mask under 50 px - no contrast was measured"}
    lum = _luma(B)
    opaque = B[:, :, 3] > 0.5 if B.shape[2] > 3 else np.ones(lum.shape, bool)
    around = _dilate(fm, ring) & ~fm & opaque
    if int(around.sum()) < 50:
        return {"red": "ring under 50 px - no contrast was measured"}
    f, a = lum[fm], lum[around]
    return {"face_p50": round(float(np.percentile(f, 50)), 4),
            "ring_p50": round(float(np.percentile(a, 50)), 4),
            "ratio": round(float(np.percentile(f, 50))
                           / max(1e-6, float(np.percentile(a, 50))), 3),
            "margin": round(float(np.percentile(f, 50)
                                  - np.percentile(a, 50)), 4),
            "face_px": int(fm.sum()), "ring_px": int(around.sum())}


def _luma(a):
    return 0.2126 * a[:, :, 0] + 0.7152 * a[:, :, 1] + 0.0722 * a[:, :, 2]


def _shot(path, hide=()):
    for o in hide:
        o.hide_render = True
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    for o in hide:
        o.hide_render = False
    return G.read_png(path)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--key", default="thatcher")
    ap.add_argument("--group", default="head")
    ap.add_argument("--occluder-slot", default="bone")
    ap.add_argument("--tag", default="")
    ap.add_argument("--out", default="")
    args = ap.parse_args(argv)
    key, tag = args.key, args.tag
    outdir = os.path.join(args.repo, "renders", "art", "minibosses", "_faceseen")
    os.makedirs(outdir, exist_ok=True)
    tmp = os.path.join(outdir, "_tmp" + tag)
    os.makedirs(tmp, exist_ok=True)
    errs = []
    rep = {"key": key, "tag": tag, "group": args.group, "views": {},
           "errors": errs,
           "asks": "how many pixels of the FACE PLATE reach the camera, per "
                   "view, by with/without through one locked camera - and how "
                   "many of the missing ones the reed takes",
           "cannot_see": "whether the plate has a FACE on it (eyes and mouth "
                         "are dark-on-dark to this test by construction), "
                         "value, hue, and the dark ties, which stay in the "
                         "no-reed arm and make it a FLOOR"}

    objs, meta, _ = _build(key, args.group, None, errs)
    mn, mx, pts = G.world_bounds(objs)
    radius = max(0.5, (mx - mn).length / 2.0)
    cent = Vector(((mn.x + mx.x) / 2.0, (mn.y + mx.y) / 2.0, (mn.z + mx.z) / 2.0))
    occ = [o for o in objs if o.name.endswith("_" + args.occluder_slot)]
    if not occ:
        errs.append("%s: no `%s` mesh - the blame arm cannot run"
                    % (key, args.occluder_slot))
    rig, cam, cam_d = _setup(bpy.context.scene, meta["aura"], cent, radius, mn, mx)

    frames = {}
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
        Bn = _shot(os.path.join(tmp, "_B_noreed_%s.png" % vname), hide=occ)
        frames[vname] = (B, Bn, cam.location.copy(), cam.rotation_euler.copy(),
                         cam_d.clip_start, cam_d.clip_end)

    # SECOND BUILD: the face oval repainted into the hood's slot. Vertex-
    # identical, so the camera poses are replayed and nothing but that one
    # material can differ.
    objs2, meta2, nrep = _build(key, args.group, 'dark', errs)
    rep["repainted_items"] = nrep
    if nrep != 1 and not errs:
        errs.append("%s: repaint moved %d items, expected 1" % (key, nrep))
    mn2, mx2, _p2 = G.world_bounds(objs2)
    # THE GUARD THAT MAKES THE WHOLE FILE HONEST. If the two builds do not
    # occupy the identical bounds then `k` differed, every vertex moved, and
    # the diff below is a picture of the normalisation and not of the face.
    drift = max(abs(mn.x - mn2.x), abs(mn.y - mn2.y), abs(mn.z - mn2.z),
                abs(mx.x - mx2.x), abs(mx.y - mx2.y), abs(mx.z - mx2.z))
    rep["bounds_drift"] = round(float(drift), 9)
    if drift > 1e-6:
        errs.append("%s: bounds moved %.3g between the two builds - the height "
                    "normalisation differed, so every vertex moved and the "
                    "pixel diff is NOT the face" % (key, drift))
    occ2 = [o for o in objs2 if o.name.endswith("_" + args.occluder_slot)]
    rig2, cam2, cam_d2 = _setup(bpy.context.scene, meta2["aura"], cent, radius, mn, mx)

    for vname, az in VIEWS:
        B, Bn, loc, rot, cs, ce = frames[vname]
        F.aim_lights(rig2, cent, radius, az)
        cam2.location, cam2.rotation_euler = loc, rot
        cam_d2.clip_start, cam_d2.clip_end = cs, ce
        bpy.context.view_layer.update()
        X = _shot(os.path.join(tmp, "_X_%s.png" % vname))
        Xn = _shot(os.path.join(tmp, "_X_noreed_%s.png" % vname), hide=occ2)
        fm = np.abs(B - X).max(axis=2) > EPS
        seen = int(fm.sum())
        free = int((np.abs(Bn - Xn).max(axis=2) > EPS).sum())
        cell = {"face_seen": seen, "face_noreed": free,
                "contrast": _local_contrast(B, fm),
                "reed_cover": free - seen,
                "reed_cover_frac": (round((free - seen) / float(free), 4)
                                    if free > 0 else None),
                "other_cover_note": "pixels of the face missing in the NO-REED "
                                    "arm are taken by something that is not "
                                    "the reed; this file does not name it"}
        if seen == 0:
            cell["red"] = ("face_seen is 0 - A RESULT, NOT AN ERROR: no pixel "
                           "of the face plate reaches this camera. Whether "
                           "that is a fault or the design depends on the view")
        rep["views"][vname] = cell

    # THE ONE CONTROL. Not per view - see the docstring.
    best = max((c.get("face_noreed", 0) for c in rep["views"].values()),
               default=0)
    rep["control_best_face_noreed"] = best
    if best < 300:
        errs.append("%s: the face plate reaches at most %d px on ANY view with "
                    "the reed hidden - the camera, the build or the isolation "
                    "is broken and nothing here was measured" % (key, best))

    rep["thatcher_twist_env"] = os.environ.get("THATCHER_TWIST", "(unset)")
    rep["thatch_gauge_env"] = os.environ.get("THATCH_GAUGE", "(unset)")
    rep["head_env"] = os.environ.get("THATCHER_HEAD", "(unset)")
    rep["tiesec_env"] = os.environ.get("THATCHER_TIESEC", "(unset)")
    rep["ok"] = not errs
    out = args.out or os.path.join(outdir, "_faceseen_%s%s.json" % (key, tag))
    with open(out, "w") as fh:
        json.dump(rep, fh, indent=1)
    print("[faceseen] wrote %s ok=%s" % (out, rep["ok"]), flush=True)


main()
