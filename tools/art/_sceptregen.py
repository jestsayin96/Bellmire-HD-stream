"""_sceptregen - AUTHOR THE TIER-5 SCEPTRE. There is no sceptre mesh in this game.

  blender -b -noaudio -P tools/art/_sceptregen.py -- --repo <repo>

WHY IT IS AUTHORED AND NOT SOURCED. Measured this run, not remembered:
  - `origin/main:scripts/gear.gd:222`
      "sceptre": {"family":"arcane", "noun":"mace",
                  "kit":[KIT+"hammer_A.gltf", KIT+"hammer_A.gltf",
                         KIT+"hammer_B.gltf", KIT+"hammer_B.gltf",
                         KIT+"hammer_B.gltf"]}
    Tiers 3, 4 AND 5 are the SAME `hammer_B.gltf` at the same scale and the
    same rotation. A viewer who spends months of points on a legendary sceptre
    is handed the uncommon one. Compare `mace` on the line above - same noun,
    family axe - which ends at `ART + "hammer_double_golden.glb"`. The arcane
    half of the same weapon never got its ladder.
  - `git grep -i -e sceptre -e scepter origin/main -- assets scripts` finds
    the word in gear.gd and three chatcmd comments. NO MESH, anywhere.
  - `assets/gear/artifact/` holds seven golden meshes (sword, big sword,
    dagger, small axe, double axe, double hammer, bow). No sceptre.
  - `C:\\hd adventure\\_packs` (97 top-level entries) walked for
    scept/mace/rod/orb/crown/club: 30 hits, and NOT ONE is a sceptre - three
    KayKit staves, two Quaternius mage staves, one Club.obj, two crowns, and
    eighteen village border props the word "rod" matched by accident.
    THE PACKS DO NOT SERVE THIS. So it is authored.

THE DESIGN, AGAINST MR. E'S THREE RULES.
  PLAINNESS: it is a mace you could hit with and a token of office, in that
  order. Cast collars, an octagonal shaft, blunt flanges. No filigree.
  WEAR IS A RECEIPT: tier 5, so the gold is POLISHED (metallic 1.0, roughness
  0.22) and new, and the stone is bright. Nothing second-hand.
  READS AT STREAM DISTANCE: the head is RADIALLY SYMMETRIC - six flanges and
  six crown points around the axis. That is deliberate and it is the answer to
  the wand's fault: the wand's crystal read front and back and vanished side
  on, because its silhouette depended on which way the head faced. A mace head
  has no front, so there is no angle that can hide it. WHAT THAT COSTS, SAID
  OUT LOUD: there is no front-facing detail to catch the eye, so the stone at
  the apex carries the read on its own.

SCALE, DERIVED NOT GUESSED. `hand_scale()` (gear.gd:295-320) has no arm for
this path and falls through `begins_with(ART)` to 0.6, so the mesh is authored
at 2.00 units and lands at 1.20 m in a hand whose slot sits at z 0.64 on a
2.45 m hero. 1.07 m of that is ABOVE the fist - clear of the torso and well
below the 2.45 m crown, which is the length the wand did not have.
"""
import os
import sys
import math
import argparse

import bpy
import bmesh
from mathutils import Matrix, Vector

NAME = "sceptre_golden"
OUT = os.path.join("assets", "gear", "artifact", NAME + ".glb")

# PASS 2, AND BOTH NUMBERS CAME OFF A CONTROL I DID NOT HAVE IN PASS 1.
# `tools/art/_goldcontrol.py` rendered the SHIPPED `sword_golden` and
# `hammer_double_golden` through this exact rig and measured the pixels they
# ADD to the frame: mean luma 0.240/0.242, 90th-percentile luma 0.385/0.421.
# Pass 1 of this sceptre measured mean 0.200 and p90 0.200 - THE SAME NUMBER,
# which is the tell: a metal with metallic 1.0 and no environment to reflect
# has no highlight at all, so it reads as a flat dark stick however bright its
# base colour is. The shipped set is bright BECAUSE it is barely metallic.
GOLD = (0.95, 0.76, 0.30, 1.0)
LEATH = (0.20, 0.14, 0.10, 1.0)
# PASS 3, AND THE PICTURE IS WHY. At emission 1.20 the stone rendered as a
# WHITE cap in all three views - the one colour accent on the piece, washed
# out of it. The numbers were all green through that: a blown highlight is
# bright, and brightness is what p90_luma measures. Saturated and dimmed so
# the stone reads BLUE, which is what a viewer is paying for.
STONE = (0.30, 0.58, 1.00, 1.0)


def cone(bm, r1, r2, z0, z1, seg=8, mat=0, rotz=0.0):
    """A capped cone/cylinder along +Z between z0 and z1, material index mat."""
    d = z1 - z0
    kw = dict(cap_ends=True, cap_tris=False, segments=seg, depth=d,
              matrix=Matrix.Translation((0, 0, z0 + d / 2.0))
              @ Matrix.Rotation(rotz, 4, 'Z'))
    try:
        res = bmesh.ops.create_cone(bm, radius1=r1, radius2=r2, **kw)
    except TypeError:                    # older bmesh API
        res = bmesh.ops.create_cone(bm, diameter1=r1 * 2, diameter2=r2 * 2, **kw)
    _tag(bm, res["verts"], mat)
    return res


def box(bm, sx, sy, sz, loc, rotz=0.0, mat=0):
    res = bmesh.ops.create_cube(bm, size=1.0,
                                matrix=Matrix.Translation(loc)
                                @ Matrix.Rotation(rotz, 4, 'Z')
                                @ Matrix.Diagonal((sx, sy, sz, 1.0)))
    _tag(bm, res["verts"], mat)
    return res


def ico(bm, r, loc, mat=0, sub=1, flat=1.0):
    kw = dict(subdivisions=sub,
              matrix=Matrix.Translation(loc) @ Matrix.Diagonal((1, 1, flat, 1)))
    try:
        res = bmesh.ops.create_icosphere(bm, radius=r, **kw)
    except TypeError:
        res = bmesh.ops.create_icosphere(bm, diameter=r * 2, **kw)
    _tag(bm, res["verts"], mat)
    return res


def _tag(bm, verts, mat):
    """Material index onto every face touched only by these new verts."""
    vs = set(verts)
    for f in bm.faces:
        if all(v in vs for v in f.verts):
            f.material_index = mat


def build():
    bm = bmesh.new()
    # 0 gold, 1 leather, 2 stone  (slot order set below)
    # --- butt and grip -------------------------------------------------
    ico(bm, 0.098, (0, 0, -0.15), mat=0, sub=1, flat=0.8)      # pommel
    cone(bm, 0.068, 0.066, -0.10, 0.20, seg=8, mat=1)          # wrapped grip
    for z in (-0.04, 0.03, 0.10, 0.17):                        # the wrap ribs
        cone(bm, 0.074, 0.074, z, z + 0.020, seg=8, mat=1)
    cone(bm, 0.110, 0.090, 0.20, 0.29, seg=8, mat=0)           # lower collar
    # --- shaft ---------------------------------------------------------
    cone(bm, 0.075, 0.064, 0.29, 1.28, seg=8, mat=0)
    cone(bm, 0.096, 0.096, 0.73, 0.77, seg=8, mat=0)           # mid band
    cone(bm, 0.090, 0.120, 1.28, 1.37, seg=8, mat=0)           # upper collar
    # --- mace head: a drum with six blunt flanges ----------------------
    cone(bm, 0.155, 0.155, 1.37, 1.64, seg=12, mat=0)
    for i in range(6):
        a = i * math.pi / 3.0
        box(bm, 0.27, 0.085, 0.215, (0.105 * math.cos(a), 0.105 * math.sin(a), 1.505),
            rotz=a, mat=0)
    cone(bm, 0.155, 0.105, 1.64, 1.70, seg=12, mat=0)
    # --- crown of six points holding the stone -------------------------
    for i in range(6):
        a = i * math.pi / 3.0 + math.pi / 6.0
        r = 0.090
        res = cone(bm, 0.036, 0.012, 1.68, 1.83, seg=5, mat=0)
        bmesh.ops.translate(bm, verts=res["verts"],
                            vec=(r * math.cos(a), r * math.sin(a), 0))
        bmesh.ops.rotate(bm, verts=res["verts"],
                         cent=(r * math.cos(a), r * math.sin(a), 1.68),
                         matrix=Matrix.Rotation(math.radians(16), 3,
                                                Vector((-math.sin(a), math.cos(a), 0))))
    ico(bm, 0.108, (0, 0, 1.78), mat=2, sub=1, flat=1.15)      # the stone
    # NO FINAL ROTATION, AND PASS 1 OF THIS FILE GOT IT WRONG. I read gear.gd's
    # comment "the _Golden set is built along +Y with the grip at the origin",
    # turned the mesh onto +Y, and asserted that axis - so my own gate enforced
    # the mistake. THE MEASUREMENT (tools/art/_sceptre_axis_probe.py) says the
    # comment is in the glTF/Godot frame, not the frame these scripts work in:
    # imported into Blender, sword_golden spans z 2.302 (x 0.534, y 0.122),
    # staff_rare z 1.162, wand_crystal z 0.921. EVERY SHIPPED WEAPON'S LONG
    # AXIS IS BLENDER +Z. A note's wording is not a measurement.
    me = bpy.data.meshes.new(NAME)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(NAME, me)
    for nm, col, metal, rough, emit in (
            ("sceptre_gold", GOLD, 0.30, 0.35, 0.0),
            ("sceptre_grip", LEATH, 0.0, 0.80, 0.0),
            ("sceptre_stone", STONE, 0.0, 0.10, 0.45)):
        m = bpy.data.materials.new(nm)
        m.use_nodes = True
        b = m.node_tree.nodes["Principled BSDF"]
        b.inputs["Base Color"].default_value = col
        b.inputs["Metallic"].default_value = metal
        b.inputs["Roughness"].default_value = rough
        if emit:
            b.inputs["Emission Color"].default_value = col
            b.inputs["Emission Strength"].default_value = emit
        me.materials.append(m)
    bpy.context.collection.objects.link(ob)
    me.shade_smooth() if hasattr(me, "shade_smooth") else None
    for p in me.polygons:
        p.use_smooth = False
    return ob


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    a = ap.parse_args(argv)
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    ob = build()
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    ev = ob.evaluated_get(dg)
    pts = [ob.matrix_world @ Vector(c) for c in ev.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    # RED ON EMPTY and RED ON WRONG AXIS - a mesh that is not built along +Y
    # with the grip near the origin is not this convention and must not ship.
    assert len(ob.data.vertices) > 100, "no geometry built"
    span = hi - lo
    # The gate now asks the measured question: +Z long, grip at the origin, the
    # same shape sword_golden has (z -0.383 .. 1.919).
    if not (span.z > span.x * 3 and span.z > span.y * 3):
        raise SystemExit("SCEPTREGEN FAIL - long axis is not +Z: span %s" % (span,))
    if lo.z < -0.30 or lo.z > -0.05:
        raise SystemExit("SCEPTREGEN FAIL - grip is not at the origin: min z %.3f" % lo.z)
    dst = os.path.join(a.repo, OUT)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    # EXPORT WITH THE DEFAULT Y-UP CONVERSION, AND THE REASON MATTERS.
    # Blender writes (x, z, -y) and `import_scene.gltf` reads back (x, -z, y),
    # so a mesh built along Blender +Y round-trips to Blender +Y - which is the
    # axis the golden set measures at, and therefore the axis every held_rot
    # number in gear.gd was solved against. Exporting with export_yup=False
    # would land the shaft on Blender +Z on reimport and make the SAME rotation
    # numbers mean something else.
    bpy.ops.export_scene.gltf(filepath=dst, export_format='GLB',
                              use_selection=True, export_apply=True)
    print("SCEPTREGEN OK verts=%d tris=%d len_y=%.3f miny=%.3f maxy=%.3f "
          "wide=%.3f bytes=%d" % (len(ob.data.vertices), len(ob.data.polygons),
                                  span.z, lo.z, hi.z, max(span.x, span.y),
                                  os.path.getsize(dst)))


if __name__ == "__main__":
    main()
