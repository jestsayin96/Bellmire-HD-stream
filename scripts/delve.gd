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
	_say(_pick_line("descend", "%s %s into the scar.") % [_names(), "descends" if party.size() == 1 else "descend"])
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
	Bestiary.memorial = roster.fallen if roster else []
	dun.position = Vector3(float(lane) * 700.0, DELVE_Y, 0)
	add_child(dun)
	if dun.info.is_empty():
		dun.build(floor_no)
	# FloorGen's entry/exit are relative to the floor's own origin
	var entry: Vector3 = dun.info["entry"] + dun.global_position
	var i := 0
	for m in _alive():
		var b: HeroBody = m["body"]
		var at := entry + Vector3(float(i % 3) - 1.0, 0, float(i / 3)) * 1.4
		# a big party's back rows can land past the wall by the stairs: on the floor or at the entry
		if not (dun.info["cells"] as Dictionary).has(_cell_of(at)):
			at = entry + Vector3(float(i % 3) - 1.0, 0, 0) * 0.5
		if not (dun.info["cells"] as Dictionary).has(_cell_of(at)):
			at = entry
		b.global_position = at
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
	# L19: the old budget - one tell a delve, on its first floor (the origin's own, or one of lore_lines)
	if floor_no == start_floor:
		var tells: Array = [String((FloorGen.ORIGINS.get(origin_key, {}) as Dictionary).get("tell", ""))]
		tells.append_array((lore().get("tells", {}) as Dictionary).get(origin_key, []))
		tells = tells.filter(func(s): return String(s) != "")
		if not tells.is_empty():
			_say(String(tells[_rng.randi() % tells.size()]))
		_bark_any("enter")
	if dun.lord:
		# NOT capitalize(): it title-cases every word (origins.json warns about this)
		var note := String(dun.lord.def.get("note", ""))
		if note != "":
			note = note.substr(0, 1).to_upper() + note.substr(1) + "."
		var uniq := bool(dun.lord.def.get("unique", false))
		_say(("%s is down here. %s" if uniq else "%s rises. %s") % [dun.lord.def.get("name", "A lord"), note])
		var intro := String((lore().get("unique_intros" if uniq else "lord_intros", {}) as Dictionary).get(String(dun.lord.def.get("id", "")), ""))
		if intro != "":
			_say(intro)
		_bark_any("lord")
		# L12: a lord rising - a WIS save (DC 10 + floor/2) or frightened a while
		if not uniq:
			for m in _alive():
				if _rng.randi_range(1, 20) + roster.save_bonus(m["h"], "wis") < mini(20, 10 + floor_no / 2):
					_give(m, "frightened", 6.0)
		Monster.roar(dun.lord)          # S2: the lord's voice as it rises (the card, the director and the spotlight cut to it)
		FeedHUD.card_on(town, String(dun.lord.def.get("name", "A lord")),
			(("A rare thing on floor %d. %s" if uniq else "Lord of floor %d. %s") % [floor_no, note]).strip_edges(), dun.lord.def.get("aura", Color(1, 0.8, 0.4)))
	if not dark and not _warned_low and oil > 0.0 and oil <= float(alive_now):
		_warned_low = true
		_say("The oil is running low.")
	_initiative()
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

func _party_uids(ms: Array) -> Array:
	var out: Array = []
	for m in ms:
		out.append(m["uid"])
	return out

## the floor's lord while it is up and fighting (risen, alive), else null:
## the boss bar and the director watch this
func lord_fighting() -> Monster:
	if state != "fight" or dun == null or not is_instance_valid(dun) or _alive().is_empty():
		return null
	if dun.lord == null or not is_instance_valid(dun.lord):
		return null
	var l: Monster = dun.lord
	if l.state == Monster.S.DEAD or l._entering():
		return null
	return l

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

## L25c: the cells a body cannot stand in the middle of (an obstacle covers the centre),
## worked out once a floor
var _blocked_for: Node = null
var _blocked := {}
func _blocked_cells() -> Dictionary:
	if _blocked_for == dun:
		return _blocked
	_blocked_for = dun
	_blocked = {}
	var cells: Dictionary = dun.info["cells"]
	for c: Vector2i in cells:
		var w := _cell_world(c) - dun.global_position
		for o in dun.info.get("obstacles", []):
			if Vector2(w.x - (o[0] as Vector3).x, w.z - (o[0] as Vector3).z).length() < float(o[1]) + 0.45:
				_blocked[c] = true
				break
	return _blocked

## the route through the floor's cells, around the cells furniture blocks (the plain grid if
## that leaves no way through)
func _bfs(a: Vector2i, b: Vector2i) -> Array:
	var r := _bfs_on(a, b, _blocked_cells())
	return r if not r.is_empty() or a == b else _bfs_on(a, b, {})

func _bfs_on(a: Vector2i, b: Vector2i, avoid: Dictionary) -> Array:
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
			if cells.has(n) and not prev.has(n) and (not avoid.has(n) or n == b):
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
## L25: who is on the move this frame (body -> frame), and how often a party was carried to the
## stairs because someone could not get there (tests read both - a stuck delver used to be hidden
## by the descent timeout)
var travel := {}
var forced := 0
var _prog := {}            # body -> [the nearest it has got to its goal, when]

## L25: no closer to where it is going for `secs` (it is pressed against something)
func stuck_on(n: Node3D, secs := 1.2) -> bool:
	var p: Array = _prog.get(n, [])
	return not p.is_empty() and _t - float(p[1]) > secs

func _go(n: Node3D, to: Vector3, spd: float, delta: float, stop := 0.3) -> bool:
	travel[n] = Engine.get_process_frames()
	var cells: Dictionary = dun.info["cells"]
	var cb_raw := _cell_of(to)
	var cb := _snap_cell(cb_raw)
	if cb != cb_raw:
		to = Vector3(_cell_world(cb).x, to.y, _cell_world(cb).z)
	# L25c: a goal inside furniture can never be reached (a ranged delver's side of a lord
	# beside the hoard) - the nearest clear cell instead
	if n is HeroBody and _blocked_cells().has(cb):
		var bd2 := 1e9
		var alt := cb
		for c: Vector2i in dun.info["cells"]:
			if not _blocked_cells().has(c):
				var d2 := Vector2(c - cb).length()
				if d2 < bd2:
					bd2 = d2
					alt = c
		cb = alt
		to = Vector3(_cell_world(cb).x, to.y, _cell_world(cb).z)
	var dist_to := _flat(n.global_position, to)
	if dist_to <= stop:
		travel.erase(n)           # arrived: not on the move
		_prog.erase(n)
		return true
	var pg: Array = _prog.get(n, [])
	if pg.is_empty() or dist_to < float(pg[0]) - 0.2 or absf(dist_to - float(pg[0])) > 12.0:
		_prog[n] = [dist_to, _t]     # progress (or a new goal far from the old one)
	elif _t - float(pg[1]) > 2.0:
		_unstick(n)
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
	# a creature has a body, not a point: it keeps its own half-width off any
	# wall (big lords and wide beasts were walking half into the stone)
	if n is Monster and dun and dun.info.has("cells"):
		var rad := float(n.get_meta("rad", -1.0))
		if rad < 0.0:
			rad = clampf((n as Monster)._height() * 0.2, 0.3, 1.8)
			n.set_meta("rad", rad)
		var G: float = dun.info["grid"]
		var cl: Dictionary = dun.info["cells"]
		var cc := _cell_of(p)
		if cl.has(cc):
			var ctr := _cell_world(cc)
			for dir: Vector3 in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
				if cl.has(cc + Vector2i(int(dir.x), int(dir.z))):
					continue
				var wall: float = (ctr + dir * G * 0.5).dot(dir)
				var over: float = (p + dir * minf(rad, G * 0.5 - 0.05)).dot(dir) - wall
				if over > 0.0:
					p -= dir * over
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
	_tags_tick(delta)
	_amb_tick(delta)          # S2: the quiet bed below
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
			# L25: on to the next floor when all are at the stairs; a delver who has truly stopped
			# getting closer (3 s) is carried, and counted - the old flat 6 s cut off a long walk
			var stopped := false
			for m in _alive():
				if stuck_on(m["body"], 3.0):
					stopped = true
			if all_there or stopped or _t > 45.0:
				if not all_there:
					forced += 1
				_next_floor()
		"home":
			pass

func _fight(delta: float) -> void:
	_check_lamp()
	_traps_tick()
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
	# venom keeps working after the bite (spider, snake, adder, wasp)
	for m in alive:
		if float(m.get("venom", 0.0)) > 0.0:
			m["venom"] = float(m["venom"]) - delta
			m["hp"] = float(m["hp"]) - float(m.get("venom_dps", 0.0)) * delta
			if float(m["hp"]) <= 0.0:
				m["venom"] = 0.0
				_hero_hit(m)
	alive = _alive()
	if alive.is_empty():
		return
	for m in alive:
		if float(m.get("slow", 0.0)) > 0.0:
			m["slow"] = float(m["slow"]) - delta
		_status_tick(m, delta)
		# D2 spells: renew mends over time, a ward fades
		if float(m.get("hot_t", 0.0)) > 0.0:
			m["hot_t"] = float(m["hot_t"]) - delta
			m["hp"] = minf(float(m["max"]), float(m["hp"]) + float(m.get("hot_rate", 0.0)) * delta)
		if float(m.get("ward_t", 0.0)) > 0.0:
			m["ward_t"] = float(m["ward_t"]) - delta
	for m in alive:
		var b: HeroBody = m["body"]
		var h: Dictionary = m["h"]
		# L12: a potion first, if one is called for (it costs the swing)
		if _quaff(m):
			continue
		# healers mend whoever is lowest first
		var hp_pow := roster.heal_power(h)
		if hp_pow > 0.0:
			var low = null
			# a paladin lays on hands only when someone is close to falling
			var mark := 0.35 if String(h["class"]) == "paladin" else 0.55
			for o in alive:
				if float(o["hp"]) < float(o["max"]) * mark and (low == null or float(o["hp"]) < float(low["hp"])):
					low = o
			m["swing"] = float(m["swing"]) - delta * _pace(m)
			if low != null and float(m["swing"]) <= 0.0:
				m["swing"] = 2.4
				# D2 spells: a sage lays renew, a cleric a ward, a paladin its hands
				var mk := String(MENDERS.get(String(h["class"]), "heal"))
				var got := Spells.cast(mk, b, low["body"], _scar_check(m, mk))
				Rig.play(b._anim, Spells.CAST_ANIM.get(got, "Spellcasting"))
				if Spells.HARM.has(got):
					# L8: the scar turned the mending into a blow - it lands on the friend
					low["hp"] = float(low["hp"]) - hp_pow * 0.5
					_hero_hit(low)
				else:
					_bless(low, got, hp_pow)
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
		var caster := String(h["class"]) in Roster.CASTERS
		var ability := String(Roster.CLASSES[String(h["class"])].get("ability", ""))
		var ranged := caster or String(h["class"]) == "ranger"
		var reach := 9.0 if ranged else REACH + tgt._height() * 0.15
		if bd > reach:
			# each hero takes their own side of the target instead of one point
			# L25: a delver pressed against a hoard or a wall on the way to its side of the target
			# goes round to another side instead of pushing at it for the rest of the fight
			if stuck_on(b):
				m["slot_off"] = float(m.get("slot_off", 0.0)) + 1.1
				_prog.erase(b)
			var slot := float(party.find(m)) * TAU / float(maxi(party.size(), 1)) + float(m.get("slot_off", 0.0))
			var ring := Vector3(cos(slot), 0, sin(slot)) * (1.4 + tgt._height() * 0.25 if not ranged else 5.0)
			_go(b, tgt.global_position + ring, roster.speed(h) * 0.9, delta)
			Rig.play(b._anim, "Running_A")
			continue
		b.rotation.y = atan2(tgt.global_position.x - b.global_position.x, tgt.global_position.z - b.global_position.z)
		m["swing"] = float(m["swing"]) - delta * _pace(m)
		if float(m["swing"]) > 0.0:
			continue
		m["swing"] = (1.3 + _rng.randf() * 0.4) * (0.6 if ability == "flurry" else 1.0) * (0.66 if has_st(m, "haste") else 1.0)
		# 5e: d20 + attack bonus vs the creature's AC (10 + depth band)
		# L5: darkvision shrugs off the dark; a lucky halfling rolls a natural 1 again
		var adv := _hero_adv(m)
		var roll := _d20(adv)
		if roll == 1 and Roster.has_trait(h, "lucky"):
			roll = _d20(adv)
		# L12: an unseen delver's first blow ends the potion
		if has_st(m, "invisible"):
			(m["st"] as Dictionary).erase("invisible")
		var ac := 10 + floor_no / 2 + (3 if tgt.def.get("boss", false) else 0) + int((tgt.def.get("ways", {}) as Dictionary).get("guard", 0))
		if caster:
			_cast_at(m, tgt, roll, ac, ability)
			continue
		else:
			Rig.play(b._anim, "1H_Melee_Attack_Chop" if String(h["class"]) != "ranger" else "1H_Ranged_Shoot")
		var lands := roll == 20 or (roll != 1 and roll + roster.attack_bonus(h) + _inspired() + (2 if has_st(m, "giant") else 0) >= ac)
		_blow_snd(m, tgt, lands, roll == 20)          # S2
		if lands:
			var dmg := _hero_damage(h, roll == 20) + (4.0 if has_st(m, "giant") else 0.0)
			dmg *= _ward(tgt) * _ability_mult(ability, tgt)
			_ability_hit(ability, m, tgt, dmg, foes)
			var was_dead := tgt.state == Monster.S.DEAD
			tgt.hurt(dmg, roll == 20)
			# a natural 20 reaches the Chronicle when it kills, or lands on a lord
			if roll == 20 and not was_dead:
				if tgt.state == Monster.S.DEAD:
					_big(m, "rolls a 20 - and the %s is gone." % String(tgt.def.get("name", "thing")))
				elif bool(tgt.def.get("boss", false)):
					_big(m, "rolls a 20 - %s reels." % String(tgt.def.get("name", "it")))
			if not was_dead and tgt.state == Monster.S.DEAD:
				_kills += 1
				_on_kill(tgt)
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
			if has_st(m, "invisible"):
				continue          # L12: Shadowcloak - it cannot pick them
			var d := _flat((m["body"] as Node3D).global_position, mon.global_position)
			if d < nd:
				nd = d
				near = m
		if near == null:
			continue
		var ways: Dictionary = mon.def.get("ways", {})
		var nearest := nd
		# a grudge goes for the weakest delver standing, not the nearest
		if ways.has("grudge"):
			for m in alive:
				if float(m["hp"]) / float(m["max"]) < float(near["hp"]) / float(near["max"]):
					near = m
			nd = _flat((near["body"] as Node3D).global_position, mon.global_position)
		var r := REACH + mon._height() * 0.2
		var shots := float(ways.get("ranged", 0.0))
		if shots > 0.0:
			r = shots
		mon.state = Monster.S.IDLE
		if ways.has("raise") and nearest < 14.0:
			_raise_tick(mon, int(ways["raise"]), delta)
		if nearest < 16.0:
			_lord_tick(mon, ways, alive, near, delta)
		if nd > r:
			# a creature mid-swing, mid-rise or reeling from a hit stands until it is done - no gliding
			if mon.busy():
				continue
			_go(mon, (near["body"] as Node3D).global_position, float(mon.def.get("spd", 3.0)) * 0.7 * _mon_pace(mon), delta)
			mon._play("walk")
			continue
		var nb: Node3D = near["body"]
		mon.rotation.y = atan2(nb.global_position.x - mon.global_position.x, nb.global_position.z - mon.global_position.z)
		mon._swing -= delta * _mon_pace(mon)
		if mon._swing > 0.0:
			continue
		mon._swing = 1.8 if not mon.def.get("boss", false) else 1.4
		var fury := 1.0
		if mon.enraged:
			var en: Dictionary = ways.get("enrage", {})
			mon._swing *= float(en.get("swing", 0.6))
			fury = float(en.get("atk", 1.3))
		var chest := nb.global_position + Vector3(0, 1.1, 0)
		if ways.has("breath"):
			mon._swing = 2.6
			mon.breathe(chest)
		elif shots > 0.0:
			mon._swing = 2.2
			mon.shoot(chest)
			if ways.has("volley"):
				_volley(mon, alive, near, shots)
		else:
			mon._play("attack")
		# L9: d20 + its to-hit vs the delver's AC; a natural 1 always misses, a natural 20 always hits and doubles the dice
		var nat := _d20(1 if dark or has_st(near, "blinded") else 0)
		var hit := nat + 2 + floor_no / 2
		if nat != 1 and (nat == 20 or hit >= roster.armour_class(near["h"])):
			var base := float(mon.def.get("boss_atk", (6.0 + float(floor_no) * 2.2) * float(mon.def.get("atk", 1.0))))
			var dmg := _mdice(base, nat == 20) * fury
			near["hp"] = float(near["hp"]) - _soak(near, dmg)
			_hero_hit(near)
			if ways.has("venom") and float(near["hp"]) > 0.0:
				near["venom"] = float(ways["venom"])
				near["venom_dps"] = base * 0.12
			if ways.has("breath") and float(near["hp"]) > 0.0:
				_give(near, "slowed" if String(mon.def.get("id", "")) == "mourncoil" else "burning", 3.0)
			# the breath splashes whoever stands beside the mark
			if ways.has("breath"):
				for o in alive:
					if o != near and float(o["hp"]) > 0.0 and _flat((o["body"] as Node3D).global_position, nb.global_position) < float(ways["breath"]):
						o["hp"] = float(o["hp"]) - _soak(o, dmg * 0.5 * _resist(o, "frost" if String(mon.def.get("id", "")) == "mourncoil" else "fire"))
						_give(o, "slowed" if String(mon.def.get("id", "")) == "mourncoil" else "burning", 3.0)
						_hero_hit(o)
		elif _has_shield(near["h"]) and shots <= 0.0 and not ways.has("breath"):
			_snd("block", (near["body"] as Node3D).global_position + Vector3(0, 1.2, 0))     # S2: a miss rings off the shield

## ---- ways (L1). A slain ooze divides; a gravecaller calls up the dead.
func _spawn_on_floor(d: Dictionary, at: Vector3) -> Monster:
	var root: Node3D = dun.info["root"]
	var m := Monster.new()
	m.def = d
	m.state = Monster.S.IDLE
	m.roam = 2.0
	var q: Vector3 = dun._out_of_props(at - root.global_position)
	m.position = Vector3(q.x, 0.0, q.z)
	root.add_child(m)
	m.max_hp = (14.0 + float(floor_no) * 6.0) * float(d.get("hp", 1.0))
	m.hp = m.max_hp
	dun.monsters.append(m)
	return m

var _split_said := -1
func _on_kill(tgt: Monster) -> void:
	var ways: Dictionary = tgt.def.get("ways", {})
	if ways.has("splits"):
		var n := int(ways["splits"])
		for k in range(n):
			var a := float(k) * TAU / float(n)
			_spawn_on_floor(Bestiary.make("slimeling", String(tgt.def.get("strain", "plain"))),
				tgt.global_position + Vector3(cos(a), 0, sin(a)) * 0.9)
		if _split_said != floor_no:
			_split_said = floor_no
			_say("The %s divides." % String(tgt.def.get("name", "ooze")))

func _raise_tick(mon: Monster, most: int, delta: float) -> void:
	_call_tick(mon, {"type": "minion", "strain": "hollowed", "name": "risen dead", "every": 9.0, "most": most,
		"rise": true, "line": "A gravecaller raises the dead on floor %d." % floor_no}, delta)

## anything that calls its kind: a gravecaller's dead, the Grubmother's brood,
## Nightwing's bats, Gnawbone's children. Never more than `most` standing at once.
func _live_called(mon: Monster) -> Array:
	var live: Array = []
	for r in mon.get_meta("risen", []):
		if is_instance_valid(r) and (r as Monster).state != Monster.S.DEAD:
			live.append(r)
	return live

func _call_tick(mon: Monster, spec: Dictionary, delta: float) -> void:
	var t := float(mon.get_meta("raise_t", 4.0)) - delta
	if t > 0.0:
		mon.set_meta("raise_t", t)
		return
	mon.set_meta("raise_t", float(spec.get("every", 9.0)))
	var live := _live_called(mon)
	if live.size() >= int(spec.get("most", 2)):
		mon.set_meta("risen", live)
		return
	mon._play("summon" if (mon.def.get("anims", {}) as Dictionary).has("summon") else "attack")
	var a := _rng.randf() * TAU
	var m := _call_one(mon, spec, mon.global_position + Vector3(cos(a), 0, sin(a)) * (1.6 + mon._height() * 0.2))
	live.append(m)
	mon.set_meta("risen", live)
	if not bool(mon.get_meta("said", false)) and String(spec.get("line", "")) != "":
		mon.set_meta("said", true)
		_say(String(spec["line"]))

func _call_one(mon: Monster, spec: Dictionary, at: Vector3) -> Monster:
	var d := Bestiary.make(String(spec["type"]), String(spec.get("strain", "plain")))
	if spec.has("name"):
		d["name"] = spec["name"]
	if bool(spec.get("rise", false)):
		d["anims"] = Bestiary.A_SKL if String(d["path"]).contains("kaykit") else d["anims"]
	d["raised"] = true
	(d["ways"] as Dictionary).erase("splits")    # a called thing does not multiply again
	var m := _spawn_on_floor(d, at)
	if bool(spec.get("rise", false)):
		m.call_deferred("rise")
	return m

## L2: a lord's mechanics (and a unique's). Runs while the party is within 16 m.
func _lord_tick(mon: Monster, ways: Dictionary, alive: Array, near: Dictionary, delta: float) -> void:
	if ways.has("summon"):
		_call_tick(mon, ways["summon"], delta)
	if ways.has("nova"):
		var nv: Dictionary = ways["nova"]
		var t := float(mon.get_meta("nova_t", float(nv.get("every", 9.0)) * 0.6)) - delta
		mon.set_meta("nova_t", t)
		if t <= 0.0:
			mon.set_meta("nova_t", float(nv.get("every", 9.0)))
			var rr := float(nv.get("r", 6.0))
			mon.nova(rr)
			if not bool(mon.get_meta("nova_said", false)) and String(nv.get("line", "")) != "":
				mon.set_meta("nova_said", true)
				_say(String(nv["line"]))
			var base := float(mon.def.get("boss_atk", 10.0)) * float(nv.get("dmg", 0.5))
			for o in alive:
				if float(o["hp"]) > 0.0 and _flat((o["body"] as Node3D).global_position, mon.global_position) < rr:
					# a DEX save halves it (5e area rule)
					var save := _rng.randi_range(1, 20) + roster.save_bonus(o["h"], "dex")
					var elem := "frost" if nv.has("slow") else "fire"
					o["hp"] = float(o["hp"]) - _soak(o, base * (0.5 if save >= 12 + floor_no / 4 else 1.0) * _resist(o, elem))
					if nv.has("slow"):
						_give(o, "slowed", float(nv["slow"]))
					else:
						_give(o, "burning", 3.0)
					_hero_hit(o)
	if ways.has("shed"):
		var sh: Dictionary = ways["shed"]
		var marks: Array = sh["at"]
		var done := int(mon.get_meta("shed_n", 0))
		if done < marks.size() and mon.hp / maxf(1.0, mon.max_hp) <= float(marks[done]):
			mon.set_meta("shed_n", done + 1)
			for k in range(int(sh.get("n", 2))):
				var a := _rng.randf() * TAU
				var m := _call_one(mon, {"type": String(sh["type"]), "rise": true},
					mon.global_position + Vector3(cos(a), 0, sin(a)) * (1.8 + mon._height() * 0.2))
				var live := _live_called(mon)
				live.append(m)
				mon.set_meta("risen", live)
			_say(String(sh.get("line", "")))
	if ways.has("swoop"):
		var sw: Dictionary = ways["swoop"]
		var t := float(mon.get_meta("swoop_t", float(sw.get("every", 7.0)))) - delta
		mon.set_meta("swoop_t", t)
		if t <= 0.0:
			mon.set_meta("swoop_t", float(sw.get("every", 7.0)))
			var weak: Dictionary = near
			for o in alive:
				if float(o["hp"]) > 0.0 and float(o["hp"]) / float(o["max"]) < float(weak["hp"]) / float(weak["max"]):
					weak = o
			# the swoop lands on the floor beside its mark, never in the wall behind it
			var wp: Vector3 = (weak["body"] as Node3D).global_position
			var land := wp + (mon.global_position - wp).normalized() * 1.4
			if not (dun.info["cells"] as Dictionary).has(_cell_of(land)):
				land = wp
			mon.swoop(land, true)
			if _d20(1 if dark else 0) + 2 + floor_no / 2 >= roster.armour_class(weak["h"]):
				weak["hp"] = float(weak["hp"]) - _soak(weak, _mdice(float(mon.def.get("boss_atk", 10.0)) * float(sw.get("mult", 1.5)), false))
				# L12: too fast to see coming - a CON save (DC 12) or blinded a moment
				if _rng.randi_range(1, 20) + roster.save_bonus(weak["h"], "con") < 12:
					_give(weak, "blinded", 3.0)
				_hero_hit(weak)
	if ways.has("enrage") and not mon.enraged:
		if mon.hp / maxf(1.0, mon.max_hp) <= float((ways["enrage"] as Dictionary).get("at", 0.3)):
			mon.enrage()
			_say("%s is enraged." % String(mon.def.get("name", "It")))
			FeedHUD.card_on(town, String(mon.def.get("name", "It")), "Enraged.", Color(1.0, 0.25, 0.15))

## a lord warded by what it called takes only that share while any of it stands
func _ward(tgt: Monster) -> float:
	var ways: Dictionary = tgt.def.get("ways", {})
	if ways.has("ward") and not _live_called(tgt).is_empty():
		return float(ways["ward"])
	return 1.0

## frost and the like: a slowed hero swings at half pace
func _pace(m: Dictionary) -> float:
	return 0.5 if float(m.get("slow", 0.0)) > 0.0 else 1.0

## the Weeping Bowman looses at everyone in reach, not only its mark
func _volley(mon: Monster, alive: Array, near: Dictionary, reach: float) -> void:
	var base := float(mon.def.get("boss_atk", 10.0)) * 0.55
	for o in alive:
		if o == near or float(o["hp"]) <= 0.0:
			continue
		var ob: Node3D = o["body"]
		if _flat(ob.global_position, mon.global_position) > reach:
			continue
		mon.shoot(ob.global_position + Vector3(0, 1.1, 0))
		if _d20(1 if dark else 0) + 2 + floor_no / 2 >= roster.armour_class(o["h"]):
			o["hp"] = float(o["hp"]) - _soak(o, _mdice(base, false))
			_hero_hit(o)

## Gold is PERSONAL (old rule): a lord's hoard is split between the heroes who
## brought it down; anything else found belongs to whoever prised it open, and
## searching costs half a flask. Materials go home to the town.
func _loot(alive: Array) -> void:
	var boss := dun.lord != null
	var uniq := boss and bool(dun.lord.def.get("unique", false))
	# L9: the party's sharpest eye searches - an Investigation check (d20 + INT,
	# + proficiency for the trained, disadvantage in the dark without darkvision)
	# vs DC 10 + floor/2: it sets how much is found, what is salvaged, and whether
	# deep gear turns up.
	var seeker: Dictionary = alive[0]
	for m in alive:
		if _search_bonus(m["h"]) > _search_bonus(seeker["h"]):
			seeker = m
	var sd := _d20(-1 if dark and not Roster.has_trait(seeker["h"], "darkvision") else 0)
	var st := sd + _search_bonus(seeker["h"])
	var sdc := mini(20, 10 + floor_no / 2)
	var mult := 0.8
	if sd == 20:
		mult = 1.6
		_big(seeker, "rolls a 20 searching the floor!")
	elif sd == 1:
		mult = 0.6
	elif st >= sdc:
		mult = minf(1.35, 1.0 + 0.03 * float(st - sdc))
	var found := int(float(floor_no) * 11.0 * ((2.0 if uniq else 3.0) if boss else 1.0) * mult)
	Sfx.play("coin", -4.0)
	_snd("chest_open", (seeker["body"] as Node3D).global_position, -2.0)      # S2: a find
	if boss:
		var share := int(float(found) / float(alive.size()))
		var took: Array = []
		for m in alive:
			roster.award(String(m["uid"]), share, 0, 0, floor_no)
			took.append(String(m["h"]["name"]))
		_gold += share * alive.size()
		_say("%s is slain on floor %d!" % [dun.lord.def.get("name", "The lord"), floor_no])
		FeedHUD.card_on(town, String(dun.lord.def.get("name", "The lord")),
			"Slain on floor %d by %s." % [floor_no, _names_of(_party_uids(alive))], dun.lord.def.get("aura", Color(1, 0.8, 0.4)))
		_say("The hoard is split %d ways - %d gold each to %s." % [took.size(), share, ", ".join(took)])
	else:
		var f: Dictionary = seeker
		roster.award(String(f["uid"]), found, 0, 0, floor_no)
		_gold += found
		oil = maxf(0.0, oil - 0.5)
		_say("%s searches (Investigation %d) and turns up %d gold on floor %d." % [f["h"]["name"], st, found, floor_no])
		_say(_pick_line("cleared", "Floor %d cleared.") % floor_no)
	# renown (old rule): a floor cleared +1, a lord slain +6
	var eco = town.get("economy") if town else null
	if eco:
		eco.renown += (3 if uniq else 6) if boss else 1
	haul["ore"] += floor_no * 0.6
	haul["stone"] += floor_no * 0.45
	if sd != 1 and st >= sdc - floor_no / 3:
		haul["gear"] += 1.0
	if sd != 1 and st >= sdc - 2:
		haul["potion"] += 1.0
	# L3: deep floors give up gear - one roll a floor, for whoever was searching
	var finder: Dictionary = seeker
	var lordly := boss and not uniq
	var deep_find := sd == 20 or (sd != 1 and st >= 25 - floor_no / 2 - (5 if lordly else 0))
	var found_line := roster.find_gear(String(finder["uid"]), floor_no, 0.0 if deep_find else 1.0, lordly)
	if found_line != "":
		_say(found_line)
		var fb: HeroBody = finder["body"]
		if is_instance_valid(fb):
			fb.refresh()
	# L12: a good search turns up a vial - the deeper, the better the brew
	if sd != 1 and st >= sdc and _rng.randf() < 0.30 + 0.02 * float(floor_no):
		var pool: Array = []
		var ps: Dictionary = Roster.potions().get("potions", {})
		for k in ps:
			if int(ps[k].get("tier", 1)) <= 1 + floor_no / 3:
				pool.append(k)
		if not pool.is_empty():
			var pk: String = pool[_rng.randi() % pool.size()]
			roster.add_brew(seeker["h"], pk, 1)
			_say("%s finds a vial of %s." % [seeker["h"]["name"], ps[pk]["name"]])
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
	# L19: a delver badly hurt says so, once a floor
	if float(m["hp"]) > 0.0 and float(m["hp"]) < float(m["max"]) * 0.25 and int(m.get("hurt_bark", -1)) != floor_no:
		m["hurt_bark"] = floor_no
		_bark(m, "hurt")
	var b: HeroBody = m["body"]
	if is_instance_valid(b) and b.is_inside_tree():
		Rig.play(b._anim, "Hit_A")
		Sfx.at("hit", b.global_position)
		_hurt_snd(m)                  # S2: a cry, now and then
	if float(m["hp"]) > 0.0:
		return
	# one death save per delve (old rule): claw back to 1 hp on a DC 10 CON save
	if not bool(m["saved"]):
		m["saved"] = true
		# L9: a natural 20 stands them up with a quarter of their life; a natural 1 is death
		var sd := _rng.randi_range(1, 20)
		var s := sd + roster.save_bonus(m["h"], "con")
		if sd == 20:
			m["hp"] = float(m["max"]) * 0.25
			_say("%s rolls a 20 on the death save - and gets up swinging." % m["h"]["name"])
			return
		if sd != 1 and s >= 10:
			m["hp"] = 1.0
			_say("%s should be dead - and stands back up (%d)." % [m["h"]["name"], s])
			return
	Rig.play(b._anim, "Death_A")
	_vox(m, "death", 3.0)             # S2
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

## ---- L4: what the newer callings do in a fight
## a bard standing anywhere in the party: everyone swings truer (+1 to hit)
func _inspired() -> int:
	for o in _alive():
		if String(o["h"]["class"]) == "bard":
			return 1
	return 0

func _ability_mult(ability: String, tgt: Monster) -> float:
	var k := 1.0
	match ability:
		"smite":    # a paladin hits the dead twice as hard
			if String(tgt.def.get("family", "")) in ["undead", "the fallen"]:
				k = 2.0
		"flurry":   # a monk hits often and light
			k = 0.7
	# a warlock's hex: everyone's blows land harder on the marked thing
	if float(tgt.get_meta("hex_t", -1.0)) > _t:
		k *= 1.25
	return k

func _ability_hit(ability: String, m: Dictionary, tgt: Monster, dmg: float, foes: Array) -> void:
	match ability:
		"drain":    # the necromancer drinks back a share of what it spends
			m["hp"] = minf(float(m["max"]), float(m["hp"]) + dmg * 0.3)
		"hex":
			if float(tgt.get_meta("hex_t", -1.0)) <= _t:
				Spells._burst(tgt.get_parent(), tgt.global_position + Vector3(0, tgt._height() * 0.6, 0), Color(0.6, 0.2, 0.9))
			tgt.set_meta("hex_t", _t + 6.0)
		"thorns":   # thorns take whatever stands beside the mark
			for f in foes:
				var o: Monster = f
				if o != tgt and is_instance_valid(o) and o.state != Monster.S.DEAD and _flat(o.global_position, tgt.global_position) < 2.5:
					var was := o.state == Monster.S.DEAD
					o.hurt(dmg * 0.5)
					if not was and o.state == Monster.S.DEAD:
						_kills += 1
						_on_kill(o)
						roster.award(String(m["uid"]), 3 + floor_no, 6 + floor_no * 2, 1, floor_no)

## ---- D2 spells below (the desktop's Spells, used the way raids.gd uses them).
## Each caster works through its book; a mending calling lays its own spell on
## whoever is lowest. Damage lands when the spell does, after its flight.
const BOOKS := {"mage": ["bolt", "bolt", "chain", "fire"], "sage": ["frost", "bolt"], "cleric": ["smite", "bolt"],
				"necromancer": ["bolt", "chain"], "druid": ["frost", "bolt"], "warlock": ["bolt", "fire"]}
const MENDERS := {"sage": "renew", "cleric": "ward", "paladin": "heal"}
const CHAIN_R := 5.0        # the chain leaps to a creature this near the last
const FIRE_R := 2.6         # the fire burst catches everything this near its mark
const FROST_SLOW := 4.0     # s a frosted creature moves and swings at half pace
const SMITE_DEAD := 1.5     # smite on the dead and the lost
const WARD_SOAK := 0.35     # of the warded delver's max, soaked for WARD_T s
const WARD_T := 8.0

func _cast_at(m: Dictionary, tgt: Monster, roll: int, ac: int, ability: String) -> void:
	var b: HeroBody = m["body"]
	var h: Dictionary = m["h"]
	var book: Array = BOOKS.get(String(h["class"]), ["bolt"])
	var kind := String(book[int(m.get("spell_i", 0)) % book.size()])
	m["spell_i"] = int(m.get("spell_i", 0)) + 1
	var hit: Array = [tgt]
	var more: Array = []
	if kind == "chain":
		var at := tgt.global_position
		for _k in range(2):
			var nx: Monster = null
			var nd := CHAIN_R
			for f in _foes():
				if hit.has(f):
					continue
				var d := _flat((f as Node3D).global_position, at)
				if d < nd:
					nd = d
					nx = f
			if nx == null:
				break
			hit.append(nx)
			more.append(nx)
			at = nx.global_position
	var actual := Spells.cast(kind, b, tgt, _scar_check(m, kind), more)
	Rig.play(b._anim, Spells.CAST_ANIM.get(actual, "Spellcast_Shoot"))
	if not Spells.HARM.has(actual):
		# L8: the scar turned the blow into a mending - wild magic mends the creature
		if actual in ["heal", "renew", "mend"] and is_instance_valid(tgt) and tgt.state != Monster.S.DEAD:
			tgt.hp = minf(tgt.max_hp, tgt.hp + roster.attack(h) * 0.5)
		return
	if not (roll == 20 or (roll != 1 and roll + roster.attack_bonus(h) + _inspired() >= ac)):
		return
	var dmg := _hero_damage(h, roll == 20)
	dmg *= _ability_mult(ability, tgt)
	var t := Spells.flight(actual, b, tgt)
	get_tree().create_timer(t).timeout.connect(_spell_lands.bind(actual, m, hit, dmg, roll == 20, ability))

func _spell_lands(kind: String, m: Dictionary, hit: Array, dmg: float, crit: bool, ability: String) -> void:
	if state != "fight" or dun == null or not is_instance_valid(dun):
		return
	var first: Monster = hit[0] if is_instance_valid(hit[0]) else null
	match kind:
		"fire":
			if first == null:
				return
			var p := first.global_position
			for f in _foes():
				if _flat((f as Node3D).global_position, p) <= FIRE_R:
					_strike(m, f, dmg * 0.8 * (0.5 if _mon_saves(f, m, 0) else 1.0), crit)
		"chain":
			var k := 1.0
			for r in hit:
				if is_instance_valid(r):
					_strike(m, r, dmg * k, crit)
				k *= 0.65
		"frost":
			if first == null:
				return
			_strike(m, first, dmg * 0.7, crit)
			# L9: a CON save against the caster's spell DC shrugs the slow off
			if is_instance_valid(first) and not _mon_saves(first, m, 0):
				first.set_meta("slow_t", _t + FROST_SLOW)
		"smite":
			if first == null:
				return
			var dead := String(first.def.get("family", "")) in ["undead", "the fallen"]
			_strike(m, first, dmg * (SMITE_DEAD if dead else 1.0), crit)
		_:
			if first == null:
				return
			_strike(m, first, dmg, crit)
	if first != null and is_instance_valid(first):
		_ability_hit(ability, m, first, dmg, _foes())

## one blow from a delver to a creature, with the kill's bookkeeping
func _strike(m: Dictionary, tgt: Monster, dmg: float, crit: bool) -> void:
	if tgt == null or not is_instance_valid(tgt) or tgt.state == Monster.S.DEAD or tgt._entering():
		return
	tgt.hurt(dmg * _ward(tgt), crit)
	if tgt.state == Monster.S.DEAD:
		_kills += 1
		_on_kill(tgt)
		roster.award(String(m["uid"]), 3 + floor_no, 6 + floor_no * 2, 1, floor_no)
		if tgt.def.get("boss", false):
			_say("%s falls to %s." % [tgt.def.get("name"), m["h"]["name"]])

## renew mends over Spells.RENEW_T; a ward soaks blows for WARD_T; heal is at once
func _bless(o: Dictionary, kind: String, pow: float) -> void:
	match kind:
		"renew":
			o["hot_t"] = Spells.RENEW_T
			o["hot_rate"] = pow * 1.3 / Spells.RENEW_T
		"ward":
			o["hp"] = minf(float(o["max"]), float(o["hp"]) + pow * 0.5)
			o["ward"] = float(o["max"]) * WARD_SOAK
			o["ward_t"] = WARD_T
		"heal", "mend":
			o["hp"] = minf(float(o["max"]), float(o["hp"]) + pow)

func _soak(o: Dictionary, dmg: float) -> float:
	if float(o.get("ward_t", 0.0)) <= 0.0 or float(o.get("ward", 0.0)) <= 0.0:
		return dmg
	var s := minf(float(o["ward"]), dmg)
	o["ward"] = float(o["ward"]) - s
	return dmg - s

## a frosted creature moves and swings at half pace
func _mon_pace(mon: Monster) -> float:
	return 0.5 if float(mon.get_meta("slow_t", -1.0)) > _t else 1.0

## ---- L8 (Mr. E, Nov 11): wild magic below. The dungeon is one enormous scar,
## so every spell cast down here is a check against it: d20 + casting ability
## mod + proficiency vs DC 10 + floor/2 (cap 20). (The sage checks on WIS, its own sheet - Mr. E, L9.) A fail misfires the way it does
## on the scar's surface (Spells.cast in_scar: the next spell in the order goes
## off instead). A natural 1 always misfires, a natural 20 never. Monsters'
## spells are not checked.
const CAST_STAT := {"mage": "int", "necromancer": "int",
					"sage": "wis", "cleric": "wis", "druid": "wis", "monk": "wis",
					"warlock": "cha", "bard": "cha", "paladin": "cha"}
var scar_casts := 0
var scar_misfires := 0
var _misfire_said := {}

static func scar_dc(floor_no: int) -> int:
	return mini(20, 10 + floor_no / 2)

func _scar_check(m: Dictionary, kind: String) -> bool:
	var h: Dictionary = m["h"]
	var stat := String(CAST_STAT.get(String(h["class"]), String(Roster.CLASSES[String(h["class"])].get("primary", "int"))))
	var d := _rng.randi_range(1, 20)
	var total := d + roster.mod(h, stat) + roster.prof(h)
	var miss := d == 1 or (d != 20 and total < scar_dc(floor_no))
	scar_casts += 1
	if miss:
		scar_misfires += 1
		# one Chronicle line per caster per floor, so the feed is not all sparks
		var key := "%s:%d" % [m["uid"], floor_no]
		if not _misfire_said.has(key):
			_misfire_said[key] = true
			_say(_pick_line("misfire", "%s's %s goes wrong - the scar answers (%d vs DC %d).") % [h["name"], kind, total if d != 1 else 1, scar_dc(floor_no)])
			_bark(m, "misfire")
	return miss

## ---- L9 (DnD RULE): the roll audit, dungeon side. Everything below is a d20
## or dice roll on the hero's real numbers (Roster.mod / prof / save_bonus).
func _dice(n: int, s: int) -> int:
	var t := 0
	for i in range(maxi(n, 1)):
		t += _rng.randi_range(1, maxi(s, 1))
	return t

## a delver's blow: the weapon's dice + the ability mod + a flat part that keeps
## the average exactly where it was (0.75 x Roster.attack + the muster's kit), so
## the measured balance holds and only the spread is now dice. A crit rolls the
## dice twice, as 5e does.
func _hero_damage(h: Dictionary, crit: bool) -> float:
	var d := roster.weapon_dice(h)
	var n := int(d[0])
	var s := int(d[1])
	var prim := String(Roster.CLASSES[String(h["class"])].get("primary", "str"))
	var md := roster.mod(h, prim)
	var flat := roster.attack(h) * 0.75 + kit_bonus + roster.acc_bonus(h, "dmg") - float(n) * float(s + 1) * 0.5 - float(md)
	var dice := _dice(n, s) + (_dice(n, s) if crit else 0)
	return maxf(1.0, float(dice + md) + flat)

## a creature's blow on 2d6: the same 0.6-1.0 of its base, mean 0.8, now dice;
## a natural 20 doubles it
func _mdice(base: float, crit: bool) -> float:
	var k := 0.6 + 0.4 * float(_dice(2, 6) - 2) / 10.0
	return base * k * (2.0 if crit else 1.0)

## big rolls reach the Chronicle - once per delver per floor
var _big_said := {}
func _big(m: Dictionary, what: String) -> void:
	var key := "%s:%d" % [m["uid"], floor_no]
	if _big_said.has(key):
		return
	_big_said[key] = true
	_say("%s %s" % [m["h"]["name"], what])

## Investigation: d20 + INT (+ proficiency for the trained searchers)
const SEARCHERS := ["rogue", "ranger", "mage", "sage", "necromancer"]
func _search_bonus(h: Dictionary) -> int:
	return roster.mod(h, "int") + (roster.prof(h) if String(h["class"]) in SEARCHERS else 0)

## initiative: d20 + DEX for each delver, d20 + 1 for each creature; who rolls
## high swings first (the first swing comes sooner the higher the roll)
func _initiative() -> void:
	var best = null
	var bi := -99
	for m in _alive():
		var d := _rng.randi_range(1, 20)
		var ini := d + roster.mod(m["h"], "dex")
		m["swing"] = 0.15 + float(maxi(0, 22 - ini)) * 0.06
		if ini > bi:
			bi = ini
			best = m
		if d == 20:
			_big(m, "rolls a 20 for initiative and is moving before anything else.")
	for mon in dun.monsters:
		if is_instance_valid(mon):
			(mon as Monster)._swing = 0.15 + float(maxi(0, 21 - _rng.randi_range(1, 20))) * 0.06
	if dun.lord and is_instance_valid(dun.lord):
		dun.lord._swing = 0.15 + float(maxi(0, 19 - _rng.randi_range(1, 20))) * 0.06

## a creature's save against a delver's spell: d20 + floor/3 (+2 for a lord) vs
## the caster's spell DC (8 + proficiency + casting mod)
func _mon_saves(mon: Monster, m: Dictionary, _kind: int) -> bool:
	var h: Dictionary = m["h"]
	var stat := String(CAST_STAT.get(String(h["class"]), String(Roster.CLASSES[String(h["class"])].get("primary", "int"))))
	var dc := 8 + roster.prof(h) + roster.mod(h, stat)
	var d := _rng.randi_range(1, 20)
	if d == 1:
		return false
	if d == 20:
		return true
	return d + floor_no / 3 + (2 if mon.def.get("boss", false) else 0) >= dc

## ---- L11: traps that visibly work. The first delver to come within reach of
## an armed trap looks for it: Perception, d20 + WIS (+ proficiency for rogue,
## ranger, monk; disadvantage in the dark without darkvision) vs DC 10 + floor/2.
## Spotted by someone with thieves' tools (rogue, bard), it is disarmed on a DEX
## (+ proficiency) check; failing that by 5 or more sets it off on them. Spotted
## by anyone else, it is stepped round. Missed, it goes off: the trap plays, a DEX
## save halves the dice, the number floats up, the Chronicle says what happened.
const SPOTTERS := ["rogue", "ranger", "monk"]
const TOOLS := ["rogue", "bard"]
const TRAP_REACH := 0.9
const TRAPS := {
	"SpikeTrap":     {"noun": "a spiked plate", "what": "spikes!", "dice": [2, 6], "sfx": "swing", "name": "a spike trap"},
	"PressurePlate": {"noun": "a plate", "what": "darts!", "dice": [3, 4], "sfx": "ui", "name": "a pressure plate"},
	"FireTrap":      {"noun": "a grate", "what": "fire!", "dice": [2, 8], "sfx": "spell", "name": "a fire grate"},
	"DartTrap":      {"noun": "a loose flagstone", "what": "darts!", "dice": [3, 4], "sfx": "swing", "name": "a dart trap"},
	"BladeTrap":     {"noun": "a slot in the floor", "what": "a blade!", "dice": [2, 8], "sfx": "swing", "name": "a blade trap"},
	"PitTrap":       {"noun": "rotten boards", "what": "the floor drops away!", "dice": [2, 6], "sfx": "hit", "name": "a pit"},
}
var trap_log := {"spotted": 0, "disarmed": 0, "sprung": 0, "saved": 0, "damage": 0.0}

func trap_dc() -> int:
	return mini(20, 10 + floor_no / 2)

func _traps_tick() -> void:
	if dun == null or not dun.info.has("traps"):
		return
	for t in dun.info["traps"]:
		var tr: Dictionary = t
		if bool(tr.get("done", false)) or not is_instance_valid(tr["node"]):
			continue
		var tp: Vector3 = (tr["node"] as Node3D).global_position
		for m in _alive():
			if _flat((m["body"] as Node3D).global_position, tp) > TRAP_REACH:
				continue
			tr["done"] = true
			_meet_trap(m, tr)
			break

func _meet_trap(m: Dictionary, tr: Dictionary, force_spot := -1) -> void:
	var h: Dictionary = m["h"]
	var spec: Dictionary = TRAPS.get(String(tr.get("kind", "SpikeTrap")), TRAPS["SpikeTrap"])
	var dc := trap_dc()
	var pd := _d20(-1 if dark and not Roster.has_trait(h, "darkvision") else 0)
	var per := pd + roster.mod(h, "wis") + (roster.prof(h) if String(h["class"]) in SPOTTERS else 0)
	var spotted := pd != 1 and (pd == 20 or per >= dc)
	if force_spot >= 0:
		spotted = force_spot == 1
	if spotted:
		trap_log["spotted"] += 1
		if String(h["class"]) in TOOLS:
			var td := _rng.randi_range(1, 20)
			var tt := td + roster.mod(h, "dex") + roster.prof(h)
			if td != 1 and (td == 20 or tt >= dc):
				trap_log["disarmed"] += 1
				_say("%s spots %s (Perception %d vs DC %d) and disarms it with thieves' tools (%d)." % [h["name"], spec["name"], per, dc, tt])
				_float_text(m, "disarmed", Color(0.6, 1.0, 0.7))
				return
			if tt <= dc - 5:
				_say("%s fumbles the thieves' tools on %s (%d vs DC %d) -" % [h["name"], spec["name"], tt, dc])
				_spring(m, tr, spec, dc)
				return
		_say("%s spots %s (Perception %d vs DC %d) and steps round it." % [h["name"], spec["name"], per, dc])
		_bark(m, "trap")
		_float_text(m, "spotted", Color(0.85, 0.95, 1.0))
		return
	_spring(m, tr, spec, dc)

func _spring(m: Dictionary, tr: Dictionary, spec: Dictionary, dc: int) -> void:
	var h: Dictionary = m["h"]
	trap_log["sprung"] += 1
	var node: Node3D = tr["node"]
	if node.has_meta("fire"):
		(node.get_meta("fire") as Callable).call()
	node.set_meta("fired", int(node.get_meta("fired", 0)) + 1)
	if node.is_inside_tree():
		Sfx.at(String(spec["sfx"]), node.global_position, 2.0)
	var what := String(spec["what"])
	var dice: Array = spec["dice"]
	if String(tr.get("kind", "")) == "PressurePlate" and _rng.randi() % 2 == 0:
		what = "a stone from the ceiling!"
		dice = [1, 10]
	var dmg := float(_dice(int(dice[0]), int(dice[1])) + floor_no / 2)
	if String(tr.get("kind", "")) == "FireTrap":
		dmg *= _resist(m, "fire")
	var sd := _rng.randi_range(1, 20)
	var sv := sd + roster.save_bonus(h, "dex")
	var saved := sd != 1 and (sd == 20 or sv >= dc)
	if saved:
		trap_log["saved"] += 1
		dmg = floorf(dmg * 0.5)
	var took := _soak(m, dmg)
	trap_log["damage"] += took
	m["hp"] = float(m["hp"]) - took
	_say("%s steps on %s - %s DEX %d vs DC %d, %d damage%s." % [h["name"], spec["noun"], what, sv, dc, int(took), " (halved)" if saved else ""])
	_float_text(m, "-%d" % int(took), Color(1.0, 0.35, 0.25) if not saved else Color(1.0, 0.75, 0.3))
	if String(tr.get("kind", "")) == "FireTrap" and not saved:
		_give(m, "burning", 3.0)
	_hero_hit(m)

## a number or word floating up off a delver's head
func _float_text(m: Dictionary, text: String, col: Color, size := 84, lift := 2.4) -> void:
	var b: Node3D = m["body"]
	if not is_instance_valid(b) or not b.is_inside_tree():
		return
	var lb := Label3D.new()
	lb.text = text
	lb.font_size = size
	lb.pixel_size = 0.006 if HudDock.split(town) else 0.01      # L21: smaller in a close side-by-side pane
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.no_depth_test = true
	lb.outline_size = 22
	lb.outline_modulate = Color(0, 0, 0, 0.95)
	lb.modulate = col
	lb.top_level = true
	# on the floor, not the hero: HeroBody renames every Label3D under it to its name
	var host: Node = dun.info["root"] if dun and dun.info.has("root") else self
	host.add_child(lb)
	var p := b.global_position + Vector3(0, lift, 0)
	lb.global_position = p
	var tw := lb.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lb, "global_position", p + Vector3(0, 1.4, 0), 1.2).set_ease(Tween.EASE_OUT)
	tw.tween_property(lb, "modulate:a", 0.0, 1.2).set_delay(0.5)
	tw.chain().tween_callback(lb.queue_free)

## ---- L12: states and potions below. A delver's states live in m["st"]
## {name: seconds}; venom ("poisoned") and frost ("slowed") keep their old
## fields so everything that already set them still does.
func has_st(m, name: String) -> bool:
	if m == null:
		return false
	match name:
		"poisoned":
			return float(m.get("venom", 0.0)) > 0.0
		"slowed":
			return float(m.get("slow", 0.0)) > 0.0
	return float((m.get("st", {}) as Dictionary).get(name, 0.0)) > 0.0

func _give(m: Dictionary, name: String, secs: float) -> void:
	if float(m.get("hp", 0.0)) <= 0.0:
		return
	if name == "frightened" and has_st(m, "heroism"):
		return
	if name == "burning" and has_st(m, "resist_fire"):
		return
	if name == "slowed":
		if has_st(m, "resist_frost"):
			return
		m["slow"] = maxf(float(m.get("slow", 0.0)), secs)
		return
	if name == "poisoned":
		m["venom"] = maxf(float(m.get("venom", 0.0)), secs)
		return
	if not m.has("st"):
		m["st"] = {}
	var was := has_st(m, name)
	m["st"][name] = maxf(float((m["st"] as Dictionary).get(name, 0.0)), secs)

func _status_tick(m: Dictionary, delta: float) -> void:
	if not m.has("st"):
		return
	var st: Dictionary = m["st"]
	for k in st.keys():
		st[k] = float(st[k]) - delta
		if float(st[k]) <= 0.0:
			st.erase(k)
	# burning: 1d4 fire a second
	if has_st(m, "burning"):
		m["burn_acc"] = float(m.get("burn_acc", 0.0)) + delta
		if float(m["burn_acc"]) >= 1.0:
			m["burn_acc"] = 0.0
			m["hp"] = float(m["hp"]) - _soak(m, float(_dice(1, 4)))
			_hero_hit(m)

func _resist(m: Dictionary, elem: String) -> float:
	if elem == "fire" and has_st(m, "resist_fire"):
		return 0.5
	if elem == "frost" and has_st(m, "resist_frost"):
		return 0.5
	return 1.0

## advantage / disadvantage on a delver's attack (they cancel, as in 5e)
func _hero_adv(m: Dictionary) -> int:
	var h: Dictionary = m["h"]
	var dis := (dark and not Roster.has_trait(h, "darkvision") and not has_st(m, "darkvision")) \
		or has_st(m, "poisoned") or has_st(m, "blinded") or has_st(m, "frightened")
	var adv := has_st(m, "invisible")
	if adv and not dis:
		return 1
	if dis and not adv:
		return -1
	return 0

## a potion, if one is called for: low on life, a cure for what ails them, a
## lord to face, the dark. Drinking takes the delver's swing.
const HEAL_ORDER := ["supreme", "superior", "greater", "mending"]
func _quaff(m: Dictionary) -> bool:
	if float(m.get("quaff_t", 0.0)) > _t:
		return false
	var h: Dictionary = m["h"]
	var want := ""
	if float(m["hp"]) < float(m["max"]) * 0.34:
		for k in HEAL_ORDER:
			if roster.brew_count(h, k) > 0:
				want = k
				break
	if want == "":
		for pair in [["poisoned", "antidote"], ["burning", "emberward"], ["slowed", "hearthwarm"], ["frightened", "bravecup"]]:
			if has_st(m, pair[0]) and roster.brew_count(h, pair[1]) > 0:
				want = pair[1]
				break
	if want == "" and dark and not Roster.has_trait(h, "darkvision") and not has_st(m, "darkvision") and roster.brew_count(h, "owl") > 0:
		want = "owl"
	if want == "" and lord_fighting() != null and not bool(m.get("buffed", false)):
		for k in ["ogre", "quickwater", "shadow", "bravecup"]:
			if roster.brew_count(h, k) > 0:
				want = k
				m["buffed"] = true
				break
	if want == "":
		return false
	drink(m, want)
	if is_instance_valid(m.get("body")):
		_snd("potion_drink", (m["body"] as Node3D).global_position + Vector3(0, 1.5, 0), POTION_DB)     # S2 (S3: up - it was buried)
	return true

func drink(m: Dictionary, key: String) -> void:
	var h: Dictionary = m["h"]
	var p := Roster.potion(key)
	roster.add_brew(h, key, -1)
	m["quaff_t"] = _t + 2.5
	m["swing"] = maxf(float(m.get("swing", 0.0)), 0.8)
	var b = m["body"]
	if b is HeroBody and is_instance_valid(b):
		Rig.play((b as HeroBody)._anim, "Use_Item")
	if p.has("heal"):
		var hd: Array = p["heal"]
		var amt := float(_dice(int(hd[0]), int(hd[1])) + int(hd[2]))
		m["hp"] = minf(float(m["max"]), float(m["hp"]) + amt)
		_float_text(m, "+%d" % int(amt), Color(0.45, 1.0, 0.5))
		_bark(m, "drink")
		if key != "mending":
			_say("%s drinks %s (+%d)." % [h["name"], p["name"], int(amt)])
		# any mending puts out a fire on you
		if m.has("st"):
			(m["st"] as Dictionary).erase("burning")
		return
	for c in p.get("cures", []):
		match String(c):
			"poisoned":
				m["venom"] = 0.0
			"slowed":
				m["slow"] = 0.0
			_:
				if m.has("st"):
					(m["st"] as Dictionary).erase(String(c))
	if p.has("gives"):
		if not m.has("st"):
			m["st"] = {}
		m["st"][String(p["gives"])] = float(p.get("secs", 30))
		if String(p["gives"]) == "heroism":
			m["hp"] = float(m["hp"]) + 10.0          # 5e: temporary hit points
	var spec: Dictionary = (Roster.potions().get("states", {}) as Dictionary).get(String(p.get("gives", "")), {})
	_float_text(m, String(spec.get("word", p["name"])), Color.html(String(spec.get("colour", "c0ffc0"))))
	_say("%s drinks %s." % [h["name"], p["name"]])

## the states a delver shows: [[word, colour], ...] - the bad first
func statuses(m: Dictionary) -> Array:
	var out: Array = []
	var states: Dictionary = Roster.potions().get("states", {})
	for bad in [true, false]:
		for k in states:
			if bool(states[k]["bad"]) == bad and has_st(m, k):
				out.append([String(states[k]["word"]), Color.html(String(states[k]["colour"]))])
	return out

## the states over each delver's head (on the floor, not the body - HeroBody
## renames every Label3D under it)
var _tags := {}
var _tag_t := 0.0
func _tags_tick(delta: float) -> void:
	_tag_t -= delta
	if _tag_t > 0.0:
		return
	_tag_t = 0.2
	for m in party:
		var uid := String(m["uid"])
		var b: Node3D = m["body"]
		var sts := statuses(m) if float(m["hp"]) > 0.0 else []
		var lb = _tags.get(uid)
		if lb != null and not is_instance_valid(lb):
			lb = null          # freed with the last floor
		if sts.is_empty() or not is_instance_valid(b) or dun == null:
			if lb and is_instance_valid(lb):
				lb.visible = false
			continue
		if lb == null or not is_instance_valid(lb):
			lb = Label3D.new()
			lb.font_size = 36
			lb.offset = Vector2(0, -62)
			lb.pixel_size = 0.01
			lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			lb.no_depth_test = true
			lb.outline_size = 16
			lb.outline_modulate = Color(0, 0, 0, 0.95)
			lb.top_level = true
			dun.info["root"].add_child(lb)
			_tags[uid] = lb
		var words: Array = []
		for s in sts:
			words.append(String(s[0]))
		lb.text = " · ".join(words)
		lb.modulate = sts[0][1]
		lb.visible = true
		# anchored where the name is, pushed down in the billboard's own plane: always just under the name
		lb.global_position = b.global_position + Vector3(0, 2.3, 0)
		# L15: keep the tag readable from far off (same rule as the names)
		var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
		if cam:
			# L21: sized for the director's camera at full screen; with panes up the side-by-side lane camera is
			# ~11 m off and would draw it huge - a fixed close size then (quarter panes do not draw it at all)
			lb.pixel_size = 0.005 if HudDock.split(town) else 0.01 * clampf(cam.global_position.distance_to(lb.global_position) / 22.0, 0.4, 2.5)

## ---- L19: more of the original's voice (data/lore_lines.json)
static var _lore: Dictionary = {}
static func lore() -> Dictionary:
	if _lore.is_empty():
		var f := FileAccess.open("res://data/lore_lines.json", FileAccess.READ)
		if f:
			_lore = JSON.parse_string(f.get_as_text())
	return _lore

## a variant of a stock line (same format arguments), or the stock line
func _pick_line(key: String, stock: String) -> String:
	var opts: Array = lore().get(key, [])
	return String(opts[_rng.randi() % opts.size()]) if not opts.is_empty() else stock

## a delver says something short over their head (not the Chronicle) - at most
## one bark each eight seconds
func _bark(m: Dictionary, kind: String) -> void:
	if float(m.get("hp", 0.0)) <= 0.0 or float(m.get("bark_t", -99.0)) > _t:
		return
	var opts: Array = (lore().get("barks", {}) as Dictionary).get(kind, [])
	if opts.is_empty():
		return
	m["bark_t"] = _t + 8.0
	_say_bubble(m, "\"%s\"" % String(opts[_rng.randi() % opts.size()]))

func _bark_any(kind: String) -> void:
	var al := _alive()
	if not al.is_empty():
		_bark(al[_rng.randi() % al.size()], kind)

## a bark as a speech bubble - the same parchment plate as the crier's in town
## (UiTheme.style_bubble), over the delver's head for three seconds
func _say_bubble(m: Dictionary, text: String) -> void:
	var b: Node3D = m["body"]
	if not is_instance_valid(b) or not b.is_inside_tree() or dun == null:
		return
	var lb := Label3D.new()
	UiTheme.style_bubble(lb)
	lb.width = 360.0
	lb.text = text
	lb.top_level = true
	dun.info["root"].add_child(lb)
	lb.global_position = b.global_position + Vector3(0, 3.4, 0)
	UiTheme.fit_plate(lb)
	var tw := lb.create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(lb.queue_free)

## ---- S2: the fight's sounds (the RPG sound library, Sfx kinds). All positional (Sfx.at).
##   a delver's blow   the weapon's own sound on the swing (sword_swing / dagger_stab /
##                     bow_draw then arrow_shot), then on a hit sword_clash on bone and
##                     armour or hit_impact on flesh; a miss is the swing alone. A shield
##                     calling now and then puts its shield into it (shield_bash).
##   a creature's miss on a shield-bearer: block
##   voices            male_ / female_ (Roster.voice_of): hurt on a hit (sampled: not every
##                     blow; a delver's cries and efforts share one HURT_GAP s), effort on a big swing (a 20, or one
##                     in EFFORT_ODDS), death when they fall (the death sting already ducks
##                     the music)
##   spells            Spells.cast sounds every cast itself (S1: mana_charge + its SOUND) - S3
##                     found S2 layering a second copy here and took it out
##   below             a quiet bed (AMB_KINDS) somewhere off in the dark every AMB_MIN-AMB_MAX s
const HURT_GAP := 2.5
const EFFORT_ODDS := 8
const AMB_KINDS := ["bat_screech", "spider_skitter", "skeleton_rattle", "ghost_wail"]
const AMB_MIN := 9.0
const AMB_MAX := 22.0
const AMB_DB := -16.0
## S3 (measured): the spider and skeleton files are ~10 dB quieter than the bat and the ghost -
## at one level two of the four were 25 dB under the music, i.e. never heard. Trimmed so the
## whole bed sits quiet but present, 12-24 dB under the music.
const AMB_TRIM := {"spider_skitter": 8.0, "skeleton_rattle": 8.0}
const POTION_DB := 4.0
var _amb_t := 6.0
var sounds := {}                   # kind -> times this delve asked for it (tests read it)

func _snd(kind: String, at: Vector3, db := 0.0) -> void:
	if kind == "":
		return
	sounds[kind] = int(sounds.get(kind, 0)) + 1
	Sfx.at(kind, at, db)

func _vox(m: Dictionary, what: String, db := 0.0) -> void:
	var b = m.get("body")
	if is_instance_valid(b) and (b as Node3D).is_inside_tree():
		_snd("%s_%s" % [Roster.voice_of(m["h"]), what], (b as Node3D).global_position + Vector3(0, 1.6, 0), db)

## the swing: which sound a delver's weapon makes
func _swing_snd(h: Dictionary) -> String:
	if String(h.get("class", "")) == "ranger":
		return "bow_draw"
	if roster.weapon_name(h).to_lower().contains("dagger") or String(h.get("class", "")) in ["rogue", "duelist"]:
		return "dagger_stab"
	return "sword_swing"

func _blow_snd(m: Dictionary, tgt: Monster, landed: bool, crit: bool) -> void:
	var h: Dictionary = m["h"]
	var b: Node3D = m["body"]
	var at := b.global_position + Vector3(0, 1.2, 0)
	var sw := _swing_snd(h)
	_snd(sw, at)
	if sw == "bow_draw":
		var to := tgt.global_position + Vector3(0, tgt._height() * 0.6, 0)
		get_tree().create_timer(0.22).timeout.connect(func() -> void: Sfx.at("arrow_shot", at))
		if landed:
			get_tree().create_timer(0.45).timeout.connect(func() -> void: Sfx.at("hit_impact", to))
			sounds["arrow_shot"] = int(sounds.get("arrow_shot", 0)) + 1
	elif landed:
		var hard := String(tgt.def.get("family", "")) in ["undead", "the fallen"] or bool(tgt.def.get("boss", false))
		_snd("sword_clash" if hard else "hit_impact", tgt.global_position + Vector3(0, tgt._height() * 0.55, 0), 2.0 if crit else 0.0)
	if landed and _has_shield(h) and _rng.randi_range(1, 4) == 1:
		_snd("shield_bash", at, -2.0)
	if (crit or _rng.randi_range(1, EFFORT_ODDS) == 1) and _t - float(m.get("cry_t", -99.0)) >= HURT_GAP:
		m["cry_t"] = _t                 # one voice gap a delver, shared by cries and efforts
		_vox(m, "effort", -3.0)

func _has_shield(h: Dictionary) -> bool:
	return String((Roster.CLASSES.get(String(h.get("class", "")), {}) as Dictionary).get("offhand", "")).contains("shield")

## a hurt delver cries out now and then - never every blow
func _hurt_snd(m: Dictionary) -> void:
	if float(m["hp"]) <= 0.0 or _t - float(m.get("cry_t", -99.0)) < HURT_GAP:
		return
	if _rng.randi_range(1, 2) == 1 or float(m["hp"]) < float(m["max"]) * 0.3:
		m["cry_t"] = _t
		_vox(m, "hurt")

func _amb_tick(delta: float) -> void:
	if dun == null or not is_instance_valid(dun) or state == "home":
		return
	_amb_t -= delta
	if _amb_t > 0.0:
		return
	_amb_t = _rng.randf_range(AMB_MIN, AMB_MAX)
	var alive := _alive()
	if alive.is_empty():
		return
	var b: Node3D = alive[0]["body"]
	if not is_instance_valid(b):
		return
	var a := _rng.randf() * TAU
	var k := String(AMB_KINDS[_rng.randi() % AMB_KINDS.size()])
	_snd(k, b.global_position + Vector3(cos(a), 0.3, sin(a)) * _rng.randf_range(10.0, 18.0), AMB_DB + float(AMB_TRIM.get(k, 0.0)))

## L25c: the watchdog. A body that has not got closer to its goal for 2 s (held by a wall and a
## table at once) is set down in the middle of the nearest clear cell and routes afresh.
var unsticks := 0
func _unstick(n: Node3D) -> void:
	var cells: Dictionary = dun.info["cells"]
	var blocked := _blocked_cells()
	var here := _cell_of(n.global_position)
	var best := Vector2i(-9999, -9999)
	var bd := 1e9
	for c: Vector2i in cells:
		if blocked.has(c) or (c == here and _flat(n.global_position, _cell_world(c)) < 0.5):
			continue          # (not where it already stands - that was a loop)
		var d := Vector2(c - here).length()
		if d < bd:
			bd = d
			best = c
	if best.x == -9999:
		return
	var w := _cell_world(best)
	n.global_position = Vector3(w.x, n.global_position.y, w.z)
	_paths.erase(n)
	_prog.erase(n)
	unsticks += 1
