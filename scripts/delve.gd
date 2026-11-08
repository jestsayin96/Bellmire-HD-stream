class_name Delve
extends Node3D
## A party's descent. Floors are built far below the valley (DELVE_Y) so the
## town keeps running above. Rules come from the ported Roster (5e to-hit:
## d20 + attack_bonus vs AC, damage from Roster.attack, max_hp, heal_power,
## one death save per delve, permadeath -> Roster.kill -> memorial) and the
## Bestiary (depth bands, strains, the lords on every fifth floor).
## Chronicle lines go to town.feed - canon word order (origin first, then the
## biome it was remade as) and never a floor count.

signal ended(survivors: Array)

const DELVE_Y := -400.0
const REACH := 1.9
var town: Node3D
var roster: Roster
var party: Array = []            # [{uid, h, body, hp, max, saved, swing}]
var floor_no := 0
var dun: DungeonHD
var state := "enter"
var _t := 0.0
var _kills := 0
var _gold := 0
var kit_bonus := 0.0      # gear drawn from the town rack at the muster
## ---- light (ported from the old expedition.gd). Burn is PER FLOOR, never per
## second: a floor is a floor on any machine. Each hero empties their own
## satchel into the party's at the mouth; one flask per two bodies a floor,
## half a flask to search one. Out of oil it goes dark: heroes swing at
## disadvantage, everything down there at advantage - and a party in the dark
## goes home after the floor it is on.
var oil := 0.0
var dark := false
var _warned_low := false
var haul := {"ore": 0.0, "stone": 0.0, "gear": 0.0, "potion": 0.0}
var _rng := RandomNumberGenerator.new()
var turn_back_at := 0.35         # mean hp fraction at which the party retreats

var start_floor := 1
var npc_party := false           # the town's own band: no viewer gold
var lane := 0                    # parallel delves sit side by side, 700 m apart

func start(uids: Array) -> void:
    _rng.randomize()
    for uid in uids:
        var h: Dictionary = roster.get_hero(uid)
        if h.is_empty() or not bool(h["alive"]):
            continue
        var b := HeroBody.new()
        b.npc = npc_party
        b.setup(roster, uid)
        b.town = self
        b.stay = true
        add_child(b)
        var mx := roster.max_hp(h)
        party.append({"uid": uid, "h": h, "body": b, "hp": mx, "max": mx, "saved": false, "swing": _rng.randf()})
        if b.has_method("compact"):
            b.call_deferred("compact", true)
    _say("%s %s into the scar." % [_names(), "descends" if party.size() == 1 else "descend"])
    for m in party:
        oil += float(int(m["h"].get("oil", 0)))
        m["h"]["oil"] = 0
    _say("They carry %d flask%s of oil between them." % [int(oil), "" if int(oil) == 1 else "s"])
    floor_no = start_floor - 1
    if is_inside_tree():
        _next_floor()
    else:
        call_deferred("_next_floor")

func _names_of(uids: Array) -> String:
    var n: Array = []
    for m in party:
        if uids.has(m["uid"]):
            n.append(String(m["h"]["name"]))
    return ", ".join(n) if n.size() < 3 else "%s and %d others" % [n[0], n.size() - 1]

func _names() -> String:
    var n: Array = []
    for m in party:
        n.append(String(m["h"]["name"]))
    return ", ".join(n) if n.size() < 3 else "%s and %d others" % [n[0], n.size() - 1]

func _say(line: String) -> void:
    if town:
        (town.get("feed") as Array).append(line)
    print("FEED ", line)

## height_at for the hero bodies: dungeon floors are flat
func height_at(_x: float, _z: float) -> float:
    return DELVE_Y + 0.05

func _alive() -> Array:
    var out: Array = []
    for m in party:
        if float(m["hp"]) > 0.0:
            out.append(m)
    return out

func _next_floor() -> void:
    floor_no += 1
    if dun:
        dun.queue_free()
    dun = DungeonHD.new()
    dun.floor_no = floor_no
    dun.position = Vector3(float(lane) * 700.0, DELVE_Y, 0)
    add_child(dun)
    if dun.info.is_empty():
        dun.build(floor_no)
    # FloorGen's entry/exit are relative to the floor's own origin
    var entry: Vector3 = dun.info["entry"] + dun.global_position
    var i := 0
    for m in _alive():
        var b: HeroBody = m["body"]
        b.global_position = entry + Vector3(float(i % 3) - 1.0, 0, float(i / 3)) * 1.4
        i += 1
    # monster numbers scale with depth (Bestiary multipliers on a floor base)
    for mon in dun.monsters:
        var M: Monster = mon
        M.max_hp = (14.0 + float(floor_no) * 6.0) * float(M.def.get("hp", 1.0))
        M.hp = M.max_hp
    if dun.lord:
        dun.lord.max_hp = float(dun.lord.def.get("boss_hp", 200.0))
        dun.lord.hp = dun.lord.max_hp
    # a floor costs one flask per two bodies
    var alive_now := _alive().size()
    oil = maxf(0.0, oil - float(maxi(1, int(ceil(float(alive_now) * 0.5)))))
    var origin_key := FloorGen.origin_for(floor_no)
    var of := String((FloorGen.ORIGINS.get(origin_key, {}) as Dictionary).get("of", "a ruin"))
    var biome := String(dun.info.get("theme_name", "the dark"))
    var line := "Floor %d - %s, remade as %s: %s." % [floor_no, of, biome, _census()]
    _say(line)
    if dun.lord:
        # NOT capitalize(): it title-cases every word (origins.json warns about this)
        var note := String(dun.lord.def.get("note", ""))
        if note != "":
            note = note.substr(0, 1).to_upper() + note.substr(1) + "."
        _say("%s rises. %s" % [dun.lord.def.get("name", "A lord"), note])
    if not dark and not _warned_low and oil > 0.0 and oil <= float(alive_now):
        _warned_low = true
        _say("The oil is running low.")
    _lamp_lit = false
    _light_check()
    state = "fight"

## ---- the wizard's lamp-stand (old expedition._check_lamp / _light_check).
## Dead centre of every floor (FloorGen puts it there). A hero who reaches it
## sets it burning: the floor is lit even with an empty satchel. It never
## refills the satchel - it changes how a floor FIGHTS, never how deep a party
## can go - and it only matters once they are in the dark.
const LAMP_REACH := 5.0
var _lamp_lit := false
var lamps_lit := 0

func _light_check() -> void:
    var now := oil < 1.0 and not _lamp_lit
    if now != dark:
        dark = now
        if dark:
            # THE ARCHITECT'S BELLS: the final lantern guttering out anywhere
            _say("Somewhere below, a bell with no clapper rings once. The dungeon is one floor deeper than it was.")
            _say("The last lantern gutters out. They are fighting blind.")
    _apply_light()

func _check_lamp() -> void:
    if _lamp_lit or dun == null or not dun.info.has("lamp"):
        return
    var lamp: Vector3 = dun.info["lamp"] + dun.global_position
    for m in _alive():
        var b: Node3D = m["body"]
        if _flat(b.global_position, lamp) > LAMP_REACH:
            continue
        _lamp_lit = true
        lamps_lit += 1
        # "Don't touch the architect's toys." - one lighting in six
        if _rng.randf() < 0.17:
            _say("A brass hand-bell rests against the stand. It has no clapper. Nobody touches it.")
        if dark:
            _say("%s sets the wizard's lamp burning. The dark pulls back from floor %d." % [m["h"]["name"], floor_no])
        var l := OmniLight3D.new()
        l.name = "wizard_lamp"
        l.light_color = Color(1.0, 0.86, 0.62)
        l.light_energy = 11.0
        l.omni_range = 26.0
        l.set_meta("e0", 11.0)
        dun.add_child(l)
        l.global_position = lamp + Vector3(0, 2.4, 0)
        _light_check()
        return

## health bars: everyone in a fight, and anyone not at full health
func _bars(foes: Array) -> void:
    for m in party:
        var b = m["body"]
        if not is_instance_valid(b):
            continue
        var near := false
        for f in foes:
            if _flat((f as Node3D).global_position, (b as Node3D).global_position) < 10.0:
                near = true
                break
        HealthBar3D.on(b, 2.05, false).set_hp(float(m["hp"]), float(m["max"]), near)
    for f in foes:
        var mo: Monster = f
        var near2 := false
        for m2 in _alive():
            if _flat((m2["body"] as Node3D).global_position, mo.global_position) < 10.0:
                near2 = true
                break
        HealthBar3D.on(mo, mo._height() + 0.25, true).set_hp(mo.hp, mo.max_hp, near2)

## the dark is shown, not just rolled: the floor's own lights sink to embers
func _apply_light() -> void:
    if dun == null:
        return
    for n in dun.find_children("*", "Light3D", true, false):
        if n.name == "wizard_lamp":
            continue
        var L: Light3D = n
        if not L.has_meta("e0"):
            L.set_meta("e0", L.light_energy)
        L.light_energy = float(L.get_meta("e0")) * (0.22 if dark else 1.0)

func _d20(adv: int) -> int:
    var a := _rng.randi_range(1, 20)
    if adv == 0:
        return a
    var b := _rng.randi_range(1, 20)
    return maxi(a, b) if adv > 0 else mini(a, b)

func _census() -> String:
    var counts := {}
    for mon in dun.monsters:
        var nm := String((mon as Monster).def.get("name", "thing"))
        counts[nm] = int(counts.get(nm, 0)) + 1
    var parts: Array = []
    for k in counts:
        var nm := String(k)
        parts.append("%d %s" % [counts[k], nm if int(counts[k]) == 1 or nm.ends_with("s") else nm + "s"])
    return ", ".join(parts) if not parts.is_empty() else "nothing stirring"

func _foes() -> Array:
    var out: Array = []
    for mon in dun.monsters:
        if is_instance_valid(mon) and (mon as Monster).state != Monster.S.DEAD:
            out.append(mon)
    if dun.lord and is_instance_valid(dun.lord) and dun.lord.state != Monster.S.DEAD and not dun.lord._entering():
        out.append(dun.lord)
    return out

## ---------------------------------------------------------------- pathing
## Through the floor's occupancy grid (FloorGen cells), never through walls or
## across the void between rooms. Routes are cached and refreshed twice a second.
var _paths := {}                   # node -> [cells(world pts), t]

func _cell_of(p: Vector3) -> Vector2i:
    var G: float = dun.info["grid"]
    var hw := (float(dun.info["w"]) - 1.0) * G * 0.5
    var hh := (float(dun.info["h"]) - 1.0) * G * 0.5
    var o := dun.global_position
    return Vector2i(int(round((p.x - o.x + hw) / G)), int(round((p.z - o.z + hh) / G)))

func _cell_world(c: Vector2i) -> Vector3:
    var G: float = dun.info["grid"]
    var hw := (float(dun.info["w"]) - 1.0) * G * 0.5
    var hh := (float(dun.info["h"]) - 1.0) * G * 0.5
    return dun.global_position + Vector3(float(c.x) * G - hw, 0.05, float(c.y) * G - hh)

func _bfs(a: Vector2i, b: Vector2i) -> Array:
    var cells: Dictionary = dun.info["cells"]
    if not cells.has(a) or not cells.has(b):
        return []
    var prev := {a: a}
    var q: Array[Vector2i] = [a]
    while not q.is_empty():
        var c: Vector2i = q.pop_front()
        if c == b:
            break
        for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
            var n: Vector2i = c + d
            if cells.has(n) and not prev.has(n):
                prev[n] = c
                q.append(n)
    if not prev.has(b):
        return []
    var out: Array = []
    var cur := b
    while cur != a:
        out.push_front(_cell_world(cur))
        cur = prev[cur]
    return out

## nearest floor cell to c (rings outward), or c itself if it is floor
func _snap_cell(c: Vector2i) -> Vector2i:
    var cells: Dictionary = dun.info["cells"]
    if cells.has(c):
        return c
    for r in range(1, 12):
        var best := Vector2i(-9999, -9999)
        var bd := 1e9
        for dx in range(-r, r + 1):
            for dz in range(-r, r + 1):
                if absi(dx) != r and absi(dz) != r:
                    continue
                var n := c + Vector2i(dx, dz)
                if cells.has(n):
                    var dd := float(dx * dx + dz * dz)
                    if dd < bd:
                        bd = dd
                        best = n
        if best.x != -9999:
            return best
    return c

## move n toward `to` along the grid; true when within `stop` of it. Bodies
## only ever walk floor cells: a goal off the floor (a ring slot behind a wall,
## a point in the void between rooms) is moved to the nearest floor cell, and
## nobody takes a straight line across anything that is not floor.
func _go(n: Node3D, to: Vector3, spd: float, delta: float, stop := 0.3) -> bool:
    var cells: Dictionary = dun.info["cells"]
    var cb_raw := _cell_of(to)
    var cb := _snap_cell(cb_raw)
    if cb != cb_raw:
        to = Vector3(_cell_world(cb).x, to.y, _cell_world(cb).z)
    if _flat(n.global_position, to) <= stop:
        return true
    var ca_raw := _cell_of(n.global_position)
    var ca := _snap_cell(ca_raw)
    if ca != ca_raw:
        # somehow off the floor: step straight back onto the nearest cell
        _step(n, _cell_world(ca), spd, delta)
        return false
    if ca == cb:
        _step(n, to, spd, delta)
        return false
    var e: Array = _paths.get(n, [])
    if e.is_empty() or _t - float(e[1]) > 0.5 or (e[0] as Array).is_empty():
        e = [_bfs(ca, cb), _t]
        _paths[n] = e
    var pts: Array = e[0]
    if pts.is_empty():
        return false          # no way through: wait rather than walk a wall
    var nxt: Vector3 = pts[0]
    nxt.y = n.global_position.y
    var before := _flat(n.global_position, nxt)
    var arrived := _step(n, nxt, spd, delta)
    var after := _flat(n.global_position, nxt)
    # a waypoint inside a table can never be reached: count it as reached
    # once the body can get no closer (it is pressed against the furniture)
    if arrived or after < 0.4 or (after < 3.0 and before - after < spd * delta * 0.2):
        pts.remove_at(0)
    return false

func _flat(a: Vector3, b: Vector3) -> float:
    return Vector2(a.x - b.x, a.z - b.z).length()

func _step(n: Node3D, to: Vector3, spd: float, delta: float) -> bool:
    var d := Vector3(to.x - n.global_position.x, 0, to.z - n.global_position.z)
    if d.length() < 0.05:
        return true
    var p := n.global_position + d.normalized() * minf(spd * delta, d.length())
    # bodies go AROUND what stands on the floor: pushed out of every table,
    # barrel, pillar and tree they would walk into - so they slide past it
    if dun and dun.info.has("obstacles"):
        var o0 := dun.global_position
        var cells: Dictionary = dun.info["cells"]
        var step_len := minf(spd * delta, d.length())
        for o in dun.info["obstacles"]:
            var c: Vector3 = (o[0] as Vector3) + o0
            var need := float(o[1]) + 0.45
            var dd := Vector2(p.x - c.x, p.z - c.z)
            if dd.length() >= need:
                continue
            var dir := dd.normalized() if dd.length() > 0.01 else Vector2(d.z, -d.x).normalized()
            var pushed := Vector3(c.x + dir.x * need, p.y, c.z + dir.y * need)
            if cells.has(_cell_of(pushed)):
                p = pushed
                continue
            # pushing out would cross a wall: slide round the obstacle on the
            # floor side instead (whichever way round heads toward the goal)
            var tan := Vector2(-dir.y, dir.x)
            if tan.dot(Vector2(d.x, d.z)) < 0.0:
                tan = -tan
            var slide := n.global_position + Vector3(tan.x, 0, tan.y) * step_len
            if cells.has(_cell_of(slide)):
                p = slide
            else:
                p = n.global_position       # hold rather than go through stone
    p.y = n.global_position.y
    # last guard: a step that would end beyond the walls is not taken
    if dun and dun.info.has("cells") and not (dun.info["cells"] as Dictionary).has(_cell_of(p)) \
            and (dun.info["cells"] as Dictionary).has(_cell_of(n.global_position)):
        return false
    n.global_position = p
    n.rotation.y = atan2(d.x, d.z)
    return _flat(p, to) < 0.05

func _process(delta: float) -> void:
    if dun == null or not is_instance_valid(dun):
        return
    _t += delta
    match state:
        "fight":
            _fight(delta)
        "descend":
            var ex: Vector3 = dun.info["exit"] + dun.global_position
            var all_there := true
            for m in _alive():
                var b: HeroBody = m["body"]
                if not _go(b, ex, 5.0, delta, 0.8):
                    all_there = false
                    Rig.play(b._anim, "Walking_A")
            if all_there or _t > 6.0:
                _next_floor()
        "home":
            pass

func _fight(delta: float) -> void:
    _check_lamp()
    var foes := _foes()
    _bars(foes)
    var alive := _alive()
    if alive.is_empty():
        _say("The scar keeps them all. No one comes home from floor %d." % floor_no)
        _finish()
        return
    if foes.is_empty() and not (dun.lord and dun.lord._entering()):
        # floor won: pay out, decide whether to press on
        _loot(alive)
        var frac := 0.0
        for m in alive:
            frac += float(m["hp"]) / float(m["max"])
        frac /= float(alive.size())
        if oil < 1.0:
            _say("Out of oil, the party feels its way back up from floor %d." % floor_no)
            _finish()
        elif frac < turn_back_at or floor_no >= max_floors:
            _say("Battered, the party climbs back out from floor %d." % floor_no)
            _finish()
        else:
            # a breather: clerics and sages mend between floors
            for m in alive:
                m["hp"] = minf(float(m["max"]), float(m["hp"]) + float(m["max"]) * 0.25)
            state = "descend"
            _t = 0.0
        return
    for m in alive:
        var b: HeroBody = m["body"]
        var h: Dictionary = m["h"]
        # healers mend whoever is lowest first
        var hp_pow := roster.heal_power(h)
        if hp_pow > 0.0:
            var low = null
            for o in alive:
                if float(o["hp"]) < float(o["max"]) * 0.55 and (low == null or float(o["hp"]) < float(low["hp"])):
                    low = o
            m["swing"] = float(m["swing"]) - delta
            if low != null and float(m["swing"]) <= 0.0:
                m["swing"] = 2.4
                low["hp"] = minf(float(low["max"]), float(low["hp"]) + hp_pow)
                Spells.cast("heal", b, (low["body"] as Node3D).global_position, false)
                continue
        var tgt: Monster = null
        var bd := 1e9
        for f in foes:
            var d := _flat((f as Node3D).global_position, b.global_position)
            if d < bd:
                bd = d
                tgt = f
        if tgt == null:
            continue
        var caster := String(h["class"]) in ["mage", "sage", "cleric"]
        var ranged := caster or String(h["class"]) == "ranger"
        var reach := 9.0 if ranged else REACH + tgt._height() * 0.15
        if bd > reach:
            # each hero takes their own side of the target instead of one point
            var slot := float(party.find(m)) * TAU / float(maxi(party.size(), 1))
            var ring := Vector3(cos(slot), 0, sin(slot)) * (1.4 + tgt._height() * 0.25 if not ranged else 5.0)
            _go(b, tgt.global_position + ring, roster.speed(h) * 0.9, delta)
            Rig.play(b._anim, "Running_A")
            continue
        b.rotation.y = atan2(tgt.global_position.x - b.global_position.x, tgt.global_position.z - b.global_position.z)
        m["swing"] = float(m["swing"]) - delta
        if float(m["swing"]) > 0.0:
            continue
        m["swing"] = 1.3 + _rng.randf() * 0.4
        # 5e: d20 + attack bonus vs the creature's AC (10 + depth band)
        var roll := _d20(-1 if dark else 0)
        var ac := 10 + floor_no / 2 + (3 if tgt.def.get("boss", false) else 0)
        if caster:
            Spells.cast("bolt", b, tgt.global_position + Vector3(0, tgt._height() * 0.5, 0), false)
            Rig.play(b._anim, "Spellcast_Shoot")
        else:
            Rig.play(b._anim, "1H_Melee_Attack_Chop" if String(h["class"]) != "ranger" else "1H_Ranged_Shoot")
        if roll == 20 or (roll != 1 and roll + roster.attack_bonus(h) >= ac):
            var dmg := (roster.attack(h) * _rng.randf_range(0.55, 0.95) + kit_bonus) * (2.0 if roll == 20 else 1.0)
            var was_dead := tgt.state == Monster.S.DEAD
            tgt.hurt(dmg, roll == 20)
            if not was_dead and tgt.state == Monster.S.DEAD:
                _kills += 1
                roster.award(String(m["uid"]), 3 + floor_no, 6 + floor_no * 2, 1, floor_no)
                if tgt.def.get("boss", false):
                    _say("%s falls to %s." % [tgt.def.get("name"), h["name"]])
    # the creatures answer
    for f in foes:
        var mon: Monster = f
        if not is_instance_valid(mon) or mon.state == Monster.S.DEAD:
            continue   # killed earlier this same tick: never stand it back up
        var near = null
        var nd := 1e9
        for m in alive:
            var d := _flat((m["body"] as Node3D).global_position, mon.global_position)
            if d < nd:
                nd = d
                near = m
        if near == null:
            continue
        var r := REACH + mon._height() * 0.2
        mon.state = Monster.S.IDLE
        if nd > r:
            _go(mon, (near["body"] as Node3D).global_position, float(mon.def.get("spd", 3.0)) * 0.7, delta)
            mon._play("walk")
            continue
        mon.rotation.y = atan2((near["body"] as Node3D).global_position.x - mon.global_position.x, (near["body"] as Node3D).global_position.z - mon.global_position.z)
        mon._swing -= delta
        if mon._swing > 0.0:
            continue
        mon._swing = 1.8 if not mon.def.get("boss", false) else 1.4
        mon._play("attack")
        var hit := _d20(1 if dark else 0) + 2 + floor_no / 2
        if hit >= roster.armour_class(near["h"]):
            var base := float(mon.def.get("boss_atk", (6.0 + float(floor_no) * 2.2) * float(mon.def.get("atk", 1.0))))
            near["hp"] = float(near["hp"]) - base * _rng.randf_range(0.6, 1.0)
            _hero_hit(near)

## Gold is PERSONAL (old rule): a lord's hoard is split between the heroes who
## brought it down; anything else found belongs to whoever prised it open, and
## searching costs half a flask. Materials go home to the town.
func _loot(alive: Array) -> void:
    var boss := dun.lord != null
    var found := int(float(floor_no) * 11.0 * (3.0 if boss else 1.0) * _rng.randf_range(0.85, 1.35))
    if boss:
        var share := int(float(found) / float(alive.size()))
        var took: Array = []
        for m in alive:
            roster.award(String(m["uid"]), share, 0, 0, floor_no)
            took.append(String(m["h"]["name"]))
        _gold += share * alive.size()
        _say("%s is slain on floor %d!" % [dun.lord.def.get("name", "The lord"), floor_no])
        _say("The hoard is split %d ways - %d gold each to %s." % [took.size(), share, ", ".join(took)])
    else:
        var f: Dictionary = alive[_rng.randi() % alive.size()]
        roster.award(String(f["uid"]), found, 0, 0, floor_no)
        _gold += found
        oil = maxf(0.0, oil - 0.5)
        _say("%s turns up %d gold on floor %d." % [f["h"]["name"], found, floor_no])
        _say("Floor %d cleared." % floor_no)
    # renown (old rule): a floor cleared +1, a lord slain +6
    var eco = town.get("economy") if town else null
    if eco:
        eco.renown += 6 if boss else 1
    haul["ore"] += floor_no * 0.6
    haul["stone"] += floor_no * 0.45
    if _rng.randf() < 0.32 + floor_no * 0.03:
        haul["gear"] += 1.0
    if _rng.randf() < 0.4:
        haul["potion"] += 1.0
    # clearing a floor is the unit of progress: everyone standing learns from it
    for m in alive:
        roster.award(String(m["uid"]), 0, floor_no * 5, 0, floor_no)

func _haul_line() -> String:
    var bits: Array = ["%d gold" % _gold]
    for k in ["ore", "stone"]:
        if int(haul[k]) > 0:
            bits.append("%d %s" % [int(haul[k]), k])
    if int(haul["gear"]) > 0:
        bits.append("%d piece%s of salvaged gear" % [int(haul["gear"]), "" if int(haul["gear"]) == 1 else "s"])
    if int(haul["potion"]) > 0:
        bits.append("%d potion%s" % [int(haul["potion"]), "" if int(haul["potion"]) == 1 else "s"])
    return ", ".join(bits.slice(0, bits.size() - 1)) + (" and " if bits.size() > 1 else "") + String(bits[-1])

func _hero_hit(m: Dictionary) -> void:
    var b: HeroBody = m["body"]
    Rig.play(b._anim, "Hit_A")
    if float(m["hp"]) > 0.0:
        return
    # one death save per delve (old rule): claw back to 1 hp on a DC 10 CON save
    if not bool(m["saved"]):
        m["saved"] = true
        var s := _rng.randi_range(1, 20) + roster.save_bonus(m["h"], "con")
        if s >= 10:
            m["hp"] = 1.0
            _say("%s should be dead - and stands back up." % m["h"]["name"])
            return
    Rig.play(b._anim, "Death_A")
    b.fallen = true
    var line := roster.kill(String(m["uid"]), "the dark below", floor_no, 0)
    _say(line)

var max_floors := 99      # test hook; canon never states one

func _finish() -> void:
    for m in party:
        var bb = m["body"]
        if is_instance_valid(bb) and bb.has_method("compact"):
            bb.compact(false)
    state = "home"
    var out: Array = []
    for m in _alive():
        out.append(m["uid"])
    if not out.is_empty():
        _say("%s %s home to Bellmire with %s. %d %s." % [_names_of(out), "comes" if out.size() == 1 else "come", _haul_line(), _kills, ("kill" if _kills == 1 else "kills") + ("" if out.size() == 1 and party.size() == 1 else " between them")])
        if town and town.has_method("receive_haul"):
            town.receive_haul(haul)
    ended.emit(out)
