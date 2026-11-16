
import bpy, sys, json, os
from mathutils import Vector
paths = sys.argv[sys.argv.index("--")+1:]
out = {}
for p in paths:
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    try:
        bpy.ops.import_scene.gltf(filepath=p)
    except Exception as e:
        out[os.path.basename(p)] = {"err": str(e)[:150]}
        continue
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []; mats = set(); tris = 0
    for ob in bpy.data.objects:
        if ob.type != 'MESH':
            continue
        obe = ob.evaluated_get(dg); me = obe.to_mesh(); mw = obe.matrix_world
        tris += len(me.polygons)
        for m in ob.data.materials:
            if m: mats.add(m.name)
        for v in me.vertices: pts.append(mw @ v.co)
        obe.to_mesh_clear()
    if not pts:
        out[os.path.basename(p)] = {"empty": True}; continue
    mn = Vector((min(q.x for q in pts), min(q.y for q in pts), min(q.z for q in pts)))
    mx = Vector((max(q.x for q in pts), max(q.y for q in pts), max(q.z for q in pts)))
    out[os.path.basename(p)] = dict(
        mn=[round(mn.x,3),round(mn.y,3),round(mn.z,3)],
        mx=[round(mx.x,3),round(mx.y,3),round(mx.z,3)],
        tris=tris, mats=sorted(mats),
        objs=[o.name for o in bpy.data.objects if o.type=='MESH'][:6])
print("GEARINSPECT " + json.dumps(out))
