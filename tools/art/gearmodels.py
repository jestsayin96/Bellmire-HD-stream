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

# family -> tier -> CANDIDATE MODELS. Five tiers, five different shapes wherever
# the packs can give five, so the ladder is visible as SHAPE and not only as
# colour - and more than one candidate per tier wherever the packs have one,
# because D94's proof sheet caught every tier-5 bow coming back as the same
# bow. Which candidate an item gets is its OWN KEY's business, not its tier's.
BLADE = {1: [(GEAR, "sword_A")], 2: [(GEAR, "sword_B"), (GEAR, "sword_A")],
         3: [(ADV, "sword_1handed"), (GEAR, "sword_C")],
         4: [(GEAR, "sword_D"), (GEAR, "sword_C")],
         5: [(GEAR, "sword_E"), (ADV, "sword_2handed")]}
AXE = {1: [(ADV, "axe_1handed"), (GEAR, "axe")], 2: [(GEAR, "axe_A"), (GEAR, "axe")],
       3: [(GEAR, "axe_B"), (GEAR, "axe_A")],
       4: [(ADV, "axe_2handed"), (GEAR, "halberd")],
       5: [(ADV, "axe_2handed"), (GEAR, "halberd")]}
HAMMER = {1: [(GEAR, "hammer_A"), (GEAR, "mallet")], 2: [(GEAR, "hammer_A"), (GEAR, "hammer")],
          3: [(GEAR, "hammer_B"), (GEAR, "hammer")],
          4: [(GEAR, "hammer_B"), (GEAR, "hammer_A")],
          5: [(GEAR, "hammer_B"), (GEAR, "hammer")]}
POLE = {t: [(GEAR, "halberd"), (GEAR, "spear_A")] for t in range(1, 6)}
STAFF = {1: [(GEAR, "staff_A")], 2: [(ADV, "staff"), (GEAR, "staff_A")],
         3: [(GEAR, "staff_B"), (ADV, "staff")], 4: [(GEAR, "staff_B"), (ADV, "staff")],
         5: [(GEAR, "staff_B"), (ADV, "staff")]}
WAND = {1: [(ADV, "wand")], 2: [(ADV, "wand")], 3: [(GEAR, "wand_A"), (ADV, "wand")],
        4: [(GEAR, "wand_A")], 5: [(GEAR, "wand_A")]}
CROSSBOW = {1: [(ADV, "crossbow_1handed")], 2: [(ADV, "crossbow_1handed")],
            3: [(ADV, "crossbow_2handed"), (ADV, "crossbow_1handed")],
            4: [(ADV, "crossbow_2handed")], 5: [(ADV, "crossbow_2handed")]}
# ONE bow model exists in the repo, so a bow's identity cannot come from the
# file. It comes from ornament(), which is per-item for this family.
BOW = {t: [(GEAR, "bow_A_withString")] for t in range(1, 6)}
DAGGER = {t: [(ADV, "dagger"), (GEAR, "knife")] for t in range(1, 6)}
SHIELDS = {1: [(GEAR, "shield_A")], 2: [(ADV, "shield_square"), (GEAR, "shield_C")],
           3: [(GEAR, "shield_B"), (GEAR, "shield_C")],
           4: [(ADV, "shield_round")], 5: [(ADV, "shield_spikes")]}


def ihash(s):
    """FNV-1a. The same dial showcase.sig turns, so the hub icon, the proof
    sheet and the model path move together for one item."""
    h = 2166136261
    for c in str(s or "").lower():
        h = ((h ^ ord(c)) * 16777619) & 0xFFFFFFFF
    return h


def _one(table, t, key):
    cand = table[max(1, min(5, t))]
    return cand[ihash(key) % len(cand)]


def pick(family, name, tier, key=""):
    """The item's NAME first, its family second - exactly as D73's hats do -
    and then the item's own KEY picks between candidates, so two items of one
    family and one tier are not forced to be the same model."""
    hay = (name + " " + key).lower()
    t = max(1, min(5, tier))
    sel = key or name
    if family == "blade":
        if any(w in hay for w in ("dagger", "knife", "dirk", "stiletto")):
            return _one(DAGGER, t, sel)
        if any(w in hay for w in ("spear", "pike", "lance", "halberd", "glaive")):
            return _one(POLE, t, sel)
        return _one(BLADE, t, sel)
    if family == "axe":
        if any(w in hay for w in ("hammer", "maul", "mallet")):
            return _one(HAMMER, t, sel)
        if any(w in hay for w in ("halberd", "poleaxe", "glaive")):
            return _one(POLE, t, sel)
        return _one(AXE, t, sel)
    if family == "arcane":
        if any(w in hay for w in ("wand", "rod")):
            return _one(WAND, t, sel)
        if any(w in hay for w in ("mace", "club", "cudgel", "hammer", "flail")):
            return _one(HAMMER, t, sel)
        return _one(STAFF, t, sel)
    if family == "ranged":
        if "crossbow" in hay or "arbalest" in hay:
            return _one(CROSSBOW, t, sel)
        return _one(BOW, t, sel)
    return _one(STAFF, t, sel)


def shield_for(tier, key=""):
    return _one(SHIELDS, max(1, min(5, tier)), key)


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


def ornament(objs, tier, mats, tag, key=""):
    """What makes it THIS item and not the pack's stock model. From runed
    upward: a lit collar at the grip, and a seam of light up the length at
    scarforged. Both measured off the model's own bounds.

    AND, at EVERY tier, a per-item band or two round the grip. The repo holds
    exactly one bow model, so for a bow the file cannot be the difference - and
    D94's proof sheet caught both tier-5 bows as one object. The item's own key
    turns these dials, so two items on one model are still two objects."""
    out = []
    mn, mx = bounds(objs)
    if mn is None:
        return out
    h = ihash(key or tag)
    cx = (mn.x + mx.x) * 0.5
    cy = (mn.y + mx.y) * 0.5
    rr = max(0.035, min(0.085, max(mx.x - mn.x, mx.y - mn.y) * 0.22))
    span = max(0.05, mx.z - mn.z)

    # per-item grip bands - plain leather-and-iron, the way a thing that gets
    # held is actually bound
    nb = 1 + (h >> 3) % 3
    for k in range(nb):
        u = 0.10 + 0.10 * k + 0.06 * (((h >> (7 + k)) % 5) / 4.0)
        zz = mn.z + span * u
        br = rr * (0.92 + 0.36 * (((h >> (11 + k)) % 4) / 3.0))
        ring = [Vector((cx + br * math.cos(math.tau * i / 12.0),
                        cy + br * math.sin(math.tau * i / 12.0), zz)) for i in range(13)]
        v, f = L.tube(ring, 0.009 + 0.005 * (((h >> (17 + k)) % 3) / 2.0), 6, caps=False)
        out.append(L.make("Model_band%d_%s" % (k, tag),
                          [p - Vector((cx, cy, zz)) for p in v], f, mats['dark']))
        out[-1].location = (cx, cy, zz)

    if tier >= 3:
        z0 = mn.z + span * 0.18
        ring = [Vector((cx + rr * math.cos(math.tau * i / 14.0),
                        cy + rr * math.sin(math.tau * i / 14.0), z0)) for i in range(15)]
        v, f = L.tube(ring, 0.012, 6, caps=False)
        out.append(L.make("Model_collar_" + tag,
                          [p - Vector((cx, cy, z0)) for p in v], f, mats['glow']))
        out[-1].location = (cx, cy, z0)
    if tier >= 5:
        # the seam's own weave is per-item too - three legs or five, leaning
        # one way or the other
        legs = 4 + (h >> 23) % 3
        amp = 0.012 + 0.008 * (((h >> 27) % 3) / 2.0)
        za, zb = mn.z + span * 0.30, mn.z + span * 0.92
        pts = [Vector((cx + (amp if k % 2 else -amp), cy - rr * 0.55,
                       za + (zb - za) * k / float(legs))) for k in range(legs + 1)]
        v, f = L.tube(pts, 0.010, 5)
        out.append(L.make("Model_seam_" + tag,
                          [p - Vector((cx, cy, za)) for p in v], f, mats['glow']))
        out[-1].location = (cx, cy, za)
    bpy.context.view_layer.update()
    return out
