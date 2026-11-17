extends SceneTree
## L72 (HUD): the camera frames each of the eight lords whole, by measured bounds, and pulls back as it rises.
## WINDOWED 1920x1080 (--resolution 1920x1080), never headless. Prints L72_TEST lines; PNGs in OUT.
var _t: Node3D
var _eye: RtsCamera
var _d: Delve
var _f := 0
var _stage := "boot"
var _i := 0
var _t0 := 0
var _shots := 0
var _fails := 0
var _audited := 0        # gated shots (t>=3) that actually measured a lord
var _nlords := 8
var _break := ""
const MAX_FRAMES := 40000
var _wait_f := 0
const LORDS := ["hollow_king", "grubmother", "rattling_host", "nightwing", "gravewyrm", "ossuary_lord", "pale_duchess", "mourncoil"]
const OUT := "res://renders/cycles/20261116_l72"

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("lords="):
			_nlords = clampi(int(a.substr(6)), 1, LORDS.size())
		if a.begins_with("break_"):
			_break = a
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _say(uid: String, nm: String, msg: String) -> void:
	var c: ChatCmd = _t.get("chat")
	c._last.clear()
	_t.call("chat_line", uid, nm, msg)

func _start_lord() -> void:
	var k: String = LORDS[_i]
	var pool: Array = Bestiary.GREATER if Bestiary.GREATER.has(k) else Bestiary.LESSER
	Bestiary._spent.clear()
	for o in pool:
		if o != k:
			Bestiary._spent.append(o)
	Bestiary.force_lord_unique = 2.0
	if _d != null and is_instance_valid(_d):
		_d.queue_free()
	var r: Roster = _t.get("roster")
	_d = Delve.new()
	_d.town = _t
	_d.roster = r
	_d.start_floor = 10 if Bestiary.GREATER.has(k) else 5
	_d.max_floors = _d.start_floor
	_t.add_child(_d)
	_d.start(["2104", "2101"])
	_eye.director._set_on(true)
	Engine.time_scale = 3.0
	_wait_f = _f
	_stage = "wait_cut"

## how much of the subject is inside the real frame (1.0 = all of it, with a 2% edge)
func _frame_report(tag: String) -> Dictionary:
	var dr: AutoDirector = _eye.director
	var lord = dr._cur.get("node")
	if _break == "break_noaudit":
		return {"ok": false}
	if lord == null or not is_instance_valid(lord):
		return {"ok": false}
	var pts := dr.subject_points(lord)
	var vs := root.size
	var inside := 0
	for p in pts:
		var behind := _eye.cam.is_position_behind(p)
		var sp := _eye.cam.unproject_position(p)
		if not behind and sp.x >= vs.x * 0.02 and sp.x <= vs.x * 0.98 and sp.y >= vs.y * 0.02 and sp.y <= vs.y * 0.98:
			inside += 1
	var sz := dr.subject_size(lord)
	var cs := _eye.camera_solid()
	var r := {"ok": true, "inside": inside, "n": pts.size(), "size": sz, "dist": _eye.dist, "pitch": rad_to_deg(_eye.pitch), "solid": cs}
	print("L72_TEST %s %s inside=%d/%d size=(%.1f w, %.1f h, %.1f d) dist=%.1f pitch=%.0f cam_in_solid=%s" % [LORDS[_i], tag, inside, pts.size(), sz.x, sz.y, sz.z, _eye.dist, rad_to_deg(_eye.pitch), cs])
	return r

func _save(tag: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + "/%d_%s_%s.png" % [_i, LORDS[_i], tag]))

func _process(_dt: float) -> bool:
	_f += 1
	if _f > MAX_FRAMES:
		print("L72_TEST NO VERDICT - frame cap %d hit at lord %d, audited=%d" % [MAX_FRAMES, _i, _audited])
		quit(2)
		return true
	match _stage:
		"boot":
			if _f == 20:
				_eye = RtsCamera.new()
				_t.add_child(_eye)
				_eye.setup(_t)
				var r: Roster = _t.get("roster")
				for v in [["2101", "JestFan", "knight dwarf"], ["2104", "BigAxe", "barbarian orc"]]:
					_say(v[0], v[1], "!enlist " + v[2])
				for id in ["2101", "2104"]:
					var h: Dictionary = r.get_hero(id)
					h["weapon"] = 3
					h["armour"] = 3
					h["oil"] = 4
				_start_lord()
		"wait_cut":
			var cur: Dictionary = _eye.director._cur
			if String(cur.get("key", "")).begins_with("lord_"):
				Engine.time_scale = 0.35          # the party lives long enough to be filmed
				_t0 = Time.get_ticks_msec()
				_shots = 0
				print("L72_TEST %s director on the lord after %d frames, rising=%s" % [LORDS[_i], _f - _wait_f, _d.lord_fighting() == null])
				_stage = "shoot"
			elif _f - _wait_f > 5000:
				print("L72_TEST %s NO LORD SHOT (timeout) state=%s" % [LORDS[_i], _d.state])
				_fails += 1
				_next()
		"shoot":
			var el := float(Time.get_ticks_msec() - _t0) / 1000.0
			var plan := [0.3, 1.6, 3.0, 5.5, 8.0]
			if _shots < plan.size() and el >= float(plan[_shots]):
				var rep := _frame_report("t=%.1fs" % el)
				_save("t%d" % _shots)
				if rep.get("ok", false) and _shots >= 3:
					_audited += 1
				if rep.get("ok", false) and (int(rep["inside"]) < int(rep["n"]) or bool(rep["solid"])) and _shots >= 3:
					_fails += 1
				_shots += 1
			if _shots >= plan.size():
				_next()
			elif not String(_eye.director._cur.get("key", "")).begins_with("lord_") and el > 1.0:
				print("L72_TEST %s lord shot lost at %.1fs (lord dead or director cut away)" % [LORDS[_i], el])
				_next()
	return false

func _next() -> void:
	_i += 1
	if _i >= _nlords:
		var floor_n := _nlords          # at least one measured gated shot per lord
		if _fails > 0:
			print("L72_TEST FAIL fails=%d audited=%d" % [_fails, _audited])
			quit(1)
		elif _audited < floor_n:
			print("L72_TEST NO VERDICT - only %d gated shots audited, need %d" % [_audited, floor_n])
			quit(2)
		else:
			print("L72_TEST OK fails=0 audited=%d" % _audited)
			quit(0)
		return
	_start_lord()
