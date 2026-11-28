
import json, os
import bpy
W5 = r"C:\hd adventure\bellmire-art"
bd = os.path.join(W5, "assets", "buildings")
out = {}
for n in ("lm_hall.glb","lm_windmill.glb","mk_house_a.glb"):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(bd,n))
    ms = [o for o in bpy.data.objects if o.type=='MESH']
    withuv = [o for o in ms if len(o.data.uv_layers) > 0]
    spans = []
    for o in withuv[:5]:
        uv = o.data.uv_layers[0].data
        us = [d.uv[0] for d in uv]; vs = [d.uv[1] for d in uv]
        spans.append({"obj": o.name, "layer": o.data.uv_layers[0].name,
                      "u": [round(min(us),3), round(max(us),3)],
                      "v": [round(min(vs),3), round(max(vs),3)], "n": len(uv)})
    # material names stripped
    names = sorted({m.name.split(".")[0] for o in ms for m in o.data.materials if m})
    out[n] = {"n_mesh": len(ms), "n_with_uv": len(withuv), "spans": spans,
              "base_mat_names": names}
dest = os.path.join(W5,"renders","art","town","_probe","_uvcheck.json")
json.dump(out, open(dest,"w"), indent=1)
print("UVCHECK " + json.dumps(out)[:3000])
