"""gearmodels - D95/D94 pass 5: the named weapons get REAL models.

The repo already carries two CC0 KayKit weapon sets that gear.gd never touches:

    addons/kaykit_character_pack_adventures/Assets/gltf/   (Adventurers 1.0, CC0)
    assets/gear/                                           (dungeon weapon bits, CC0)

Both are authored Z-up about the GRIP - the pommel sits a little below the
origin and the blade runs up +Z - which is the handslot convention this rig
uses, so a model dropped at the posed hand is held correctly. Pass 4's
procedural blades were readable but thin, and a bought Wyrmfang deserves to look
like a sword somebody forged, not like four boxes.

WHAT STILL COMES FROM THE ITEM. The model is the silhouette; the item keeps its
identity through the tier ladder applied ON TOP of it:
    family + the item's NAME  ->  which model (an arbalest is not a bow, a
                                  greataxe is not a hatchet, a wand is not a staff)
    tier                      ->  which model within the family AND the tint
    tier >= 3                 ->  a lit runed collar at the grip
    tier >= 5                 ->  a seam of light up the length

NOT RE-EXPORTED. These files stay where they are; the kit GLBs carry only
original geometry and the report names the model path per hero so the game build
worker parents the file that is already in the project.
"""
import os
import math

import bpy
from mathutils import Vector, Matrix

import lordlib as L

ADV = os.path.join("addons", "kaykit_character_pack_adventures", "Assets", "gltf")
GEAR = os.path.join("assets", "gear")

# family -> tier -> (pack, file). Five tiers, five different shapes wherever the
# packs can give five, so the ladder is visible as SHAPE and not only as colour.
BLADE = {1: (GEAR, "sword_A"), 2: (GEAR, "sword_B"), 3: (ADV, "sword_1handed"),
         4: (GEAR, "sword_D"), 5: (GEAR, "sword_E")}
AXE = {1: (ADV, "axe_1handed"), 2: (GEAR, "axe_A"), 3: (GEAR, "axe_B"),
       4: (ADV, "axe_2handed"), 5: (ADV, "axe_2handed")}
HAMMER = {1: (GEAR, "hammer_A"), 2: (GEAR, "hammer_A"), 3: (GEAR, "hammer_B"),
          4: (GEAR, "hammer_B"), 5: (GEAR, "hammer_B")}
STAFF = {1: (GEAR, "staff_A"), 2: (ADV, "staff"), 3: (GEAR, "staff_B"),
         4: (GEAR, "staff_B"), 5: (GEAR, "staff_B")}
WAND = {1: (ADV, "wand"), 2: (ADV, "wand"), 3: (GEAR, "wand_A"),
        4: (GEAR, "wand_A"), 5: (GEAR, "wand_A")}
CROSSBOW = {1: (ADV, "crossbow_1handed"), 2: (ADV, "crossbow_1handed"),
            3: (ADV, "crossbow_2handed"), 4: (ADV, "crossbow_2handed"),
            5: (ADV, "crossbow_2handed")}
BOW = {t: (GEAR, "bow_A_withString") for t in range(1, 6)}
DAGGER = {t: (ADV, "dagger") for t in range(1, 6)}
SHIELDS = {1: (GEAR, "shield_A"), 2: (ADV, "shield_square"), 3: (GEAR, "shield_B"),
           4: (ADV, "shield_round"), 5: (ADV, "shield_spikes")}


def pick(family, name, tier, key=""):
    """The item's NAME first, its family second - exactly as D73's hats do."""
    hay = (name + " " + key).lower()
    t = max(1, min(5, tier))
    if family == "blade":
        if any(w in hay for w in ("dagger", "knife", "dirk", "stiletto")):
            return DAGGER[t]
        return BLADE[t]
    if family == "axe":
        if any(w in hay for w in ("hammer", "maul", "mallet")):
            return HAMMER[t]
        return AXE[t]
    if family == "arcane":
        if any(w in hay for w in ("wand", "rod")):
            return WAND[t]
        return STAFF[t]
    if family == "ranged":
        if "crossbow" in hay or "arbalest" in hay:
            return CROSSBOW[t]
        return BOW[t]
    return STAFF[t]


def shield_for(tier):
    return SHIELDS[max(1, min(5, tier))]


def load(repo, pack, stem, tag):
    """Import one model. Returns its objects, or [] if the file is missing -
    a missing model must never take a hero out of the sheet."""
    path = os.path.join(repo, pack, stem + ".gltf")
    if not os.path.isfile(path):
        path = os.path.join(repo, pack, stem + ".glb")
        if not os.path.isfile(path):
            return []
    before = set(bpy.data.objects)
    try:
        bpy.ops.import_scene.gltf(filepath=path)
    except Exception:
        return []
    new = [ob for ob in bpy.data.objects if ob not in before]
    for ob in list(new):
        if ob.type == 'MESH' and not ob.data.materials:
            bpy.data.objects.remove(ob, do_unlink=True)
            new.remove(ob)
    meshes = [ob for ob in new if ob.type == 'MESH']
    for ob in meshes:
        ob.name = "Model_%s_%s" % (stem, tag)
    for ob in new:
        if ob.type != 'MESH':
            try:
                bpy.data.objects.remove(ob, do_unlink=True)
            except Exception:
                pass
    return meshes


def bounds(objs):
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    for ob in objs:
        obe = ob.evaluated_get(dg)
        me = obe.to_mesh()
        mw = obe.matrix_world
        for v in me.vertices:
            pts.append(mw @ v.co)
        obe.to_mesh_clear()
    if not pts:
        return None, None
    return (Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts))),
            Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts))))


def ground(objs, z=0.005):
    """A staff or a polearm rests its butt ON the floor; the fit test counts
    anything below the feet as sunk, and it is right to."""
    mn, mx = bounds(objs)
    if mn is None or mn.z >= z:
        return 0.0
    d = z - mn.z
    for ob in objs:
        ob.location = (ob.location[0], ob.location[1], ob.location[2] + d)
    bpy.context.view_layer.update()
    return d


def place(objs, at, target_len, lean=-0.17, roll=0.0):
    """Carry the model to the hand, scaled to the body that carries it.
    MEASURED: the scale comes from the model's own height and the body's own
    shoulder height, never from a magic number."""
    mn, mx = bounds(objs)
    if mn is None:
        return 1.0
    # the LONGEST dimension, not the height: a crossbow lies along Y, and
    # scaling it by its height blew it up 1.25x and pushed it out of frame
    sz, sy, sx = mx.z - mn.z, mx.y - mn.y, mx.x - mn.x
    span = max(0.05, sz, sy, sx)
    # a thing carried ACROSS the body (a crossbow lies along Y, a bow along X)
    # is not as long as a thing carried UP it, or it leaves the fixed frame
    if span > sz * 1.05:
        target_len *= 0.62
    k = max(0.25, min(1.25, target_len / span))
    M = (Matrix.Translation(at) @ Matrix.Rotation(lean, 4, 'Y')
         @ Matrix.Rotation(roll, 4, 'Z') @ Matrix.Diagonal(Vector((k, k, k)).to_4d()))
    for ob in objs:
        ob.matrix_world = M @ ob.matrix_world
    bpy.context.view_layer.update()
    return k


def tint(objs, rgb, tag, rough=0.5):
    """The tier ladder, multiplied over the pack's own atlas - the texture
    survives, so the render is honest about what the game will show."""
    done = {}
    for ob in objs:
        for i, m in enumerate(list(ob.data.materials)):
            if m is None:
                continue
            if m.name in done:
                ob.data.materials[i] = done[m.name]
                continue
            nm = m.copy()
            nm.name = "%s_%s" % (m.name, tag)
            nt = nm.node_tree
            bsdf = next((n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'), None)
            if bsdf is not None and 'Base Color' in bsdf.inputs:
                sock = bsdf.inputs['Base Color']
                if sock.is_linked:
                    src = sock.links[0].from_socket
                    nt.links.remove(sock.links[0])
                    mixn = nt.nodes.new('ShaderNodeMixRGB')
                    mixn.blend_type = 'MULTIPLY'
                    mixn.inputs['Fac'].default_value = 1.0
                    mixn.inputs['Color2'].default_value = (rgb[0], rgb[1], rgb[2], 1.0)
                    nt.links.new(src, mixn.inputs['Color1'])
                    nt.links.new(mixn.outputs['Color'], sock)
                else:
                    sock.default_value = (rgb[0], rgb[1], rgb[2], 1.0)
                if 'Roughness' in bsdf.inputs:
                    bsdf.inputs['Roughness'].default_value = rough
            done[m.name] = nm
            ob.data.materials[i] = nm


def ornament(objs, tier, mats, tag):
    """What makes it THIS item and not the pack's stock model: a lit collar at
    the grip from runed upward, and a seam of light up the length at scarforged.
    Both are measured off the model's own bounds."""
    out = []
    if tier < 3:
        return out
    mn, mx = bounds(objs)
    if mn is None:
        return out
    cx = (mn.x + mx.x) * 0.5
    cy = (mn.y + mx.y) * 0.5
    rr = max(0.035, min(0.085, max(mx.x - mn.x, mx.y - mn.y) * 0.22))
    z0 = mn.z + (mx.z - mn.z) * 0.18
    ring = [Vector((cx + rr * math.cos(math.tau * i / 14.0),
                    cy + rr * math.sin(math.tau * i / 14.0), z0)) for i in range(15)]
    v, f = L.tube(ring, 0.012, 6, caps=False)
    out.append(L.make("Model_collar_" + tag, [p - Vector((cx, cy, z0)) for p in v], f, mats['glow']))
    out[-1].location = (cx, cy, z0)
    if tier >= 5:
        za, zb = mn.z + (mx.z - mn.z) * 0.30, mn.z + (mx.z - mn.z) * 0.92
        pts = [Vector((cx + (0.016 if k % 2 else -0.016), cy - rr * 0.55,
                       za + (zb - za) * k / 5.0)) for k in range(6)]
        v, f = L.tube(pts, 0.010, 5)
        out.append(L.make("Model_seam_" + tag, [p - Vector((cx, cy, za)) for p in v], f, mats['glow']))
        out[-1].location = (cx, cy, za)
    bpy.context.view_layer.update()
    return out
