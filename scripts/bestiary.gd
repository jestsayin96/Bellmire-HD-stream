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
}
static var no_strains := false

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
    var pick_k: String = fresh[randi() % fresh.size()]
    _spent.append(pick_k)
    var out: Dictionary = (BOSS_DEFS[pick_k] as Dictionary).duplicate()
    out["id"] = pick_k
    if pending_title != "":
        out["title"] = pending_title
        out["note"] = "named by the crowd above"
        pending_title = ""
    return out

static func boss_body(b: Dictionary) -> Dictionary:
    var body := String(b.get("body", "warrior"))
    if body == "dragon":
        return DRAGON
    return TYPES[body]

## which creatures live at which depth (old bands, the new creatures woven in
## where they fit: vermin up top, venom in the middle, fiends deep)
const DEPTHS := [
    [1, 2,  ["slime", "bat", "minion", "rat", "frog"]],
    [3, 4,  ["minion", "bones", "bat", "slime", "rat", "spider", "puglin"]],
    [5, 5,  ["warrior", "bones", "warlock", "spider"]],
    [6, 7,  ["warrior", "cutpurse", "bones", "snake", "wasp", "puglin"]],
    [8, 9,  ["warrior", "warlock", "bones", "bat", "adder", "imp"]],
    [10, 99,["warrior", "warlock", "cutpurse", "bones", "adder", "imp", "wasp"]],
]

static func pool(floor_no: int) -> Array:
    for band in DEPTHS:
        if floor_no >= int(band[0]) and floor_no <= int(band[1]):
            return band[2]
    return ["warrior", "bones"]

static func make(type_key: String, strain_key := "plain") -> Dictionary:
    var out: Dictionary = (TYPES[type_key] as Dictionary).duplicate(true)
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
    out["tint"] = st["tint"]
    out["glow"] = st["glow"]
    return out

static func pick(floor_no: int) -> Dictionary:
    var p := pool(floor_no)
    return make(String(p[randi() % p.size()]), strain_for(floor_no))

## a boss as a spawnable def: its body, scaled up, armed, haloed, named
static func boss_def(b: Dictionary) -> Dictionary:
    var out: Dictionary = (boss_body(b) as Dictionary).duplicate(true)
    out["name"] = b["title"]
    out["h"] = float(b["h"])
    out["tint"] = b["tint"]
    out["boss"] = true
    out["note"] = b.get("note", "")
    out["aura"] = b.get("aura", Color(1, 0.8, 0.4))
    out["lift"] = float(out.get("lift", 0.0)) * float(b["h"]) / float(boss_body(b)["h"]) * 0.5
    if b.has("hand"):
        out["hand"] = b["hand"]
        out["off"] = b.get("off", "")
        out["wscale"] = b.get("wscale", 1.0)
        out["wglow"] = b.get("glow", 0.0)
    out["boss_hp"] = b["hp"]
    out["boss_atk"] = b["atk"]
    return out
