class_name Notables
extends Node

## D6: Bellmire's own people - named, each with a look, a day and a voice.
## LORE FIRST: the original town's roster (town.gd ROSTER) already had the chief
## in his hall, the smith, the chapel healer, the innkeeper and the market's
## merchants, and its names were FIRST x LAST ("Corvin Fenwick"). Those bodies
## are PROMOTED here (same role, same work, so the economy is untouched) and
## given a fixed name, a title and a day. The crier, the priest, the bard, the
## pedlar with her cart, two children, the beggar and the drunk are HD street
## life, named from the same lists and spoken in the old chronicle's voice.
##
## A day is a list of slots [from hour, to hour, place, chronicle tag]. When the
## town clock enters a slot the person is sent there (Townsfolk.stops, so every
## step still goes by the navmesh and through doors - D1). Now and then one of
## them gets a line in the Chronicle; the crier reads the Chronicle aloud.

const ADV_KIT := "res://addons/kaykit_character_pack_adventures/Assets/gltf/"
const GEAR_KIT := "res://assets/gear/"

## Bellmire is wide (the square to the tavern is ~120 m, a walk of half a town
## day), so each person's day keeps to one quarter: they live by their work
## ("near"), and a slot is long enough to walk to.
const PEOPLE := [
    {"key": "chief", "promote": "chief", "work": "hall", "home": "hall", "name": "Aldric Ashwood", "title": "Chief of Bellmire",
     "model": "Mage.glb", "tint": Color(0.86, 0.74, 1.0), "size": 1.07,
     "day": [[6, 13, "hall+in", "work"], [13, 21, "store", "market"], [21, 6, "hall+in", "night"]],
     "lines": {"work": ["%s counts the treasury twice and frowns once.", "%s signs a warrant for the watch.",
                        "%s hears a grievance about a goat."],
               "market": ["%s walks the east market and asks the price of bread.", "%s shakes hands with a delver back from the scar."]}},
    {"key": "smith", "promote": "smith", "work": "smithy", "near": "smithy", "name": "Garm Coalfoot", "title": "the Smith",
     "model": "Barbarian.glb", "tint": Color(0.98, 0.56, 0.32), "size": 1.12,
     "day": [[5, 18, "smithy", "work"], [18, 22, "armorer", "evening"], [22, 5, "home+in", "night"]],
     "act": ["Interact", "Use_Item"],
     "lines": {"work": ["%s's hammer rings from the smithy.", "%s quenches a blade and swears at it.",
                        "%s turns away a delver who wants a sword by noon."],
               "evening": ["%s argues steel with the armourer over the fence."]}},
    {"key": "healer", "promote": "healer", "work": "chapel", "near": "chapel", "name": "Ysolde of the Ford", "title": "Healer of the Chapel",
     "model": "Mage.glb", "tint": Color(0.66, 0.96, 0.86), "size": 1.0,
     "day": [[6, 11, "chapel+in", "work"], [11, 18, "rounds", "rounds"], [18, 21, "chapel", "work"], [21, 6, "home+in", "night"]],
     "lines": {"work": ["%s mends a farmhand's split thumb.", "%s boils linen at the chapel."],
               "rounds": ["%s makes her rounds with a satchel of salves.", "%s sits with a fevered child by the chapel."]}},
    {"key": "innkeeper", "promote": "innkeeper", "work": "tavern", "near": "tavern", "name": "Rolf Thatcher", "title": "Keeper of the Tavern",
     "model": "Barbarian.glb", "tint": Color(0.94, 0.80, 0.52), "size": 1.1,
     "day": [[3, 11, "store+in", "buying"], [11, 3, "tavern_work", "work"]],
     "lines": {"work": ["%s rolls a fresh cask into the tavern.", "%s waters the ale. Nobody can prove it.",
                        "%s chalks another delver's tab on the wall."],
               "buying": ["%s haggles over a sack of barley at the store."]}},
    {"key": "priest", "promote": "priest", "work": "chapel", "near": "chapel", "name": "Osric Hollow", "title": "Priest of the Chapel",
     "model": "Mage.glb", "tint": Color(0.97, 0.94, 0.80), "size": 1.03,
     "day": [[6, 10, "chapel+in", "work"], [10, 16, "chapel", "sermon"], [16, 21, "chapel+in", "work"], [21, 6, "home+in", "night"]],
     "act": ["Cheer", "Interact"],
     "lines": {"sermon": ["%s preaches on the chapel steps: the scar is a wound, not a door.", "%s blesses the delvers' boots. They will need it."],
               "work": ["%s rings the chapel bell for the fallen.", "%s lights a candle for the ones still below."]}},
    {"key": "crier", "promote": "crier", "near": "market", "name": "Cort Rivers", "title": "the Town Crier",
     "model": "Knight.glb", "tint": Color(0.96, 0.84, 0.55), "size": 1.0,
     "day": [[7, 19, "crier_spot", "cry"], [19, 7, "home+in", "night"]],
     "lines": {"cry": ["%s reads the Chronicle aloud on the square.", "%s rings his bell and clears his throat."]}},
    {"key": "bard", "role": "bard", "near": "market", "name": "Wren Bramble", "title": "the Bard",
     "model": "Rogue.glb", "tint": Color(0.96, 0.62, 0.80), "size": 0.98, "cape": Color(0.55, 0.16, 0.45),
     "kit": [[ADV_KIT + "wand.gltf", "handslot.r", "weapon", 1.0], [ADV_KIT + "spellbook_open.gltf", "handslot.l", "offhand", 1.0]],
     "act": ["Cheer", "Interact", "Use_Item"],
     "day": [[9, 16, "bard_spot", "square"], [16, 23, "apothecary", "evening"], [23, 9, "home+in", "night"]],
     "lines": {"square": ["%s sings of the delvers who came back.", "%s plays for coppers on the square and gets three."],
               "evening": ["%s sings of the ones who did not. The street goes quiet.", "%s plays a reel for the queue at the apothecary."]}},
    {"key": "pedlar", "role": "pedlar", "gear": "merchant", "near": "market", "name": "Petra Fenwick", "title": "the Pedlar",
     "model": "Rogue_Hooded.glb", "tint": Color(0.92, 0.72, 0.38), "size": 1.0, "cape": Color(0.66, 0.42, 0.14),
     "cart": true,
     "day": [[6, 20, "pedlar_spot", "market"], [20, 6, "gate", "camp"]],
     "lines": {"market": ["%s sells a lucky charm. It is not lucky.", "%s swears her salt came from the coast.",
                          "%s's cart is the busiest stall on the square."],
               "camp": ["%s camps by the south gate with her cart."]}},
    {"key": "tove", "role": "child", "home_of": "bard", "name": "Tove Bramble", "title": "the Bard's Girl",
     "model": "Rogue.glb", "tint": Color(1.0, 0.86, 0.62), "size": 0.62, "cape": Color(0.85, 0.35, 0.30), "speed": 6.2,
     "day": [[7, 19, "play", "play"], [19, 7, "home+in", "night"]],
     "lines": {"play": ["%s and the other children play delvers-and-lords round the well.", "%s is chased round the square by a hen."]}},
    {"key": "dunn", "role": "child", "near": "market", "name": "Dunn the Younger", "title": "a Boy of Bellmire",
     "model": "Rogue_Hooded.glb", "tint": Color(0.78, 0.92, 1.0), "size": 0.66, "cape": Color(0.22, 0.45, 0.70), "speed": 6.4,
     "day": [[7, 19, "play", "play"], [19, 7, "home+in", "night"]],
     "lines": {"play": ["%s dares the others to touch the scar's edge. Nobody does.", "%s swings a stick at a lord only he can see."]}},
    {"key": "beggar", "role": "beggar", "near": "chapel", "name": "Harl Quarryman", "title": "the Beggar",
     "model": "Rogue_Hooded.glb", "tint": Color(0.56, 0.52, 0.47), "size": 0.94, "cape": Color(0.32, 0.28, 0.22), "speed": 3.6,
     "kit": [[ADV_KIT + "mug_empty.gltf", "handslot.r", "weapon", 1.0]],
     "act": ["Interact", "Idle_B"],
     "day": [[6, 10, "chapel_side", "chapel"], [10, 21, "beggar_spot", "market"], [21, 6, "home+in", "night"]],
     "lines": {"market": ["%s asks the market for a copper.", "%s swears he once delved the scar. Nobody believes him."],
               "chapel": ["%s waits on the chapel steps for the priest's bread."]}},
    {"key": "drunk", "role": "drunk", "home": "tavern", "name": "Rask Stonehand", "title": "the Town Drunk",
     "model": "Barbarian.glb", "tint": Color(0.92, 0.62, 0.55), "size": 1.04, "cape": Color(0.48, 0.12, 0.10), "speed": 3.6,
     "kit": [[ADV_KIT + "mug_full.gltf", "handslot.r", "weapon", 1.0]],
     "act": ["Cheer"],
     "day": [[6, 15, "home+in", "sleep"], [15, 1, "tavern+in", "tavern"], [1, 6, "stagger", "stagger"]],
     # he sleeps it off in the straw of the tavern's back room
     "lines": {"tavern": ["%s is turned out of the tavern. Again.", "%s challenges the innkeeper to an arm-wrestle and loses."],
               "stagger": ["%s sings at the moon outside the tavern.", "%s argues with a rain barrel. The barrel wins.",
                           "%s weaves home the long way round."]}},
]

var town: Node3D
var cast: Array = []          # one Dictionary per person: {who, def, home, slot, ...}
var rng := RandomNumberGenerator.new()
var _tick := 0.0
var _line_t := 22.0
var _crier: Townsfolk = null
var _last_line := ""
var _names_t := 1.0
## test telemetry
var visits := 0
var reached := 0
var lines_said := 0
var read_aloud := 0

func setup(t: Node3D) -> void:
    town = t
    rng.seed = 6611
    var taken := {}
    for d in PEOPLE:
        var def: Dictionary = d
        var who: Townsfolk = null
        if def.has("promote"):
            for p in town.get("people"):
                if p is Townsfolk and not (p is HeroBody) and String(p.role) == String(def["promote"]) \
                        and not taken.has(p) and (p as Townsfolk).notable_title == "":
                    who = p
                    break
        var fresh := who == null
        if fresh:
            who = Townsfolk.new()
            who.role = String(def.get("role", "peasant"))
            who.town = town
        taken[who] = true
        who.model = String(def["model"])
        who.tint = def["tint"]
        who.size_k = float(def.get("size", 1.0))
        who.gear_role = String(def.get("gear", ""))
        who.gear_seed = 0
        if def.has("cape"):
            who.livery = def["cape"]
        if def.has("speed"):
            who.speed = float(def["speed"])
        who.stay = false
        who.make_notable(String(def["name"]), String(def["title"]))
        if def.has("work"):
            # the economy counts them at work by this door (Economy._at_work)
            var wd: Array = _door_of(String(def["work"]))
            who.work = wd[0]
            who.work_in = wd[1]
        var c := {"who": who, "def": def, "slot": -1, "tag": "", "goals": [], "hit": false, "gest": 0.0}
        # a home of their own (the promoted keep the one the town gave them)
        if def.has("home"):
            c["home"] = _door_of(String(def["home"]))          # the chief in his hall, the drunk at the tavern
        elif def.has("near"):
            var hp: Dictionary = _home_near(_door_of(String(def["near"]))[0])
            c["home"] = [town.call("_door", hp), town.call("_door_in", hp)]
        elif who.home != Vector3.ZERO and not fresh:
            c["home"] = [who.home, who.home_in]
        else:
            var hp2: Dictionary = town.call("_home_for", rng)
            c["home"] = [town.call("_door", hp2), town.call("_door_in", hp2)]
        who.home = c["home"][0]
        who.home_in = c["home"][1]
        if def.has("home_of"):
            for o in cast:
                if String((o["def"] as Dictionary)["key"]) == String(def["home_of"]):
                    c["home"] = o["home"]
                    who.home = c["home"][0]
                    who.home_in = c["home"][1]
        cast.append(c)
        if fresh:
            var at: Vector3 = (c["home"] as Array)[0]
            town.call("_put_folk", who, at)
        else:
            # a promoted body was dressed in _ready: dress it again in its new look
            _redress(who)
        if def.has("kit"):
            _kit(c)
        if def.has("cart"):
            who.cart = town.call("spawn_wagon", who.global_position)
        if String(def["key"]) == "crier":
            _crier = who
    _unique_names()
    call_deferred("_unique_names")      # after the garrison is raised

## the promoted were built before they were named: swap in their new body/look
func _redress(who: Townsfolk) -> void:
    if who._mdl:
        who._mdl.free()
        who._mdl = null
    var sc: PackedScene = load(Townsfolk.ADV + who.model)
    if sc == null:
        return
    who._mdl = sc.instantiate()
    who.add_child(who._mdl)
    Rig.tint(who._mdl, who.tint)
    who._anim = Rig.find(who._mdl)
    Rig.prep(who._anim)
    Rig.play(who._anim, "Idle")
    who._mdl.scale = Vector3.ONE * who.size_k
    Gear.strip_props(who._mdl)
    Gear.dress_role(who._mdl, who.gear_role if who.gear_role != "" else who.role, who.gear_seed)
    Gear.clothe(who._mdl, who.gear_role if who.gear_role != "" else who.role, who.livery, who.rank)

func _kit(c: Dictionary) -> void:
    var who: Townsfolk = c["who"]
    if who._mdl == null:
        # not built yet (fresh bodies build in _ready): try again next tick
        c["kit_due"] = true
        return
    for k in (c["def"] as Dictionary)["kit"]:
        Gear.equip(who._mdl, String(k[0]), String(k[1]), String(k[2]), float(k[3]))
    c.erase("kit_due")

## nobody else in Bellmire shares a named person's name
func _unique_names() -> void:
    var names := {}
    for c in cast:
        if is_instance_valid(c["who"]):
            names[(c["who"] as Townsfolk).person_name] = true
    for p in town.get("people"):
        if not (p is Townsfolk) or p is HeroBody or (p as Townsfolk).notable_title != "":
            continue
        var f: Townsfolk = p
        var tries := 0
        while names.has(f.person_name) and tries < 40:
            tries += 1
            var parts := f.person_name.split(" ", false, 1)
            var nf: String = ["Bran", "Edda", "Mira", "Talen", "Hilda", "Petra", "Nessa", "Sable", "Ingrid", "Maela"][rng.randi() % 10]
            f.person_name = nf + " " + (parts[1] if parts.size() > 1 else "Rivers")
            if f._tag:
                f._tag.text = f.person_name

## ---------------------------------------------------------------- places
func _door_of(place: String) -> Array:
    match place:
        "hall":
            return town.call("_lm_door", "lm_hall")
        "chapel":
            return town.call("_lm_door", "lm_chapel")
        "tavern":
            return town.call("_shop_door", "tavern")
        "store":
            return town.call("_shop_door", "store")
        "armorer":
            return town.call("_shop_door", "armorer")
        "apothecary":
            return town.call("_shop_door", "apothecary")
        "market":
            return [town.get("_market_pos"), Vector3.ZERO]
        "smithy":
            var d: Array = town.call("_shop_door", "blacksmith")
            if (d[0] as Vector3) == (town.get("_market_pos") as Vector3):
                d = town.call("_lm_door", "lm_workshop")
            return d
    return [town.get("_market_pos"), Vector3.ZERO]

func _spot(off: Vector3) -> Vector3:
    return _ground((town.get("_market_pos") as Vector3) + off)

## a standing place on open ground near p. The navmesh's nearest point when the
## map answers sensibly; early on (or when it answers the origin) the town's own
## push-out of solids - a wrong answer stacked the square's people on one spot.
func _ground(p: Vector3) -> Vector3:
    var q: Vector3 = town.call("_snap", p)
    if Vector2(q.x - p.x, q.z - p.z).length() > 3.0:
        q = town.call("keep_walkable", p)
    return Vector3(q.x, 0.0, q.z)

## the gate nearest the square, a little inside it (the carters' turning point)
func _gate() -> Vector3:
    var mp: Vector3 = town.get("_market_pos")
    var best := Vector3.INF
    for g in (town.get("_wall_info") as Dictionary).get("gates", []):
        var gv: Vector3 = g
        var q := gv - Vector3(gv.x, 0, gv.z).normalized() * 10.0
        if best == Vector3.INF or q.distance_to(mp) < best.distance_to(mp):
            best = q
    if best == Vector3.INF:
        return _spot(Vector3(-20, 0, 0))
    return town.call("keep_walkable", best)

## a house a named person can live in, the nearest free one to their work
var _homes_taken := {}

func _home_near(at: Vector3) -> Dictionary:
    var cands: Array = []
    for pl in town.get("plots"):
        if pl.has("back") or pl.has("shop") or pl.has("landmark") or not pl.has("door") \
                or pl.get("unbuilt", false) or pl.has("special") or _homes_taken.has(pl["door"]):
            continue
        cands.append([(pl["door"] as Vector3).distance_to(at), pl])
    cands.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
    # a door the streets actually reach (Townsfolk waits outside one they do not)
    var from: Vector3 = town.get("_market_pos")
    for i in range(mini(cands.size(), 10)):
        var pl: Dictionary = cands[i][1]
        var dv: Vector3 = pl["door"]
        var r: Array = town.call("route", from, dv)
        var end: Vector3 = r.back() if not r.is_empty() else from
        if Vector2(end.x - dv.x, end.z - dv.z).length() <= 0.9:
            _homes_taken[dv] = true
            return pl
    if not cands.is_empty():
        _homes_taken[cands[0][1]["door"]] = true
        return cands[0][1]
    return town.call("_home_for", rng)

## somewhere to stand within r of p, on walkable ground
func _near(p: Vector3, r: float) -> Vector3:
    var a := rng.randf() * TAU
    return town.call("keep_walkable", p + Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(2.0, r))

func _stops(place: String, c: Dictionary) -> Array:
    var home: Array = c["home"]
    if place.ends_with("+in"):
        var base := place.trim_suffix("+in")
        if base == "home":
            return [[home[0], home[1], 999.0]]
        var d: Array = _door_of(base)
        return [[d[0], d[1], 999.0]]
    match place:
        "hall", "chapel", "tavern", "store", "armorer", "apothecary":
            var d0: Array = _door_of(place)
            return [[_near(d0[0], 3.0) if place != "chapel" else d0[0], Vector3.ZERO, 999.0]]
        "chapel_side":
            var dc: Array = _door_of("chapel")
            return [[town.call("keep_walkable", (dc[0] as Vector3) + Vector3(2.4, 0, 0.8)), Vector3.ZERO, 999.0]]
        "smithy":
            var d: Array = _door_of("smithy")
            return [[d[0], Vector3.ZERO, 22.0], [d[0], d[1], 26.0]]
        "tavern_work":
            var d: Array = _door_of("tavern")
            return [[d[0], d[1], 30.0], [d[0], Vector3.ZERO, 10.0]]
        "tavern_door":
            var d: Array = _door_of("tavern")
            var dv: Vector3 = d[0]
            var side := Vector3(2.2, 0, 0) if String((c["def"] as Dictionary)["key"]) == "bard" else Vector3(-2.2, 0, 1.0)
            return [[_ground(dv + side), Vector3.ZERO, 999.0]]
        "market":
            var out: Array = []
            for i in range(3):
                out.append([town.call("_near_market", rng, 9.0), Vector3.ZERO, rng.randf_range(6.0, 12.0)])
            return out
        "rounds":
            var out: Array = []
            var ch: Vector3 = _door_of("chapel")[0]
            var near: Array = []
            for pl in town.get("plots"):
                if pl.has("door") and not pl.has("landmark") and (pl["door"] as Vector3).distance_to(ch) < 45.0:
                    near.append(pl["door"])
            for i in range(3):
                out.append([near[rng.randi() % near.size()] if not near.is_empty() else _near(ch, 20.0), Vector3.ZERO, 8.0])
            out.append([ch, Vector3.ZERO, 6.0])
            return out
        "sermon":
            return [[_spot(Vector3(3.5, 0, -3.5)), Vector3.ZERO, 999.0]]
        "crier_spot":
            return [[_spot(Vector3(0, 0, 4.2)), Vector3.ZERO, 999.0]]
        "bard_spot":
            return [[_spot(Vector3(-4.5, 0, 3.0)), Vector3.ZERO, 999.0]]
        "beggar_spot":
            return [[_spot(Vector3(6.0, 0, -5.0)), Vector3.ZERO, 999.0]]
        "pedlar_spot":
            return [[_spot(Vector3(-11.0, 0, -4.0)), Vector3.ZERO, 999.0]]
        "gate":
            return [[_gate(), Vector3.ZERO, 999.0]]
        "play":
            var out: Array = []
            for i in range(6):
                out.append([town.call("_near_market", rng, 14.0), Vector3.ZERO, rng.randf_range(1.0, 4.0)])
            return out
        "stagger":
            var out: Array = []
            var tv: Vector3 = _door_of("tavern")[0]
            for i in range(4):
                out.append([_near(tv, 16.0), Vector3.ZERO, rng.randf_range(2.0, 5.0)])
            out.append([home[0], home[1], 999.0])
            return out
    return [[home[0], home[1], 999.0]]

## ---------------------------------------------------------------- days
static func slot_at(day: Array, h: float) -> int:
    for i in range(day.size()):
        var a := float(day[i][0])
        var b := float(day[i][1])
        if (a < b and h >= a and h < b) or (a > b and (h >= a or h < b)):
            return i
    return day.size() - 1

func _apply(c: Dictionary, i: int) -> void:
    var who: Townsfolk = c["who"]
    if int(c["slot"]) >= 0:
        visits += 1
        if bool(c["hit"]):
            reached += 1
    var sl: Array = (c["def"] as Dictionary)["day"][i]
    who.stay = false
    who.leader = null
    who.stops = _stops(String(sl[2]), c)
    who._stop_i = 0
    who._route = []
    who._wait = 0.0
    c["slot"] = i
    c["tag"] = String(sl[3])
    c["goals"] = who.stops.map(func(s: Array) -> Vector3: return s[0])
    c["hit"] = false
    who.sway = 0.42 if c["tag"] == "stagger" else (0.12 if String((c["def"] as Dictionary)["key"]) == "drunk" else 0.04)
    if who == _crier:
        who.shout_lines = _news() if c["tag"] == "cry" else []

func _process(delta: float) -> void:
    var eco = town.get("economy") if town else null
    if eco == null:
        return
    _tick -= delta
    if _tick > 0.0:
        return
    _tick = 0.25
    var raids = town.get("raids")
    var raid_on: bool = raids != null and bool(raids.get("_live"))
    var h: float = eco.hour()
    for c in cast:
        # D7: a notable killed in a raid is freed - test before typing it (a
        # typed assign of a freed body stopped this whole pass every tick)
        if not is_instance_valid(c["who"]):
            continue
        var who: Townsfolk = c["who"]
        if c.has("kit_due"):
            _kit(c)
        var i := slot_at((c["def"] as Dictionary)["day"], h)
        if i != int(c["slot"]) and not raid_on:
            _apply(c, i)
        if not bool(c["hit"]):
            if who.inside:
                c["hit"] = true
            else:
                for g in c["goals"]:
                    var gv: Vector3 = g
                    if Vector2(who.global_position.x - gv.x, who.global_position.z - gv.z).length() < 2.5:
                        c["hit"] = true
                        break
        _gesture(c, 0.25)
    if is_instance_valid(_crier) and not _crier.shout_lines.is_empty():
        _crier.shout_lines = _news()
    _names_t -= 0.25
    if _names_t <= 0.0:
        _names_t = 5.0
        _unique_names()          # settlers and the garrison arrive later
    _line_t -= 0.25
    if _line_t <= 0.0:
        _line_t = rng.randf_range(28.0, 55.0)
        _say()

## performers and the posted act while they stand at their spot
func _gesture(c: Dictionary, dt: float) -> void:
    var def: Dictionary = c["def"]
    if not def.has("act"):
        return
    var who: Townsfolk = c["who"]
    if who.inside or not who._route.is_empty() or who._anim == null:
        return
    c["gest"] = float(c["gest"]) - dt
    if float(c["gest"]) > 0.0:
        return
    c["gest"] = rng.randf_range(4.0, 9.0)
    var acts: Array = def["act"]
    var a: String = acts[rng.randi() % acts.size()]
    if who._anim.has_animation(a):
        Rig.play(who._anim, a)
        var wid := who.get_instance_id()     # D8: never capture a node that may be freed first
        get_tree().create_timer(minf(who._anim.get_animation(a).length, 3.0)).timeout.connect(func() -> void:
            var w = instance_from_id(wid)
            if w != null and is_instance_valid(w) and w._route.is_empty():
                Rig.play(w._anim, "Idle"))

## ---------------------------------------------------------------- voices
func _say() -> void:
    var feed: Array = town.get("feed")
    var pool: Array = []
    for c in cast:
        var lines: Dictionary = (c["def"] as Dictionary)["lines"]
        if lines.has(c["tag"]) and is_instance_valid(c["who"]):
            pool.append(c)
    if pool.is_empty():
        return
    var c: Dictionary = pool[rng.randi() % pool.size()]
    var ls: Array = (c["def"] as Dictionary)["lines"][c["tag"]]
    var line: String = String(ls[rng.randi() % ls.size()]) % (c["who"] as Townsfolk).person_name
    if line == _last_line:
        return
    _last_line = line
    feed.append(line)
    lines_said += 1

## the crier reads the Chronicle aloud: the latest news that is not his own
const CALLS := ["MEASURE THE GRAIN. COUNT THE FLASKS. KEEP THE DOOR.",
    "The Guild is hiring! Delvers wanted at the north gate!",
    "By order of the Chief: no fishing off the bridge!"]

func _news() -> Array:
    var feed: Array = town.get("feed")
    var out: Array = []
    var i := feed.size() - 1
    while i >= 0 and out.size() < 3:
        var l := String(feed[i])
        if not l.begins_with("Cort Rivers") and not l.begins_with("Day ") and l.length() < 110:
            out.append("Hear ye! " + l)
        i -= 1
    read_aloud = out.size()
    if out.is_empty():
        return CALLS.duplicate()
    out.append(CALLS[rng.randi() % CALLS.size()])
    return out

func by_key(k: String) -> Townsfolk:
    for c in cast:
        if String((c["def"] as Dictionary)["key"]) == k:
            return c["who"] if is_instance_valid(c["who"]) else null
    return null
