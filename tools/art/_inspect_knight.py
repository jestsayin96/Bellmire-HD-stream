import bpy, sys, json, os
from mathutils import Vector
p = sys.argv[sys.argv.index("--")+1]
for ob in list(bpy.data.objects): bpy.data.objects.remove(ob, do_unlink=True)
bpy.ops.import_scene.gltf(filepath=p)
dg = bpy.context.evaluated_depsgraph_get()
pts=[]; info=[]
arms=[]
for ob in bpy.data.objects:
    info.append(dict(name=ob.name, type=ob.type, parent=(ob.parent.name if ob.parent else None),
                     mats=[m.name for m in ob.data.materials] if ob.type=='MESH' and ob.data else []))
    if ob.type=='ARMATURE':
        arms.append(dict(name=ob.name, bones=[b.name for b in ob.data.bones]))
    if ob.type=='MESH':
        obe=ob.evaluated_get(dg); me=obe.to_mesh(); mw=obe.matrix_world
        for v in me.vertices: pts.append(mw@v.co)
        obe.to_mesh_clear()
mn=Vector((min(q.x for q in pts),min(q.y for q in pts),min(q.z for q in pts)))
mx=Vector((max(q.x for q in pts),max(q.y for q in pts),max(q.z for q in pts)))
# bone head/tail in world space for the key bones
bonepos={}
for a in bpy.data.objects:
    if a.type!='ARMATURE': continue
    for b in a.data.bones:
        h=a.matrix_world@b.head_local; t=a.matrix_world@b.tail_local
        bonepos[b.name]=[round(h.x,4),round(h.y,4),round(h.z,4),round(t.x,4),round(t.y,4),round(t.z,4)]
out=dict(objs=info, arms=arms, bounds=[[round(mn.x,4),round(mn.y,4),round(mn.z,4)],[round(mx.x,4),round(mx.y,4),round(mx.z,4)]],
         height=round(mx.z-mn.z,4), actions=[a.name for a in bpy.data.actions][:60], bones=bonepos,
         mats=[dict(name=m.name) for m in bpy.data.materials])
print("INSPECT "+json.dumps(out))
