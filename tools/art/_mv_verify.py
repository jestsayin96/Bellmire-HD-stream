"""_mv_verify.py - RE-OPEN THE SHIPPED GLB AND MEASURE WHAT IS ACTUALLY IN IT.

The export printed "More than one shader node tex image used for a texture.
The resulting glTF sampler will behave like the first shader node tex image."
The register says the red map was swapped in; that is a statement about the
Blender scene, NOT about the file on disk. This asks the file.
  blender -b -noaudio -P tools/art/_mv_verify.py -- <glb> <out.json>
"""
import bpy, sys, os, json
import numpy as np

argv = sys.argv[sys.argv.index("--") + 1:]
glb, outp = argv[0], argv[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)

def mean(img):
    w, h = img.size
    a = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(a)
    a = a.reshape(h, w, 4)
    m = a[..., 3] > 0.5
    return ([round(float(x), 4) for x in a[..., :3][m].mean(axis=0)] if m.any() else None)

rep = {"glb": glb, "bytes": os.path.getsize(glb), "objects": [], "images": [], "base": []}
for o in bpy.data.objects:
    rep["objects"].append(dict(name=o.name, type=o.type,
                               parent=(o.parent.name if o.parent else None)))
for im in bpy.data.images:
    im.colorspace_settings.name = 'Non-Color'
    rep["images"].append(dict(name=im.name, size=list(im.size), mean=mean(im)))
for m in bpy.data.materials:
    if not m.node_tree:
        continue
    for n in m.node_tree.nodes:
        if n.type == 'TEX_IMAGE' and n.image is not None:
            links = [l.to_node.type for l in n.outputs[0].links]
            rep["base"].append(dict(mat=m.name, node=n.name, img=n.image.name,
                                    size=list(n.image.size), mean=mean(n.image),
                                    to=links))
with open(outp, "w") as f:
    json.dump(rep, f, indent=1)
print("MV_VERIFY_OK")
