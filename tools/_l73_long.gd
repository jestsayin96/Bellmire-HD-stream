extends SceneTree
## L73 DONE-line capture (WINDOWED 1920x1080): 12 min of DIRECTOR clock (1800 s did not fit a lock slot: the clock ran ~0.4 s per wall second under load), shaped like L64's run
## but with the events the shot language is about: two delves setting out, two raids, two real deaths, quiet between.
## Samples the camera every 0.5 director-seconds (dist, pitch, shot, key) and stills at each event. Prints L73_LONG lines.
var _t: Node3D
var _eye: RtsCamera
var _d1: Delve
var _d2: Delve
var _f := 0
var _out := ""
var _rows: Array = []
var _events: Array = []          # {name, t}
var _shots := {}
var _next_s := 0.0
var _raid_i := 0
var _kill_i := 0
var _d2_started := false
const RAIDS := [100.0, 520.0]
const KILLS := [220.0, 620.0]
const D2_AT := 400.0
const RUN_S := 720.0
const OUT := "res://renders/cycles/20261116_l73long/"

func _initialize() -> void:
	_out = ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(_out)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)

func _say(uid: String, nm: String, msg: String) -> void:
	_t.call("chat_line", uid, nm, msg)

func _shot(tag: String) -> void:
	if _shots.has(tag):
		return
	_shots[tag] = 1
	root.get_texture().get_image().save_png(_out + "l73_%s.png" % tag)
	print("SHOT l73_%s shot=%s key=%s dist=%.1f" % [tag, _eye.director._cur.get("shot", "-"), _eye.director._cur.get("key", "-"), _eye.dist])

func _mkdelve(ids: Array, floor_n: int) -> Delve:
	var d := Delve.new()
	d.town = _t
	d.roster = _t.get("roster")
	d.start_floor = floor_n
	d.max_floors = 3
	_t.add_child(d)
	d.start(ids)
	return d

func _process(dt: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		for v in [["2101", "JestFan", "knight dwarf"], ["2102", "Mira", "ranger elf"], ["2103", "Tuck", "rogue halfling"], ["2104", "BigAxe", "barbarian orc"]]:
			_say(v[0], v[1], "!enlist " + v[2])
	if _f == 40:
		_d1 = _mkdelve(["2101", "2102"], 2)
		_eye.director._set_on(true)
		Engine.time_scale = 6.0
	if _f < 60:
		return false
	var d: AutoDirector = _eye.director
	var c := d._clock
	if not _d2_started and c > D2_AT:
		_d2_started = true
		_d2 = _mkdelve(["2103", "2104"], 4)
		_events.append({"name": "delve_start", "t": c})
		print("EVENT delve_start at %.1f" % c)
	if _raid_i < RAIDS.size() and c > RAIDS[_raid_i]:
		_raid_i += 1
		_t.raids.force_level = 3
		_t.raids.raid("scar")
		_events.append({"name": "raid", "t": c})
		print("EVENT raid at %.1f" % c)
	if _kill_i < KILLS.size() and c > KILLS[_kill_i]:
		var dv: Delve = _d1 if _kill_i == 0 else (_d2 if _d2 != null else _d1)
		if is_instance_valid(dv):
			var al: Array = dv._alive()
			if al.size() > 0:
				al[0]["hp"] = 0.0
				_kill_i += 1
				_events.append({"name": "death", "t": c})
				print("EVENT death at %.1f" % c)
	for e in _events:
		var age := c - float(e["t"])
		var tag := "%s_%d" % [e["name"], int(e["t"])]
		if age > 2.0 and age < 6.0:
			_shot(tag + "_a")
		if age > 9.0 and age < 14.0:
			_shot(tag + "_b")
	if c >= _next_s:
		_next_s = c + 0.5
		_rows.append([c, _eye.dist, _eye.pitch if "pitch" in _eye else 0.0, String(d._cur.get("shot", "-")), String(d._cur.get("key", "-")), d._pace])
	if c >= RUN_S:
		_finish(d)
		return true
	return false

func _finish(d: AutoDirector) -> void:
	var f := FileAccess.open(_out + "camera_series.csv", FileAccess.WRITE)
	f.store_line("t,dist,pitch,shot,key,pace")
	for r in _rows:
		f.store_line("%.1f,%.2f,%.1f,%s,%s,%.2f" % [r[0], r[1], r[2], r[3], r[4], r[5]])
	f.close()
	var lf := FileAccess.open(_out + "director_decision_log.txt", FileAccess.WRITE)
	for l in d.log_lines:
		lf.store_line(l)
	lf.close()
	# quiet baseline: distances while no event is within 25 s before it
	var quiet: Array = []
	for r in _rows:
		var near := false
		for e in _events:
			if float(r[0]) >= float(e["t"]) - 2.0 and float(r[0]) <= float(e["t"]) + 25.0:
				near = true
		if not near and String(r[3]) != "hard_cut" and String(r[3]) != "breath":
			quiet.append(float(r[1]))
	quiet.sort()
	var qmed: float = quiet[quiet.size() / 2] if quiet.size() > 0 else 0.0
	print("L73_LONG quiet_samples=%d quiet_median_dist=%.1f" % [quiet.size(), qmed])
	var fails := 0
	for e in _events:
		var t0 := float(e["t"])
		var shots := {}
		var dmin := 1e9
		var dmax := 0.0
		var first_change := -1.0
		var prev := ""
		for r in _rows:
			var rt := float(r[0])
			if rt >= t0 and rt <= t0 + 20.0:
				shots[String(r[3])] = int(shots.get(String(r[3]), 0)) + 1
				dmin = minf(dmin, float(r[1]))
				dmax = maxf(dmax, float(r[1]))
				if first_change < 0.0 and (String(r[4]) != prev and prev != ""):
					first_change = rt - t0
				prev = String(r[4])
		# the camera "tells" when within 20 s of the event it is on a story shot or its distance moves >= 25% off the quiet median
		var told: bool = (e["name"] == "death" and (shots.has("hard_cut") or shots.has("breath"))) or (e["name"] != "death" and (absf(dmin - qmed) / maxf(qmed, 1.0) >= 0.25 or absf(dmax - qmed) / maxf(qmed, 1.0) >= 0.25 or shots.size() >= 2))
		print("L73_LONG event=%s t=%.0f first_cut_after=%.1fs dist=[%.1f..%.1f] shots=%s told=%s" % [e["name"], t0, first_change, dmin, dmax, shots, told])
		if not told:
			fails += 1
	print("L73_LONG events=%d cuts_logged=%d fails=%d" % [_events.size(), d.log_lines.size(), fails])
	print("L73_LONG ", "OK" if fails == 0 and _events.size() >= 5 else "FAIL")
	quit(0)
