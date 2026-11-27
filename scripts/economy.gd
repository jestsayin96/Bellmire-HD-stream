extends Node
class_name Economy
## The valley's stock - ported from the old sim.gd / villager._produce (the
## read-only original is the rulebook; numbers are its numbers).
## Every working villager produces on a 3.5-6.5 s beat; the smith turns ore and
## wood into gear, the healer turns food into potions, miners dig ore and
## stone. Delves bring ore, stone, salvaged gear and potions home, and a party
## setting out draws half a set of gear per hero from the rack (+2 to every
## blow) - or goes without and the town notes the want.

const GOODS := ["food", "wood", "stone", "ore", "gear", "potion"]
const BASE_PRICE := {"food": 4.0, "wood": 5.0, "stone": 7.0,
                     "ore": 11.0, "gear": 38.0, "potion": 26.0}
var stock := {"food": 60.0, "wood": 40.0, "stone": 25.0,
              "ore": 18.0, "gear": 6.0, "potion": 5.0}
var demand := {}
var treasury := 400
var town: Node3D
var _beat := {}            # townsfolk -> seconds to next produce
var _chatter := 15.0
signal changed

# ---- D34 natural disasters -------------------------------------------------
# The words (begin / during / pass + alt variants) are the content writer's,
# in data/lore_lines.json "disasters"; the COST of each is a mechanic and lives
# here, charged against the town's own stock, treasury and renown. Disasters are
# OCCASIONAL and gated on town size (a four-hut Crossing is never struck by a
# volcano), one at a time, and they leave a mark the stream can read.
const DIS_MIN_LEVEL := 2          # nothing before the town is more than a founding
const DIS_MIN_DAY := 6            # and not in the first days
const DIS_DAYS := 2.5             # how long one lingers, in in-game days
const DIS_COOL_DAYS := 7.0        # mean quiet span between disasters, jittered
const DIS_DURING_GAP := 24.0      # seconds between "during" Chronicle lines
# frac_* are fractions of CURRENT stock lost at onset (scale with the town, never
# over-draw); gold is a flat treasury hit, renown a flat standing hit. workk damps
# production while it lasts; no_growth halts hiring/settling; no_cast / trade_frozen
# are exposed for spells / trade to honour. on_pass_gold is a rebuild cost (<0) or a
# windfall (>0) applied when it ends.
const DIS_SPECS := {
    "volcano":    {"food": 0.45, "gold": 120, "renown": 1, "workk": 0.6, "on_pass_gold": -60},
    "fire":       {"wood": 0.6, "gear": 0.5, "gold": 90, "workk": 0.5, "on_pass_gold": -80},
    "drought":    {"food": 0.6, "renown": 1, "workk": 0.5},
    "famine":     {"food": 0.5, "renown": 2, "no_growth": true},
    "sickness":   {"renown": 2, "workk": 0.35, "trade_frozen": true, "no_growth": true},
    "hurricane":  {"wood": 0.5, "food": 0.3, "gold": 80, "workk": 0.6, "on_pass_gold": -60},
    "tornado":    {"wood": 0.45, "stone": 0.3, "gold": 70, "workk": 0.7},
    "earthquake": {"stone": 0.55, "wood": 0.3, "gold": 110, "renown": 1, "workk": 0.6, "on_pass_gold": -70},
    "meteor":     {"food": 0.3, "wood": 0.3, "workk": 0.7, "on_pass_gold": 260},
    "scarstorm":  {"renown": 1, "workk": 0.6, "no_cast": true},
    "flood":      {"food": 0.35, "wood": 0.3, "gold": 60, "workk": 0.6, "trade_frozen": true},
    "blight":     {"food": 0.7, "potion": 0.4, "no_growth": true},
    "coldsnap":   {"food": 0.4, "wood": 0.4, "workk": 0.3, "no_growth": true},
}
var _dis_lore := {}
var _dis_lore_loaded := false
var _dis_active := ""
var _dis_t := 0.0
var _dis_during_t := 0.0
var _dis_cool := DIS_COOL_DAYS * DAY_SECONDS   # a quiet spell before the first
var dis_work_k := 1.0             # production multiplier while a disaster lasts
var _dis_no_growth := false
var _dis_no_cast := false
var _dis_trade_frozen := false
var disasters_survived := 0

## ---- town level (old sim.gd). Earned by holding people and being worth
## talking about; gold left out on purpose. Checked once a day (90 s), and a
## town can fall back down. Raids are gated on it (from level 3).
const DAY_SECONDS := 90.0
## D32: TWELVE earned tiers. The town was levelling far too fast - it FOUNDED at
## level 3 of 6 (score ~153) and auto-climbed to 5 on settlers alone. Names and
## crier lines are the content writer's (data/lore_lines.json "growth_tiers").
## The curve: founding sits at a HAMLET (tier 2); the first handful of tiers come
## from settlers filling the housing (the pop-driven ceiling is ~pop_cap*3, here
## ~315); every tier above that is renown-gated, so reaching a CITY is a long
## delving grind, not a free gift. town_name keeps the lowercase grammatical form
## that slots into the feed lines; the proper names live in the crier line.
const TOWN_LEVELS := [
    {"at": 0,    "name": "a crossing"},
    {"at": 120,  "name": "a hamlet"},
    {"at": 175,  "name": "a guild post"},
    {"at": 230,  "name": "a village"},
    {"at": 290,  "name": "a market-day town"},
    {"at": 360,  "name": "a chapel town"},
    {"at": 440,  "name": "a crafters' row"},
    {"at": 540,  "name": "a garrison town"},
    {"at": 660,  "name": "a market town"},
    {"at": 800,  "name": "a walled heart"},
    {"at": 960,  "name": "a walled town"},
    {"at": 1140, "name": "a city in all but charter"},
]
var renown := 0
var day := 1
var clock := 0.30                # 0..1 through the day; start at dawn (old sim)

func hour() -> float:
    return clock * 24.0

func is_night() -> bool:
    var h := hour()
    return h < 6.0 or h > 18.5
var town_level := 1
var town_name := "a crossing"
# D32: the content writer's crier lines for reaching a tier (growth_tiers.tiers)
var _gt_lore: Array = []
var _gt_loaded := false
var _day_t := DAY_SECONDS
var _founded := false

## The old valley's souls are its ROSTER trades (30 at the founding). The HD
## town's extra street life (washers, children, the watch, carters...) is set
## dressing and is not counted - otherwise Bellmire would be founded a free city.
const SOULS := ["adventurer", "chief", "guard", "farmer", "lumberjack", "miner", "smith", "healer",
                "merchant", "trader", "miller", "fletcher", "innkeeper"]

func population() -> int:
    var n := 0
    for p in town.get("people"):
        if not is_instance_valid(p):
            continue
        # viewers' heroes are not the valley's souls; the town's own band is
        if p is HeroBody and not (p as HeroBody).npc:
            continue
        if String((p as Townsfolk).role) in SOULS:
            n += 1
    return n

func town_score() -> int:
    return population() * 3 + renown * 2

func level_for(score: int) -> int:
    var lv := 1
    for i in range(TOWN_LEVELS.size()):
        if score >= int(TOWN_LEVELS[i]["at"]):
            lv = i + 1
    return lv

## D32: load the content writer's growth-tier crier lines once, lazily.
func _ensure_growth_lore() -> void:
    if _gt_loaded:
        return
    _gt_loaded = true
    var f := FileAccess.open("res://data/lore_lines.json", FileAccess.READ)
    if f == null:
        return
    var data: Variant = JSON.parse_string(f.get_as_text())
    f.close()
    if data is Dictionary and (data as Dictionary).has("growth_tiers"):
        var gt: Variant = (data as Dictionary)["growth_tiers"]
        if gt is Dictionary and (gt as Dictionary).has("tiers"):
            _gt_lore = (gt as Dictionary)["tiers"]

## the crier's line on reaching town level `level` (1-based), or "" if none.
func _crier_for(level: int) -> String:
    _ensure_growth_lore()
    var i := level - 1
    if i >= 0 and i < _gt_lore.size():
        return String((_gt_lore[i] as Dictionary).get("crier", ""))
    return ""

func check_town_level(founding := false) -> int:
    var want := level_for(town_score())
    if want == town_level and not founding:
        return 0
    var was := town_level
    town_level = want
    town_name = String(TOWN_LEVELS[town_level - 1]["name"])
    # WHAT THE TOWN CAN MAKE (old sim.sync_unlocks): the smiths forge up to the
    # town's own tier - one static for every roll, the viewers' and the band's
    # D64: that ceiling is now a property of the SMITHY (a building with a level), not of the
    # town at large. Growth still grants the smithy what the town can host; D66's viewer poll
    # adds levels on top through raise_shop(). The counter honours Roster.town_tier, which is
    # set from the smithy's level and nothing else.
    shop_grown["smithy"] = Roster.tier_for_town(town_level)
    _apply_shop_caps()
    # D3: Bellmire's buildings follow its level (scripts/growth.gd)
    if town.has_method("show_level"):
        town.call("show_level", town_level, founding)
    var feed: Array = town.get("feed")
    if founding:
        feed.append("%d souls live here." % population())
        var cf := _crier_for(town_level)
        if cf != "":
            feed.append(cf)
        else:
            feed.append("Bellmire stands as %s.  (town level %d)" % [town_name, town_level])
        _tag("growth")
    elif want > was:
        # D32: cry the content writer's line for each tier crossed on the way up
        for l in range(was + 1, town_level + 1):
            var c := _crier_for(l)
            if c != "":
                feed.append(c)
            else:
                feed.append("Bellmire grows into %s.  (town level %d)" % [town_name, town_level])
            _tag("growth")
        # D63.6: the town growing a level is a reason for a festival
        if town.has_method("start_festival"):
            town.call_deferred("start_festival", "level")
    else:
        feed.append("Bellmire falls back to %s.  (town level %d)" % [town_name, town_level])
        _tag("growth")
    return want - was

func price(g: String) -> float:
    var s: float = maxf(stock.get(g, 0.0), 1.0)
    var d: float = maxf(demand.get(g, 0.0), 1.0)
    var base: float = BASE_PRICE[g]
    return clampf(base * (d / s) * 6.0, base * 0.35, base * 4.0)

func add(g: String, n: float) -> void:
    stock[g] = maxf(0.0, stock.get(g, 0.0) + n * _work_k)

func take(g: String, n: float) -> bool:
    n *= _work_k
    if stock.get(g, 0.0) < n:
        demand[g] = demand.get(g, 0.0) + n
        return false
    stock[g] -= n
    return true

func want(g: String, n: float) -> void:
    demand[g] = demand.get(g, 0.0) + n

func _at_work(f: Townsfolk) -> bool:
    if f.stay:
        return true          # stallholders and posted guards are always at their post
    if f.work == Vector3.ZERO:
        return false
    # indoors at the workshop counts; indoors at home does not
    return Vector2(f.global_position.x - f.work.x, f.global_position.z - f.work.z).length() < 8.0

## D9 (the DnD RULE): a beat of work is a roll - d20 + 2 (a trained hand) vs
## DC 10. A 1 spoils the beat (nothing), a miss does half, a hit the full
## measure, a 20 twice it - all divided by the mean (0.85), so the town makes
## what it always made, now by the dice. A 20 reaches the Chronicle now and then.
const WORK_BONUS := 2
const WORK_DC := 10
const WORK_MEAN := 0.85
var _work_k := 1.0               # the beat's measure while produce() runs
var work_rolls := [0, 0, 0, 0]   # nat 1, miss, hit, nat 20 (tests)
var last_work_d := 0
var _work_big_t := 60.0

func work_roll() -> float:
    var c := Dice.check(WORK_BONUS, WORK_DC)
    last_work_d = int(c["d"])
    var k := 1.0
    if last_work_d == 1:
        k = 0.0
        work_rolls[0] += 1
    elif last_work_d == 20:
        k = 2.0
        work_rolls[3] += 1
    elif c["ok"]:
        work_rolls[2] += 1
    else:
        k = 0.5
        work_rolls[1] += 1
    return k / WORK_MEAN

## villager._produce, verbatim in effect (k: the work roll's measure, D9)
func produce(role: String, k := 1.0) -> void:
    _work_k = k
    _produce(role)
    _work_k = 1.0

func _produce(role: String) -> void:
    match role:
        "farmer":
            add("food", 1.45)
        "lumberjack":
            add("wood", 1.15)
        "miner":
            add("ore", 1.1)
            add("stone", 0.9)
        "smith":
            if take("ore", 1.2) and take("wood", 0.5):
                add("gear", 0.38)
            else:
                want("ore", 1.2)
        "healer":
            if take("food", 0.4):
                add("potion", 0.4)
        "merchant", "trader":
            treasury += int(round(2.0 * _work_k))
        "miller":
            if take("wood", 0.2):
                add("food", 0.85)
        "fletcher":
            if take("wood", 0.8):
                add("gear", 0.2)
        "innkeeper":
            if take("food", 0.5):
                treasury += int(round(3.0 * _work_k))

func _process(delta: float) -> void:
    if town == null:
        return
    var any := false
    for p in town.get("people"):
        if not is_instance_valid(p):
            continue
        var f: Townsfolk = p
        var t: float = float(_beat.get(f, randf_range(0.0, 6.5))) - delta
        if t <= 0.0:
            t = randf_range(3.5, 6.5)
            # old villager: _produce runs in the WORK state, which is the
            # daytime (the old clock: night is before 6:00 and after 18:30)
            if not is_night():
                produce(String(f.role), work_roll() * dis_work_k)
                any = true
                if last_work_d == 20 and _work_big_t <= 0.0 and f.person_name != "":
                    _work_big_t = 150.0
                    (town.get("feed") as Array).append("%s rolls a 20 at the %s's work - does a double day of it." % [f.person_name, String(f.role)])
        _beat[f] = t
    if any:
        changed.emit()
    if not _founded and town.get("people").size() > 0:
        _founded = true
        check_town_level(true)
    clock = fmod(clock + delta / DAY_SECONDS, 1.0)
    _day_t -= delta
    if _day_t <= 0.0:
        _day_t = DAY_SECONDS
        day += 1
        _end_of_day()
    growth(delta)
    _disaster_tick(delta)
    _work_big_t -= delta
    _chatter -= delta
    if _chatter <= 0.0:
        _chatter = randf_range(11.0, 20.0)
        _flavour()

## the old town._flavour stock lines (only the ones about stock)
func _flavour() -> void:
    var lines := []
    if stock.get("food", 0.0) < 20.0:
        lines.append("The granary is running low.")
    if stock.get("ore", 0.0) < 6.0:
        lines.append("The forge sits cold — no ore.")
    if stock.get("gear", 0.0) < 1.0:
        lines.append("No gear left on the rack.")
    if price("gear") > BASE_PRICE["gear"] * 2.0:
        lines.append("Gear prices have doubled.")
    if stock.get("food", 0.0) > 320.0 and randf() < 0.3:
        lines.append("A good harvest — the stores are full.")
    if lines.is_empty():
        return
    var line: String = lines[randi() % lines.size()]
    var feed: Array = town.get("feed")
    if feed.is_empty() or feed.back() != line:
        feed.append(line)

## ---------------------------------------------------------- end of a day
## old sim._end_of_day: the souls eat (1.15 food each), the granary can run
## empty (starving counts the days), demand decays so prices drift back, tax
## 1.8 and wages 1.9 a soul ("a soul is very nearly self-financing"), the
## level is checked, and the day is announced with the town's standing.
var starving := 0
var dead := 0

func next_level_at() -> int:
    if town_level >= TOWN_LEVELS.size():
        return -1
    return int(TOWN_LEVELS[town_level]["at"])

## D60: tag the Chronicle line just raised (town.tag_feed) - kind, and the heroes it is about
func _tag(kind: String, who: Array = []) -> void:
    if town and town.has_method("tag_feed"):
        town.call("tag_feed", kind, who)

func _end_of_day() -> void:
    var pop := population()
    var feed: Array = town.get("feed")
    var eaten := float(pop) * 1.15
    if not take("food", eaten):
        stock["food"] = 0.0
        starving += 1
        feed.append("Day %d  —  the granary is empty. Hunger bites (%d days)." % [day, starving])
        _tag("hunger")
    else:
        starving = 0
    for g in GOODS:
        demand[g] = demand.get(g, 0.0) * 0.55
    var tax := int(round(float(pop) * 1.8))
    var wages := int(round(float(pop) * 1.9))
    treasury += tax - wages
    if treasury < 0:
        treasury = 0
        feed.append("The coffer is empty — wages go unpaid.")
        _tag("treasury")
    check_town_level()
    _counter_watch()
    var nxt := next_level_at()
    var standing := ("standing %d/%d" % [town_score(), nxt]) if nxt > 0 else ("standing %d, at its height" % town_score())
    feed.append("Day %d begins  —  %d souls, %d gold, %s (lvl %d, %s)" % [day, pop, treasury, town_name, town_level, standing])
    _tag("day")

## --------------------------------------------------- growth and hardship
## old town._peril_pass timers: rebuild 22 s (Raids), chief spends 40 s,
## settlers 45-80 s, hunger 20 s.
const TRADES := ["farmer", "lumberjack", "miner", "smith", "trader", "fletcher", "guard"]
var _hire_t := 50.0
var _settler_t := 60.0
var _hunger_t := 30.0

func _count_role(r: String) -> int:
    var n := 0
    for p in town.get("people"):
        if is_instance_valid(p) and not (p is HeroBody) and String((p as Townsfolk).role) == r:
            n += 1
    return n

func growth(delta: float) -> void:
    _hire_t -= delta
    if _hire_t <= 0.0:
        _hire_t = 40.0
        if not _dis_no_growth:
            _chief_spends()
    _settler_t -= delta
    if _settler_t <= 0.0:
        _settler_t = randf_range(45.0, 80.0)
        if not _dis_no_growth:
            _settlers()
    _hunger_t -= delta
    if _hunger_t <= 0.0:
        _hunger_t = 20.0
        _hunger()

func _settlers() -> void:
    var housing: int = int(town.call("home_count")) * 3
    if population() >= housing:
        return
    # word of a prosperous town travels
    if stock.get("food", 0.0) < 35.0 or treasury < 120:
        return
    var adv: Adventurers = town.get("adventurers")
    if adv and renown >= 3 and adv.count() < 6 and randf() < 0.55:
        var b := adv.make("", true)
        var h := adv.npcs.get_hero(b.user_id)
        (town.get("feed") as Array).append("%s the %s arrives at the tavern, drawn by tales of the deep." % [b.person_name, h["class"]])
        _tag("arrival", [b.person_name])
        renown -= 1
        return
    town.call("arrive", TRADES[randi() % TRADES.size()], "%s settles in Bellmire, looking for work.")

func _chief_spends() -> void:
    var feed: Array = town.get("feed")
    var guards := _count_role("guard")
    var rd = town.get("raids")
    var raids_n: int = rd.raids if rd else 0
    # standing garrison scales with how dangerous the valley has become
    var want_guards: int = 3 + int(raids_n / 2)
    if guards < want_guards and treasury >= 180:
        treasury -= 180
        town.call("arrive", "guard", "%s is sworn into the watch.")
        return
    # a bounty draws sellswords when the dungeon has eaten the last party
    var adv: Adventurers = town.get("adventurers")
    if adv and adv.count() < 3 and treasury >= 240:
        treasury -= 240
        var b := adv.make("" if adv.has_healer() else "sage", true)
        var h := adv.npcs.get_hero(b.user_id)
        feed.append("A bounty is posted — %s the %s answers it." % [b.person_name, h["class"]])
        _tag("arrival", [b.person_name])
        return
    # commission gear when the rack is bare
    if stock.get("gear", 0.0) < 4.0 and treasury >= 150:
        treasury -= 150
        add("gear", 5.0)
        feed.append("The chief commissions a batch of gear.")
        changed.emit()
        return
    # lean years: buy grain rather than let people starve
    if stock.get("food", 0.0) < 25.0 and treasury >= 120:
        treasury -= 120
        add("food", 40.0)
        feed.append("The chief buys grain against the hunger.")

## two days of an empty granary and people start to die (14 a blow, 28 hp)
func _hunger() -> void:
    if starving < 2:
        return
    var pool: Array = []
    for p in town.get("people"):
        if is_instance_valid(p) and not (p is HeroBody) and String((p as Townsfolk).role) in SOULS \
                and String((p as Townsfolk).role) != "chief":
            pool.append(p)
    if pool.is_empty():
        return
    var v: Townsfolk = pool[randi() % pool.size()]
    var hp := float(v.get_meta("hp", 28.0)) - 14.0
    v.set_meta("hp", hp)
    HealthBar3D.on(v, 2.05, false).set_hp(hp, 28.0, false)
    if hp <= 0.0:
        renown = max(0, renown - 2)
        town.call("bury", v, "%s has starved." % v.person_name)


## --------------------------------------------------- D34 natural disasters
func _ensure_dis_lore() -> void:
    if _dis_lore_loaded:
        return
    _dis_lore_loaded = true
    var f := FileAccess.open("res://data/lore_lines.json", FileAccess.READ)
    if f == null:
        return
    var data: Variant = JSON.parse_string(f.get_as_text())
    f.close()
    if data is Dictionary and (data as Dictionary).has("disasters"):
        _dis_lore = (data as Dictionary)["disasters"]

func disaster_active() -> String:
    return _dis_active

func casting_blocked() -> bool:
    return _dis_no_cast

func trade_blocked() -> bool:
    return _dis_trade_frozen

## the canonical line, or - 6 times in 10 - a random alt so a second disaster of
## the same kind never reads word for word like the first
func _dis_phrase(key: String, alt_key: String) -> String:
    var d: Dictionary = _dis_lore.get(_dis_active, {})
    if d.is_empty():
        return ""
    if alt_key != "" and d.has(alt_key):
        var alt: Array = d[alt_key]
        if alt.size() > 0 and randf() < 0.6:
            return String(alt[randi() % alt.size()])
    return String(d.get(key, ""))

func _dis_say(line: String) -> void:
    if line == "" or town == null:
        return
    var feed = town.get("feed")
    if feed != null and (feed.is_empty() or String(feed.back()) != line):
        feed.append(line)
        _tag("disaster")

## begin a named disaster: charge its onset cost, raise its flags, cry the line
func trigger_disaster(name: String) -> bool:
    if _dis_active != "" or not DIS_SPECS.has(name):
        return false
    _ensure_dis_lore()
    _dis_active = name
    _dis_t = DIS_DAYS * DAY_SECONDS
    _dis_during_t = DIS_DURING_GAP
    var spec: Dictionary = DIS_SPECS[name]
    for g in GOODS:
        if spec.has(g):
            stock[g] = maxf(0.0, stock.get(g, 0.0) * (1.0 - float(spec[g])))
    if spec.has("gold"):
        treasury = max(0, treasury - int(spec["gold"]))
    if spec.has("renown"):
        renown = max(0, renown - int(spec["renown"]))
    dis_work_k = float(spec.get("workk", 1.0))
    _dis_no_growth = bool(spec.get("no_growth", false))
    _dis_no_cast = bool(spec.get("no_cast", false))
    _dis_trade_frozen = bool(spec.get("trade_frozen", false))
    _dis_say(_dis_phrase("begin", "begin_alt"))
    changed.emit()
    return true

func _end_disaster() -> void:
    if _dis_active == "":
        return
    var spec: Dictionary = DIS_SPECS.get(_dis_active, {})
    _dis_say(_dis_phrase("pass", "pass_alt"))
    var og: int = int(spec.get("on_pass_gold", 0))
    if og != 0:
        treasury = max(0, treasury + og)
    disasters_survived += 1
    _dis_active = ""
    _dis_t = 0.0
    dis_work_k = 1.0
    _dis_no_growth = false
    _dis_no_cast = false
    _dis_trade_frozen = false
    _dis_cool = randf_range(DIS_COOL_DAYS * 0.7, DIS_COOL_DAYS * 1.3) * DAY_SECONDS
    changed.emit()

func _disaster_tick(delta: float) -> void:
    if _dis_active != "":
        _dis_t -= delta
        _dis_during_t -= delta
        if _dis_during_t <= 0.0:
            _dis_during_t = DIS_DURING_GAP
            var d: Dictionary = _dis_lore.get(_dis_active, {})
            var during: Array = d.get("during", [])
            if during.size() > 0:
                _dis_say(String(during[randi() % during.size()]))
        if _dis_t <= 0.0:
            _end_disaster()
        return
    _dis_cool -= delta
    if _dis_cool <= 0.0:
        _dis_cool = randf_range(DIS_COOL_DAYS * 0.7, DIS_COOL_DAYS * 1.3) * DAY_SECONDS
        if town_level >= DIS_MIN_LEVEL and day >= DIS_MIN_DAY:
            _maybe_disaster()

func _maybe_disaster() -> void:
    _ensure_dis_lore()
    var pool: Array = DIS_SPECS.keys()
    if not pool.is_empty():
        trigger_disaster(String(pool[randi() % pool.size()]))

## ---------------------------------------------- D64: a shop's level decides what it sells
## Mr. E's ruling (Nov 15 11:46): "a shop that is level 1 isn't going to sell epic or legendary
## equipment". Tier availability is a property of the BUILDING, not the buyer.
##   - RARITY names the existing gear ladders (gear.gd/roster.gd WEAPONS + ARMOUR, read only - no
##     cost, atk, hp, ac or dice value changes). Index = tier: 0 is the unarmed/unarmoured
##     fallback, 1-4 are what a smith can make, 5 (scarforged / scarwoven mail) stays FOUND-only.
##   - A shop's level IS the highest tier it will sell (level 1 sells common and nothing else).
##   - shop_grown is what the town's growth grants the building (today's curve, unchanged, so
##     nothing regresses); shop_raised is what viewers paid for (D66 calls raise_shop). The
##     level is the sum, clamped to what a smith can make at all.
## C-55: the ladder word is "very rare", matching data/items.json - "epic" is retired everywhere
const RARITY := ["none", "common", "uncommon", "rare", "very rare", "legendary"]
const SHOP_MAX_LEVEL := 4
const SHOP_NAMES := {"smithy": "the smithy"}
var shop_grown := {"smithy": 1}
var shop_raised := {"smithy": 0}
var _counter_told := {}           # "user_id|level" -> true: the counter says it once per level
var counter_refusals := 0         # tests: times a richer hero was turned away by the cap

## H29.6: the content writer's data/items.json, read ONCE and shared (the shelves, the
## caravans' cargo and the retirements are all in it). Read-only; {} if it is missing.
static var _items_cache: Dictionary = {}
static var _items_loaded := false
static func items_data() -> Dictionary:
    if not _items_loaded:
        _items_loaded = true
        var f := FileAccess.open("res://data/items.json", FileAccess.READ)
        if f:
            var d: Variant = JSON.parse_string(f.get_as_text())
            if d is Dictionary:
                _items_cache = d
    return _items_cache

## D99: items.json stock_by_tier - the content writer's growth gating, CUMULATIVE: a town at
## tier N carries every shop_adds (or cargo_adds) key from tiers 1..N and nothing is removed.
## Returns the first tier a key is listed at, or 0 when stock_by_tier does not name the key at
## all (then the older rule - the good's own tier / opens_tier - still governs it alone).
static var _sbt: Dictionary = {}
static func stock_first_tier(key: String, kind := "shop_adds") -> int:
    if not _sbt.has(kind):
        var m: Dictionary = {}
        for row in ((items_data().get("stock_by_tier", {}) as Dictionary).get("tiers", []) as Array):
            if row is Dictionary:
                var t := int((row as Dictionary).get("tier", 0))
                for k in ((row as Dictionary).get(kind, []) as Array):
                    if not m.has(String(k)):
                        m[String(k)] = t
        _sbt[kind] = m
    return int((_sbt[kind] as Dictionary).get(key, 0))

## D99: true when stock_by_tier lets this key be on sale at this growth tier.
static func stock_open(key: String, tier: int, kind := "shop_adds") -> bool:
    var first := stock_first_tier(key, kind)
    return first == 0 or first <= tier

## D99: ARTIFACT is found-only (items.json _note_c58 / _note_c61): "no shop at any level and no
## trader may ever stock one". Every shelf and every wagon asks this before it lists a good.
static func never_stocked(g: Dictionary) -> bool:
    return String(g.get("rarity", "")).to_lower() == "artifact" or bool(g.get("found", false))

## D99: items.json price_ladders, checked as its _note says: down each ladder cost and tier are
## both non-decreasing, so a grander good is never cheaper. A key is looked up in shop_stock,
## trader_cargo and every trade_stock own_goods. Returns one line per fault (a missing key is a
## fault too - a ladder naming nothing is not a check). Empty = the ladders hold.
static func ladder_faults() -> Array:
    var it := items_data()
    var pool: Dictionary = {}
    for src in ["shop_stock", "trader_cargo"]:
        var d: Variant = it.get(src, {})
        if d is Dictionary:
            for k in (d as Dictionary):
                if (d as Dictionary)[k] is Dictionary:
                    pool[String(k)] = (d as Dictionary)[k]
    var trades: Variant = (it.get("trade_stock", {}) as Dictionary).get("trades", {})
    if trades is Dictionary:
        for tk in (trades as Dictionary):
            var own: Variant = ((trades as Dictionary)[tk] as Dictionary).get("own_goods", {})
            if own is Dictionary:
                for k in (own as Dictionary):
                    if (own as Dictionary)[k] is Dictionary and not pool.has(String(k)):
                        pool[String(k)] = (own as Dictionary)[k]
    var out: Array = []
    var ladders: Variant = (it.get("price_ladders", {}) as Dictionary).get("ladders", {})
    if not (ladders is Dictionary) or (ladders as Dictionary).is_empty():
        out.append("price_ladders: no ladders in items.json")
        return out
    for ln in (ladders as Dictionary):
        var pc := -1
        var pt := -1
        var pk := ""
        for key in ((ladders as Dictionary)[ln] as Array):
            var g: Variant = pool.get(String(key))
            if not (g is Dictionary):
                out.append("%s: %s is in no stock table" % [ln, key])
                continue
            var c := int((g as Dictionary).get("cost", 0))
            var t := int((g as Dictionary).get("tier", 1))
            if c < pc:
                out.append("%s: %s costs %d, under %s at %d" % [ln, key, c, pk, pc])
            if t < pt:
                out.append("%s: %s is tier %d, under %s at %d" % [ln, key, t, pk, pt])
            pc = c
            pt = t
            pk = String(key)
    return out

## D99: classes.json `healing` - the mend beat and the quaff rule. mend_interval_s is a number;
## quaff is the content writer's sentence ("A hero below 34% hp drinks a potion for 45% of max.")
## and its first percentage IS the threshold, read out of it rather than kept twice.
static var _heal_rules: Dictionary = {}
static var _heal_loaded := false
static func healing_rules() -> Dictionary:
    if not _heal_loaded:
        _heal_loaded = true
        var out := {"mend_interval_s": 2.4, "quaff_below": 0.34, "from_file": false}
        var f := FileAccess.open("res://data/classes.json", FileAccess.READ)
        if f:
            var d: Variant = JSON.parse_string(f.get_as_text())
            var hr: Variant = (d as Dictionary).get("healing") if d is Dictionary else null
            if hr is Dictionary:
                out["from_file"] = true
                if (hr as Dictionary).has("mend_interval_s"):
                    out["mend_interval_s"] = maxf(0.5, float((hr as Dictionary)["mend_interval_s"]))
                var re := RegEx.new()
                re.compile("below (\\d+)%")
                var mt := re.search(String((hr as Dictionary).get("quaff", "")))
                if mt:
                    out["quaff_below"] = clampf(float(mt.get_string(1)) / 100.0, 0.05, 0.95)
                out["voice"] = String((hr as Dictionary).get("voice", ""))
                # the voice rule's first quoted phrase is the self-mend wording
                var rq := RegEx.new()
                rq.compile("'([^']+)'")
                var mq := rq.search(String(out["voice"]))
                if mq:
                    out["self_mend"] = mq.get_string(1)
        if not bool(out["from_file"]):
            push_error("D99: classes.json healing not read - mend/quaff fall back to the old constants")
        _heal_rules = out
    return _heal_rules

static func rarity_of(tier: int) -> String:
    return String(RARITY[clampi(tier, 0, RARITY.size() - 1)])

func shop_level(key := "smithy") -> int:
    return clampi(int(shop_grown.get(key, 1)) + int(shop_raised.get(key, 0)), 1, SHOP_MAX_LEVEL)

## the best tier this shop will ever put on the counter
func shop_cap(key := "smithy") -> int:
    return shop_level(key)

func shop_sells_to(key := "smithy") -> String:
    return rarity_of(shop_cap(key))

func _apply_shop_caps() -> void:
    Roster.town_tier = shop_cap("smithy")
    if town and town.has_method("show_tiers"):
        town.call("show_tiers", Roster.town_tier, shop_level("smithy"))

## D66's entry point: an event raises a named shop. Returns the levels actually gained.
func raise_shop(key: String, by := 1, who := "") -> int:
    if not SHOP_NAMES.has(key):
        return 0
    var was := shop_level(key)
    shop_raised[key] = int(shop_raised.get(key, 0)) + maxi(by, 0)
    var now := shop_level(key)
    shop_raised[key] = now - int(shop_grown.get(key, 1))   # never bank levels past the top
    if now == was:
        return 0
    _apply_shop_caps()
    if town:
        var feed: Array = town.get("feed")
        var nm := String(SHOP_NAMES[key])
        var by_who := (" - paid for by %s" % who) if who != "" else ""
        feed.append("%s is raised to level %d: it will now sell %s goods%s." % [nm.capitalize(), now, rarity_of(shop_cap(key)), by_who])
        _tag("shop", [who] if who != "" else [])
    return now - was

## The counter, once a day: a hero who has the gold for the next piece but stands at a shop
## that is not allowed to sell it is told so plainly in the Chronicle, instead of the smith
## silently handing over nothing. Read-only on the roster (laptop-owned).
func _counter_watch() -> void:
    if town == null:
        return
    var r = town.get("roster")
    if r == null:
        return
    var feed: Array = town.get("feed")
    var cap := shop_cap("smithy")
    var lv := shop_level("smithy")
    for uid in (r.heroes as Dictionary).keys():
        var h: Dictionary = r.heroes[uid]
        if not bool(h.get("alive", true)):
            continue
        var w := int(h.get("weapon", 0))
        var nxt := w + 1
        if nxt >= Roster.WEAPONS.size() or bool((Roster.WEAPONS[nxt] as Dictionary).get("found", false)):
            continue
        if nxt <= cap:
            continue                  # the shop may sell it; whether they buy is the forge's business
        var price: int = r.cost_for(h, int((Roster.WEAPONS[nxt] as Dictionary)["cost"]))
        if int(h.get("gold", 0)) < price + Roster.KIT_RESERVE:
            continue                  # not a richer hero - the cap is not what stops them
        var key := "%s|%d" % [uid, lv]
        if _counter_told.has(key):
            continue
        _counter_told[key] = true
        counter_refusals += 1
        var best: Dictionary = Roster.WEAPONS[cap]
        var nm := String(h.get("name", "A hero"))
        feed.append("%s stands at the smithy with %d gold for %s steel, but a level %d smithy sells nothing past %s - %s is the best it will make." \
            % [nm, int(h.get("gold", 0)), rarity_of(nxt), lv, rarity_of(cap), String(best["name"])])
        _tag("shop", [nm])

# ---- SYSTEM 38 (S151): TAVERN GAMES - the house-game logic behind `!dice` ----
## Mr. E's directive (27 Nov 02:18 CT, claude/sup-nov27-0218): one roll per command, no doubling
## down, no side bets. The tavern building already stands; this is a function on it, not a building.
##   tavern_dice(h, 0)        bare `!dice` - a roll for fun, no gold moves
##   tavern_dice(h, amt)      against the house: both roll a d20, BEAT the house to win. A win pays
##                            double the stake less the house's 10% cut of that pot; a loss leaves the
##                            stake with the tavern. A TIE IS THE HOUSE'S ("beat the house roll").
##                            Gold the tavern keeps LEAVES THE ECONOMY (a System 20 sink) - it is
##                            counted in tavern_take and never reaches the treasury; what it pays on
##                            a win is counted in tavern_paid. The house edge (ties, and the cut)
##                            makes take - paid the net gold sunk, positive over any long run.
##   tavern_duel(a, b, amt)   viewer against viewer: both stake, higher roll takes the pot, NO cut,
##                            ties re-roll (bounded) so a duel always ends in one command.
## Stakes: min DICE_MIN, max dice_max_bet() which scales with the town level. Each call returns a
## Dictionary - ok, why (on a refusal), rolls, delta(s) and a plain `text` line - so the chat bot's
## `!dice` only renders it; this file owns the rules and moves the gold.
const DICE_MIN := 1
const DICE_MAX_PER_LEVEL := 25    # a crossing stakes 25g at most; a city in all but charter 300g
const DICE_HOUSE_CUT := 0.10
const DICE_TIE_REROLLS := 8
var dice_rng := RandomNumberGenerator.new()
var tavern_take := 0              # gold the house has kept and sunk (lost stakes + its cut)
var tavern_paid := 0              # gold the house has paid out on wins (the stake it matched)
var tavern_games := 0
var tavern_duels := 0

func dice_max_bet() -> int:
    return DICE_MAX_PER_LEVEL * maxi(1, town_level)

func _dice_stake_ok(h: Dictionary, amount: int) -> String:
    if amount < DICE_MIN:
        return "min"
    if amount > dice_max_bet():
        return "max"
    if int(h.get("gold", 0)) < amount:
        return "gold"
    return ""

func _dice_refusal(h: Dictionary, why: String, amount: int) -> String:
    var nm := String(h.get("name", "A hero"))
    match why:
        "min":
            return "%s - the least the tavern takes is %d gold." % [nm, DICE_MIN]
        "max":
            return "%s - %s plays for %d gold at most. The stakes rise as the town does." \
                % [nm, town_name, dice_max_bet()]
        "gold":
            return "%s puts down %d gold they do not have - %d in the purse." % [nm, amount, int(h.get("gold", 0))]
        "dead":
            return "%s is in no state to throw dice." % nm
        "self":
            return "%s cannot dice against themselves." % nm
    return "%s cannot play that." % nm

func tavern_dice(h: Dictionary, amount := 0) -> Dictionary:
    var nm := String(h.get("name", "A hero"))
    if not bool(h.get("alive", true)):
        return {"ok": false, "why": "dead", "text": _dice_refusal(h, "dead", amount)}
    var you := dice_rng.randi_range(1, 20)
    if amount <= 0:
        return {"ok": true, "fun": true, "you": you, "delta": 0,
            "text": "%s throws the tavern dice for luck: %d." % [nm, you]}
    var why := _dice_stake_ok(h, amount)
    if why != "":
        return {"ok": false, "why": why, "text": _dice_refusal(h, why, amount)}
    var house := dice_rng.randi_range(1, 20)
    tavern_games += 1
    var delta := 0
    var text := ""
    if you > house:
        var cut := int(ceil(float(amount * 2) * DICE_HOUSE_CUT))
        delta = amount - cut                      # stake back + stake won, less the cut of the pot
        tavern_take += cut
        tavern_paid += amount                     # the house matched the stake
        text = "%s rolls %d to the house's %d and wins - %d gold after the house's cut." % [nm, you, house, amount * 2 - cut]
    else:
        delta = -amount
        tavern_take += amount
        text = "%s rolls %d to the house's %d%s - the tavern keeps %d gold." \
            % [nm, you, house, " (the house wins ties)" if you == house else "", amount]
    h["gold"] = int(h.get("gold", 0)) + delta
    Roster.rep_add(h, "innkeeper")            # S152 System 39: a staked game, silent
    return {"ok": true, "fun": false, "you": you, "house": house, "delta": delta, "text": text}

func tavern_duel(a: Dictionary, b: Dictionary, amount: int) -> Dictionary:
    if is_same(a, b):
        return {"ok": false, "why": "self", "text": _dice_refusal(a, "self", amount)}
    for p in [a, b]:
        if not bool(p.get("alive", true)):
            return {"ok": false, "why": "dead", "who": String(p.get("name", "")), "text": _dice_refusal(p, "dead", amount)}
        var why := _dice_stake_ok(p, amount)
        if why != "":
            return {"ok": false, "why": why, "who": String(p.get("name", "")), "text": _dice_refusal(p, why, amount)}
    var ra := 0
    var rb := 0
    var throws := 0
    while ra == rb and throws <= DICE_TIE_REROLLS:
        ra = dice_rng.randi_range(1, 20)
        rb = dice_rng.randi_range(1, 20)
        throws += 1
    if ra == rb:
        rb = ra - 1 if ra > 1 else ra + 1        # bounded: the last tie is broken, never left open
    var win: Dictionary = a if ra > rb else b   # ra != rb is guaranteed above
    var lose: Dictionary = b if ra > rb else a
    win["gold"] = int(win.get("gold", 0)) + amount
    lose["gold"] = int(lose.get("gold", 0)) - amount
    tavern_duels += 1
    Roster.rep_add(a, "innkeeper")            # S152 System 39: both players did business here
    Roster.rep_add(b, "innkeeper")
    var na := String(a.get("name", "A hero"))
    var nb := String(b.get("name", "A hero"))
    return {"ok": true, "a": ra, "b": rb, "throws": throws, "winner": String(win.get("name", "")),
        "pot": amount * 2, "delta_a": amount if is_same(win, a) else -amount, "delta_b": amount if is_same(win, b) else -amount,
        "text": "%s rolls %d, %s rolls %d%s - %s takes the pot of %d gold." \
            % [na, ra, nb, rb, " after a tie" if throws > 1 else "", String(win.get("name", "")), amount * 2]}

## S151: a duel takes BOTH purses, so the challenged must agree - otherwise `!dice 300 someone` would
## gamble away a viewer's gold without them. tavern_challenge posts the offer (stakes checked now,
## no gold moves); tavern_accept(b) settles it through tavern_duel, re-checking both purses then. One
## open offer per challenged hero (a new one replaces it); offers lapse after DICE_OFFER_MS.
const DICE_OFFER_MS := 60000
var _dice_offers: Array = []      # [{a, b, amt, at}]

func tavern_challenge(a: Dictionary, b: Dictionary, amount: int, now_ms := -1) -> Dictionary:
    if is_same(a, b):
        return {"ok": false, "why": "self", "text": _dice_refusal(a, "self", amount)}
    for p in [a, b]:
        if not bool(p.get("alive", true)):
            return {"ok": false, "why": "dead", "who": String(p.get("name", "")), "text": _dice_refusal(p, "dead", amount)}
        var why := _dice_stake_ok(p, amount)
        if why != "":
            return {"ok": false, "why": why, "who": String(p.get("name", "")), "text": _dice_refusal(p, why, amount)}
    var t := now_ms if now_ms >= 0 else Time.get_ticks_msec()
    for i in range(_dice_offers.size() - 1, -1, -1):
        if is_same(_dice_offers[i]["b"], b):
            _dice_offers.remove_at(i)
    _dice_offers.append({"a": a, "b": b, "amt": amount, "at": t})
    return {"ok": true, "pending": true, "text": "%s lays %d gold on the table and dares %s to throw. (!dice accept)" \
        % [String(a.get("name", "A hero")), amount, String(b.get("name", "A hero"))]}

func tavern_accept(b: Dictionary, now_ms := -1) -> Dictionary:
    var t := now_ms if now_ms >= 0 else Time.get_ticks_msec()
    for i in range(_dice_offers.size() - 1, -1, -1):
        var o: Dictionary = _dice_offers[i]
        if t - int(o["at"]) > DICE_OFFER_MS:
            _dice_offers.remove_at(i)
            continue
        if is_same(o["b"], b):
            _dice_offers.remove_at(i)
            return tavern_duel(o["a"], b, int(o["amt"]))
    return {"ok": false, "why": "none", "text": "%s has no dare on the table." % String(b.get("name", "A hero"))}
