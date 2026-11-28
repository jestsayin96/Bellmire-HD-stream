"""_speargen - THE TIER-5 SPEAR, BUILT FROM THE PACK AND NOT AUTHORED.

  blender -b -noaudio -P tools/art/_speargen.py -- --repo <repo> [--langets 1]

WHY IT IS SOURCED AND NOT AUTHORED, WHICH IS THE OPPOSITE OF THE SCEPTRE.
Measured this run, not remembered:
  - `scripts/gear.gd:213`
      "spear": {"family":"blade", "noun":"spear",
                "kit":[KIT+"spear_A.gltf", KIT+"spear_A.gltf",
                       KIT+"halberd.gltf", KIT+"halberd.gltf",
                       KIT+"halberd.gltf"]}
    Tiers 3, 4 AND 5 are the SAME `halberd.gltf`. Identical mesh, identical
    scale. A viewer who spends months of points on a legendary spear is handed
    the rare one. It is the sceptre's defect exactly, one row up the file.
  - `assets/gear/artifact/` holds EIGHT golden meshes now (sword, big sword,
    dagger, small axe, double axe, double hammer, bow, and last hour's
    sceptre). No spear.
  - THE PACKS DO SERVE THIS ONE, and that is why this file is a transform and
    not a bmesh author. `C:\\hd adventure\\_packs` walked for
    spear/pike/lance/javelin/glaive/halberd/trident/polearm: 18 hits over
    10,172 files, of which 13 are floor spikes and 5 are real spears -
    `quaternius_medieval_weapons_2018_CC0` (1,202 tris, 4 materials) and
    `medieval_pack_CC0` (196 tris, 1 material). The Quaternius one is the
    better mesh by an order of magnitude in material separation.
  - LICENCE, AND IT IS NOT TAKEN FROM THE FOLDER NAME. `docs/art/ASSET_SOURCES.md`
    row 15 records Medieval Weapons Pack (Sept 2018), Quaternius, **CC0 1.0**,
    opengameart.org/content/lowpoly-medieval-weapons, and the System 8 entry
    records that this same pack's five shields already SHIPPED into
    `assets/gear/shields/` with `LICENSE_Quaternius_MedievalWeapons_CC0.txt`
    written beside them because the extracted pack carries no licence file.
    So the pack is cleared and in use; this is not its first use.

THE SUBSTITUTION IS QUATERNIUS' OWN AND I MEASURED IT RATHER THAN INVENTING IT.
`tools/art/_goldmatprobe.py` read the shipped `sword_golden.glb` and the pack's
own plain `Sword.obj` through the same importer:
    plain Sword.obj    Steel 224  LightSteel 132  DarkSteel 180  LightWood 240  DarkWood 96
    sword_golden.glb   Golden 224 LightGold  132  DarkSteel 180  LightWood 240  DarkWood 96
TRIANGLE COUNTS IDENTICAL, MATERIAL FOR MATERIAL. The golden tier of this
family IS the plain mesh with `Steel -> Golden` and `LightSteel -> LightGold`.
So the tier-5 spear is the pack spear under that same substitution: it joins a
family that already shipped, by construction, instead of being my own idea of
gold standing next to seven meshes that agree with each other.

AND THE GOLD IS THE FAMILY'S, NOT MINE - THIS IS THE SCEPTRE'S LESSON PAID OFF.
The sceptre's pass-2 note says a gold at metallic 1.0 reads as a flat dark
stick and that `_goldcontrol.py` found the shipped set bright because it is
"barely metallic". The probe says it is not barely - IT IS ZERO:
    Golden     base 0.4672 0.3365 0.0589   metallic 0.0  roughness 0.50
    LightGold  base 0.7874 0.6773 0.1896   metallic 0.0  roughness 0.50
    DarkSteel  base 0.2664 0.2664 0.2232   metallic 0.0  roughness 0.00
    DarkWood   base 0.0637 0.0324 0.0516   metallic 0.0  roughness 0.50
    LightWood  base 0.1574 0.0790 0.0849   metallic 0.0  roughness 0.50
My sceptre shipped at metallic 0.3 / roughness 0.35 on a base of my own
choosing, so it is NOT this family's gold. Said out loud because it is a
defect in my own shipped work and it is recorded in the summary, not buried.
NOTE ALSO that the golden set's wood is DARKER than the pack's plain wood
(DarkWood 0.0637 vs 0.1301, LightWood 0.1574 vs 0.1907) - the family darkened
the shaft so the gold carries the eye. The substitution takes the wood too.

SCALE AND GRIP, DERIVED OFF THE SHIPPED POLEARMS AND NOT GUESSED.
  pack Spear.obj     +Z, 9.7171 long, z -2.1552 .. +7.5619  (butt 22.2% below origin)
  SHIPPED spear_A    +Z, 3.1387 long, z -1.0322 .. +2.1066  (butt 32.9% below origin)
  SHIPPED halberd    +Z, 2.7468 long, z -0.9322 .. +1.8146  (butt 33.9% below origin)
`hand_scale()` (gear.gd:290-320) has NO arm for this path and falls through
`begins_with(ART)` to **0.60**; `spear_A` and `halberd` are KIT and take 0.62.
So to read at least as long as the common spear the mesh must be
0.62/0.60 x 3.1387 = 3.243 units, and tier 5 should be the grander one, so the
target is **3.50 units -> 2.10 m in a hand on a 2.45 m hero**, against the
common spear's 1.95 m. The origin is put at **33.0% from the butt**, which is
`spear_A`'s own proportion, so the engine's existing carry frames this the way
it already frames the mesh it ships. THAT IS THE POINT: no `held_rot` arm, no
`hand_scale` arm, NO WIRING OF ANY KIND IS NEEDED IN gear.gd.

LANGETS - NOT IN PASS 1, ON PURPOSE. The wand's fault was that its head read
front and back and vanished side-on because the silhouette depended on facing,
and a leaf blade is flat for the same reason. The fix, if the measurement asks
for it, is four radial gold langets at the socket - width from every angle,
the sceptre's radial answer. It is behind `--langets 1` so it is ONE change
measured on its own, never bundled with the substitution.
"""
import os
import sys
import math
import argparse

import bpy
import bmesh
from mathutils import Matrix, Vector

NAME = "spear_golden"
OUT = os.path.join("assets", "gear", "artifact", NAME + ".glb")

PACK = os.path.join(r"C:\hd adventure\_packs",
                    "quaternius_medieval_weapons_2018_CC0",
                    "Medieval Weapons Pack - Sept 2018", "OBJ", "Spear.obj")

# Read off the SHIPPED golden set by _goldmatprobe.py. Do not retype these from
# memory and do not round them - they are the family's identity.
FAMILY = {
    "Golden":    ((0.4672, 0.3365, 0.0589, 1.0), 0.0, 0.50),
    "LightGold": ((0.7874, 0.6773, 0.1896, 1.0), 0.0, 0.50),
    "DarkSteel": ((0.2664, 0.2664, 0.2232, 1.0), 0.0, 0.00),
    "DarkWood":  ((0.0637, 0.0324, 0.0516, 1.0), 0.0, 0.50),
    "LightWood": ((0.1574, 0.0790, 0.0849, 1.0), 0.0, 0.50),
}
# Quaternius' own golden-tier substitution, proven by identical tri counts.
SUBST = {"Steel": "Golden", "LightSteel": "LightGold"}

TARGET_LEN = 3.50      # units; -> 2.10 m at hand_scale 0.60
BUTT_FRAC = 0.330      # spear_A's own grip proportion


def mat(name):
    m = bpy.data.materials.get(name)
    if m:
        return m
    base, metal, rough = FAMILY[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = base
    b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = rough
    if "Emission Strength" in b.inputs:
        b.inputs["Emission Strength"].default_value = 0.0
    return m


def bounds(objs):
    dg = bpy.context.evaluated_depsgraph_get()
    lo = [1e9] * 3
    hi = [-1e9] * 3
    for o in objs:
        oe = o.evaluated_get(dg)
        me = oe.to_mesh()
        for v in me.vertices:
            w = oe.matrix_world @ v.co
            for i in range(3):
                lo[i] = min(lo[i], w[i])
                hi[i] = max(hi[i], w[i])
        oe.to_mesh_clear()
    return lo, hi


def add_langets(obj, z_socket, r_shaft, scale_applied):
    """Four radial gold langets + a collar at the socket. Radially symmetric so
    no viewing angle can hide the head's width - the sceptre's own answer."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    # material slot index for Golden
    names = [ms.material.name for ms in obj.material_slots]
    gi = names.index("Golden")
    li = names.index("LightGold")

    def tag(verts, idx):
        for f in {f for v in verts for f in v.link_faces}:
            f.material_index = idx

    # collar: a short octagonal band at the socket
    r = r_shaft * 1.55
    res = bmesh.ops.create_cone(bm, radius1=r, radius2=r, segments=8,
                                depth=0.085 * scale_applied, cap_ends=True,
                                cap_tris=False,
                                matrix=Matrix.Translation((0, 0, z_socket)))
    tag(res["verts"], li)
    # four langets, straps running UP the socket, 90 deg apart
    L = 0.26 * scale_applied
    W = r_shaft * 0.85
    T = r_shaft * 0.52
    for k in range(4):
        a = k * math.pi / 2.0
        res = bmesh.ops.create_cube(bm, size=1.0, matrix=(
            Matrix.Translation((math.cos(a) * r_shaft * 0.95,
                                math.sin(a) * r_shaft * 0.95,
                                z_socket + L * 0.5))
            @ Matrix.Rotation(a, 4, 'Z')
            @ Matrix.Diagonal((T, W, L, 1.0))))
        tag(res["verts"], gi)
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--langets", type=int, default=0)
    a = ap.parse_args(argv)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    if not os.path.isfile(PACK):
        raise SystemExit("SPEARGEN FAIL - pack spear missing: " + PACK)
    try:
        bpy.ops.wm.obj_import(filepath=PACK)
    except AttributeError:
        bpy.ops.import_scene.obj(filepath=PACK)

    objs = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    if len(objs) != 1:
        raise SystemExit("SPEARGEN FAIL - expected 1 mesh, got %d" % len(objs))
    ob = objs[0]
    ob.name = NAME
    ob.data.name = NAME

    # *** APPLY THE WHOLE TRANSFORM BEFORE MEASURING ANYTHING. ***
    # Trap 3's family, and it cost two runs before the assert named it. The OBJ
    # importer leaves a 90-degree X rotation ON THE OBJECT to convert Y-up to
    # Z-up, so LOCAL y is WORLD z. Every `v.co.z` edit below was therefore
    # moving the mesh along a world axis it was not meant to touch: run 1's
    # re-origin looked like a silent no-op and run 2's x/y centring moved the
    # length instead. Flattening location+rotation+scale into the mesh makes
    # local and world the same frame, which is the only state in which the
    # vertex arithmetic further down is readable.
    bpy.ops.object.select_all(action='DESELECT')
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.context.view_layer.update()

    lo0, hi0 = bounds([ob])
    if abs(ob.matrix_world.to_euler().x) > 1e-6 or tuple(ob.location) != (0.0, 0.0, 0.0):
        raise SystemExit("SPEARGEN FAIL - transform did not flatten: loc %r rot %r"
                         % (tuple(ob.location), tuple(ob.matrix_world.to_euler())))
    raw_len = hi0[2] - lo0[2]
    if raw_len <= 0:
        raise SystemExit("SPEARGEN FAIL - RED ON EMPTY: raw length %r" % raw_len)

    # --- the substitution, material for material, with a hard count check ---
    before = {}
    ob.data.calc_loop_triangles()
    slot_names = [ms.material.name if ms.material else "<none>"
                  for ms in ob.material_slots]
    for t in ob.data.loop_triangles:
        nm = slot_names[t.material_index] if t.material_index < len(slot_names) else "<oob>"
        before[nm] = before.get(nm, 0) + 1
    if not before:
        raise SystemExit("SPEARGEN FAIL - RED ON EMPTY: zero triangles measured")
    for i, ms in enumerate(ob.material_slots):
        src = ms.material.name if ms.material else None
        if src is None:
            raise SystemExit("SPEARGEN FAIL - empty material slot %d" % i)
        tgt = SUBST.get(src, src)
        if tgt not in FAMILY:
            raise SystemExit("SPEARGEN FAIL - pack material %r maps to %r which "
                             "is not in the shipped golden family %r"
                             % (src, tgt, sorted(FAMILY)))
        ms.material = mat(tgt)

    # --- scale, then re-origin the grip to spear_A's proportion ---
    s = TARGET_LEN / raw_len
    ob.scale = (s, s, s)
    bpy.context.view_layer.update()
    bpy.ops.object.select_all(action='DESELECT')
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.context.view_layer.update()

    # --- RE-ORIGIN. TWO FAULTS MY OWN FIRST RUN PRINTED, BOTH FIXED HERE. ---
    # (1) `butt_frac` came back 0.2218 against a target of 0.3300 - the vertex
    #     move had done NOTHING, because `bounds()` reads the evaluated
    #     depsgraph and I never asked the view layer to update after editing
    #     the mesh. A silent no-op that the print caught. Hence the asserts
    #     below: an instrument that cannot fail is not a pass.
    # (2) FAR WORSE AND IT WOULD HAVE SHIPPED. The first run's bounds were
    #     x -0.0791..0.1119 and **y 0.3202..0.4372** - the pack spear's shaft
    #     does NOT run up x=y=0, it is offset ~0.38 units in y. The engine
    #     attaches at the ORIGIN, so this spear would have floated 0.23 m to
    #     the side of the fist in every carry. The centre is measured off the
    #     WOOD vertices of the lower shaft, not off the whole bounds, because
    #     the blade is asymmetric and would drag the average.
    me = ob.data
    lo1, hi1 = bounds([ob])
    wood = {i for i, ms in enumerate(ob.material_slots)
            if ms.material and ms.material.name in ("DarkWood", "LightWood")}
    if not wood:
        raise SystemExit("SPEARGEN FAIL - RED ON EMPTY: no wood material slot "
                         "to measure the shaft axis from")
    me.calc_loop_triangles()
    zcut = lo1[2] + 0.45 * (hi1[2] - lo1[2])
    shaft = set()
    for t in me.loop_triangles:
        if t.material_index in wood:
            for vi in t.vertices:
                if me.vertices[vi].co.z < zcut:
                    shaft.add(vi)
    if len(shaft) < 8:
        raise SystemExit("SPEARGEN FAIL - RED ON EMPTY: %d lower-shaft wood "
                         "verts, cannot derive an axis" % len(shaft))
    cx = 0.5 * (min(me.vertices[i].co.x for i in shaft)
                + max(me.vertices[i].co.x for i in shaft))
    cy = 0.5 * (min(me.vertices[i].co.y for i in shaft)
                + max(me.vertices[i].co.y for i in shaft))
    want_lo = -TARGET_LEN * BUTT_FRAC
    dz = want_lo - lo1[2]
    for v in me.vertices:
        v.co.x -= cx
        v.co.y -= cy
        v.co.z += dz
    me.update()
    bpy.context.view_layer.update()

    lo2, hi2 = bounds([ob])
    got = -lo2[2] / (hi2[2] - lo2[2])
    if abs(got - BUTT_FRAC) > 0.005:
        raise SystemExit("SPEARGEN FAIL - butt_frac %.4f, wanted %.4f. The "
                         "re-origin did not take." % (got, BUTT_FRAC))
    # the shaft axis must now sit on x=y=0 at the grip
    gx = 0.5 * (min(me.vertices[i].co.x for i in shaft)
                + max(me.vertices[i].co.x for i in shaft))
    gy = 0.5 * (min(me.vertices[i].co.y for i in shaft)
                + max(me.vertices[i].co.y for i in shaft))
    if max(abs(gx), abs(gy)) > 1e-4:
        raise SystemExit("SPEARGEN FAIL - shaft axis still off the origin: "
                         "x %.5f y %.5f" % (gx, gy))
    print("  axis_fix     cx %+.4f cy %+.4f dz %+.4f" % (cx, cy, dz))

    if a.langets:
        # socket = where the steel starts. Measure it rather than typing it:
        # the lowest vertex carrying the Golden material.
        me.calc_loop_triangles()
        names = [ms.material.name for ms in ob.material_slots]
        gidx = {i for i, n in enumerate(names) if n in ("Golden", "LightGold")}
        zs = []
        for t in me.loop_triangles:
            if t.material_index in gidx:
                for vi in t.vertices:
                    zs.append(me.vertices[vi].co.z)
        if not zs:
            raise SystemExit("SPEARGEN FAIL - RED ON EMPTY: no gold verts found "
                             "for the socket measurement")
        z_socket = min(zs)
        # shaft radius at the grip, measured
        rs = max(abs(v.co.x) for v in me.vertices if abs(v.co.z) < 0.15 * TARGET_LEN)
        add_langets(ob, z_socket, rs, 1.0)   # mesh is already at final scale
        lo2, hi2 = bounds([ob])

    out = os.path.join(a.repo, OUT)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    bpy.ops.object.select_all(action='DESELECT')
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.export_scene.gltf(filepath=out, export_format='GLB',
                              use_selection=True, export_apply=True)

    me.calc_loop_triangles()
    after = {}
    names = [ms.material.name if ms.material else "<none>" for ms in ob.material_slots]
    for t in me.loop_triangles:
        nm = names[t.material_index] if t.material_index < len(names) else "<oob>"
        after[nm] = after.get(nm, 0) + 1
    print("SPEARGEN OK", out)
    print("  raw_len      %.4f  scale %.5f  -> %.4f" % (raw_len, s, hi2[2] - lo2[2]))
    print("  bounds       lo %s hi %s" % ([round(v, 4) for v in lo2],
                                          [round(v, 4) for v in hi2]))
    print("  butt_frac    %.4f (target %.4f)" % (-lo2[2] / (hi2[2] - lo2[2]), BUTT_FRAC))
    print("  in_hand_m    %.3f at hand_scale 0.60" % ((hi2[2] - lo2[2]) * 0.60))
    print("  tris_before  %s" % before)
    print("  tris_after   %s" % after)
    print("  langets      %d" % a.langets)


main()
