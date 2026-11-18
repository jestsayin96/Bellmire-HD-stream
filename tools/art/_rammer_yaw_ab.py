"""RAMMER: WHAT ACTUALLY FILLS THE GAP UNDER THE HEAD - A MOVING INSTRUMENT.

The 12:39 write-up asserted the band between the head cap and the monkey is
"the two frame legs". That attribution was arithmetic, not evidence, and the
house rule is that a number which cannot move is not a pass.

THE VIEWER'S QUESTION: in a FRONT orthographic view, with colour thrown away,
is there daylight between the head and the hauled block - and if not, WHICH
part is standing in it?

THE TEST THAT MOVES: render the shipped glb through ONE camera at several YAW
angles and measure the vertical white run at the cap's centre column between
the cap's bottom and the monkey's top. A part that sits ON the centre line
(x = 0) projects down the centre at yaw 0 and swings off it as yaw grows; a
part that is already off-centre does not behave that way. If the gap OPENS
with yaw, the thing filling it was on the axis.

RED ON EMPTY: a render with no opaque pixels, or a band with no rows in it,
is a RED, not a clean sheet.

usage: blender -b -noaudio -P _rammer_yaw_ab.py -- <repo>
"""
import math
import os
import sys

import numpy as np
import bpy

argv = sys.argv[sys.argv.index("--") + 1:]
repo = argv[0]
GLB = os.path.join(repo, "assets", "monsters", "minibosses", "rammer.glb")
OUT = os.path.join(repo, "renders", "art", "minibosses", "_rammer_yaw_ab")
os.makedirs(OUT, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE'
scene.render.film_transparent = True
scene.render.resolution_x = 900
scene.render.resolution_y = 1200
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

# TRAP 1 AND TRAP 3: measure world bounds off the EVALUATED depsgraph, with the
# scene active, so clip and camera distance come from the model and not a guess.
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
cam.ortho_scale = span * 1.22
cam.clip_start = max(0.01, cam_d - span * 2.0)
cam.clip_end = cam_d + span * 2.0
cob = bpy.data.objects.new("cam", cam)
scene.collection.objects.link(cob)
cob.location = (float(ctr[0]), float(ctr[1]) - cam_d, float(ctr[2]))
cob.rotation_euler = (math.pi / 2.0, 0.0, 0.0)
scene.camera = cob

# Z height of the two landmarks, from the source geometry, not from the picture:
CAP_BOT = 2.58 - 0.17 / 2.0          # head cap box centre 2.58, 0.17 thick
MON_TOP = 1.93 + 0.30 + 0.055        # monkey lifting-eye ring top


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


rows = []
for yaw in (0, 8, 16, 24, 40):
    root.rotation_euler = (0.0, 0.0, math.radians(yaw))
    bpy.context.view_layer.update()
    p = os.path.join(OUT, "yaw%02d.png" % yaw)
    scene.render.filepath = p
    bpy.ops.render.render(write_still=True)
    a = read_alpha(p)
    if int(a.sum()) == 0:
        raise SystemExit("RED yaw %d: EMPTY render - an empty frame is not a pass" % yaw)
    H, W = a.shape
    # world z -> image row, through the ortho camera
    top_w = float(ctr[2]) + cam.ortho_scale * (H / W) * 0.5
    bot_w = float(ctr[2]) - cam.ortho_scale * (H / W) * 0.5
    def row_of(z):
        return int(round((top_w - z) / (top_w - bot_w) * (H - 1)))
    r_cap, r_mon = row_of(CAP_BOT), row_of(MON_TOP)
    if r_mon <= r_cap:
        raise SystemExit("RED: band has no rows (cap %d monkey %d)" % (r_cap, r_mon))
    band = a[r_cap:r_mon]
    # the cap's own centre column, found from the picture each time
    caprow = a[max(0, row_of(2.58) - 2):row_of(2.58) + 3]
    cols = np.where(caprow.any(axis=0))[0]
    if cols.size == 0:
        raise SystemExit("RED yaw %d: no cap pixels to centre on" % yaw)
    cx = int(round(cols.mean()))
    col = band[:, cx]
    white_at_cx = int((~col).sum())
    # and the honest wider question: how much daylight is there anywhere in the
    # band between the cap's left and right edges
    l, r = int(cols.min()), int(cols.max())
    white_in_cap_width = int((~band[:, l:r + 1]).sum())
    rows.append((yaw, cx, int(band.shape[0]), white_at_cx,
                 white_in_cap_width, int(band[:, l:r + 1].size)))
    print("YAW %2d cx %4d band_rows %3d white_at_centre %3d "
          "white_in_cap_width %6d of %6d" % rows[-1])

print("RAMMER_YAW_AB", rows)
