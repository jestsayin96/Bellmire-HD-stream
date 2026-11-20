# S7 export: bake the fitted transform into five .glb bodies, origin at the CHEST BONE head
# (Blender z 0.9726 = model y 0.97), model axes, front = model +Z after the glTF Y-up convert.
import bpy, sys, os, json
A=sys.argv[sys.argv.index("--")+1:]
OUT=A[0]; REG=A[1]
W5=r"C:\hd adventure\bellmire-art"
PK=r"C:\hd adventure\_packs\quaternius_ultimate_rpg_items_CC0\Ultimate RPG Items Pack - Aug 2019"
FIT=json.load(open(os.path.join(W5,"renders","art","s7_armour","fit","_fit2.json")))
CHEST_Z=0.9726
os.makedirs(OUT,exist_ok=True)
reg={"source_pack":"Quaternius Ultimate RPG Items Pack (Aug 2019), CC0 1.0",
     "licence_file":"License.txt in the pack; recorded in docs/art/ASSET_SOURCES.md",
     "body":"KayKit adventurers, Knight.glb, Idle frame 1",
     "origin":"chest bone head (model y 0.97); front = model +Z",
     "uniform_scale":FIT["uniform_scale"],"hero_chest_depth_m":FIT["hero_chest_depth"],
     "clearance_m":FIT["clearance_m"],"pieces":{}}
for name,a in FIT["armours"].items():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.obj_import(filepath=os.path.join(PK,"OBJ",name+".obj"))
    objs=[o for o in bpy.context.scene.objects if o.type=='MESH']
    S=FIT["uniform_scale"]
    for o in objs:
        o.scale=(S,a["y_scale"]*S,S)
        o.location=(0.0,a["y_offset"],a["dz"]-CHEST_Z)
    bpy.context.view_layer.update()
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active=objs[0]
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    dg=bpy.context.evaluated_depsgraph_get()
    pts=[]; tris=0
    for o in objs:
        oe=o.evaluated_get(dg); me=oe.to_mesh(); mw=oe.matrix_world
        pts+=[tuple(mw@v.co) for v in me.vertices]
        me.calc_loop_triangles(); tris+=len(me.loop_triangles)
        oe.to_mesh_clear()
    p=os.path.join(OUT,name.lower()+".glb")
    bpy.ops.export_scene.gltf(filepath=p,export_format='GLB',use_selection=False)
    reg["pieces"][name.lower()]={
        "glb":"assets/gear/armour/"+name.lower()+".glb",
        "source_obj":"_packs/quaternius_ultimate_rpg_items_CC0/.../OBJ/%s.obj"%name,
        "uniform_scale":S,"y_scale":a["y_scale"],"y_offset":a["y_offset"],
        "dz_before_chest_shift":a["dz"],"collar_z":a["collar_z"],
        "baked_origin":"chest bone head",
        "bounds_model_axes_about_chest":{"lo":[round(min(p[i] for p in pts),4) for i in range(3)],
                                         "hi":[round(max(p[i] for p in pts),4) for i in range(3)]},
        "tris":tris,
        "front_first_body_rows_before":a["front_first_before"]["body_in_front"],
        "front_first_body_rows_after":a["front_first_after"]["body_in_front"],
        "front_first_rows":a["front_first_after"]["rows"],
        "blank_check":{v:k["opaque"] for v,k in a["views"].items()},
        "border_alpha":{v:k["border_alpha"] for v,k in a["views"].items()},
        "glb_import_sibling":False}
    print("EXPORTED",p,tris)
with open(REG,"w") as f: json.dump(reg,f,indent=1)
print("DONE")
