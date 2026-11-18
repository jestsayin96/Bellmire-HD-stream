"""_metal_read - DOES THIS MATERIAL READ AS THE METAL IT IS, OR AS TIMBER?

  blender -b -noaudio -P tools/art/_metal_read.py -- --repo <repo> \
      --key greener --span plates --views front,side

WHY THIS EXISTS, AND WHY IT IS NOT ANOTHER COLOUR DIAL.
The Greener's copper leaves are the OLDEST OPEN FAULT on this lane's list. They
have had three separate goes - pass 2 change E, pass 4 change J, pass 5 - and
every one of them moved the SAME THREE DIALS: base colour, roughness, metallic.
The written record of those passes is the evidence that the dials were the
wrong question:
    E  (0.735, 0.355, 0.135) rough 0.34 metal 0.62 -> "came back BROWN"
    J  (0.905, 0.470, 0.205) rough 0.30            -> "still read as PLYWOOD"
    5  (1.000, 0.520, 0.235) rough 0.13 metal 0.52 -> still reads as timber
Three monotone steps along hue and brightness did not change the NAME a viewer
gives the surface. That is not a sign the steps were too small. It is a sign
the thing that makes metal look like metal is not in those three dials at all.

WHAT ACTUALLY TELLS A VIEWER A SURFACE IS METAL is the behaviour of its
HIGHLIGHT: bright, tight, far above the body of the surface, and it MOVES when
the light moves. Timber has a broad dim sheen that sits still. Hue is nearly
irrelevant - polished copper and oiled oak occupy the same hue band, which is
exactly why three hue steps could not separate them.

So this measures highlight behaviour, and it measures it the only honest way:
  1. THE MASK IS WHAT A VIEWER CAN SEE, NOT WHAT IS THERE. Render the creature
     through one fixed camera with the span present and again with it removed;
     the leaf pixels are the ones that MOVED. This lane has already shipped one
     number that answered a different question than the sentence beside it
     (`head_glow_px: 156` next to "the head has no face at all", because the
     group was rendered ALONE). A mask of the leaves alone would again measure
     how BIG they are, not what a viewer sees of them.
  2. THE BAR IS NOT MINE. Two CONTROLS are rendered through the same camera on
     the SAME GEOMETRY with only the material swapped - a matte oak and a real
     polished copper. Each metric is then placed on the timber->copper axis:
     t = (shipped - timber) / (copper - timber). PASS is t >= --bar on every
     metric, i.e. the surface reads closer to copper than to timber. Because
     the controls ride the same geometry, changing the GEOMETRY later moves the
     axis too and the comparison stays fair.

*** THE FIRST AXIS THIS FILE SHIPPED WAS WRONG AND THE CONTROLS ARE WHAT PROVED
*** IT. I am leaving the record in rather than quietly deleting it. ***
The first version scored the leaves on "closer to a physically-correct copper
than to oak" over spec peak, spec range and highlight mobility. The controls
came back and overturned it (greener/side, baseline):
    ctrl_timber  spec_peak 0.4865  spec_range 0.3958  mobility 0.5505
    ctrl_copper  spec_peak 0.2075  spec_range 0.0233  mobility 0.0064
REAL POLISHED COPPER IS DARKER, FLATTER AND ALL BUT IMMOBILE IN THIS RIG, and
oak is the bright lively one. That is not a broken control, it is the physics:
a fully metallic surface has NO diffuse term, and this rig gives it nothing to
reflect - lordgen.render_views sets the world to (0.045, 0.05, 0.065) at
strength 1.0 and film_transparent, so the only thing in the environment is two
SUN lamps with a ~0.5 deg angular size. A mirror in an empty room is black.
SO THE AXIS WOULD HAVE BEEN MET BY MAKING THE LEAVES DARKER AND FLATTER, which
is worse, and a number that rewards the wrong change is worse than no number.
IT ALSO EXPLAINS ALL THREE FAILED PASSES AT ONCE, which is why I trust it: every
step E -> J -> 5 pushed toward "more metal", every step took the surface nearer
a dead plate, and each time the lane compensated by brightening the base colour
- and a bright hue carried by a diffuse term on a smooth sheet is PAINTED WOOD.
The dials were never going to get there. THE REGISTER-WIDE LESSON: in this rig
METALLIC IS NOT A DIAL THAT BUYS A METAL LOOK, it is one that spends it.

WHAT IS MEASURED INSTEAD: SPECKLE. With nothing to reflect, the only thing left
that separates metal from timber is HIGH-FREQUENCY LUMINANCE STRUCTURE - a
hammered sheet is a field of small facet-bright and facet-dark cells, a plank is
smooth and even. And the bar is NOT mine and NOT a physics ideal: it is measured
off the CC0 KayKit dungeon weapons already in this repo, under our own lights.
Those are third-party artist-authored metals that demonstrably read as metal, so
"measures like the metal on a shipped sword" is a target nobody on this lane
wrote. The axis is timber -> those references.

IT GOES RED, IT GOES RED ON EMPTY, AND IT GOES RED ON ITS OWN AUTHOR:
  - a visible-span mask under 400 px is a FAILED RENDER, not a small part
  - a span that is empty, or absent from the builder, is an ERROR, never 0.000
  - IF THE TWO CONTROLS DO NOT SEPARATE on a metric, that metric is BLIND and
    is reported as an error, not as a score. An instrument that cannot tell oak
    from copper cannot be used to tell me the leaves are copper. This is the
    rule this lane wrote for itself after computing a ratio over zero pairs and
    calling it green.
  - the shipped material is scored, not asserted. Run it on the body as it
    stands and it must be able to FAIL.
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

RES = (520, 700)

# THE TWO CONTROLS. Neither is tuned to make anything pass.
#   TIMBER is the failure mode the fault names - a matte brown board. It is
#   deliberately the SAME HUE FAMILY as copper, because if the controls differed
#   in hue the axis would measure hue and we are back to the dials that failed.
#   COPPER is real polished copper: the measured reflectance of Cu as a base
#   colour, fully metallic, mill-finish roughness.
CTRL = {
    "timber": ((0.330, 0.200, 0.105), 0.72, 0.00),
    "copper": ((0.955, 0.637, 0.538), 0.18, 1.00),
    # *** THE THIRD CONTROL IS NOT A PHYSICS CONTROL. IT IS THE SHIPPED
    # *** MATERIAL WITH THE PASS-10 VERTEX PAINT TAKEN OFF - i.e. the pass-9
    # *** state - AND IT IS HERE BECAUSE WITHOUT IT THE VIEW-TRANSFORM A/B
    # *** COMPARES A PAINTED SURFACE AGAINST TWO UNPAINTED ONES.
    # The two controls above are built with mat_solid, so they carry no vertex
    # colour; the shipped leaf does. Pass 10's paint lays a near-white sheen
    # band into the brightest vertices, which DRAGS body_sat DOWN, so every
    # "shipped vs timber" saturation gap is measured with the shipped side
    # handicapped by an amount nobody has quantified. On a metric about
    # saturation that is not a detail. This row is the shipped override
    # (1.000, 0.520, 0.235) rough 0.44 metal 0.06 spec 0.92 read off
    # minibosses.OVERRIDE['greener']['bone'], minus the fifth element - so it
    # isolates WHAT THE TRANSFORM DOES TO THE MATERIAL from what the paint does.
    "flat": ((1.000, 0.520, 0.235), 0.44, 0.06),
}
# the dielectric specular level for the "flat" control only, so it is the
# shipped material and not a lookalike. None for the two physics controls,
# which must stay exactly as they were measured on every earlier pass.
CTRL_SPEC = {"flat": 0.92}
# how far the light rig is swung for the mobility read. Small enough that the
# geometry presents the same faces, large enough that a specular lobe leaves
# the pixel it was in.
LIGHT_DELTA = 28.0
# a metric whose two controls land closer together than this is BLIND - the
# separation is smaller than the quantisation and shading noise of the render.
SEPARATION_FLOOR = {"spec_peak": 0.04, "spec_range": 0.04, "mobility": 0.02,
                    "speckle": 0.05, "hilite_desat": 0.08}

# *** THE VIEW TRANSFORM IS AN ARGUMENT OF THIS INSTRUMENT AND NOTHING ELSE. ***
# The team lead's 22:58 row asked for a bounded A/B and said CHANGE NO DEFAULT.
# So this is deliberately NOT a change to lordgen.set_engine: that function is
# left exactly as it is, the register keeps rendering under Blender's default
# AgX, and the only thing that can select another transform is this flag on this
# reader. Nothing else in the tree reads VIEW_TRANSFORM.
# IT IS RECORDED IN THE REPORT AND VERIFIED BY READBACK. A number measured under
# a transform that silently failed to apply, labelled as that transform, is the
# exact fault class this lane has shipped twice (a group rendered alone labelled
# as visibility, a painted band labelled as reflection). So the requested name
# is asserted against what the scene actually holds afterwards, and a mismatch
# is an ERROR, never a fallback to the default with the label kept.
VIEW_TRANSFORM = None


def _mats(key):
    """The SHIPPING materials, as _trade_read and _colour_read build them."""
    title, height, tint, aura, theme, idea, wear, line = M.CANON[key]
    body = tuple((c * 0.80) * 0.80 + a * 0.20 for c, a in zip(tint, aura))
    dull = 1.0 - 0.45 * wear
    body = tuple(c * dull + 0.010 * wear for c in body)
    rough = 0.34 + 0.40 * wear
    metal = 0.55 * (1.0 - wear) ** 1.4
    mats = {
        'body': L.mat_solid(key + "_mb", body, rough, metal),
        'dark': L.mat_solid(key + "_md", tuple(c * 0.16 + 0.012 for c in body), 0.74, 0.04),
        'bone': L.mat_solid(key + "_mn", tuple((0.30 + c * 0.55) * dull for c in tint),
                            rough * 0.9, 0.02),
        'glow': L.mat_glow(key + "_mg", tuple(min(1.0, c / max(aura)) for c in aura), 3.2),
    }
    return M.apply_overrides(key, mats)


def _objs(key, items, mats, suffix, vcols=None):
    """Delegates to minibosses.merge_objs - THE one merge the shipping generator
    uses. This file used to carry its own identical copy, and so did two other
    readers; measuring a body through a different merge than the one that ships
    is the same fault class as measuring it through a different material table.
    `vcols` must be passed through from the builder or a vertex-painted slot is
    measured UNPAINTED, which would read as a fix that is not there."""
    return M.merge_objs(key, items, mats, suffix=suffix, vcols=vcols)


def _clear():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)


def _rig(mn, mx):
    """Camera and lights set ONCE from the whole creature. Returns the light
    objects too, because swinging them is the measurement."""
    scene = bpy.context.scene
    G.set_engine(scene)
    if VIEW_TRANSFORM:
        scene.view_settings.view_transform = VIEW_TRANSFORM
    scene.render.resolution_x, scene.render.resolution_y = RES
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    ctr = Vector(((mn.x + mx.x) / 2.0, (mn.y + mx.y) / 2.0, (mn.z + mx.z) / 2.0))
    rad = max(1e-3, max(mx.x - mn.x, mx.y - mn.y, mx.z - mn.z))
    cam_d = rad * 4.0
    cam = bpy.data.cameras.new("mr_cam")
    cam.type = 'ORTHO'
    cam.ortho_scale = rad * 1.34
    cam.clip_start = max(0.01, cam_d - rad * 3.0)
    cam.clip_end = cam_d + rad * 3.0
    ob = bpy.data.objects.new("mr_cam", cam)
    scene.collection.objects.link(ob)
    scene.camera = ob
    lights = []
    for ang, energy in ((40.0, 3.4), (-120.0, 1.5)):
        li = bpy.data.lights.new("mr_l", 'SUN')
        li.energy = energy
        lo = bpy.data.objects.new("mr_l", li)
        scene.collection.objects.link(lo)
        lo.rotation_euler = (math.radians(55.0), 0.0, math.radians(ang))
        lights.append((lo, ang))
    return ob, ctr, cam_d, lights


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


def _speckle(lum, mask, win=7, thr=0.05):
    """Share of masked pixels that depart from their own LOCAL median - the
    high-frequency structure a faceted metal has and a smooth board does not.
    Scale-free, so it compares across different geometry, which is what lets an
    outside reference set the bar."""
    try:
        from numpy.lib.stride_tricks import sliding_window_view as swv
    except Exception:
        return None
    pad = win // 2
    lp = np.pad(lum, pad, mode='edge')
    w = swv(lp, (win, win)).reshape(lum.shape[0], lum.shape[1], win * win)
    med = np.median(w, axis=-1)
    d = np.abs(lum - med)
    return float((d[mask] > thr).mean())


def _sat(a):
    """HSV saturation, per pixel."""
    mx = a[..., 0:3].max(axis=-1)
    mn = a[..., 0:3].min(axis=-1)
    return np.where(mx > 1e-6, (mx - mn) / np.maximum(mx, 1e-6), 0.0)


def _desat(lum, sat, mask):
    """HIGHLIGHT DESATURATION: how much whiter the bright end is than the body
    of the surface. This is physics, not taste - a specular reflection carries
    the LIGHT's colour, so a metal's highlight runs toward white while a painted
    or pigmented surface keeps its hue all the way up. Positive = the highlight
    desaturates = behaves like a reflection. Near zero or negative = the bright
    end is just more of the same paint, which is what a plank does."""
    l, s_ = lum[mask], sat[mask]
    if l.size < 400:
        return None
    dk = l <= np.percentile(l, 50.0)
    br = l >= np.percentile(l, 95.0)
    if dk.sum() < 50 or br.sum() < 50:
        return None
    return float(s_[dk].mean() - s_[br].mean())


def _body_sat(sat, lum, mask):
    """Median saturation of the surface's MID-TONES - the 25th-75th luminance
    band, so neither the baked highlight nor the deepest shadow can move it.
    This is the axis hilite_desat does not cover: whether the BODY of the
    surface still carries the material's colour at all."""
    l, s_ = lum[mask], sat[mask]
    if l.size < 400:
        return None
    lo, hi = np.percentile(l, 25.0), np.percentile(l, 75.0)
    band = (l >= lo) & (l <= hi)
    if band.sum() < 50:
        return None
    return float(np.median(s_[band]))


def _authored_sat(rgb):
    mx, mn = max(rgb), min(rgb)
    return float((mx - mn) / mx) if mx > 1e-6 else 0.0


def _lum(a):
    return 0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]


def _moved(a, b):
    return ((np.abs(a[..., 3] - b[..., 3]) > 0.02) |
            (np.abs(a[..., 0:3] - b[..., 0:3]).max(axis=-1) > 0.02))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--key", default="greener")
    ap.add_argument("--span", default="plates")
    ap.add_argument("--slot", default="bone")
    ap.add_argument("--views", default="front,side")
    ap.add_argument("--bar", type=float, default=0.50)
    ap.add_argument("--tag", default="")
    ap.add_argument("--view_transform", default="",
                    help="OCIO view transform for THIS READ ONLY (e.g. Standard, "
                         "'Khronos PBR Neutral'). Empty = whatever set_engine "
                         "leaves, i.e. Blender's default AgX. Changes no default.")
    ap.add_argument("--refs", default="",
                    help="comma-separated .glb paths, relative to --repo, whose "
                         "metal sets the bar. CC0 KayKit dungeon weapons.")
    args = ap.parse_args(argv)

    global VIEW_TRANSFORM
    key, span = args.key, args.span
    views = [v.strip() for v in args.views.split(",") if v.strip()]
    # THE TRANSFORM GOES IN THE EVIDENCE PATH. The first view-transform sweep
    # wrote all three runs to the same filenames, so by the time I went to LOOK
    # at the pictures the AgX and Standard frames had been overwritten by the
    # last run and only the numbers survived. A reader that keeps the number and
    # destroys the picture is the wrong way round on this lane - the picture is
    # the evidence and the number is the suspect.
    tmp = os.path.join(args.repo, "renders", "art", "minibosses", "_metal_tmp")
    if args.view_transform:
        tmp = os.path.join(tmp, args.view_transform.replace(" ", "_"))
    os.makedirs(tmp, exist_ok=True)
    rep = {"ok": True, "errors": [], "blind": [], "key": key, "span": span,
           "bar": args.bar, "light_delta": LIGHT_DELTA, "tag": args.tag,
           "by_view": {}}

    # THE TRANSFORM IS PROVED TO HAVE APPLIED BEFORE A SINGLE PIXEL IS READ.
    sc = bpy.context.scene
    rep["view_transform_default"] = sc.view_settings.view_transform
    rep["view_transform_requested"] = args.view_transform or None
    if args.view_transform:
        try:
            sc.view_settings.view_transform = args.view_transform
        except Exception as e:
            rep["ok"] = False
            rep["errors"].append(
                "view transform %r is not offered by this build's OCIO config "
                "(%s). RED, not a silent fall back to the default - a number "
                "measured under AgX and labelled Standard is worse than no "
                "number." % (args.view_transform, e))
            print("METALREAD " + json.dumps(rep))
            return
        got = sc.view_settings.view_transform
        if got != args.view_transform:
            rep["ok"] = False
            rep["errors"].append(
                "view transform asked for %r, scene reports %r after assignment "
                "- RED." % (args.view_transform, got))
            print("METALREAD " + json.dumps(rep))
            return
        VIEW_TRANSFORM = args.view_transform
    rep["view_transform_active"] = sc.view_settings.view_transform

    # ------------------------------------------------------------------
    # THE EXTERNAL BAR, MEASURED FIRST. Each reference .glb is imported alone
    # under THIS rig's own two suns and the same speckle statistic is taken
    # over its BRIGHT HALF - on a KayKit weapon the bright half is the blade
    # and head, the dark half the grip and leather. Measuring a lone object is
    # legitimate HERE and only here: the reference IS the whole object, nothing
    # occludes it, so there is no hidden-behind-the-body question to get wrong.
    # Said plainly as an approximation rather than claimed as a metal mask.
    refs = [r.strip() for r in args.refs.split(",") if r.strip()]
    if refs:
        vals, dvals, per = [], [], {}
        for rel in refs:
            path = rel if os.path.isabs(rel) else os.path.join(args.repo, rel)
            if not os.path.exists(path):
                rep["errors"].append("reference missing: %s" % rel)
                rep["ok"] = False
                continue
            _clear()
            before = set(bpy.data.objects)
            try:
                bpy.ops.import_scene.gltf(filepath=path)
            except Exception as e:
                rep["errors"].append("reference %s failed to import: %s" % (rel, e))
                rep["ok"] = False
                continue
            obs = [o for o in bpy.data.objects if o not in before and o.type == 'MESH']
            if not obs:
                rep["errors"].append("reference %s imported NO meshes - red on empty" % rel)
                rep["ok"] = False
                continue
            rmn, rmx, _ = G.world_bounds(obs)
            rcam, rctr, rd, rlights = _rig(rmn, rmx)
            _place(rcam, rctr, rd, 0.0, 2.0)
            _swing(rlights, 0.0)
            a = _shoot(os.path.join(tmp, "_ref_%s.png"
                                    % os.path.basename(rel).replace(".glb", "")))
            msk = a[..., 3] > 0.02
            n = int(msk.sum())
            if n < 400:
                rep["errors"].append("reference %s silhouette %d px - FAILED render, "
                                     "not a small sword" % (rel, n))
                rep["ok"] = False
                continue
            lum = _lum(a)
            bright = msk & (lum > float(np.median(lum[msk])))
            sp = _speckle(lum, bright)
            ds = _desat(lum, _sat(a), msk)
            if sp is None:
                rep["errors"].append("reference %s: speckle uncomputable" % rel)
                rep["ok"] = False
                continue
            per[os.path.basename(rel)] = {"mask_px": n, "bright_px": int(bright.sum()),
                                          "speckle": round(sp, 4),
                                          "hilite_desat": (None if ds is None
                                                           else round(ds, 4))}
            vals.append(sp)
            if ds is not None:
                dvals.append(ds)
            _clear()
        rep["reference"] = {"per_file": per,
                            "speckle": round(float(np.median(vals)), 4) if vals else None,
                            "hilite_desat": (round(float(np.median(dvals)), 4)
                                             if dvals else None),
                            "n": len(vals)}
    else:
        rep["errors"].append("NO --refs given: there is no bar, so nothing here can "
                             "pass. Red on empty by design.")
        rep["ok"] = False

    if key not in M.BUILDERS:
        rep["ok"] = False
        rep["errors"].append("%s: no builder" % key)
        print("METALREAD " + json.dumps(rep))
        return

    _clear()
    mats = _mats(key)
    P = M.BUILDERS[key]()
    spans = dict(getattr(P, "spans", {}) or {})
    if span not in spans:
        rep["ok"] = False
        rep["errors"].append("%s: span '%s' is not exposed by the builder - RED ON "
                             "EMPTY, not a 0.000 score" % (key, span))
        print("METALREAD " + json.dumps(rep))
        return
    i0, i1 = spans[span]
    if i1 <= i0:
        rep["ok"] = False
        rep["errors"].append("%s: span '%s' is EMPTY (%d,%d) - red on empty"
                             % (key, span, i0, i1))
        print("METALREAD " + json.dumps(rep))
        return

    # WHICH SLOT INSIDE THE SPAN. The first run of this instrument went RED on
    # its author here and it was right to: span 'plates' holds the copper
    # leaves ('bone') AND the dark rack that carries them ('dark'), so a whole-
    # span mask would have measured the rack's matte black as part of the
    # copper and a one-material swap would not have been a clean substitution.
    # The measured thing is the slot the COPPER is in; everything else in the
    # span stays in the picture, where it belongs.
    slot = args.slot
    slots = sorted({s for _, _, s in P.items[i0:i1]})
    rep["span_slots"] = slots
    if slot not in slots:
        rep["errors"].append("%s: span '%s' has no geometry in slot '%s' (it holds "
                             "%s) - RED ON EMPTY" % (key, span, slot, slots))
        rep["ok"] = False
        print("METALREAD " + json.dumps(rep))
        return
    tgt = [j for j in range(i0, i1) if P.items[j][2] == slot]
    rep["measured_items"] = len(tgt)
    if not tgt:
        rep["errors"].append("%s: no items in span '%s' slot '%s'" % (key, span, slot))
        rep["ok"] = False
        print("METALREAD " + json.dumps(rep))
        return

    # the colour the span's slot was AUTHORED with, for the hue-retention
    # diagnostic. Taken from the override row when there is one, because that
    # is what apply_overrides actually puts on the mesh.
    SPAN_RGB = M.SLOT_RGB.get((key, slot)) or (1.0, 1.0, 1.0)
    rep["span_authored_rgb"] = list(SPAN_RGB)

    height = M.CANON[key][1]
    probe = _objs(key, P.items, mats, "probe", getattr(P, "vcols", None))
    mn, mx, _ = G.world_bounds(probe)
    cur = mx.z - mn.z
    k = height / cur if cur > 1e-6 else 1.0
    for ob in probe:
        bpy.data.objects.remove(ob, do_unlink=True)

    def _scaled(items, sfx, mm):
        obs = _objs(key, items, mm, sfx, getattr(P, "vcols", None))
        for ob in obs:
            ob.scale = (k, k, k)
            ob.location = (ob.location.x * k, ob.location.y * k, ob.location.z * k)
        bpy.context.view_layer.update()
        return obs

    full = _scaled(P.items, "full", mats)
    # *** THE PAINT IS PROVED APPLIED BEFORE ANY NUMBER IS BELIEVED. ***
    # If the span's slot is vertex-driven, the merge records how many items
    # carried declared colours. A wrong key paints everything the fill colour
    # and the render comes back looking like the OLD body - which reads as
    # "the change did nothing" when the truth is "the change never happened".
    # This lane has already shipped one number that answered a different
    # question than the sentence beside it; this is the cheap guard against
    # doing it again.
    if slot in M.VCOL_SLOTS.get(key, set()):
        got = next((int(ob.get("vcol_items", 0)) for ob in full
                    if ob.name.endswith("_%s_full" % slot)), 0)
        rep["vcol_items_painted"] = got
        if got != len(tgt):
            rep["errors"].append(
                "%s: slot '%s' is vertex-driven but %d of %d items in the span "
                "carried declared colours - the paint did NOT reach the mesh, so "
                "every number below would be measuring the UNPAINTED body"
                % (key, slot, got, len(tgt)))
            rep["ok"] = False
            print("METALREAD " + json.dumps(rep))
            return
    mn, mx, _ = G.world_bounds(full)
    camob, ctr, d, lights = _rig(mn, mx)
    for ob in list(bpy.data.objects):
        if ob.type == 'MESH':
            bpy.data.objects.remove(ob, do_unlink=True)

    # the CUT drops ONLY the copper, keeping the rack and the rest of the body,
    # so the moved pixels are the copper a viewer can actually see.
    drop = set(tgt)
    cut_items = [it for j, it in enumerate(P.items) if j not in drop]

    # the three material variants: the shipped one, and the two controls, each
    # differing from the others in the span's slot ONLY.
    variants = {"shipped": None}
    variants.update({("ctrl_" + n): CTRL[n] for n in CTRL})

    for vname, yaw, pitch in (("front", 0.0, 2.0), ("side", 90.0, 2.0),
                              ("back", 180.0, 2.0)):
        if vname not in views:
            continue
        _place(camob, ctr, d, yaw, pitch)
        scores, raw = {}, {}
        for var, spec in variants.items():
            mm = dict(mats)
            if spec is not None:
                rgb, rough, metal = spec
                mm[slot] = L.mat_solid("%s_ctrl_%s" % (key, var), rgb, rough, metal,
                                       CTRL_SPEC.get(var.replace("ctrl_", "")))
            per_light = []
            for di, delta in enumerate((0.0, LIGHT_DELTA)):
                _swing(lights, delta)
                for ob in list(bpy.data.objects):
                    if ob.type == 'MESH':
                        bpy.data.objects.remove(ob, do_unlink=True)
                _scaled(P.items, "f%d" % di, mm)
                a_full = _shoot(os.path.join(tmp, "%s_%s_%s_%d_full.png"
                                             % (key, vname, var, di)))
                for ob in list(bpy.data.objects):
                    if ob.type == 'MESH':
                        bpy.data.objects.remove(ob, do_unlink=True)
                _scaled(cut_items, "c%d" % di, mm)
                a_cut = _shoot(os.path.join(tmp, "%s_%s_%s_%d_cut.png"
                                            % (key, vname, var, di)))
                per_light.append((a_full, _moved(a_full, a_cut)))
            (a0, m0), (a1, m1) = per_light
            vis = m0 & m1            # seen under BOTH light positions
            npx = int(vis.sum())
            if npx < 400:
                rep["errors"].append("%s/%s/%s: visible span mask %d px - a FAILED "
                                     "render, not a small part" % (key, vname, var, npx))
                rep["ok"] = False
                continue
            l0, l1 = _lum(a0)[vis], _lum(a1)[vis]
            peak = float(np.percentile(l0, 99.5))
            med = float(np.percentile(l0, 50.0))
            mob = float((np.abs(l0 - l1) > 0.06).mean())
            raw[var] = {"mask_px": npx,
                        "spec_peak": round(peak, 4),
                        "spec_range": round(peak - med, 4),
                        "median_lum": round(med, 4),
                        "mobility": round(mob, 4),
                        "speckle": _speckle(_lum(a0), vis),
                        "hilite_desat": _desat(_lum(a0), _sat(a0), vis),
                        "body_sat": _body_sat(_sat(a0), _lum(a0), vis)}
        cell = {"raw": raw, "scores": {}, "verdict": "FAIL"}
        # HUE RETENTION: how much of the colour the material was AUTHORED with
        # is still on screen. Added 18 Nov because the whole fault history of
        # this span turns out to sit downstream of the material: the register
        # renders under the AgX view transform (never set by its own rig - it
        # is Blender's default and lordgen.set_engine touches only the engine),
        # and AgX removes over half the saturation of a bright warm colour. A
        # flat patch of the shipped copper measures, through this rig's own two
        # suns: authored sat 0.765 -> Raw 0.744, Standard 0.463, AgX 0.335.
        # Shading keeps the hue; the DISPLAY TRANSFORM takes it. That is why
        # nine passes of hue/roughness/metallic could not move the read - every
        # dial they turned was upstream of the thing removing the evidence.
        if "shipped" in raw and raw["shipped"].get("body_sat") is not None:
            cell["authored_sat"] = round(_authored_sat(SPAN_RGB), 4)
            if cell["authored_sat"] > 1e-6:
                cell["hue_retention"] = round(
                    raw["shipped"]["body_sat"] / cell["authored_sat"], 4)
        if "shipped" in raw and "ctrl_timber" in raw:
            # THE AXIS IS hilite_desat AND THE OTHER THREE ARE DIAGNOSTICS ONLY.
            # spec_peak, spec_range, mobility and speckle were all tried as the
            # axis first and all four were ABANDONED ON EVIDENCE, not on taste:
            # on every one of them the outside references and/or the physics
            # control land on the SAME SIDE AS "darker and flatter", so passing
            # them would have rewarded a change that makes the sheet worse. They
            # are still measured and still printed, because the record of a
            # metric that pointed the wrong way is worth keeping.
            MET = "hilite_desat"
            t = raw["ctrl_timber"][MET]
            ref = rep.get("reference", {}).get(MET)
            if t is None or raw["shipped"][MET] is None:
                rep["errors"].append("%s/%s: speckle could not be computed (numpy "
                                     "metric uncomputable) - NOT a 0.0 score"
                                     % (key, vname))
                rep["ok"] = False
            elif ref is None:
                rep["errors"].append("%s/%s: NO EXTERNAL REFERENCE measured, so there "
                                     "is no bar - red on empty, not a pass" % (key, vname))
                rep["ok"] = False
            elif abs(ref - t) < SEPARATION_FLOOR[MET]:
                rep["blind"].append("%s/%s: %s is BLIND - oak %.4f and the KayKit "
                                    "metal %.4f do not separate (floor %.3f)"
                                    % (key, vname, MET, t, ref, SEPARATION_FLOOR[MET]))
                rep["ok"] = False
            else:
                sc = (raw["shipped"][MET] - t) / (ref - t)
                cell["scores"][MET] = round(float(sc), 3)
                ok_all = sc >= args.bar
                cell["verdict"] = "READS AS METAL" if ok_all else "READS AS TIMBER"
                if not ok_all:
                    rep["ok"] = False
                # *** THE HARNESS GOES RED ON ITS AUTHOR, THE FOURTH TIME FOR
                # *** THIS LANE, AND THIS ONE IS THE MOST IMPORTANT. ***
                # hilite_desat asks "is the bright end whiter than the body".
                # On the CC0 reference metals that is a fair question, because
                # their near-white bands are painted into a texture and that IS
                # how the thing reads as metal. But it means the metric can be
                # satisfied by PAINTING A WHITE STRIPE - and pass 10 did
                # exactly that, as a vertex-colour ramp, and took the score
                # from 0.159/0.203/0.035 to 0.971/0.528/0.962 while the picture
                # still plainly showed tan sheets and not copper. I looked at
                # the render and the render disagreed with my own number.
                # So: when the span's slot is VERTEX-PAINTED, this metric is
                # measuring a band someone chose, not reflection behaviour, and
                # the instrument says so instead of banking the pass. The score
                # is still reported - it is a real measurement of a real change
                # - but it cannot close the fault on its own.
                if ok_all and slot in M.VCOL_SLOTS.get(key, set()):
                    cell["verdict"] = "PAINTED - NOT EARNED AS REFLECTION"
                    rep["errors"].append(
                        "%s/%s: %s scores %.3f but the span's slot is "
                        "VERTEX-PAINTED, so this metric is reading a band that "
                        "was authored into the mesh rather than reflection "
                        "behaviour. A painted stripe satisfies 'the bright end "
                        "runs whiter than the body' by construction. NOT a pass."
                        % (key, vname, MET, sc))
                    rep["ok"] = False
        else:
            rep["ok"] = False
        rep["by_view"][vname] = cell

    _clear()
    print("METALREAD " + json.dumps(rep))


main()
