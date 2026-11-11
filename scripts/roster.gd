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
const CLASSES := {
    "knight":    {"hp": 72, "atk": 11, "spd": 4.2, "model": "Knight.glb",
                  "family": "blade", "offhand": "shield_square.gltf",
                  "primary": "str", "blurb": "Stout, shielded. Hard to kill, slow to finish a fight."},
    "warden":    {"hp": 80, "atk": 10, "spd": 3.9, "model": "Knight.glb",
                  "family": "axe", "offhand": "shield_round_barbarian.gltf",
                  "primary": "str", "blurb": "The wall the dungeon breaks on."},
    "barbarian": {"hp": 88, "atk": 13, "spd": 4.4, "model": "Barbarian.glb",
                  "family": "axe", "offhand": "",
                  "primary": "str", "blurb": "The most meat. Swings heavy, guards nothing."},
    "rogue":     {"hp": 48, "atk": 15, "spd": 5.4, "model": "Rogue.glb",
                  "family": "blade", "offhand": "",
                  "primary": "dex", "blurb": "Fast and sharp, but folds under a real hit."},
    "duelist":   {"hp": 52, "atk": 16, "spd": 5.1, "model": "Rogue.glb",
                  "family": "blade", "offhand": "dagger.gltf",
                  "primary": "dex", "blurb": "Two blades, no patience."},
    "ranger":    {"hp": 55, "atk": 14, "spd": 4.9, "model": "Rogue_Hooded.glb",
                  "family": "ranged", "offhand": "quiver.gltf", "offhand_bone": "chest",
                  "primary": "dex", "blurb": "Kills things before they arrive."},
    "mage":      {"hp": 42, "atk": 19, "spd": 4.0, "model": "Mage.glb",
                  "family": "arcane", "offhand": "",
                  "primary": "int", "blurb": "Hits hardest. Dies hardest."},
    "sage":      {"hp": 50, "atk": 9, "spd": 4.0, "model": "Mage.glb",
                  "family": "arcane", "offhand": "spellbook_open.gltf",
                  "primary": "wis",
                  "blurb": "Mends the party faster than the dark can open it."},
    "cleric":    {"hp": 60, "atk": 12, "spd": 4.1, "model": "Mage.glb",
                  "family": "arcane", "offhand": "shield_round.gltf",
                  "primary": "wis", "blurb": "Keeps the party upright longer than it deserves."},
}

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
    {"name": "bare hands", "cost": 0,    "atk": 0,  "scale": 0.0, "glow": 0.0},
    {"name": "plain steel", "cost": 60,  "atk": 4,  "scale": 1.0, "glow": 0.0},
    {"name": "fine steel",  "cost": 160, "atk": 9,  "scale": 1.05, "glow": 0.0},
    {"name": "runed",       "cost": 420, "atk": 16, "scale": 1.12, "glow": 0.5},
    {"name": "dragontooth", "cost": 1100,"atk": 26, "scale": 1.25, "glow": 1.0},
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
]
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
func fresh(user_id: String, display: String, cls := "") -> Dictionary:
    if cls == "" or not CLASSES.has(cls):
        cls = CLASSES.keys()[rng.randi() % CLASSES.size()]
    var h := {
        "id": user_id, "name": display, "class": cls,
        "stats": roll_stats(cls), "weapon": 0, "armour": 0, "potions": 1,
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
    if cls not in ["sage", "cleric"]:
        return 0.0
    var base: float = 11.0 if cls == "sage" else 7.0
    return base + float(mod(h, "wis")) * 2.5

# CHA haggles the shopkeeper down, to a floor of 70%
func price_mult(h: Dictionary) -> float:
    return clampf(1.0 - float(mod(h, "cha")) * 0.05, 0.70, 1.25)

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

func buy_weapon(user_id: String) -> String:
    var h := get_hero(user_id)
    if h.is_empty(): return "no hero"
    var nxt: int = int(h["weapon"]) + 1
    if nxt >= WEAPONS.size():
        return "%s already carries a %s - nothing better is forged here." \
            % [h["name"], WEAPONS[-1]["name"]]
    if nxt > town_tier:
        return "%s wants %s, but no smith in Bellmire can forge it yet." \
            % [h["name"], WEAPONS[nxt]["name"]]
    var w: Dictionary = WEAPONS[nxt]
    var peek := h.duplicate(true)
    peek["weapon"] = nxt
    var label := weapon_name(peek)
    if not spend(h, cost_for(h, int(w["cost"]))):
        return "%s needs %d gold for %s %s (has %d)." \
            % [h["name"], cost_for(h, int(w["cost"])), _an(label), label, int(h["gold"])]
    h["weapon"] = nxt
    changed.emit(user_id)
    return "%s takes up %s %s. (+%d atk)" % [h["name"], _an(label), label, int(w["atk"])]

func _an(word: String) -> String:
    return "an" if word.substr(0, 1).to_lower() in ["a", "e", "i", "o", "u"] else "a"

func buy_armour(user_id: String) -> String:
    var h := get_hero(user_id)
    if h.is_empty(): return "no hero"
    var nxt: int = int(h["armour"]) + 1
    if nxt >= ARMOUR.size():
        return "%s is already in %s." % [h["name"], ARMOUR[-1]["name"]]
    if nxt > town_tier:
        return "%s wants %s, but Bellmire has no one who can make it yet." \
            % [h["name"], ARMOUR[nxt]["name"]]
    var a: Dictionary = ARMOUR[nxt]
    if not spend(h, cost_for(h, int(a["cost"]))):
        return "%s needs %d gold for %s (has %d)." \
            % [h["name"], cost_for(h, int(a["cost"])), a["name"], int(h["gold"])]
    h["armour"] = nxt
    changed.emit(user_id)
    return "%s is fitted with %s. (+%d hp)" % [h["name"], a["name"], int(a["hp"])]

func buy_potion(user_id: String, n := 1) -> String:
    var h := get_hero(user_id)
    if h.is_empty(): return "no hero"
    if not spend(h, cost_for(h, POTION_COST * n)):
        return "%s needs %d gold (has %d)." % [h["name"], cost_for(h, POTION_COST * n), int(h["gold"])]
    h["potions"] = int(h["potions"]) + n
    changed.emit(user_id)
    return "%s buys %d %s. Now carrying %d." % [h["name"], n,
        "potion" if n == 1 else "potions", int(h["potions"])]

# Lamp oil. A flask is one floor of good light; what a hero carries is pooled
# with the rest of the party at the mouth, so the miser and the spendthrift
# descend into the same darkness.
func buy_oil(user_id: String, n := 1) -> String:
    var h := get_hero(user_id)
    if h.is_empty(): return "no hero"
    if not spend(h, cost_for(h, OIL_COST * n)):
        return "%s needs %d gold for oil (has %d)." \
            % [h["name"], cost_for(h, OIL_COST * n), int(h["gold"])]
    h["oil"] = int(h.get("oil", 0)) + n
    changed.emit(user_id)
    return "%s buys %d flask%s of oil. Now carrying %d." \
        % [h["name"], n, "" if n == 1 else "s", int(h.get("oil", 0))]

# `prepaid` is for redemptions already paid for in channel points or bits -
# the viewer has spent something real, so the gold cost is waived.
func reroll(user_id: String, prepaid := false) -> String:
    var h := get_hero(user_id)
    if h.is_empty(): return "no hero"
    if not prepaid and not spend(h, cost_for(h, REROLL_COST)):
        return "%s needs %d gold to reroll (has %d)." \
            % [h["name"], REROLL_COST, int(h["gold"])]
    var before: Dictionary = h["stats"].duplicate()
    var a := roll_stats(String(h["class"]))
    var b := roll_stats(String(h["class"]))
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
    var fam: String = String(CLASSES[h["class"]]["family"])
    var list: Array = FAMILIES[fam]
    return String(list[clampi(t - 1, 0, list.size() - 1)])

func offhand_mesh(h: Dictionary) -> String:
    return String(CLASSES[h["class"]]["offhand"])

# most offhands are held; a quiver is worn
func offhand_bone(h: Dictionary) -> String:
    return String(CLASSES[h["class"]].get("offhand_bone", "handslot.l"))

func weapon_look(h: Dictionary) -> Dictionary:
    var w: Dictionary = WEAPONS[int(h["weapon"])]
    return {"scale": float(w["scale"]), "glow": float(w["glow"])}

# the full name a viewer sees: tier adjective + family noun
const FAMILY_NOUN := {"blade": "blade", "axe": "axe", "arcane": "focus", "ranged": "bow"}

func weapon_name(h: Dictionary) -> String:
    var t: int = int(h["weapon"])
    if t <= 0:
        return "bare hands"
    return "%s %s" % [WEAPONS[t]["name"],
        FAMILY_NOUN.get(String(CLASSES[h["class"]]["family"]), "weapon")]

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
        % [h["name"], h["class"], rank_of(h), int(h["level"]),
           armour_class(h), int(max_hp(h)), sign_str(prof(h)),
           sign_str(attack_bonus(h)), _stat_line(h["stats"]), save_line(h),
           weapon_name(h), ARMOUR[int(h["armour"])]["name"],
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
