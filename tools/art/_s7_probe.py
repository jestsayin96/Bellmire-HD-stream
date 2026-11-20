# S7 stage A: render each armour ALONE from 4 views to learn its shape and facing.
# Blender Z is up after wm.obj_import (importer converts Y-up OBJ). FRONT of the hero is -Y.
import bpy, sys, os, json, math, mathutils
import numpy as np
ARGS = sys.argv[sys.argv.index("--")+1:]
OUTDIR = ARGS[0]
PK = r"C:\hd adventure\_packs\quaternius_ultimate_rpg_items_CC0\Ultimate RPG Items Pack - Aug 2019"
NAMES = ["Armor_Black","Armor_Golden","Armor_Leather","Armor_Metal","Armor_Metal2"]
RES = 420
os.makedirs(OUTDIR, exist_ok=True)

def setup_world():
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_EEVEE'
    sc.render.resolution_x = RES; sc.render.resolution_y = RES
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGBA'
    # three lamps so a dark material still reads
    for loc, e in [((4,-5,6),2000),((-5,-3,3),900),((0,6,4),700)]:
        l = bpy.data.lights.new("L", 'POINT'); l.energy = e
        ob = bpy.data.objects.new("L", l); ob.location = loc
        sc.collection.objects.link(ob)

def bounds(objs):
    dg = bpy.context.evaluated_depsgraph_get()
    pts=[]
    for o in objs:
        if o.type!='MESH': continue
        oe=o.evaluated_get(dg); me=oe.to_mesh(); mw=oe.matrix_world
        pts += [tuple(mw@v.co) for v in me.vertices]
        oe.to_mesh_clear()
    lo=[min(p[i] for p in pts) for i in range(3)]; hi=[max(p[i] for p in pts) for i in range(3)]
    return lo,hi

def check_png(path):
    im = bpy.data.images.load(path)
    im.colorspace_settings.name = 'Non-Color'
    w,h = im.size
    a = np.array(im.pixels[:], dtype=np.float32).reshape(h,w,4)
    alpha = a[:,:,3]
    opaque = int((alpha > 0.02).sum())
    b = 2
    border = float(max(alpha[:b,:].max(), alpha[-b:,:].max(), alpha[:,:b].max(), alpha[:,-b:].max()))
    bpy.data.images.remove(im)
    return {"opaque": opaque, "border_alpha": round(border,4), "size":[w,h]}

report = {}
for name in NAMES:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    setup_world()
    bpy.ops.wm.obj_import(filepath=os.path.join(PK,"OBJ",name+".obj"))
    objs=[o for o in bpy.context.scene.objects if o.type=='MESH']
    lo,hi = bounds(objs)
    ctr = mathutils.Vector(((lo[0]+hi[0])/2,(lo[1]+hi[1])/2,(lo[2]+hi[2])/2))
    rad = max(hi[i]-lo[i] for i in range(3))
    dist = rad*2.4
    cam_d = bpy.data.cameras.new("C"); cam = bpy.data.objects.new("C", cam_d)
    bpy.context.scene.collection.objects.link(cam); bpy.context.scene.camera = cam
    cam_d.clip_start = max(0.01, dist*0.05); cam_d.clip_end = dist*6
    cam_d.sensor_fit = 'AUTO'
    views = {"front_negY": mathutils.Vector((0,-1,0)), "back_posY": mathutils.Vector((0,1,0)),
             "side_posX": mathutils.Vector((1,0,0)), "top_posZ": mathutils.Vector((0,-0.001,1))}
    rep={}
    for vn, d in views.items():
        dv = d.normalized()
        cam.location = ctr + dv*dist
        # aim at ctr
        look = (ctr - cam.location).normalized()
        cam.rotation_euler = look.to_track_quat('-Z','Y').to_euler()
        # frame it: ortho-ish with a wide enough fov
        cam_d.lens = 50
        cam_d.angle = 2*math.atan((rad*0.62)/dist)
        p = os.path.join(OUTDIR, "%s_%s.png" % (name, vn))
        bpy.context.scene.render.filepath = p
        bpy.ops.render.render(write_still=True)
        rep[vn] = check_png(p)
    report[name] = {"lo":[round(c,4) for c in lo],"hi":[round(c,4) for c in hi],"views":rep}

# contact sheet: 5 rows x 4 cols
cols = ["front_negY","back_posY","side_posX","top_posZ"]
sheet = np.zeros((RES*len(NAMES), RES*len(cols), 4), dtype=np.float32)
for r,name in enumerate(NAMES):
    for c,vn in enumerate(cols):
        im = bpy.data.images.load(os.path.join(OUTDIR,"%s_%s.png"%(name,vn)))
        im.colorspace_settings.name='Non-Color'
        a = np.array(im.pixels[:],dtype=np.float32).reshape(RES,RES,4)
        a = a[::-1]  # blender pixels are bottom-up
        sheet[r*RES:(r+1)*RES, c*RES:(c+1)*RES] = a
        bpy.data.images.remove(im)
# flat grey behind so transparent regions read
bg = np.array([0.16,0.17,0.19,1.0],dtype=np.float32)
al = sheet[:,:,3:4]
comp = sheet[:,:,:4]*al + bg*(1-al)
comp[:,:,3]=1.0
out = bpy.data.images.new("sheet", width=sheet.shape[1], height=sheet.shape[0], alpha=True)
out.colorspace_settings.name='Non-Color'
out.pixels = comp[::-1].ravel().tolist()
out.filepath_raw = os.path.join(OUTDIR,"_sheet_alone.png")
out.file_format='PNG'
out.save()
report["_sheet"] = os.path.join(OUTDIR,"_sheet_alone.png")
report["_sheet_cols"] = cols
report["_sheet_rows"] = NAMES
blanks = [ (n,v) for n,d in report.items() if isinstance(d,dict) and "views" in d for v,x in d["views"].items() if x["opaque"]==0 ]
clipped = [ (n,v,x["border_alpha"]) for n,d in report.items() if isinstance(d,dict) and "views" in d for v,x in d["views"].items() if x["border_alpha"]>0.02 ]
report["_blanks"]=blanks; report["_border_clips"]=clipped
with open(os.path.join(OUTDIR,"_probe.json"),"w") as f: json.dump(report,f,indent=1)
print("BLANKS",blanks); print("CLIPS",clipped); print("DONE")
