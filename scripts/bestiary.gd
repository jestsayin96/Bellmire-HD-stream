class_name Bestiary
extends RefCounted
## What haunts each depth. Ported from the old game's bestiary.gd (TYPES,
## STRAINS, BOSS_DEFS, DEPTHS, next_boss - numbers and canon unchanged) and
## widened with the six owned Quaternius creatures the old game never used
## (rat, spider, frog, snake, wasp, imp, puglin). Bosses are canon - the eight
## lords from NOTES.md - so none are invented here.
##
## Size is given as a REAL HEIGHT in metres ("h"); Monster scales each body to
## it from its measured bounds (the source files range from a 0.9 m puglin to a
## 7 m rat). Strain scale multiplies the height.

const SKL := "res://addons/kaykit_character_pack_skeletons/Characters/gltf/"
const QUAT := "res://addons/quaternius_monsters/"
const MON := "res://assets/monsters/"
const ADV := "res://addons/kaykit_character_pack_adventures/Assets/gltf/"

const A_KAY := {"idle": "Idle", "walk": "Walking_A", "run": "Running_A", "attack": "1H_Melee_Attack_Chop",
                "cast": "Spellcast_Shoot", "die": "Death_A", "hit": "Hit_A"}
const A_BAT := {"idle": "Bat_Flying", "walk": "Bat_Flying", "run": "Bat_Flying", "attack": "Bat_Attack", "die": "Bat_Death", "hit": "Bat_Hit"}
const A_SLIME := {"idle": "Slime_Idle", "walk": "Slime_Walk", "run": "Slime_Walk", "attack": "Slime_Attack", "die": "Slime_Death", "hit": "Slime_Idle"}
const A_BONES := {"idle": "Skeleton_Idle", "walk": "Skeleton_Running", "run": "Skeleton_Running", "attack": "Skeleton_Attack", "die": "Skeleton_Death", "hit": "Skeleton_Idle", "rise": "Skeleton_Spawn"}
const A_DRAGON := {"idle": "Dragon_Flying", "walk": "Dragon_Flying", "run": "Dragon_Flying", "attack": "Dragon_Attack", "die": "Dragon_Death", "hit": "Dragon_Hit"}
const A_RAT := {"idle": "Rat_Idle", "walk": "Rat_Walk", "run": "Rat_Run", "attack": "Rat_Attack", "die": "Rat_Death", "hit": "Rat_Idle"}
const A_SPIDER := {"idle": "Spider_Idle", "walk": "Spider_Walk", "run": "Spider_Walk", "attack": "Spider_Attack", "die": "Spider_Death", "hit": "Spider_Idle"}
const A_FROG := {"idle": "Frog_Idle", "walk": "Frog_Jump", "run": "Frog_Jump", "attack": "Frog_Attack", "die": "Frog_Death", "hit": "Frog_Idle"}
const A_SNAKE := {"idle": "Snake_Idle", "walk": "Snake_Walk", "run": "Snake_Walk", "attack": "Snake_Attack", "die": "Snake_Death", "hit": "Snake_Idle"}
const A_WASP := {"idle": "Wasp_Flying", "walk": "Wasp_Flying", "run": "Wasp_Flying", "attack": "Wasp_Attack", "die": "Wasp_Death", "hit": "Wasp_Flying"}
## Imp and Puglin ship rigged but with NO animations. Their rig is the
## Quaternius Universal rig, so they borrow the owned Universal Animation
## Library (UAL1/UAL2 in assets/monsters) - Monster grafts it on at load.
const A_UAL := {"idle": "Idle", "walk": "Walk", "run": "Jog_Fwd", "attack": "Sword_Attack",
                "cast": "Spell_Simple_Shoot", "die": "Death01", "hit": "Hit_Chest", "ual": true}

## hp/atk/spd are MULTIPLIERS on the floor's base difficulty (old game);
## scale = real-size normaliser; lift = hover height for flyers
const TYPES := {
    "minion":  {"name": "skeleton minion", "path": SKL + "Skeleton_Minion.glb", "anims": A_KAY, "hp": 0.8, "atk": 0.9, "spd": 4.2, "h": 1.6, "lift": 0.0, "hand": ADV + "axe_1handed.gltf", "off": ADV + "shield_round.gltf", "family": "undead"},
    "warrior": {"name": "skeleton warrior", "path": SKL + "Skeleton_Warrior.glb", "anims": A_KAY, "hp": 1.2, "atk": 1.1, "spd": 3.9, "h": 1.8, "lift": 0.0, "hand": ADV + "axe_2handed.gltf", "off": "", "family": "undead"},
    "cutpurse":{"name": "skeleton rogue", "path": SKL + "Skeleton_Rogue.glb", "anims": A_KAY, "hp": 0.9, "atk": 1.2, "spd": 4.8, "h": 1.6, "lift": 0.0, "hand": ADV + "dagger.gltf", "off": ADV + "dagger.gltf", "family": "undead"},
    "warlock": {"name": "skeleton mage", "path": SKL + "Skeleton_Mage.glb", "anims": A_KAY, "hp": 0.8, "atk": 1.5, "spd": 3.6, "h": 1.8, "lift": 0.0, "hand": ADV + "staff.gltf", "off": "", "casts": true, "family": "undead"},
    "slime":   {"name": "slime", "path": QUAT + "Slime.glb", "anims": A_SLIME, "hp": 1.4, "atk": 0.7, "spd": 2.4, "h": 1.0, "lift": 0.0, "family": "ooze"},
    "bat":     {"name": "cave bat", "path": QUAT + "Bat.glb", "anims": A_BAT, "hp": 0.5, "atk": 0.8, "spd": 6.2, "h": 0.9, "lift": 1.8, "family": "beast"},
    "bones":   {"name": "risen bones", "path": QUAT + "Skeleton.glb", "anims": A_BONES, "hp": 1.0, "atk": 1.0, "spd": 4.4, "h": 1.8, "lift": 0.0, "hand": ADV + "sword_1handed.gltf", "off": ADV + "shield_badge.gltf", "family": "undead"},
    "rat":     {"name": "giant rat", "path": MON + "Rat.glb", "anims": A_RAT, "hp": 0.6, "atk": 0.7, "spd": 5.6, "h": 0.55, "lift": 0.0, "family": "beast"},
    "spider":  {"name": "cave spider", "path": MON + "Spider.glb", "anims": A_SPIDER, "hp": 1.0, "atk": 1.2, "spd": 4.6, "h": 0.7, "lift": 0.0, "family": "beast"},
    "frog":    {"name": "bog frog", "path": MON + "Frog.glb", "anims": A_FROG, "hp": 1.1, "atk": 0.9, "spd": 3.4, "h": 0.8, "lift": 0.0, "family": "beast"},
    "snake":   {"name": "pit viper", "path": MON + "Snake.glb", "anims": A_SNAKE, "hp": 0.7, "atk": 1.3, "spd": 4.0, "h": 0.9, "lift": 0.0, "family": "beast"},
    "adder":   {"name": "scar adder", "path": MON + "Snake_Angry.glb", "anims": A_SNAKE, "hp": 0.9, "atk": 1.5, "spd": 4.4, "h": 1.0, "lift": 0.0, "family": "beast"},
    "wasp":    {"name": "blood wasp", "path": MON + "Wasp.glb", "anims": A_WASP, "hp": 0.4, "atk": 1.1, "spd": 6.8, "h": 0.6, "lift": 1.5, "family": "beast"},
    "imp":     {"name": "imp", "path": MON + "Imp.glb", "anims": A_UAL, "hp": 0.7, "atk": 1.3, "spd": 5.0, "h": 1.3, "lift": 0.6, "casts": true, "family": "fiend"},
    "puglin":  {"name": "puglin", "path": MON + "Puglin.glb", "anims": A_UAL, "hp": 0.9, "atk": 0.9, "spd": 4.4, "h": 0.9, "lift": 0.0, "family": "fiend"},
}
## ---- Work plan 2, L1: new creatures from CC0 bodies already owned (KayKit
## Skeletons + its own weapon set, KayKit Adventurers, the Quaternius dragon and
## slime). Nothing here is a lord; each is named in the old game's plain voice
## and fits the scar: the guild's own dead, the bone garrison, the wyrm's brood.
const SKA := "res://addons/kaykit_character_pack_skeletons/Assets/gltf/"
const ADVC := "res://addons/kaykit_character_pack_adventures/Characters/gltf/"
const A_SKL := {"idle": "Idle", "walk": "Walking_D_Skeletons", "run": "Running_A", "attack": "1H_Melee_Attack_Chop",
                "cast": "Spellcast_Shoot", "die": "Death_C_Skeletons", "hit": "Hit_A", "rise": "Skeletons_Awaken_Floor",
                "summon": "Spellcast_Summon"}
const A_BOW := {"idle": "2H_Ranged_Aiming", "walk": "Walking_D_Skeletons", "run": "Running_A", "attack": "2H_Ranged_Shoot",
                "die": "Death_C_Skeletons", "hit": "Hit_A", "rise": "Skeletons_Awaken_Floor"}
const A_GUARD := {"idle": "Blocking", "walk": "Walking_D_Skeletons", "run": "Running_A", "attack": "Block_Attack",
                  "die": "Death_C_Skeletons", "hit": "Block_Hit", "rise": "Skeletons_Awaken_Floor"}
const NEW_TYPES := {
    "bowman":     {"name": "bone bowman", "path": SKL + "Skeleton_Minion.glb", "anims": A_BOW, "hp": 0.7, "atk": 1.0, "spd": 3.8, "h": 1.6, "lift": 0.0,
                   "hand": SKA + "Skeleton_Crossbow.gltf", "off": "", "family": "undead",
                   "ways": {"ranged": 8.5, "shot": "bolt_bone"}, "homes": ["barracks", "keep", "prison"]},
    "sentinel":   {"name": "bone sentinel", "path": SKL + "Skeleton_Warrior.glb", "anims": A_GUARD, "hp": 1.3, "atk": 0.9, "spd": 3.2, "h": 1.9, "lift": 0.0,
                   "hand": SKA + "Skeleton_Blade.gltf", "off": SKA + "Skeleton_Shield_Large_A.gltf", "family": "undead",
                   "ways": {"guard": 3}, "homes": ["keep", "treasury", "barracks"]},
    "gravecaller":{"name": "gravecaller", "path": SKL + "Skeleton_Mage.glb", "anims": A_SKL, "hp": 0.9, "atk": 1.2, "spd": 3.4, "h": 1.85, "lift": 0.0,
                   "hand": SKA + "Skeleton_Staff.gltf", "off": "", "casts": true, "family": "undead", "tint": Color(0.80, 0.90, 0.76), "glow": Color(0.12, 0.50, 0.25),
                   "ways": {"ranged": 7.0, "raise": 2}, "homes": ["crypt", "shrine", "tomb"]},
    "lost":       {"name": "lost delver", "paths": [ADVC + "Knight.glb", ADVC + "Barbarian.glb", ADVC + "Rogue_Hooded.glb"], "path": ADVC + "Knight.glb",
                   "anims": A_KAY, "hp": 1.1, "atk": 1.2, "spd": 4.2, "h": 1.75, "lift": 0.0,
                   "hand": ADV + "sword_1handed.gltf", "off": "", "family": "the fallen", "tint": Color(0.80, 0.86, 0.94), "glow": Color(0.12, 0.20, 0.32),
                   "ways": {"grudge": true}, "homes": ["prison", "fogbound", "keep"]},
    "whelp":      {"name": "grave-whelp", "path": QUAT + "Dragon.glb", "anims": A_DRAGON, "hp": 1.0, "atk": 1.3, "spd": 4.6, "h": 2.3, "lift": 1.0,
                   "family": "wyrm", "tint": Color(0.86, 1.0, 0.86),
                   "ways": {"breath": 2.8}, "homes": ["firepit", "crypt", "keep"]},
    "slimeling":  {"name": "slimeling", "path": QUAT + "Slime.glb", "anims": A_SLIME, "hp": 0.35, "atk": 0.5, "spd": 3.6, "h": 0.5, "lift": 0.0,
                   "family": "ooze", "homes": []},
}
## what the old creatures do and where they are at home (L1). `ways` are the
## creature's habits in a fight (Delve reads them): ranged = keeps this far
## off and shoots; splits = an ooze divides into two slimelings when it dies;
## venom = a bite that keeps hurting; pack = comes with this many of its kind;
## guard = harder to hit; raise = calls up to N dead; breath = splashes the
## heroes beside its mark; grudge = goes for the weakest delver.
const WAYS := {
    "minion": {}, "warrior": {}, "cutpurse": {"grudge": true}, "warlock": {"ranged": 7.0},
    "slime": {"splits": 2}, "bat": {"pack": 1}, "bones": {}, "rat": {"pack": 2},
    "spider": {"venom": 4.0}, "frog": {}, "snake": {"venom": 3.0}, "adder": {"venom": 5.0},
    "wasp": {"venom": 2.0, "pack": 2}, "imp": {"ranged": 6.5}, "puglin": {"pack": 1},
}
## homes are FloorGen theme keys: a creature is three times as likely on a floor
## dressed as one of its homes
const HOMES := {
    "minion": ["barracks", "crypt", "prison"], "warrior": ["barracks", "keep"], "cutpurse": ["treasury", "prison"],
    "warlock": ["shrine", "crypt"], "slime": ["flooded", "mess", "confection"], "bat": ["fogbound", "wood"],
    "bones": ["crypt", "keep"], "rat": ["mess", "prison", "workshop"], "spider": ["wood", "fogbound"],
    "frog": ["flooded", "grassland"], "snake": ["grassland", "wood"], "adder": ["firepit"],
    "wasp": ["grassland", "confection"], "imp": ["firepit", "shrine"], "puglin": ["workshop", "confection"],
}

static func def_of(k: String) -> Dictionary:
    if TYPES.has(k):
        var d: Dictionary = (TYPES[k] as Dictionary).duplicate(true)
        d["ways"] = (WAYS.get(k, {}) as Dictionary).duplicate()
        d["homes"] = HOMES.get(k, [])
        return d
    return (NEW_TYPES[k] as Dictionary).duplicate(true)

static func all_keys() -> Array:
    var out: Array = TYPES.keys()
    out.append_array(NEW_TYPES.keys())
    return out

const DRAGON := {"name": "gravewyrm", "path": QUAT + "Dragon.glb", "anims": A_DRAGON, "hp": 1.0, "atk": 1.0, "spd": 3.0, "h": 3.0, "lift": 2.2, "family": "wyrm"}

## Strains (old game, numbers unchanged). Measured: they IMPROVED survival
## (83% vs 63%) - do not soften them. `glow` added: the strain is readable at
## stream distance, not only in the name.
const STRAINS := {
    "plain":        {"label": "", "hp": 1.00, "atk": 1.00, "spd": 1.00, "scale": 1.00, "tint": Color(1, 1, 1), "glow": Color(0, 0, 0)},
    "hollowed":     {"label": "hollowed", "hp": 0.75, "atk": 0.95, "spd": 1.10, "scale": 0.92, "tint": Color(0.86, 0.90, 0.84), "glow": Color(0, 0, 0)},
    "drowned":      {"label": "drowned", "hp": 1.35, "atk": 0.90, "spd": 0.80, "scale": 1.05, "tint": Color(0.52, 0.78, 0.82), "glow": Color(0.2, 0.6, 0.7)},
    "emberbound":   {"label": "emberbound", "hp": 0.90, "atk": 1.40, "spd": 1.15, "scale": 1.00, "tint": Color(1.00, 0.58, 0.32), "glow": Color(1.0, 0.4, 0.1)},
    "gorged":       {"label": "gorged", "hp": 1.60, "atk": 1.10, "spd": 0.75, "scale": 1.35, "tint": Color(0.86, 0.84, 0.46), "glow": Color(0, 0, 0)},
    "wraithtouched":{"label": "wraithtouched", "hp": 0.85, "atk": 1.25, "spd": 1.30, "scale": 0.98, "tint": Color(0.68, 0.55, 0.95), "glow": Color(0.6, 0.4, 1.0)},
    # L1: two strains the scar itself would make. Scarborn: grown too near the
    # wild magic - its glow wanders through every colour, as the scar's motes do.
    # Mossbacked: the drowned of the buried meadows and woods, grown over.
    "scarborn":     {"label": "scarborn", "hp": 0.95, "atk": 1.20, "spd": 1.10, "scale": 1.02, "tint": Color(0.92, 0.80, 1.00), "glow": Color(0.9, 0.3, 0.8), "wild": true},
    "mossbacked":   {"label": "mossbacked", "hp": 1.30, "atk": 0.95, "spd": 0.85, "scale": 1.08, "tint": Color(0.62, 0.82, 0.50), "glow": Color(0, 0, 0)},
}
static var no_strains := false

## the old bands, unchanged, then the scar's own strains: on a meadow or wood
## floor the drowned come up mossbacked; from floor 8 half the plain are scarborn
static func strain_for_theme(floor_no: int, theme: String) -> String:
    var s := strain_for(floor_no)
    if no_strains:
        return s
    if s == "drowned" and theme in ["grassland", "wood"]:
        return "mossbacked"
    if s == "plain" and floor_no >= 8 and randi() % 2 == 0:
        return "scarborn"
    return s

static func strain_for(floor_no: int) -> String:
    if no_strains:
        return "plain"
    var roll := randi() % 100
    if floor_no <= 2:
        return "plain" if roll < 85 else "hollowed"
    if floor_no <= 5:
        if roll < 55: return "plain"
        if roll < 75: return "hollowed"
        return "drowned"
    if floor_no <= 9:
        if roll < 30: return "plain"
        if roll < 48: return "drowned"
        if roll < 66: return "emberbound"
        if roll < 84: return "wraithtouched"
        return "gorged"
    if roll < 15: return "plain"
    if roll < 40: return "emberbound"
    if roll < 65: return "wraithtouched"
    if roll < 85: return "gorged"
    return "drowned"

## The eight lords (canon). Lesser hold floors ending in 5, greater every 10th.
## They rotate from two bags. `scale` multiplies the body's real-size scale.
const BOSS_DEFS := {
    "hollow_king":  {"title": "The Hollow King", "body": "warlock", "h": 4.2, "hp": 150.0, "atk": 15.0, "spd": 3.4, "tint": Color(1.0, 0.72, 0.45), "hand": ADV + "staff.gltf", "off": "", "wscale": 1.25, "glow": 1.0, "aura": Color(0.55, 0.75, 1.0), "note": "wreathed in cold fire"},
    "grubmother":   {"title": "The Grubmother", "body": "slime", "h": 4.5, "hp": 230.0, "atk": 10.0, "spd": 1.8, "tint": Color(0.62, 0.95, 0.45), "aura": Color(0.5, 1.0, 0.3), "note": "vast, slow, and patient"},
    "rattling_host":{"title": "The Rattling Host", "body": "warrior", "h": 4.4, "hp": 165.0, "atk": 14.0, "spd": 4.1, "tint": Color(0.92, 0.92, 0.86), "hand": ADV + "axe_2handed.gltf", "off": "", "wscale": 1.2, "glow": 0.6, "aura": Color(0.9, 0.9, 0.8), "note": "a hundred dead men in one harness"},
    "nightwing":    {"title": "Nightwing", "body": "bat", "h": 3.2, "hp": 110.0, "atk": 19.0, "spd": 6.6, "tint": Color(0.52, 0.40, 0.72), "aura": Color(0.5, 0.3, 0.9), "note": "too fast to see coming"},
    "gravewyrm":    {"title": "The Gravewyrm", "body": "dragon", "h": 9.0, "hp": 260.0, "atk": 22.0, "spd": 3.0, "tint": Color(1.0, 1.0, 1.0), "aura": Color(0.6, 1.0, 0.6), "note": "the thing the dungeon was built to hold"},
    "ossuary_lord": {"title": "The Ossuary Lord", "body": "bones", "h": 7.0, "hp": 330.0, "atk": 18.0, "spd": 2.5, "tint": Color(0.98, 0.90, 0.60), "hand": ADV + "sword_2handed.gltf", "off": ADV + "shield_spikes.gltf", "wscale": 1.2, "glow": 0.7, "aura": Color(1.0, 0.85, 0.4), "note": "it does not hurry; it does not need to"},
    "pale_duchess": {"title": "The Pale Duchess", "body": "cutpurse", "h": 4.6, "hp": 200.0, "atk": 27.0, "spd": 5.7, "tint": Color(0.80, 0.62, 0.95), "hand": ADV + "dagger.gltf", "off": ADV + "dagger.gltf", "wscale": 1.3, "glow": 0.8, "aura": Color(0.85, 0.5, 1.0), "note": "she opens throats, not doors"},
    "mourncoil":    {"title": "Mourncoil", "body": "dragon", "h": 10.0, "hp": 300.0, "atk": 24.0, "spd": 2.8, "tint": Color(0.62, 0.84, 1.0), "aura": Color(0.5, 0.85, 1.0), "note": "frost comes off it in sheets"},
}
const LESSER := ["hollow_king", "grubmother", "rattling_host", "nightwing"]
const GREATER := ["gravewyrm", "ossuary_lord", "pale_duchess", "mourncoil"]
## a lord stands this much taller than its canon height: a floor lord is an event
const LORD_SCALE := 1.2
static var _spent: Array = []
static var pending_title := ""

static func is_boss_floor(floor_no: int) -> bool:
    return floor_no > 0 and floor_no % 5 == 0

static func next_boss(floor_no: int) -> Dictionary:
    if not is_boss_floor(floor_no):
        return {}
    var pool_k: Array = GREATER if floor_no % 10 == 0 else LESSER
    var fresh := []
    for k in pool_k:
        if not _spent.has(k):
            fresh.append(k)
    if fresh.is_empty():
        for k in pool_k:
            _spent.erase(k)
        fresh = pool_k.duplicate()
        # a fresh bag never opens with the lord that closed the last one
        if fresh.size() > 1:
            fresh.erase(_last_lord)
    var pick_k: String = fresh[randi() % fresh.size()]
    _spent.append(pick_k)
    _last_lord = pick_k
    var out: Dictionary = (BOSS_DEFS[pick_k] as Dictionary).duplicate()
    out["id"] = pick_k
    if pending_title != "":
        out["title"] = pending_title
        out["note"] = "named by the crowd above"
        pending_title = ""
    return out
static var _last_lord := ""

static func boss_body(b: Dictionary) -> Dictionary:
    var body := String(b.get("body", "warrior"))
    if body == "dragon":
        return DRAGON
    if NEW_TYPES.has(body):
        return NEW_TYPES[body]
    return TYPES[body]

## ---- L2: each lord fights the way its canon note says it does. Delve reads
## these like any creature's ways. nova = a ring of its power on everyone near
## (slow = the heroes swing at half pace for that long); summon = calls its kind,
## up to `most`; shed = drops dead men from the harness as its hp falls past each
## mark; swoop = crosses the room onto the weakest and hits harder; enrage = below
## `at` of its hp it swings faster and harder; ward = takes that share of damage
## while anything it called still stands.
const LORD_WAYS := {
    "hollow_king":  {"ranged": 6.0, "nova": {"every": 9.0, "r": 6.0, "dmg": 0.6, "line": "Cold fire rolls off the Hollow King."}},
    "grubmother":   {"summon": {"type": "slimeling", "every": 9.0, "most": 4, "line": "The Grubmother's brood spills out of her."}},
    "rattling_host":{"shed": {"at": [0.66, 0.33], "type": "bones", "n": 2, "line": "Dead men drop out of the harness."}},
    "nightwing":    {"swoop": {"every": 7.0, "mult": 1.6}, "summon": {"type": "bat", "every": 14.0, "most": 2, "line": "Bats pour out of the dark around Nightwing."}},
    "gravewyrm":    {"breath": 4.0, "enrage": {"at": 0.3, "swing": 0.6, "atk": 1.3}},
    "ossuary_lord": {"summon": {"type": "bones", "every": 12.0, "most": 2, "rise": true, "line": "The Ossuary Lord calls its bones up out of the floor."}, "ward": 0.5},
    "pale_duchess": {"venom": 4.0, "grudge": true, "enrage": {"at": 0.35, "swing": 0.55, "atk": 1.25}},
    "mourncoil":    {"breath": 3.0, "nova": {"every": 8.0, "r": 7.0, "dmg": 0.5, "slow": 3.0, "line": "Frost comes off Mourncoil in sheets."}},
}

## ---- L2: rare uniques. Not lords and never on a lord's floor: a named thing
## that turns up now and then (UNIQUE_CHANCE of an ordinary floor from floor 2),
## from a bag, never the same one twice running. Each has a name card, the boss
## bar and a mechanic. The last is the scar's own: a delver from the memorial,
## kept below (only once someone has fallen there).
const UNIQUE_CHANCE := 0.12
const UNIQUES := {
    "gnawbone":   {"title": "Gnawbone", "body": "rat", "h": 1.5, "min": 2, "hp": 4.0, "atk": 1.3, "tint": Color(0.78, 0.70, 0.58), "aura": Color(0.85, 0.65, 0.35),
                   "note": "the rats' queen, fat on what the delvers dropped",
                   "ways": {"summon": {"type": "rat", "every": 8.0, "most": 4, "line": "Gnawbone's children come squealing."}}},
    "mother_silk":{"title": "Mother Silk", "body": "spider", "h": 1.6, "min": 3, "hp": 4.0, "atk": 1.3, "tint": Color(0.86, 0.86, 0.92), "aura": Color(0.80, 0.85, 1.0),
                   "note": "every thread in the dark is hers",
                   "ways": {"venom": 6.0, "summon": {"type": "spider", "every": 11.0, "most": 3, "line": "Spiders drop from Mother Silk's threads."}}},
    "weeping_bowman":{"title": "The Weeping Bowman", "body": "bowman", "h": 2.3, "min": 4, "hp": 3.5, "atk": 1.2, "tint": Color(0.62, 0.80, 0.86), "aura": Color(0.45, 0.75, 0.90),
                   "hand": SKA + "Skeleton_Crossbow.gltf", "note": "it never stops drawing",
                   "ways": {"ranged": 11.0, "shot": "bolt_bone", "volley": true}},
    "cinderjack": {"title": "Cinderjack", "body": "imp", "h": 1.9, "min": 6, "hp": 3.5, "atk": 1.4, "tint": Color(1.0, 0.62, 0.38), "aura": Color(1.0, 0.45, 0.15),
                   "note": "the firepits let him out",
                   "ways": {"ranged": 7.0, "nova": {"every": 7.5, "r": 5.0, "dmg": 0.55, "line": "Cinderjack goes up like a struck match."}}},
    "kept":       {"title": "%s, Kept by the Scar", "body": "lost", "h": 2.0, "min": 3, "hp": 4.5, "atk": 1.4, "tint": Color(0.80, 0.86, 0.96), "aura": Color(0.55, 0.70, 1.0),
                   "hand": ADV + "sword_1handed.gltf", "note": "fell below, and the scar did not let go",
                   "ways": {"grudge": true, "enrage": {"at": 0.4, "swing": 0.6, "atk": 1.3}}},
}
## the memorial (Roster.fallen), set by Delve before each floor is built
static var memorial: Array = []
static var _last_unique := ""
## test hook: only this unique may be drawn
static var only_unique := ""

static func unique_for(floor_no: int, roll: float) -> Dictionary:
    if is_boss_floor(floor_no) or floor_no < 2 or roll >= UNIQUE_CHANCE:
        return {}
    var below: Array = []
    for f in memorial:
        if String((f as Dictionary).get("killed_by", "")) == "the dark below":
            below.append(f)
    var keys: Array = []
    for k in UNIQUES:
        if only_unique != "" and k != only_unique:
            continue
        if floor_no >= int(UNIQUES[k]["min"]) and (k != _last_unique or only_unique != "") and (k != "kept" or not below.is_empty()):
            keys.append(k)
    if keys.is_empty():
        return {}
    var k: String = keys[randi() % keys.size()]
    _last_unique = k
    var u: Dictionary = (UNIQUES[k] as Dictionary).duplicate(true)
    u["id"] = k
    if k == "kept":
        var f: Dictionary = below[randi() % below.size()]
        u["title"] = String(u["title"]) % String(f["name"])
        u["note"] = "a %s of the guild who fell below, and the scar did not let go" % String(f.get("class", "delver"))
        var cls := String(f.get("class", "knight"))
        var body := "Knight"
        if cls in ["barbarian", "warden"]:
            body = "Barbarian"
        elif cls in ["rogue", "duelist", "ranger"]:
            body = "Rogue_Hooded"
        elif cls in ["mage", "sage", "cleric"]:
            body = "Mage"
        u["path"] = ADVC + body + ".glb"
    return u

## a unique as a spawnable def: like a lord, scaled to this floor
static func unique_def(u: Dictionary, floor_no: int) -> Dictionary:
    var out: Dictionary = make(String(u["body"]), "plain")
    out["name"] = u["title"]
    out["h"] = float(u["h"])
    out["lift"] = float(out.get("lift", 0.0)) * float(u["h"]) / maxf(0.1, float(def_of(String(u["body"]))["h"]))
    out["tint"] = u["tint"]
    out["glow"] = Color(0, 0, 0)
    out["boss"] = true
    out["unique"] = true
    out["id"] = u["id"]
    out["note"] = u["note"]
    out["aura"] = u["aura"]
    if u.has("hand"):
        out["hand"] = u["hand"]
    if u.has("path"):
        out["path"] = u["path"]
    out["ways"] = (u["ways"] as Dictionary).duplicate(true)
    out["boss_hp"] = (14.0 + float(floor_no) * 6.0) * float(u["hp"])
    out["boss_atk"] = (6.0 + float(floor_no) * 2.2) * float(u["atk"])
    return out

## which creatures live at which depth (old bands, the new creatures woven in
## where they fit: vermin up top, venom in the middle, fiends deep)
const DEPTHS := [
    [1, 2,  ["slime", "bat", "minion", "rat", "frog"]],
    [3, 4,  ["minion", "bones", "bat", "slime", "rat", "spider", "puglin", "bowman"]],
    [5, 5,  ["warrior", "bones", "warlock", "spider", "bowman", "sentinel"]],
    [6, 7,  ["warrior", "cutpurse", "bones", "snake", "wasp", "puglin", "bowman", "sentinel", "gravecaller"]],
    [8, 9,  ["warrior", "warlock", "bones", "bat", "adder", "imp", "sentinel", "gravecaller", "lost"]],
    [10, 99,["warrior", "warlock", "cutpurse", "bones", "adder", "imp", "wasp", "bowman", "sentinel", "gravecaller", "lost", "whelp"]],
]

static func pool(floor_no: int) -> Array:
    for band in DEPTHS:
        if floor_no >= int(band[0]) and floor_no <= int(band[1]):
            return band[2]
    return ["warrior", "bones"]

## the depth's pool, with every creature at home on this theme counted thrice
static func pool_for(floor_no: int, theme := "") -> Array:
    var out: Array = pool(floor_no).duplicate()
    if theme == "":
        return out
    for k in pool(floor_no):
        if (def_of(String(k)).get("homes", []) as Array).has(theme):
            out.append(k)
            out.append(k)
    return out

static func make(type_key: String, strain_key := "plain") -> Dictionary:
    var out: Dictionary = def_of(type_key)
    if out.has("paths"):
        var ps: Array = out["paths"]
        out["path"] = ps[randi() % ps.size()]
    var st: Dictionary = STRAINS[strain_key]
    out["type"] = type_key
    out["strain"] = strain_key
    var label := String(st["label"])
    if label != "":
        out["name"] = "%s %s" % [label, String(out["name"])]
    out["hp"] = float(out["hp"]) * float(st["hp"])
    out["atk"] = float(out["atk"]) * float(st["atk"])
    out["spd"] = float(out["spd"]) * float(st["spd"])
    out["h"] = float(out["h"]) * float(st["scale"])
    # a creature with a look of its own keeps it on a plain strain
    if strain_key != "plain" or not out.has("tint"):
        out["tint"] = st["tint"]
    if strain_key != "plain" or not out.has("glow"):
        out["glow"] = st["glow"]
    out["wild"] = bool(st.get("wild", false))
    if not out.has("ways"):
        out["ways"] = {}
    return out

static func pick(floor_no: int, theme := "") -> Dictionary:
    var p := pool_for(floor_no, theme)
    return make(String(p[randi() % p.size()]), strain_for_theme(floor_no, theme))

## a boss as a spawnable def: its body, scaled up, armed, haloed, named
static func boss_def(b: Dictionary) -> Dictionary:
    var out: Dictionary = (boss_body(b) as Dictionary).duplicate(true)
    out["name"] = b["title"]
    out["h"] = float(b["h"]) * LORD_SCALE
    out["tint"] = b["tint"]
    out["boss"] = true
    out["note"] = b.get("note", "")
    out["aura"] = b.get("aura", Color(1, 0.8, 0.4))
    out["lift"] = float(out.get("lift", 0.0)) * float(out["h"]) / float(boss_body(b)["h"]) * 0.5
    if b.has("hand"):
        out["hand"] = b["hand"]
        out["off"] = b.get("off", "")
        out["wscale"] = b.get("wscale", 1.0)
        out["wglow"] = b.get("glow", 0.0)
    out["boss_hp"] = b["hp"]
    out["boss_atk"] = b["atk"]
    out["id"] = b.get("id", "")
    out["ways"] = (LORD_WAYS.get(String(b.get("id", "")), {}) as Dictionary).duplicate(true)
    return out
