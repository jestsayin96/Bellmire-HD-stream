## PORTED VERBATIM from the old game (trial-and-error, read only). Pure data + rules, no Twitch connection.
class_name Roster
extends Node

# Persistent viewer characters for Jests Medieval Adventure.
#
# Keyed by Twitch USER-ID, never display name: viewers rename themselves and a
# name key would orphan their hero. The id arrives in the IRC tags as `user-id`.
#
# PERMADEATH. When a hero dies they move to `fallen` for the memorial and the
# leaderboards, and the viewer rolls a fresh one. That is what makes buying
# armour matter.
#
# No Twitch dependency in here on purpose - this is pure data and rules so it
# can be driven from a fake chat feed and tested headless.

const SAVE_PATH := "user://roster.json"
# Proper D&D abilities. Scores run 3-18 from 4d6-drop-lowest; the MODIFIER is
# floor((score - 10) / 2), so 10-11 is +0 and 18 is +4. Every derived number
# uses the modifier, never the raw score.
const STATS := ["str", "dex", "con", "int", "wis", "cha"]
const STAT_FULL := {
    "str": "Strength", "dex": "Dexterity", "con": "Constitution",
    "int": "Intelligence", "wis": "Wisdom", "cha": "Charisma",
}

static func modifier(score: int) -> int:
    return int(floor((float(score) - 10.0) / 2.0))

static func sign_str(n: int) -> String:
    return ("+%d" % n) if n >= 0 else str(n)

# Eight callings from five models. A class is a MODEL plus a weapon FAMILY plus
# an offhand plus a stat profile - so Rogue+crossbow+quiver reads as a Ranger
# and Rogue+twin-blades reads as a Duelist without needing new meshes.
## L6: heroes wear the KayKit Adventurers 2.0 bodies (CC0, assets/characters/kaykit_adv2), baked by
## tools/_bake_adv2.gd into scenes with the shared animation library. Relative to the
## KayKit 1.0 folder the hero loader prefixes (it resolves to res://assets/...).
const ADV2 := "../../../../assets/characters/kaykit_adv2/hero_"
const CLASSES := {
    "knight":    {"hp": 72, "atk": 11, "spd": 4.2, "model": ADV2 + "Knight.tscn",
                  "family": "blade", "offhand": "shield_square.gltf",
                  "primary": "str", "blurb": "Stout, shielded. Hard to kill, slow to finish a fight."},
    "warden":    {"hp": 80, "atk": 10, "spd": 3.9, "model": ADV2 + "Knight.tscn",
                  "family": "axe", "offhand": "shield_round_barbarian.gltf",
                  "primary": "str", "blurb": "The wall the dungeon breaks on."},
    "barbarian": {"hp": 88, "atk": 13, "spd": 4.4, "model": ADV2 + "Barbarian.tscn",
                  "family": "axe", "offhand": "",
                  "primary": "str", "blurb": "The most meat. Swings heavy, guards nothing."},
    "rogue":     {"hp": 48, "atk": 15, "spd": 5.4, "model": ADV2 + "Rogue.tscn",
                  "family": "blade", "offhand": "",
                  "primary": "dex", "blurb": "Fast and sharp, but folds under a real hit."},
    "duelist":   {"hp": 52, "atk": 16, "spd": 5.1, "model": ADV2 + "Rogue.tscn",
                  "family": "blade", "offhand": "dagger.gltf",
                  "primary": "dex", "blurb": "Two blades, no patience."},
    "ranger":    {"hp": 55, "atk": 14, "spd": 4.9, "model": ADV2 + "Ranger.tscn",
                  "family": "ranged", "offhand": "quiver.gltf", "offhand_bone": "chest",
                  "primary": "dex", "blurb": "Kills things before they arrive."},
    "mage":      {"hp": 42, "atk": 19, "spd": 4.0, "model": ADV2 + "Mage.tscn",
                  "family": "arcane", "offhand": "",
                  "primary": "int", "blurb": "Hits hardest. Dies hardest."},
    "sage":      {"hp": 50, "atk": 9, "spd": 4.0, "model": ADV2 + "Mage.tscn",
                  "family": "arcane", "offhand": "spellbook_open.gltf",
                  "primary": "wis",
                  "blurb": "Mends the party faster than the dark can open it."},
    "cleric":    {"hp": 60, "atk": 12, "spd": 4.1, "model": ADV2 + "Mage.tscn",
                  "family": "arcane", "offhand": "shield_round.gltf",
                  "primary": "wis", "blurb": "Keeps the party upright longer than it deserves."},
    # ---- L4: six more callings, built the old way (a body + a family + an
    # offhand + a stat profile), each with one thing it does in a fight
    # (Delve reads "ability") and a cloak colour so it reads at stream distance.
    "paladin":   {"hp": 70, "atk": 11, "spd": 4.1, "model": ADV2 + "Knight.tscn",
                  "family": "blade", "offhand": "shield_badge_color.gltf", "kind": "sword",
                  "primary": "str", "ability": "smite", "cape": Color(0.92, 0.86, 0.62),
                  "blurb": "Lays hands on the fallen, and hits the dead twice as hard."},
    "necromancer": {"hp": 44, "atk": 17, "spd": 4.0, "model": ADV2 + "Mage.tscn",
                  "family": "arcane", "offhand": "spellbook_closed.gltf", "kind": "staff",
                  "primary": "int", "ability": "drain", "cape": Color(0.10, 0.16, 0.12),
                  "blurb": "Reads the scar's own grammar. Drinks back what it spends."},
    "monk":      {"hp": 58, "atk": 13, "spd": 5.6, "model": ADV2 + "Rogue.tscn",
                  "family": "open", "offhand": "", "kind": "quarterstaff",
                  "primary": "dex", "ability": "flurry", "cape": Color(0.90, 0.55, 0.18),
                  "blurb": "Fast hands, no armour, no fear of the dark."},
    "druid":     {"hp": 54, "atk": 12, "spd": 4.1, "model": ADV2 + "Mage.tscn",
                  "family": "arcane", "offhand": "", "kind": "staff",
                  "primary": "wis", "ability": "thorns", "cape": Color(0.22, 0.48, 0.20),
                  "blurb": "Brought the meadow down with them. Thorns take the crowd."},
    "warlock":   {"hp": 46, "atk": 17, "spd": 4.3, "model": ADV2 + "Rogue_Hooded.tscn",
                  "family": "arcane", "offhand": "spellbook_closed.gltf", "kind": "wand",
                  "primary": "cha", "ability": "hex", "cape": Color(0.36, 0.14, 0.46),
                  "blurb": "Struck a bargain with something below. Marks a thing for everyone."},
    "bard":      {"hp": 52, "atk": 12, "spd": 4.8, "model": ADV2 + "Rogue.tscn",
                  "family": "blade", "offhand": "", "kind": "dagger",
                  "primary": "cha", "ability": "inspire", "cape": Color(0.70, 0.12, 0.16),
                  "blurb": "Sings the party steady. Everyone swings truer while they stand."},
}
## ---- L5: the peoples of the valley. The old game names none (its folk read
## as valley humans), so these are new: the common five, plus one only this
## world has - the scarkin, born too near the scar. 5e-style ability bonuses
## (capped at 20), one trait each that Delve reads, and a look (Gear dresses it).
## darkvision: no disadvantage when the oil is gone. lucky: a natural 1 is rolled again.
const SPECIES := {
    "human":    {"bonus": {"str": 1, "dex": 1, "con": 1, "int": 1, "wis": 1, "cha": 1}, "trait": "",
                 "weight": 34, "blurb": "valley-born, like most of Bellmire"},
    "elf":      {"bonus": {"dex": 2, "int": 1}, "trait": "darkvision", "weight": 12,
                 "scale": Vector3(0.96, 1.05, 0.96), "skin": Color(1.0, 0.96, 0.92), "parts": ["ears"],
                 "blurb": "out of the old woods past the fields; sees in the dark"},
    "dwarf":    {"bonus": {"con": 2, "wis": 1}, "trait": "darkvision", "weight": 14,
                 "scale": Vector3(1.12, 0.86, 1.12), "skin": Color(1.0, 0.86, 0.78), "parts": ["beard"],
                 "blurb": "down from the hill mines; sees in the dark"},
    "halfling": {"bonus": {"dex": 2, "cha": 1}, "trait": "lucky", "weight": 12,
                 "scale": Vector3(0.80, 0.78, 0.80), "skin": Color(1.0, 0.94, 0.88), "parts": [],
                 "blurb": "from the field-farms; a natural 1 is rolled again"},
    "orc":      {"bonus": {"str": 2, "con": 1}, "trait": "darkvision", "weight": 14,
                 "scale": Vector3(1.10, 1.06, 1.10), "skin": Color(0.62, 0.80, 0.54), "parts": ["tusks"],
                 "blurb": "came over the west road and stayed; sees in the dark"},
    "scarkin":  {"bonus": {"cha": 2, "int": 1}, "trait": "darkvision", "weight": 8,
                 "scale": Vector3(1.0, 1.0, 1.0), "skin": Color(0.84, 0.74, 0.98), "parts": ["shard"],
                 "blurb": "born too near the scar; its light in the eyes, its dark no bother"},
}

func _any_species() -> String:
    var total := 0
    for k in SPECIES:
        total += int(SPECIES[k]["weight"])
    var r := rng.randi() % total
    for k in SPECIES:
        r -= int(SPECIES[k]["weight"])
        if r < 0:
            return k
    return "human"

func _with_species(stats: Dictionary, species: String) -> Dictionary:
    var b: Dictionary = SPECIES.get(species, {}).get("bonus", {})
    for k in b:
        stats[k] = mini(20, int(stats.get(k, 10)) + int(b[k]))
    return stats

static func species_of(h: Dictionary) -> String:
    return String(h.get("species", "human"))

static func has_trait(h: Dictionary, t: String) -> bool:
    return String(SPECIES.get(species_of(h), {}).get("trait", "")) == t

## L4: the casters throw bolts from range; the healers mend
const CASTERS := ["mage", "sage", "cleric", "necromancer", "druid", "warlock"]

# Only four weapon meshes per family exist, so the top tiers reuse a mesh and
# separate themselves by SIZE and GLOW instead. A dragontooth blade is the same
# geometry as a runed one, bigger and lit from within.
const FAMILIES := {
    "blade":  ["dagger.gltf", "sword_1handed.gltf", "sword_2handed.gltf", "sword_2handed_color.gltf"],
    "axe":    ["axe_1handed.gltf", "axe_1handed.gltf", "axe_2handed.gltf", "axe_2handed.gltf"],
    "arcane": ["wand.gltf", "wand.gltf", "staff.gltf", "staff.gltf"],
    "ranged": ["crossbow_1handed.gltf", "crossbow_1handed.gltf", "crossbow_2handed.gltf", "crossbow_2handed.gltf"],
}

# tiered goods. index is the tier the viewer owns; 0 means nothing bought yet.
const WEAPONS := [
    {"name": "bare hands", "cost": 0,    "atk": 0,  "scale": 0.0, "glow": 0.0, "dice": [1, 4]},
    {"name": "plain steel", "cost": 60,  "atk": 4,  "scale": 1.0, "glow": 0.0, "dice": [1, 6]},
    {"name": "fine steel",  "cost": 160, "atk": 9,  "scale": 1.05, "glow": 0.0, "dice": [1, 8]},
    {"name": "runed",       "cost": 420, "atk": 16, "scale": 1.12, "glow": 0.5, "dice": [1, 10]},
    {"name": "dragontooth", "cost": 1100,"atk": 26, "scale": 1.25, "glow": 1.0, "dice": [1, 12]},
    # L3: found only below (Gear.WEAPONS carries the same row) - no smith makes it
    {"name": "scarforged",  "cost": 0,   "atk": 34, "scale": 1.3, "glow": 1.3, "found": true, "dice": [2, 8]},
]
# "ac" is the 5E armour bonus on top of 10 + DEX. Armour used to give hit
# points only, which is not how D&D works: better armour should make you
# harder to HIT, not spongier.
const ARMOUR := [
    {"name": "rags", "cost": 0, "hp": 0, "ac": 0},
    {"name": "leather", "cost": 50, "hp": 10, "ac": 1},
    {"name": "chainmail", "cost": 150, "hp": 26, "ac": 3},
    {"name": "plate", "cost": 400, "hp": 48, "ac": 5},
    {"name": "warded plate", "cost": 1000, "hp": 80, "ac": 7},
    {"name": "scarwoven mail", "cost": 0, "hp": 110, "ac": 8, "found": true},
]
## the forge's best: the found-only tiers above are never sold
static func forged_max(list: Array) -> int:
    var top := 0
    for i in range(list.size()):
        if not bool((list[i] as Dictionary).get("found", false)):
            top = i
    return top
# WHAT THE TOWN CAN MAKE. His design: levelling the town "unlocks more gear
# and stuff potions". A hamlet's smith does not forge warded plate - the top
# tiers are gated behind Bellmire itself growing, which gives the valley's
# prosperity a direct, visible payoff for every viewer with a purse.
#
# Set once a day from Sim.town_level. Defaults wide open so the harness and
# any test that never builds a town are unaffected.
static var town_tier := 4

static func tier_for_town(level: int) -> int:
    return clampi(level, 1, 4)

const POTION_COST := 35
# A flask of lamp oil. Deliberately cheap: light is the one thing nobody
# should be priced out of, because a hero who cannot afford it drags the
# whole party into the dark (see Expedition).
const OIL_COST := 12
const REROLL_COST := 120
const RESPEC_COST := 200

var heroes := {}        # user_id -> hero dictionary
var patrons := {}       # user_id -> {name, given} - who has given to the valley
var fallen := []        # newest first; the memorial
var rng := RandomNumberGenerator.new()

signal changed(user_id: String)
signal announced(line: String, colour: Color)

func _init() -> void:
    rng.randomize()

# ----------------------------------------------------------------- lifecycle
func fresh(user_id: String, display: String, cls := "", species := "") -> Dictionary:
    if cls == "" or not CLASSES.has(cls):
        cls = CLASSES.keys()[rng.randi() % CLASSES.size()]
    if not SPECIES.has(species):
        species = _any_species()
    var h := {
        "id": user_id, "name": display, "class": cls, "species": species,
        "stats": _with_species(roll_stats(cls), species), "weapon": 0, "armour": 0, "potions": 1,
        "oil": 2,
        "gold": 40, "level": 1, "xp": 0,
        "delves": 0, "kills": 0, "deepest": 0, "alive": true,
    }
    heroes[user_id] = h
    return h

# 4d6 drop lowest, the way a tabletop roll goes. Range 3-18, centred near 12.
#
# The six rolls are then ASSIGNED rather than dealt out blind: the best roll
# goes to the class's primary ability, exactly as a player would place it. A
# sage with STR 18 and WIS 8 is a wasted character sheet.
func roll_stats(cls := "") -> Dictionary:
    var rolls := []
    for i in range(STATS.size()):
        var d := [rng.randi_range(1, 6), rng.randi_range(1, 6),
                  rng.randi_range(1, 6), rng.randi_range(1, 6)]
        d.sort()
        rolls.append(int(d[1] + d[2] + d[3]))
    rolls.sort()
    rolls.reverse()                       # best first
    var order := STATS.duplicate()
    if cls != "" and CLASSES.has(cls):
        var prim := String(CLASSES[cls].get("primary", "str"))
        order.erase(prim)
        _shuffle(order)
        order.push_front(prim)
    else:
        _shuffle(order)
    var out := {}
    for i in range(order.size()):
        out[String(order[i])] = int(rolls[i])
    return out

# own shuffle so a seeded rng gives reproducible characters
func _shuffle(a: Array) -> void:
    for i in range(a.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var t = a[i]; a[i] = a[j]; a[j] = t

func get_hero(user_id: String) -> Dictionary:
    return heroes.get(user_id, {})

func is_alive(user_id: String) -> bool:
    var h := get_hero(user_id)
    return not h.is_empty() and bool(h.get("alive", false))

# derived combat numbers: class base + stat modifiers + gear
# ---------------------------------------------------------- the 5E numbers
# Which two abilities each class is proficient in, as on the sheet.
const SAVES := {
    "knight": ["str", "con"], "warden": ["con", "wis"],
    "barbarian": ["str", "con"], "rogue": ["dex", "int"],
    "duelist": ["dex", "cha"], "ranger": ["dex", "str"],
    "mage": ["int", "wis"], "sage": ["wis", "cha"], "cleric": ["wis", "cha"],
    # L4, as the 5e sheets have them
    "paladin": ["wis", "cha"], "necromancer": ["int", "wis"], "monk": ["str", "dex"],
    "druid": ["int", "wis"], "warlock": ["wis", "cha"], "bard": ["dex", "cha"],
}

# 5E proficiency: +2 at level 1, +1 every four levels after.
func prof(h: Dictionary) -> int:
    return 2 + int(floor((float(int(h.get("level", 1))) - 1.0) / 4.0))

# 10 + DEX + armour, and +2 for a shield in the off hand, as 5E does it.
func armour_class(h: Dictionary) -> int:
    var ac := 10 + mod(h, "dex") + int(ARMOUR[int(h.get("armour", 0))].get("ac", 0))
    var off := String(CLASSES[String(h["class"])].get("offhand", ""))
    if off.begins_with("shield"):
        ac += 2
    # L4: a monk in no more than leather adds WIS (unarmoured defence)
    if String(h["class"]) == "monk" and int(h.get("armour", 0)) <= 1:
        ac += maxi(0, mod(h, "wis"))
    return ac

# d20 + proficiency + the class's own ability, as the attack line on the sheet.
func attack_bonus(h: Dictionary) -> int:
    return prof(h) + mod(h, String(CLASSES[String(h["class"])].get("primary", "str")))

func save_bonus(h: Dictionary, stat: String) -> int:
    var b := mod(h, stat)
    if stat in SAVES.get(String(h["class"]), []):
        b += prof(h)
    return b

func save_line(h: Dictionary) -> String:
    var parts := []
    for k: String in SAVES.get(String(h["class"]), []):
        parts.append("%s %s" % [k.to_upper(), sign_str(save_bonus(h, k))])
    return " ".join(parts)

func mod(h: Dictionary, stat: String) -> int:
    return modifier(int(h["stats"].get(stat, 10)))

func max_hp(h: Dictionary) -> float:
    return float(CLASSES[h["class"]]["hp"]) + float(mod(h, "con")) * 5.0 \
         + float(ARMOUR[int(h["armour"])]["hp"])

# a class hits with its own ability: a mage's INT, a rogue's DEX, a knight's STR
func attack(h: Dictionary) -> float:
    var prim: String = String(CLASSES[h["class"]].get("primary", "str"))
    return float(CLASSES[h["class"]]["atk"]) + float(mod(h, prim)) * 1.6 \
         + float(WEAPONS[int(h["weapon"])]["atk"])

func speed(h: Dictionary) -> float:
    return float(CLASSES[h["class"]]["spd"]) + float(mod(h, "dex")) * 0.15

# WIS drives mending; sages mend harder than clerics
func heal_power(h: Dictionary) -> float:
    var cls: String = String(h["class"])
    if cls == "paladin":
        # L4: lay on hands - a smaller well, drawn on CHA
        return 5.0 + float(maxi(0, mod(h, "cha"))) * 2.0
    if cls not in ["sage", "cleric"]:
        return 0.0
    var base: float = 11.0 if cls == "sage" else 7.0
    return base + float(mod(h, "wis")) * 2.5

## L9: a weapon's damage dice by tier (bare hands 1d4 ... scarforged 2d8)
func weapon_dice(h: Dictionary) -> Array:
    return WEAPONS[clampi(int(h.get("weapon", 0)), 0, WEAPONS.size() - 1)].get("dice", [1, 4])

func dice_str(h: Dictionary) -> String:
    var d := weapon_dice(h)
    return "%dd%d" % [int(d[0]), int(d[1])]

# L9 (DnD RULE): CHA no longer takes a flat cut off every price - the hero
# haggles, a CHA check at the counter (Roster.haggle). Kept for old callers.
func price_mult(_h: Dictionary) -> float:
    return 1.0

## Persuasion at the counter: d20 + CHA (+ proficiency for the talkers - bard,
## warlock, paladin, rogue) vs DC 12. Beat it: 10% off, +1% a point over, at most
## 20%. A natural 20: a quarter off. A natural 1: the smith takes offence, a
## tenth over. Otherwise the list price. last_haggle says what happened.
const HAGGLE_DC := 12
const TALKERS := ["bard", "warlock", "paladin", "rogue"]
var last_haggle := ""
func haggle(h: Dictionary, list_price: int) -> int:
    var d := rng.randi_range(1, 20)
    var total := d + mod(h, "cha") + (prof(h) if String(h["class"]) in TALKERS else 0)
    var k := 1.0
    last_haggle = ""
    if d == 20:
        k = 0.75
        last_haggle = " A natural 20 at the counter - a quarter off."
    elif d == 1:
        k = 1.1
        last_haggle = " A natural 1 - the smith takes offence and charges a tenth over."
    elif total >= HAGGLE_DC:
        k = 1.0 - clampf(0.10 + 0.01 * float(total - HAGGLE_DC), 0.10, 0.20)
        last_haggle = " Haggled %d%% off (%d)." % [int(round((1.0 - k) * 100.0)), total]
    return maxi(1, int(round(float(list_price) * k)))

# ------------------------------------------------------------------ spending
# Every purchase in the game goes through here, so the guild's rate goes here
# too rather than being sprinkled over each shop. Charisma haggles; rank is
# the guild telling the smith what this one pays.
func cost_for(h: Dictionary, base: int) -> int:
    var off := float(rank_row(h).get("off", 0.0))
    return maxi(1, int(round(float(base) * price_mult(h) * (1.0 - off))))

func spend(h: Dictionary, cost: int) -> bool:
    if int(h["gold"]) < cost:
        return false
    h["gold"] = int(h["gold"]) - cost
    Sfx.play("coin", -6.0)
    return true

func buy_weapon(user_id: String, kind := "") -> String:
    var h := get_hero(user_id)
    if h.is_empty(): return "no hero"
    # L3: !forge <kind> - a kind of this hero's family (sword, spear, mace, bow...)
    if kind != "":
        var fam := String(CLASSES[h["class"]]["family"])
        if not Gear.KINDS.has(kind) or String(Gear.KINDS[kind]["family"]) != fam:
            return "The smith does not make a %s for a %s. Ask for: %s." % [kind, h["class"], ", ".join(Gear.kinds_of(fam))]
        var top := mini(forged_max(WEAPONS), town_tier)
        if int(h["weapon"]) >= top and int(h["weapon"]) > 0:
            # nothing better to buy: the smith reworks what they carry into the new kind
            if String(h.get("wkind", "")) == kind:
                return "%s already carries %s %s." % [h["name"], _an(weapon_name(h)), weapon_name(h)]
            if bool(WEAPONS[int(h["weapon"])].get("found", false)):
                return "No smith in Bellmire will put a hammer to scarforged steel."
            var rework := haggle(h, cost_for(h, int(int(WEAPONS[int(h["weapon"])]["cost"]) / 4)))
            if not spend(h, rework):
                return "%s needs %d gold to have it reworked into a %s (has %d)." % [h["name"], rework, kind, int(h["gold"])]
            h["wkind"] = kind
            changed.emit(user_id)
            return "The smith reworks %s's steel into %s %s.%s" % [h["name"], _an(weapon_name(h)), weapon_name(h), last_haggle]
    var nxt: int = int(h["weapon"]) + 1
    if nxt >= WEAPONS.size() or bool(WEAPONS[nxt].get("found", false)):
        return "%s already carries %s %s - nothing better is forged here." \
            % [h["name"], _an(weapon_name(h)), weapon_name(h)]
    if nxt > town_tier:
        return "%s wants %s, but no smith in Bellmire can forge it yet." \
            % [h["name"], WEAPONS[nxt]["name"]]
    var w: Dictionary = WEAPONS[nxt]
    var peek := h.duplicate(true)
    peek["weapon"] = nxt
    if kind != "":
        peek["wkind"] = kind
    var label := weapon_name(peek)
    var price := haggle(h, cost_for(h, int(w["cost"])))
    if not spend(h, price):
        return "%s needs %d gold for %s %s (has %d)." \
            % [h["name"], price, _an(label), label, int(h["gold"])]
    h["weapon"] = nxt
    if kind != "":
        h["wkind"] = kind
    changed.emit(user_id)
    return "%s takes up %s %s. (+%d atk, %dd%d)%s" % [h["name"], _an(label), label, int(w["atk"]), int(w["dice"][0]), int(w["dice"][1]), last_haggle]

func _an(word: String) -> String:
    return "an" if word.substr(0, 1).to_lower() in ["a", "e", "i", "o", "u"] else "a"

func buy_armour(user_id: String) -> String:
    var h := get_hero(user_id)
    if h.is_empty(): return "no hero"
    var nxt: int = int(h["armour"]) + 1
    if nxt >= ARMOUR.size() or bool(ARMOUR[nxt].get("found", false)):
        return "%s is already in %s - nothing better is made here." % [h["name"], ARMOUR[int(h["armour"])]["name"]]
    if nxt > town_tier:
        return "%s wants %s, but Bellmire has no one who can make it yet." \
            % [h["name"], ARMOUR[nxt]["name"]]
    var a: Dictionary = ARMOUR[nxt]
    var aprice := haggle(h, cost_for(h, int(a["cost"])))
    if not spend(h, aprice):
        return "%s needs %d gold for %s (has %d)." \
            % [h["name"], aprice, a["name"], int(h["gold"])]
    h["armour"] = nxt
    changed.emit(user_id)
    return "%s is fitted with %s. (+%d hp)%s" % [h["name"], a["name"], int(a["hp"]), last_haggle]

func buy_potion(user_id: String, n := 1) -> String:
    var h := get_hero(user_id)
    if h.is_empty(): return "no hero"
    var pprice := haggle(h, cost_for(h, POTION_COST * n))
    if not spend(h, pprice):
        return "%s needs %d gold (has %d)." % [h["name"], pprice, int(h["gold"])]
    h["potions"] = int(h["potions"]) + n
    changed.emit(user_id)
    return "%s buys %d %s. Now carrying %d.%s" % [h["name"], n,
        "potion" if n == 1 else "potions", int(h["potions"]), last_haggle]

# Lamp oil. A flask is one floor of good light; what a hero carries is pooled
# with the rest of the party at the mouth, so the miser and the spendthrift
# descend into the same darkness.
func buy_oil(user_id: String, n := 1) -> String:
    var h := get_hero(user_id)
    if h.is_empty(): return "no hero"
    var oprice := haggle(h, cost_for(h, OIL_COST * n))
    if not spend(h, oprice):
        return "%s needs %d gold for oil (has %d)." \
            % [h["name"], oprice, int(h["gold"])]
    h["oil"] = int(h.get("oil", 0)) + n
    changed.emit(user_id)
    return "%s buys %d flask%s of oil. Now carrying %d.%s" \
        % [h["name"], n, "" if n == 1 else "s", int(h.get("oil", 0)), last_haggle]

# `prepaid` is for redemptions already paid for in channel points or bits -
# the viewer has spent something real, so the gold cost is waived.
func reroll(user_id: String, prepaid := false) -> String:
    var h := get_hero(user_id)
    if h.is_empty(): return "no hero"
    if not prepaid and not spend(h, cost_for(h, REROLL_COST)):
        return "%s needs %d gold to reroll (has %d)." \
            % [h["name"], REROLL_COST, int(h["gold"])]
    var before: Dictionary = h["stats"].duplicate()
    var a := _with_species(roll_stats(String(h["class"])), species_of(h))
    var b := _with_species(roll_stats(String(h["class"])), species_of(h))
    var best: Dictionary = a if _total(a) >= _total(b) else b
    # You gamble the GOLD, never the character. A paid reroll that leaves a
    # viewer strictly worse off is a refund request, not a highlight - so a
    # bad throw costs the fee and nothing else.
    if _total(best) <= _total(before):
        changed.emit(user_id)
        return "%s rerolls and the dice are unkind (%d vs %d) - the old fate stands." \
            % [h["name"], _total(best), _total(before)]
    h["stats"] = best
    changed.emit(user_id)
    return "%s rerolls: %s  ->  %s" % [h["name"], _stat_line(before), _stat_line(h["stats"])]

func _total(s: Dictionary) -> int:
    var t := 0
    for k: String in STATS:
        t += int(s[k])
    return t

func respec(user_id: String, cls: String, prepaid := false) -> String:
    var h := get_hero(user_id)
    if h.is_empty(): return "no hero"
    cls = cls.to_lower()
    if not CLASSES.has(cls):
        return "No such calling. Try: %s" % ", ".join(CLASSES.keys())
    if cls == h["class"]:
        return "%s is already a %s." % [h["name"], cls]
    if not prepaid and not spend(h, cost_for(h, RESPEC_COST)):
        return "%s needs %d gold to retrain (has %d)." \
            % [h["name"], RESPEC_COST, int(h["gold"])]
    var was: String = h["class"]
    h["class"] = cls
    # a weapon kind of the old calling's family does not carry over (L3 kinds)
    if h.has("wkind") and not Gear.kinds_of(String(CLASSES[cls]["family"])).has(String(h["wkind"])):
        h.erase("wkind")
    changed.emit(user_id)
    return "%s abandons the %s's path and takes up the %s. %s" \
        % [h["name"], was, cls, CLASSES[cls]["blurb"]]

# -------------------------------------------------------------------- record
func award(user_id: String, gold: int, xp: int, kills := 0, floor_no := 0) -> void:
    var h := get_hero(user_id)
    if h.is_empty(): return
    h["gold"] = int(h["gold"]) + gold
    h["xp"] = int(h["xp"]) + xp
    h["kills"] = int(h["kills"]) + kills
    if floor_no > int(h["deepest"]):
        h["deepest"] = floor_no
    var rank_was := rank_of(h)
    while int(h["xp"]) >= _xp_needed(int(h["level"])):
        h["xp"] = int(h["xp"]) - _xp_needed(int(h["level"]))
        h["level"] = int(h["level"]) + 1
        var s: String = STATS[rng.randi() % STATS.size()]
        h["stats"][s] = int(h["stats"][s]) + 1
        announced.emit("%s reaches level %d (+1 %s)." % [h["name"], int(h["level"]), s],
            Color(0.95, 0.86, 0.45))
    # A promotion is a story beat, so it is said out loud like a level-up.
    var rank_now := rank_of(h)
    if rank_now != rank_was:
        announced.emit("%s is raised to %s of the Bellmire Guild."
            % [h["name"], rank_now], Color(0.98, 0.90, 0.52))
    changed.emit(user_id)

func _xp_needed(level: int) -> int:
    return 40 + level * 30

func kill(user_id: String, killed_by: String, floor_no: int, day: int) -> String:
    var h := get_hero(user_id)
    if h.is_empty() or not bool(h["alive"]):
        return ""
    h["alive"] = false
    Sfx.sting()
    fallen.push_front({
        "name": h["name"], "class": h["class"], "level": int(h["level"]),
        "deepest": max(int(h["deepest"]), floor_no), "kills": int(h["kills"]),
        "killed_by": killed_by, "day": day,
    })
    if fallen.size() > 200:
        fallen.resize(200)
    changed.emit(user_id)
    # A hero cut down in the town by a raider was being announced as "falls on
    # floor 0", because this line assumed every death happens underground.
    # Raids account for 3-5 deaths per ten days, so that nonsense was on screen
    # regularly. Above ground gets its own wording.
    if floor_no <= 0:
        return "%s the %s is cut down defending Bellmire by %s. Level %d, %d kills. !reroll to rise again." \
            % [h["name"], h["class"], killed_by, int(h["level"]), int(h["kills"])]
    return "%s the %s falls on floor %d to %s. Level %d, %d kills. !reroll to rise again." \
        % [h["name"], h["class"], floor_no, killed_by, int(h["level"]), int(h["kills"])]

# --------------------------------------------------------------- leaderboard
# ------------------------------------------------------- the guild roll
# The Bellmire Guild keeps a roll, and standing on it is EARNED - how deep a
# hero has been, what they have put down, and how long they have survived
# doing it. Gold buys gear; it does not buy rank. A viewer who delves badly
# but gets lucky with a chest should not outrank one who has walked floor ten.
# Rank is not a label. A guild that gives nothing for climbing it is just a
# scoreboard, so each rung buys something real:
#   off    - the guild's rate at the forge and the chandler, as a fraction
#   stores - free flasks of oil drawn from guild stores at every muster
#   first  - stands ahead of lesser ranks when a party musters
const RANKS := [
    {"title": "Unproven", "at": 0, "off": 0.00, "stores": 0, "first": false},
    {"title": "Novice", "at": 8, "off": 0.10, "stores": 0, "first": false},
    {"title": "Delver", "at": 22, "off": 0.10, "stores": 1, "first": true},
    {"title": "Journeyman", "at": 46, "off": 0.15, "stores": 1, "first": true},
    {"title": "Veteran", "at": 84, "off": 0.20, "stores": 2, "first": true},
    {"title": "Master", "at": 140, "off": 0.25, "stores": 2, "first": true},
    {"title": "Grandmaster", "at": 230, "off": 0.30, "stores": 3, "first": true},
]

func standing(h: Dictionary) -> int:
    return int(h.get("deepest", 0)) * 6 + int(h.get("kills", 0)) * 2 \
         + (int(h.get("level", 1)) - 1) * 8

func rank_row(h: Dictionary) -> Dictionary:
    var sc := standing(h)
    var row: Dictionary = RANKS[0]
    for r: Dictionary in RANKS:
        if sc >= int(r["at"]):
            row = r
    return row

func rank_of(h: Dictionary) -> String:
    return String(rank_row(h)["title"])

func leaderboard(kind := "deepest", n := 10) -> Array:
    var rows := []
    for id: String in heroes:
        var h: Dictionary = heroes[id]
        if not bool(h["alive"]):
            continue          # already represented by their `fallen` entry
        rows.append({"name": h["name"], "alive": true, "rank": rank_of(h),
            "standing": standing(h),
            "deepest": int(h["deepest"]), "gold": int(h["gold"]),
            "kills": int(h["kills"]), "level": int(h["level"])})
    for f: Dictionary in fallen:
        rows.append({"name": f["name"], "alive": false, "rank": rank_of(f),
            "standing": standing(f),
            "deepest": int(f["deepest"]), "gold": 0,
            "kills": int(f["kills"]), "level": int(f["level"])})
    var key := kind if kind in ["deepest", "gold", "kills", "level", "standing"] else "standing"
    rows.sort_custom(func(a, b): return int(a[key]) > int(b[key]))
    return rows.slice(0, n)

# what this hero is holding, for Rig.equip()
func weapon_mesh(h: Dictionary) -> String:
    var t: int = int(h["weapon"])
    if t <= 0:
        return ""
    # L3: a chosen kind (!forge <kind>) has its own mesh per tier
    var kind := String(h.get("wkind", CLASSES[h["class"]].get("kind", "")))
    if Gear.KINDS.has(kind):
        return Gear.kind_path(kind, t)
    var fam: String = String(CLASSES[h["class"]]["family"])
    var list: Array = FAMILIES[fam]
    return String(list[clampi(t - 1, 0, list.size() - 1)])

func offhand_mesh(h: Dictionary) -> String:
    return String(CLASSES[h["class"]]["offhand"])

# most offhands are held; a quiver is worn
func offhand_bone(h: Dictionary) -> String:
    # L3: HeroBody.refresh asks this just before Gear.rank_trim - the armour goes on there
    Gear._dressing = h
    return String(CLASSES[h["class"]].get("offhand_bone", "handslot.l"))

func weapon_look(h: Dictionary) -> Dictionary:
    var w: Dictionary = WEAPONS[clampi(int(h["weapon"]), 0, WEAPONS.size() - 1)]
    var path := weapon_mesh(h)
    return {"scale": float(w["scale"]) * Gear.hand_scale(path), "glow": float(w["glow"])}

# the full name a viewer sees: tier adjective + family noun
const FAMILY_NOUN := {"blade": "blade", "axe": "axe", "arcane": "focus", "ranged": "bow"}

func weapon_name(h: Dictionary) -> String:
    var t: int = int(h["weapon"])
    if t <= 0:
        return "bare hands"
    var kind := String(h.get("wkind", CLASSES[h["class"]].get("kind", "")))
    var noun: String = String(Gear.KINDS[kind]["noun"]) if Gear.KINDS.has(kind) else String(FAMILY_NOUN.get(String(CLASSES[h["class"]]["family"]), "weapon"))
    return "%s %s" % [WEAPONS[clampi(t, 0, WEAPONS.size() - 1)]["name"], noun]

## ---- L3: what the forge offers this hero: their family's kinds and the next tier
func forge_menu(user_id: String) -> String:
    var h := get_hero(user_id)
    if h.is_empty(): return "no hero"
    var fam := String(CLASSES[h["class"]]["family"])
    var nxt := int(h["weapon"]) + 1
    var top := mini(forged_max(WEAPONS), town_tier)
    var next := "nothing better is forged here" if nxt > top else "next: %s, %d gold" % [WEAPONS[nxt]["name"], cost_for(h, int(WEAPONS[nxt]["cost"]))]
    return "The smith works %s for a %s: %s (!forge <kind>)  |  %s." % [
        "steel", h["class"], ", ".join(Gear.kinds_of(fam)), next]

## a deep floor gives up gear: one tier above what the finder carries (the
## forge's best at most), and from floor 10 scarforged steel or scarwoven mail
## for one already at the top. Returns the Chronicle line, or "".
func find_gear(user_id: String, floor_no: int, roll: float, lord := false) -> String:
    var h := get_hero(user_id)
    if h.is_empty() or floor_no < 6:
        return ""
    var chance := 0.05 + 0.01 * float(floor_no) + (0.2 if lord else 0.0)
    if roll >= chance:
        return ""
    var arm := int(h["armour"]) < int(h["weapon"])
    var key := "armour" if arm else "weapon"
    var list: Array = ARMOUR if arm else WEAPONS
    var cur := int(h[key])
    var top := forged_max(list)
    var nxt := cur + 1
    if cur >= top:
        if floor_no < 10 or nxt >= list.size():
            return ""
    h[key] = nxt
    if not arm:
        var kinds := Gear.kinds_of(String(CLASSES[h["class"]]["family"]))
        if not kinds.is_empty():
            h["wkind"] = kinds[randi() % kinds.size()]
    changed.emit(user_id)
    var what := weapon_name(h) if not arm else String(ARMOUR[nxt]["name"])
    return "%s prises %s %s from the dead on floor %d." % [h["name"], _an(what), what, floor_no] if not arm \
        else "%s strips a set of %s off the dead on floor %d." % [h["name"], what, floor_no]

func _stat_line(s: Dictionary) -> String:
    var parts := []
    for k: String in STATS:
        var v: int = int(s.get(k, 10))
        parts.append("%s %d(%s)" % [k.to_upper(), v, sign_str(modifier(v))])
    return " ".join(parts)

func describe(user_id: String) -> String:
    var h := get_hero(user_id)
    if h.is_empty():
        return "No hero yet - type !enlist to join the valley."
    if not bool(h["alive"]):
        return "%s is dead. !reroll to raise a new hero." % h["name"]
    # Laid out like the sheet, but kept to chat lines so it costs no screen.
    return ("%s the %s, %s, level %d  |  AC %d  HP %d  prof %s  to-hit %s  |  %s" +
            "  |  saves %s  |  %s, %s  |  %d potions, %d oil, %d gold" +
            "  |  deepest floor %d, %d kills") \
        % [h["name"], "%s %s" % [species_of(h), h["class"]], rank_of(h), int(h["level"]),
           armour_class(h), int(max_hp(h)), sign_str(prof(h)),
           sign_str(attack_bonus(h)), _stat_line(h["stats"]), save_line(h),
           "%s (%s)" % [weapon_name(h), dice_str(h)], ARMOUR[int(h["armour"])]["name"],
           int(h["potions"]), int(h.get("oil", 0)), int(h["gold"]),
           int(h["deepest"]), int(h["kills"])]

# ---------------------------------------------------------------- persistence
# ------------------------------------------------------------------- boons
# A permanent +1 to ONE ability for every living hero. This is safe precisely
# BECAUSE it is universal - nobody gains relative advantage, so a big cheer
# raises the whole valley without buying anyone a place on the leaderboard.
func boon_ability() -> String:
    var stat: String = STATS[rng.randi() % STATS.size()]
    for id: String in heroes:
        var h: Dictionary = heroes[id]
        if bool(h.get("alive", false)):
            h["stats"][stat] = int(h["stats"][stat]) + 1
    return String(STAT_FULL[stat])

func save_all() -> void:
    var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f == null:
        push_warning("roster: cannot write %s" % SAVE_PATH)
        return
    f.store_string(JSON.stringify({"heroes": heroes, "fallen": fallen,
        "patrons": patrons}, "  "))
    f.close()

func load_all() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if f == null:
        return
    var raw: Variant = JSON.parse_string(f.get_as_text())
    f.close()
    if typeof(raw) != TYPE_DICTIONARY:
        push_warning("roster: save file unreadable, starting fresh")
        return
    var d: Dictionary = raw
    heroes = d.get("heroes", {})
    # Saves written before a field existed simply lack it. Fill the gaps once,
    # here, rather than scattering .get() defaults through every call site.
    for h: Dictionary in heroes.values():
        if not h.has("oil"):
            h["oil"] = 2
    fallen = d.get("fallen", [])
    patrons = d.get("patrons", {})


# --------------------------------------------------------------- generosity
# Everything bought with real money is a gift to the WHOLE valley, so what we
# record is how much someone has given, never how strong it made them. This
# ledger is a thank-you board; it must never be merged with the deepest-floor
# leaderboard, or giving turns into buying rank.
func record_gift(user_id: String, display: String, worth: int) -> void:
    if user_id == "":
        return
    var row: Dictionary = patrons.get(user_id, {"name": display, "given": 0})
    row["name"] = display if display != "" else String(row["name"])
    row["given"] = int(row["given"]) + worth
    patrons[user_id] = row

func patron_board(n := 5) -> Array:
    var rows := []
    for id: String in patrons:
        rows.append({"name": patrons[id]["name"], "given": int(patrons[id]["given"])})
    rows.sort_custom(func(a, b): return int(a["given"]) > int(b["given"]))
    return rows.slice(0, n)

# A boon reaches every living hero on the roster. `gold` and `potions` are
# per-head, not a pot to be divided - the point is that everyone feels it.
func grant_all(gold: int, potions: int) -> int:
    var touched := 0
    for id: String in heroes:
        var h: Dictionary = heroes[id]
        if not bool(h.get("alive", false)):
            continue
        h["gold"] = int(h["gold"]) + gold
        h["potions"] = int(h["potions"]) + potions
        touched += 1
    return touched
