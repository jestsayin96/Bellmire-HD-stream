extends SceneTree
## L20: the eye camera keeps every director shot clear - town wide, the tour, a hero
## follow, a fight below, a raid. Real auto-director shots (its own _best / tour_stops
## through its own _cut), never a fixed test camera. Every frame after a cut settles:
## would a roof / wall sit in the near part of the lower frame WITHOUT L20 ("raw"),
## does it now ("blocked"), is the camera inside anything ("solid"). Plus one staged
## worst case (the camera parked behind a house, low) to prove the rule bites.
## Prints L20_TEST OK. tools/_l20_shot.gd (extends this) also saves a frame of each.
var save := false
const OUT := "res://renders/cycles/20261111_l20"
var _fail := 0
var _t: Node3D
var _eye: RtsCamera
var _dir: AutoDirector
var _f := 0
var _phase := 0
var _pf := 0                  # frames in this phase
var _stat := {}               # shot -> [frames, raw, blocked, solid, max lift deg]
var _shot := ""
var _shots: Array = []        # [name, Callable start, Callable ready, frames]

func _ok(c: bool, what: String) -> void:
	print(("  ok  " if c else "  FAIL ") + what)
	if not c:
		_fail += 1

func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	if save:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _say(uid: String, nm: String, msg: String) -> void:
	(_t.get("chat") as ChatCmd)._last.erase(uid)
	_t.call("chat_line", uid, nm, msg)

## the near lower frame of a camera at p on pivot: clear?
func _clear_at(piv: Vector3, p: Vector3) -> bool:
	_eye._clear_near(piv, piv.distance_to(p))
	return _eye.frame_clear(piv, p, _eye.cam.fov, _eye._aspect())

func _measure() -> void:
	var piv := _eye.focus + Vector3(0, 1.0, 0)
	var raw := piv + Vector3(sin(_eye.yaw) * cos(_eye.pitch), -sin(_eye.pitch), cos(_eye.yaw) * cos(_eye.pitch)) * _eye.dist
	var s: Array = _stat.get(_shot, [0, 0, 0, 0, 0.0, 0.0, 0])
	s[0] += 1
	if not _clear_at(piv, raw):
		s[1] += 1
	if not _clear_at(piv, _eye.cam.global_position):
		s[2] += 1
	if _eye.cam.global_position.distance_to(piv) < (3.5 if piv.y < Delve.DELVE_Y * 0.5 else 5.0):     # in someone's face (the first L20 hero render)
		s[6] += 1
	if _eye.camera_solid():
		s[3] += 1
	s[4] = maxf(float(s[4]), rad_to_deg(_eye._lift))
	# what one search costs (it runs 5x a second): the worst seen on this shot, ms
	# (L23 de-flake: the fastest of 3 runs per sample - the search's own cost, not a time the
	# OS took the thread away; a 2.5 ms search had measured 9.9 ms once on a busy laptop)
	if int(s[0]) % 30 == 1:
		var best := 1.0e9
		for rep in 3:
			var t0 := Time.get_ticks_usec()
			_eye.clear_lift(piv, raw, _eye.cam.fov, _eye._aspect())
			best = minf(best, float(Time.get_ticks_usec() - t0) / 1000.0)
		s[5] = maxf(float(s[5]), best)
	_stat[_shot] = s

## L23 de-flake: once the story is really happening, the director decides NOW (its own
## _best through its own _cut - still the director's choice, just not left to its 1 s tick
## and its hold timers). Ready when its shot is the story wanted.
var _fight_d: Delve
func _decide(key: String, happening: Callable) -> bool:
	if not bool(happening.call()):
		return false
	if not String(_dir._cur.get("key", "")).begins_with(key):
		_dir._cut(_dir._best())
	var ok := String(_dir._cur.get("key", "")).begins_with(key)
	if ok:
		Engine.time_scale = 1.0
	return ok

func rd_live() -> bool:
	var rd: Raids = _t.get("raids")
	if not bool(rd.get("_live")):
		return false
	for r in rd.raiders:
		if r is Dictionary and is_instance_valid(r.get("node")):
			return true
	return false

func _cut_tour(i: int) -> void:
	var st: Array = _dir.tour_stops()
	_dir._cut(st[i % st.size()])
	_dir._held = 0.0

func _process(_d: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		_dir = _eye.director
		(_t.get("raids") as Raids).set("_raid_t", 99999.0)      # no surprise raid before the raid shot
		_dir._set_on(true)
		_shots = [
			["tour_market", func(): _cut_tour(0), Callable(), 600],
			["tour_scar", func(): _cut_tour(1), Callable(), 600],
			["tour_valley", func(): _cut_tour(2), Callable(), 400],
			["hero", func():
				for v in [["9201", "Ash", "!enlist knight dwarf"], ["9202", "Bree", "!enlist mage elf"], ["9203", "Cole", "!enlist rogue halfling"]]:
					_say(v[0], v[1], v[2])
				_say("9202", "Bree", "!hero")
				_dir._cut(_dir._best()), Callable(), 600],
			["raid", func():
				var rd: Raids = _t.get("raids")
				rd.force_level = 3
				rd.raid("road"),
				func() -> bool: return _decide("raid", func() -> bool: return bool(rd_live())), 500],
			["fight", func():
				var dv := Delve.new()
				dv.town = _t
				dv.roster = _t.get("roster")
				# L23 de-flake: a LORD floor - its lord rises as the party arrives, every run (it
				# was floor 2, waiting for the party to happen on monsters inside the window)
				dv.start_floor = 5
				dv.max_floors = 5
				_t.add_child(dv)
				_fight_d = dv
				dv.start(["9201", "9202", "9203"])
				Engine.time_scale = 4.0,           # only while waiting; the shot is measured at 1x
				func() -> bool: return _decide("lord_", func() -> bool: return _fight_d != null and _fight_d.lord_fighting() != null), 500],
		]
		_phase = -1
		_next()
	if _f <= 20:
		return false
	if _phase >= _shots.size():
		return _finish()
	var sh: Array = _shots[_phase]
	var ready: Callable = sh[2]
	_pf += 1
	if _shot == "":
		# waiting for the director to take this story on its own
		if ready.is_valid() and not bool(ready.call()):
			if _pf > 3000:
				_ok(false, "the director never cut to %s (on %s)" % [sh[0], _dir._cur.get("key")])
				_next()
			return false
		_shot = sh[0]
		_pf = 0
		print("L20 shot %s = director key %s" % [_shot, _dir._cur.get("key")])
	_dir._tick = 999.0                # the director has taken this shot: hold it while it is measured
	if _pf > 45:                      # 0.75 s to fly in and settle
		_measure()
	if save and _pf == int(sh[3]) / 2:
		var img := root.get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path(OUT + "/%s_1080.png" % _shot))
		img.resize(854, 480, Image.INTERPOLATE_LANCZOS)
		img.save_png(ProjectSettings.globalize_path(OUT + "/%s_phone480.png" % _shot))
		print("L20_SHOT %s lift %.1f deg" % [_shot, rad_to_deg(_eye._lift)])
	if _pf >= int(sh[3]):
		_next()
	return false

func _next() -> void:
	Engine.time_scale = 1.0
	_phase += 1
	_shot = ""
	_pf = 0
	if _dir:
		_dir._tick = 0.0             # the director decides again for the next story
	if _phase < _shots.size():
		var start: Callable = _shots[_phase][1]
		start.call()

func _finish() -> bool:
	for k in _stat:
		var s: Array = _stat[k]
		var n := maxf(1.0, float(s[0]))
		print("L20 %-12s frames %4d  raw-blocked %5.1f%%  blocked %4.1f%%  solid %d  max lift %.0f deg  search <= %.2f ms" % [k, s[0], 100.0 * s[1] / n, 100.0 * s[2] / n, s[3], s[4], s[5]])
		_ok(float(s[5]) < 4.0, "%s: the clearance search stays cheap (%.2f ms, 5x a second)" % [k, s[5]])
		_ok(float(s[2]) / n <= 0.03, "%s: the lower frame stays clear (%.1f%% blocked)" % [k, 100.0 * s[2] / n])
		_ok(int(s[3]) == 0, "%s: the camera is never inside a house or wall" % k)
		_ok(int(s[6]) == 0, "%s: the camera never comes within 5 m of the subject (3.5 m below) (%d frames)" % [k, s[6]])
	_ok(_stat.size() == 6, "all six shot types were seen (%s)" % str(_stat.keys()))
	# the staged worst case: parked low behind a house, the director off
	_dir._set_on(false)
	var hs: Array = _eye._house_rects()
	var h: Array = hs[0]
	for r: Array in hs:                                   # the ordinary house nearest the market (not the 25 m hall)
		if r.size() > 6 and String(r[6]) == "house" and float(r[4]) < 14.0 and (float(h[4]) >= 14.0 or String(h[6]) != "house" or (r[0] as Vector2).distance_to(Vector2(_t.get("_market_pos").x, _t.get("_market_pos").z)) < (h[0] as Vector2).distance_to(Vector2(_t.get("_market_pos").x, _t.get("_market_pos").z))):
			h = r
	var c: Vector2 = h[0]
	var mp: Vector3 = _t.get("_market_pos")                # the same spot every run (was: wherever the last shot left the eye)
	var away := (c - Vector2(mp.x, mp.z)).normalized()
	var fp := c + away * (float(h[5]) + 4.0)          # the subject just past the house
	_eye.focus = Vector3(fp.x, _eye._ground(Vector3(fp.x, 0, fp.y)), fp.y)
	_eye.yaw = atan2(-away.x, -away.y)                 # the camera on the house side
	_eye.pitch = deg_to_rad(-22.0)
	_eye.dist = 30.0
	_eye._lift = 0.0
	_eye._swing = 0.0
	_eye._lift_t = 0.0
	var piv := _eye.focus + Vector3(0, 1, 0)
	var raw := piv + Vector3(sin(_eye.yaw) * cos(_eye.pitch), -sin(_eye.pitch), cos(_eye.yaw) * cos(_eye.pitch)) * _eye.dist
	_ok(not _clear_at(piv, raw), "staged: parked low behind a house, the raw view IS blocked (the check sees roofs)")
	for i in 180:                                    # 3 s: the swing glides, never snaps
		_eye._process(1.0 / 60.0)
	_ok(_clear_at(piv, _eye.cam.global_position) and (rad_to_deg(_eye._lift) > 3.0 or absf(rad_to_deg(_eye._swing)) > 3.0), "staged: the eye tilts %.0f deg / swings %.0f deg and the frame is clear" % [rad_to_deg(_eye._lift), rad_to_deg(_eye._swing)])
	if _fail > 0:
		# diagnostic: where the eye wanted to go, is THAT clear, and what the house is
		var tgt := RtsCamera.shifted(piv, raw, Vector2(_eye._lift_want, _eye._swing_want))
		print("  staged: want tilt %.0f swing %.0f, target clear %s" % [rad_to_deg(_eye._lift_want), rad_to_deg(_eye._swing_want), _clear_at(piv, tgt)])
		var p := _eye.cam.global_position
		print("  staged: swing %.1f, cam %s pivot %s lift %.1f house top %.1f centre %s r %.1f" % [rad_to_deg(_eye._swing), p, piv, rad_to_deg(_eye._lift), float(h[4]), h[0], float(h[5])])
	print("L20_TEST OK" if _fail == 0 else "L20_TEST FAIL %d" % _fail)
	return true
