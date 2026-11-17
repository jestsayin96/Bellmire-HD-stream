
import os,sys,json,math
import bpy
from mathutils import Vector
sys.path.append(os.path.join(r"C:\hd adventure\bellmire-art","tools","art"))
import lordgen as G, e3pogen as EG, showcasegen as SG, showcase as SC, icons as IC
import d94proof as P
repo = r"C:\hd adventure\bellmire-art"
items = SG.load_items(repo)
rows = P.acc_rows(items)
row = [r for r in rows if r["slot"]=="gloves"][0]
out = {"anchor_y": None, "cells": []}
for cell in row["cells"]:
    cell["view"] = "front"
    fp = os.path.join(repo,"renders","art","_g6tmp_full.png")
    dp = os.path.join(repo,"renders","art","_g6tmp_det.png")
    rec = P.build_cell(repo, cell, 200, 280, fp, dp)
    # after build_cell the scene still holds body+item
    arm = next((o for o in bpy.context.scene.objects if o.type=='ARMATURE'), None)
    anc = {}
    if arm:
        for bn in ("hand.l","hand.r","wrist.l","lowerarm.l","spine","chest"):
            b = arm.pose.bones.get(bn) or arm.data.bones.get(bn)
            if b is not None:
                try: p = arm.matrix_world @ arm.pose.bones[bn].head
                except Exception: p = arm.matrix_world @ arm.data.bones[bn].head_local
                anc[bn] = [round(v,4) for v in p]
    gl = [o for o in bpy.context.scene.objects if o.type=='MESH' and "Glove" in o.name]
    gi = []
    for o in gl:
        dg = bpy.context.evaluated_depsgraph_get()
        me = o.evaluated_get(dg).to_mesh()
        ws = [o.matrix_world @ v.co for v in me.vertices]
        o.evaluated_get(dg).to_mesh_clear()
        if not ws: continue
        cz = sum(v.z for v in ws)/len(ws)
        gi.append({"name":o.name,"cz":round(cz,4),
                   "zmin":round(min(v.z for v in ws),4),
                   "zmax":round(max(v.z for v in ws),4),
                   "cx":round(sum(v.x for v in ws)/len(ws),4),
                   "width_x":round(max(v.x for v in ws)-min(v.x for v in ws),4)})
    out["cells"].append({"key":cell["key"],"cost":cell["cost"],"anchors":anc,"gloves":gi,
                         "fit":[{k:f[k] for k in ("part","inside_pct","penetration_m")} for f in rec["fit"]]})
open(os.path.join(repo,"renders","art","_g6_place.json"),"w").write(json.dumps(out,indent=1))
print("G6PLACE_DONE")
