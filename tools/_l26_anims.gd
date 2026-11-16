extends SceneTree
## L26a ANIM AUDIT (headless; logic + clip names, no visuals):
##   godot --headless --path . --script tools/_l26_anims.gd
## A: every bestiary def (creatures, L1 types, the lords, the uniques) - each fight key resolves
##    through Monster.clip_for (with its fallback chain) to a clip the body really has; a missing
##    hit is covered by the procedural flinch; impact() lands inside the swing.
## B: live delves (L26_FLOORS, default "2,5,9"): every frame a creature MOVES, what is it playing?
##    idle / nothing = STATIC (the glide this item hunts). Also counts runs, swings, flinches and
##    blows landed on the contact frame. Prints MON_ANIMS static=N and L26A_ANIMS OK/FAIL.
const KEYS := ["idle", "walk", "run", "attack", "die"]
var _fail := 0
var _mons: Array = []
var _f := 0
var _d: Delve
var _r: Roster
var _floors: Array = []
var _live := {}
var _last_pos := {}
var _static := 0
var _moving := 0
var _running := 0
var _swung := 0
var _flinch0 := {}
var _flinches := 0
var _blows := 0
var _floor_f := 0

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _initialize() -> void:
	var fl := OS.get_environment("L26_FLOORS")
	for s in (fl if fl != "" else "2,5,9").split(","):
		_floors.append(int(s))
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
	print("A: every def resolves its fight clips (fallbacks allowed)")
	var defs_static := 0
	for m in _mons:
		var mo: Monster = m
		var lab := String(mo.get_meta("label"))
		var an: Dictionary = mo.def.get("anims", {})
		var got: Array = []
		var miss: Array = []
		var keys: Array = KEYS.duplicate()
		if bool(mo.def.get("casts", false)) or an.has("cast"):
			keys.append("cast")
		for k in ["rise", "summon", "attack2"]:
			if an.has(k):
				keys.append(k)
		for k in keys:
			var c := mo.clip_for(k)
			if c == "":
				miss.append(k)
			else:
				got.append("%s=%s%s" % [k, c, "" if c == String(an.get(k, "")) else "*"])
		var hit := mo.clip_for("hit")
		got.append("hit=" + (hit if hit != "" else "(flinch)"))
		var ok := mo._ap != null and miss.is_empty()
		if not ok:
			defs_static += 1
		print("  %-26s %s | %s%s" % [lab, String(mo.def.get("path", "")).get_file(), " ".join(got),
			"" if miss.is_empty() else " | MISSING " + str(miss)])
		_ok(ok, "%s: every fight key plays a real clip" % lab)
		if mo._ap:
			mo._play_now("attack")
			var t := mo.impact()
			_ok(t > 0.1 and t < 0.65, "%s: impact %.2f s inside the swing" % [lab, t])
		mo.queue_free()
	print("MON_ANIMS_DEFS static=%d" % defs_static)

func _next_floor() -> bool:
	if _d:
		_d.queue_free()
		_d = null
	if _r:
		_r.queue_free()
		_r = null
	if _floors.is_empty():
		return false
	var fl: int = _floors.pop_front()
	print("B: live delve on floor %d" % fl)
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
	_d.start_floor = fl
	_d.max_floors = fl
	root.add_child(_d)
	_d.start(ids)
	for m in _d.party:
		m["max"] = float(m["max"]) * 5.0
		m["hp"] = m["max"]
	_floor_f = 0
	_last_pos.clear()
	return true

func _sample() -> void:
	if _d.dun == null or not is_instance_valid(_d.dun):
		return
	for f in _d._foes():
		var mo: Monster = f
		var id := mo.get_instance_id()
		if not _flinch0.has(id):
			_flinch0[id] = 0
		_flinches += mo.flinches - int(_flinch0[id])
		_flinch0[id] = mo.flinches
		if mo._ap == null or mo._entering():
			continue
		var an: Dictionary = mo.def.get("anims", {})
		var cur := String(mo._ap.current_animation)
		var nm := String(mo.def.get("name", "?"))
		if not _live.has(nm):
			_live[nm] = {"moving": 0, "static": 0, "run": 0, "swing": 0}
		var p := mo.global_position
		if _last_pos.has(id) and Vector2(p.x - (_last_pos[id] as Vector3).x, p.z - (_last_pos[id] as Vector3).z).length() > 0.01:
			_moving += 1
			_live[nm]["moving"] += 1
			if cur == "" or not mo._ap.is_playing() or (cur == String(an.get("idle", "")) and cur != String(an.get("walk", ""))):
				_static += 1
				_live[nm]["static"] += 1
			if cur == mo.clip_for("run") and mo.clip_for("run") != mo.clip_for("walk"):
				_running += 1
				_live[nm]["run"] += 1
		_last_pos[id] = p
		if cur != "" and (cur == mo.clip_for("attack") or cur == String(an.get("attack2", "")) or cur == mo.clip_for("cast")):
			_swung += 1
			_live[nm]["swing"] += 1

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 10:
		_report()
		_next_floor()
		return false
	if _d == null:
		return false
	_sample()
	_floor_f += 1
	if _d.state == "home" or _floor_f > 60 * 75:
		_blows += _d.blows_landed
		if not _next_floor():
			for nm in _live:
				var e: Dictionary = _live[nm]
				print("    live %-24s moving %5d  static %3d  running %4d  swinging %4d" % [nm, e["moving"], e["static"], e["run"], e["swing"]])
			print("MON_ANIMS static=%d (of %d moving frames), running %d, swinging %d, flinches %d, blows landed on contact %d" % [
				_static, _moving, _running, _swung, _flinches, _blows])
			_ok(_moving > 0 and _static == 0, "no creature moves while standing still in its clip (static %d)" % _static)
			_ok(_swung > 0, "creatures are seen swinging")
			_ok(_blows > 0, "melee blows land on the contact frame (%d)" % _blows)
			print("L26A_ANIMS OK" if _fail == 0 else "L26A_ANIMS FAIL %d" % _fail)
			return true
	return false
