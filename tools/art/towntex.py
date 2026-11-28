"""towntex - PUT THE TEXTURES BACK ON THE TOWN'S BUILDINGS.

  blender -b -noaudio -P tools/art/towntex.py -- --repo <repo> [--only lm_hall.glb]
                                                 [--px 1024] [--write]

THE DEFECT, MEASURED ON 28 NOV 2026 ~02:0x CT, NOT REMEMBERED
-------------------------------------------------------------
Every one of the twelve pack-derived buildings in `assets/buildings/` carries
**ZERO images and ZERO base-colour links**; all their materials sit at
Blender's default grey (0.8, 0.8, 0.8). Audited file by file, not sampled:

    lm_barracks 51 mats / 0 linked      mk_house_a 39 / 0
    lm_chapel   50 / 0                  mk_house_b 42 / 0
    lm_granary  29 / 0                  mk_house_c 44 / 0
    lm_hall     49 / 0                  mk_house_d 44 / 0
    lm_sawmill  28 / 0                  lm_watermill 41 / 0
    lm_windmill 21 / 0                  lm_workshop  45 / 0

They were exported on 15 Nov from the Medieval Village MegaKit with the
textures stripped. On stream the whole town therefore reads as untextured
grey, which is the exact opposite of Mr. E's binding principle - people want
to see what they pay for.

*** THE THREE WELLS ARE NOT PART OF THIS AND MUST NOT BE "FIXED". *** A first
cut of the audit flagged `town_well_t1/t2/t3` too, because they also report
zero images. THAT FLAG WAS WRONG AND IT WOULD HAVE LIBELLED GOOD WORK: the
wells are SOLID-COLOUR meshes built by `lordlib.mat_solid`, whose colour lives
in the Base Color default_value, not in a texture. The honest test is not
"has images" but "is the base colour still default grey AND unlinked", and
that is the test this tool applies. A gate that cannot tell a painted material
from an unpainted one is not a gate.

WHY THIS IS A RELINK AND NOT A REPAINT - AND WHY IT IS EXACT
------------------------------------------------------------
Nothing is invented here. The stripped export kept two things that make the
original recoverable:
  1. **The UVs are intact** - 225/225 meshes in lm_hall carry a `UVMap` inside
     0..1. Measured, because relinking textures over missing UVs produces
     garbage and I would not have been able to see it in a thumbnail.
  2. **The material NAMES survived**, suffixed by Blender's import
     de-duplicator: `MI_Plaster.011`, `MI_Brick.004`. Strip the `.NNN` and
     every one of them is a real material in the pack.
So this tool harvests the NINE REAL MATERIAL DATABLOCKS from the pack's own
glTF files - whole node graphs, authored by Quaternius, not reconstructed by
me - and reassigns them by name. The derivation is reproducible from this file
alone, which is the standard the tier-5 spear set.

SOURCE MODULES, chosen so the nine are covered with no guessing:
    Wall_Plaster_Door_Round ....... MI_Plaster, MI_RockTrim, MI_WoodTrim
    Wall_UnevenBrick_Straight ..... MI_UnevenBrick
    Wall_Plaster_Window_Wide_Round  MI_Brick
    Roof_Tower_RoundTiles ......... MI_RoundTiles, MI_MetalOrnaments
    Roof_Wooden_2x1 ............... MI_WoodTrim_Wear
    Door_1_Round .................. MI_WindowGlass
MI_WoodTrim_Wear and MI_WindowGlass were each CHECKED against the module that
uses them rather than assumed: the wear material resolves to the T_WoodTrim_*
set (the pack ships no T_WoodTrim_Wear map), and the glass material carries no
texture at all. Neither was invented.

LICENCE: Medieval Village MegaKit [Standard], Quaternius, CC0 1.0 Universal,
licence read off disk and recorded in docs/art/ASSET_SOURCES.md line ~703. The
buildings were already derived from this pack on 15 Nov; this run restores the
pack's own textures to them and introduces no new source.

SIZE, AND THE ONE REAL TRADE - MEASURED TWICE, BECAUSE MY FIRST ANSWER WAS BAD
------------------------------------------------------------------------------
The pack's maps are 2048 and total 51.58 MB. Embedding every map in every
building duplicates them twelve times over, so maps must be cut. MY FIRST CUT
WAS NOT ENOUGH AND THE FILE SIZE CAUGHT IT: dropping normals and downscaling
to 1024 still shipped 14 images and took lm_hall from 1.0 MB to **28.1 MB**.
Every gate was GREEN over that - no gate I had asks "is this file sane to
commit". Twelve of those is 336 MB of repo for one visual fix. So:
  - **BASE COLOUR ONLY.** Normal and roughness/ORM maps are dropped.
  - Roughness and metallic are NOT guessed when their map goes: the map's own
    channel MEAN is measured and written into the material as a constant, so
    the surface keeps roughly the finish Quaternius gave it.
  - Base colour is exported as **JPEG** at --px (default 1024). All seven
    textured materials here are opaque, so nothing needs an alpha channel;
    the one material that would (T_VineLeaf) is not used by these buildings.
This is a deliberate trade, stated so the next seat can reverse it: pass
--px 2048 and restore the normal branch if these ever carry a close-up.

THE GATE, AND WHAT IT CANNOT SEE
---------------------------------
After export the file is RE-IMPORTED FROM DISK and checked:
  1. images > 0 and every material's Base Color is LINKED - RED ON EMPTY: a
     file with zero materials passes a "share of materials linked" test
     vacuously, so zero materials is itself RED.
  2. triangle count unchanged - a relink that silently drops geometry is a
     worse bug than the grey it fixed.
  3. every UV layer still present.
WHAT IT CANNOT SEE: whether the texture landed the RIGHT WAY UP or on the
RIGHT SURFACE. A plaster map on a roof passes all three. Only looking at the
render answers that, so this tool is never run without `_hallook`-style
renders afterwards, and the summary says what was seen.
"""
import argparse, json, os, sys

import bpy

W5 = r"C:\hd adventure\bellmire-art"
PACK = (r"C:\hd adventure\_packs\Medieval_Village_MegaKit"
        r"\Medieval Village MegaKit[Standard]\glTF")

# module -> the materials harvested from it. Checked, not assumed.
SOURCES = {
    "Wall_Plaster_Door_Round":       ("MI_Plaster", "MI_RockTrim", "MI_WoodTrim"),
    "Wall_UnevenBrick_Straight":     ("MI_UnevenBrick",),
    "Wall_Plaster_Window_Wide_Round": ("MI_Brick",),
    "Roof_Tower_RoundTiles":         ("MI_RoundTiles", "MI_MetalOrnaments"),
    "Roof_Wooden_2x1":               ("MI_WoodTrim_Wear",),
    "Door_1_Round":                  ("MI_WindowGlass",),
}
WANTED = sorted({m for v in SOURCES.values() for m in v})
# Branches dropped on purpose - see the docstring; a size trade, not an
# oversight. Roughness and Metallic are measured to a constant before they go.
DROP_INPUTS = ("Normal",)
FLATTEN_INPUTS = ("Roughness", "Metallic", "Specular IOR Level", "Alpha")


def base_name(n):
    """`MI_Plaster.011` -> `MI_Plaster`. Blender's import de-duplicator only
    ever appends `.NNN`, so splitting on the last dot is safe here; a material
    legitimately containing a dot would break it and the pack has none."""
    head = n.rsplit(".", 1)
    if len(head) == 2 and head[1].isdigit() and len(head[1]) == 3:
        return head[0]
    return n


def _channel_mean(sock):
    """Mean of the exact channel feeding this socket, read off the pixels.

    ORM maps pack Occlusion/Roughness/Metallic into R/G/B, so a socket fed
    through a Separate Color node must be averaged over ITS OWN channel - the
    whole-image mean would hand a roughness slot the occlusion map's average.
    Returns None rather than a made-up number when the chain is not one this
    understands; the caller then leaves the material's own default alone."""
    link = sock.links[0]
    node, out = link.from_node, link.from_socket
    chan = None
    if node.type in ('SEPARATE_COLOR', 'SEPRGB'):
        chan = {'Red': 0, 'Green': 1, 'Blue': 2}.get(out.name)
        if chan is None or not node.inputs[0].is_linked:
            return None
        node = node.inputs[0].links[0].from_node
    if node.type != 'TEX_IMAGE' or node.image is None or not node.image.has_data:
        return None
    img = node.image
    w, h = img.size
    if w == 0 or h == 0:
        return None
    px = list(img.pixels)
    if chan is None:
        chan = 0
    vals = px[chan::4]
    if not vals:
        return None
    return float(sum(vals) / len(vals))


def harvest(px):
    """Import the source modules and keep their real material datablocks."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    got = {}
    for mod, names in SOURCES.items():
        p = os.path.join(PACK, mod + ".gltf")
        if not os.path.isfile(p):
            raise SystemExit("MISSING SOURCE MODULE: %s" % p)
        bpy.ops.import_scene.gltf(filepath=p)
        for n in names:
            m = bpy.data.materials.get(n)
            if m is None:
                raise SystemExit("MISSING MATERIAL %s in %s" % (n, mod))
            m.use_fake_user = True
            got[n] = m
    missing = [n for n in WANTED if n not in got]
    if missing:
        raise SystemExit("HARVEST INCOMPLETE: %s" % missing)
    # drop the node branches we are not shipping, then downscale what is left
    for m in got.values():
        if not m.use_nodes:
            continue
        bsdf = next((x for x in m.node_tree.nodes
                     if x.type == 'BSDF_PRINCIPLED'), None)
        if bsdf is None:
            continue
        for inp in DROP_INPUTS:
            s = bsdf.inputs.get(inp)
            if s is not None and s.is_linked:
                for lk in list(s.links):
                    m.node_tree.links.remove(lk)
        # measure, then flatten: the constant comes off the map, not off me
        for inp in FLATTEN_INPUTS:
            s = bsdf.inputs.get(inp)
            if s is None or not s.is_linked:
                continue
            val = _channel_mean(s)
            for lk in list(s.links):
                m.node_tree.links.remove(lk)
            if val is not None:
                s.default_value = val
    # prune now-orphaned image nodes so their images are not exported
    for m in got.values():
        if not m.use_nodes:
            continue
        nt = m.node_tree
        changed = True
        while changed:
            changed = False
            for n in list(nt.nodes):
                if n.type in ('OUTPUT_MATERIAL', 'BSDF_PRINCIPLED'):
                    continue
                if not any(o.is_linked for o in n.outputs):
                    nt.nodes.remove(n)
                    changed = True
    for img in bpy.data.images:
        if img.name == 'Render Result' or not img.has_data:
            continue
        w, h = img.size
        if max(w, h) > px:
            img.scale(min(w, px), min(h, px))
    return got


def remap(objs, mats):
    """Point every material slot at the harvested material of the same name."""
    used, unknown = set(), set()
    for o in objs:
        for sl in o.material_slots:
            if sl.material is None:
                continue
            bn = base_name(sl.material.name)
            if bn in mats:
                sl.material = mats[bn]
                used.add(bn)
            else:
                unknown.add(sl.material.name)
    return used, unknown


def tri_uv(objs):
    return (sum(len(o.data.polygons) for o in objs),
            sum(1 for o in objs if len(o.data.uv_layers) > 0), len(objs))


def verify(path):
    """Re-import FROM DISK. Nothing is trusted from the session that wrote it."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    objs = [o for o in bpy.data.objects if o.type == 'MESH']
    imgs = [i for i in bpy.data.images if i.name != 'Render Result']
    linked = tot = 0
    grey = []
    for m in bpy.data.materials:
        if not m.use_nodes:
            continue
        b = next((x for x in m.node_tree.nodes
                  if x.type == 'BSDF_PRINCIPLED'), None)
        if b is None:
            continue
        tot += 1
        bc = b.inputs['Base Color']
        if bc.is_linked:
            linked += 1
        else:
            v = [round(x, 3) for x in bc.default_value]
            if v[:3] == [0.8, 0.8, 0.8]:
                grey.append(m.name)
    tris, uvd, nobj = tri_uv(objs)
    return {"n_images": len(imgs), "n_mat": tot, "base_linked": linked,
            "default_grey_mats": grey[:8], "n_default_grey": len(grey),
            "n_tri": tris, "n_mesh": nobj, "n_mesh_with_uv": uvd,
            "bytes": os.path.getsize(path)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=W5)
    ap.add_argument("--only", default="")
    ap.add_argument("--px", type=int, default=1024)
    ap.add_argument("--write", action="store_true")
    a = ap.parse_args(sys.argv[sys.argv.index("--") + 1:])
    bd = os.path.join(a.repo, "assets", "buildings")
    targets = ([a.only] if a.only else
               sorted(f for f in os.listdir(bd)
                      if f.endswith(".glb") and not f.startswith("town_well_")))
    report = {"px": a.px, "wrote": bool(a.write), "files": {}, "errors": []}

    for fn in targets:
        src = os.path.join(bd, fn)
        mats = harvest(a.px)                      # fresh per file: clean session
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=src)
        objs = [o for o in bpy.data.objects
                if o not in before and o.type == 'MESH']
        pre_tris, pre_uv, pre_n = tri_uv(objs)
        pre_slots = len({sl.material.name for o in objs
                         for sl in o.material_slots if sl.material})
        used, unknown = remap(objs, mats)
        row = {"pre": {"n_tri": pre_tris, "n_mesh": pre_n,
                       "n_mesh_with_uv": pre_uv, "n_mat_slots": pre_slots},
               "mats_used": sorted(used), "unknown_mats": sorted(unknown),
               "src_bytes": os.path.getsize(src)}
        if unknown:
            report["errors"].append("%s UNKNOWN MATERIALS %s" % (fn, sorted(unknown)))
        if a.write:
            for o in bpy.data.objects:
                o.select_set(o in objs)
            bpy.context.view_layer.objects.active = objs[0] if objs else None
            bpy.ops.export_scene.gltf(
                filepath=src, export_format='GLB', use_selection=True,
                export_materials='EXPORT', export_image_format='JPEG',
                export_jpeg_quality=90, export_yup=True)
            row["post"] = verify(src)
            p = row["post"]
            if p["n_images"] == 0:
                report["errors"].append("%s STILL NO IMAGES" % fn)
            if p["n_mat"] == 0:
                report["errors"].append("%s RED ON EMPTY: zero materials" % fn)
            elif p["base_linked"] < p["n_mat"] - 1:   # glass legitimately plain
                report["errors"].append(
                    "%s ONLY %d/%d BASE COLOURS LINKED"
                    % (fn, p["base_linked"], p["n_mat"]))
            if p["n_tri"] != pre_tris:
                report["errors"].append(
                    "%s GEOMETRY CHANGED %d -> %d" % (fn, pre_tris, p["n_tri"]))
            if p["n_mesh_with_uv"] != p["n_mesh"]:
                report["errors"].append("%s LOST UVs" % fn)
        report["files"][fn] = row

    report["verdict"] = "GREEN" if not report["errors"] else "RED"
    dest = os.path.join(a.repo, "renders", "art", "town", "_texfix.json")
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with open(dest, "w") as f:
        json.dump(report, f, indent=1)
    print("TOWNTEX " + json.dumps(report))


main()
