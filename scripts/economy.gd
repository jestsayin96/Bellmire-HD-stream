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

## ---- town level (old sim.gd). Earned by holding people and being worth
## talking about; gold left out on purpose. Checked once a day (90 s), and a
## town can fall back down. Raids are gated on it (from level 3).
const DAY_SECONDS := 90.0
const TOWN_LEVELS := [
    {"at": 0,   "name": "a hamlet"},
    {"at": 46,  "name": "a village"},
    {"at": 104, "name": "a market town"},
    {"at": 190, "name": "a walled town"},
    {"at": 310, "name": "a free city"},
    {"at": 470, "name": "the seat of the valley"},
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
var town_name := "a hamlet"
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

func check_town_level(founding := false) -> int:
    var want := level_for(town_score())
    if want == town_level and not founding:
        return 0
    var was := town_level
    town_level = want
    town_name = String(TOWN_LEVELS[town_level - 1]["name"])
    # WHAT THE TOWN CAN MAKE (old sim.sync_unlocks): the smiths forge up to the
    # town's own tier - one static for every roll, the viewers' and the band's
    Roster.town_tier = Roster.tier_for_town(town_level)
    if town.has_method("show_tiers"):
        town.call("show_tiers", Roster.town_tier)
    # D3: Bellmire's buildings follow its level (scripts/growth.gd)
    if town.has_method("show_level"):
        town.call("show_level", town_level, founding)
    var feed: Array = town.get("feed")
    if founding:
        feed.append("%d souls live here." % population())
        feed.append("Bellmire stands as %s.  (town level %d)" % [town_name, town_level])
    elif want > was:
        feed.append("Bellmire grows into %s.  (town level %d)" % [town_name, town_level])
    else:
        feed.append("Bellmire falls back to %s.  (town level %d)" % [town_name, town_level])
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
                produce(String(f.role), work_roll())
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

func _end_of_day() -> void:
    var pop := population()
    var feed: Array = town.get("feed")
    var eaten := float(pop) * 1.15
    if not take("food", eaten):
        stock["food"] = 0.0
        starving += 1
        feed.append("Day %d  —  the granary is empty. Hunger bites (%d days)." % [day, starving])
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
    check_town_level()
    var nxt := next_level_at()
    var standing := ("standing %d/%d" % [town_score(), nxt]) if nxt > 0 else ("standing %d, at its height" % town_score())
    feed.append("Day %d begins  —  %d souls, %d gold, %s (lvl %d, %s)" % [day, pop, treasury, town_name, town_level, standing])

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
        _chief_spends()
    _settler_t -= delta
    if _settler_t <= 0.0:
        _settler_t = randf_range(45.0, 80.0)
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
