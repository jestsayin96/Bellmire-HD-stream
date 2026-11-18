"""RAMMER: CAN THE CHALK RING BE SEEN - AND FROM WHERE?

THE TEAM LEAD COULD NOT FIND THE CHALK RING IN EITHER ON-BODY RENDER AND ASKED
WHETHER IT WAS EVER MODELLED. It was. The generator lays a horizontal annulus,
r 0.20, tube 0.016, on the broomed head of the pile at z 0.415 - and my own
write-up and my own source comment both put it ON THE FLOOR, which is why he
went looking at the floor plane and found nothing. The sentence was the fault.

BUT "IT IS IN THE GLB" IS THE EXACT CLAIM PASS 11 TAUGHT ME NOT TO ACCEPT.
`head_glow_px: 156` shipped beside my own sentence "the head now has no face at
all" and both were true, because a mask rendered alone answers how BIG a thing
is and says nothing about whether it can be SEEN. So the question here is not
whether the ring exists. It is whether a viewer gains any pixels from it.

AND THERE IS A GEOMETRIC REASON TO DOUBT IT, WHICH IS WHY THIS HARNESS EXISTS
RATHER THAN A SENTENCE: directly beneath the ring sits the broomed collar, a
cone of radius 0.255 tapering to 0.215 over z 0.335..0.410. The ring's radius
is 0.20. THE COLLAR IS WIDER THAN THE RING AND THE RING SITS ON TOP OF IT, so
from any camera at or below the ring's own height the collar's rim hides it
completely. A flat mark 0.4 off the floor, read from eye level, is a hairline.

THE TEST: render with the ring and without it, through ONE camera, and count
the pixels that MOVED. The renderer does the depth. Sweep the camera ELEVATION,
because that is the variable the answer turns on and I do not own the dungeon
camera - the game build does. The output says at what elevation the mark starts
to read, so that lane can say whether its camera clears it.

RED ON EMPTY: an empty render is RED. Zero moved pixels is NOT an error here -
it is the finding - but it is printed as a fault line, not buried in a total.

usage: blender -b -noaudio -P _rammer_ring_ab.py -- <repo>
"""
import math
import os
import sys

import numpy as np
import bpy
import bmesh

argv = sys.argv[sys.argv.index("--") + 1:]
repo = argv[0]
GLB = os.path.join(repo, "assets", "monsters", "minibosses", "rammer.glb")
OUT = os.path.join(repo, "renders", "art", "minibosses", "_rammer_ring_ab")
os.makedirs(OUT, exist_ok=True)

RING_Z_MAX = 0.60      # the ring tops out at 0.431; the eyes sit at 1.30

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE'
scene.render.film_transparent = True
scene.render.resolution_x = 1100
scene.render.resolution_y = 1100
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'

bpy.ops.import_scene.gltf(filepath=GLB)
meshes = [o for o in scene.objects if o.type == 'MESH']
if not meshes:
    raise SystemExit("RED: no meshes imported from %s" % GLB)

dg = bpy.context.evaluated_depsgraph_get()
lo = np.array([1e9, 1e9, 1e9]); hi = np.array([-1e9, -1e9, -1e9])
for o in meshes:
    ev = o.evaluated_get(dg)
    for c in ev.bound_box:
        p = np.array(ev.matrix_world @ type(o.location)(c))
        lo = np.minimum(lo, p); hi = np.maximum(hi, p)
ctr = (lo + hi) * 0.5
span = float(max(hi - lo))
print("BOUNDS", lo.round(3).tolist(), hi.round(3).tolist(), "span", round(span, 3))

glow = None
for o in meshes:
    if o.name.split('.')[0] == "rammer_glow":
        glow = o
if glow is None:
    raise SystemExit("RED: no rammer_glow mesh in the glb")

# the ring alone, out of a slot it shares with the hauler's eyes
me_noring = glow.data.copy()
bm = bmesh.new(); bm.from_mesh(me_noring)
kill = [v for v in bm.verts if v.co.z <= RING_Z_MAX]
if not kill:
    raise SystemExit("RED: no glow verts below z %.2f - the ring is not where "
                     "the generator says it is" % RING_Z_MAX)
keep = len(bm.verts) - len(kill)
bmesh.ops.delete(bm, geom=kill, context='VERTS')
bm.to_mesh(me_noring); bm.free()
print("RING verts %d of %d in rammer_glow (the other %d are the hauler's eyes)"
      % (len(kill), len(kill) + keep, keep))
me_full = glow.data

# a light, because an emissive mark on dark wet oak is the whole question
lamp = bpy.data.lights.new("key", 'SUN'); lamp.energy = 3.0
lob = bpy.data.objects.new("key", lamp); scene.collection.objects.link(lob)
lob.rotation_euler = (math.radians(55), 0.0, math.radians(35))

cam = bpy.data.cameras.new("cam"); cam.lens = 50.0
cob = bpy.data.objects.new("cam", cam); scene.collection.objects.link(cob)
scene.camera = cob
cam_d = span * 2.6
cam.clip_start = max(0.01, cam_d - span * 2.0)
cam.clip_end = cam_d + span * 2.0

# aim at the PILE HEAD, not the body centre: that is where the mark is, and a
# camera framed on the whole creature puts a 0.4-wide mark in a handful of px.
AIM = np.array([0.0, -0.10, 0.415])


def read_alpha_rgb(path):
    img = bpy.data.images.load(path, check_existing=False)
    try:
        img.colorspace_settings.name = 'Non-Color'
    except Exception:
        pass
    w, h = img.size
    buf = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(buf)
    bpy.data.images.remove(img)
    a = buf.reshape(h, w, 4)[::-1]
    return a[:, :, 3] > 0.5, a[:, :, :3]


def shoot(path):
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    al, rgb = read_alpha_rgb(path)
    if int(al.sum()) == 0:
        raise SystemExit("RED: EMPTY render %s" % path)
    return al, rgb


rows = []
for elev in (0, 10, 20, 30, 45, 60):
    for yaw in (0, 40):
        e = math.radians(elev)
        y = math.radians(yaw)
        d = np.array([math.sin(y) * math.cos(e), -math.cos(y) * math.cos(e),
                      math.sin(e)])
        cob.location = tuple(AIM + d * cam_d)
        cob.rotation_euler = (math.pi / 2.0 - e, 0.0, y)
        base = os.path.join(OUT, "e%02d_y%02d" % (elev, yaw))
        glow.data = me_full
        bpy.context.view_layer.update()
        a1, c1 = shoot(base + "_ring.png")
        glow.data = me_noring
        bpy.context.view_layer.update()
        a2, c2 = shoot(base + "_noring.png")
        glow.data = me_full
        # a mark that is the same colour family as what it sits on moves few
        # alpha pixels and many COLOUR pixels, so both are counted.
        dalpha = int((a1 != a2).sum())
        dcol = int((np.abs(c1 - c2).max(axis=2) > 0.02).sum())
        if dcol == 0:
            print("   !! elev %2d yaw %2d: the chalk ring moves ZERO pixels - "
                  "present and INVISIBLE from here" % (elev, yaw))
        rows.append({"elev": elev, "yaw": yaw, "moved_alpha": dalpha,
                     "moved_colour": dcol, "visible": bool(dcol > 0)})
        print("ELEV %2d YAW %2d  moved_alpha %6d  moved_colour %6d  %s"
              % (elev, yaw, dalpha, dcol, "SEEN" if dcol else "INVISIBLE"))

first = [r["elev"] for r in rows if r["visible"]]
print("RAMMER_RING_AB lowest_visible_elev=%s invisible_at=%s"
      % (min(first) if first else None,
         [(r["elev"], r["yaw"]) for r in rows if not r["visible"]]))
print("RAMMER_RING_AB_JSON", rows)
