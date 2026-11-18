"""RAMMER: IS THE MONKEY THE WIDEST THING IN THE UPPER FRAME - AT EVERY ANGLE?

MY OWN 12:39 FIX TARGET, STATED AS A SENTENCE AND NEVER MEASURED: "narrow the
head cap so the monkey is the widest thing in the upper frame by a clear margin
at every angle". A sentence is not an instrument. The team lead then looked at
three silhouettes by eye and said the FRONT already passes, the SIDE is about
equal, and only the THREE-QUARTER fails. That is a hypothesis about a picture,
and the honest move is to measure the same thing the eye was doing rather than
take either of us at our word.

THE VIEWER'S QUESTION: with colour thrown away, at a given yaw, how wide does
the HEAD CAP BAND read, and how wide does the MONKEY BAND read? If the cap band
is as wide as or wider than the monkey band, the telegraph - THE MONKEY IS UP,
SO IT IS COMING DOWN - is being carried by something other than shape.

WHAT IS MEASURED, AND IT IS THE WHOLE SILHOUETTE, NOT THE CAP ALONE: the
left-most and right-most opaque column inside each z band, converted to world
units through the ortho camera. That is what a viewer's eye integrates. The
cap's own box is only part of the cap band - the three leg tops and the sheave
pin are in there too - so a fix to the box that does not move this number is
not a fix, and the AFTER run is what says which.

PASS 1 OF THIS HARNESS MEASURED THE BANDS AND CAME BACK GREEN AT EVERY YAW -
AND I DID NOT TRUST IT, BECAUSE ONE NUMBER WAS TOO BIG. At yaw 0 the monkey
band read 0.867 wide while the monkey block and its straps are only 0.62. The
extra 0.25 is THE SIDE STAY ROPE, which crosses that band on its way down to
the hauler's grip. So a green band margin can be green because the ROPE is
wide, which says nothing about whether the BLOCK reads. That is the same family
as `head_glow_px: 156` beside "the head has no face": a number measuring the
wrong object.

SO THERE ARE TWO MEASUREMENTS HERE AND THEY ARE REPORTED SEPARATELY:
  (1) BAND READ - the whole silhouette's extent in each z band. What a viewer's
      eye integrates, rope included. Honest, and NOT sufficient.
  (2) THE PART'S OWN READ, by the only test that answers it: render with the
      part and without it through ONE camera and count the pixels that MOVED.
      The renderer does the depth; the moved pixels are by definition the ones
      the viewer gains from that part being there. Zero moved pixels means the
      part is present and INVISIBLE, which is the fault no mask_of can see.
      The cap is stripped out of `rammer_bone` only, so the leg tops and the
      sheave pin stay in; the monkey block and its two straps are stripped out
      of `rammer_dark` only, so the ropes and the lifting eye stay in. Each
      number is therefore that ONE part's own contribution to the picture.

RED ON EMPTY, BOTH WAYS: a render with no opaque pixels is RED; a BAND with no
opaque pixels is RED too. A margin computed over an empty band reads
beautifully and means nothing.
AND THE BORDER IS CHECKED: a clipped silhouette is not a blank one, so any
opaque pixel on the frame edge is RED.

usage: blender -b -noaudio -P _rammer_cap_ab.py -- <repo> <tag>
"""
import math
import os
import sys

import numpy as np
import bpy

argv = sys.argv[sys.argv.index("--") + 1:]
repo = argv[0]
tag = argv[1] if len(argv) > 1 else "before"
GLB = os.path.join(repo, "assets", "monsters", "minibosses", "rammer.glb")
OUT = os.path.join(repo, "renders", "art", "minibosses", "_rammer_cap_ab")
os.makedirs(OUT, exist_ok=True)

# the two bands, off the SOURCE geometry in minibosses.py, not off the picture.
# cap:    box 0.17 thick centred z 2.58 -> 2.495..2.665; the sheave pin ring is
#         r 0.115 + tube 0.028 about the same centre -> 2.437..2.723; model top
#         is 2.75. Band 2.44..2.76 covers the whole head assembly.
# monkey: block 0.52 tall centred 1.93 -> 1.67..2.19; the two strap boxes reach
#         2.156; the lifting eye ring tops out at 1.93+0.30+0.055+0.022=2.307.
CAP_LO, CAP_HI = 2.44, 2.76
MON_LO, MON_HI = 1.67, 2.31

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE'
scene.render.film_transparent = True
scene.render.resolution_x = 1100
scene.render.resolution_y = 1400
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'

bpy.ops.import_scene.gltf(filepath=GLB)
meshes = [o for o in scene.objects if o.type == 'MESH']
if not meshes:
    raise SystemExit("RED: no meshes imported from %s" % GLB)

root = bpy.data.objects.new("rammer_root", None)
scene.collection.objects.link(root)
for o in meshes:
    if o.parent is None:
        o.parent = root
        o.matrix_parent_inverse = root.matrix_world.inverted()

# TRAP 1 AND TRAP 3: bounds off the EVALUATED depsgraph with the scene active,
# so clip and camera distance come from the model and never from a guess.
dg = bpy.context.evaluated_depsgraph_get()
lo = np.array([1e9, 1e9, 1e9])
hi = np.array([-1e9, -1e9, -1e9])
for o in meshes:
    ev = o.evaluated_get(dg)
    for c in ev.bound_box:
        p = np.array(ev.matrix_world @ type(o.location)(c))
        lo = np.minimum(lo, p)
        hi = np.maximum(hi, p)
ctr = (lo + hi) * 0.5
span = float(max(hi - lo))
print("BOUNDS", lo.round(3).tolist(), hi.round(3).tolist(), "span", round(span, 3))

cam_d = span * 4.0
cam = bpy.data.cameras.new("cam")
cam.type = 'ORTHO'
# sensor_fit VERTICAL on purpose: with AUTO and a portrait frame it is the
# HEIGHT that ortho_scale maps to, and the old yaw harness assumed width. One
# explicit line removes a whole class of silent off-by-aspect error.
cam.sensor_fit = 'VERTICAL'
cam.ortho_scale = span * 1.25
cam.clip_start = max(0.01, cam_d - span * 2.0)
cam.clip_end = cam_d + span * 2.0
cob = bpy.data.objects.new("cam", cam)
scene.collection.objects.link(cob)
cob.location = (float(ctr[0]), float(ctr[1]) - cam_d, float(ctr[2]))
cob.rotation_euler = (math.pi / 2.0, 0.0, 0.0)
scene.camera = cob

W = scene.render.resolution_x
H = scene.render.resolution_y
WPP = cam.ortho_scale / float(H)        # world units per pixel, both axes


# ---------------------------------------------------------------- VARIANTS
# The A/B strip boxes, in BUILD coordinates (the glTF importer restores Z-up,
# and BOUNDS above agrees with minibosses.py's own numbers, so these are the
# generator's own figures and not re-derived from the picture).
#   cap   bone verts in the TOP slab of the capping block. The block spans
#         z 2.495..2.665; the three legs converge AT z 2.52, so the slab starts
#         at 2.53 to leave the leg apex alone. A box's width does not vary with
#         z, so the top slab gives the cap's full x extent.
#   mon   dark verts of the block (0.58x0.34x0.52 at z 1.93) and its two strap
#         boxes (to z 2.156). The lifting eye (2.23+) and both ropes are left
#         in on purpose.
CAP_BOX = ((-0.21, 0.21), (-0.27, 0.11), (2.53, 2.67))
MON_BOX = ((-0.335, 0.335), (-0.30, 0.10), (1.66, 2.17))
STRIP = {"rammer_bone": CAP_BOX, "rammer_dark": MON_BOX}


def stripped(obj, bx):
    """A copy of obj's mesh with every vert inside bx removed."""
    import bmesh
    me = obj.data.copy()
    bm = bmesh.new()
    bm.from_mesh(me)
    (x0, x1), (y0, y1), (z0, z1) = bx
    kill = [v for v in bm.verts
            if x0 <= v.co.x <= x1 and y0 <= v.co.y <= y1 and z0 <= v.co.z <= z1]
    if not kill:
        raise SystemExit("RED: strip box for %s selected NO verts - the box and "
                         "the geometry disagree, so the A/B cannot move" % obj.name)
    bmesh.ops.delete(bm, geom=kill, context='VERTS')
    bm.to_mesh(me)
    bm.free()
    return me, len(kill)


by_name = {}
for o in meshes:
    by_name[o.name.split('.')[0]] = o
VAR = {}
for nm, bx in STRIP.items():
    if nm not in by_name:
        raise SystemExit("RED: expected mesh %s not in the glb (%s)"
                         % (nm, sorted(by_name)))
    ob = by_name[nm]
    me, n = stripped(ob, bx)
    VAR[nm] = (ob, ob.data, me, n)
    print("STRIP %-12s removed %4d verts of %4d" % (nm, n, len(ob.data.vertices)))


def read_alpha(path):
    img = bpy.data.images.load(path, check_existing=False)
    try:
        img.colorspace_settings.name = 'Non-Color'
    except Exception:
        pass
    w, h = img.size
    buf = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(buf)
    bpy.data.images.remove(img)
    return buf.reshape(h, w, 4)[::-1, :, 3] > 0.5


def row_of(z):
    return int(round((float(ctr[2]) - z) / WPP + (H - 1) * 0.5))


def band_width(a, z_lo, z_hi, name, yaw):
    r_hi, r_lo = row_of(z_hi), row_of(z_lo)       # higher z = smaller row
    r_hi = max(0, r_hi)
    r_lo = min(H - 1, r_lo)
    if r_lo <= r_hi:
        raise SystemExit("RED yaw %d: %s band has no rows" % (yaw, name))
    b = a[r_hi:r_lo + 1]
    cols = np.where(b.any(axis=0))[0]
    if cols.size == 0:
        raise SystemExit("RED yaw %d: %s band is EMPTY - an empty band is not "
                         "a clean sheet" % (yaw, name))
    wpx = int(cols.max() - cols.min()) + 1
    # peak single-row run too: the extent can be two thin things far apart
    peak = int(max((np.where(r)[0].max() - np.where(r)[0].min() + 1)
                   if r.any() else 0 for r in b))
    return wpx, wpx * WPP, peak * WPP, int(b.sum())


def shoot(path):
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    a = read_alpha(path)
    if int(a.sum()) == 0:
        raise SystemExit("RED: EMPTY render %s" % path)
    return a


def moved_extent(full, var, z_lo, z_hi, name, yaw):
    """Pixels the viewer GAINS from the part being there, inside the band."""
    r_hi, r_lo = max(0, row_of(z_hi)), min(H - 1, row_of(z_lo))
    d = (full[r_hi:r_lo + 1] != var[r_hi:r_lo + 1])
    n = int(d.sum())
    if n == 0:
        print("   !! %s moved ZERO pixels at yaw %d - the part is present and "
              "INVISIBLE from here" % (name, yaw))
        return 0, 0.0
    cols = np.where(d.any(axis=0))[0]
    return n, (int(cols.max() - cols.min()) + 1) * WPP


rows = []
for yaw in (0, 15, 30, 45, 60, 75, 90):
    root.rotation_euler = (0.0, 0.0, math.radians(yaw))
    bpy.context.view_layer.update()
    base = os.path.join(OUT, "%s_yaw%02d" % (tag, yaw))
    for nm, (ob, orig, _me, _n) in VAR.items():
        ob.data = orig
    a = shoot(base + ".png")
    if a[0].any() or a[-1].any() or a[:, 0].any() or a[:, -1].any():
        raise SystemExit("RED yaw %d: silhouette touches the frame border - a "
                         "clipped icon is not a blank one" % yaw)
    cpx, cw, cpk, cfill = band_width(a, CAP_LO, CAP_HI, "cap", yaw)
    mpx, mw, mpk, mfill = band_width(a, MON_LO, MON_HI, "monkey", yaw)

    # (2) each part's OWN read, by what moves when it is taken away
    ob, orig, me, _n = VAR["rammer_bone"]
    ob.data = me
    bpy.context.view_layer.update()
    a_nc = shoot(base + "_nocap.png")
    ob.data = orig
    ob2, orig2, me2, _n2 = VAR["rammer_dark"]
    ob2.data = me2
    bpy.context.view_layer.update()
    a_nm = shoot(base + "_nomonkey.png")
    ob2.data = orig2
    bpy.context.view_layer.update()

    cap_n, cap_own = moved_extent(a, a_nc, CAP_LO, CAP_HI, "cap", yaw)
    mon_n, mon_own = moved_extent(a, a_nm, MON_LO, MON_HI, "monkey", yaw)
    own_margin = mon_own - cap_own
    rows.append({"yaw": yaw,
                 "band_cap_w": round(cw, 4), "band_mon_w": round(mw, 4),
                 "band_margin": round(mw - cw, 4),
                 "cap_own_w": round(cap_own, 4), "cap_moved_px": cap_n,
                 "mon_own_w": round(mon_own, 4), "mon_moved_px": mon_n,
                 "own_margin": round(own_margin, 4),
                 "pass": bool(own_margin >= 0.09 and cap_n > 0 and mon_n > 0)})
    print("YAW %2d | band cap %.3f mon %.3f (m %+.3f) | OWN cap %.3f (%d px) "
          "mon %.3f (%d px) margin %+.3f %s"
          % (yaw, cw, mw, mw - cw, cap_own, cap_n, mon_own, mon_n, own_margin,
             "PASS" if rows[-1]["pass"] else "FAIL"))

worst = min(r["own_margin"] for r in rows)
fails = [r["yaw"] for r in rows if not r["pass"]]
print("RAMMER_CAP_AB tag=%s worst_own_margin=%+.4f fail_yaws=%s" % (tag, worst, fails))
print("RAMMER_CAP_AB_JSON", rows)
