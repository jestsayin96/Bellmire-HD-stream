"""_el_ground_probe - CAN THIS BLENDER CATCH A SHADOW ON AN ALPHA FILM?

20 Nov 2026, instalment 5. The ground-contact fault is rig-level: minibossfit
renders with film_transparent and NO floor, so every subject in every even
light cell stands on nothing. Three instalments have named it.

Before I write a fix I have to know which of two mechanisms this Blender
actually supports, and the only way to know is to render and LOOK AT THE
NUMBERS, not to read a release note:

  A. is_shadow_catcher on the plane. If EEVEE honours it, the plane is
     invisible except where it is shadowed, and the shadow arrives in the
     ALPHA channel. That is the cheap fix - one object, one flag.
  B. If it does not, the plane renders as an opaque white slab (alpha 1
     everywhere it covers) and the cut-out look is destroyed.

GOES RED ON EMPTY: if the lit control has no opaque pixels at all the probe
is an error, not a verdict - a shadow measured over an empty render would
read as a clean zero either way.
"""
import os, sys, math, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, numpy as np
from mathutils import Vector

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "."


def read_png(path):
    img = bpy.data.images.load(path, check_existing=False)
    try:
        img.colorspace_settings.name = 'Non-Color'
    except Exception:
        pass
    w, h = img.size
    buf = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(buf)
    bpy.data.images.remove(img)
    return buf.reshape(h, w, 4)[::-1]


def fresh():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    eng = None
    for name in ('BLENDER_EEVEE', 'BLENDER_EEVEE_NEXT', 'CYCLES'):
        try:
            sc.render.engine = name
            eng = name
            break
        except Exception:
            continue
    sc.render.resolution_x = sc.render.resolution_y = 256
    sc.render.resolution_percentage = 100
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGBA'
    return sc, eng


def build(catcher):
    sc, eng = fresh()
    bpy.ops.mesh.primitive_plane_add(size=12.0, location=(0, 0, 0))
    plane = bpy.context.object
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.5))
    cube = bpy.context.object
    flag_ok = hasattr(plane, "is_shadow_catcher")
    if catcher and flag_ok:
        plane.is_shadow_catcher = True
    li = bpy.data.lights.new("key", type='SUN')
    li.energy = 3.0
    lo = bpy.data.objects.new("key", li)
    bpy.context.collection.objects.link(lo)
    d = Vector((0.6, -1.0, 0.9)).normalized()
    lo.location = d * 10.0
    lo.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
    cd = bpy.data.cameras.new("cam")
    cd.type = 'ORTHO'
    cd.ortho_scale = 6.0
    cam = bpy.data.objects.new("cam", cd)
    bpy.context.collection.objects.link(cam)
    sc.camera = cam
    cd2 = Vector((0.0, -1.0, 0.25)).normalized()
    cam.location = Vector((0, 0, 0.5)) + cd2 * 12.0
    cam.rotation_euler = cd2.to_track_quat('Z', 'Y').to_euler()
    cd.clip_start, cd.clip_end = 0.1, 60.0
    return sc, eng, flag_ok


def shoot(sc, path):
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return read_png(path)


rows = {}
res = {"engine": None, "blender": bpy.app.version_string, "flag_exists": None}
for tag, catcher in (("nofloor", None), ("catcher", True), ("opaque", False)):
    sc, eng, flag_ok = build(catcher if catcher is not None else False)
    res["engine"] = eng
    res["flag_exists"] = flag_ok
    if tag == "nofloor":
        for o in list(bpy.context.scene.objects):
            if o.name.startswith("Plane"):
                bpy.data.objects.remove(o, do_unlink=True)
    p = os.path.join(OUT, "_gp_%s.png" % tag)
    a = shoot(sc, p)
    al = a[:, :, 3]
    opaque = int((al > 0.98).sum())
    partial = int(((al > 0.02) & (al <= 0.98)).sum())
    empty = int((al <= 0.02).sum())
    rows[tag] = {"opaque": opaque, "partial": partial, "empty": empty,
                 "mean_alpha": float(al.mean()),
                 "lit_rgb": [round(float(a[:, :, i][al > 0.98].mean()), 4) if opaque else None
                             for i in range(3)]}
res["rows"] = rows
res["RED_ON_EMPTY"] = (rows["nofloor"]["opaque"] == 0)
with open(os.path.join(OUT, "_el_ground_probe.json"), "w") as f:
    json.dump(res, f, indent=1)
print("PROBE_DONE", json.dumps(res))
