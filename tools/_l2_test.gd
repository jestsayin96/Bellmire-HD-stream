extends SceneTree
## L2 (work plan 2): lords and rare uniques, each with a mechanic.
## A: the lord bags never deal the same lord twice running; every lord carries
##    its mechanic. B: uniques turn up only on ordinary floors, never twice
##    running; "Kept by the Scar" takes a name from the memorial.
## C: every lord and unique fought in a real delve; its mechanic must fire and
##    the boss bar's lord_fighting() must see it. Prints L2_TEST OK.
var _fail := 0
var _f := 0
var _queue: Array = []
var _cur: Dictionary = {}
var _d: Delve
var _r: Roster
var _t0 := 0
var _seen := {}
var _chipped := false

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _initialize() -> void:
	print("A: bags and mechanics")
	var last := ""
	var twice := false
	var seen_l := {}
	for i in range(60):
		var fl := 5 + 10 * i if i % 2 == 0 else 10 + 10 * i
		var b := Bestiary.next_boss(fl)
		if String(b["id"]) == last:
			twice = true
		last = String(b["id"])
		seen_l[last] = true
	_ok(not twice, "60 lords drawn, never the same one twice running")
	_ok(seen_l.size() == 8, "all eight lords drawn (%d)" % seen_l.size())
	for k in Bestiary.BOSS_DEFS:
		var b: Dictionary = (Bestiary.BOSS_DEFS[k] as Dictionary).duplicate()
		b["id"] = k
		var w: Dictionary = Bestiary.boss_def(b)["ways"]
		_ok(not w.is_empty(), "%s has a mechanic %s" % [k, w.keys()])
	print("B: uniques")
	Bestiary.memorial = [{"name": "Wren", "class": "ranger", "killed_by": "the dark below"}]
	var lastu := ""
	var rep := false
	var on_lord := false
	var got := {}
	for i in range(200):
		var fl := 2 + i % 12
		var u := Bestiary.unique_for(fl, 0.0)
		if Bestiary.is_boss_floor(fl):
			if not u.is_empty():
				on_lord = true
			continue
		if u.is_empty():
			continue
		if String(u["id"]) == lastu:
			rep = true
		lastu = String(u["id"])
		got[lastu] = String(u["title"])
	_ok(not on_lord, "no unique on a lord's floor")
	_ok(not rep, "a unique never twice running")
	_ok(got.size() == Bestiary.UNIQUES.size(), "every unique turned up %s" % [got.values()])
	_ok(String(got.get("kept", "")).begins_with("Wren"), "the memorial names the kept: %s" % got.get("kept", "?"))
	_ok(Bestiary.unique_for(4, 0.5).is_empty(), "no unique when the roll misses")
	Bestiary.memorial = []
	Bestiary.only_unique = "kept"
	_ok(Bestiary.unique_for(4, 0.0).is_empty(), "no kept one with an empty memorial")
	Bestiary.only_unique = ""
	if OS.get_environment("L2_ONLY") != "":
		for k in OS.get_environment("L2_ONLY").split(","):
			_queue.append({"lord": k, "floor": 10 if k in Bestiary.GREATER else 5} if Bestiary.BOSS_DEFS.has(k) else {"unique": k, "floor": 7})
		print("C: fights")
		return
	for k in Bestiary.LESSER:
		_queue.append({"lord": k, "floor": 5})
	for k in Bestiary.GREATER:
		_queue.append({"lord": k, "floor": 10})
	for k in Bestiary.UNIQUES:
		_queue.append({"unique": k, "floor": 7})
	print("C: fights")

func _next() -> void:
	_cur = _queue.pop_front()
	_seen = {}
	_chipped = false
	Bestiary.memorial = [{"name": "Wren", "class": "ranger", "killed_by": "the dark below"}]
	if _cur.has("lord"):
		var bag: Array = Bestiary.LESSER if int(_cur["floor"]) == 5 else Bestiary.GREATER
		Bestiary._spent = bag.duplicate()
		Bestiary._spent.erase(_cur["lord"])
		Bestiary._last_lord = ""
		DungeonHD.force_unique = -1.0
		Bestiary.only_unique = ""
	else:
		DungeonHD.force_unique = 0.0
		Bestiary.only_unique = String(_cur["unique"])
	_r = Roster.new()
	root.add_child(_r)
	var V := [["3001", "Ashe", "knight"], ["3002", "Bram", "cleric"], ["3003", "Cass", "barbarian"], ["3004", "Dov", "ranger"], ["3005", "Eda", "mage"]]
	var ids := []
	for v in V:
		var h: Dictionary = _r.fresh(v[0], v[1], v[2])
		h["weapon"] = 2
		h["armour"] = 3
		h["oil"] = 6
		ids.append(v[0])
	_r.fallen = [{"name": "Wren", "class": "ranger", "killed_by": "the dark below"}]
	_d = Delve.new()
	_d.roster = _r
	_d.start_floor = int(_cur["floor"])
	_d.max_floors = int(_cur["floor"])
	root.add_child(_d)
	_d.start(ids)
	for m in _d.party:
		m["max"] = float(m["max"]) * 8.0
		m["hp"] = m["max"]
	_t0 = _f

func _process(_dt: float) -> bool:
	_f += 1
	if _d == null:
		if _queue.is_empty():
			DungeonHD.force_unique = -1.0
			Bestiary.only_unique = ""
			print("L2_TEST OK" if _fail == 0 else "L2_TEST FAIL %d" % _fail)
			return true
		_next()
		return false
	var lord: Monster = null
	if _d.dun and is_instance_valid(_d.dun) and _d.dun.lord and is_instance_valid(_d.dun.lord):
		lord = _d.dun.lord
	var want := String(_cur.get("lord", _cur.get("unique", "")))
	if lord:
		_seen["id"] = String(lord.def.get("id", ""))
		var close := false
		for m in _d.party:
			if float(m["hp"]) > 0.0 and _d._flat((m["body"] as Node3D).global_position, lord.global_position) < 15.0:
				close = true
		if _d.lord_fighting() == lord:
			_seen["bar"] = true
		if _d.lord_fighting() == lord and close:
			if _chipped and _f % 60 == 0 and lord.hp > lord.max_hp * 0.05:
				lord.hurt(lord.max_hp * 0.012)
			if not _chipped:
				_chipped = true
				lord.max_hp *= 3.0
				lord.hp = lord.max_hp * 0.72        # so the marks below 2/3 and the enrage come in a short test
		var w: Dictionary = lord.def.get("ways", {})
		if OS.get_environment("L2_ONLY") != "" and _f % 60 == 0:
			print("    dbg hp ", snappedf(lord.hp / lord.max_hp, 0.01), " raise_t ", lord.get_meta("raise_t", -1), " called ", _d._live_called(lord).size(), " pos ", lord.global_position.snapped(Vector3.ONE), " hero0 ", (_d.party[0]["body"] as Node3D).global_position.snapped(Vector3.ONE), " enraged ", lord.enraged, " state ", lord.state, " fighting ", _d.lord_fighting() == lord)
		if w.has("summon") and not _d._live_called(lord).is_empty():
			_seen["summon"] = true
		if w.has("nova") and lord.nova_count > 0:
			_seen["nova"] = true
		if w.has("shed") and int(lord.get_meta("shed_n", 0)) > 0:
			_seen["shed"] = true
		if w.has("swoop") and lord.has_meta("swoop_t") and float(lord.get_meta("swoop_t")) > float((w["swoop"] as Dictionary)["every"]) - 0.1:
			_seen["swoop"] = true
		if w.has("enrage") and lord.enraged:
			_seen["enrage"] = true
		if w.has("ward") and _d._ward(lord) < 1.0:
			_seen["ward"] = true
		if w.has("breath") and lord.shots > 0:
			_seen["breath"] = true
		if w.has("volley") and lord.shots > 2:
			_seen["volley"] = true
	var over := _d.state == "home" or _f - _t0 > 60 * 150
	if over:
		var w2: Dictionary = {}
		if _cur.has("lord"):
			var b: Dictionary = (Bestiary.BOSS_DEFS[want] as Dictionary).duplicate()
			b["id"] = want
			w2 = Bestiary.boss_def(b)["ways"]
		else:
			w2 = Bestiary.UNIQUES[want]["ways"]
		_ok(String(_seen.get("id", "")) == want, "%s: the right one held the floor (%s)" % [want, _seen.get("id", "none")])
		_ok(bool(_seen.get("bar", false)), "%s: the boss bar saw it fight" % want)
		for k in ["summon", "nova", "shed", "swoop", "enrage", "ward", "breath", "volley"]:
			if w2.has(k):
				_ok(bool(_seen.get(k, false)), "%s: %s fired" % [want, k])
		print("    ", want, " ended ", _d.state, " after ", (_f - _t0) / 60, " s; kills ", _d._kills)
		_d.queue_free()
		_r.queue_free()
		_d = null
	return false
