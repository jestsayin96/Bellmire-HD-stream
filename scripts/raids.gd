extends Node
class_name Raids
## PERILS - ported from the old town._raid / _peril_pass / _combat_pass /
## _wreck_a_building / _rebuild_pass and villager.gd's FIGHT state. The
## read-only original is the rulebook:
##  - no raids until Bellmire is a market town (RAIDS_FROM_LEVEL 3) - "a hamlet
##    has nothing to defend itself with and nothing to lose";
##  - every 110-190 s; 62% boil out of the scar (skeleton warriors, rogues and
##    minions), otherwise bandits ride in on the west road; n = min(8,
##    2 + 0..2 + day/3 + renown/12); raiders hp 30, atk 5.5, speed 4;
##  - guards (hp 64, atk 11), the chief (hp 40, atk 6) and heroes fight; a
##    defender takes the nearest raider within 70 m, a raider the nearest
##    defender within 26 m, else it makes for the middle of town; anyone who
##    cannot fight runs 16 m away from a raider within 13 m;
##  - d20 + to-hit vs AC: a 1 always misses, a 20 lands double; swing 1.1 s,
##    reach 2.2 m, chase at 1.15x speed;
##  - while raiders are inside the walls a building is wrecked every 7-13 s
##    ("A building is burning!"); townsfolk raise the first ruin again every
##    22 s for 12 wood + 8 stone;
##  - "The attack is driven off. The gates hold." when the last one falls.
## Bellmire HD balance (cycle 55):
##  - a green hero (under GREEN_BELOW) does not charge the raiders: they hold
##    the market square with the townsfolk behind them and only fight what
##    comes within arm's reach - until raiders are inside the walls (the town
##    is breached), then everyone fights;
##  - a hero's first fall in a raid while still green is a grace, once ever:
##    knocked senseless, out of the fight, up again when the raid is over.

const RAIDS_FROM_LEVEL := 3
const GREEN_BELOW := 3           # heroes under this level hang back
const HOLD_REACH := 9.0          # a hanging-back hero fights only this close
const SKELETONS := ["warrior", "cutpurse", "minion"]
var town: Node3D
var economy: Economy
var raids := 0
var _raid_t := randf_range(110.0, 190.0)
var _breach := 0.0
var _rebuild_t := 22.0
var _live := false
var raiders: Array = []          # {node, hp, max, atk, ac, to_hit, speed, name, target, swing, kind}
var _fighters := {}              # defender node -> {hp, max, atk, ac, to_hit, speed, target, swing, post, yaw, stay}
var ruins: Array = []            # {node, pos, debris}
var _slow := 0.0
var force_level := -1            # test hook
var breached := false            # raiders are inside the walls

func _level() -> int:
    return force_level if force_level > 0 else economy.town_level

func _say(line: String) -> void:
    (town.get("feed") as Array).append(line)
    print("FEED ", line)

## ------------------------------------------------------------------ raid
func raid(source := "") -> void:
    if _level() < RAIDS_FROM_LEVEL:
        return
    raids += 1
    var from_dungeon := randf() < 0.62 if source == "" else source == "scar"
    var day := economy.day
    var n: int = min(8, 2 + randi() % 3 + int(day / 3) + int(economy.renown / 12))
    var spawn: Vector3
    var sc: Dictionary = town.get("_scar_info")
    if from_dungeon and sc.has("mouth"):
        spawn = sc["mouth"] + (sc["fwd"] as Vector3) * 6.0
    else:
        from_dungeon = false
        var gw: Vector3 = town.call("_gate", -1.0)
        spawn = gw + Vector3(gw.x, 0, gw.z).normalized() * 40.0
    for i in range(n):
        var at := spawn + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
        at.y = float(town.call("height_at", at.x, at.z))
        var node: Node3D
        var nm := "Raider"
        if from_dungeon:
            var m := Monster.new()
            m.def = Bestiary.make(SKELETONS[randi() % SKELETONS.size()])
            m.state = Monster.S.IDLE
            m.ground_fn = Callable(town, "height_at")
            m.max_hp = 30.0
            m.hp = 30.0
            node = m
            nm = String(m.def.get("name", "raider"))
        else:
            var b := Townsfolk.new()
            b.role = "bandit"
            b.model = "Rogue_Hooded.glb"
            b.tint = Color(0.45, 0.36, 0.40)
            b.person_name = "Bandit"
            b.town = town
            b.stay = true
            node = b
            nm = "a bandit"
        node.position = at
        town.add_child(node)
        raiders.append({"node": node, "hp": 30.0, "max": 30.0, "atk": 5.5, "ac": 10, "to_hit": 2,
                        "speed": 4.0, "name": nm, "target": null, "swing": randf() * 1.1,
                        "kind": "monster" if from_dungeon else "bandit"})
    if from_dungeon:
        _say("%d creatures boil out of the dungeon!" % n)
    else:
        _say("%d bandits are riding on the west road!" % n)
    var riders := 0
    for p in town.get("people"):
        if is_instance_valid(p) and p is Cavalry and (p as Node3D).visible:
            riders += 1
    if riders > 0:
        _say("The mounted watch rides out to meet them - %d riders." % riders)

## ------------------------------------------------------------- defenders
func _defenders() -> Array:
    var out: Array = []
    for p in town.get("people"):
        if not is_instance_valid(p) or not (p as Node3D).visible:
            continue
        var is_hero: bool = p is HeroBody
        var role := String((p as Townsfolk).role)
        if not is_hero and role != "guard" and role != "chief":
            continue
        if String((p as Townsfolk).gear_role) == "lookout":
            continue          # the tower lookouts keep their towers
        if not _fighters.has(p):
            var st := {"target": null, "swing": 0.0, "post": (p as Node3D).global_position,
                       "yaw": (p as Node3D).rotation.y, "stay": (p as Townsfolk).stay}
            if is_hero:
                var r: Roster = (p as HeroBody).roster      # viewers' roll or the town's own
                var h: Dictionary = r.get_hero((p as HeroBody).user_id)
                st.merge({"hp": r.max_hp(h), "max": r.max_hp(h), "atk": r.attack(h), "ac": r.armour_class(h),
                          "to_hit": r.attack_bonus(h), "speed": r.speed(h)})
                st["green"] = int(h.get("level", 1)) < GREEN_BELOW
                st["cls"] = String(h.get("class", ""))
            elif p is Cavalry:
                # D4: the mounted watch - horsed, harder to bring down, rides at them
                st.merge({"hp": 80.0, "max": 80.0, "atk": 13.0, "ac": 13, "to_hit": 4, "speed": 9.0})
            elif role == "guard":
                st.merge({"hp": 64.0, "max": 64.0, "atk": 11.0, "ac": 10, "to_hit": 2, "speed": 4.4})
            else:
                st.merge({"hp": 40.0, "max": 40.0, "atk": 6.0, "ac": 10, "to_hit": 2, "speed": 3.4})
            _fighters[p] = st
        out.append(p)
    return out

func _d20() -> int:
    return randi() % 20 + 1

## one swing, by the sheet
func _strike(atk: float, to_hit: int, ac: int) -> float:
    var d := _d20()
    if d == 1:
        return 0.0
    if d == 20:
        return atk * 2.0
    return 0.0 if d + to_hit < ac else atk

func _flat(a: Vector3, b: Vector3) -> float:
    return Vector2(a.x - b.x, a.z - b.z).length()

## D1: raiders and defenders walked a straight line at their mark - through
## houses, stalls and the wall. Now they follow the town's navmesh (re-asked
## when the mark moves or every 0.7 s) and never step off walkable ground:
## raiders come in by the gates.
var _paths := {}

func _step(n: Node3D, to: Vector3, spd: float, delta: float) -> void:
    var goal := to
    var nv = town.get("nav")
    if nv != null and nv.ready_ok:
        var k := n.get_instance_id()
        var now := Time.get_ticks_msec()
        var c: Dictionary = _paths.get(k, {})
        if c.is_empty() or _flat(c["to"], to) > 1.0 or now - int(c["t"]) > 700:
            c = {"to": to, "t": now, "pts": town.call("route", n.global_position, to)}
            _paths[k] = c
        var pts: Array = c["pts"]
        while pts.size() > 1 and _flat(pts[0], n.global_position) < 0.45:
            pts.remove_at(0)
        if not pts.is_empty():
            goal = pts[0]
    var d := Vector3(goal.x - n.global_position.x, 0, goal.z - n.global_position.z)
    if d.length() < 0.05:
        return
    var p := n.global_position + d.normalized() * minf(spd * delta, d.length())
    n.global_position = town.call("keep_walkable", p)
    n.rotation.y = atan2(d.x, d.z)

func _anim(n: Node3D, key: String) -> void:
    if n is Cavalry:
        (n as Cavalry).mounted(key)
    elif n is Monster:
        (n as Monster)._play({"walk": "walk", "run": "walk", "attack": "attack", "idle": "idle", "die": "die"}[key])
    elif n is Townsfolk:
        var ap: AnimationPlayer = (n as Townsfolk)._anim
        Rig.play(ap, {"walk": "Walking_A", "run": "Running_A", "attack": "1H_Melee_Attack_Chop", "idle": "Idle", "die": "Death_A"}[key])

## ---------------------------------------------------------------- tick
func _process(delta: float) -> void:
    if town == null or economy == null:
        return
    _raid_t -= delta
    if _raid_t <= 0.0:
        _raid_t = randf_range(110.0, 190.0)
        raid()
    _rebuild_t -= delta
    if _rebuild_t <= 0.0:
        _rebuild_t = 22.0
        _rebuild_pass()
    _tick_ruin_fires(delta)
    if raiders.is_empty():
        if _live:
            _live = false
            _breach = 0.0
            breached = false
            _say("The attack is driven off. The gates hold.")
        _stand_down(delta)
        if _paths.size() > 400:
            _paths.clear()
        return
    _live = true
    var defs := _defenders()
    _tick_blessings(delta)
    _volley(delta)
    var centre: Vector3 = town.get("_market_pos")
    # breach: raiders inside the walls wreck the town
    var inside := 0
    for r in raiders:
        if _inside_walls((r["node"] as Node3D).global_position):
            inside += 1
    breached = inside > 0
    if inside > 0:
        _breach -= delta
        if _breach <= 0.0:
            _breach = randf_range(7.0, 13.0)
            _wreck_a_building()
    # targeting (the old _combat_pass, twice a second)
    _slow -= delta
    if _slow <= 0.0:
        _slow = 0.5
        _targets(defs)
        _flee()
    # health bars on everyone in the fight
    for rr in raiders:
        var rn: Node3D = rr["node"]
        HealthBar3D.on(rn, Spells.body_height(rn) + 0.25 if rn is Monster else 2.05, true).set_hp(float(rr["hp"]), float(rr["max"]), rr["target"] != null)
    for dd in defs:
        var st0: Dictionary = _fighters[dd]
        HealthBar3D.on(dd, 2.05, false).set_hp(float(st0["hp"]), float(st0["max"]), st0["target"] != null)
    # defenders
    var hold_i := 0
    for d in defs:
        var st: Dictionary = _fighters[d]
        if st.get("ko", false):
            continue
        var tg = st["target"]
        if tg == null or not raiders.has(tg):
            st["target"] = null
            if _hangs_back(st):
                _hold_square(d, st, centre, hold_i, delta)
                hold_i += 1
            continue
        (d as Townsfolk).stay = true
        _engage(d, st, tg, delta, true)
    # raiders
    for r in raiders.duplicate():
        var n: Node3D = r["node"]
        var tg = r["target"]
        if tg != null and (not is_instance_valid(tg) or not _fighters.has(tg) or float(_fighters[tg]["hp"]) <= 0.0):
            r["target"] = null
            tg = null
        if tg == null:
            if _flat(n.global_position, centre) > 3.0:
                _step(n, centre, _speed(r), delta)
                _anim(n, "walk")
            continue
        _engage(n, r, tg, delta, false)

func _targets(defs: Array) -> void:
    for d in defs:
        var st: Dictionary = _fighters[d]
        if st.get("ko", false):
            st["target"] = null
            continue
        if _hangs_back(st):
            # a green hero keeps the square: only what comes to them
            var near = st["target"] if raiders.has(st["target"]) else null
            if near != null and _flat((near["node"] as Node3D).global_position, (d as Node3D).global_position) > HOLD_REACH * 1.5:
                near = null
            if near == null:
                var nd := HOLD_REACH
                for r in raiders:
                    var dd := _flat((r["node"] as Node3D).global_position, (d as Node3D).global_position)
                    if dd < nd:
                        nd = dd
                        near = r
            st["target"] = near
            continue
        if st["target"] == null or not raiders.has(st["target"]):
            # The old 70 m reached every guard in the little hex town (they
            # mustered at one barracks). Bellmire HD posts its guards at gates
            # ~350 m apart, so the horn turns the WHOLE garrison out - the same
            # outcome: every guard in the valley answers the raid.
            var best = null
            var bd := 1e9
            for r in raiders:
                var rp: Vector3 = (r["node"] as Node3D).global_position
                var dist := _flat(rp, (d as Node3D).global_position)
                if dist < bd:
                    bd = dist
                    best = r
            st["target"] = best
    for r in raiders:
        if r["target"] == null:
            var best2 = null
            var bd2 := 26.0
            for d in defs:
                if _fighters[d].get("ko", false):
                    continue
                var dist2 := _flat((d as Node3D).global_position, (r["node"] as Node3D).global_position)
                if dist2 < bd2:
                    bd2 = dist2
                    best2 = d
            r["target"] = best2

## a green hero hangs back unless the town is breached
func _hangs_back(st: Dictionary) -> bool:
    return bool(st.get("green", false)) and not breached

## a green hero's place: a ring on the market square, facing out
func _hold_square(d: Node3D, st: Dictionary, centre: Vector3, i: int, delta: float) -> void:
    (d as Townsfolk).stay = true
    var a := float(i) * 1.3 + 0.4
    var spot := centre + Vector3(sin(a), 0, cos(a)) * (5.0 + float(i % 3) * 1.6)
    if _flat(d.global_position, spot) > 0.8:
        _step(d, spot, float(st["speed"]), delta)
        _anim(d, "run")
        return
    var out := spot - centre
    d.rotation.y = atan2(out.x, out.z)
    _anim(d, "idle")

## a fight between `me` (stats `st`) and `tg` - a raider dict (for a defender)
## or a defender node (for a raider)
func _engage(me: Node3D, st: Dictionary, tg, delta: float, defending: bool) -> void:
    if defending and BOOKS.has(String(st.get("cls", ""))):
        _cast_engage(me, st, tg, delta)
        return
    var tn: Node3D = (tg["node"] as Node3D) if defending else (tg as Node3D)
    st["swing"] = float(st["swing"]) - delta
    if _flat(me.global_position, tn.global_position) > 2.2:
        _step(me, tn.global_position, _speed(st) * 1.15, delta)
        _anim(me, "run")
        return
    var to := tn.global_position - me.global_position
    me.rotation.y = atan2(to.x, to.z)
    if float(st["swing"]) > 0.0:
        return
    st["swing"] = 1.1
    _anim(me, "attack")
    var ts: Dictionary = tg if defending else _fighters[tg]
    var dmg := _strike(float(st["atk"]), int(st["to_hit"]), int(ts["ac"]))
    if dmg > 0.0 and not defending:
        dmg = _ward_soaks(ts, dmg)
    if dmg <= 0.0:
        Sfx.at("swing", tn.global_position, -4.0)
        return
    Sfx.at("hit", tn.global_position)
    ts["hp"] = float(ts["hp"]) - dmg
    if tn is Monster:
        (tn as Monster).hp = float(ts["hp"])
        (tn as Monster)._number(dmg, dmg > float(st["atk"]))
        (tn as Monster)._flash()
    var killer := _name_of(me, st)
    if float(ts["hp"]) <= 0.0:
        if defending:
            _raider_falls(tg, killer)
        else:
            _defender_falls(tn, ts, killer)

## ------------------------------------------------------------ spells (D2)
## The arcane callings (mage, sage, cleric) fight a raid with spells from
## SPELL_REACH, not a staff to the face. A mage works through its book (bolt,
## bolt, chain, fire); a sage first lays RENEW on the most hurt defender near
## it, else slows a raider with frost; a cleric first WARDS the most hurt,
## else SMITES (the scar's dead take it hardest). Damage lands when the spell
## does, after its flight. In a scar the cast misfires in turn (Spells).
const SPELL_REACH := 8.0
const SPELL_SWING := 1.6
const BOOKS := {"mage": ["bolt", "bolt", "chain", "fire"], "sage": ["frost", "bolt"], "cleric": ["smite", "bolt"]}
const MENDERS := {"sage": "renew", "cleric": "ward"}
const CHAIN_R := 5.0             # the chain leaps to a raider this near the last
const FIRE_R := 2.6              # the fire burst catches every raider this near its mark
const FROST_SLOW := 4.0          # s a frosted raider goes at half pace
const SMITE_DEAD := 1.5          # smite on the scar's dead
const RENEW_HEAL := 0.30         # of the target's max, over Spells.RENEW_T
const WARD_SOAK := 0.35          # of the target's max, soaked for WARD_T s
const WARD_T := 8.0

func _speed(st: Dictionary) -> float:
    return float(st["speed"]) * (0.5 if float(st.get("slow_t", 0.0)) > 0.0 else 1.0)

func _cast_engage(me: Node3D, st: Dictionary, tg: Dictionary, delta: float) -> void:
    var tn: Node3D = tg["node"]
    st["swing"] = float(st["swing"]) - delta
    if _flat(me.global_position, tn.global_position) > SPELL_REACH:
        _step(me, tn.global_position, _speed(st) * 1.15, delta)
        _anim(me, "run")
        return
    var to := tn.global_position - me.global_position
    me.rotation.y = atan2(to.x, to.z)
    if float(st["swing"]) > 0.0:
        return
    st["swing"] = SPELL_SWING
    var cls := String(st["cls"])
    var in_scar: bool = town.call("in_scar", me.global_position)
    var who := _name_of(me, st)
    if MENDERS.has(cls):
        var hurt = _most_hurt(me, SPELL_REACH)
        if hurt != null:
            var mk := Spells.cast(String(MENDERS[cls]), me, hurt, in_scar)
            Rig.play((me as Townsfolk)._anim, Spells.CAST_ANIM.get(mk, "Spellcasting"))
            _bless(hurt, mk)
            return
    var book: Array = BOOKS[cls]
    var kind: String = book[int(st.get("spell_i", 0)) % book.size()]
    st["spell_i"] = int(st.get("spell_i", 0)) + 1
    var hit: Array = [tg]
    var more: Array = []
    if kind == "chain":
        var at := tn.global_position
        for _k in range(2):
            var nx = null
            var nd := CHAIN_R
            for r in raiders:
                if hit.has(r):
                    continue
                var d := _flat((r["node"] as Node3D).global_position, at)
                if d < nd:
                    nd = d
                    nx = r
            if nx == null:
                break
            hit.append(nx)
            more.append(nx["node"])
            at = (nx["node"] as Node3D).global_position
    var actual := Spells.cast(kind, me, tn, in_scar, more)
    Rig.play((me as Townsfolk)._anim, Spells.CAST_ANIM.get(actual, "Spellcast_Shoot"))
    if not Spells.HARM.has(actual):
        # a misfire into a mending spell mends the raider - wild magic
        if actual == "heal" or actual == "renew" or actual == "mend":
            tg["hp"] = minf(float(tg["max"]), float(tg["hp"]) + float(st["atk"]) * 0.5)
        return
    var t := Spells.flight(actual, me, tn)
    get_tree().create_timer(t).timeout.connect(_spell_lands.bind(actual, hit, tn.global_position,
        float(st["atk"]), int(st["to_hit"]), who))

func _spell_lands(kind: String, hit: Array, at: Vector3, atk: float, to_hit: int, who: String) -> void:
    var first: Dictionary = hit[0]
    if kind == "fire":
        var p := at
        if raiders.has(first) and is_instance_valid(first["node"]):
            p = (first["node"] as Node3D).global_position
        for r in raiders.duplicate():
            if _flat((r["node"] as Node3D).global_position, p) <= FIRE_R:
                _spell_hurt(r, _strike(atk * 0.8, to_hit, int(r["ac"])), atk, who)
        return
    if kind == "chain":
        var k := 1.0
        for r in hit:
            if raiders.has(r):
                _spell_hurt(r, _strike(atk * k, to_hit, int(r["ac"])), atk, who)
            k *= 0.65
        return
    if not raiders.has(first):
        return
    var mult := 1.0
    if kind == "frost":
        mult = 0.7
    elif kind == "smite" and String(first.get("kind", "")) == "monster":
        mult = SMITE_DEAD
    var dmg := _strike(atk * mult, to_hit, int(first["ac"]))
    if kind == "frost" and dmg > 0.0:
        first["slow_t"] = FROST_SLOW
    _spell_hurt(first, dmg, atk, who)

func _spell_hurt(r: Dictionary, dmg: float, atk: float, who: String) -> void:
    var n: Node3D = r["node"]
    if dmg <= 0.0 or not raiders.has(r) or not is_instance_valid(n):
        return
    Sfx.at("hit", n.global_position)
    r["hp"] = float(r["hp"]) - dmg
    if n is Monster:
        (n as Monster).hp = float(r["hp"])
        (n as Monster)._number(dmg, dmg > atk)
        (n as Monster)._flash()
    if float(r["hp"]) <= 0.0:
        _raider_falls(r, who)

## the defender within reach worst off (under 60%), not already blessed
func _most_hurt(me: Node3D, reach: float):
    var best = null
    var bf := 0.6
    for d in _fighters.keys():
        if not is_instance_valid(d):
            continue
        var s: Dictionary = _fighters[d]
        if s.get("ko", false) or float(s["hp"]) <= 0.0 or float(s.get("blessed_t", 0.0)) > 0.0:
            continue
        if _flat((d as Node3D).global_position, me.global_position) > reach:
            continue
        var f := float(s["hp"]) / maxf(float(s["max"]), 1.0)
        if f < bf:
            bf = f
            best = d
    return best

func _bless(d: Node3D, kind: String) -> void:
    var s: Dictionary = _fighters.get(d, {})
    if s.is_empty():
        return
    s["blessed_t"] = Spells.RENEW_T
    match kind:
        "renew":
            s["hot_t"] = Spells.RENEW_T
            s["hot_rate"] = float(s["max"]) * RENEW_HEAL / Spells.RENEW_T
        "ward":
            s["ward"] = float(s["max"]) * WARD_SOAK
            s["ward_t"] = WARD_T
        "heal", "mend":
            s["hp"] = minf(float(s["max"]), float(s["hp"]) + float(s["max"]) * 0.25)
        _:
            pass         # a misfire into a harming spell fizzles on a friend

func _ward_soaks(ts: Dictionary, dmg: float) -> float:
    if float(ts.get("ward_t", 0.0)) <= 0.0 or float(ts.get("ward", 0.0)) <= 0.0:
        return dmg
    var soak := minf(float(ts["ward"]), dmg)
    ts["ward"] = float(ts["ward"]) - soak
    return dmg - soak

## renew mends a little every frame; wards, blessings and frost wear off
func _tick_blessings(delta: float) -> void:
    for d in _fighters.keys():
        var s: Dictionary = _fighters[d]
        for key in ["blessed_t", "ward_t"]:
            if float(s.get(key, 0.0)) > 0.0:
                s[key] = float(s[key]) - delta
        if float(s.get("hot_t", 0.0)) > 0.0 and not s.get("ko", false) and float(s["hp"]) > 0.0:
            s["hot_t"] = float(s["hot_t"]) - delta
            s["hp"] = minf(float(s["max"]), float(s["hp"]) + float(s["hot_rate"]) * delta)
    for r in raiders:
        if float(r.get("slow_t", 0.0)) > 0.0:
            r["slow_t"] = float(r["slow_t"]) - delta

func _name_of(n: Node3D, st: Dictionary) -> String:
    if st.has("name"):
        return String(st["name"])
    return String((n as Townsfolk).person_name)

func _raider_falls(r: Dictionary, _killer: String) -> void:
    raiders.erase(r)
    var n: Node3D = r["node"]
    if n is Monster:
        (n as Monster).die()
    else:
        _anim(n, "die")
        get_tree().create_timer(25.0).timeout.connect(func() -> void:
            if is_instance_valid(n):
                n.queue_free())

func _defender_falls(n: Node3D, st: Dictionary, killer: String) -> void:
    # heroes get one CON save, DC 10 (old take_damage)
    if n is HeroBody and not st.get("saved", false):
        st["saved"] = true
        var r: Roster = (n as HeroBody).roster
        var h := r.get_hero((n as HeroBody).user_id)
        var roll := randi() % 20 + 1 + r.save_bonus(h, "con")
        if roll >= 10:
            st["hp"] = 1.0
            _say("%s goes down and claws back up. (CON save %d)" % [(n as Townsfolk).person_name, roll])
            return
        _say("%s fails the save. (CON %d)" % [(n as Townsfolk).person_name, roll])
    # the grace: a green hero's first fall is a knock-out, once ever
    if n is HeroBody:
        var rg: Roster = (n as HeroBody).roster
        var hg := rg.get_hero((n as HeroBody).user_id)
        if int(hg.get("level", 1)) < GREEN_BELOW and not bool(hg.get("graced", false)):
            hg["graced"] = true
            st["ko"] = true
            st["hp"] = 0.0
            st["target"] = null
            (n as Townsfolk).stay = true
            _anim(n, "die")
            rg.changed.emit((n as HeroBody).user_id)
            _say("%s is knocked senseless, but lives. The guild's grace - once." % (n as Townsfolk).person_name)
            return
    _fighters.erase(n)
    _anim(n, "die")
    (town.get("people") as Array).erase(n)
    (n as Townsfolk).stay = true
    var who := (n as Townsfolk).person_name
    if n is HeroBody:
        (n as HeroBody).fallen = true
        var r2: Roster = (n as HeroBody).roster
        var line := r2.kill((n as HeroBody).user_id, killer, 0, 0)
        if line != "":
            _say(line)
        (town.get("heroes") as Dictionary).erase((n as HeroBody).user_id)
        var adv = town.get("adventurers")
        if adv:
            (adv.bodies as Dictionary).erase((n as HeroBody).user_id)
        get_tree().create_timer(25.0).timeout.connect(func() -> void:
            if is_instance_valid(n):
                n.queue_free())
    elif String((n as Townsfolk).role) == "chief":
        town.call("bury", n, "%s, the chief of Bellmire, is killed by %s." % [who, killer])
    else:
        town.call("bury", n, "%s is killed by %s." % [who, killer])

func _flee() -> void:
    for p in town.get("people"):
        if not is_instance_valid(p) or _fighters.has(p) or p is HeroBody:
            continue
        var f: Townsfolk = p
        if f.stay or String(f.role) in ["guard", "chief"]:
            continue
        for r in raiders:
            var hp: Vector3 = (r["node"] as Node3D).global_position
            if _flat(hp, f.global_position) < 13.0:
                var away := Vector3(f.global_position.x - hp.x, 0, f.global_position.z - hp.z).normalized()
                f._route = town.call("route", f.global_position, f.global_position + away * 16.0)
                f._enter_at = Vector3.ZERO
                f._wait = 3.0
                break

## after the raid, defenders walk back to their posts and take them up again
func _stand_down(delta: float) -> void:
    for d in _fighters.keys():
        if not is_instance_valid(d):
            _fighters.erase(d)
            continue
        var st: Dictionary = _fighters[d]
        if st.get("ko", false):
            st.erase("ko")
            st["hp"] = 1.0
            _say("%s comes round." % (d as Townsfolk).person_name)
        var post: Vector3 = st["post"]
        if _flat((d as Node3D).global_position, post) > 0.6:
            _step(d, post, float(st["speed"]), delta)
            _anim(d, "walk")
        else:
            (d as Node3D).rotation.y = float(st["yaw"])
            (d as Townsfolk).stay = bool(st["stay"])
            if not bool(st["stay"]):
                (d as Townsfolk)._route = []
            _anim(d, "idle")
            _fighters.erase(d)

func _inside_walls(p: Vector3) -> bool:
    var wi: Dictionary = town.get("_wall_info")
    var ax := float(wi.get("ax", 0.0))
    var az := float(wi.get("az", 0.0))
    if ax <= 0.0 or az <= 0.0:
        return _flat(p, town.get("_market_pos")) < 60.0
    return (p.x * p.x) / (ax * ax) + (p.z * p.z) / (az * az) < 1.0

## ------------------------------------------------------- ruin and rebuild
const RUBBLE := "res://addons/kaykit_dungeon_remastered/Assets/gltf/"

func _wreck_a_building() -> void:
    var pool: Array = []
    for plot in town.get("plots"):
        if plot.get("ruined", false) or not plot.has("node") or plot.has("landmark") \
                or plot.get("unbuilt", false) or plot.has("special"):
            continue
        if is_instance_valid(plot["node"]) and _inside_walls(plot["pos"]):
            pool.append(plot)
    if pool.is_empty():
        return
    # the raiders burn what they can reach: the nearest house to one of them
    var r: Dictionary = raiders[randi() % raiders.size()]
    var rp: Vector3 = (r["node"] as Node3D).global_position
    pool.sort_custom(func(a, b) -> bool: return _flat(a["pos"], rp) < _flat(b["pos"], rp))
    var plot: Dictionary = pool[0]
    plot["ruined"] = true
    plot["ruin"] = _ruin_at(plot)
    ruins.append(plot)
    _say("A building is burning!")

## The house is not swapped for a stock "destroyed" model (the old hex one
## would not match): it is the same house, burnt black, its frame sagged into
## its own footprint, with fallen stone at its feet.
var _char: StandardMaterial3D

func _ruin_at(plot: Dictionary) -> Node3D:
    var house: Node3D = plot["node"]
    if _char == null:
        _char = StandardMaterial3D.new()
        _char.albedo_color = Color(0.11, 0.09, 0.08)
        _char.roughness = 1.0
    plot["was"] = [house.position, house.rotation]
    var aabb := _bounds(house)
    for m in house.find_children("*", "MeshInstance3D", true, false):
        (m as MeshInstance3D).material_override = _char
    house.position.y -= aabb.size.y * 0.38
    house.rotation.z += 0.07
    house.rotation.x -= 0.04
    var holder := Node3D.new()
    holder.name = "ruin"
    town.add_child(holder)
    var c: Vector3 = plot["pos"]
    var yaw := float(plot.get("yaw", 0.0))
    var fw := Vector3(sin(yaw), 0, cos(yaw))
    var sd := Vector3(-fw.z, 0, fw.x)
    var hx := maxf(aabb.size.x, 6.0) * 0.5 + 0.6
    var hz := maxf(aabb.size.z, 6.0) * 0.5 + 0.6
    var pieces := [["rubble_half", hx, 0.0, 0.3], ["rubble_half", -hx, 1.0, 2.0], ["rubble_large", 0.8, hz, 0.9],
                   ["rubble_half", -1.5, -hz, 1.4], ["wall_broken", hx * 0.6, -hz, 0.0]]
    for pc in pieces:
        var path: String = RUBBLE + String(pc[0]) + ".gltf.glb"
        if not ResourceLoader.exists(path):
            continue
        var n: Node3D = (load(path) as PackedScene).instantiate()
        var q := c + sd * float(pc[1]) + fw * float(pc[2])
        n.position = Vector3(q.x, float(town.call("height_at", q.x, q.z)), q.z)
        n.rotation.y = yaw + float(pc[3])
        n.scale = Vector3.ONE * 0.9
        holder.add_child(n)
    var fire := _fire(c + Vector3(0, aabb.size.y * 0.25, 0), hx, hz)
    holder.add_child(fire)
    holder.set_meta("burn", 45.0)
    return holder

func _bounds(n: Node3D) -> AABB:
    var out := AABB()
    var first := true
    for m in n.find_children("*", "MeshInstance3D", true, false):
        var mi: MeshInstance3D = m
        var ab: AABB = mi.global_transform * mi.get_aabb()
        out = ab if first else out.merge(ab)
        first = false
    return out

var _soft: GradientTexture2D

func _fire(at: Vector3, hx := 3.0, hz := 3.0) -> Node3D:
    if _soft == null:
        _soft = GradientTexture2D.new()
        _soft.fill = GradientTexture2D.FILL_RADIAL
        _soft.fill_from = Vector2(0.5, 0.5)
        _soft.fill_to = Vector2(0.5, 0.0)
        var g := Gradient.new()
        g.set_color(0, Color(1, 1, 1, 1))
        g.set_color(1, Color(1, 1, 1, 0))
        _soft.gradient = g
        _soft.width = 64
        _soft.height = 64
    var root := Node3D.new()
    root.position = at
    # [colour, rise speed, amount, life, size]
    for spec in [[Color(1.0, 0.55, 0.15, 0.9), 2.4, 160, 1.3, 1.3], [Color(1.0, 0.85, 0.35, 0.8), 3.0, 60, 0.8, 0.7],
                 [Color(0.16, 0.15, 0.15, 0.55), 3.2, 70, 6.0, 4.0]]:
        var p := GPUParticles3D.new()
        p.amount = int(spec[2])
        p.lifetime = float(spec[3])
        var pm := ParticleProcessMaterial.new()
        pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
        pm.emission_box_extents = Vector3(hx * 0.6, 0.5, hz * 0.6)
        pm.direction = Vector3(0, 1, 0)
        pm.spread = 10.0
        pm.initial_velocity_min = float(spec[1]) * 0.5
        pm.initial_velocity_max = float(spec[1])
        pm.gravity = Vector3(0.4, 0.3, 0)
        pm.scale_min = float(spec[4]) * 0.6
        pm.scale_max = float(spec[4])
        var fade := Curve.new()
        fade.add_point(Vector2(0, 0.4))
        fade.add_point(Vector2(0.3, 1.0))
        fade.add_point(Vector2(1, 0.0))
        var ct := CurveTexture.new()
        ct.curve = fade
        pm.scale_curve = ct
        p.process_material = pm
        var q := QuadMesh.new()
        q.size = Vector2(1, 1)
        var m := StandardMaterial3D.new()
        m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        m.albedo_color = spec[0]
        m.albedo_texture = _soft
        m.vertex_color_use_as_albedo = true
        if (spec[0] as Color).r > 0.9:
            m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
        q.material = m
        p.draw_pass_1 = q
        root.add_child(p)
    var l := OmniLight3D.new()
    l.light_color = Color(1.0, 0.5, 0.2)
    l.light_energy = 4.0
    l.omni_range = 14.0
    l.position.y = 1.5
    root.add_child(l)
    root.name = "fire"
    return root

func _tick_ruin_fires(delta: float) -> void:
    for plot in ruins:
        var h = plot.get("ruin")
        if h == null or not is_instance_valid(h) or not (h as Node).has_meta("burn"):
            continue
        var t := float((h as Node).get_meta("burn")) - delta
        (h as Node).set_meta("burn", t)
        if t <= 0.0:
            (h as Node).remove_meta("burn")
            var f := (h as Node).get_node_or_null("fire")
            if f:
                f.queue_free()

func _rebuild_pass() -> void:
    if ruins.is_empty():
        return
    var plot: Dictionary = ruins[0]
    if economy.stock.get("wood", 0.0) < 12.0 or economy.stock.get("stone", 0.0) < 8.0:
        economy.want("wood", 12.0)
        economy.want("stone", 8.0)
        return
    economy.take("wood", 12.0)
    economy.take("stone", 8.0)
    ruins.remove_at(0)
    plot["ruined"] = false
    if is_instance_valid(plot["node"]):
        var house: Node3D = plot["node"]
        for m in house.find_children("*", "MeshInstance3D", true, false):
            (m as MeshInstance3D).material_override = null
        if plot.has("was"):
            house.position = plot["was"][0]
            house.rotation = plot["was"][1]
            plot.erase("was")
    if plot.get("ruin") != null and is_instance_valid(plot["ruin"]):
        (plot["ruin"] as Node).queue_free()
    plot.erase("ruin")
    _say("The townsfolk raise the ruin again.")

## ------------------------------------------------------- tower archers (D4)
## The watchtower crossbowmen keep their towers (they never join the melee) but
## no longer only watch: every BOW_SWING s each looses a bolt at the nearest
## raider within BOW_REACH. The bolt flies (ARROW_V m/s, a shallow arc) and the
## d20 is rolled when it lands, like the casters' spells.
const BOW_REACH := 42.0
const BOW_SWING := 2.4
const BOW_ATK := 9.0
const BOW_TO_HIT := 3
const ARROW_V := 40.0
var _bows := {}
var arrows_loosed := 0
var arrows_hit := 0
var _bolt_mat: StandardMaterial3D

func _volley(delta: float) -> void:
    for p in town.get("people"):
        if not is_instance_valid(p) or not (p is Townsfolk) or not (p as Node3D).visible:
            continue
        if String((p as Townsfolk).gear_role) != "lookout":
            continue
        var t := float(_bows.get(p, randf_range(0.2, BOW_SWING))) - delta
        _bows[p] = t
        if t > 0.0:
            continue
        var me: Vector3 = (p as Node3D).global_position
        var best = null
        var bd := BOW_REACH
        for r in raiders:
            var d := _flat((r["node"] as Node3D).global_position, me)
            if d < bd and d > 1.0:
                bd = d
                best = r
        if best == null:
            _bows[p] = 0.5
            continue
        _bows[p] = BOW_SWING + randf_range(-0.3, 0.3)
        _loose(p, best)

func _loose(archer: Townsfolk, r: Dictionary) -> void:
    var tn: Node3D = r["node"]
    var from: Vector3 = archer.global_position + Vector3(0, 1.35, 0)
    var to: Vector3 = tn.global_position + Vector3(0, (Spells.body_height(tn) * 0.6) if tn is Monster else 1.2, 0)
    archer.rotation.y = atan2(to.x - from.x, to.z - from.z)
    Rig.play(archer._anim, "2H_Ranged_Shoot", 0.1)
    arrows_loosed += 1
    if _bolt_mat == null:
        _bolt_mat = StandardMaterial3D.new()
        _bolt_mat.albedo_color = Color(0.36, 0.24, 0.12)
    var bolt := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 0.03
    cm.bottom_radius = 0.03
    cm.height = 0.85
    cm.radial_segments = 6
    bolt.mesh = cm
    bolt.material_override = _bolt_mat
    town.add_child(bolt)
    var dist := from.distance_to(to)
    var fl := maxf(dist / ARROW_V, 0.12)
    var arc := dist * 0.05
    var fly := func(k: float) -> void:
        if not is_instance_valid(bolt):
            return
        var a := from.lerp(to, k) + Vector3.UP * sin(k * PI) * arc
        var b := from.lerp(to, minf(k + 0.05, 1.0)) + Vector3.UP * sin(minf(k + 0.05, 1.0) * PI) * arc
        bolt.global_position = a
        if a.distance_to(b) > 0.001 and absf((b - a).normalized().y) < 0.98:
            bolt.look_at(b, Vector3.UP)
            bolt.rotate_object_local(Vector3.RIGHT, PI * 0.5)
    fly.call(0.0)
    Sfx.at("swing", from, -8.0)
    var tw := town.create_tween()
    tw.tween_method(fly, 0.0, 1.0, fl)
    tw.tween_callback(func() -> void:
        if is_instance_valid(bolt):
            bolt.queue_free()
        _bolt_lands(r, archer.person_name if is_instance_valid(archer) else "a tower archer"))

func _bolt_lands(r: Dictionary, who: String) -> void:
    if not raiders.has(r):
        return
    var tn: Node3D = r["node"]
    var dmg := _strike(BOW_ATK, BOW_TO_HIT, int(r["ac"]))
    if dmg <= 0.0:
        return
    arrows_hit += 1
    Sfx.at("hit", tn.global_position, -3.0)
    r["hp"] = float(r["hp"]) - dmg
    if tn is Monster:
        (tn as Monster).hp = float(r["hp"])
        (tn as Monster)._number(dmg, dmg > BOW_ATK)
        (tn as Monster)._flash()
    if float(r["hp"]) <= 0.0:
        _raider_falls(r, who)
