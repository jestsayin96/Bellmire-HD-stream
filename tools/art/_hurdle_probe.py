"""_hurdle_probe - MEASURE THE HURDLEMAN'S THREE WORST FAULTS, ONE AT A TIME.

  blender -b -noaudio -P tools/art/_hurdle_probe.py -- --repo <repo> --tag before

The team lead's 08:58 row names three of the eight faults I wrote down myself
in docs/art/MINIBOSSES.md and says: re-measure with the same method, state the
numbers, do not assert the change. "I looked and it is better" is not a number,
so this file turns each of the three into one:

  FAULT 1  BACK VIEW - "the three spares read as a loose jumble of sticks".
           A fan of PANELS has few edge directions; a jumble has many. Metric:
           AXIS CONCENTRATION - the share of the spares-only silhouette's edge
           pixels whose gradient direction falls in the two strongest 10-degree
           orientation bins (a panel has exactly two families, posts and rails).
           Jumble -> low. Panels -> high. Plus the 4-connected COMPONENT COUNT
           of the same mask: three panels tied in one bundle should be fewer
           pieces than three panels crossing in mid-air.

  FAULT 3  THREE-QUARTER VIEW - "the standing hurdle covers the body from the
           chest down". Metric: OCCLUSION - the share of the man's own pixels
           that the hurdle's pixels sit on top of, and the share of the man
           that survives BELOW his own chest line. Both measured off isolated
           renders of the two groups through ONE camera, not estimated.

  FAULT 4  FRONT VIEW - "the withy head still reads as a helmet with a visor
           band". A visor is ONE DARK HORIZONTAL BAND across the head. Metric:
           BAND SCORE - over the head's own bounding box, the maximum per-row
           dark-weave coverage minus the median row's. A band spikes one row
           family; a vertical weave spreads it. The glow (the eyes) is measured
           SEPARATELY on its own row spread, because two lit dots sitting on
           that band are half the visor read and must not hide inside one
           number.

*** AND IT GOES RED ON EMPTY. *** Every metric states the pixel count it was
computed over. A mask with fewer than MIN_PX pixels is an error, not a pass -
this lane has already shipped one register that was ok:true over pairs:{} and
nearly called a real fix dead with an instrument that could not move.
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

RES_X, RES_Y = 760, 520
MIN_PX = 300
KEY = "hurdleman"


def build_groups():
    """One object per named span, normalised exactly as minibossgen does -
    authored height, feet on z=0 - so the numbers are in the shipped scale."""
    P = M.BUILDERS[KEY]()
    spans = getattr(P, "spans", None)
    if not spans:
        raise RuntimeError("builder exposed no spans: nothing can be isolated")
    mat = L.mat_solid("probe", (0.6, 0.6, 0.6), 0.5, 0.0)
    objs, groups = [], {}
    for name, (i0, i1) in spans.items():
        gv, gf = [], []
        for verts, faces, slot in P.items[i0:i1]:
            off = len(gv)
            gv.extend(verts)
            gf.extend([tuple(i + off for i in f) for f in faces])
        if not gf:
            continue
        ob = L.make("%s_%s" % (KEY, name), gv, gf, mat)
        groups[name] = [ob]
        objs.append(ob)
    # the head splits again by SLOT - the weave is 'dark', the eyes are 'glow'
    # - and EVERYTHING THAT IS NOT THE EYES is kept as its own group, because
    # the occlusion test needs an occluder that does not contain the thing it
    # is occluding. The first version of that test used the whole "head" span,
    # which holds the eyes, so the glow was always hidden by itself and the
    # answer was 0 no matter where the eyes were. A metric that cannot come out
    # any other way is not a measurement.
    i0, i1 = spans["head"]
    gv, gf = [], []
    for verts, faces, slot in P.items[i0:i1]:
        if slot == "glow":
            continue
        off = len(gv)
        gv.extend(verts)
        gf.extend([tuple(i + off for i in f) for f in faces])
    if gf:
        ob = L.make("%s_head_noglow" % KEY, gv, gf, mat)
        groups["head_noglow"] = [ob]
        objs.append(ob)
    for want in ("dark", "glow"):
        gv, gf = [], []
        for verts, faces, slot in P.items[i0:i1]:
            if slot != want:
                continue
            off = len(gv)
            gv.extend(verts)
            gf.extend([tuple(i + off for i in f) for f in faces])
        if gf:
            ob = L.make("%s_head_%s" % (KEY, want), gv, gf, mat)
            groups["head_" + want] = [ob]
            objs.append(ob)
    mn, mx, _ = G.world_bounds(objs)
    cur = mx.z - mn.z
    k = M.CANON[KEY][1] / cur if cur > 1e-6 else 1.0
    for ob in objs:
        ob.scale = (k, k, k)
        ob.location = (ob.location.x * k, ob.location.y * k, ob.location.z * k)
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(objs)
    for ob in objs:
        ob.location = (ob.location.x, ob.location.y, ob.location.z - mn.z)
    bpy.context.view_layer.update()
    return objs, groups


def setup(objs):
    scene = bpy.context.scene
    G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = RES_X, RES_Y
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    mn, mx, pts = G.world_bounds(objs)
    radius = max(0.5, (mx - mn).length / 2.0)
    G.add_lights(Vector(((mn.x + mx.x) / 2.0, (mn.y + mx.y) / 2.0, (mn.z + mx.z) / 2.0)),
                 radius, (0.7, 0.9, 0.7))
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam_d.ortho_scale = max(mx.x - mn.x, mx.z - mn.z) * 1.25 + 0.4
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    return cam, cam_d, mn, mx, pts, radius


def aim(cam, cam_d, az, el, mn, mx, pts, radius):
    a, e = math.radians(az), math.radians(el)
    dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e),
                   math.sin(e))).normalized()
    target = Vector(((mn.x + mx.x) / 2.0, (mn.y + mx.y) / 2.0, (mn.z + mx.z) / 2.0))
    cam.location = target + dirv * (radius * 4.0 + 4.0)
    cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
    bpy.context.view_layer.update()
    fwd = (cam.matrix_world.to_3x3() @ Vector((0, 0, -1))).normalized()
    depth = [(p - cam.location).dot(fwd) for p in pts]
    cam_d.clip_start = max(0.01, min(depth) - radius * 0.5)
    cam_d.clip_end = max(depth) + radius * 2.0 + 8.0


def mask_of(objs, groups, keep, outpath):
    """Render ONLY the named groups and return the alpha mask."""
    want = set()
    for k in keep:
        for o in groups.get(k, []):
            want.add(o.name)
    for o in objs:
        o.hide_render = o.name not in want
    bpy.context.scene.render.filepath = outpath
    bpy.ops.render.render(write_still=True)
    a = G.read_png(outpath)
    for o in objs:
        o.hide_render = False
    return (a[..., 3] > 0.3)


def rgb_of(objs, groups, keep, outpath):
    """Render ONLY the named groups and return the full RGBA array, not a
    mask - the eye test needs colour, because the question it asks is what the
    picture GAINS when the eyes are switched on."""
    want = set()
    for k in keep:
        for o in groups.get(k, []):
            want.add(o.name)
    for o in objs:
        o.hide_render = o.name not in want
    bpy.context.scene.render.filepath = outpath
    bpy.ops.render.render(write_still=True)
    a = G.read_png(outpath)
    for o in objs:
        o.hide_render = False
    return a


def components(mask):
    """4-connected component count, written out rather than imported: Blender
    carries numpy but not scipy."""
    h, w = mask.shape
    lab = np.zeros((h, w), dtype=np.int32)
    n = 0
    ys, xs = np.nonzero(mask)
    seen = np.zeros((h, w), dtype=bool)
    for y0, x0 in zip(ys, xs):
        if seen[y0, x0]:
            continue
        n += 1
        stack = [(y0, x0)]
        seen[y0, x0] = True
        while stack:
            y, x = stack.pop()
            lab[y, x] = n
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ny, nx = y + dy, x + dx
                if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    stack.append((ny, nx))
    sizes = np.bincount(lab.ravel())[1:] if n else np.array([])
    big = int((sizes >= 60).sum())
    return n, big


def axis_concentration(mask, bins=18):
    """Share of edge-gradient mass in the two strongest 10-degree orientation
    bins. Two families (posts, rails) is a panel; many is a jumble."""
    f = mask.astype(np.float32)
    gx = np.zeros_like(f)
    gy = np.zeros_like(f)
    gx[:, 1:-1] = f[:, 2:] - f[:, :-2]
    gy[1:-1, :] = f[2:, :] - f[:-2, :]
    mag = np.sqrt(gx * gx + gy * gy)
    sel = mag > 0.25
    if int(sel.sum()) < 50:
        return None, 0
    ang = (np.degrees(np.arctan2(gy[sel], gx[sel])) + 180.0) % 180.0
    hist, _ = np.histogram(ang, bins=bins, range=(0.0, 180.0), weights=mag[sel])
    tot = float(hist.sum())
    if tot <= 0:
        return None, int(sel.sum())
    top = np.sort(hist)[::-1][:2].sum()
    return round(float(top / tot), 4), int(sel.sum())


def band_score(mask):
    """Max per-row coverage minus the median row's, inside the mask's own
    bounding box. A dark horizontal visor band spikes one row family."""
    ys, xs = np.nonzero(mask)
    if ys.size < MIN_PX:
        return None, int(ys.size)
    y0, y1, x0, x1 = ys.min(), ys.max(), xs.min(), xs.max()
    sub = mask[y0:y1 + 1, x0:x1 + 1]
    w = max(1, sub.shape[1])
    rows = sub.sum(axis=1) / float(w)
    occupied = rows[rows > 0.0]
    if occupied.size < 3:
        return None, int(ys.size)
    return round(float(rows.max() - np.median(occupied)), 4), int(ys.size)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--tag", required=True)
    args = ap.parse_args(argv)

    out = os.path.join(args.repo, "renders", "art", "minibosses", "_probe")
    os.makedirs(out, exist_ok=True)
    rep = {"tag": args.tag, "ok": True, "errors": [], "metrics": {}, "counts": {}}

    G.purge()
    objs, groups = build_groups()
    cam, cam_d, mn, mx, pts, radius = setup(objs)
    man = [g for g in ("man_lower", "head", "tool_arms") if g in groups]

    def shot(name, keep, az, el, floor=MIN_PX):
        # THE EYES ARE LEGITIMATELY TINY - two glow spheres came in at 251 px
        # and the flat MIN_PX floor called a real measurement empty. A floor
        # that fires on a true reading is as wrong as one that never fires, so
        # the glow mask carries its own, and it is still a floor.
        p = os.path.join(out, "%s_%s.png" % (args.tag, name))
        aim(cam, cam_d, az, el, mn, mx, pts, radius)
        m = mask_of(objs, groups, keep, p)
        n = int(m.sum())
        rep["counts"][name] = n
        if n < floor:
            rep["ok"] = False
            rep["errors"].append("%s: %d px - EMPTY OR NEAR-EMPTY MASK. A metric "
                                 "computed over this is not a measurement." % (name, n))
        return m

    # ---- FAULT 1. BACK VIEW, THE SPARE FAN ON ITS OWN.
    #
    # THE FIRST INSTRUMENT I BUILT FOR THIS FAULT DID NOT MEASURE THE FAULT.
    # Edge-orientation concentration came back 0.8993 on the pass the eye calls
    # a jumble, and the component count came back 1 - because the panels are
    # built of boxes and they touch. Both numbers are true and neither is about
    # SPLAY, which is what the written fault says: "the posts splay and cross at
    # odd angles". So the panels are now rendered ONE AT A TIME and the real
    # question is asked of them: how far apart are their long axes, and how much
    # of each one is buried behind another. The old pair is kept as context, not
    # as the test.
    sp = shot("back_spares", ["spares"], 180.0, 12.0)
    panels = [g for g in ("spare0", "spare1", "spare2") if g in groups]
    pang, pmask = [], []
    for g in panels:
        m = shot("back_%s" % g, [g], 180.0, 12.0)
        pmask.append(m)
        ys, xs = np.nonzero(m)
        if ys.size < MIN_PX:
            continue
        # principal axis of the panel's own silhouette, in screen degrees
        y = ys.astype(np.float64) - ys.mean()
        x = xs.astype(np.float64) - xs.mean()
        cov = np.array([[float((x * x).mean()), float((x * y).mean())],
                        [float((x * y).mean()), float((y * y).mean())]])
        w_, v_ = np.linalg.eigh(cov)
        vx, vy = v_[:, int(np.argmax(w_))]
        pang.append((math.degrees(math.atan2(vy, vx)) + 180.0) % 180.0)
    if len(pang) < 2:
        rep["ok"] = False
        rep["errors"].append("spare panels: fewer than two measurable - RED, "
                             "a splay over one panel is not a splay")
        rep["metrics"]["fan_axis_splay_deg"] = None
    else:
        spread = 0.0
        for i in range(len(pang)):
            for j in range(i + 1, len(pang)):
                d = abs(pang[i] - pang[j]) % 180.0
                spread = max(spread, min(d, 180.0 - d))
        rep["metrics"]["fan_axis_splay_deg"] = round(spread, 2)
        rep["metrics"]["fan_panel_angles_deg"] = [round(a, 2) for a in pang]
        ov = []
        for i, m in enumerate(pmask):
            other = np.zeros_like(m)
            for j, n_ in enumerate(pmask):
                if j != i:
                    other |= n_
            ov.append(round(float((m & other).sum()) / max(1, int(m.sum())), 4))
        rep["metrics"]["fan_panel_overlap"] = ov
        rep["metrics"]["fan_panel_overlap_max"] = max(ov) if ov else None
    conc, edges = axis_concentration(sp)
    ncomp, nbig = components(sp)
    rep["metrics"]["fan_axis_concentration"] = conc
    rep["metrics"]["fan_edge_px"] = edges
    rep["metrics"]["fan_components"] = ncomp
    rep["metrics"]["fan_components_over_60px"] = nbig
    if conc is None:
        rep["ok"] = False
        rep["errors"].append("fan_axis_concentration: no edge mass to measure - RED")
    # and what the man has left to read against behind his own fences
    mb = shot("back_man", man, 180.0, 12.0)
    rep["metrics"]["back_man_px"] = int(mb.sum())
    rep["metrics"]["back_man_hidden_by_spares"] = (
        round(float((mb & sp).sum()) / max(1, int(mb.sum())), 4))

    # ---- FAULT 3. THREE-QUARTER, THE HURDLE OVER THE MAN.
    mm = shot("tq_man", man, 38.0, 14.0)
    hh = shot("tq_hurdle", ["hurdle"], 38.0, 14.0)
    tot = int(mm.sum())
    rep["metrics"]["tq_man_px"] = tot
    rep["metrics"]["tq_man_hidden_by_hurdle"] = round(float((mm & hh).sum()) / max(1, tot), 4)
    ys, xs = np.nonzero(mm)
    if ys.size >= MIN_PX:
        # the chest line: a third of the way down the man's own extent
        chest = ys.min() + int(0.33 * (ys.max() - ys.min()))
        low = mm.copy()
        low[:chest, :] = False
        lown = int(low.sum())
        rep["metrics"]["tq_man_below_chest_px"] = lown
        rep["metrics"]["tq_below_chest_hidden"] = round(
            float((low & hh).sum()) / max(1, lown), 4)
    else:
        rep["ok"] = False
        rep["errors"].append("tq_man: too few pixels to find a chest line - RED")

    # ---- FAULT 4. FRONT, THE WITHY HEAD.
    hd = shot("front_head_dark", ["head_dark"], 0.0, 12.0)
    bs, npx = band_score(hd)
    rep["metrics"]["head_weave_band_score"] = bs
    rep["metrics"]["head_weave_px"] = npx
    if bs is None:
        rep["ok"] = False
        rep["errors"].append("head_weave_band_score: nothing to measure - RED")
    gl = shot("front_head_glow", ["head_glow"], 0.0, 12.0, floor=40)

    # *** PASS 11. THE INSTRUMENT COULD NOT SEE THE FAULT IT WAS BUILT FOR, AND
    # *** THE PICTURE IS WHAT CAUGHT IT. ***
    # mask_of renders the named group ALONE - every other object hidden - which
    # is exactly right for asking how big a thing is and exactly wrong for
    # asking whether it can be SEEN. The eyes sit at y -0.11 inside a solid bone
    # skull whose surface is at -0.154, so on the real render there is no face
    # at all: the shipped table's "156 px" is the size of two spheres that are
    # INSIDE the head. A number that survives its own object being buried is the
    # same class of fault as the register that read ok:true over pairs:{}.
    # So: render everything EXCEPT the glow, and count the glow that SURVIVES it.
    # *** AND MY FIRST ANSWER TO THAT WAS WRONG IN THE SAME FAMILY, WHICH IS
    # *** WORTH WRITING DOWN RATHER THAN QUIETLY REPLACING. *** I rendered the
    # body without the eyes and counted the glow pixels that fell outside its
    # ALPHA. That asks "does the glow stick out past the whole silhouette",
    # and it answers 0 for every face ever drawn, because a face sits INSIDE
    # the head's outline. An alpha mask carries no depth. The number was 0 at
    # fwd 0.110 and still 0 at 0.168 after I had moved the eyes 58 mm clear of
    # the skull - a metric that cannot come out any other way, again.
    # THE HONEST QUESTION IS WHAT THE EYES CHANGE IN THE PICTURE: render the
    # creature with them and without them through one camera and count the
    # pixels that MOVED. That is depth-correct for free, because the renderer
    # does the depth, and it is the viewer's own test.
    not_glow = [k for k in groups if k not in ("head_glow", "head")]
    rgb_off = rgb_of(objs, groups, not_glow,
                     os.path.join(out, "%s_front_noeyes.png" % args.tag))
    rgb_on = rgb_of(objs, groups, not_glow + ["head_glow"],
                    os.path.join(out, "%s_front_witheyes.png" % args.tag))
    d = np.abs(rgb_on[..., :3] - rgb_off[..., :3]).max(axis=2)
    a = np.maximum(rgb_on[..., 3], rgb_off[..., 3])
    vis = (d > 0.08) & (a > 0.3)
    rep["metrics"]["head_glow_visible_px"] = int(vis.sum())
    rep["metrics"]["head_glow_visible_share"] = round(
        float(vis.sum()) / max(1, int(gl.sum())), 4)
    # AND IT GOES RED ON A FEATURE THAT CANNOT BE SEEN. The eyes exist to be
    # looked at; zero surviving pixels is not a small number, it is no face.
    if int(vis.sum()) == 0:
        rep["ok"] = False
        rep["errors"].append("head_glow_visible_px: 0 - the eyes are rendered "
                             "but NOTHING of them survives the body in front of "
                             "them. A glow that cannot be seen is not a face.")
    # AND THE RAW COUNT IS FRAMING-DEPENDENT, WHICH I PROVED BY ACCIDENT THIS
    # RUN: shrinking the spare panels moved head_glow_px 156 -> 178 without any
    # dial on the head being touched, because the camera's ortho scale is
    # derived from the whole body's bounds. The share of the head's own weave is
    # the scale-free form of the same question, so both are reported.
    rep["metrics"]["head_glow_share_of_weave"] = round(
        float(gl.sum()) / max(1, int(rep["metrics"].get("head_weave_px") or 1)), 5)
    gys, gxs = np.nonzero(gl)
    if gys.size:
        rep["metrics"]["head_glow_px"] = int(gys.size)
        rep["metrics"]["head_glow_row_span_px"] = int(gys.max() - gys.min() + 1)
        rep["metrics"]["head_glow_col_span_px"] = int(gxs.max() - gxs.min() + 1)
    else:
        rep["metrics"]["head_glow_px"] = 0
        rep["metrics"]["head_glow_row_span_px"] = 0
        rep["metrics"]["head_glow_col_span_px"] = 0

    rep["verdict"] = "GREEN" if rep["ok"] else "RED"
    with open(os.path.join(out, "_probe_%s.json" % args.tag), "w") as f:
        json.dump(rep, f, indent=1)
    print("HURDLE_PROBE " + json.dumps(rep))


if __name__ == "__main__":
    main()
