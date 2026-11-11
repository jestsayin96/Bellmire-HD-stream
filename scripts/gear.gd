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
    {"name": "bare hands", "cost": 0, "atk": 0, "scale": 0.0, "glow": 0.0},
    {"name": "plain steel", "cost": 60, "atk": 4, "scale": 1.0, "glow": 0.0},
    {"name": "fine steel", "cost": 160, "atk": 9, "scale": 1.05, "glow": 0.0},
    {"name": "runed", "cost": 420, "atk": 16, "scale": 1.12, "glow": 0.5},
    {"name": "dragontooth", "cost": 1100, "atk": 26, "scale": 1.25, "glow": 1.0},
    # L3: never forged in Bellmire - only ever found below, grown in the scar's wild magic
    {"name": "scarforged", "cost": 0, "atk": 34, "scale": 1.3, "glow": 1.3, "found": true},
]
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
    var att := BoneAttachment3D.new()
    att.name = "eq_" + slot
    att.bone_name = bone
    sk.add_child(att)
    var m: Node3D = (_cache[path] as PackedScene).instantiate()
    m.scale = Vector3.ONE * scale
    att.add_child(m)
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
const KINDS := {
    "sword":      {"family": "blade", "noun": "sword", "kit": [ADV + "sword_1handed.gltf", KIT + "sword_A.gltf", KIT + "sword_B.gltf", KIT + "sword_C.gltf", KIT + "sword_E.gltf"]},
    "greatsword": {"family": "blade", "noun": "greatsword", "kit": [ADV + "sword_2handed.gltf", ADV + "sword_2handed.gltf", ADV + "sword_2handed_color.gltf", KIT + "sword_D.gltf", SKA + "Skeleton_Blade.gltf"]},
    "dagger":     {"family": "blade", "noun": "dagger", "kit": [ADV + "dagger.gltf", ADV + "dagger.gltf", KIT + "knife.gltf", ADV + "dagger.gltf", ADV + "dagger.gltf"]},
    "spear":      {"family": "blade", "noun": "spear", "kit": [KIT + "spear_A.gltf", KIT + "spear_A.gltf", KIT + "halberd.gltf", KIT + "halberd.gltf", KIT + "halberd.gltf"]},
    "axe":        {"family": "axe", "noun": "axe", "kit": [ADV + "axe_1handed.gltf", KIT + "axe_A.gltf", ADV + "axe_2handed.gltf", KIT + "axe_B.gltf", SKA + "Skeleton_Axe.gltf"]},
    "mace":       {"family": "axe", "noun": "mace", "kit": [KIT + "hammer_A.gltf", KIT + "hammer_A.gltf", KIT + "hammer_B.gltf", KIT + "hammer_B.gltf", KIT + "hammer_B.gltf"]},
    "staff":      {"family": "arcane", "noun": "staff", "kit": [ADV + "staff.gltf", ADV + "staff.gltf", ADV + "staff.gltf", KIT + "staff_B.gltf", SKA + "Skeleton_Staff.gltf"]},
    "wand":       {"family": "arcane", "noun": "wand", "kit": [ADV + "wand.gltf", KIT + "wand_A.gltf", ADV + "wand.gltf", KIT + "wand_A.gltf", KIT + "wand_A.gltf"]},
    "crossbow":   {"family": "ranged", "noun": "crossbow", "kit": [ADV + "crossbow_1handed.gltf", ADV + "crossbow_1handed.gltf", ADV + "crossbow_2handed.gltf", ADV + "crossbow_2handed.gltf", SKA + "Skeleton_Crossbow.gltf"]},
    "bow":        {"family": "ranged", "noun": "bow", "kit": [KIT + "bow_A_withString.gltf", KIT + "bow_A_withString.gltf", KIT + "bow_A_withString.gltf", KIT + "bow_A_withString.gltf", KIT + "bow_A_withString.gltf"]},
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

## the KayKit weapon bits are modelled ~1.6x a KayKit hand
static func hand_scale(path: String) -> float:
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

static func dress_armour(model_root: Node, tier: int) -> void:
    var sk := skeleton(model_root)
    if sk == null:
        return
    for slot in ["eq_boot_l", "eq_boot_r", "eq_pauldron_l", "eq_pauldron_r", "eq_helm"]:
        var old := sk.get_node_or_null(NodePath(slot))
        if old:
            old.free()
    var look: Dictionary = ARMOUR_LOOK[clampi(tier, 0, ARMOUR_LOOK.size() - 1)]
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
                var bm := BoxMesh.new()
                bm.size = Vector3(0.36, 0.26, 0.46)
                b.mesh = bm
                b.position = Vector3(0, 0.06, 0.04)
    if bool(look.get("pauldrons", false)):
        for s in ["l", "r"]:
            var p := _piece(sk, "upperarm." + s, "eq_pauldron_" + s, m)
            if p:
                var sm := SphereMesh.new()
                sm.radius = 0.26
                sm.height = 0.30
                sm.is_hemisphere = true
                p.mesh = sm
                p.position = Vector3(0, 0.08, 0)
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
            var crest := MeshInstance3D.new()
            var pm := BoxMesh.new()
            pm.size = Vector3(0.10, 0.22, 0.95)
            crest.mesh = pm
            crest.material_override = m
            crest.position = Vector3(0, 0.64, 0)
            hm.add_child(crest)

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
const BODY_PARTS := ["Leg", "Head", "Body", "Arm", "Cape", "Helmet", "Hat"]

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

## L4: a calling's own cloak colour
static func _cape_tint(model_root: Node, col: Color) -> void:
    var ms := _cape_meshes(model_root)
    # the hat or hood too, so a calling reads from the front
    var st: Array = [model_root]
    while not st.is_empty():
        var c: Node = st.pop_back()
        if c is MeshInstance3D and (c as MeshInstance3D).visible and (String(c.name).contains("Hat") or String(c.name).contains("Hood")):
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
        dress_armour(model_root, int(_dressing.get("armour", 0)))
        var cls: Dictionary = Roster.CLASSES.get(String(_dressing.get("class", "")), {})
        if cls.has("cape"):
            _cape_tint(model_root, cls["cape"])
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
