class_name Gear
extends RefCounted
## EQUIPMENT. Ported from the old game (roster.gd FAMILIES / WEAPONS / ARMOUR,
## rig.gd equip) and widened: every townsperson carries what their trade uses,
## heroes carry their class family at their bought tier. KayKit rigs carry
## dedicated attachment bones (handslot.r, handslot.l, chest), so a mesh
## parented there follows the hand through every animation.

const ADV := "res://addons/kaykit_character_pack_adventures/Assets/gltf/"
const KIT := "res://assets/gear/"

## a class is a body + weapon FAMILY + offhand (old roster CLASSES)
const FAMILIES := {
    "blade":  [ADV + "dagger.gltf", ADV + "sword_1handed.gltf", ADV + "sword_2handed.gltf", ADV + "sword_2handed_color.gltf"],
    "axe":    [ADV + "axe_1handed.gltf", ADV + "axe_1handed.gltf", ADV + "axe_2handed.gltf", ADV + "axe_2handed.gltf"],
    "arcane": [ADV + "wand.gltf", ADV + "wand.gltf", ADV + "staff.gltf", ADV + "staff.gltf"],
    "ranged": [ADV + "crossbow_1handed.gltf", ADV + "crossbow_1handed.gltf", ADV + "crossbow_2handed.gltf", ADV + "crossbow_2handed.gltf"],
}
## tiered goods (old roster WEAPONS / ARMOUR, numbers unchanged). Top tiers
## reuse geometry and separate themselves by SIZE and GLOW.
const WEAPONS := [
    {"name": "bare hands", "cost": 0, "atk": 0, "scale": 0.0, "glow": 0.0, "dice": [1, 4]},
    {"name": "plain steel", "cost": 60, "atk": 4, "scale": 1.0, "glow": 0.0, "dice": [1, 6]},
    {"name": "fine steel", "cost": 160, "atk": 9, "scale": 1.05, "glow": 0.0, "dice": [1, 8]},
    {"name": "runed", "cost": 420, "atk": 16, "scale": 1.12, "glow": 0.5, "dice": [1, 10]},
    {"name": "dragontooth", "cost": 1100, "atk": 26, "scale": 1.25, "glow": 1.0, "dice": [1, 12]},
    # L3: never forged in Bellmire - only ever found below, grown in the scar's wild magic
    {"name": "scarforged", "cost": 0, "atk": 34, "scale": 1.3, "glow": 1.3, "found": true, "dice": [2, 8]},
]
## S87 WRITE-DOWN (B103's ask, closed): this ARMOUR copy is NOT read by any game path. The till is
## Roster.ARMOUR (roster.gd:183, Roster.buy_armour) and so are hp/ac (roster.gd:337/:368). Its ONLY reader is
## chatcmd.gd's ARMOURY drift arm (:2744), which compares it to Roster.ARMOUR - so it is KEPT as that
## arm's second authority, not deleted. Gear.WEAPONS differs: town.gd:4571 dresses the smithy stall from it.
## Do not wire a shop or a stat to this table; change prices in roster.gd and mirror them here.
const ARMOUR := [
    {"name": "rags", "cost": 0, "hp": 0, "ac": 0},
    {"name": "leather", "cost": 50, "hp": 10, "ac": 1},
    {"name": "chainmail", "cost": 150, "hp": 26, "ac": 3},
    {"name": "plate", "cost": 400, "hp": 48, "ac": 5},
    {"name": "warded plate", "cost": 1000, "hp": 80, "ac": 7},
    {"name": "scarwoven mail", "cost": 0, "hp": 110, "ac": 8, "found": true},
]
## the trades: [right hand, left hand, left bone]
const ROLE_GEAR := {
    "chief":      [ADV + "staff.gltf", ADV + "spellbook_closed.gltf", "handslot.l"],
    "guard":      [ADV + "sword_1handed.gltf", ADV + "shield_square_color.gltf", "handslot.l"],
    "gateguard":  [KIT + "halberd.gltf", ADV + "shield_badge_color.gltf", "handslot.l"],
    "lookout":    [ADV + "crossbow_2handed.gltf", "", ""],
    "farmer":     [KIT + "shovel.gltf", "", ""],
    "lumberjack": [KIT + "axe.gltf", "", ""],
    "miner":      [KIT + "pickaxe.gltf", KIT + "lantern.gltf", "handslot.l"],
    "smith":      [KIT + "hammer.gltf", KIT + "tongs.gltf", "handslot.l"],
    "blacksmith": [KIT + "hammer.gltf", KIT + "tongs.gltf", "handslot.l"],
    "armorer":    [ADV + "sword_2handed_color.gltf", "", ""],
    "healer":     [ADV + "staff.gltf", ADV + "spellbook_open.gltf", "handslot.l"],
    "apothecary": [ADV + "wand.gltf", ADV + "spellbook_open.gltf", "handslot.l"],
    "fletcher":   [KIT + "bow_A_withString.gltf", ADV + "quiver.gltf", "chest"],
    "innkeeper":  [ADV + "mug_full.gltf", ADV + "mug_full.gltf", "handslot.l"],
    "tavern":     [ADV + "mug_full.gltf", "", ""],
    "trader":     [KIT + "map_rolled.gltf", "", ""],
    "merchant":   [KIT + "journal_closed.gltf", "", ""],
    "miller":     [KIT + "saw.gltf", "", ""],
    "store":      [KIT + "knife.gltf", "", ""],
    "baker":      [KIT + "mallet.gltf", "", ""],
    "washer":     [KIT + "bucket_metal.gltf", "", ""],
    "priest":     [ADV + "staff.gltf", ADV + "spellbook_closed.gltf", "handslot.l"],
    "crier":      [KIT + "map_rolled.gltf", KIT + "lantern.gltf", "handslot.l"],
    "watch":      [ADV + "sword_1handed.gltf", KIT + "torch.gltf", "handslot.l"],
    "carter":     [KIT + "rope_bundle_A.gltf", "", ""],
    "child":      ["", "", ""],
}
const PEASANT_KIT := ["", ADV + "mug_empty.gltf", KIT + "lantern.gltf", KIT + "torch.gltf", ""]

static var _cache := {}

static func skeleton(n: Node) -> Skeleton3D:
    var st: Array = [n]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is Skeleton3D:
            return c
        for g in c.get_children():
            st.append(g)
    return null

## Attach a mesh (full res:// path) to a bone. `slot` names it so re-equipping
## replaces rather than stacks.
## S24: how far (mesh units, before scale) the pack staff's grip slides toward its butt. S21 measured +0.25:
## shaft clear of the floor in Idle 0.10-0.15 m on a mage; the Cheer inversion it causes is staff_grip.gd's job.
const STAFF_GRIP_SHIFT := 0.25
const STAFF_GRIP := preload("res://scripts/staff_grip.gd")

static func equip(model_root: Node, path: String, bone := "handslot.r", slot := "weapon",
                  scale := 1.0, glow := 0.0) -> Node3D:
    var sk := skeleton(model_root)
    if sk == null:
        return null
    var old := sk.get_node_or_null(NodePath("eq_" + slot))
    if old:
        old.free()
    if path == "" or sk.find_bone(bone) < 0 or not ResourceLoader.exists(path):
        return null
    if not _cache.has(path):
        _cache[path] = load(path)
    ## S35: ResourceLoader.exists() is true for an un-imported asset whose load() still returns
    ## null (a worktree with a partial .godot/imported). Skip the piece, never instantiate a null.
    var ps := _cache[path] as PackedScene
    if ps == null:
        _cache.erase(path)
        return null
    var att := BoneAttachment3D.new()
    att.name = "eq_" + slot
    att.bone_name = bone
    sk.add_child(att)
    var m := ps.instantiate() as Node3D
    if m == null:
        att.free()
        return null
    m.scale = Vector3.ONE * scale
    m.rotation_degrees = held_rot(path)
    att.add_child(m)
    if path.begins_with(DUN + "staff_"):
        ## S24: the pack staff's grip slides toward the butt, and the inverted fist turns it end for end.
        ## The model's own children move, so deco_piece measures the moved bounds and the wrap stays in the fist.
        for c in m.get_children():
            if c is Node3D:
                (c as Node3D).position.y += STAFF_GRIP_SHIFT
        m.set_meta("staff_grip", true)
        var g: Node = STAFF_GRIP.new()
        g.name = "staff_grip"
        g.set("held", m)
        att.add_child(g)
    if glow > 0.0:
        ignite(m, glow)
    return m

## the old rig's smoulder: runed weapons ember, dragontooth burns cold-white
static func ignite(n: Node, amount: float) -> void:
    var st: Array = [n]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is MeshInstance3D:
            var mi: MeshInstance3D = c
            if mi.mesh:
                for i in range(mi.mesh.get_surface_count()):
                    var src: Material = mi.get_active_material(i)
                    if src is StandardMaterial3D:
                        var d: StandardMaterial3D = src.duplicate()
                        d.emission_enabled = true
                        d.emission = Color(1.0, 0.62, 0.22).lerp(Color(0.65, 0.85, 1.0), clampf(amount - 0.5, 0.0, 1.0) * 0.7)
                        if amount >= 1.25:      # scarforged: the scar's violet, a smoulder not a lamp
                            d.emission = Color(0.78, 0.36, 1.0)
                            d.emission_energy_multiplier = 0.16
                        d.emission_energy_multiplier = amount * 0.30
                        mi.set_surface_override_material(i, d)
        for g in c.get_children():
            st.append(g)

## dress a townsperson for their trade
static func dress_role(model_root: Node, role: String, seed_i: int = 0) -> void:
    var g: Array = ROLE_GEAR.get(role, [])
    if g.is_empty():
        if role == "peasant":
            var pk: String = PEASANT_KIT[seed_i % PEASANT_KIT.size()]
            equip(model_root, pk, "handslot.r", "weapon", 0.62 if pk.begins_with(KIT) else 1.0)
        return
    ## RPG-tools / weapon-bits are modelled bigger than the Adventurers' own
    ## weapons; in a KayKit hand they read ~1.6x too large
    var s0 := 0.62 if String(g[0]).begins_with(KIT) else 1.0
    var s1 := 0.62 if String(g[1]).begins_with(KIT) else 1.0
    equip(model_root, String(g[0]), "handslot.r", "weapon", s0)
    if String(g[1]) != "":
        equip(model_root, String(g[1]), String(g[2]), "offhand", s1)

## a hero's weapon at their bought tier (old roster weapon_mesh/weapon_look)
static func weapon_path(family: String, tier: int) -> String:
    if tier <= 0:
        return ""
    var f: Array = FAMILIES.get(family, FAMILIES["blade"])
    return String(f[clampi(tier - 1, 0, f.size() - 1)])

## ---------------------------------------------------------------- L3 kinds
## Within a family a hero may carry another KIND of weapon (!forge <kind>). The
## numbers are the tier's, whatever the kind - the old balance is untouched; a
## kind is its look and its name. The family's own kind (blade, axe, arcane,
## ranged) is the old progression, so every existing hero looks as before.
## Meshes per tier 1..5: KayKit Adventurers, the KayKit weapon bits in
## assets/gear (modelled bigger: x0.62 in a KayKit hand) and the KayKit
## skeleton pack's own grave-steel for the found-only tier.
const SKA := "res://addons/kaykit_character_pack_skeletons/Assets/gltf/"
## S16 (System 2, first half): the KayKit DUNGEON pack's tiered weapons (CC0, LICENSE in the dir).
## KINDS below IS the family+tier -> model map (family, then per-tier kit). One family is wired end to
## end so far: blade/sword tiers 1-3 take the pack's common/uncommon/rare sword.
## S17 (System 2, second half, part 1): axe/axe and axe/mace tiers 1-3 take the pack's axe_* and
## hammer_* the same way (tiers 4-5 keep their existing kit). Same 0.8 hand_scale: measured off the
## .glb accessors, axe 0.89/0.95/0.95 and hammer 0.86/0.87/0.90 long, origin in the grip.
## S18 (System 2, second half, part 2): dagger tiers 1-3 take the pack's dagger_*. Measured off the .glb
## accessors: 0.90/1.03/1.15 long, origin at the grip -> hand_scale 0.5 (0.45/0.54/0.65 m in the fist).
## S19: staff and crossbow tiers 1-3 take the pack's staff_*/crossbow_*. Neither needed the held rotation
## S18 thought: both are built on the SAME axes as the Adventurers' staff/crossbow they replace. The S18
## staff read as a wand because it was scaled 0.8 - see hand_scale.
const DUN := "res://assets/gear/dungeon/"
## S45 (System 6, artifact tier): the found-only tier 5 (C-58) takes Quaternius Ultimate RPG Items' _Golden set (CC0,
## LICENSE in the dir) for the 7 kinds it covers - sword, greatsword, dagger, axe, greataxe, mace, bow. staff,
## quarterstaff, wand and crossbow keep their kit[4]. Art (ARTIFACT_GOLD_VS_SCARRED.md): keep the gold, no red tint.
const ART := "res://assets/gear/artifact/"
## S80 (System 8 row (b)): the Quaternius Medieval Weapons shields (CC0, LICENSE in the dir), armour tiers 4-5.
const SHD := "res://assets/gear/shields/"
const KINDS := {
    "sword":      {"family": "blade", "noun": "sword", "kit": [DUN + "sword_common.glb", DUN + "sword_uncommon.glb", DUN + "sword_rare.glb", KIT + "sword_C.gltf", ART + "sword_golden.glb"]},
    "greatsword": {"family": "blade", "noun": "greatsword", "kit": [ADV + "sword_2handed.gltf", ADV + "sword_2handed.gltf", ADV + "sword_2handed_color.gltf", KIT + "sword_D.gltf", ART + "sword_big_golden.glb"]},
    "dagger":     {"family": "blade", "noun": "dagger", "kit": [DUN + "dagger_common.glb", DUN + "dagger_uncommon.glb", DUN + "dagger_rare.glb", ADV + "dagger.gltf", ART + "dagger_golden.glb"]},
    "spear":      {"family": "blade", "noun": "spear", "kit": [KIT + "spear_A.gltf", KIT + "spear_A.gltf", KIT + "halberd.gltf", KIT + "halberd.gltf", KIT + "halberd.gltf"]},
    "axe":        {"family": "axe", "noun": "axe", "kit": [DUN + "axe_common.glb", DUN + "axe_uncommon.glb", DUN + "axe_rare.glb", KIT + "axe_B.gltf", ART + "axe_small_golden.glb"]},
    "mace":       {"family": "axe", "noun": "mace", "kit": [DUN + "hammer_common.glb", DUN + "hammer_uncommon.glb", DUN + "hammer_rare.glb", KIT + "hammer_B.gltf", ART + "hammer_double_golden.glb"]},
    # S20 (System 2 engine half, art's SYSTEM2_WEAPONS (b)): a GREATAXE is double-headed, not a hatchet. Tiers 1-3
    # take the pack's axeDouble_*; 4-5 keep the axe kit until a heavier model exists. "Bearded Greataxe" (t2) and
    # "Ash-Maul Greataxe" (t4) reach it through D94_KIND_WORDS. Added AFTER "mace" so kinds_of("axe")[0] stays "axe".
    "greataxe":   {"family": "axe", "noun": "greataxe", "kit": [DUN + "axeDouble_common.glb", DUN + "axeDouble_uncommon.glb", DUN + "axeDouble_rare.glb", KIT + "axe_B.gltf", ART + "axe_double_golden.glb"]},
    "staff":      {"family": "arcane", "noun": "staff", "kit": [DUN + "staff_common.glb", DUN + "staff_uncommon.glb", DUN + "staff_rare.glb", KIT + "staff_B.gltf", SKA + "Skeleton_Staff.gltf"]},
    # D94b: an arcane MACE ("Parish Iron Mace") had no kind and fell back to a staff
    "sceptre":    {"family": "arcane", "noun": "mace", "kit": [KIT + "hammer_A.gltf", KIT + "hammer_A.gltf", KIT + "hammer_B.gltf", KIT + "hammer_B.gltf", KIT + "hammer_B.gltf"]},
    "wand":       {"family": "arcane", "noun": "wand", "kit": [ADV + "wand.gltf", KIT + "wand_A.gltf", ADV + "wand.gltf", KIT + "wand_A.gltf", KIT + "wand_A.gltf"]},
    "crossbow":   {"family": "ranged", "noun": "crossbow", "kit": [DUN + "crossbow_common.glb", DUN + "crossbow_uncommon.glb", DUN + "crossbow_rare.glb", ADV + "crossbow_2handed.gltf", SKA + "Skeleton_Crossbow.gltf"]},
    "bow":        {"family": "ranged", "noun": "bow", "kit": [KIT + "bow_A_withString.gltf", KIT + "bow_A_withString.gltf", KIT + "bow_A_withString.gltf", KIT + "bow_A_withString.gltf", ART + "bow_golden.glb"]},
    # L4: the monk's open hand - a quarterstaff, or bare wrapped fists (no mesh)
    "quarterstaff": {"family": "open", "noun": "quarterstaff", "kit": [ADV + "staff.gltf", ADV + "staff.gltf", ADV + "staff.gltf", KIT + "staff_B.gltf", SKA + "Skeleton_Staff.gltf"]},
    "wraps":      {"family": "open", "noun": "hand wraps", "bare": true, "kit": ["", "", "", "", ""]},
}

static func kinds_of(family: String) -> Array:
    var out: Array = []
    for k in KINDS:
        if String(KINDS[k]["family"]) == family:
            out.append(k)
    return out

## the mesh for a kind at a tier ("" for bare hands)
static func kind_path(kind: String, tier: int) -> String:
    if tier <= 0 or not KINDS.has(kind):
        return ""
    var l: Array = KINDS[kind]["kit"]
    return String(l[clampi(tier - 1, 0, l.size() - 1)])

## S19: a per-path HELD ROTATION. The hand slot's +Y points FORWARD out of the fist in the idle pose, so
## a mesh built along +Y lies horizontal (s19_side, first run: the pack staff at x1.9 was a lance).
## A staff wants its shaft UP. MEASURED, not guessed (tools/_s19_hand.gd AXIS lines, posed idle): the
## slot's +Y is world-forward and its +X is world-DOWN (-0.99), so +90 about Z turns the mesh's +Y onto
## the slot's -X = world UP. (A first guess, -90 about X, laid it sideways across the body.)
static func held_rot(path: String) -> Vector3:
    if path.begins_with(DUN + "staff_"):
        return Vector3(0, 0, 90)
    ## S45: the _Golden bow is built along +Y (limbs) with its belly toward +X; held plain it lay FLAT along the
    ## forearm (s45_side, first run). The staff's +90 about Z stands the limbs UP and turns the belly forward.
    if path == ART + "bow_golden.glb":
        return Vector3(0, 0, 90)
    ## S163: the tier-5 _Golden dagger read BLIND held plain (blade edge-on to the front camera: 13 px minor). Art's
    ## prescription (docs/art/THE_DAGGER_READ_BLIND_BECAUSE_OF_FACING_NOT_SIZE_AND_MY_OWN_SEARCH_HID_THE_FIX.md),
    ## measured on a posed knight: the bow's (0, 0, 90) turns the FACE to the front (38 px minor), with hand_scale 0.60.
    if path.begins_with(ART + "dagger_"):
        return Vector3(0, 0, 90)
    ## S20: the pack crossbow is built with its stock along the mesh's +Z (prod at the +Z end), its prod (bow arms)
    ## along +X and its thin axis along +Y. Held plain, the prod stood VERTICAL and the stock pointed ACROSS the
    ## body (s19_side). Art's (0, 0, 90.06) was tried first: it levelled the prod but left the stock across the
    ## body (AXIS: prod +X along world -Z). The wanted map in the slot frame (+Y forward, +X down, measured S19) is
    ## mesh +Z -> slot +Y (stock forward), mesh +Y -> slot -X (up), mesh +X -> slot -Z (prod across): Godot YXZ
    ## euler (-90, 0, 90), solved off that matrix, not guessed. tools/_s20_hand.gd gates prod level + stock forward.
    ## S95: art's 35 deg ROLL about the slot's own forward axis (slot +Y), measured on the corrected local-frame
    ## weaponfit gate (show 0.757 vs SHOW_MIN 0.70) and on the picture: held level the prod lay in a horizontal
    ## plane and every camera caught it edge-on as a lath. Godot's YXZ euler is Basis = Ry * Rx * Rz with Ry
    ## OUTERMOST, i.e. applied in the PARENT (slot) frame, so a roll about slot +Y is exactly the euler's y term:
    ## Ry(35) * [Ry(0) Rx(-90) Rz(90)] == euler (-90, 35, 90). Derived, not guessed; scale stays x1.0.
    ## tools/_s20_hand.gd now gates "prod CANTED 25-45 deg, stock forward" instead of "prod level".
    if path.begins_with(DUN + "crossbow_"):
        return Vector3(-90, 35, 90)
    return Vector3.ZERO

## S20: the off hand's scale. The pack shield is built like the Adventurers' shields it replaces (face in the mesh
## XY plane, centred on its origin, boss toward +Z) so it needs NO held rotation on handslot.l; it is smaller
## (0.68-0.76 wide against shield_square's 0.88), so x1.2 brings it to the kit shield's size.
static func offhand_scale(path: String) -> float:
    if path.begins_with(DUN + "shield_"):
        return 1.2
    if path.begins_with(SHD):
        return float(SHD_SCALE.get(path.get_file(), 1.0))
    return 1.0

## S80: measured on the hand by tools/_s80_shield.gd at x1.0 (largest world dim against the pack's rare shield at its
## x1.2: heater_2 2.34x, round_2 1.86x, celtic 3.97x), not off a file print. Heater/round brought to ~1.0x; the celtic
## is a tall kite, so ~1.2x.
const SHD_SCALE := {"shield_heater_2.fbx": 0.43, "shield_round_2.fbx": 0.54, "shield_celtic_golden.fbx": 0.30}

## the KayKit weapon bits are modelled ~1.6x a KayKit hand
## D94b: except the bow - at x0.62 the KayKit bow was a toy in the fist and a "Greatbow" read small
static func hand_scale(path: String) -> float:
    if path.ends_with("bow_A_withString.gltf"):
        return 0.92
    ## S19: the S18 staff was not lying wrong, it was SMALL. The Adventurers' own staff.gltf - which reads
    ## as a staff in every mage's hand - is built the SAME way (along +Y, origin in the shaft, -0.90..1.25,
    ## 2.15 long); the pack staff is 0.91/1.12/1.16 long, so at 0.8 it was a 0.7-0.9 m wand. x1.9 puts it
    ## at 1.7/2.1/2.2 m, the Adventurers' length.
    if path.begins_with(DUN + "staff_"):
        return 1.9
    ## S19: the pack crossbow is built along +Z exactly like the Adventurers' crossbow_1handed (z -0.28..0.94,
    ## held at x1.0); 0.64-0.76 deep and 0.69-1.04 wide, so it needs no held rotation - only x1.0, not 0.8.
    if path.begins_with(DUN + "crossbow_"):
        return 1.0
    ## S45: the _Golden set is built along +Y with the grip at the origin, like the pack sword, and BIG - measured off
    ## the .blend bounds: sword 2.30, big sword 2.74, dagger 1.39, axe 1.58, double axe 2.15, double hammer 2.53, bow 2.17.
    if path.begins_with(ART + "dagger_"):   # S163: 0.5 -> 0.60, art's prescribed pair with held_rot (0,0,90); 0.834 m
        return 0.60
    if path.begins_with(ART + "hammer_"):
        return 0.4
    if path.begins_with(ART):
        return 0.6
    if path.begins_with(DUN + "dagger_"):   # S18: pack daggers are 0.9-1.15 long; 0.5 puts them at a long knife
        return 0.5
    if path.begins_with(DUN):   # S16: dungeon-pack blades are ~1.3-1.9 long; 0.8 puts the common at an arming sword
        return 0.8
    return 0.62 if path.begins_with(KIT) else 1.0

## ---------------------------------------------------------------- L3 armour, worn
## Armour shows on the body: boots from leather, pauldrons from chainmail, a
## helm from plate (only on a head with no helmet or hat of its own), warded
## plate glows faintly, scarwoven mail wears the scar's violet. Simple shapes on
## the KayKit bones, coloured per tier. Hero bodies are dressed through
## Roster.offhand_bone -> rank_trim (both called by HeroBody.refresh).
const ARMOUR_LOOK := [
    {},
    {"col": Color(0.42, 0.28, 0.17), "metal": 0.0, "boots": true},
    {"col": Color(0.58, 0.60, 0.62), "metal": 0.7, "boots": true, "pauldrons": true},
    {"col": Color(0.78, 0.80, 0.84), "metal": 0.9, "boots": true, "pauldrons": true, "helm": true},
    {"col": Color(0.80, 0.84, 0.92), "metal": 0.9, "boots": true, "pauldrons": true, "helm": true, "glow": Color(0.45, 0.65, 1.0), "e": 0.12},
    {"col": Color(0.24, 0.16, 0.30), "metal": 0.7, "boots": true, "pauldrons": true, "helm": true, "glow": Color(0.70, 0.30, 1.0), "e": 0.18},
]
static var _dressing: Dictionary = {}

static func dress_armour(model_root: Node, tier: int, piece := "") -> void:
    var sk := skeleton(model_root)
    if sk == null:
        return
    for slot in ["eq_boot_l", "eq_boot_r", "eq_pauldron_l", "eq_pauldron_r", "eq_helm",
                 "eq_bracer_l", "eq_bracer_r", "eq_robe"]:
        var old := sk.get_node_or_null(NodePath(slot))
        if old:
            old.free()
    # D94: a named piece is the tier's face - its own colour, cut and trim (armour_piece_look)
    var look: Dictionary = ARMOUR_LOOK[clampi(tier, 0, ARMOUR_LOOK.size() - 1)]
    if piece != "" and tier > 0:
        look = armour_piece_look(piece, tier)
    if look.is_empty():
        return
    var m := StandardMaterial3D.new()
    m.albedo_color = look["col"]
    m.metallic = float(look["metal"])
    m.roughness = 0.45 if float(look["metal"]) > 0.0 else 0.85
    if look.has("glow"):
        m.emission_enabled = true
        m.emission = look["glow"]
        m.emission_energy_multiplier = float(look.get("e", 0.15))
    if bool(look.get("boots", false)):
        for s in ["l", "r"]:
            var b := _piece(sk, "foot." + s, "eq_boot_" + s, m)
            if b:
                # D94/D95 fit: laid out in model axes (the foot bone is pitched 45 deg, which
                # tipped the old box off the ground), sized from the measured KayKit foot
                _align(b, sk, "foot." + s)
                _part(b, _cap(0.145, 0.46), m, Vector3(0, -0.065, 0.10), Vector3(PI * 0.5, 0, 0), Vector3(1, 1, 0.59))
                _part(b, _cyl(0.14, 0.145, 0.12, 10), m, Vector3(0, 0.03, 0.0))
    var trim := int(look.get("trim", 0))
    var trim_m := StandardMaterial3D.new()
    trim_m.albedo_color = (look["col"] as Color).darkened(0.35)
    trim_m.metallic = minf(1.0, float(look["metal"]) + 0.2)
    trim_m.roughness = 0.5
    if bool(look.get("pauldrons", false)):
        var small := bool(look.get("small_pauldrons", false))
        for s in ["l", "r"]:
            var p := _piece(sk, "upperarm." + s, "eq_pauldron_" + s, m)
            if p:
                var sm := SphereMesh.new()
                sm.radius = 0.20 if small else 0.26
                sm.height = 0.22 if small else 0.30
                sm.is_hemisphere = true
                p.mesh = sm
                p.position = Vector3(0, 0.08, 0)
                if trim == 1:       # riveted: three studs on the plate
                    for k in range(3):
                        _part(p, _sph(0.035), trim_m, Vector3(-0.10 + 0.10 * k, 0.12 if not small else 0.09, 0.12))
                elif trim == 2:     # banded: a second lame under the first
                    _part(p, _tor(sm.radius - 0.04, sm.radius + 0.01), trim_m, Vector3(0, 0.0, 0))
    if bool(look.get("bracers", false)):
        for s in ["l", "r"]:
            var br := _piece(sk, "lowerarm." + s, "eq_bracer_" + s, m)
            if br:
                br.mesh = _cyl(0.095, 0.11, 0.24, 10)
                br.position = Vector3(0, 0.17, 0)
                if trim > 0:
                    _part(br, _cyl(0.115, 0.115, 0.03, 10), trim_m, Vector3(0, 0.10 * (1 if trim == 1 else -1), 0))
    if bool(look.get("robe", false)):
        # a caster's cut: a robe SKIRT round the hips (model y 0.27..0.62, over the measured body
        # 0.86 x 0.78), flared to the hem, with a trim band. (A flat front panel was tried and read
        # as a signboard held to the chest - D95 fit pass 3.)
        var rb := _piece(sk, "chest", "eq_robe", m)
        if rb:
            _align(rb, sk, "chest")
            _part(rb, _cyl(0.45, 0.52, 0.36, 14), m, Vector3(0, -0.52, 0.0), Vector3.ZERO, Vector3(1.0, 1.0, 0.92))
            _part(rb, _cyl(0.525, 0.53, 0.045, 14), trim_m, Vector3(0, -0.69 + 0.10 * trim, 0.0), Vector3.ZERO, Vector3(1.0, 1.0, 0.92))
            if look.has("glow"):
                _part(rb, _sph(0.045, 0.06), trim_m, Vector3(0, -0.38, 0.45))
    if bool(look.get("helm", false)) and not _has_headwear(model_root):
        var hm := _piece(sk, "head", "eq_helm", m)
        if hm:
            var cm := SphereMesh.new()
            cm.radius = 0.66
            cm.height = 0.66
            cm.is_hemisphere = true
            hm.mesh = cm
            hm.position = Vector3(0, 0.36, 0)
            hm.scale = Vector3(1.0, 0.85, 1.0)
            var brim := MeshInstance3D.new()
            var tor := TorusMesh.new()
            tor.inner_radius = 0.6
            tor.outer_radius = 0.74
            brim.mesh = tor
            brim.material_override = m
            brim.position = Vector3(0, 0.02, 0)
            brim.scale = Vector3(1.0, 0.5, 1.0)
            hm.add_child(brim)
            var hv := int(look.get("helm_v", 0))
            if hv == 0:
                var crest := MeshInstance3D.new()
                var pm := BoxMesh.new()
                pm.size = Vector3(0.10, 0.22, 0.95)
                crest.mesh = pm
                crest.material_override = m
                crest.position = Vector3(0, 0.64, 0)
                hm.add_child(crest)
            elif hv == 2:       # D94: a tall plume instead of a crest
                _part(hm, _cyl(0.0, 0.10, 0.55, 6), trim_m, Vector3(0, 0.88, -0.10), Vector3(-0.35, 0, 0))
            else:               # D94: a nasal bar and no crest
                _part(hm, _box(0.10, 0.36, 0.08), trim_m, Vector3(0, 0.0, 0.66))

static func _piece(sk: Skeleton3D, bone: String, slot: String, m: Material) -> MeshInstance3D:
    if sk.find_bone(bone) < 0:
        return null
    var att := BoneAttachment3D.new()
    att.name = slot
    att.bone_name = bone
    sk.add_child(att)
    var mi := MeshInstance3D.new()
    mi.material_override = m
    att.add_child(mi)
    return mi

static func _has_headwear(model_root: Node) -> bool:
    var st: Array = [model_root]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is MeshInstance3D and (c as MeshInstance3D).visible and (String(c.name).contains("Helmet") or String(c.name).contains("Hat") or String(c.name).contains("Hood")):
            return true
        for g in c.get_children():
            st.append(g)
    return false

static func dress_hero(model_root: Node, family: String, tier: int, offhand := "", off_bone := "handslot.l") -> void:
    var w: Dictionary = WEAPONS[clampi(tier, 0, WEAPONS.size() - 1)]
    equip(model_root, weapon_path(family, tier), "handslot.r", "weapon", float(w["scale"]), float(w["glow"]))
    equip(model_root, offhand, off_bone, "offhand")


## ---------------------------------------------------------------- clothing
## The KayKit bodies stay as they are (Mr. E's call). Each file carries its
## whole prop set as extra meshes (Knight: 2 swords + 4 shields) and every one
## showed at once - in the old game too. Hide everything that is not the body,
## so the gear above is the only thing in the hands.
const BODY_PARTS := ["Leg", "Head", "Body", "Arm", "Cape", "Helmet", "Hat", "Mask"]

static func strip_props(model_root: Node) -> void:
    ## the kit's own props ALSO arrive under BoneAttachment3D nodes, so ours are
    ## told apart by name (every Gear attachment is "eq_*") - never by type
    var st: Array = [model_root]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if String(c.name).begins_with("eq_"):
            continue
        if c is MeshInstance3D:
            var nm := String(c.name)
            var body := false
            for k in BODY_PARTS:
                if nm.contains(k):
                    body = true
            if not body:
                (c as MeshInstance3D).visible = false
        for g in c.get_children():
            st.append(g)

## role cloaks: who wears what over the body
const ROLE_CAPE := {
    "chief": Color(0.14, 0.18, 0.48), "healer": Color(0.92, 0.92, 0.86),
    "apothecary": Color(0.20, 0.45, 0.25), "guard": Color(0.16, 0.26, 0.62),
    "gateguard": Color(0.16, 0.26, 0.62), "lookout": Color(0.16, 0.26, 0.62),
    "fisher": Color(0.30, 0.42, 0.50), "miner": Color(0.25, 0.22, 0.20),
    "priest": Color(0.92, 0.88, 0.70), "watch": Color(0.16, 0.26, 0.62), "baker": Color(0.95, 0.92, 0.85),
    "washer": Color(0.55, 0.62, 0.70),
}

## ---- L5: a people's look. Body proportions (set, never multiplied, so a
## re-dress is idempotent), the skin of head and arms tinted from the mesh's own
## material, and a few small parts on the head bone: elven ears, a dwarf's
## beard, an orc's tusks, the scar's shard on a scarkin brow.
static func species_look(model_root: Node, species: String) -> void:
    var sp: Dictionary = Roster.SPECIES.get(species, {})
    if model_root is Node3D:
        (model_root as Node3D).scale = sp.get("scale", Vector3.ONE)
    var skin: Color = sp.get("skin", Color(1, 1, 1))
    var st: Array = [model_root]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is MeshInstance3D and not String(c.name).begins_with("eq_"):
            var nm := String(c.name)
            if nm.ends_with("_Head") or nm.contains("Arm"):
                var mi: MeshInstance3D = c
                for i in range(mi.mesh.get_surface_count()):
                    var base: Material = mi.mesh.surface_get_material(i)
                    if base is StandardMaterial3D:
                        var d: StandardMaterial3D = (base as StandardMaterial3D).duplicate()
                        d.albedo_color = d.albedo_color * skin
                        mi.set_surface_override_material(i, d)
        for g in c.get_children():
            if not String(g.name).begins_with("eq_"):
                st.append(g)
    var sk := skeleton(model_root)
    if sk == null:
        return
    var old := sk.get_node_or_null("eq_species")
    if old:
        old.free()
    var parts: Array = sp.get("parts", [])
    if parts.is_empty() or sk.find_bone("head") < 0:
        return
    var att := BoneAttachment3D.new()
    att.name = "eq_species"
    att.bone_name = "head"
    sk.add_child(att)
    var flesh := StandardMaterial3D.new()
    flesh.albedo_color = Color(0.93, 0.74, 0.62) * skin
    for p in parts:
        match String(p):
            "ears":
                for s in [-1.0, 1.0]:
                    var e := MeshInstance3D.new()
                    var pm := PrismMesh.new()
                    pm.size = Vector3(0.16, 0.42, 0.08)
                    e.mesh = pm
                    e.material_override = flesh
                    e.position = Vector3(0.56 * s, 0.50, -0.02)
                    e.rotation = Vector3(0, 0, -0.95 * s)
                    att.add_child(e)
            "beard":
                var bm := StandardMaterial3D.new()
                bm.albedo_color = Color(0.48, 0.30, 0.17)
                var b := MeshInstance3D.new()
                var pr := PrismMesh.new()
                pr.size = Vector3(0.60, 0.42, 0.22)
                b.mesh = pr
                b.material_override = bm
                b.position = Vector3(0, 0.0, 0.40)
                b.rotation = Vector3(PI, 0, 0)
                att.add_child(b)
            "tusks":
                var tm := StandardMaterial3D.new()
                tm.albedo_color = Color(0.95, 0.92, 0.82)
                for s in [-1.0, 1.0]:
                    var t := MeshInstance3D.new()
                    var tp := PrismMesh.new()
                    tp.size = Vector3(0.08, 0.16, 0.06)
                    t.mesh = tp
                    t.material_override = tm
                    t.position = Vector3(0.15 * s, 0.10, 0.47)
                    att.add_child(t)
            "shard":
                var gm := StandardMaterial3D.new()
                gm.albedo_color = Color(0.70, 0.40, 1.0)
                gm.emission_enabled = true
                gm.emission = Color(0.75, 0.40, 1.0)
                gm.emission_energy_multiplier = 1.2
                var g := MeshInstance3D.new()
                var pm2 := PrismMesh.new()
                pm2.size = Vector3(0.12, 0.22, 0.08)
                g.mesh = pm2
                g.material_override = gm
                g.position = Vector3(0, 0.82, 0.44)
                att.add_child(g)

## L4: a calling's own cloak colour
static func _cape_tint(model_root: Node, col: Color) -> void:
    var ms := _cape_meshes(model_root)
    # the hat or hood too, so a calling reads from the front
    var st: Array = [model_root]
    while not st.is_empty():
        var c: Node = st.pop_back()
        # a separate hat mesh only: on the 2.0 hooded rogue the hood IS the head mesh (face and all)
        if c is MeshInstance3D and (c as MeshInstance3D).visible and String(c.name).ends_with("Hat"):
            ms.append(c)
        for g in c.get_children():
            st.append(g)
    for m in ms:
        var mi: MeshInstance3D = m
        for i in range(mi.mesh.get_surface_count()):
            var src: Material = mi.get_active_material(i)
            var d: StandardMaterial3D = (src as StandardMaterial3D).duplicate() if src is StandardMaterial3D else StandardMaterial3D.new()
            d.albedo_color = col
            d.albedo_texture = null       # the atlas would tint it back to the kit colour
            mi.set_surface_override_material(i, d)

static func _cape_meshes(model_root: Node) -> Array:
    var out: Array = []
    var st: Array = [model_root]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is MeshInstance3D and String(c.name).contains("Cape"):
            out.append(c)
        for g in c.get_children():
            st.append(g)
    return out

## livery: the district's banner colour, worn by anyone without a role cloak
static func clothe(model_root: Node, role: String, livery: Color, rank: int = -1) -> void:
    var col: Color = ROLE_CAPE.get(role, livery)
    for m in _cape_meshes(model_root):
        var mi: MeshInstance3D = m
        for i in range(mi.mesh.get_surface_count()):
            var src: Material = mi.get_active_material(i)
            var d: StandardMaterial3D = (src as StandardMaterial3D).duplicate() if src is StandardMaterial3D else StandardMaterial3D.new()
            d.albedo_color = col
            if role == "chief":
                d.emission_enabled = true
                d.emission = Color(0.85, 0.66, 0.2)
                d.emission_energy_multiplier = 0.08
            mi.set_surface_override_material(i, d)
    if rank >= 0:
        rank_trim(model_root, rank)

## Guild rank, worn: a coloured sash across the chest (Unproven bare,
## Novice..Grandmaster climbing bronze -> silver -> gold -> violet).
const RANK_COLOURS := [Color(0, 0, 0, 0), Color(0.55, 0.40, 0.25), Color(0.62, 0.62, 0.62),
    Color(0.35, 0.60, 0.85), Color(0.85, 0.85, 0.90), Color(0.95, 0.75, 0.25), Color(0.70, 0.40, 1.0)]

static func rank_trim(model_root: Node, rank: int) -> void:
    # L3: a hero being dressed (stashed by Roster.offhand_bone) gets their armour on
    if not _dressing.is_empty():
        dress_armour(model_root, int(_dressing.get("armour", 0)), armour_id(_dressing))
        species_look(model_root, Roster.species_of(_dressing))
        var cls: Dictionary = Roster.CLASSES.get(String(_dressing.get("class", "")), {})
        if cls.has("cape"):
            _cape_tint(model_root, cls["cape"])
        dress_cosmetics(model_root, _dressing)
        _dressing = {}
    var sk := skeleton(model_root)
    if sk == null or rank <= 0:
        return
    var old := sk.get_node_or_null("eq_rank")
    if old:
        old.free()
    var att := BoneAttachment3D.new()
    att.name = "eq_rank"
    att.bone_name = "chest"
    sk.add_child(att)
    var sash := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(0.16, 0.95, 0.04)
    sash.mesh = bm
    var m := StandardMaterial3D.new()
    m.albedo_color = RANK_COLOURS[clampi(rank, 0, RANK_COLOURS.size() - 1)]
    m.metallic = 0.4 if rank >= 4 else 0.0
    if rank >= 6:
        m.emission_enabled = true
        m.emission = m.albedo_color
        m.emission_energy_multiplier = 0.6
    sash.material_override = m
    sash.rotation.z = deg_to_rad(38.0)
    sash.position = Vector3(0, 0.15, 0.42)
    att.add_child(sash)

## ---- L13: what a hero wears beyond their kit (data/items.json). Accessories
## show small (a ring at the left wrist, an amulet on the chest, gloves, boots,
## a cloak's colour on the cape); cosmetics are the hat, the dye (armour pieces
## and cloak), a banner on the back, a pet at heel and a title under the name.
const ACC_COL := {"ring": Color(0.85, 0.70, 0.30), "amulet": Color(0.80, 0.75, 0.55), "gloves": Color(0.30, 0.22, 0.16),
                  "boots": Color(0.24, 0.17, 0.12)}
const CLOAK_COL := {"guild_cloak": Color(0.45, 0.46, 0.48), "mire_cloak": Color(0.28, 0.38, 0.26)}

static func dress_cosmetics(model_root: Node, h: Dictionary) -> void:
    var sk := skeleton(model_root)
    if sk == null:
        return
    for slot in ["eq_ring", "eq_amulet", "eq_glove_l", "eq_glove_r", "eq_hat", "eq_banner", "eq_cboot_l", "eq_cboot_r", "eq_cloak"]:
        var old := sk.get_node_or_null(NodePath(slot))
        if old:
            old.free()
    var acc: Dictionary = h.get("acc", {})
    var cos: Dictionary = h.get("cos", {})
    var has_dye := cos.has("dye")
    var dye_col := Color.html(String((Roster.items().get("dyes", {}) as Dictionary).get(String(cos.get("dye", "")), "ffffff")))
    # the cape: dye first, then a worn cloak's own colour (the calling's colour stays otherwise)
    if has_dye:
        _cape_tint(model_root, dye_col)
    elif acc.has("cloak") and not acc_ctx(String(acc["cloak"])).is_empty():
        # D94: the cloak's own cloth (was CLOAK_COL, two entries for 49 cloaks)
        _cape_tint(model_root, acc_ctx(String(acc["cloak"]))["cloth"])
    # dye the armour pieces too
    if has_dye:
        for slot in ["eq_boot_l", "eq_boot_r", "eq_pauldron_l", "eq_pauldron_r", "eq_helm"]:
            var p := sk.get_node_or_null(NodePath(slot))
            if p:
                for mi in p.find_children("*", "MeshInstance3D", true, false):
                    var mm := (mi as MeshInstance3D).material_override as StandardMaterial3D
                    if mm:
                        var d := mm.duplicate() as StandardMaterial3D
                        d.albedo_color = dye_col.lerp(mm.albedo_color, 0.25)
                        (mi as MeshInstance3D).material_override = d
    # D94: every accessory is built from ITS OWN item (acc_ctx), not from its slot
    if acc.has("ring"):
        var rc := acc_ctx(String(acc["ring"]))
        # the ring goes on the hand the camera can see: not the one behind a held shield or book
        var held_off := String(Roster.CLASSES.get(String(h.get("class", "")), {}).get("offhand", ""))
        var off_bone := String(Roster.CLASSES.get(String(h.get("class", "")), {}).get("offhand_bone", "handslot.l"))
        var ring_hand := "hand.r" if (held_off != "" and off_bone == "handslot.l") else "hand.l"
        var r := _piece(sk, ring_hand, "eq_ring", null)
        if r and not rc.is_empty():
            r.position = Vector3(0, RING_Y, 0)
            _build_ring(r, rc)
    if acc.has("amulet"):
        var ac := acc_ctx(String(acc["amulet"]))
        var a := _piece(sk, "chest", "eq_amulet", null)
        if a and not ac.is_empty():
            _build_amulet(a, ac)
    if acc.has("gloves"):
        var gc := acc_ctx(String(acc["gloves"]))
        if not gc.is_empty():
            gc["key"] = String(acc["gloves"])
            for s in ["l", "r"]:
                var g := _piece(sk, "hand." + s, "eq_glove_" + s, null)
                if g:
                    _build_glove(g, gc)
    # D94b: BOUGHT boots win over the armour's set boots (the paladin's Long Count Boots were
    # suppressed whenever any armour was worn). The armour keeps its pauldrons, helm and bracers.
    if acc.has("boots") and not acc_ctx(String(acc["boots"])).is_empty():
        for s in ["eq_boot_l", "eq_boot_r"]:
            var ob := sk.get_node_or_null(NodePath(s))
            if ob:
                ob.free()
    if acc.has("boots") and sk.get_node_or_null("eq_boot_l") == null:
        var bc := acc_ctx(String(acc["boots"]))
        if not bc.is_empty():
            if has_dye:
                bc["cloth"] = dye_col
            for s in ["l", "r"]:
                var bt := _piece(sk, "foot." + s, "eq_cboot_" + s, null)
                if bt:
                    _align(bt, sk, "foot." + s)
                    _build_boot(bt, bc)
    if acc.has("cloak"):
        var kc := acc_ctx(String(acc["cloak"]))
        var ck := _piece(sk, "chest", "eq_cloak", null)
        if ck and not kc.is_empty():
            _align(ck, sk, "chest")
            if has_dye:
                kc["cloth"] = dye_col
            _build_cloak(ck, kc)
    if cos.has("hat"):
        _hat(model_root, sk, String(cos["hat"]))
    if cos.has("banner"):
        var it := Roster.item(String(cos["banner"]))
        var bn := _piece(sk, "chest", "eq_banner", _mat_c(Color(0.35, 0.25, 0.15), 0.0))
        if bn:
            var pole := BoxMesh.new()
            pole.size = Vector3(0.06, 2.0, 0.06)
            bn.mesh = pole
            bn.position = Vector3(0.25, 0.6, -0.45)
            var cloth := MeshInstance3D.new()
            var cb := BoxMesh.new()
            cb.size = Vector3(0.55, 0.75, 0.03)
            cloth.mesh = cb
            cloth.material_override = _mat_c(Color.html(String(it.get("colour", "aa2222"))), 0.0)
            cloth.position = Vector3(-0.3, 0.6, 0)
            bn.add_child(cloth)
    # the title, under the name (a Label3D straight under a HeroBody is renamed by it; this one sits deeper)
    var old_t := model_root.get_node_or_null("eq_title")
    if old_t:
        old_t.free()
    var title := _title_of(h)
    if title != "" and model_root is Node3D:
        var lb := Label3D.new()
        lb.name = "eq_title"
        lb.text = title
        lb.font_size = 24
        var sy := maxf(0.2, (model_root as Node3D).scale.y)
        lb.pixel_size = 0.01 / sy
        lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        lb.no_depth_test = true
        lb.outline_size = 12
        lb.outline_modulate = Color(0, 0, 0, 0.9)
        lb.modulate = Color(0.95, 0.85, 0.55)
        lb.offset = Vector2(0, -34)
        lb.position = Vector3(0, 2.3 / sy, 0)
        model_root.add_child(lb)
    # the pet, at heel
    var host: Node = model_root.get_parent()
    if host:
        for c in host.get_children():
            if c is HeroPet:
                c.queue_free()
        if cos.has("pet"):
            var pit := Roster.item(String(cos["pet"]))
            var pet := HeroPet.new()
            pet.owner_body = host as Node3D
            pet.model = String(pit.get("model", ""))
            pet.scale_f = float(pit.get("scale", 0.35))
            host.add_child(pet)

static func _title_of(h: Dictionary) -> String:
    var k := String((h.get("cos", {}) as Dictionary).get("title", ""))
    return String(Roster.item(k).get("name", "")) if k != "" else ""

static func _mat_c(col: Color, metal: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = col
    m.metallic = metal
    m.roughness = 0.4 if metal > 0.5 else 0.8
    return m

## cosmetic hats sit over the head and hide the body's own hat or helmet
static func _hat(model_root: Node, sk: Skeleton3D, key: String) -> void:
    var it := Roster.item(key)
    var st: Array = [model_root]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is MeshInstance3D and not String(c.name).begins_with("eq_") and (String(c.name).contains("Hat") or String(c.name).contains("Helmet")):
            (c as MeshInstance3D).visible = false
        for g in c.get_children():
            if not String(g.name).begins_with("eq_"):
                st.append(g)
    var col := Color.html(String(it.get("colour", "553322")))
    var hat := _piece(sk, "head", "eq_hat", _mat_c(col, 0.0))
    if hat == null:
        return
    var crown := CylinderMesh.new()
    match key:
        "wide_hat":
            crown.top_radius = 0.42
            crown.bottom_radius = 0.48
            crown.height = 0.36
            hat.position = Vector3(0, 0.95, 0)
            _brim(hat, 0.9, col)
        "straw_hat":
            crown.top_radius = 0.12
            crown.bottom_radius = 0.5
            crown.height = 0.4
            hat.position = Vector3(0, 0.98, 0)
            _brim(hat, 0.95, col)
        "feather_cap":
            crown.top_radius = 0.45
            crown.bottom_radius = 0.6
            crown.height = 0.3
            hat.position = Vector3(0, 0.86, 0)
            var f := MeshInstance3D.new()
            var pm := PrismMesh.new()
            pm.size = Vector3(0.12, 0.7, 0.05)
            f.mesh = pm
            f.material_override = _mat_c(Color(0.95, 0.92, 0.85), 0.0)
            f.position = Vector3(0.4, 0.35, -0.1)
            f.rotation.z = -0.5
            hat.add_child(f)
        "crown_of_ash":
            var tm := TorusMesh.new()
            tm.inner_radius = 0.5
            tm.outer_radius = 0.58
            hat.mesh = tm
            hat.position = Vector3(0, 0.82, 0)
            return
        # ---- L53: the content writer's hats. Every one of these had NO case, so it fell
        # through to a bare CylinderMesh at its default size - a great pale cone on the head.
        # Each gets its own silhouette, because the colour alone (which the data supplies) is
        # not enough to tell a coif from a kettle-helm at pane distance.
        "guild_hood", "mire_hood":
            # a hood: close crown with a drape down the back of the neck
            crown.top_radius = 0.40
            crown.bottom_radius = 0.52
            crown.height = 0.44
            hat.position = Vector3(0, 0.92, 0)
            var drape := MeshInstance3D.new()
            var dm := BoxMesh.new()
            dm.size = Vector3(0.62, 0.52, 0.18)
            drape.mesh = dm
            drape.material_override = _mat_c(col.darkened(0.12), 0.0)
            drape.position = Vector3(0, -0.30, -0.26)
            hat.add_child(drape)
        "bell_coif":
            # a coif sits ON the skull - a squashed dome, no brim, no crown above it
            var sm := SphereMesh.new()
            sm.radius = 0.52
            sm.height = 0.78
            hat.mesh = sm
            hat.material_override = _mat_c(col, 0.25)
            hat.position = Vector3(0, 0.84, 0)
            return
        "watch_helm":
            # a kettle-helm: shallow steel dome under a wide flat brim
            crown.top_radius = 0.30
            crown.bottom_radius = 0.50
            crown.height = 0.30
            hat.material_override = _mat_c(col, 0.75)
            hat.position = Vector3(0, 0.90, 0)
            _brim(hat, 0.82, col.darkened(0.15))
        "miller_cap":
            # a soft flat cap with a short peak over the brow
            crown.top_radius = 0.46
            crown.bottom_radius = 0.50
            crown.height = 0.18
            hat.position = Vector3(0, 0.88, 0)
            var peak := MeshInstance3D.new()
            var pk := BoxMesh.new()
            pk.size = Vector3(0.56, 0.05, 0.34)
            peak.mesh = pk
            peak.material_override = _mat_c(col.darkened(0.15), 0.0)
            peak.position = Vector3(0, -0.07, 0.34)
            hat.add_child(peak)
        "ford_circlet":
            # a circlet - thinner than the ash crown, and it sits lower
            var cm2 := TorusMesh.new()
            cm2.inner_radius = 0.50
            cm2.outer_radius = 0.545
            hat.mesh = cm2
            hat.material_override = _mat_c(col, 0.7)
            hat.position = Vector3(0, 0.80, 0)
            return
        "guard_helm", "plumed_helm":
            # a closed helm with a nasal bar; the plumed one wears a crest as well
            crown.top_radius = 0.44
            crown.bottom_radius = 0.52
            crown.height = 0.52
            hat.material_override = _mat_c(col, 0.8)
            hat.position = Vector3(0, 0.94, 0)
            var nasal := MeshInstance3D.new()
            var nm := BoxMesh.new()
            nm.size = Vector3(0.09, 0.34, 0.06)
            nasal.mesh = nm
            nasal.material_override = _mat_c(col.darkened(0.2), 0.8)
            nasal.position = Vector3(0, -0.22, 0.49)
            hat.add_child(nasal)
            if key == "plumed_helm":
                var plume := MeshInstance3D.new()
                var qm := PrismMesh.new()
                qm.size = Vector3(0.14, 0.62, 0.42)
                plume.mesh = qm
                plume.material_override = _mat_c(Color(0.92, 0.88, 0.82), 0.0)
                plume.position = Vector3(0, 0.46, -0.04)
                hat.add_child(plume)
        _:
            # L53: a hat key with no case of its own must still read as a HAT. Before this the
            # fall-through left CylinderMesh at its defaults (a 2 m cone), so every hat the
            # content writer adds broke the model until someone noticed. A plain soft cap is a
            # dull but honest default, and new keys now degrade instead of breaking.
            crown.top_radius = 0.44
            crown.bottom_radius = 0.52
            crown.height = 0.30
            hat.position = Vector3(0, 0.90, 0)
    hat.mesh = crown

static func _brim(hat: MeshInstance3D, r: float, col: Color) -> void:
    var b := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = r
    cm.bottom_radius = r
    cm.height = 0.04
    b.mesh = cm
    b.material_override = _mat_c(col.darkened(0.1), 0.0)
    b.position = Vector3(0, -0.16, 0)
    hat.add_child(b)

## ============================================================== D94: EVERY ITEM LOOKS LIKE ITSELF
## Mr. E, 16 Nov 00:55: "ring should not at all be looking the same at all ... all equipment ...
## should not be looking the same, again unless they are a set." Before this a worn accessory was
## drawn from its SLOT (one gold torus for all 55 rings), and the 119 named weapons and armour
## pieces in items.json were read by no script at all.
##
## ACCESSORIES: the look is derived from the ITEM, by the SAME rules the D73 icon generator uses
## (tools/art/icongen.py context() + icons.py variant_for/STAT_GEM/METALS), ported line for line,
## so the icon on the hub and the thing on the hero are the same object:
##   variant  the item's NAME first (a "Signet" is a signet), hash(key) only as a fallback
##   orn      cost within its slot, 0..1 -> ornateness, the metal (iron/bronze/silver/gold) and
##            WEAR (cheap reads handled and worn, expensive reads new - the 15 Nov ruling)
##   gem      the stat it adds (ac steel, saves violet, hp red, speed green, hit amber, dmg orange)
##   cloth    one of eight leather/cloth tones from the key's hash
## NAMED WEAPONS AND ARMOUR: a hero's tier (h.weapon / h.armour, the balanced 12-step ladder)
## stays the NUMBERS. The named piece is the tier's FACE: h.wname / h.aname name a piece of that
## tier, stamped when the piece is bought or found; a save without them (or with one that no
## longer fits the tier) derives a stable piece from the hero's name, so no old save breaks.
## A piece's look: its KIND from its name (a Cutlass is a sword, a Hatchet an axe), a distinct
## mesh where its kind has more than one, and a MATERIAL read from its name (ember, cold-white,
## ash, scar, rune, dragontooth, bell-bronze, hazel...). Armour pieces dress boots, shoulders,
## helm and bracers in ONE material - that is the declared SET Mr. E named as the exception.

const D94_TONES := [Color(0.30, 0.25, 0.20), Color(0.22, 0.19, 0.17), Color(0.36, 0.28, 0.20),
    Color(0.24, 0.26, 0.29), Color(0.31, 0.22, 0.22), Color(0.21, 0.26, 0.23),
    Color(0.38, 0.34, 0.27), Color(0.26, 0.23, 0.30)]
const D94_METALS := [Color(0.40, 0.42, 0.45), Color(0.56, 0.38, 0.20), Color(0.74, 0.76, 0.80), Color(0.87, 0.70, 0.28)]
const D94_STAT_GEM := {"ac": Color(0.52, 0.66, 0.92), "saves": Color(0.68, 0.46, 0.92),
    "hp": Color(0.86, 0.30, 0.32), "speed": Color(0.40, 0.84, 0.46),
    "hit": Color(0.95, 0.76, 0.32), "dmg": Color(0.95, 0.52, 0.22)}
const D94_STAT_ORDER := ["ac", "saves", "hp", "speed", "hit", "dmg"]
const D94_NAME_HINTS := {
    "ring":   {"signet": 1, "seal": 1, "twist": 2, "braid": 2, "plait": 2,
               "stone": 3, "gem": 3, "jewel": 3, "band": 0, "engrav": 4, "etch": 4},
    "amulet": {"locket": 4, "case": 4, "vial": 3, "phial": 3, "flask": 3,
               "crescent": 2, "moon": 2, "disc": 1, "medal": 1, "coin": 1,
               "pendant": 0, "tear": 0, "drop": 0},
    "cloak":  {"hood": 0, "mantle": 1, "short": 1, "half": 1, "long": 2, "sweep": 2,
               "fur": 3, "pelt": 3, "wolf": 3, "tatter": 4, "rag": 4, "ragged": 4},
    "boots":  {"clog": 0, "shoe": 0, "slipper": 0, "sandal": 0, "tall": 2, "rider": 2,
               "high": 2, "fur": 3, "winter": 3, "point": 4},
    "gloves": {"gauntlet": 0, "plate": 0, "mitt": 1, "mitten": 1, "wrap": 4,
               "fingerless": 4, "bracer": 3, "vambrace": 3, "stud": 2},
}
## D94c - CLOAKS DIFFER BY COLOUR, NOT ONLY BY SHAPE. The eight TONES above are all dark
## leather/cloth, so 49 cloaks read as one brown-grey cape with a different collar. A cloak is the
## largest single area of colour on a hero; it takes a DYE of its own instead. Twelve period dyes
## (madder, woad, weld, woodland green, walnut black, undyed wool...), kept below full saturation so
## they sit in the HD palette. THE SHARED RULE (tools/art must derive the same index so the hub icon
## and the hero match):
##   hay   = (name + " " + key).lower()
##   dye_i = the FIRST entry of D94_CLOAK_WORDS (in list order) whose word is in hay,
##           else (d94_hash(key) >> 8) % 12   (the same bits the TONES used)
##   cloth = D94_CLOAK_DYES[dye_i] (linear, like TONES - _lin() for Godot), cloth_i = dye_i
## Gloves and boots keep the eight TONES (they are leather).
const D94_CLOAK_DYES := [
    Color(0.42, 0.08, 0.07),   # 0 madder red
    Color(0.08, 0.14, 0.36),   # 1 woad blue
    Color(0.06, 0.20, 0.08),   # 2 woodland green
    Color(0.04, 0.035, 0.035), # 3 walnut black
    Color(0.30, 0.29, 0.27),   # 4 grey wool
    Color(0.62, 0.56, 0.42),   # 5 undyed cream
    Color(0.52, 0.30, 0.04),   # 6 weld ochre
    Color(0.22, 0.06, 0.20),   # 7 wine / mulberry
    Color(0.04, 0.20, 0.20),   # 8 river teal
    Color(0.28, 0.10, 0.03),   # 9 russet
    Color(0.12, 0.08, 0.30),   # 10 scar violet (dear dye)
    Color(0.18, 0.17, 0.06),   # 11 oilcloth / peat olive
]
const D94_CLOAK_WORDS := [
    ["scar", 10], ["red", 0], ["harl", 0], ["raid", 0], ["warhorn", 0], ["feast", 7], ["chronicl", 7],
    ["backstair", 7], ["caravan", 9], ["hurdl", 9], ["bowyer", 9], ["mourn", 4], ["grey", 4],
    ["fog", 4], ["ash", 4], ["sexton", 3], ["black", 3], ["ossuary", 3], ["grave", 3],
    ["green", 2], ["wood", 2], ["hedge", 2], ["orchard", 2], ["osier", 2],
    ["oilcloth", 11], ["peat", 11], ["turbary", 11], ["mire", 11], ["tanner", 9], ["butcher", 9],
    ["winter", 5], ["salt", 5], ["pilgrim", 5], ["lime", 5],
    ["lamp", 6], ["guild", 6], ["thatch", 6], ["crier", 6],
    ["commander", 1], ["constable", 1], ["watch", 1], ["wall", 1],
    ["ferry", 8], ["raft", 8], ["lighter", 8], ["lock", 8], ["crane", 8], ["wake", 8], ["deep", 8],
]
static func cloak_dye_i(key: String, name: String) -> int:
    var hay := (name + " " + key).to_lower()
    for e in D94_CLOAK_WORDS:
        if hay.contains(String(e[0])):
            return int(e[1])
    return (d94_hash(key) >> 8) % D94_CLOAK_DYES.size()

## D94d - THE SHADE STEP (mirrors tools/art/icons.py register_cloaks / cloth_tone, bit for bit).
## The dye alone left fifteen cloaks sharing BOTH a dye and a cut (six woad mantles - every watch
## and wall cloak). The answer is not to scatter the dyes; it is a lighter or darker bolt of the
## same dye, assigned by POSITION IN THE COLLIDING GROUP so it cannot collide by construction:
##   group   = every cloak sharing (dye_i, variant), keys sorted as plain strings
##   shade_i = the key's index in that group, capped at 7; 0 leaves the dye alone
##   cloth   = clamp(dye * D94_CLOAK_SHADES[shade_i], 0.02, 0.95) per channel, in LINEAR (then _lin)
## cloth_i stays the dye index - the shade is a value step, never a new hue.
const D94_CLOAK_SHADES := [1.00, 0.72, 1.34, 0.56, 1.62, 0.88, 1.16, 0.44]
static var _cloak_shade := {}
static func cloak_shade_i(key: String) -> int:
    if _cloak_shade.is_empty():
        var all: Dictionary = Roster.items().get("accessories", {})
        var keys: Array = all.keys()
        keys.sort()
        var groups := {}
        for k in keys:
            var e = all[k]
            if not (e is Dictionary) or String(e.get("slot", "")) != "cloak":
                continue
            var nm := String(e.get("name", ""))
            var sig := "%d|%d" % [cloak_dye_i(String(k), nm), _acc_variant("cloak", String(k), nm)]
            var n := int(groups.get(sig, 0))
            _cloak_shade[String(k)] = mini(n, D94_CLOAK_SHADES.size() - 1)
            groups[sig] = n + 1
    return int(_cloak_shade.get(key, 0))

## the item's own name first; its hash only when the name says nothing (icons.variant_for)
static func _acc_variant(slot: String, key: String, name: String) -> int:
    var variant := d94_hash(key) % 5
    var hay := (name + " " + key).to_lower()
    var hints: Dictionary = D94_NAME_HINTS.get(slot, {})
    for word in hints:
        if hay.contains(word):
            variant = int(hints[word])
            break
    return variant

static var _acc_span := {}          # slot -> [lo, hi] cost over the accessories

## icongen.context()'s hash, bit for bit
static func d94_hash(key: String) -> int:
    var h := 0
    for i in range(key.length()):
        h = (h * 131 + key.unicode_at(i)) & 0xFFFFFFFF
    return h

## the icon generator works in Blender's linear colour; Godot's albedo is sRGB
static func _lin(c: Color) -> Color:
    return c.linear_to_srgb()

## the look of one accessory, derived from the item exactly as its icon was, PLUS its FORM
## (D94b): two items that land on the same variant, metal, stat and cloth would otherwise be
## ONE object (the proof sheet's DUPLICATE). Every such collision group is sorted by item KEY
## and numbered 0, 1, 2 - that number is the item's form, and form > 0 changes the GEOMETRY
## (a drop under a pendant, a flared cuff, a buckle strap, a hem band), never just the colour.
## THE SHARED RULE (tools/art must derive the same number so the hub icon and the hero match):
##   sig  = slot | variant | metal_i | stat | cloth_i (cloth_i = -1 for ring and amulet)
##   form = index of the key within its sig group, keys sorted as plain strings
static var _acc_forms := {}
const D94_CLOTH_SLOTS := ["gloves", "boots", "cloak"]
static func acc_form(key: String) -> int:
    if _acc_forms.is_empty():
        var all: Dictionary = Roster.items().get("accessories", {})
        var keys: Array = all.keys()
        keys.sort()
        var groups := {}
        for k in keys:
            var c := _acc_base(String(k))
            if c.is_empty():
                continue
            var ci := int(c["cloth_i"]) if D94_CLOTH_SLOTS.has(String(c["slot"])) else -1
            var sig := "%s|%d|%d|%s|%d" % [c["slot"], int(c["variant"]), int(c["metal_i"]), c["stat"], ci]
            var n := int(groups.get(sig, 0))
            _acc_forms[String(k)] = n
            groups[sig] = n + 1
    return int(_acc_forms.get(key, 0))

static func acc_ctx(key: String) -> Dictionary:
    var c := _acc_base(key)
    if not c.is_empty():
        c["form"] = acc_form(key)
    return c

static func _acc_base(key: String) -> Dictionary:
    var all: Dictionary = Roster.items().get("accessories", {})
    var it: Dictionary = all.get(key, {})
    if it.is_empty():
        return {}
    var slot := String(it.get("slot", ""))
    if _acc_span.is_empty():
        for k in all:
            var e = all[k]
            if not (e is Dictionary):
                continue
            var s := String(e.get("slot", ""))
            var c := float(e.get("cost", 0))
            var sp: Array = _acc_span.get(s, [1e9, 0.0])
            _acc_span[s] = [minf(float(sp[0]), c), maxf(float(sp[1]), c)]
    var span: Array = _acc_span.get(slot, [0.0, 1.0])
    var orn := (float(it.get("cost", 0)) - float(span[0])) / maxf(1.0, float(span[1]) - float(span[0]))
    var h := d94_hash(key)
    var stat := ""
    for s in D94_STAT_ORDER:
        if it.has(s):
            stat = s
            break
    var variant := _acc_variant(slot, key, String(it.get("name", "")))
    var mi := mini(3, int(orn * 4.0))
    var ti := (h >> 8) % D94_TONES.size()
    var cloth: Color = D94_TONES[ti]
    if slot == "cloak":                        # D94c: a cloak wears a dye, not a leather tone
        ti = cloak_dye_i(key, String(it.get("name", "")))
        var dye: Color = D94_CLOAK_DYES[ti]
        var k := float(D94_CLOAK_SHADES[cloak_shade_i(key)])    # D94d: the shade step
        cloth = Color(clampf(dye.r * k, 0.02, 0.95), clampf(dye.g * k, 0.02, 0.95), clampf(dye.b * k, 0.02, 0.95))
    return {"slot": slot, "variant": variant, "orn": orn, "stat": stat,
            "metal": _lin(D94_METALS[mi]), "metal_i": mi,
            "cloth": _lin(cloth), "cloth_i": ti,
            "gem": _lin(D94_STAT_GEM.get(stat, Color(0.70, 0.70, 0.74))),
            # WEAR RIDES COST: a cheap piece is dull and handled, an expensive one bright and kept
            "rough": lerpf(0.82, 0.28, orn), "sheen": lerpf(0.45, 0.95, orn)}

static func _m_metal(c: Dictionary) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c["metal"]
    m.metallic = float(c["sheen"])
    m.roughness = float(c["rough"])
    return m

static func _m_gem(c: Dictionary) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c["gem"]
    m.metallic = 0.1
    m.roughness = 0.15
    m.emission_enabled = true          # a stone must read at arm's length on a moving body
    m.emission = c["gem"]
    m.emission_energy_multiplier = 0.25 + 0.5 * float(c["orn"])
    return m

static func _m_cloth(col: Color, rough := 0.85) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = col
    m.roughness = rough
    return m

static func _part(parent: Node3D, mesh: Mesh, m: Material, pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = m
    mi.position = pos
    mi.rotation = rot
    mi.scale = scl
    mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(mi)
    return mi

static func _sph(r: float, h := -1.0) -> SphereMesh:
    var s := SphereMesh.new()
    s.radius = r
    s.height = h if h > 0.0 else r * 2.0
    s.radial_segments = 10
    s.rings = 6
    return s

static func _box(x: float, y: float, z: float) -> BoxMesh:
    var b := BoxMesh.new()
    b.size = Vector3(x, y, z)
    return b

static func _cyl(top: float, bot: float, h: float, seg := 10) -> CylinderMesh:
    var c := CylinderMesh.new()
    c.top_radius = top
    c.bottom_radius = bot
    c.height = h
    c.radial_segments = seg
    c.rings = 1
    return c

## a rounded foot: a capsule laid along model Z (rotate PI/2 about X), flattened by scale.z
static func _cap(r: float, h: float) -> CapsuleMesh:
    var c := CapsuleMesh.new()
    c.radius = r
    c.height = h
    c.radial_segments = 10
    c.rings = 3
    return c

static func _tor(inner: float, outer: float) -> TorusMesh:
    var t := TorusMesh.new()
    t.inner_radius = inner
    t.outer_radius = outer
    t.rings = 14
    t.ring_segments = 6
    return t

## ---- the five accessory builds, placed by MEASUREMENT (tools/_d94_bones.gd, every KayKit
## hero body shares one skeleton): chest bone at model y 0.97; body front z +0.37, back -0.41,
## top 1.30; the head overhangs from y 1.05-1.22 and is ~1.1 across; arms are ~0.29 thick and
## the mitt hand runs 0.18 past hand.l/r (bone +Y along the arm, bone +Z = back of the hand in
## the rest pose); ankle (foot bone) at y 0.15, sole 0.0, toe z +0.29, heel -0.13, foot 0.24
## wide; knee at 0.29. The front of a body is model +Z. Feet and the cloak are built in MODEL
## axes (_align undoes the bone's rest rotation), so a boot sole is flat on the ground.

## a piece hung on `bone` but laid out in the model's own axes (the bone's rest rotation undone)
static func _align(mi: Node3D, sk: Skeleton3D, bone: String) -> void:
    var i := sk.find_bone(bone)
    if i >= 0:
        mi.basis = sk.get_bone_global_rest(i).basis.orthonormalized().inverse()

## RING: round the mitt at the knuckles. KayKit hands have no finger bones, so the band
## circles the whole mitt where a finger ring shows - never smaller than the hand, so it can
## never sink into it - and the setting sits on the BACK of the hand (bone +Z).
## band: plain / signet / twisted / claw-set stone / engraved.
const RING_R := 0.078     # the mitt's half-width at the knuckles, MEASURED in the idle pose (the fist is ~0.15 across)
const RING_Y := 0.09      # along the hand bone from the wrist to the knuckles
static func _build_ring(root: MeshInstance3D, c: Dictionary) -> void:
    var v := int(c["variant"])
    var orn := float(c["orn"])
    var mm := _m_metal(c)
    var gm := _m_gem(c)
    var band := 0.009 + 0.007 * orn
    root.mesh = _tor(RING_R, RING_R + band * 2.0)
    root.material_override = mm
    var top := Vector3(0, 0, RING_R + band * 2.0)        # the back of the hand
    match v:
        1:  # signet: a flat bezel with a dark seal, lying on the back of the hand
            _part(root, _box(0.06, 0.05, 0.02), mm, top)
            _part(root, _box(0.04, 0.03, 0.01), _m_cloth(Color(0.08, 0.07, 0.07), 0.6), top + Vector3(0, 0, 0.012))
        2:  # twisted: a second band wound on the first
            _part(root, _tor(RING_R + band * 0.4, RING_R + band * 1.6), mm, Vector3(0, band, 0), Vector3(0.0, 0, 0.18))
        3:  # a real stone in four claws
            _part(root, _sph(0.026 + 0.012 * orn, 0.032 + 0.012 * orn), gm, top + Vector3(0, 0, 0.014))
            for k in range(4):
                var a := TAU * k / 4.0 + 0.78
                _part(root, _cyl(0.0, 0.006, 0.03, 4), mm, top + Vector3(0.024 * cos(a), 0.024 * sin(a), 0.008), Vector3(PI * 0.5, 0, 0))
        4:  # engraved: two dark grooves
            for y in [-band * 0.7, band * 0.7]:
                _part(root, _tor(RING_R + band * 1.6, RING_R + band * 2.2), _m_cloth(Color(0.10, 0.09, 0.08), 0.5), Vector3(0, y, 0))
    if orn > 0.45 and v != 1:     # costly rings carry small stones round the band
        var n := int(2 + 6 * orn)
        for k in range(n):
            var a2 := TAU * k / float(n) + 0.4
            var rr := RING_R + band * 2.0
            _part(root, _sph(0.010), gm, Vector3(rr * cos(a2), 0.0, rr * sin(a2)))
    match int(c.get("form", 0)):
        1:  # a broad cigar band beside the first
            _part(root, _tor(RING_R + band * 1.6, RING_R + band * 2.8), mm, Vector3(0, -band * 2.4, 0), Vector3.ZERO, Vector3(1, 2.4, 1))
        2:  # three stones set across the palm side
            for k in range(3):
                var a3 := PI + (k - 1) * 0.45
                _part(root, _sph(0.016), gm, Vector3((RING_R + band * 2.0) * cos(a3 + PI * 0.5), 0.0, (RING_R + band * 2.0) * sin(a3 + PI * 0.5)))

## AMULET: a pendant on the breastbone, below the overhang of the head where the camera sees
## it, hung from a linked chain draped wide across the upper chest to the collarbones (D94c).
## pendant: teardrop / disc / crescent / vial / locket.
static func _build_amulet(root: MeshInstance3D, c: Dictionary) -> void:
    var v := int(c["variant"])
    var orn := float(c["orn"])
    var mm := _m_metal(c)
    var gm := _m_gem(c)
    root.position = Vector3(0, 0.02, 0.42)            # model y ~0.99, just proud of the chest
    # D94c: the chain was two thin rods running straight up under the chin, so the head's overhang
    # buried them and only the pendant read. It is now a run of LINKS draped wide across the upper
    # chest, out towards the collarbones where the head does not cover it, following the barrel of
    # the chest back as it climbs (z falls with x) - a V a viewer reads as "worn on a chain".
    var lr := 0.016 + 0.008 * orn
    var lm := _m_metal(c)
    lm.emission_enabled = true                         # a chain must catch the light on stream
    lm.emission = (c["metal"] as Color) * 0.5
    lm.emission_energy_multiplier = 0.35
    for s in [-1.0, 1.0]:
        for k in range(1, 9):
            var t := k / 8.0
            var p := Vector3(0.235 * s * pow(t, 0.85), 0.035 + 0.11 * t * t, 0.012 - 0.15 * t * t)
            _part(root, _sph(lr, lr * 1.5), lm, p, Vector3(0, 0, -0.9 * s * t))
    root.mesh = null
    match v:
        0:
            _part(root, _sph(0.06, 0.09), gm, Vector3.ZERO)
            _part(root, _cyl(0.0, 0.045, 0.08, 8), gm, Vector3(0, -0.075, 0), Vector3(PI, 0, 0))
        1:
            _part(root, _cyl(0.085, 0.085, 0.025, 14), mm, Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
            _part(root, _sph(0.035, 0.03), gm, Vector3(0, 0, 0.015))
        2:
            _part(root, _sph(0.025), gm, Vector3.ZERO)
            for k in range(9):
                var a := PI * (0.2 + 0.6 * k / 8.0) + PI
                _part(root, _sph(0.022), mm, Vector3(0.08 * cos(a), 0.08 * sin(a) + 0.03, 0))
        3:
            _part(root, _cyl(0.035, 0.045, 0.12, 10), gm, Vector3.ZERO)
            _part(root, _box(0.05, 0.035, 0.05), mm, Vector3(0, 0.075, 0))
        _:
            _part(root, _box(0.10, 0.12, 0.03), mm, Vector3.ZERO)
            _part(root, _box(0.06, 0.07, 0.02), gm, Vector3(0, 0, 0.015))
    if orn > 0.5:
        for s in [-1.0, 1.0]:
            _part(root, _sph(0.018), gm, Vector3(0.05 * s, 0.07, 0.0))
    match int(c.get("form", 0)):
        1:  # a second stone hung on a short link below the pendant
            _part(root, _cyl(0.008, 0.008, 0.07, 5), mm, Vector3(0, -0.12, 0))
            _part(root, _sph(0.034, 0.05), gm, Vector3(0, -0.17, 0.0))
        2:  # a metal halo framing the pendant
            _part(root, _tor(0.095, 0.12), mm, Vector3(0, 0, -0.005), Vector3(PI * 0.5, 0, 0))

## ---------------------------------------------------------------- D94e: THE GLOVE'S SILHOUETTE
## Mr. E, 16 Nov 10:24: "okay so fix them" - gloves must READ AT STREAM DISTANCE, and the fix is
## MORE DERIVED VARIATION, NOT A BIGGER GLOVE. This is a bit-for-bit port of the ART lane's ONE
## shared derivation - tools/art/icons.py glove_form() (the hub icon calls it) and
## tools/art/showcase.py acc_gloves() (the worn piece the proof sheet measures) - so the glove in
## the satchel, the glove on the proof sheet and the glove on the hero in game are ONE object.
## If icons.glove_form's tables change, change D94_G_* here in the same breath.
##            cut:  gauntlet  mitt  studded  vambrace  wrap
const D94_G_CUFF0 := [0.30, 0.13, 0.20, 0.42, 0.22]
const D94_G_CUFFK := [0.26, 0.14, 0.20, 0.20, 0.18]
const D94_G_FLARE0 := [1.70, 1.25, 1.40, 1.55, 1.18]
const D94_G_FLAREK := [0.95, 0.30, 0.55, 0.80, 0.26]
const D94_G_KNUCK0 := [0.34, 0.10, 0.21, 0.15, 0.06]
const D94_G_KNUCKK := [0.52, 0.26, 0.44, 0.30, 0.22]
const D94_G_SHELL0 := [1.46, 1.62, 1.38, 1.32, 1.26]
const D94_G_PLATES := [[3, 6], [0, 1], [2, 5], [1, 3], [0, 2]]
const D94_G_METAL := [true, false, true, true, false]
const D94_G_FINGERS := [4, 0, 4, 4, 4]
## measured on the KayKit adventurer (showcase.acc_gloves): wrist -> hand bone x2, wrist -> elbow
const D94_G_HANDLEN := 0.1477
const D94_G_FOREARM := 0.26

## showcase.sig: FNV-1a over "key|name" lower-cased, then twelve LCG dials (showcase.Dial)
static func d94_dials(key: String, name: String) -> Array:
    var hay := (key + "|" + name).to_lower()
    var h := 2166136261
    for i in range(hay.length()):
        h = ((h ^ hay.unicode_at(i)) * 16777619) & 0xFFFFFFFF
    var out: Array = []
    var x := h | 1
    for _k in range(12):
        x = (x * 1103515245 + 12345) & 0x7FFFFFFF
        out.append(x)
    return out

static func _dial_u(d: Array, i: int, lo: float, hi: float) -> float:
    return lo + (hi - lo) * (float(d[i % 12]) / 2147483648.0)

## icons.glove_form, ported: the dials for one glove off its cut, its cost quantile and its key
static func glove_form(variant: int, orn: float, d: Array) -> Dictionary:
    var v := clampi(variant, 0, 4)
    var o := clampf(orn, 0.0, 1.0)
    var cuff := float(D94_G_CUFF0[v]) + float(D94_G_CUFFK[v]) * o
    var fl0 := float(D94_G_FLARE0[v]) + float(D94_G_FLAREK[v]) * o
    var pl: Array = D94_G_PLATES[v]
    return {"variant": v,
        "cuff": clampf(cuff * _dial_u(d, 0, 0.86, 1.14), 0.10, 0.94),
        "flare": maxf(1.0, fl0 * _dial_u(d, 1, 0.93, 1.09)),
        "knuck": maxf(0.0, (float(D94_G_KNUCK0[v]) + float(D94_G_KNUCKK[v]) * o) * _dial_u(d, 2, 0.86, 1.18)),
        "shell": maxf(1.02, float(D94_G_SHELL0[v]) * _dial_u(d, 3, 0.96, 1.10)),
        "plates": int(pl[0]) + int(round((int(pl[1]) - int(pl[0])) * o)),
        "metal": bool(D94_G_METAL[v]), "fingers": int(D94_G_FINGERS[v]),
        "lip": fl0 > 1.85}

## GLOVES, one hand, on the hand bone (+Y down the fingers, +Z the back of the hand, the wrist
## at -HANDLEN/2). showcase.acc_gloves part for part: the bell cuff up the forearm, the hard lip,
## the hand shell wider than the fist, a mitt pocket or four fingers, the thumb, the KNUCKLE
## PLATES standing off the fist (count rides cost), studs, and the STRAPS round the cuff.
static func _build_glove(root: MeshInstance3D, c: Dictionary) -> void:
    var orn := float(c["orn"])
    var key := String(c.get("key", ""))
    var nm := String(Roster.items().get("accessories", {}).get(key, {}).get("name", ""))
    var F := glove_form(int(c["variant"]), orn, d94_dials(key, nm))
    var v := int(F["variant"])
    var cm := _m_cloth(c["cloth"] as Color, float(c["rough"]))
    var dm := _m_cloth((c["cloth"] as Color).darkened(0.35), 0.9)
    var mm := _m_metal(c)
    var hard: Material = mm if bool(F["metal"]) else dm
    var hl := D94_G_HANDLEN
    var wy := -hl * 0.5                                  # the wrist
    var ar := hl * 0.38                                  # forearm radius
    var cuff := D94_G_FOREARM * float(F["cuff"])
    var mouth := ar * float(F["flare"])
    var hw := hl * 0.5 * float(F["shell"])
    var side := -1.0 if root.name.ends_with("_r") else 1.0
    root.mesh = null
    root.scale = Vector3.ONE
    root.position = Vector3.ZERO
    # 1. THE CUFF - the readable mass, a cone from inside the shell down past the wrist
    var L := cuff + hl * 0.30
    _part(root, _cyl(hw * 0.99, mouth, L, 14), hard, Vector3(0, wy + hl * 0.30 - L * 0.5, 0))
    if bool(F["lip"]):
        _part(root, _tor(mouth * 0.89, mouth * 1.15), hard, Vector3(0, wy - cuff, 0))
    # 2. THE HAND SHELL - wider than the hand it covers (rounded, never a box)
    _part(root, _sph(0.5, 1.0), cm, Vector3(0, hl * 0.12, 0), Vector3.ZERO,
        Vector3(hw * 1.42 * 1.12, hl * 0.62 * 1.12, hw * 1.26 * 1.12))
    if int(F["fingers"]) == 0:                           # a mitt: one pocket
        _part(root, _cyl(hw * 0.56, hw * 0.86, hl * 0.46, 12), cm, Vector3(0, hl * 0.34 + hl * 0.23, 0))
    else:
        var tip := 0.34 if v == 4 else 0.44
        for k in range(4):
            var dx := (-hw * 0.52 + hw * 0.35 * k) * side
            var ln := hl * (tip - 0.26)
            _part(root, _cyl(hw * 0.16, hw * 0.20, ln, 6), cm, Vector3(dx, hl * 0.26 + ln * 0.5, hw * 0.06))
    # the thumb, so a glove reads as a glove from the side
    _part(root, _cyl(hw * 0.17, hw * 0.24, hl * 0.25, 7), cm, Vector3(-hw * 0.71 * side, hl * 0.19, -hw * 0.05),
        Vector3(0, 0, 0.6 * side))
    # 3. THE KNUCKLE PLATES - stand OFF the back of the fist, count riding cost
    var kn := hw * float(F["knuck"]) * 0.55
    if kn > 0.008:
        for k in range(maxi(1, int(F["plates"]))):
            _part(root, _box(hw * 1.34, hl * 0.13, maxf(0.010, kn * 0.52)), hard,
                Vector3(0, hl * (0.06 + 0.15 * k), hw * 0.66 + kn * 0.46))
        if bool(F["metal"]):
            _part(root, _sph(kn * 0.40, kn * 0.92), _m_gem(c), Vector3(0, hl * 0.08, hw * 0.70 + kn * 0.92))
    elif orn > 0.45:
        _part(root, _sph(hw * 0.17, hw * 0.40), _m_gem(c), Vector3(0, hl * 0.10, hw * 0.72))
    if v == 2:                                           # studs down the fingers
        for k in range(4):
            _part(root, _sph(hw * 0.11), mm, Vector3((-hw * 0.52 + hw * 0.35 * k) * side, hl * 0.38, hw * 0.22))
    # 4. THE STRAPS round the cuff: a dear gauntlet is strapped, a cheap wrap tied once
    for k in range(maxi(1, mini(3, int(F["plates"]) - 1))):
        var t := 0.28 + 0.30 * k
        var rr := hw * 0.96 + (mouth - hw * 0.96) * t
        var tr := maxf(0.006, rr * 0.11)
        _part(root, _tor(rr * 1.03 - tr, rr * 1.03 + tr), dm, Vector3(0, wy - cuff * t, 0))
    match int(c.get("form", 0)):     # D94b's collision form, kept: geometry, never colour
        1:  # a metal band hard at the wrist
            _part(root, _tor(hw * 0.92, hw * 1.10), mm, Vector3(0, wy, 0))
        2:  # a raised spine down the knuckle plates
            _part(root, _box(hw * 0.22, hl * 0.50, 0.03), mm, Vector3(0, hl * 0.20, hw * 0.80 + kn))

## BOOTS, one foot, in model axes (sole flat): low shoe / ankle boot / tall riding boot /
## fur-cuffed / pointed toe. Shafts are short because a KayKit knee is at y 0.29.
static func _build_boot(root: MeshInstance3D, c: Dictionary) -> void:
    var v := int(c["variant"])
    var orn := float(c["orn"])
    var cm := _m_cloth(c["cloth"] as Color, float(c["rough"]))
    var dm := _m_cloth((c["cloth"] as Color).darkened(0.40), 0.9)
    var foot := Node3D.new()
    foot.position = Vector3(0, -0.15, 0.02)            # from the ankle bone to the ground under it
    root.add_child(foot)
    root.mesh = null
    # the foot, over the body's own - ROUNDED (D94b: "all boots are boxes"), a flattened capsule
    _part(foot, _cap(0.14, 0.46), cm, Vector3(0, 0.115, 0.08), Vector3(PI * 0.5, 0, 0), Vector3(1, 1, 0.72))
    _part(foot, _cap(0.15, 0.47), dm, Vector3(0, 0.017, 0.08), Vector3(PI * 0.5, 0, 0), Vector3(1, 1, 0.12))   # sole, rounded to the foot
    var shaft: float = [0.0, 0.10, 0.24, 0.16, 0.05][v]
    if shaft > 0.0:
        _part(foot, _cyl(0.135, 0.14, shaft, 10), cm, Vector3(0, 0.21 + shaft * 0.5, -0.02))
    if v == 3:
        _part(foot, _tor(0.12, 0.19), dm, Vector3(0, 0.21 + shaft, -0.02), Vector3.ZERO, Vector3(1, 1.4, 1))
    elif shaft > 0.0:
        _part(foot, _cyl(0.148, 0.148, 0.035, 10), dm, Vector3(0, 0.21 + shaft, -0.02))
    if v == 4:
        _part(foot, _cyl(0.0, 0.09, 0.20, 8), cm, Vector3(0, 0.07, 0.37), Vector3(PI * 0.5 - 0.2, 0, 0), Vector3(1.0, 1.0, 0.55))
    if v == 2 or orn > 0.5:
        var mm := _m_metal(c)
        var nb := 1 + int(2 * orn)
        for k in range(nb):
            var y := 0.08 + (0.12 + shaft) * (k + 0.5) / float(nb)
            _part(foot, _box(0.29, 0.03, 0.03), mm, Vector3(0, y, 0.30 if y < 0.21 else 0.13))
        if orn > 0.6:
            _part(foot, _sph(0.022), _m_gem(c), Vector3(0.0, 0.16, 0.31))
    match int(c.get("form", 0)):
        1:  # a buckled strap across the instep
            _part(foot, _box(0.30, 0.045, 0.10), dm, Vector3(0, 0.19, 0.17))
            _part(foot, _box(0.07, 0.06, 0.025), _m_metal(c), Vector3(0.09, 0.19, 0.225))
        2:  # a turned-down cuff in a lighter lining
            _part(foot, _cyl(0.17, 0.165, 0.075, 10), _m_cloth((c["cloth"] as Color).lightened(0.30), 0.9), Vector3(0, 0.20 + shaft, -0.02))

## CLOAK, in model axes about the chest bone: the body's own cape takes the cloak's cloth; the
## clasp, collar, hood, mantle or hanging rags are built. hood / mantle / long / fur / tattered.
static func _build_cloak(root: MeshInstance3D, c: Dictionary) -> void:
    var v := int(c["variant"])
    var orn := float(c["orn"])
    var cm := _m_cloth((c["cloth"] as Color).lightened(0.08), 0.9)
    var dm := _m_cloth((c["cloth"] as Color).darkened(0.30), 0.95)
    var mm := _m_metal(c)
    root.mesh = null
    # the clasp, at the collarbone below the chin: a bar and a stone
    var clasp := _part(root, _box(0.30, 0.045, 0.04), mm, Vector3(0, 0.16, 0.38))
    _part(clasp, _sph(0.045, 0.06), _m_gem(c), Vector3(0, 0, 0.03))
    match v:
        0:      # a hood thrown back, lying between the shoulders behind the head
            _part(root, _sph(0.28, 0.40), cm, Vector3(0, 0.24, -0.50), Vector3(0.4, 0, 0), Vector3(1.0, 0.7, 0.8))
        1:      # a short mantle over both shoulders, under the overhang of the head
            _part(root, _cyl(0.40, 0.56, 0.18, 14), cm, Vector3(0, 0.12, -0.02))
        2:      # a long sweep: a second fold over the cape, down to the heels
            _part(root, _box(0.84, 1.10, 0.05), cm, Vector3(0, -0.30, -0.45), Vector3(-0.04, 0, 0))
        3:      # a fur collar round the neck
            _part(root, _tor(0.30, 0.46), dm, Vector3(0, 0.22, -0.03), Vector3.ZERO, Vector3(1.0, 1.4, 1.0))
        _:      # tattered: rags hanging below the cape's hem
            for k in range(4):
                _part(root, _box(0.16, 0.30 + 0.08 * (k % 2), 0.035), dm, Vector3(-0.30 + 0.20 * k, -0.78, -0.40), Vector3(0.0, 0, 0.08 * (k - 1.5)))
    if orn > 0.55:
        for k in range(4):
            _part(clasp, _sph(0.018), mm, Vector3(-0.12 + 0.08 * k, -0.04, 0.02))
    match int(c.get("form", 0)):
        1:  # a pale border band across the back of the cape near the hem
            _part(root, _box(0.82, 0.08, 0.04), _m_cloth((c["cloth"] as Color).lightened(0.40), 0.85), Vector3(0, -0.56, -0.46))
        2:  # metal rondels on both shoulders
            for s in [-1.0, 1.0]:
                _part(root, _cyl(0.075, 0.075, 0.025, 12), mm, Vector3(0.34 * s, 0.13, 0.20), Vector3(PI * 0.5, 0, 0))

## ---------------------------------------------------------------- D94: named weapons
## A piece's KIND, read from its name. Constrained to the family's kinds by the caller.
const D94_KIND_WORDS := [
    ["greatsword", "greatsword"], ["shortknife", "dagger"], ["knife", "dagger"], ["dagger", "dagger"],
    ["rapier", "sword"], ["cutlass", "sword"], ["sabre", "sword"], ["falchion", "sword"],
    ["backsword", "sword"], ["longsword", "sword"], ["brand", "sword"], ["sword", "sword"], ["blade", "sword"],
    ["fang", "sword"], ["edge", "sword"],
    ["greataxe", "greataxe"],   # S20: before "maul", so "Ash-Maul Greataxe" is a greataxe
    ["mace", "mace"], ["mace", "sceptre"], ["maul", "axe"], ["hatchet", "axe"], ["cleaver", "axe"], ["splitter", "axe"],
    ["greataxe", "axe"], ["hewer", "axe"], ["breaker", "axe"], ["axe", "axe"],
    ["quarterstaff", "quarterstaff"], ["wraps", "wraps"], ["knuckles", "wraps"], ["fist", "wraps"],
    ["wand", "wand"], ["rod", "wand"], ["stick", "wand"], ["staff", "staff"],
    ["arbalest", "crossbow"], ["crossbow", "crossbow"], ["greatbow", "bow"], ["bow", "bow"],
    ["string", "bow"], ["thrum", "crossbow"], ["reedcutter", "crossbow"]]

## a piece's MATERIAL, read from its name: [word, tint, how hard it tints, glow colour or clear]
const D94_STUFF := [
    ["scar", Color(0.42, 0.26, 0.55), 0.55, Color(0.78, 0.36, 1.0)],
    ["seam", Color(0.32, 0.28, 0.48), 0.55, Color(0.70, 0.45, 1.0)],
    ["ember", Color(0.78, 0.36, 0.18), 0.45, Color(1.0, 0.50, 0.15)],
    ["cold", Color(0.86, 0.92, 1.0), 0.50, Color(0.65, 0.85, 1.0)],
    ["coldflame", Color(0.80, 0.90, 1.0), 0.50, Color(0.55, 0.80, 1.0)],
    ["dragontooth", Color(0.92, 0.88, 0.74), 0.55, Color(0, 0, 0, 0)],
    ["wyrm", Color(0.38, 0.52, 0.34), 0.45, Color(0, 0, 0, 0)],
    ["drake", Color(0.55, 0.30, 0.22), 0.45, Color(0, 0, 0, 0)],
    ["ash", Color(0.52, 0.52, 0.54), 0.45, Color(0, 0, 0, 0)],
    ["rune", Color(0.55, 0.62, 0.78), 0.35, Color(0.40, 0.60, 1.0)],
    ["lamp", Color(0.88, 0.74, 0.42), 0.40, Color(1.0, 0.80, 0.40)],
    ["tallow", Color(0.86, 0.80, 0.62), 0.45, Color(0, 0, 0, 0)],
    ["bell", Color(0.72, 0.52, 0.26), 0.55, Color(0, 0, 0, 0)],
    ["ferry", Color(0.36, 0.58, 0.56), 0.40, Color(0, 0, 0, 0)],
    ["guild", Color(0.86, 0.74, 0.40), 0.30, Color(0, 0, 0, 0)],
    ["iron", Color(0.38, 0.38, 0.40), 0.45, Color(0, 0, 0, 0)],
    ["militia", Color(0.48, 0.48, 0.44), 0.35, Color(0, 0, 0, 0)],
    ["hazel", Color(0.55, 0.40, 0.24), 0.50, Color(0, 0, 0, 0)],
    ["reed", Color(0.66, 0.62, 0.40), 0.45, Color(0, 0, 0, 0)],
    ["grave", Color(0.22, 0.24, 0.22), 0.55, Color(0, 0, 0, 0)],
    ["ink", Color(0.18, 0.20, 0.30), 0.45, Color(0, 0, 0, 0)],
    ["stone", Color(0.58, 0.56, 0.52), 0.40, Color(0, 0, 0, 0)],
    ["heron", Color(0.82, 0.84, 0.88), 0.35, Color(0, 0, 0, 0)],
    ["gutter", Color(0.30, 0.32, 0.26), 0.45, Color(0, 0, 0, 0)],
    ["sun", Color(0.95, 0.80, 0.40), 0.40, Color(1.0, 0.85, 0.40)],
    ["wall", Color(0.62, 0.60, 0.56), 0.35, Color(0, 0, 0, 0)],
    ["toll", Color(0.50, 0.44, 0.36), 0.35, Color(0, 0, 0, 0)],
    ["stitch", Color(0.60, 0.30, 0.28), 0.40, Color(0, 0, 0, 0)],
    ["pilgrim", Color(0.60, 0.48, 0.32), 0.40, Color(0, 0, 0, 0)],
    ["hunt", Color(0.40, 0.34, 0.24), 0.40, Color(0, 0, 0, 0)],
    ["oath", Color(0.92, 0.86, 0.62), 0.35, Color(0, 0, 0, 0)],
    ["parish", Color(0.60, 0.60, 0.62), 0.30, Color(0, 0, 0, 0)],
    ["pact", Color(0.36, 0.14, 0.46), 0.45, Color(0.55, 0.20, 0.80)],
    ["mill", Color(0.66, 0.64, 0.60), 0.35, Color(0, 0, 0, 0)],
    ["warren", Color(0.42, 0.36, 0.28), 0.40, Color(0, 0, 0, 0)],
    ["stage", Color(0.75, 0.20, 0.25), 0.35, Color(0, 0, 0, 0)],
    ["gnarl", Color(0.42, 0.32, 0.20), 0.50, Color(0, 0, 0, 0)],
]

static func equipment() -> Dictionary:
    return Roster.items().get("equipment", {})

static func weapon_piece(id: String) -> Dictionary:
    return (equipment().get("weapons", {}) as Dictionary).get(id, {})

static func armour_piece(id: String) -> Dictionary:
    return (equipment().get("armour", {}) as Dictionary).get(id, {})

## the kind a named weapon IS, among the kinds its family has ("" = the hero's own kind)
static var _kind_cache := {}
static func piece_kind(id: String, family: String) -> String:
    var ck := id + "|" + family
    if _kind_cache.has(ck):
        return String(_kind_cache[ck])
    var hay := String(weapon_piece(id).get("name", "")).to_lower()
    var fam_kinds := kinds_of(family)
    var out := ""
    for wk in D94_KIND_WORDS:
        if hay.contains(String(wk[0])) and fam_kinds.has(String(wk[1])):
            out = String(wk[1])
            break
    _kind_cache[ck] = out
    return out

## the named piece a hero holds at their tier: the stamped one if it still fits, else a stable
## derivation from the hero's name, so a save from before D94 shows a named piece too
static func weapon_id(h: Dictionary, family: String, kind := "") -> String:
    var tier := int(h.get("weapon", 0))
    var stamped := String(h.get("wname", ""))
    var p := weapon_piece(stamped)
    if not p.is_empty() and int(p.get("tier", -1)) == tier and String(p.get("family", "")) == family:
        return stamped
    if tier == 0:   # a calling's starting kit: the plain piece it came with
        var kit: Dictionary = (equipment().get("starting_kits", {}) as Dictionary).get(String(h.get("class", "")), {})
        return String(kit.get("weapon", ""))
    var pool: Array = []
    var same_kind: Array = []
    for id in (equipment().get("weapons", {}) as Dictionary):
        var w: Dictionary = weapon_piece(id)
        if int(w.get("tier", -1)) == tier and String(w.get("family", "")) == family:
            pool.append(id)
            if kind != "" and piece_kind(id, family) == kind:
                same_kind.append(id)
    if kind != "" and String(h.get("wkind", "")) != "":
        pool = same_kind      # a kind chosen at the forge: only a piece OF that kind will do
    if pool.is_empty():
        return ""
    pool.sort()
    return String(pool[d94_hash(String(h.get("name", "")) + str(tier)) % pool.size()])

## the cut of armour a calling wears
const D94_CUT := {"knight": "heavy", "warden": "heavy", "paladin": "heavy", "barbarian": "light",
    "rogue": "light", "duelist": "light", "ranger": "light", "monk": "light", "bard": "light",
    "mage": "robe", "sage": "robe", "cleric": "robe", "necromancer": "robe", "druid": "robe", "warlock": "robe"}

static func armour_id(h: Dictionary) -> String:
    var tier := int(h.get("armour", 0))
    var stamped := String(h.get("aname", ""))
    var p := armour_piece(stamped)
    if not p.is_empty() and int(p.get("tier", -1)) == tier:
        return stamped
    var cls := String(h.get("class", ""))
    if tier == 0:
        var kit: Dictionary = (equipment().get("starting_kits", {}) as Dictionary).get(cls, {})
        return String(kit.get("armour", ""))
    var cut := String(D94_CUT.get(cls, "light"))
    var pool: Array = []
    var any: Array = []
    for id in (equipment().get("armour", {}) as Dictionary):
        var a: Dictionary = armour_piece(id)
        if int(a.get("tier", -1)) == tier:
            any.append(id)
            if String(a.get("cut", "")) == cut:
                pool.append(id)
    if pool.is_empty():
        pool = any
    if pool.is_empty():
        return ""
    pool.sort()
    return String(pool[d94_hash(String(h.get("name", "")) + "a" + str(tier)) % pool.size()])

## stamp the pieces a hero now holds (called when a tier changes), so a later data edit never
## swaps what a viewer bought
static func stamp(h: Dictionary, family: String, kind := "") -> void:
    var w := weapon_id(h, family, kind)
    if w != "":
        h["wname"] = w
    else:
        h.erase("wname")
    var a := armour_id(h)
    if a != "":
        h["aname"] = a
    else:
        h.erase("aname")

static func _stuff(nm: String) -> Array:
    var hay := nm.to_lower()
    var best: Array = []
    for s in D94_STUFF:      # the LONGEST matching word wins ("coldflame" over "cold")
        if hay.contains(String(s[0])) and (best.is_empty() or String(s[0]).length() > String(best[0]).length()):
            best = s
    return best

## the look of a named weapon: which mesh, its tint, its own glow
static func weapon_piece_look(id: String, family: String, tier: int, fallback_kind: String) -> Dictionary:
    var p := weapon_piece(id)
    var kind := piece_kind(id, family)
    if kind == "":
        kind = fallback_kind
    var out := {"kind": kind, "path": "", "tint": Color(1, 1, 1), "tint_amt": 0.0, "glow_col": Color(0, 0, 0, 0), "scale_mul": 1.0}
    if not KINDS.has(kind):
        return out
    var kit: Array = KINDS[kind]["kit"]
    var t := maxi(1, tier)
    # pieces sharing a tier and a kind take NEIGHBOURING meshes, so two named swords of one
    # tier are two different swords; the tier still reads in size and glow
    var sib: Array = []
    for oid in (equipment().get("weapons", {}) as Dictionary):
        var o: Dictionary = weapon_piece(oid)
        var ok_kind := piece_kind(oid, family)
        if ok_kind == "":
            ok_kind = fallback_kind      # D94b: a piece with no kind word IS the hero's kind - a sibling too
        if int(o.get("tier", -1)) == tier and String(o.get("family", "")) == family and ok_kind == kind:
            sib.append(oid)
    sib.sort()
    var j := maxi(0, sib.find(id))
    var distinct: Array = []
    for pth in kit:
        if String(pth) != "" and not distinct.has(pth):
            distinct.append(pth)
    var base := String(kit[clampi(t - 1, 0, kit.size() - 1)])
    var bi := maxi(0, distinct.find(base))
    var offs := [0, 1, -1, 2, -2]
    var path := base
    if not distinct.is_empty():
        path = String(distinct[clampi(bi + int(offs[j % offs.size()]), 0, distinct.size() - 1)])
    out["path"] = path
    var st := _stuff(String(p.get("name", "")))
    if not st.is_empty():
        out["tint"] = st[1]
        out["tint_amt"] = float(st[2])
        out["glow_col"] = st[3]
    var h := d94_hash(id)
    out["scale_mul"] = 0.94 + 0.12 * float(h % 100) / 99.0
    # D94b: the piece's own key reaches the GEOMETRY. Siblings (same tier, family and kind) are
    # numbered in key order; that number picks the furniture deco_piece() builds on the mesh,
    # so two tier-5 bows that share the pack's one bow mesh are still two bows.
    out["form"] = j
    out["accent"] = _lin(D94_TONES[(h >> 8) % D94_TONES.size()]).lightened(0.12)
    out["named"] = not p.is_empty()
    out["id"] = id
    return out

## the bounds of every mesh under n, in n's own space
static func _local_aabb(n: Node3D) -> AABB:
    var out := AABB()
    var first := true
    var st: Array = [[n, Transform3D.IDENTITY]]
    while not st.is_empty():
        var e: Array = st.pop_back()
        var c: Node = e[0]
        var t: Transform3D = e[1]
        if c is MeshInstance3D and (c as MeshInstance3D).mesh:
            var b: AABB = t * (c as MeshInstance3D).mesh.get_aabb()
            out = b if first else out.merge(b)
            first = false
        for g in c.get_children():
            if g is Node3D:
                st.append([g, t * (g as Node3D).transform])
    return out

## D94b: the named piece's furniture, built on the instanced mesh and measured off its bounds:
##   every named piece  a grip wrap in the piece's own tone (the hub icon's cloth)
##   form 1             ribbons trailing from the butt / lower limb
##   form 2             a stone at the head / upper limb, in the piece's glow or amber
##   form 3             two dark collars a third and two thirds along
##   form 4             ribbons AND a stone
const D94_PENNON := [Color(0.80, 0.16, 0.14), Color(0.92, 0.78, 0.25), Color(0.92, 0.92, 0.88),
    Color(0.20, 0.50, 0.85), Color(0.25, 0.62, 0.30), Color(0.55, 0.25, 0.70)]
static func deco_piece(n: Node3D, look: Dictionary) -> void:
    if n == null or not bool(look.get("named", false)):
        return
    var bb := _local_aabb(n)
    if bb.size == Vector3.ZERO:
        return
    var ax := 1                                  # the long axis: up the blade, or across a bow
    if bb.size.x > bb.size.y and bb.size.x >= bb.size.z:
        ax = 0
    elif bb.size.z > bb.size.y:
        ax = 2
    var rot: Vector3 = [Vector3(0, 0, PI * 0.5), Vector3.ZERO, Vector3(PI * 0.5, 0, 0)][ax]
    var dir := Vector3.ZERO
    dir[ax] = 1.0
    var lo := bb.position[ax]
    var hi := bb.position[ax] + bb.size[ax]
    var span := hi - lo
    var thick := 0.0                                # the narrower cross-section, so a wrap hugs it
    for i in range(3):
        if i != ax:
            thick = bb.size[i] if thick == 0.0 else minf(thick, bb.size[i])
    var r := clampf(thick * 0.30, 0.035, 0.07)
    var accent: Color = look.get("accent", Color(0.5, 0.4, 0.3))
    var gc: Color = look.get("glow_col", Color(0, 0, 0, 0))
    var wrap := _part(n, _cyl(r, r, clampf(span * 0.11, 0.08, 0.20), 8), _m_cloth(accent, 0.8), Vector3.ZERO, rot)
    wrap.name = "d94_wrap"
    var f := int(look.get("form", 0))
    # the pennon's colour: from the key, but never the colour the piece is already tinted (a
    # purple ribbon on a scar-purple bow is no ribbon at all)
    var pi := (d94_hash(String(look.get("id", ""))) >> 4) % D94_PENNON.size()
    var tc: Color = look.get("tint", Color(1, 1, 1))
    for _t in range(D94_PENNON.size()):
        var pc: Color = D94_PENNON[pi]
        if float(look.get("tint_amt", 0.0)) <= 0.0 or Vector3(pc.r - tc.r, pc.g - tc.g, pc.b - tc.b).length() > 0.35:
            break
        pi = (pi + 1) % D94_PENNON.size()
    if f == 1 or f == 4:
        for k in [-1.0, 1.0]:
            # S24: a pack staff's ribbons hang under the finial, not off the butt (the butt is near the floor)
            var rat := (hi - span * 0.20) if n.has_meta("staff_grip") else (lo - span * 0.14)
            var rib := _part(n, _box(0.07, 0.045, 0.02), _m_cloth(D94_PENNON[pi], 0.7), dir * rat + Vector3(0.05 * k, 0, 0.05 * k) * (Vector3.ONE - dir), rot)
            rib.scale = Vector3(1, maxf(2.0, span * 0.30 / 0.045), 1)
            rib.name = "d94_ribbon"
    if f == 2 or f == 4:
        var sm := StandardMaterial3D.new()
        var sc: Color = gc if gc.a > 0.0 else Color(0.95, 0.72, 0.30)
        sm.albedo_color = sc
        sm.emission_enabled = true
        sm.emission = sc
        sm.emission_energy_multiplier = 0.6
        sm.roughness = 0.2
        var stone := _part(n, _sph(clampf(span * 0.03, 0.03, 0.055)), sm, dir * (hi - span * 0.03))
        stone.name = "d94_stone"
    if f == 3:
        for t in [0.36, 0.68]:
            var col := _part(n, _tor(r * 1.0, r * 1.7), _m_cloth(accent.darkened(0.45), 0.5), dir * (lo + span * t), rot)
            col.name = "d94_collar"

## tint an instanced weapon's materials toward its piece's stuff, and give it the piece's glow
## S17: material names (KayKit dungeon pack) that are the cutting edge or striking head of a weapon;
## tint_piece leaves their albedo alone (the glow still reaches them). Atlas-textured kits match none.
## S45: + the artifact _Golden set's metals - art's ruling (ARTIFACT_GOLD_VS_SCARRED.md) keeps the gold untinted;
## its wood grip still takes the name's stuff word.
const EDGE_MATS := ["Metal", "Stone", "StoneDark", "White", "Golden", "LightGold", "DarkSteel"]

static func tint_piece(n: Node, look: Dictionary) -> void:
    if n == null:
        return
    var amt := float(look.get("tint_amt", 0.0))
    var gc: Color = look.get("glow_col", Color(0, 0, 0, 0))
    if amt <= 0.0 and gc.a <= 0.0:
        return
    var tint: Color = look.get("tint", Color(1, 1, 1))
    var st: Array = [n]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is MeshInstance3D and (c as MeshInstance3D).mesh:
            var mi: MeshInstance3D = c
            for i in range(mi.mesh.get_surface_count()):
                var src: Material = mi.get_active_material(i)
                if src is StandardMaterial3D:
                    var d: StandardMaterial3D = src.duplicate()
                    # S17: the EDGE keeps its own colour - the material word tints the haft, grip and
                    # trim, not the blade or the head (a whole-mesh wash made a falchion read as wood)
                    if not EDGE_MATS.has(String(src.resource_name)):
                        d.albedo_color = d.albedo_color.lerp(tint, amt)
                    if gc.a > 0.0:
                        d.emission_enabled = true
                        d.emission = gc
                        d.emission_energy_multiplier = maxf(d.emission_energy_multiplier, 0.35)
                    mi.set_surface_override_material(i, d)
        for g in c.get_children():
            st.append(g)

## the look of a named armour piece: ONE material across every part it dresses (the set)
static func armour_piece_look(id: String, tier: int) -> Dictionary:
    var p := armour_piece(id)
    var look: Dictionary = (ARMOUR_LOOK[clampi(tier, 0, ARMOUR_LOOK.size() - 1)] as Dictionary).duplicate()
    if p.is_empty():
        return look
    var cut := String(p.get("cut", "light"))
    look["cut"] = cut
    var base: Color = look.get("col", Color(0.42, 0.28, 0.17))
    var st := _stuff(String(p.get("name", "")))
    if not st.is_empty():
        base = base.lerp(st[1], float(st[2]) + 0.15)
        if (st[3] as Color).a > 0.0:
            look["glow"] = st[3]
            look["e"] = maxf(float(look.get("e", 0.0)), 0.12)
    var h := d94_hash(id)
    # two pieces of one tier and cut must still differ: hue and value nudged by the key
    base = Color.from_hsv(fposmod(base.h + (float(h % 21) - 10.0) * 0.006, 1.0), clampf(base.s * (0.85 + 0.3 * float((h >> 5) % 10) / 9.0), 0.0, 1.0), clampf(base.v * (0.9 + 0.2 * float((h >> 9) % 10) / 9.0), 0.05, 1.0))
    look["col"] = base
    if cut == "robe":
        # a caster's cut: soft cloth, no pauldrons or helm; a hood-like cowl and a sash instead
        look["metal"] = 0.0
        look["pauldrons"] = false
        look["helm"] = false
        look["boots"] = tier >= 1
        look["robe"] = true
    elif cut == "light":
        look["metal"] = minf(float(look.get("metal", 0.0)), 0.3)
        look["helm"] = false
        look["bracers"] = tier >= 1
        look["pauldrons"] = tier >= 2
        look["small_pauldrons"] = true
    else:
        look["bracers"] = tier >= 2
    look["trim"] = (h >> 3) % 3            # 0 plain, 1 riveted, 2 banded - a second axis of difference
    look["helm_v"] = (h >> 6) % 3          # helm crest / no crest / horned-plume
    return look
