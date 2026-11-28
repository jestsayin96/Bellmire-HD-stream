
import json, os
import bpy
from mathutils import Vector
PACK = r"C:\hd adventure\_packs\Medieval_Village_MegaKit\Medieval Village MegaKit[Standard]\glTF"
W5 = r"C:\hd adventure\bellmire-art"
PICK = ["Roof_Wooden_2x1","Roof_Wooden_2x1_Center","Roof_Wooden_2x1_Center_Mirror",
        "Roof_Wooden_2x1_Corner","Roof_Wooden_2x1_L","Roof_Wooden_2x1_Middle","Roof_Wooden_2x1_R",
        "Roof_RoundTiles_4x4","Roof_RoundTiles_6x6","Roof_RoundTiles_8x8","Roof_RoundTiles_6x10",
        "Wall_Plaster_WoodGrid","Wall_Plaster_Straight_Base","Wall_UnevenBrick_Door_Round",
        "Wall_UnevenBrick_Window_Wide_Round","Wall_Plaster_Window_Thin_Round",
        "Corner_Exterior_Wood","Corner_ExteriorWide_Brick","Prop_ExteriorBorder_Straight1",
        "Prop_Brick1","Prop_Crate","Prop_Vine1","Stairs_Exterior_Sides","Roof_Dormer_RoundTile",
        "Roof_FrontSupports","Roof_Support2","Balcony_Simple_Straight","Door_2_Round","Door_4_Round"]
def meas(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    bpy.context.view_layer.update()
    ms = [o for o in bpy.data.objects if o.type == 'MESH']
    pts = [o.matrix_world @ Vector(c) for o in ms for c in o.bound_box]
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return {"n_tri": sum(len(o.data.polygons) for o in ms),
            "dims": [round(v,4) for v in (mx.x-mn.x, mx.y-mn.y, mx.z-mn.z)],
            "min": [round(mn.x,4), round(mn.y,4), round(mn.z,4)],
            "max": [round(mx.x,4), round(mx.y,4), round(mx.z,4)],
            "mats": sorted({m.name for o in ms for m in o.data.materials if m})}
out = {"modules": {}, "existing": {}}
for n in PICK:
    p = os.path.join(PACK, n + ".gltf")
    if os.path.isfile(p):
        try: out["modules"][n] = meas(p)
        except Exception as e: out["modules"][n] = {"error": repr(e)[:200]}
    else:
        out["modules"][n] = {"error": "missing"}
for n in ("lm_hall.glb","lm_chapel.glb","town_well_t3.glb"):
    p = os.path.join(W5, "assets", "buildings", n)
    if os.path.isfile(p):
        try: out["existing"][n] = meas(p)
        except Exception as e: out["existing"][n] = {"error": repr(e)[:200]}
dest = os.path.join(W5, "renders", "art", "town", "_probe", "_megakit_modules2.json")
os.makedirs(os.path.dirname(dest), exist_ok=True)
json.dump(out, open(dest,"w"), indent=1)
print("MODPROBE2 OK")
