# What is the shell actually MADE OF? The earlier passes separated "plate" from "horn" by a
# |x| <= 0.45 cutoff and then reported the plate's reach as 0.4495 - a number that CANNOT
# exceed the cutoff by construction. That is a circular instrument: it answers the threshold,
# not the geometry, and finding 5's conclusion ("a slice of the plate is beyond the threshold")
# rests on it. Separate by MATERIAL and by CONNECTED COMPONENT instead, which are facts about
# the mesh and not about my own cutoff.
# RED ON EMPTY: zero islands or zero verts in an island fails.
import bpy, sys, os, json, math, mathutils, bmesh
A=sys.argv[sys.argv.index("--")+1:]
OUT=A[0]
PK=r"C:\hd adventure\_packs\quaternius_ultimate_rpg_items_CC0\Ultimate RPG Items Pack - Aug 2019"
NAMES=["Armor_Black","Armor_Golden","Armor_Leather","Armor_Metal","Armor_Metal2"]
rep={"shells":{},"errors":[]}
for name in NAMES:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.obj_import(filepath=os.path.join(PK,"OBJ",name+".obj"))
    sc=bpy.context.scene
    objs=[o for o in sc.objects if o.type=='MESH']
    if not objs:
        rep["errors"].append("%s: RED no mesh"%name); continue
    ent={"objects":[],"materials":[],"islands":[]}
    for o in objs:
        o.data.transform(o.matrix_world); o.matrix_world=mathutils.Matrix.Identity(4)
        ent["objects"].append({"name":o.name,"verts":len(o.data.vertices),"tris":len(o.data.loop_triangles) if o.data.loop_triangles else len(o.data.polygons)})
        ent["materials"]+= [m.name for m in o.data.materials if m]
        bm=bmesh.new(); bm.from_mesh(o.data)
        bm.verts.ensure_lookup_table()
        seen=set(); isl=[]
        for v in bm.verts:
            if v.index in seen: continue
            stack=[v]; comp=[]
            seen.add(v.index)
            while stack:
                cv=stack.pop(); comp.append(cv)
                for e in cv.link_edges:
                    ov=e.other_vert(cv)
                    if ov.index not in seen: seen.add(ov.index); stack.append(ov)
            isl.append(comp)
        for comp in isl:
            xs=[c.co.x for c in comp]; ys=[c.co.y for c in comp]; zs=[c.co.z for c in comp]
            if not xs: rep["errors"].append("%s: RED empty island"%name); continue
            ent["islands"].append({"obj":o.name,"verts":len(comp),
                "x":[round(min(xs),4),round(max(xs),4)],
                "y":[round(min(ys),4),round(max(ys),4)],
                "z":[round(min(zs),4),round(max(zs),4)],
                "cx":round(sum(xs)/len(xs),4),
                "touches_centre": bool(min(abs(x) for x in xs)<0.08)})
        bm.free()
    if not ent["islands"]: rep["errors"].append("%s: RED zero islands"%name)
    ent["islands"].sort(key=lambda i:-i["verts"])
    rep["shells"][name]=ent
open(OUT,"w").write(json.dumps(rep,indent=1))
print("ISLANDS errors=%d"%len(rep["errors"]))
print("DONE")
