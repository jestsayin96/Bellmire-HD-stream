extends SceneTree
## Every bestiary def (creatures, the L1 ones, the eight lords, the uniques):
## its model, whether an AnimationPlayer was found, its animations, and which
## of def.anims (idle/walk/run/attack/cast/hit/die/rise) really exist - a
## missing name means Monster._play() silently does nothing. Then a LIVE check:
## a real delve, sampling what each creature is actually playing while it
## moves and fights. Prints MON_ANIMS OK when every def has idle + walk +
## attack and creatures really walk and swing in a fight.
const KEYS := ["idle", "walk", "run", "attack", "cast", "hit", "die", "rise"]
var _fail := 0
var _mons: Array = []
var _f := 0
var _d: Delve
var _r: Roster
var _live := {}          # instance id -> {"walk": n, "attack": n, "moving": n, "name": s}
var _last_pos := {}

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _initialize() -> void:
	var defs: Array = []
	for k in Bestiary.all_keys():
		defs.append(["creature " + String(k), Bestiary.make(String(k), "plain")])
	for k in Bestiary.BOSS_DEFS:
		var b: Dictionary = (Bestiary.BOSS_DEFS[k] as Dictionary).duplicate()
		b["id"] = k
		defs.append(["lord " + String(k), Bestiary.boss_def(b)])
	Bestiary.memorial = [{"name": "Wren", "class": "ranger", "killed_by": "the dark below"}]
	for k in Bestiary.UNIQUES:
		Bestiary.only_unique = String(k)
		Bestiary._last_unique = ""
		var u := Bestiary.unique_for(7, 0.0)
		defs.append(["unique " + String(k), Bestiary.unique_def(u, 7)])
	Bestiary.only_unique = ""
	for e in defs:
		var m := Monster.new()
		m.def = e[1]
		m.set_meta("label", e[0])
		root.add_child(m)
		_mons.append(m)

func _report() -> void:
	print("A: every def's animations")
	for m in _mons:
		var mo: Monster = m
		var lab := String(mo.get_meta("label"))
		var an: Dictionary = mo.def.get("anims", {})
		var have: Array = []
		var miss: Array = []
		for k in KEYS:
			if not an.has(k):
				continue
			if mo._ap and mo._ap.has_animation(String(an[k])):
				have.append(k)
			else:
				miss.append("%s=%s" % [k, an[k]])
		var all := mo._ap.get_animation_list() if mo._ap else PackedStringArray()
		print("  %s | %s | player %s | %d anims | has %s | MISSING %s" % [lab, String(mo.def.get("path", "")).get_file(), mo._ap != null, all.size(), have, miss])
		_ok(mo._ap != null and have.has("idle") and have.has("walk") and have.has("attack"), "%s has idle + walk + attack" % lab)
		mo.queue_free()

func _start_live() -> void:
	print("B: live - what creatures actually play in a fight")
	_r = Roster.new()
	root.add_child(_r)
	var ids := []
	for i in 4:
		var h: Dictionary = _r.fresh("v%d" % i, "V%d" % i, ["knight", "barbarian", "cleric", "ranger"][i], "human")
		h["weapon"] = 1
		h["armour"] = 4
		h["oil"] = 5
		ids.append("v%d" % i)
	_d = Delve.new()
	_d.roster = _r
	_d.start_floor = int(OS.get_environment("MON_FLOOR")) if OS.get_environment("MON_FLOOR") != "" else 5
	_d.max_floors = _d.start_floor
	root.add_child(_d)
	_d.start(ids)
	for m in _d.party:
		m["max"] = float(m["max"]) * 5.0
		m["hp"] = m["max"]

func _sample() -> void:
	if _d.dun == null or not is_instance_valid(_d.dun):
		return
	for f in _d._foes():
		var mo: Monster = f
		if mo._ap == null:
			continue
		var id := mo.get_instance_id()
		if not _live.has(id):
			_live[id] = {"walk": 0, "attack": 0, "moving": 0, "name": String(mo.def.get("name", "?"))}
		var an: Dictionary = mo.def.get("anims", {})
		var cur := String(mo._ap.current_animation)
		var p := mo.global_position
		if _last_pos.has(id) and (p - (_last_pos[id] as Vector3)).length() > 0.01:
			_live[id]["moving"] += 1
			if cur == String(an.get("walk", "")) or cur == String(an.get("run", "")):
				_live[id]["walk"] += 1
		_last_pos[id] = p
		if cur == String(an.get("attack", "")) or cur == String(an.get("cast", "")):
			_live[id]["attack"] += 1

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 10:
		_report()
		_start_live()
		return false
	if _d == null:
		return false
	_sample()
	if _d.state == "home" or _f > 60 * 90:
		var movers := 0
		var walked := 0
		var swung := 0
		for id in _live:
			var e: Dictionary = _live[id]
			if int(e["moving"]) > 20:
				movers += 1
				if float(e["walk"]) / float(e["moving"]) > 0.6:
					walked += 1
			if int(e["attack"]) > 0:
				swung += 1
			print("    live %s: moving %d frames, walk anim on %d of them, attack/cast playing %d frames" % [e["name"], e["moving"], e["walk"], e["attack"]])
		_ok(movers > 0 and walked == movers, "creatures that move play their walk (%d of %d)" % [walked, movers])
		_ok(swung > 0, "creatures are seen swinging (%d of %d)" % [swung, _live.size()])
		print("MON_ANIMS OK" if _fail == 0 else "MON_ANIMS FAIL %d" % _fail)
		return true
	return false
