extends SceneTree
## L73 (HUD): the director's shot language - establish on a delve's start, tighten as a fight turns,
## hold on a death, a breath after. WINDOWED 1920x1080. Prints L73_TEST lines; PNGs in OUT.
var _t: Node3D
var _eye: RtsCamera
var _d: Delve
var _f := 0
var _stage := "boot"
var _t0 := 0
var _fails := 0
var _est_t := -1.0
var _est := {}
var _tight := {}
var _death_t := -1.0
var _shots := {}
const OUT := "res://renders/cycles/20261116_l73"

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _say(uid: String, nm: String, msg: String) -> void:
	var c: ChatCmd = _t.get("chat")
	c._last.clear()
	_t.call("chat_line", uid, nm, msg)

func _save(tag: String) -> void:
	if _shots.has(tag):
		return
	_shots[tag] = true
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/" + tag + ".png"))

func _el() -> float:
	return float(Time.get_ticks_msec() - _t0) / 1000.0

func _process(_dt: float) -> bool:
	_f += 1
	var dr: AutoDirector = null if _eye == null else _eye.director
	if _stage == "boot" and _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		var r: Roster = _t.get("roster")
		for v in [["2101", "JestFan", "knight dwarf"], ["2104", "BigAxe", "barbarian orc"]]:
			_say(v[0], v[1], "!enlist " + v[2])
		_d = Delve.new()
		_d.town = _t
		_d.roster = r
		_d.start_floor = 3
		_d.max_floors = 3
		_t.add_child(_d)
		_d.start(["2104", "2101"])
		_eye.director._set_on(true)
		Engine.time_scale = 2.0
		_t0 = Time.get_ticks_msec()
		_stage = "run"
	if _stage == "run" and dr != null:
		var el := _el()
		var cur: Dictionary = dr._cur
		var note := String(cur.get("note", ""))
		# ESTABLISH: sample the first delve-start shot
		if note.begins_with("delve start"):
			if _est_t < 0.0:
				_est_t = el
				_est = {"d0": _eye.dist, "want": float(cur.get("to", cur.get("dist", 22.0)))}
				_save("establish_t0")
			var age := el - _est_t
			if age > 6.5 and not _est.has("d6"):
				_est["d6"] = _eye.dist
				_save("establish_t6")
		# TIGHTEN: in a fight, record dist fresh, then wound the party and record again
		if String(cur.get("key", "")).begins_with("fight_") and not _d._alive().is_empty():
			if not _tight.has("t") and dr._held > 3.0:
				_tight = {"t": el, "d0": _eye.dist, "hurt0": float(cur.get("hurt", 0.0))}
				_save("fight_fresh")
			elif _tight.has("t") and not _tight.has("d1") and not _tight.has("wounded"):
				for m in _d._alive():
					m["hp"] = maxf(float(m["max"]) * 0.2, 1.0)
				_tight["wounded"] = el
			elif _tight.has("wounded") and not _tight.has("d1") and el - float(_tight["wounded"]) > 7.0:
				_tight["d1"] = _eye.dist
				_tight["hurt1"] = float(cur.get("hurt", 0.0))
				_save("fight_hurt")
			elif _tight.has("d1") and _death_t < 0.0:
				var al: Array = _d._alive()
				if al.size() > 1:
					_death_t = el
					al[0]["hp"] = 0.0           # a delver falls
					print("L73_TEST killed a delver at %.1fs" % el)
		if _death_t > 0.0 and String(cur.get("shot", "")) == "hard_cut":
			_save("death_hold")
		if String(cur.get("shot", "")) == "breath":
			_save("breath")
		if int(el * 2.0) != int((el - _dt) * 2.0) and int(el) % 2 == 0:
			pass
		if el > 330.0 or (_death_t > 0.0 and el - _death_t > 30.0):
			_finish()
	return false

func _finish() -> void:
	var dr: AutoDirector = _eye.director
	for l in dr.log_lines:
		print("L73_LOG ", String(l).left(170))
	print("L73_TEST establish ", _est)
	print("L73_TEST tighten ", _tight)
	if not _est.has("d6") or float(_est["d0"]) < float(_est["want"]) * 1.4 or absf(float(_est["d6"]) - float(_est["want"])) > 6.0:
		_fails += 1
		print("L73_TEST FAIL establish")
	if not _tight.has("d1") or float(_tight["d1"]) > 20.0 * (1.0 - 0.38 * float(_tight.get("hurt1", 0.0))) + 1.5:
		_fails += 1
		print("L73_TEST FAIL tighten")
	# death -> hold >= hold_min -> breath
	var seq := dr.log_lines
	var ok_hold := false
	var ok_breath := false
	for i in seq.size():
		var l := String(seq[i])
		if "shot=hard_cut" in l and i + 1 < seq.size():
			var nx := String(seq[i + 1])
			var m := nx.split("held_prev=")
			if m.size() > 1 and float(m[1].split(" ")[0]) >= 3.0:
				ok_hold = true
			if "shot=breath" in nx and "why=breath" in nx:
				ok_breath = true
	print("L73_TEST death hold>=3s %s, breath after %s" % [ok_hold, ok_breath])
	if not ok_hold:
		_fails += 1
	if not ok_breath:
		_fails += 1
	print("L73_TEST DONE fails=%d" % _fails)
	quit(0)
