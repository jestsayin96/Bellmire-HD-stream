"""showcasegen - D95, THE TEN-CHARACTER SHOWCASE (headless Blender driver).

  blender -b -noaudio -P tools/art/showcasegen.py -- --repo <repo> [--res 700x1000]

Mr. E, 16 Nov 00:59: "i want 10 characters with different equipment and armor and
accessories as a show case for me ... front, side, back, top down profile views
i want to make sure everything that is made for these characters actually fit.
people are not going to waste money on slop."

WHAT HE IS CHECKING IS FIT, so fit is MEASURED here, not eyeballed:
  * every shell is built off radii sampled from the real posed body (BVH ray),
    offset by a stated clearance - a piece cannot float and cannot sink
  * then every finished piece is re-tested against the body's full BVH and the
    report lists penetration, gap, and anything standing in the floor
  * FIT REPORT is printed and written whether it is clean or not

Four views, ONE framing for all ten (a fixed ortho height and a fixed camera
centre), so nothing is quietly cropped or zoomed to flatter a piece.

The two traps that have bitten this lane before:
  SCALE   clip range and ortho height come from measured bounds / fixed metres
  BLANKS  every PNG is reopened and its opaque pixel count asserted
"""
import os
import sys
import math
import json
import argparse

import bpy
import numpy as np
from mathutils import Vector, Matrix, bvhtree

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordlib as L            # noqa: E402
import icons as IC             # noqa: E402
import showcase as SC          # noqa: E402
import lordgen as G            # noqa: E402
import e3pogen as EG           # noqa: E402
import gearmodels as GM        # noqa: E402

VIEWS = (("front", 0.0, 0.0), ("side", 90.0, 0.0), ("back", 180.0, 0.0), ("top", 0.0, 88.0))
FRAME_H = 3.30          # metres of ortho height - IDENTICAL for all ten
FRAME_CZ = 1.28         # camera centre height - IDENTICAL for all ten

# tier -> rarity word (gear.gd's ladder index is the rarity ladder)
RARITY = ["starting", "common", "uncommon", "rare", "very rare", "legendary"]

# The ten. body/calling/tier are chosen for SPREAD: two per rarity band, three
# armour cuts, five weapon families, six different bodies, and one declared SET.
ROSTER = [
    dict(key="knight", calling="knight", body="Knight", tier=1, nudge=-0.04,
         weapon="w_blade_ironmonger", armour="a_padded_gambeson",
         slots=["ring", "amulet", "boots"], shield=True),
    dict(key="ranger", calling="ranger", body="Ranger", tier=1, nudge=+0.04,
         weapon="w_ranged_hunters_crossbow", armour="a_ford_leathers",
         slots=["cloak", "gloves", "boots"]),
    dict(key="rogue", calling="rogue", body="Rogue", tier=2, nudge=-0.05,
         weapon="w_blade_stonewick", armour="a_studded_brigandine",
         slots=["ring", "cloak", "gloves"]),
    dict(key="warden", calling="warden", body="Barbarian", tier=2, nudge=+0.05,
         weapon="w_axe_ferrywarden", armour="a_militia_hauberk",
         slots=["amulet", "boots", "gloves"]),
    dict(key="mage", calling="mage", body="Mage", tier=3, nudge=-0.05,
         weapon="w_arcane_runewrapped_staff", armour="a_runed_vestment",
         slots=["amulet", "ring", "cloak"]),
    dict(key="duelist", calling="duelist", body="Rogue_Hooded", tier=3, nudge=+0.05,
         weapon="w_blade_stitchwound", armour="a_emberleather",
         slots=["gloves", "boots", "ring"]),
    dict(key="barbarian", calling="barbarian", body="Barbarian", tier=4, nudge=-0.04,
         weapon="w_axe_ashmaul", armour="a_wyrmhide_coat",
         slots=["cloak", "amulet", "boots"]),
    dict(key="sage", calling="sage", body="Mage", tier=4, nudge=+0.04,
         weapon="w_arcane_dragontooth_staff", armour="a_dragonsilk_robe",
         slots=["ring", "amulet", "gloves"]),
    dict(key="paladin", calling="paladin", body="Knight", tier=5, nudge=0.00,
         weapon="w_blade_scarfang", armour="a_scarwoven_hauberk",
         slots=["boots", "gloves", "cloak"], helm=True, shield=True,
         set_name="Scarwoven plate"),
    dict(key="cleric", calling="cleric", body="Rogue_Hooded", tier=5, nudge=+0.03,
         weapon="w_arcane_seam_staff", armour="a_seamwoven_vestment",
         slots=["amulet", "cloak", "boots"], shield=True),
]

# the body's own hat/cape must come off when we put our own on, or the sheet
# shows two capes and a helm over a hat and the fit report is a lie
HIDE_FOR = {"hat": ("_Helmet", "_HelmetVisor", "_Hat", "_BearHat"),
            "cloak": ("_Cape",)}

# Six bodies carry ten heroes, so four of them are worn twice. town.gd already
# tints a body; the showcase uses the same lever so the Mage and the Sage are
# not one man photographed twice. Values stay high or the atlas turns to mud.
BODY_TINT = {"knight": (0.80, 0.86, 1.00), "ranger": (0.74, 0.92, 0.70),
             "rogue": (0.86, 0.72, 0.92), "warden": (1.00, 0.80, 0.62),
             "mage": (0.70, 0.74, 1.00), "duelist": (0.66, 0.94, 0.92),
             "barbarian": (1.00, 0.88, 0.60), "sage": (1.00, 0.96, 0.84),
             "paladin": (1.00, 1.00, 0.96), "cleric": (0.72, 0.82, 0.96)}


# ------------------------------------------------------------------ item data
def load_items(repo):
    d = json.load(open(os.path.join(repo, "data", "items.json"), encoding="utf-8"))
    # D94c-2: the cloak shade step needs the whole list to assign (see icons.py)
    IC.register_cloaks(d.get("accessories", {}))
    return d


def acc_pick(items, slot, tier, used):
    """Rarity has to be VISIBLE, so an accessory is drawn from the character's
    own RARITY BAND - and the band is the one STORED on the item, not one
    guessed from a cost quintile. C-61 re-banded all 254 accessories per slot
    (boots are legendary at 390-420, gloves at 320-380), so a cost threshold
    now disagrees with the item's own word for itself. Cheapest unused inside
    the band, so it is deterministic; if a band is exhausted we walk OUTWARD
    one rung at a time rather than falling back to the whole list, so a
    legendary hero never silently drops to a common ring."""
    want = RARITY[tier] if tier < len(RARITY) else RARITY[-1]
    if want == "starting":
        want = "common"
    byband = {}
    for k, v in items["accessories"].items():
        if v["slot"] != slot:
            continue
        byband.setdefault(v.get("rarity", "common"), []).append((v["cost"], k))
    for b in byband:
        byband[b].sort()
    ladder = RARITY[1:]
    try:
        i = ladder.index(want)
    except ValueError:
        i = 0
    order = [ladder[i]]
    for d in range(1, len(ladder)):
        for j in (i - d, i + d):
            if 0 <= j < len(ladder):
                order.append(ladder[j])
    for b in order:
        for cost, k in byband.get(b, ()):
            if k not in used:
                used.add(k)
                return k, items["accessories"][k]
    raise RuntimeError("no accessory left for " + slot)


def helm_pick(items, used):
    cands = [(v["cost"], k) for k, v in items["cosmetics"].items()
             if isinstance(v, dict) and v.get("kind") == "hat"
             and any(w in v["name"].lower() for w in ("helm", "sallet", "barbute", "kettle"))]
    cands.sort(reverse=True)
    for cost, k in cands:
        if k not in used:
            used.add(k)
            return k, items["cosmetics"][k]
    return None, None


# ---------------------------------------------------------------- the surface
class Surf(object):
    """Radius of the TORSO at a height and an angle, measured off the real
    posed mesh. Arms and legs are deliberately excluded: a ray at shoulder
    height that hits a hanging arm would make the cuirass a barrel."""

    def __init__(self, trees, default=0.17):
        self.trees = trees
        self.default = default
        self.cache = {}
        self.misses = 0

    def r(self, z, a):
        k = (round(z, 3), round(a, 3))
        if k in self.cache:
            return self.cache[k]
        d = Vector((math.cos(a), math.sin(a), 0.0))
        best = None
        for t in self.trees:
            loc, nor, idx, dist = t.ray_cast(Vector((0.0, 0.0, z)), d, 3.0)
            if loc is not None and (best is None or dist > best):
                best = dist          # the OUTERMOST torso surface on that ray
        if best is None:
            self.misses += 1
            best = self.default
        best = max(0.06, min(0.55, best))
        self.cache[k] = best
        return best


def ray_out(trees, origin, d, maxd=1.2):
    """Distance from a point INSIDE the body out to its surface along d.
    This is how the boots learn how wide the foot actually is."""
    best = None
    for t in trees:
        loc, nor, idx, dist = t.ray_cast(origin, Vector(d).normalized(), maxd)
        if loc is not None and (best is None or dist > best):
            best = dist
    return best


def scale_part(part, centre, sx, sy, sz=1.0):
    c = Vector(centre)
    part.items = [([Vector((c.x + (v.x - c.x) * sx, c.y + (v.y - c.y) * sy,
                            c.z + (v.z - c.z) * sz)) for v in verts], f, m)
                  for verts, f, m in part.items]


def bvh_for(objs):
    dg = bpy.context.evaluated_depsgraph_get()
    out = []
    for ob in objs:
        try:
            out.append(bvhtree.BVHTree.FromObject(ob, dg))
        except Exception:
            pass
    return out


# --------------------------------------------------------------- build a hero
def hand_delta(arm, bone):
    """Carry a held weapon to the POSED hand WITHOUT the shoulder's rotation.
    Pass 1 used the full bone matrix and every one of the ten had its own blade
    lying horizontally through its chest. A carried weapon stays upright."""
    pb = arm.pose.bones.get(bone)
    if pb is None:
        return Matrix.Identity(4)
    rest = arm.data.bones[bone].matrix_local
    head = arm.matrix_world @ arm.data.bones[bone].head_local
    posed = arm.matrix_world @ pb.matrix @ rest.inverted() @ head
    return Matrix.Translation(posed - head)


def merge_parts(parts, mats, anchors, arm, tag, posed=True):
    """One object per material per part, origin on the bone it hangs from -
    the same contract as E3PO's kit, so the game build worker parents these."""
    objs, manifest = [], []
    for part in parts:
        groups = {}
        for verts, faces, slot in part.items:
            gv, gf = groups.setdefault(slot, ([], []))
            off = len(gv)
            gv.extend(verts)
            gf.extend([tuple(i + off for i in f) for f in faces])
        anchor = anchors[part.bone]
        if posed and arm:
            delta = (hand_delta(arm, part.bone) if part.slot == "weapon"
                     else EG.bone_delta(arm, part.bone))
        else:
            delta = Matrix.Identity(4)
        pm = getattr(part, "mats", None) or mats
        made = []
        for slot, (gv, gf) in groups.items():
            moved = [delta @ v for v in gv]
            a = delta @ anchor if posed else anchor
            local = [v - a for v in moved]
            ob = L.make("%s_%s_%s" % (part.name, slot, tag), local, gf, pm[slot])
            ob.location = a
            objs.append(ob)
            made.append(ob)
        part.objs = made
        manifest.append(dict(part=part.name, bone=part.bone, item=part.item,
                             slot=part.slot, mats=sorted(groups.keys())))
    bpy.context.view_layer.update()
    return objs, manifest


# ------------------------------------------------------------------- fit test
def fit_check(parts, body_trees, body_min_z):
    """THE HONEST LIST. Every vertex of every piece against the body surface:
    inside = clip, far = float, below zero = standing in the floor."""
    faults, rows = [], []
    for part in parts:
        if not getattr(part, "objs", None):
            continue
        pen, gap, minz, nin, nv = 0.0, 1e9, 1e9, 0, 0
        for ob in part.objs:
            mw = ob.matrix_world
            vs = [mw @ v.co for v in ob.data.vertices]
            step = max(1, len(vs) // 260)
            near = getattr(part, "ignore_near", None)
            for v in vs[::step]:
                if near is not None and (v - near[0]).length < near[1]:
                    continue        # the grip is inside the fist BY DESIGN
                nv += 1
                minz = min(minz, v.z)
                best = None
                for t in body_trees:
                    loc, nor, idx, dist = t.find_nearest(v, 1.2)
                    if loc is None:
                        continue
                    inside = (v - loc).dot(nor) < 0.0
                    if best is None or dist < best[0]:
                        best = (dist, inside)
                if best is None:
                    continue
                dist, inside = best
                if inside:
                    nin += 1
                    pen = max(pen, dist)
                else:
                    gap = min(gap, dist)
        row = dict(part=part.name, item=part.item, slot=part.slot,
                   verts=nv, inside_pct=round(100.0 * nin / max(1, nv), 1),
                   penetration_m=round(pen, 4),
                   gap_m=(round(gap, 4) if gap < 1e8 else None),
                   min_z=round(minz, 4))
        rows.append(row)
        # A boot contains a foot and a gauntlet contains a hand: their inner
        # faces are inside the body on purpose. What is a FAULT is a piece
        # mostly buried in the body, or a carried thing passing through it.
        enclosing = part.name.startswith(("Acc_Boot", "Acc_Glove", "Acc_Helm", "Acc_Ring",
                                          "Armour_Pauldron", "Armour_Tassets",
                                          "Armour_Sleeve"))
        if not part.touches and pen > 0.020:
            faults.append("%s (%s): PASSES THROUGH the body by %.3f m"
                          % (part.name, part.item, pen))
        elif part.touches and (pen > (0.115 if enclosing else 0.045)
                               or row["inside_pct"] > (62.0 if enclosing else 34.0)):
            faults.append("%s (%s): CLIPS the body - %.3f m deep, %.0f%% of it inside"
                          % (part.name, part.item, pen, row["inside_pct"]))
        if part.touches and gap < 1e8 and gap > 0.075 and nin == 0:
            faults.append("%s (%s): FLOATS - nearest body surface %.3f m away"
                          % (part.name, part.item, gap))
        if minz < body_min_z - 0.012:
            faults.append("%s (%s): stands %.3f m BELOW the feet - sunk in the floor"
                          % (part.name, part.item, body_min_z - minz))
        if part.name.startswith("Acc_Boot") and minz > body_min_z + 0.045:
            faults.append("%s (%s): sole is %.3f m off the ground"
                          % (part.name, part.item, minz - body_min_z))
    return rows, faults


# -------------------------------------------------------------------- renders
def render_fixed(objs, path, az, el, resx, resy):
    """FIXED framing: the same ortho height and centre for every character and
    every view, so the sheet cannot flatter one piece by zooming in."""
    scene = bpy.context.scene
    mn, mx, pts = EG.mesh_bounds(objs)
    center = Vector((0.0, 0.0, FRAME_CZ))
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    a, e = math.radians(az), math.radians(el)
    dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e))).normalized()
    cam.location = center + dirv * 8.0
    cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
    bpy.context.view_layer.update()
    fwd = (cam.matrix_world.to_3x3() @ Vector((0, 0, -1))).normalized()
    depth = [(p - cam.location).dot(fwd) for p in pts]
    cam_d.ortho_scale = FRAME_H
    cam_d.clip_start = max(0.01, min(depth) - 1.0)
    cam_d.clip_end = max(depth) + 4.0
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    # did anything fall outside the fixed frame? that is a CROP and a fault.
    mwi = cam.matrix_world.inverted()
    half_v = FRAME_H / 2.0
    half_h = FRAME_H * (resx / float(resy)) / 2.0
    out = 0
    for p in pts:
        q = mwi @ p
        if abs(q.y) > half_v or abs(q.x) > half_h:
            out += 1
    bpy.data.objects.remove(cam, do_unlink=True)
    return dict(ortho=round(cam_d.ortho_scale, 3), outside=out,
                clip=[round(cam_d.clip_start, 3), round(cam_d.clip_end, 3)])


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--res", default="700x1000")
    ap.add_argument("--only", default="")
    args = ap.parse_args(argv)
    resx, resy = (int(x) for x in args.res.split("x"))
    repo = args.repo
    outdir = os.path.join(repo, "renders", "art", "d95")
    os.makedirs(outdir, exist_ok=True)
    items = load_items(repo)
    bodydir = os.path.join(repo, "assets", "characters", "kaykit_adv2")
    gdir = os.path.join(repo, "assets", "characters", "bellmire", "showcase")
    os.makedirs(gdir, exist_ok=True)

    # accessory cost bounds per slot, for the ornateness derivation
    lo, hi = {}, {}
    for k, v in items["accessories"].items():
        s = v["slot"]
        lo[s] = min(lo.get(s, 1e9), v["cost"])
        hi[s] = max(hi.get(s, 0), v["cost"])

    used = set()
    report = {"ok": True, "errors": [], "chars": [], "fit_faults": [], "blank": {}}
    roster = [r for r in ROSTER if not args.only or r["key"] in args.only.split(",")]

    for rec in roster:
        key = rec["key"]
        try:
            G.purge()
            EG.setup_scene(resx, resy, transparent=True)
            # a dark world renders kept steel as a black mirror; the showcase
            # lifts the ambient so the tier ladder reads as VALUE on screen
            bg = next((n for n in bpy.context.scene.world.node_tree.nodes
                       if n.type == 'BACKGROUND'), None)
            if bg:
                bg.inputs['Color'].default_value = (0.19, 0.20, 0.23, 1.0)
                bg.inputs['Strength'].default_value = 1.0
            arm, meshes = EG.import_knight(os.path.join(bodydir, rec["body"] + ".glb"), key)
            wrec = items["equipment"]["weapons"][rec["weapon"]]
            arec = items["equipment"]["armour"][rec["armour"]]
            tier = rec["tier"]
            wear = SC.wear_for(tier, rec["nudge"])

            # --- the accessories, chosen in the character's own rarity band
            accs = []
            for slot in rec["slots"]:
                ak, av = acc_pick(items, slot, tier, used)
                stat = next((s for s in IC.STAT_ORDER if s in av), None)
                h = 0
                for ch in ak:
                    h = (h * 131 + ord(ch)) & 0xFFFFFFFF
                ctx = dict(variant=IC.variant_for(slot, ak, av["name"], h),
                           orn=(av["cost"] - lo[slot]) / max(1.0, float(hi[slot] - lo[slot])),
                           gem=IC.STAT_GEM.get(stat, (0.72, 0.72, 0.76)))
                accs.append((slot, ak, av, ctx, stat))
            helm = None
            if rec.get("helm"):
                hk, hv = helm_pick(items, used)
                if hk:
                    h = 0
                    for ch in hk:
                        h = (h * 131 + ord(ch)) & 0xFFFFFFFF
                    helm = (hk, hv, dict(variant=IC.variant_for("hat", hk, hv["name"], h),
                                         orn=0.85, gem=IC.STAT_GEM["ac"]))

            # --- the body's own hat/cape comes off where we replace it
            hidden = []
            repl = set(s for s, _, _, _, _ in accs) | ({"hat"} if helm else set())
            for ob in list(meshes):
                for slot, sfx in HIDE_FOR.items():
                    if slot in repl and any(ob.name.split('.')[0].endswith(x) for x in sfx):
                        hidden.append(ob.name)
                        bpy.data.objects.remove(ob, do_unlink=True)
                        meshes.remove(ob)
                        break

            EG.tint_meshes(meshes, BODY_TINT.get(key, (1.0, 1.0, 1.0)), "sc_" + key,
                           wear * 0.45)
            EG.pose_at_post(arm)
            anchors = EG.rest_anchors(arm)
            bpy.context.view_layer.update()

            # --- measure the posed body: torso only for shells, all for fit
            torso = [ob for ob in meshes if any(w in ob.name for w in ("_Body", "_Head"))]
            S = Surf(bvh_for(torso or meshes))
            body_trees = bvh_for(meshes)
            # the torso sampler deliberately ignores arms and legs; a skirt and
            # a cloak have to clear the LEGS, so they get a whole-body sampler
            S.full = Surf(body_trees)
            bmn, bmx, _ = EG.mesh_bounds(meshes)

            # --- the gear
            gem = accs[0][3]['gem'] if accs else (0.72, 0.72, 0.76)
            mats = SC.materials(tier, wear, gem=gem, tag="_" + key)
            parts = []
            for q in SC.armour(arec["name"], arec["cut"], tier, S, anchors):
                parts.append(q)
            use_model = GM.pick(wrec["family"], wrec["name"], tier, rec["weapon"])
            wp = SC.weapon(wrec["name"], wrec["family"], tier, rec["weapon"],
                           key=rec["weapon"])
            # authored about its grip at the origin: carry it to the hand slot,
            # and out from the hip so the hand is not inside the blade
            hs = anchors["handslot.r"]
            off = Vector((hs.x - 0.135, hs.y - 0.115, hs.z))
            wp.items = [([v + off for v in verts], f, m) for verts, f, m in wp.items]
            parts.append(wp)

            def acc_mats(ak, av, ctx, stat, setpiece=False):
                """D73's derivation for the WORN piece, so the icon in the hub
                and the thing on the hero are the same object: metal from the
                COST QUARTILE, gem from the STAT, cloth tone from the key, and
                WEAR RIDING COST - a 200-gold mitt is handled, a 500-gold
                mantle is kept."""
                if setpiece:            # a declared set shares its look. Mr E's
                    return mats         # one named exception.
                q = min(3, int(ctx['orn'] * 4.0))
                aw = max(0.08, min(0.92, 0.95 - 0.85 * ctx['orn']))
                # D94c: a cloak wears a DYE, leather keeps its tone. One rule,
                # in icons.cloth_tone, mirrored from gear.gd.
                return SC.materials(max(1, min(5, 1 + q)), aw, gem=ctx['gem'],
                                    cloth=IC.cloth_tone(av.get("slot", ""), ak,
                                                        av.get("name", "")),
                                    tag="_%s_%s" % (key, ak),
                                    metal=IC.METALS[q])

            # how big is this body's foot and hand? six bodies, six answers.
            fL = anchors["foot.l"]
            fw = max(ray_out(body_trees, Vector((fL.x, fL.y, 0.075)), (1, 0, 0)) or 0.055,
                     ray_out(body_trees, Vector((fL.x, fL.y, 0.075)), (-1, 0, 0)) or 0.055)

            boot_k = max(0.80, min(1.9, (fw + 0.016) / 0.058))

            # the head, measured: centre and radius of the body's own skull
            headobjs = [ob for ob in meshes if "_Head" in ob.name or "Hair" in ob.name]
            if headobjs:
                hmn, hmx, _ = EG.mesh_bounds(headobjs)
                headbox = ((hmn.z + hmx.z) * 0.5,
                           max(hmx.x - hmn.x, hmx.y - hmn.y) * 0.5 + 0.012)
            else:
                headbox = None

            # A weapon is carried by a body 46% of which is head. Authored at
            # human proportions it is a lamppost, so it is scaled to the body's
            # own shoulder height - measured, never a magic number.
            wmn = min(v.z for verts, f, m in wp.items for v in verts)
            wmx = max(v.z for verts, f, m in wp.items for v in verts)
            wk = max(0.45, min(1.0, (anchors["upperarm.l"].z * 1.02) / max(0.2, wmx - wmn)))
            hs0 = Vector((hs.x - 0.135, hs.y - 0.115, hs.z))
            wp.items = [([Vector((hs0.x + (v.x - hs0.x) * wk, hs0.y + (v.y - hs0.y) * wk,
                                  hs0.z + (v.z - hs0.z) * wk)) for v in verts], f, m)
                        for verts, f, m in wp.items]

            setslots = set()
            if rec.get("set_name"):
                setslots = {"boots", "gloves", "hat"}
            for slot, ak, av, ctx, stat in accs:
                for q in SC.ACC_BUILDERS[slot](av["name"], ak, av["cost"], ctx, anchors, S):
                    q.mats = acc_mats(ak, av, ctx, stat, slot in setslots)
                    if q.name.startswith("Acc_Boot"):
                        f = anchors["foot." + q.name[-1].lower()]
                        scale_part(q, (f.x, f.y, 0.0), boot_k, boot_k, 1.0)
                    parts.append(q)
            if helm:
                for q in SC.acc_helm(helm[1]["name"], helm[0], helm[1]["cost"], helm[2],
                                     anchors, S, headbox=headbox):
                    q.mats = acc_mats(helm[0], helm[1], helm[2], "ac", "hat" in setslots)
                    parts.append(q)

            objs, manifest = merge_parts(parts, mats, anchors, arm, key, posed=True)

            # ---- the carried model. Dropped at the POSED hand, scaled to the
            # body, tinted up the tier ladder, and given its lit collar/seam.
            models, model_notes, model_groups = [], [], []
            tint_rgb = SC.worn(tuple(0.45 + 0.55 * c for c in SC.TIER_METAL[tier]), wear)
            hs_posed = hand_delta(arm, "handslot.r") @ anchors["handslot.r"]
            target = anchors["upperarm.l"].z * 1.30
            mobjs = GM.load(repo, use_model[0], use_model[1], key)
            if mobjs:
                # held clear of the hip, leaned out: a carried weapon that
                # crosses its owner's chest is the fault the fit test shouts
                # about, and pass 5's models are twice the size of pass 4's
                GM.place(mobjs, hs_posed + Vector((-0.135, -0.085, 0.02)), target, lean=-0.24)
                mmn, mmx = GM.bounds(mobjs)
                if mmx is not None and (mmx.z - mmn.z) > anchors["upperarm.l"].z:
                    GM.ground(mobjs)        # a staff stands on the floor
                GM.tint(mobjs, tint_rgb, "w_" + key, 0.42 + 0.34 * wear)
                orn = GM.ornament(mobjs, tier, mats, "w_" + key, key=rec["weapon"])
                models += mobjs + orn
                model_groups.append(("Model_Weapon", wrec["name"], "weapon", mobjs,
                                     (hs_posed, 0.17)))
                model_notes.append(dict(slot="weapon", item=wrec["name"],
                                        path="%s/%s.gltf" % (use_model[0].replace("\\", "/"),
                                                             use_model[1])))
                parts = [q for q in parts if q.slot != "weapon"]
                objs = [o for o in objs if not o.name.startswith("Weapon_")]
                for o in list(bpy.data.objects):
                    if o.name.startswith("Weapon_"):
                        bpy.data.objects.remove(o, do_unlink=True)
            if rec.get("shield"):
                sp = GM.shield_for(tier, key=rec.get("shield") or key)
                sobjs = GM.load(repo, sp[0], sp[1], key + "_sh")
                if sobjs:
                    hl = hand_delta(arm, "handslot.l") @ anchors["handslot.l"]
                    # a shield is carried on the arm, not worn as a table: it
                    # is HALF the body's shoulder height and it stands clear of
                    # the belly, which pass 5 did not
                    GM.place(sobjs, hl + Vector((0.135, -0.105, 0.075)),
                             anchors["upperarm.l"].z * 0.55, lean=0.16)
                    GM.tint(sobjs, tint_rgb, "s_" + key, 0.42 + 0.34 * wear)
                    models += sobjs + GM.ornament(sobjs, tier, mats, "s_" + key,
                                                  key=str(rec.get("shield") or key))
                    model_groups.append(("Model_Shield", "shield (" + sp[1] + ")",
                                         "offhand", sobjs, (hl, 0.19)))
                    model_notes.append(dict(slot="offhand", item="shield (" + sp[1] + ")",
                                            path="%s/%s.gltf" % (sp[0].replace("\\", "/"), sp[1])))
            allobjs = meshes + objs + models
            EG.add_lights(Vector((0.0, 0.0, 1.20)), 1.65)

            class _Shim(object):
                """A carried model is not one of our Parts, but it is judged by
                the same fit test - a bought sword through the owner's hip is a
                fault whoever modelled it."""
                def __init__(self, name, item, slot, objs, near=None):
                    self.name, self.item, self.slot = name, item, slot
                    self.objs, self.touches = objs, False
                    self.ignore_near = near
            fitparts = list(parts) + [_Shim(n, it, sl, og, nr)
                                      for n, it, sl, og, nr in model_groups]
            rows, faults = fit_check(fitparts, body_trees, bmn.z)
            cams = {}
            d = os.path.join(outdir, key)
            os.makedirs(d, exist_ok=True)
            for vname, az, el in VIEWS:
                cams[vname] = render_fixed(allobjs, os.path.join(d, vname + ".png"),
                                           az, el, resx, resy)
                if cams[vname]["outside"] > 0:
                    faults.append("%s view: %d vertices outside the fixed frame - CROPPED"
                                  % (vname, cams[vname]["outside"]))
            amn, amx, _ = EG.mesh_bounds(allobjs)
            ch = dict(key=key, calling=rec["calling"], body=rec["body"], tier=tier,
                      rarity=RARITY[tier], wear=round(wear, 3),
                      weapon=dict(id=rec["weapon"], name=wrec["name"], family=wrec["family"],
                                  tier_name=wrec["tier_name"]),
                      armour=dict(id=rec["armour"], name=arec["name"], cut=arec["cut"],
                                  tier_name=arec["tier_name"]),
                      accessories=[dict(slot=s, id=k, name=v["name"], cost=v["cost"],
                                        stat=st, variant=c["variant"]) for s, k, v, c, st in accs],
                      helm=(dict(id=helm[0], name=helm[1]["name"], cost=helm[1]["cost"]) if helm else None),
                      set_name=rec.get("set_name"),
                      hidden_body_meshes=hidden, surf_misses=S.misses,
                      models=model_notes,
                      height=round(amx.z - amn.z, 3),
                      tris=sum(len(o.data.polygons) for o in objs),
                      pieces=len(objs), manifest=manifest, fit=rows, faults=faults, cams=cams)
            report["chars"].append(ch)
            report["fit_faults"] += ["%s: %s" % (key, f) for f in faults]

            # --- export the kit in REST space for the game build worker
            kit_objs = objs
            for ob in list(meshes) + list(models) + [arm]:
                try:
                    bpy.data.objects.remove(ob, do_unlink=True)
                except Exception:
                    pass
            ok, msg = EG.export_glb(kit_objs, os.path.join(gdir, key + "_kit.glb"))
            ch["export"] = dict(ok=ok, msg=msg)
        except Exception:
            import traceback
            report["ok"] = False
            report["errors"].append("%s: %s" % (key, traceback.format_exc()[-1200:]))

    # ---------------------------------------------------- blank check + sheets
    try:
        checked, bad = [], []
        cells = {}
        for ch in report["chars"]:
            for vname, _, _ in VIEWS:
                p = os.path.join(outdir, ch["key"], vname + ".png")
                if not os.path.isfile(p):
                    bad.append([p, "missing"])
                    continue
                a = G.read_png(p)
                n = int((a[..., 3] > 0.02).sum())
                checked.append([os.path.relpath(p, repo), n])
                if n < 2000:
                    bad.append([p, "blank or near-blank: %d opaque px" % n])
                cells[(ch["key"], vname)] = G.box2(a)
        report["blank"] = dict(files=len(checked), failures=bad)
        if bad:
            report["ok"] = False

        cw, chh = resx // 2, resy // 2
        lab = 40
        # one sheet per character: four views in a row
        for ch in report["chars"]:
            sheet = np.zeros((chh + lab, 4 * cw, 4), dtype=np.float32)
            sheet[..., 0:3] = np.array((0.055, 0.060, 0.075))
            sheet[..., 3] = 1.0
            for i, (vname, _, _) in enumerate(VIEWS):
                a = cells.get((ch["key"], vname))
                if a is None:
                    continue
                al = a[..., 3:4]
                dst = sheet[lab:lab + chh, i * cw:(i + 1) * cw, 0:3]
                sheet[lab:lab + chh, i * cw:(i + 1) * cw, 0:3] = a[..., 0:3] * al + dst * (1.0 - al)
                G.draw_text(sheet, vname.upper(), i * cw + 8, lab + 8, 2, (0.80, 0.78, 0.70))
            t1 = "%s  %s  (%s)  wear %.2f" % (ch["calling"].upper(), ch["armour"]["name"],
                                              ch["rarity"].upper(), ch["wear"])
            t2 = "%s + %s" % (ch["weapon"]["name"],
                              ", ".join(a["name"] for a in ch["accessories"]) +
                              (", " + ch["helm"]["name"] if ch["helm"] else ""))
            G.draw_text(sheet, t1[:96], 8, 6, 2, (0.92, 0.88, 0.74))
            G.draw_text(sheet, t2[:150], 8, 24, 1, (0.74, 0.76, 0.82))
            G.write_png(os.path.join(outdir, "_sheet_%s.png" % ch["key"]), sheet)

        # the overview: all ten, front view, five across
        cols, rows_n = 5, 2
        ow, oh = cw, chh + lab
        over = np.zeros((rows_n * oh, cols * ow, 4), dtype=np.float32)
        over[..., 0:3] = np.array((0.045, 0.050, 0.062))
        over[..., 3] = 1.0
        for i, ch in enumerate(report["chars"][:10]):
            cx, cy = (i % cols) * ow, (i // cols) * oh
            a = cells.get((ch["key"], "front"))
            if a is not None:
                al = a[..., 3:4]
                dst = over[cy + lab:cy + lab + chh, cx:cx + cw, 0:3]
                over[cy + lab:cy + lab + chh, cx:cx + cw, 0:3] = a[..., 0:3] * al + dst * (1.0 - al)
            G.draw_text(over, "%d %s" % (i + 1, ch["calling"].upper()), cx + 8, cy + 6, 2,
                        (0.92, 0.88, 0.74))
            G.draw_text(over, "%s %s" % (ch["rarity"].upper(), ch["armour"]["tier_name"]),
                        cx + 8, cy + 24, 1, (0.72, 0.80, 0.88))
        G.write_png(os.path.join(outdir, "_overview.png"), over)
    except Exception:
        import traceback
        report["ok"] = False
        report["errors"].append("sheets: %s" % traceback.format_exc()[-900:])

    with open(os.path.join(outdir, "_report.json"), "w") as f:
        json.dump(report, f, indent=1)
    print("SHOWCASEGEN " + json.dumps(dict(
        ok=report["ok"], chars=len(report["chars"]),
        errors=report["errors"][:2],
        blank=report["blank"].get("failures", [])[:5],
        faults=report["fit_faults"][:40])))


if __name__ == "__main__":
    main()
