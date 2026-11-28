"""Which way does each mesh's long axis point, imported, and where does the
calibrated staff basis send each unit axis? Measured, so the authoring axis is
read off the engine's own basis instead of reasoned about."""
import os, sys, bpy
from mathutils import Vector, Matrix
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import weaponfit as WF

repo = sys.argv[sys.argv.index("--")+1]
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)

def span(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(repo, path))
    new = [o for o in bpy.data.objects if o not in before]
    mesh = [o for o in new if o.type == 'MESH']
    bpy.context.view_layer.update()
    pts = WF.world_verts(mesh)
    lo = [min(p[i] for p in pts) for i in range(3)]
    hi = [max(p[i] for p in pts) for i in range(3)]
    for o in new:
        bpy.data.objects.remove(o, do_unlink=True)
    return [round(hi[i]-lo[i],3) for i in range(3)], [round(v,3) for v in lo], [round(v,3) for v in hi]

for p in ("assets/gear/wand_crystal.glb",
          "assets/gear/artifact/sceptre_golden.glb",
          "assets/gear/artifact/sword_golden.glb",
          "assets/gear/dungeon/staff_rare.glb"):
    try:
        print("AXIS %s span=%s lo=%s hi=%s" % ((p,) + span(p)))
    except Exception as e:
        print("AXIS %s EXC %r" % (p, e))

M, roll = WF.slot_matrix("staff", ("0","0","90"))
for nm, v in (("+X", (1,0,0)), ("+Y", (0,1,0)), ("+Z", (0,0,1))):
    print("BASIS staff(0,0,90) mesh %s -> slot %s" % (nm, [round(c,3) for c in (M.to_3x3() @ Vector(v))]))
I, _ = WF.slot_matrix("staff", ("0","0","0")) if False else (Matrix.Identity(4), 0)
print("SLOT_ROT_staff_cols %s" % (WF.SLOT_ROT["staff"],))
print("SLOT_ROT_CAL_staff %s" % (WF.SLOT_ROT_CAL.get("staff"),))
