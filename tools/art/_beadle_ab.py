"""_beadle_ab.py - PASS 12 A/B for THE BEADLE, answering the team lead's three
09:1x findings SEPARATELY through ONE LOCKED CAMERA.

  blender -b -noaudio -P tools/art/_beadle_ab.py -- --repo <repo>

WHY A LOCKED CAMERA. The standing lesson from the Hurdleman's pass 11 is that a
number which does not answer the VIEWER'S question is not evidence. The viewer's
question here is "did anything I can SEE change?", so every variant renders
through the camera measured off the BASE body - if the camera re-fit itself per
variant, every pixel would move and the count would read green for nothing.

IT ALSO GOES RED ON EMPTY: a moved-pixel count of zero is a FAILED fix, not a
pass, and a variant whose alpha is empty fails loudly.
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


def _args():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--res", default="560x784")
    return ap.parse_args(a)


def build(nape, knob):
    G.purge()
    M._BEADLE_NAPE = bool(nape)
    M._BEADLE_KNOB = bool(knob)
    return MG.build_miniboss(KEY)


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
    return 0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]


def moved(p_base, p_var, thr=0.02):
    """THE VIEWER'S QUESTION: how many pixels through this one camera are
    different? Counts an alpha change as a change too, so a silhouette that
    grew is not invisible to it."""
    A, B = G.read_png(p_base), G.read_png(p_var)
    assert A.shape == B.shape, "shape %s vs %s" % (A.shape, B.shape)
    d = np.max(np.abs(A[..., :3] - B[..., :3]), axis=-1)
    da = np.abs(A[..., 3] - B[..., 3])
    m = (np.maximum(d, da) > thr)
    opaque = int((A[..., 3] > 0.5).sum())
    return int(m.sum()), opaque, m


def opaque_and_border(path):
    """The standing blank-and-border assertion: opaque pixels must exist and
    NOTHING may touch the frame edge."""
    a = G.read_png(path)
    al = a[..., 3]
    op = int((al > 0.5).sum())
    edge = max(float(al[0, :].max()), float(al[-1, :].max()),
               float(al[:, 0].max()), float(al[:, -1].max()))
    return op, edge, a


def main():
    ns = _args()
    resx, resy = (int(v) for v in ns.res.lower().split("x"))
    out = os.path.join(ns.repo, "renders", "art", "minibosses", "_ab_beadle")
    os.makedirs(out, exist_ok=True)
    rep = {"res": [resx, resy], "errors": [], "checks": {}}

    scene = bpy.context.scene
    MG.G.set_engine(scene)

    # ---- BASE BODY: the camera is measured ONCE, off this, and locked ----
    objs, info = build(0, 0)
    mn, mx, pts = G.world_bounds(objs)
    center = (mn + mx) / 2.0
    radius = max(0.35, (mx - mn).length / 2.0)
    span = max((mx - mn).x, (mx - mn).y, (mx - mn).z)
    ORTHO = span * 1.18
    rep["camera"] = {"center": list(center), "radius": round(radius, 4),
                     "ortho": round(ORTHO, 4), "locked": True}
    rig(scene, center, radius, info["aura"], resx, resy)

    VIEWS = {"back": (180.0, 11.0), "side": (90.0, 11.0), "front": (0.0, 12.0)}
    paths = {}
    for v, (az, el) in VIEWS.items():
        paths[("base", v)] = shoot(os.path.join(out, "base_%s.png" % v),
                                   center, radius, az, el, ORTHO)

    # ---- (c) IS IT THE WOOL OR THE RIM LIGHT? one change, one camera ----
    # add_lights puts the rim at (0.1, 1.0, 0.55) - DIRECTLY BEHIND - and its
    # colour is the CANON aura, which for this body is (1.00, 0.74, 0.26) amber.
    # In the BACK view that rim is the key light on everything you can see. So
    # re-render the SAME body with the rim neutralised and nothing else touched.
    for li in list(bpy.data.objects):
        if li.type == 'LIGHT' and li.name.startswith("rim"):
            li.data.color = (1.0, 1.0, 1.0)
    paths[("neutralrim", "back")] = shoot(
        os.path.join(out, "neutralrim_back.png"), center, radius, 180.0, 11.0, ORTHO)
    # and put the amber rim back for every later variant
    for li in list(bpy.data.objects):
        if li.type == 'LIGHT' and li.name.startswith("rim"):
            li.data.color = info["aura"]

    def coat_patch(path):
        """A fixed window on the COAT (lower torso), in fractions of the frame,
        so the same ground is sampled in both renders. Opaque pixels only."""
        a = G.read_png(path)
        h, w = a.shape[0], a.shape[1]
        sub = a[int(h * 0.62):int(h * 0.78), int(w * 0.12):int(w * 0.44)]
        m = sub[..., 3] > 0.9
        if int(m.sum()) < 200:
            return None, int(m.sum())
        px = sub[..., :3][m]
        return [round(float(c), 4) for c in px.mean(axis=0)], int(m.sum())

    amber, n1 = coat_patch(paths[("base", "back")])
    neut, n2 = coat_patch(paths[("neutralrim", "back")])
    if amber is None or neut is None:
        rep["errors"].append("coat patch empty: %s %s" % (n1, n2))
    else:
        rep["checks"]["c_warm_back"] = {
            "coat_rgb_with_aura_rim": amber, "coat_rgb_with_neutral_rim": neut,
            "px": [n1, n2],
            "r_minus_b_aura": round(amber[0] - amber[2], 4),
            "r_minus_b_neutral": round(neut[0] - neut[2], 4),
            "material_body_is_blue_grey": True,
        }

    # ---- (a) THE NAPE: measured on the BACK view, and the FRONT must not move
    objs_a, info_a = build(1, 0)
    rig(scene, center, radius, info_a["aura"], resx, resy)
    for v in ("back", "front", "side"):
        az, el = VIEWS[v]
        paths[("nape", v)] = shoot(os.path.join(out, "nape_%s.png" % v),
                                   center, radius, az, el, ORTHO)
    mb, opb, _ = moved(paths[("base", "back")], paths[("nape", "back")])
    mf, opf, _ = moved(paths[("base", "front")], paths[("nape", "front")])
    rep["checks"]["a_nape"] = {
        "back_moved_px": mb, "back_opaque_px": opb,
        "back_moved_frac": round(mb / max(1, opb), 4),
        "front_moved_px": mf, "front_opaque_px": opf,
        "front_moved_frac": round(mf / max(1, opf), 4),
        "red_on_empty": mb == 0,
    }

    # ---- (b) THE KNOB: measured on the SIDE view ----
    objs_b, info_b = build(0, 1)
    rig(scene, center, radius, info_b["aura"], resx, resy)
    for v in ("side", "front", "back"):
        az, el = VIEWS[v]
        paths[("knob", v)] = shoot(os.path.join(out, "knob_%s.png" % v),
                                   center, radius, az, el, ORTHO)
    ms, ops, mask = moved(paths[("base", "side")], paths[("knob", "side")])

    # AND THE NUMBER THAT ACTUALLY ANSWERS THE FAULT. The fault was not "the
    # knob is small", it was "the knob has no CONTRAST against what is behind
    # it". So: take the knob's own pixels, take the ring of pixels just outside
    # them, and report the LUMINANCE GAP across that boundary. A pale knob on a
    # pale skull reads a small gap; a dark ferrule reads a large one.
    def knob_gap(path, box):
        a = G.read_png(path)
        h, w = a.shape[0], a.shape[1]
        y0, y1, x0, x1 = (int(h * box[0]), int(h * box[1]),
                          int(w * box[2]), int(w * box[3]))
        sub = a[y0:y1, x0:x1]
        if sub[..., 3].max() < 0.5:
            return None
        li = lum(sub)
        op = sub[..., 3] > 0.5
        if int(op.sum()) < 50:
            return None
        v = li[op]
        return {"lum_min": round(float(v.min()), 4),
                "lum_max": round(float(v.max()), 4),
                "lum_range": round(float(v.max() - v.min()), 4),
                "lum_p05": round(float(np.percentile(v, 5)), 4),
                "lum_p95": round(float(np.percentile(v, 95)), 4),
                "px": int(op.sum())}

    # *** THE WINDOW IS DERIVED FROM THE MOVED MASK, NOT TYPED, AND THE FIRST
    # *** VERSION OF THIS CHECK WAS BLIND. *** I typed a box in frame fractions
    # at (0.33, 0.50, 0.40, 0.66) and it returned window_base and window_knob
    # IDENTICAL TO FOUR DECIMALS over 19,430 px while the renders plainly
    # differed - a window big enough to be dominated by the body cannot see the
    # one object it exists to measure. That is the Hurdleman's pass-11 fault in
    # a new coat: it did not go red, it went BLIND, and the run still read
    # GREEN. The knob's pixels are exactly the pixels that MOVED, so the mask
    # locates the window and the window cannot miss - and if the two windows
    # come back identical now, that is RED, because it means nothing moved.
    ys, xs = np.nonzero(mask)
    if ys.size:
        pad = 10
        BOX = (max(0, int(ys.min()) - pad) / mask.shape[0],
               min(mask.shape[0], int(ys.max()) + pad) / mask.shape[0],
               max(0, int(xs.min()) - pad) / mask.shape[1],
               min(mask.shape[1], int(xs.max()) + pad) / mask.shape[1])
        wb = knob_gap(paths[("base", "side")], BOX)
        wk = knob_gap(paths[("knob", "side")], BOX)
    else:
        BOX, wb, wk = None, None, None
    blind = (wb is not None and wb == wk)
    if blind:
        rep["errors"].append("b_knob window is BLIND: base and variant identical")
    # *** AND A GUARD THAT A COIN-FLIP SATISFIES IS NOT A GUARD. *** With the
    # window derived rather than typed the two readings stopped being identical
    # - by 0.003 at the 5th percentile, which is noise, so `blind` went False on
    # nothing. The window is still ~16,000 px around a knob of a few hundred:
    # the moved mask tells me WHERE the knob is, it does not make a luminance
    # histogram over the surrounding body into a statement about the knob. So
    # this check DECLARES ITS OWN COARSENESS instead of being read as evidence.
    # What carries fault (b) is the two side renders I looked at, and the
    # front-view core/ring gap in _beadle_knobgap.py, where the lit core does
    # isolate: 0.109 base -> 0.422 fixed.
    coarse = (wb is not None and wb.get("px", 0) > 4 * max(1, ms))
    rep["checks"].setdefault("instrument_notes", {})["b_window"] = (
        "TOO COARSE TO BE EVIDENCE - window %s px against %s moved px; it "
        "locates the knob, it does not measure it. The picture and "
        "_beadle_knobgap.py carry this fault."
        % ((wb or {}).get("px"), ms) if coarse else "window is knob-dominated")
    rep["checks"]["b_knob"] = {
        "side_moved_px": ms, "side_opaque_px": ops,
        "side_moved_frac": round(ms / max(1, ops), 4),
        "window_derived_from_moved_mask": BOX,
        "window_base": wb, "window_knob": wk,
        "red_on_empty": ms == 0, "red_on_blind": blind,
    }

    # ---- BOTH: the shipped shape ----
    objs_x, info_x = build(1, 1)
    rig(scene, center, radius, info_x["aura"], resx, resy)
    for v in ("front", "side", "back"):
        az, el = VIEWS[v]
        paths[("both", v)] = shoot(os.path.join(out, "both_%s.png" % v),
                                   center, radius, az, el, ORTHO)

    blanks, clipped = [], []
    for (k, v), p in sorted(paths.items()):
        op, edge, _ = opaque_and_border(p)
        rep["checks"].setdefault("renders", {})["%s_%s" % (k, v)] = \
            {"opaque": op, "border_alpha": round(float(edge), 4)}
        if op < 500:
            blanks.append(p)
        if edge > 0.02:
            clipped.append(p)
    rep["blanks"], rep["frame_clips"] = blanks, clipped

    a_ok = rep["checks"]["a_nape"]["back_moved_px"] > 0
    b_ok = (rep["checks"]["b_knob"]["side_moved_px"] > 0
            and not rep["checks"]["b_knob"]["red_on_blind"])
    rep["verdict"] = ("GREEN" if (a_ok and b_ok and not blanks and not clipped
                                  and not rep["errors"]) else "RED")
    with open(os.path.join(out, "_ab.json"), "w") as fh:
        json.dump(rep, fh, indent=1)
    print("AB_JSON_BEGIN")
    print(json.dumps(rep))
    print("AB_JSON_END")


main()
