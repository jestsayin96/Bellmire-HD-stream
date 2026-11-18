"""_sheen_ab - THE BAND'S COLOUR IS THE DIAL. ONE BODY, FOUR BAND COLOURS.

  blender -b -noaudio -P tools/art/_sheen_ab.py -- --repo <repo> [--key greener]

WHY THIS EXISTS AND WHY IT IS NOT A FOURTH GO AT THE HUE DIAL.
The 23:58 ART row handed this lane the side-view leaf that goes near-white and
reads as a cream-painted board, and said the remedy is in the material or the
paint, not in the grade. The view-transform A/B had just killed the grade route
on numbers, and the same run established WHERE the fault lives: the pass-10
vertex paint costs 0.222 of body saturation in the side view, seven times its
cost on the front, and it reverses the sign of the margin against the matte-oak
control. The geometry is not what goes cream. THE BAND IS.

THE PREVIOUS RUN THEN FRAMED IT AS A BINARY AND REFUSED TO SETTLE IT - paint ON
(body_sat collapses) against paint OFF (hilite_desat regresses below oak, the
pass-5 state the whole history was escaping). THAT BINARY IS FALSE AND THAT IS
THIS RUN'S FINDING TO TEST. The band is not a switch; its COLOUR is a parameter,
and the shipped value is the one thing in the ramp nobody has ever measured an
alternative for.

WHAT IS WRONG WITH THE SHIPPED VALUE, STATED AS PHYSICS AND NOT AS TASTE.
COPPER_SHEEN is (1.000, 0.880, 0.820): authored saturation 0.180. The leaf body
is (1.000, 0.520, 0.235): authored saturation 0.765. So the band drives 86% of
the way from a saturation of 0.765 to a saturation of 0.180 - it is very nearly
a chalk wash, and the file's own comment beside it says a chalk-white streak is
a different lie. BUT A METAL'S HIGHLIGHT IS NOT WHITE. It carries the LIGHT's
colour times the METAL's own reflectance, and copper's reflectance is strongly
coloured - this repo already measures it, in _metal_read.CTRL['copper'],
(0.955, 0.637, 0.538), authored saturation 0.437. A dielectric's highlight runs
to white; a conductor's runs to its own tint. The leaves are being painted with
a dielectric's highlight, which is the same class of error as the metallic dial:
a number borrowed from the wrong physics.

SO THE CANDIDATES ARE NOT TASTE STEPS. They walk the band from the shipped
near-white to copper's own measured reflectance, and the one that matters is
`cu`, which is that reflectance and nothing else - no number of mine in it.

ONE THING CHANGES AND ONLY ONE. SHEEN_MAX (0.86), SHEEN_LO/HI (0.58/0.80),
SHADE_FLOOR (0.42), COPPER_BODY, COPPER_DEEP, the material, the rig, the camera,
the lights and the view transform are IDENTICAL across all four arms. The
shipped arm is arm 1 and must reproduce the pass-10 numbers or this instrument
is not measuring what it says.

THE MASK IS THE VIEWER'S QUESTION, NOT THE MESH'S. Taken exactly as
_metal_read.py takes it: render the body with the copper present and again with
ONLY the copper removed, under TWO light positions, and keep the pixels that
moved in both. This lane has shipped a number that answered a different question
from the sentence beside it (a group rendered ALONE, labelled as visibility), and
a mask of the leaves alone would measure how BIG they are, not what is seen.

IT GOES RED, AND IT GOES RED ON ITS AUTHOR:
  - a visible mask under 400 px is a FAILED render, not a small part
  - TWO ARMS THAT PRODUCE THE SAME VERTEX COLOURS ARE A NO-OP, and a sweep whose
    arms do not differ reads green while measuring one thing four times. The
    vertex colours are hashed per arm and an identical pair is an ERROR.
  - the paint is proved to have REACHED the mesh (merge_objs' own count) before
    any number is believed
  - THE CONTROL IS PROVED PAINT-INDEPENDENT rather than assumed: ctrl_flat is
    measured under the first AND the last arm and the two must agree. The whole
    comparison rests on the control not moving, and that was an assumption in
    the A/B that nobody tested.
  - every tile of the look sheet must have opaque pixels AND a clear border: a
    clipped icon is not a blank one and the blank check cannot see it.

WHAT THIS DOES NOT DO. It changes no default and ships no material: it writes
numbers and one picture. The band colour is minibosses.COPPER_SHEEN and is
patched in this process only.
"""
import os
import sys
import math
import json
import hashlib
import argparse

import bpy
import numpy as np
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordlib as L          # noqa: E402
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402

RES = (520, 700)
TILE = (420, 560)
VIEWS = (("front", 0.0, 2.0), ("side", 90.0, 2.0), ("back", 180.0, 2.0))
LIGHT_DELTA = 28.0

# THE FOUR ARMS. `ship` is today's bytes. `cu` is _metal_read.CTRL['copper']
# normalised so its brightest channel is 1.0, i.e. copper's own measured
# reflectance used as the highlight colour - the physically right value and the
# only arm with no number of mine in it. `warm` and `pale` bracket it so the
# answer is a curve and not a single point, and so a monotone response can be
# told apart from a lucky hit.
_CU = (0.955, 0.637, 0.538)
_CU_N = tuple(c / max(_CU) for c in _CU)              # (1.000, 0.667, 0.563)
ARMS = (
    ("ship", (1.000, 0.880, 0.820)),                  # authored sat 0.180
    ("pale", (1.000, 0.800, 0.715)),                  # authored sat 0.285
    ("warm", (1.000, 0.735, 0.640)),                  # authored sat 0.360
    ("cu",   _CU_N),                                  # authored sat 0.437
)
# the two controls this run needs. The physics copper and the matte oak come
# from _metal_read verbatim; `flat` is the shipped material with the paint OFF,
# which is the fair comparison for a painted surface and the arm-independent
# reference every margin below is taken against.
CTRL = {
    "timber": ((0.330, 0.200, 0.105), 0.72, 0.00, None),
    "flat":   ((1.000, 0.520, 0.235), 0.44, 0.06, 0.92),
}


def _clear():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)


def _mats(key):
    """THE SHIPPING materials, exactly as _metal_read and _trade_read build
    them. A body measured through a different material table is a different
    body."""
    title, height, tint, aura, theme, idea, wear, line = M.CANON[key]
    body = tuple((c * 0.80) * 0.80 + a * 0.20 for c, a in zip(tint, aura))
    dull = 1.0 - 0.45 * wear
    body = tuple(c * dull + 0.010 * wear for c in body)
    rough = 0.34 + 0.40 * wear
    metal = 0.55 * (1.0 - wear) ** 1.4
    mats = {
        'body': L.mat_solid(key + "_sb", body, rough, metal),
        'dark': L.mat_solid(key + "_sd", tuple(c * 0.16 + 0.012 for c in body), 0.74, 0.04),
        'bone': L.mat_solid(key + "_sn", tuple((0.30 + c * 0.55) * dull for c in tint),
                            rough * 0.9, 0.02),
        'glow': L.mat_glow(key + "_sg", tuple(min(1.0, c / max(aura)) for c in aura), 3.2),
    }
    return M.apply_overrides(key, mats)


def _sat(a):
    mx = a[..., 0:3].max(axis=-1)
    mn = a[..., 0:3].min(axis=-1)
    return np.where(mx > 1e-6, (mx - mn) / np.maximum(mx, 1e-6), 0.0)


def _lum(a):
    return 0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]


def _desat(lum, sat, mask):
    """HIGHLIGHT DESATURATION, _metal_read's axis, verbatim: how much whiter the
    bright end is than the body. NOTE WHAT IT IS AND IS NOT HERE. On a
    vertex-painted span _metal_read itself refuses this as a pass - a painted
    stripe satisfies it by construction - so it is carried in this run as the
    number that must not COLLAPSE, not as a number that can pass."""
    l, s_ = lum[mask], sat[mask]
    if l.size < 400:
        return None
    dk = l <= np.percentile(l, 50.0)
    br = l >= np.percentile(l, 95.0)
    if dk.sum() < 50 or br.sum() < 50:
        return None
    return float(s_[dk].mean() - s_[br].mean())


def _body_sat(sat, lum, mask):
    """Median saturation of the 25th-75th luminance band - whether the BODY of
    the surface still carries the material's colour. _metal_read verbatim."""
    l, s_ = lum[mask], sat[mask]
    if l.size < 400:
        return None
    lo, hi = np.percentile(l, 25.0), np.percentile(l, 75.0)
    band = (l >= lo) & (l <= hi)
    if band.sum() < 50:
        return None
    return float(np.median(s_[band]))


def _cream(sat, lum, mask):
    """THE FAULT, SAID AS A NUMBER, AND IT IS THE ONE NUMBER HERE THAT ASKS THE
    VIEWER'S QUESTION. The complaint is not "saturation is low on a percentile
    band" - it is "that sheet looks like a cream-painted board". A cream-painted
    board is pixels that are BRIGHT AND COLOURLESS AT ONCE. So: the share of
    visible copper pixels above the median luminance whose saturation is under
    0.25. Neither half alone is the fault - a dark grey pixel is shadow, and a
    bright saturated pixel is a copper highlight doing its job.

    0.25 is not tuned to make anything pass and it is stated so it can be
    checked: the matte-oak control's own body sits at 0.47-0.55 and the copper's
    at 0.29, so 0.25 is BELOW every surface in this test's vocabulary. A pixel
    under it is not a dull copper, it is a colourless one."""
    l, s_ = lum[mask], sat[mask]
    if l.size < 400:
        return None
    med = float(np.median(l))
    hi = l > med
    if hi.sum() < 50:
        return None
    return float((s_[hi] < 0.25).mean())


def _moved(a, b):
    return ((np.abs(a[..., 3] - b[..., 3]) > 0.02) |
            (np.abs(a[..., 0:3] - b[..., 0:3]).max(axis=-1) > 0.02))


def _authored_sat(rgb):
    mx = max(rgb)
    return float((mx - min(rgb)) / mx) if mx > 1e-6 else 0.0


def _rig(mn, mx, res, ortho_k):
    scene = bpy.context.scene
    G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    ctr = Vector(((mn.x + mx.x) / 2.0, (mn.y + mx.y) / 2.0, (mn.z + mx.z) / 2.0))
    rad = max(1e-3, max(mx.x - mn.x, mx.y - mn.y, mx.z - mn.z))
    d = rad * 4.0
    cam = bpy.data.cameras.new("sa_cam")
    cam.type = 'ORTHO'
    cam.ortho_scale = rad * ortho_k
    cam.clip_start = max(0.01, d - rad * 3.0)
    cam.clip_end = d + rad * 3.0
    ob = bpy.data.objects.new("sa_cam", cam)
    scene.collection.objects.link(ob)
    scene.camera = ob
    lights = []
    for ang, energy in ((40.0, 3.4), (-120.0, 1.5)):
        li = bpy.data.lights.new("sa_l", 'SUN')
        li.energy = energy
        lo = bpy.data.objects.new("sa_l", li)
        scene.collection.objects.link(lo)
        lo.rotation_euler = (math.radians(55.0), 0.0, math.radians(ang))
        lights.append((lo, ang))
    return ob, ctr, d, lights


def _swing(lights, delta):
    for lo, base in lights:
        lo.rotation_euler = (math.radians(55.0), 0.0, math.radians(base + delta))
    bpy.context.view_layer.update()


def _place(camob, ctr, d, yaw_deg, pitch_deg):
    a = math.radians(yaw_deg)
    p = math.radians(pitch_deg)
    camob.location = (ctr.x + d * math.sin(a) * math.cos(p),
                      ctr.y - d * math.cos(a) * math.cos(p),
                      ctr.z + d * math.sin(p))
    camob.rotation_euler = (math.radians(90.0 - pitch_deg), 0.0, a)
    bpy.context.view_layer.update()


def _shoot(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return G.read_png(path)


def _drop_meshes():
    for ob in list(bpy.data.objects):
        if ob.type == 'MESH':
            bpy.data.objects.remove(ob, do_unlink=True)


# *** THESE TWO ARE MODULE-LEVEL ON PURPOSE. _sheen_grid_ab.py IMPORTS THEM
# *** RATHER THAN KEEPING ITS OWN COPY: two readers in this tree each kept a
# *** private copy of the same statistic and the copies drifted.
def _scaled_free(P, items, sfx, mm, k, key):
    obs = M.merge_objs(key, items, mm, suffix=sfx, vcols=getattr(P, "vcols", None))
    for ob in obs:
        ob.scale = (k, k, k)
        ob.location = (ob.location.x * k, ob.location.y * k, ob.location.z * k)
    bpy.context.view_layer.update()
    return obs


def _measure_free(P, tgt, mm, lights, k, key, tmp, tag):
    """body_sat / hilite_desat / cream_share over the pixels a viewer can SEE of
    the copper: the body rendered WITH the span and again with ONLY the span
    removed, under both light positions, keeping what moved in both. A mask of
    the leaves alone would measure how BIG they are, not what is seen."""
    drop = set(tgt)
    cut_items = [it for j, it in enumerate(P.items) if j not in drop]
    per = []
    for di, delta in enumerate((0.0, LIGHT_DELTA)):
        _swing(lights, delta)
        _drop_meshes()
        _scaled_free(P, P.items, "%s_f%d" % (tag, di), mm, k, key)
        a_full = _shoot(os.path.join(tmp, "%s_full_%d.png" % (tag, di)))
        _drop_meshes()
        _scaled_free(P, cut_items, "%s_c%d" % (tag, di), mm, k, key)
        a_cut = _shoot(os.path.join(tmp, "%s_cut_%d.png" % (tag, di)))
        per.append((a_full, _moved(a_full, a_cut)))
    (a0, m0), (a1, m1) = per
    vis = m0 & m1
    npx = int(vis.sum())
    if npx < 400:
        return None, npx
    s0, l0 = _sat(a0), _lum(a0)
    return {"mask_px": npx,
            "median_lum": round(float(np.percentile(l0[vis], 50.0)), 4),
            "body_sat": round(_body_sat(s0, l0, vis), 4),
            "hilite_desat": round(_desat(l0, s0, vis), 4),
            "cream_share": round(_cream(s0, l0, vis), 4)}, npx


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--key", default="greener")
    ap.add_argument("--span", default="plates")
    ap.add_argument("--slot", default="bone")
    args = ap.parse_args(argv)
    key, span, slot = args.key, args.span, args.slot
    out = os.path.join(args.repo, "renders", "art", "minibosses")
    tmp = os.path.join(out, "_sheen_ab_tmp")
    os.makedirs(tmp, exist_ok=True)

    rep = {"ok": True, "errors": [], "key": key, "span": span, "slot": slot,
           "shipped_sheen": list(M.COPPER_SHEEN),
           "fixed": {"SHEEN_MAX": M.SHEEN_MAX,
                     "SHEEN_LO": M.SHEEN_LO, "SHEEN_HI": M.SHEEN_HI,
                     "SHADE_FLOOR": M.SHADE_FLOOR,
                     "COPPER_BODY": list(M.COPPER_BODY),
                     "COPPER_DEEP": list(M.COPPER_DEEP)},
           "arms": {}, "controls": {}, "vcol_hash": {}, "look": {}}

    orig_sheen = tuple(M.COPPER_SHEEN)
    # SLOT_RGB is filled by merge_objs, not by the builder, so it is read AFTER
    # the probe merge below and not here. Reading it now returns an empty table
    # and every hue_retention in the report would be measured against white -
    # a silent 1.0 denominator rather than an error, which is exactly the kind
    # of quietly-wrong number this lane keeps catching.
    for nm, rgb in ARMS:
        rep["arms"][nm] = {"sheen_rgb": [round(c, 4) for c in rgb],
                           "sheen_authored_sat": round(_authored_sat(rgb), 4),
                           "by_view": {}}

    # ---------------------------------------------------------- BUILD EACH ARM
    # The builder is called ONCE PER ARM with COPPER_SHEEN patched, so the band
    # is recomputed inside _leaf_vcol at build time. Hash the painted colours so
    # two arms that come out identical are an ERROR and not a quiet duplicate.
    builds = {}
    for nm, rgb in ARMS:
        M.COPPER_SHEEN = tuple(rgb)
        _clear()
        P = M.BUILDERS[key]()
        if span not in (getattr(P, "spans", {}) or {}):
            rep["ok"] = False
            rep["errors"].append("%s: span %r not exposed - RED ON EMPTY" % (key, span))
            print("SHEENAB " + json.dumps(rep))
            return
        i0, i1 = P.spans[span]
        tgt = [j for j in range(i0, i1) if P.items[j][2] == slot]
        if not tgt:
            rep["ok"] = False
            rep["errors"].append("%s: span %r slot %r is EMPTY - RED ON EMPTY"
                                 % (key, span, slot))
            print("SHEENAB " + json.dumps(rep))
            return
        painted = [P.vcols.get(id(P.items[j])) for j in tgt]
        if any(p is None for p in painted):
            rep["ok"] = False
            rep["errors"].append("arm %s: %d of %d measured items carry NO vertex "
                                 "colour - the paint never reached the build"
                                 % (nm, sum(1 for p in painted if p is None), len(tgt)))
            print("SHEENAB " + json.dumps(rep))
            return
        blob = ";".join(",".join("%.6f" % c for v in p for c in v) for p in painted)
        h = hashlib.sha256(blob.encode()).hexdigest()[:16]
        rep["vcol_hash"][nm] = h
        rep["arms"][nm]["painted_items"] = len(tgt)
        rep["arms"][nm]["painted_verts"] = sum(len(p) for p in painted)
        # the mean of the painted colours, for a human-readable check that the
        # arm moved in the direction its name claims
        allc = np.array([c for p in painted for c in p], dtype=np.float64)
        rep["arms"][nm]["vcol_mean_rgb"] = [round(float(x), 4) for x in allc.mean(axis=0)]
        rep["arms"][nm]["vcol_mean_sat"] = round(
            float(np.median((allc.max(axis=1) - allc.min(axis=1))
                            / np.maximum(allc.max(axis=1), 1e-6))), 4)
        builds[nm] = (P, tgt)
    M.COPPER_SHEEN = orig_sheen

    seen = {}
    for nm in rep["vcol_hash"]:
        h = rep["vcol_hash"][nm]
        if h in seen:
            rep["ok"] = False
            rep["errors"].append("arms %s and %s produced IDENTICAL vertex colours "
                                 "(%s) - this sweep would measure one thing twice "
                                 "and read green. NO-OP ARM." % (seen[h], nm, h))
        seen[h] = nm
    if not rep["ok"]:
        print("SHEENAB " + json.dumps(rep))
        return

    # ---------------------------------------------------------------- MEASURE
    mats = _mats(key)
    height = M.CANON[key][1]

    def _scaled(P, items, sfx, mm, k):
        return _scaled_free(P, items, sfx, mm, k, key)

    def _measure(P, tgt, mm, camob, ctr, d, lights, yaw, pitch, k, tag):
        return _measure_free(P, tgt, mm, lights, k, key, tmp, tag)

    # one rig, built off the SHIPPED arm's bounds, reused for every arm and
    # control so no number moves because the camera moved.
    P0, tgt0 = builds["ship"]
    _clear()
    probe = M.merge_objs(key, P0.items, mats, suffix="probe",
                         vcols=getattr(P0, "vcols", None))
    mn, mx, _ = G.world_bounds(probe)
    cur = mx.z - mn.z
    k = height / cur if cur > 1e-6 else 1.0
    SPAN_RGB = M.SLOT_RGB.get((key, slot))
    if SPAN_RGB is None:
        rep["ok"] = False
        rep["errors"].append("SLOT_RGB has no (%s,%s) row after the probe merge - "
                             "the authored colour is unknown, so hue_retention "
                             "would be measured against white. RED, not 1.0."
                             % (key, slot))
        print("SHEENAB " + json.dumps(rep))
        return
    rep["span_authored_rgb"] = [round(c, 4) for c in SPAN_RGB]
    rep["authored_sat"] = round(_authored_sat(SPAN_RGB), 4)
    _drop_meshes()
    full = _scaled(P0, P0.items, "rig", mats, k)
    got = next((int(ob.get("vcol_items", 0)) for ob in full
                if ob.name.endswith("_%s_rig" % slot)), 0)
    rep["vcol_items_painted"] = got
    if got != len(tgt0):
        rep["ok"] = False
        rep["errors"].append("slot %r is vertex-driven but %d of %d items carried "
                             "declared colours - the paint did NOT reach the mesh"
                             % (slot, got, len(tgt0)))
        print("SHEENAB " + json.dumps(rep))
        return
    mn, mx, _ = G.world_bounds(full)
    camob, ctr, d, lights = _rig(mn, mx, RES, 1.34)
    _drop_meshes()

    for vname, yaw, pitch in VIEWS:
        _place(camob, ctr, d, yaw, pitch)
        for nm, _rgb in ARMS:
            P, tgt = builds[nm]
            cell, npx = _measure(P, tgt, mats, camob, ctr, d, lights, yaw, pitch,
                                 k, "%s_%s" % (nm, vname))
            if cell is None:
                rep["ok"] = False
                rep["errors"].append("%s/%s: visible mask %d px - FAILED RENDER, "
                                     "not a small part" % (nm, vname, npx))
                continue
            cell["hue_retention"] = (round(cell["body_sat"] / rep["authored_sat"], 4)
                                     if rep["authored_sat"] > 1e-6 else None)
            rep["arms"][nm]["by_view"][vname] = cell

        # THE CONTROLS. Measured on the SHIPPED arm's build with the slot's
        # material swapped, which is how _metal_read does it - and `flat` is
        # measured a SECOND time on the `cu` arm to PROVE it is paint-blind.
        for cn, (rgb, rough, metal, spec) in CTRL.items():
            mm = dict(mats)
            mm[slot] = L.mat_solid("%s_c_%s" % (key, cn), rgb, rough, metal, spec)
            cell, npx = _measure(P0, tgt0, mm, camob, ctr, d, lights, yaw, pitch,
                                 k, "ctrl_%s_%s" % (cn, vname))
            if cell is None:
                rep["ok"] = False
                rep["errors"].append("ctrl_%s/%s: visible mask %d px - FAILED RENDER"
                                     % (cn, vname, npx))
                continue
            rep["controls"].setdefault(cn, {})[vname] = cell
        Pc, tgc = builds["cu"]
        mmf = dict(mats)
        rgb, rough, metal, spec = CTRL["flat"]
        mmf[slot] = L.mat_solid("%s_c_flat2" % key, rgb, rough, metal, spec)
        cell, npx = _measure(Pc, tgc, mmf, camob, ctr, d, lights, yaw, pitch, k,
                             "ctrl_flat2_%s" % vname)
        if cell is None:
            rep["ok"] = False
            rep["errors"].append("ctrl_flat(on cu arm)/%s: mask %d px - FAILED RENDER"
                                 % (vname, npx))
        else:
            base = rep["controls"].get("flat", {}).get(vname)
            rep.setdefault("ctrl_flat_paint_blind", {})[vname] = {
                "on_ship_arm": base, "on_cu_arm": cell}
            if base is not None:
                dbs = abs(base["body_sat"] - cell["body_sat"])
                if dbs > 0.01:
                    rep["ok"] = False
                    rep["errors"].append(
                        "ctrl_flat MOVED between arms on %s (body_sat %.4f vs %.4f, "
                        "d=%.4f). The control is supposed to be paint-blind and every "
                        "margin in this table is taken against it. IT IS NOT. The "
                        "table below cannot be read as a comparison."
                        % (vname, base["body_sat"], cell["body_sat"], dbs))

    # ------------------------------------------------------------- THE PICTURE
    # 4 arms x 3 views, same rig, wider framing so the border assert means
    # something, and I look at it.
    _clear()
    grid = {}
    for nm, rgb in ARMS:
        P, _tgt = builds[nm]
        _drop_meshes()
        obs = _scaled(P, P.items, "look_%s" % nm, mats, k)
        if nm == "ship":
            lmn, lmx, _ = G.world_bounds(obs)
            lcam, lctr, ld, _ll = _rig(lmn, lmx, TILE, 1.50)
        for vname, yaw, pitch in VIEWS:
            _place(lcam, lctr, ld, yaw, pitch)
            path = os.path.join(tmp, "look_%s_%s.png" % (nm, vname))
            img = _shoot(path)
            al = img[..., 3]
            opaque = int((al > 0.02).sum())
            b = 3
            border = float(max(al[:b, :].max(), al[-b:, :].max(),
                               al[:, :b].max(), al[:, -b:].max()))
            ck = "%s/%s" % (nm, vname)
            rep["look"][ck] = {"opaque_px": opaque, "border_alpha": round(border, 4)}
            if opaque < 2000:
                rep["ok"] = False
                rep["errors"].append("%s: %d opaque px - BLANK OR NEAR-BLANK" % (ck, opaque))
            if border > 0.02:
                rep["ok"] = False
                rep["errors"].append("%s: border alpha %.3f - BODY CLIPPED BY THE "
                                     "FRAME, which a blank check cannot see" % (ck, border))
            grid[(nm, vname)] = img
        _drop_meshes()

    if grid:
        h, w = TILE[1], TILE[0]
        sheet = np.zeros((h * len(ARMS), w * len(VIEWS), 4), dtype=np.float32)
        sheet[..., 0:3] = 0.08
        sheet[..., 3] = 1.0
        for ri, (nm, _rgb) in enumerate(ARMS):
            for ci, (vname, _y, _p) in enumerate(VIEWS):
                img = grid.get((nm, vname))
                if img is None:
                    continue
                al = img[..., 3:4]
                sheet[ri * h:(ri + 1) * h, ci * w:(ci + 1) * w, 0:3] = (
                    img[..., 0:3] * al + 0.08 * (1.0 - al))
        for ri in range(1, len(ARMS)):
            sheet[ri * h - 1:ri * h + 1, :, 0:3] = 0.55
        for ci in range(1, len(VIEWS)):
            sheet[:, ci * w - 1:ci * w + 1, 0:3] = 0.55
        spath = os.path.join(out, "_sheen_ab_sheet.png")
        G.write_png(spath, sheet)
        rep["sheet"] = spath
        rep["sheet_layout"] = ("rows top->bottom: %s ; cols left->right: %s"
                               % (", ".join(n for n, _ in ARMS),
                                  ", ".join(v[0] for v in VIEWS)))
    else:
        rep["ok"] = False
        rep["errors"].append("no look tiles rendered - red on empty")

    with open(os.path.join(out, "_sheen_ab.json"), "w") as f:
        json.dump(rep, f, indent=1)
    _clear()
    print("SHEENAB " + json.dumps(rep))


# GUARDED so this file can be IMPORTED as the metric library by a second sweep
# instead of a second sweep copying the four metric functions. A copied metric
# is how two readers in this tree drifted apart before.
if __name__ == "__main__":
    main()
