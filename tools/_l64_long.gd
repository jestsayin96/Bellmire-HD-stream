extends SceneTree
## L64 DONE-line run (WINDOWED): 30 min of DIRECTOR clock (time_scale 6), two raids, a death,
## a long quiet stretch. Saves the full decision log + shots to renders/cycles/20261115_l64long/.
## Audits: no repeat inside window, no hold past max, every cut has a why, no pane on the director's body.
var _t: Node3D
var _eye: RtsCamera
var _f := 0
var _raids := [300.0, 1250.0]
var _raid_i := 0
var _death_at := -1.0
var _shots := {}
var _natural_death := false
var _dual := 0
var _streak := 0.0
var _worst := 0.0
var _frames := 0
var _out := ""
const RUN_S := 1800.0
func _initialize() -> void:
	_out = ProjectSettings.globalize_path("res://renders/cycles/20261115_l64long/")
	DirAccess.make_dir_recursive_absolute(_out)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
func _shot(tag: String) -> void:
	if _shots.has(tag):
		return
	_shots[tag] = 1
	root.get_texture().get_image().save_png(_out + "l64_%s.png" % tag)
	print("SHOT l64_%s cur=%s" % [tag, _eye.director._cur.get("key", "-")])
func _process(_d: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		for u in ["1001", "1002", "1003", "1004"]:
			_t.chat_line(u, "Viewer" + u, "!enlist knight")
		for u in ["1001", "1002", "1003", "1004"]:
			_t.chat_line(u, "Viewer" + u, "!delve")
	if _f == 40:
		_eye.director._set_on(true)
		Engine.time_scale = 6.0
	if _f < 60:
		return false
	var d: AutoDirector = _eye.director
	var s = HudDock.spot(_t)
	var dn = d._cur.get("node") if not d._cur.is_empty() else null
	if s != null and dn != null and is_instance_valid(dn):
		_frames += 1
		var hit := false
		for l in Spotlight.LANES:
			if s._target(l) == dn and s.paid_target(l) == null:
				_dual += 1
				hit = true
		if hit:
			_streak += _d / maxf(Engine.time_scale, 0.001)
			_worst = maxf(_worst, _streak)
		else:
			_streak = 0.0
	if _raid_i < _raids.size() and d._clock > _raids[_raid_i]:
		_raid_i += 1
		_t.raids.force_level = 3
		_t.raids.raid("scar")
		print("RAID started at ", d._clock)
	if _raid_i >= 1 and d._clock > _raids[0] + 8.0:
		_shot("raid")
	if _death_at < 0.0 and d._clock > 800.0:
		_death_at = d._clock
		if d._deaths.is_empty():
			d._deaths.append({"key": "death_synthetic_%d" % int(d._clock), "pos": Vector3(0, 0, 0), "t": d._clock})
			print("SYNTHETIC death injected at ", d._clock)
		else:
			_natural_death = true
	if _death_at > 0.0 and d._clock > _death_at + 2.0:
		_shot("death")
	if d._clock > 1000.0 and d._clock < 1200.0 and not (d._raid_active if "_raid_active" in d else false):
		_shot("quiet")
	if d._clock >= RUN_S:
		_audit(d)
		return true
	return false
func _audit(d: AutoDirector) -> void:
	var f := FileAccess.open(_out + "director_decision_log.txt", FileAccess.WRITE)
	for l in d.log_lines:
		f.store_line(l)
	f.close()
	var cuts: Array = []
	var m := RegEx.create_from_string("t=([0-9.]+) CUT (\\S+) shot=(\\S+) pri=([0-9.\\-]+) why=(\\S*)")
	for l in d.log_lines:
		var r := m.search(l)
		if r:
			cuts.append({"t": float(r.get_string(1)), "key": r.get_string(2), "shot": r.get_string(3), "why": r.get_string(5)})
	var bad := 0
	for i in cuts.size():
		var c: Dictionary = cuts[i]
		var story: bool = c["key"] == "raid" or String(c["key"]).begins_with("lord_") or String(c["key"]).begins_with("death_")
		if String(c["key"]).begins_with("tour_"):
			# a place, not a subject: the lap rule (oldest stop first) means it may only recur after the lap
			for j in i:
				if cuts[j]["key"] == c["key"] and float(c["t"]) - float(cuts[j]["t"]) < 20.0:
					print("FAIL tour repeat ", c["key"], " at ", c["t"], " prev ", cuts[j]["t"]); bad += 1
		elif not story:
			for j in i:
				if cuts[j]["key"] == c["key"] and float(c["t"]) - float(cuts[j]["t"]) < AutoDirector.REPEAT_WINDOW:
					print("FAIL repeat ", c["key"], " at ", c["t"], " prev ", cuts[j]["t"]); bad += 1
		if c["why"] == "":
			print("FAIL no why at ", c["t"]); bad += 1
		if i + 1 < cuts.size():
			var hold: float = float(cuts[i + 1]["t"]) - float(c["t"])
			var mx: float = float(AutoDirector.SHOTS.get(c["shot"], {"max": 22.0})["max"]) * 1.4 + 2.0
			# a gap closed by "start" is a manual-input pause (someone touched the machine): not a hold
			if hold > mx and cuts[i + 1]["why"] != "shot_gone" and cuts[i + 1]["why"] != "start":
				print("FAIL hold ", c["key"], " ", hold, " > ", mx); bad += 1
	var shots := {}
	for c in cuts:
		shots[c["shot"]] = int(shots.get(c["shot"], 0)) + 1
	print("L64_LONG cuts=%d shots=%s natural_death=%s bad=%d dual_ambient_frames=%d of %d worst_streak_s=%.2f" % [cuts.size(), shots, _natural_death, bad, _dual, _frames, _worst])
	print("L64_LONG ", "OK" if bad == 0 and cuts.size() >= 20 and _worst <= 1.6 else "FAIL")
