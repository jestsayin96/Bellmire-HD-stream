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
]
const ARMOUR := [
    {"name": "rags", "cost": 0, "hp": 0, "ac": 0},
    {"name": "leather", "cost": 50, "hp": 10, "ac": 1},
    {"name": "chainmail", "cost": 150, "hp": 26, "ac": 3},
    {"name": "plate", "cost": 400, "hp": 48, "ac": 5},
    {"name": "warded plate", "cost": 1000, "hp": 80, "ac": 7},
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
