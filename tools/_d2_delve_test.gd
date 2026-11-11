extends SceneTree
## D2 laptop half: the delve's casters use the D2 spells, and a monster's health
## bar no longer climbs. Prints D2_DELVE OK.
var _fail := 0
var _d: Delve
var _r: Roster
var _f := 0
var kinds := {}
var seen := {"renew": false, "ward": false, "slowed": false}
var bars := {}          # bar instance id -> [first y, max y]

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _initialize() -> void:
	_r = Roster.new()
	root.add_child(_r)
	var ids := []
	var cls := ["mage", "sage", "cleric", "necromancer", "druid", "warlock", "knight"]
	for i in cls.size():
		var h: Dictionary = _r.fresh("c%d" % i, "Caster%d" % i, cls[i], "human")
		h["weapon"] = 2
		h["armour"] = 2
		h["oil"] = 5
		ids.append("c%d" % i)
	_d = Delve.new()
	_d.roster = _r
	_d.start_floor = 3
	_d.max_floors = 4
	root.add_child(_d)
	_d.start(ids)
	for m in _d.party:
		m["max"] = float(m["max"]) * 4.0     # long enough to see the menders work
		m["hp"] = m["max"]

func _process(_dt: float) -> bool:
	_f += 1
	if Spells.last.has("kind"):
		kinds[String(Spells.last["kind"])] = true
	for m in _d.party:
		if float(m.get("hot_t", 0.0)) > 0.0:
			seen["renew"] = true
		if float(m.get("ward_t", 0.0)) > 0.0:
			seen["ward"] = true
		# keep someone hurt so the menders have work
		if _f in [600, 1800] and float(m["hp"]) > 0.0:
			m["hp"] = float(m["max"]) * 0.4
	if _d.dun and is_instance_valid(_d.dun):
		for mo in _d.dun.monsters:
			if not is_instance_valid(mo):
				continue
			if (mo as Monster).has_meta("slow_t"):
				seen["slowed"] = true
			if (mo as Monster).state == Monster.S.DEAD:
				continue
			for c in (mo as Node).get_children():
				if c is HealthBar3D and (c as Node3D).visible:
					var id := c.get_instance_id()
					var y := (c as Node3D).position.y
					if not bars.has(id):
						bars[id] = [y, y]
					bars[id][1] = maxf(float(bars[id][1]), y)
	if _d.state == "home" or _f > 60 * 150:
		for k in ["bolt", "chain", "fire", "frost", "smite", "renew", "ward"]:
			_ok(kinds.has(k), "the delve cast %s" % k)
		for k in seen:
			_ok(seen[k], "seen: %s" % k)
		var climb := 0.0
		for id in bars:
			climb = maxf(climb, float(bars[id][1]) - float(bars[id][0]))
		_ok(bars.size() > 0 and climb < 0.3, "monster bars hold their height (%d bars, worst rise %.2f m)" % [bars.size(), climb])
		_ok(_d._kills > 0, "spells killed things (%d kills, floor %d, %s)" % [_d._kills, _d.floor_no, _d.state])
		print("D2_DELVE OK" if _fail == 0 else "D2_DELVE FAIL %d" % _fail)
		return true
	return false
