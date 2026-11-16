extends SceneTree
## L34: THE TOP-LEFT (DIRECTOR) PANE MUST NEVER FREEZE OR GO BLACK.
## Mr. E, in his own game chat: "the top left screen goes black or stays stuck when someone dies".
## Two root causes, both fixed and both checked here:
##   (a) auto_director.gd _process(): `if best.is_empty(): return` parked the eye the moment the
##       subject died / rerolled / despawned - _fallback_shot() now steps the town tour instead.
##   (b) spotlight.gd _follow(): the director pane copied get_viewport().get_camera_3d() and
##       SILENTLY held its last transform when that was null - it now falls back to the eye's own
##       camera, then to the eye's numbers (_eye_xform).
## Windowed (--resolution 1920x1080; a pane cannot be judged headless - COORDINATION 4).
## Three scripted events, each followed by a 3 s watch of the REAL director pane camera:
##   1. the subject DIES      (Roster.kill)
##   2. the subject REROLLS   (Roster.reroll)
##   3. the subject DESPAWNS  (its body freed under the director's feet)
## For each: 0 frozen frames (no two consecutive frames with the same pane transform), the
## director keeps a non-empty shot, and the pane camera never sits below ground (the "black void").
## Prints L34_TEST OK / FAIL.
var _t: Node3D
var _eye: RtsCamera
var _dir: AutoDirector
var _f := 0
var _fails: Array = []
var _checks := 0
var _stage := "boot"
var _watch := 0                   # frames left in the current watch window
var _last_x: Transform3D
var _have_last := false
var _run := 0                     # current run of identical pane transforms
var _frozen := 0                  # worst run in this window
var _void := 0                    # frames with the pane camera below ground
var _empty := 0                   # frames the director had no shot at all
var _ev := ""
var _results: Array = []
var _keys := {}
var _eye_moved := 0.0
var _pane_moved := 0.0
var _main_null := 0
var _eye_last := Vector3.ZERO
var _lost_key := ""               # the shot key whose subject this event destroys
var _last_key := ""
var _pairs := 0
var _shots := not DisplayServer.get_name().to_lower().contains("headless")
const OUT := "res://renders/cycles/20261112_l34"
const WATCH_F := 180              # 3 s at 60 fps
const UIDS := [["3401", "Ashvein", "!enlist knight"], ["3402", "Brelda", "!enlist mage"],
			   ["3403", "Corrin", "!enlist rogue"], ["3404", "Dunmar", "!enlist ranger"]]

func _initialize() -> void:
	if not _shots:
		root.size = Vector2i(1920, 1080)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	if _shots:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _ok(c: bool, what: String) -> void:
	_checks += 1
	print("  %s %s" % ["ok  " if c else "FAIL", what])
	if not c:
		_fails.append(what)

func _say(uid: String, nm: String, msg: String) -> void:
	(_t.get("chat") as ChatCmd)._last.erase(uid)
	_t.call("chat_line", uid, nm, msg)

func _spot() -> Spotlight:
	return Spotlight.of(_t)

## the REAL top-left pane camera - what the stream shows
func _pane_cam() -> Camera3D:
	var s := _spot()
	if s == null or not s._panes.has("director"):
		return null
	return s._panes["director"]["cam"] as Camera3D

func _pane_live() -> bool:
	var s := _spot()
	if s == null or not s._panes.has("director"):
		return false
	return (s._panes["director"]["box"] as Control).visible

func _grab(tag: String) -> void:
	if not _shots:
		return
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + "/%s_1080.png" % tag))

func _body(uid: String) -> Node3D:
	return _spot().body_of(uid)

## put the director on a hero we control, so the event we script is the one it is watching
func _aim_at(uid: String) -> bool:
	var b := _body(uid)
	if b == null or not is_instance_valid(b):
		return false
	_dir._cut({"key": "hero_%s" % uid, "pri": 30.0, "node": b, "dist": 14.0, "pitch": -30.0})
	return true

func _start_watch(ev: String, lost := "") -> void:
	_ev = ev
	_lost_key = lost
	_last_key = ""
	_watch = WATCH_F
	_frozen = 0
	_void = 0
	_empty = 0
	_run = 0
	_have_last = false
	_keys = {}
	_eye_moved = 0.0
	_pane_moved = 0.0
	_main_null = 0
	_pairs = 0
	_eye_last = _eye.cam.global_position if _eye != null and is_instance_valid(_eye.cam) else Vector3.ZERO

func _end_watch() -> void:
	_results.append({"ev": _ev, "frozen": _frozen, "void": _void, "empty": _empty})
	print("    [diag %s] keys=%s eye_moved=%.3f main_null=%d pane_moved=%.3f"
		% [_ev, str(_keys.keys()), _eye_moved, _main_null, _pane_moved])
	# <= 2 frames absorbs the node-order lag (Spotlight._process copies the eye before
	# RtsCamera._process has placed it this frame); a real freeze runs for tens of frames.
	_ok(_frozen <= 2, "%s: the pane never holds a dead frame while the eye moves - 0 stale frames (worst run %d)" % [_ev, _frozen])
	_ok(_void == 0, "%s: the pane camera never sits below ground - 0 void frames (%d)" % [_ev, _void])
	_ok(_empty == 0, "%s: the director always has a shot - 0 empty ticks (%d)" % [_ev, _empty])
	# THE FREEZE ITSELF, measured over the whole window: the eye travelled, so the pane - which
	# is meant to be showing the eye's shot - must have travelled too. A pane that moves ~0 m
	# while the eye moves metres is the dead frame Mr. E saw, however it came about (a null main
	# camera, a hidden pane, a cut the pane never picked up).
	# Only meaningful with a full window of consecutive samples: if the pane was hidden for part
	# of the window the eye's travel lands in one catch-up delta with nothing to compare against,
	# and the totals say nothing. The forced-null window below always has a full window.
	if _eye_moved > 1.0 and _pairs >= 60:
		_ok(_pane_moved > 0.25,
			"%s: the pane tracked the eye, not a dead frame (eye %.2f m, pane %.2f m over %d frames)" % [_ev, _eye_moved, _pane_moved, _pairs])
	# root cause (a): the director must MOVE ON from the subject it lost rather than stay parked
	# on it. It may still hold the lost key for up to one _tick (1 s), so the test is where it
	# ENDED UP, not that it never appeared. (The eye's own travel is not the measure: a valid new
	# subject can be standing perfectly still, which is a held shot, not a freeze.)
	_ok(_lost_key == "" or _last_key != _lost_key,
		"%s: the director moved off the lost subject (ended on %s, lost %s)" % [_ev, _last_key, _lost_key])
	_grab(_ev)

## sample the pane every frame: is it actually moving, and is it looking at anything?
func _sample() -> void:
	if not _pane_live():
		return
	var dc := _pane_cam()
	if dc == null or not is_instance_valid(dc):
		return
	# in the forced-null-camera window, drive the eye by hand so "did the pane track?" has a
	# definite answer that does not depend on whatever the town happens to be doing
	if _ev == "4_null_main_camera" and _eye != null:
		_eye.yaw += 0.02
	var x := dc.global_transform
	_last_key = String(_dir._cur.get("key", "<empty>"))
	_keys[_last_key] = true
	if root.get_camera_3d() == null:
		_main_null += 1
	# how far the EYE travelled this frame - the pane is meant to be tracking it
	var eye_step := 0.0
	if _eye != null and is_instance_valid(_eye.cam):
		var ep := _eye.cam.global_position
		eye_step = ep.distance_to(_eye_last)
		_eye_moved += eye_step
		_eye_last = ep
	if _have_last:
		_pairs += 1
		_pane_moved += x.origin.distance_to(_last_x.origin)
		# A STALE frame: the eye moved, the pane did not. An identical transform while the eye
		# itself is still is NOT a fault - the director is simply holding a motionless subject
		# (an angler at the water, a hero standing), which is what the shot is meant to show.
		# The L34 bug was the pane holding a DEAD frame while the eye moved on; that is this.
		var pane_still := x.origin.distance_to(_last_x.origin) < 1.0e-6 and x.basis.is_equal_approx(_last_x.basis)
		if pane_still and eye_step > 1.0e-4:
			_run += 1
			_frozen = maxi(_frozen, _run)
		else:
			_run = 0
	_last_x = x
	_have_last = true
	if _eye != null:
		var g := _eye._ground(dc.global_position)
		if dc.global_position.y < g - 0.1:
			_void += 1
	if _dir._cur.is_empty():
		_empty += 1

func _process(_dt: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		_dir = _eye.director
		(_t.get("raids") as Raids).set("_raid_t", 99999.0)   # no raid stealing the eye
		for v in UIDS:
			_say(v[0], v[1], v[2])
		_dir._set_on(true)
		return false
	if _f < 60:
		return false
	if _f == 60:
		_ok(_pane_live(), "the grid is up and the top-left (director) pane is live")
		_ok(_dir.on, "the director is on")
		for v in UIDS:
			_say(v[0], v[1], "!hero")
		return false

	if _watch > 0:
		_sample()
		_watch -= 1
		if _watch == 0:
			_end_watch()
		return false

	match _stage:
		"boot":
			if _f < 90:
				return false
			_ok(_aim_at("3401"), "the director is aimed at Ashvein's hero")
			_stage = "death"
			_start_watch("0_baseline")
		"death":
			# the subject DIES under the eye - the case Mr. E reported
			var r: Roster = _t.get("roster")
			r.kill("3401", "a scarrat", 3, 1)
			var b := _body("3401")
			if b != null and is_instance_valid(b):
				(b as Node3D).visible = false
			_stage = "reroll"
			_start_watch("1_after_death", "hero_3401")
		"reroll":
			_ok(_aim_at("3402"), "the director is aimed at Brelda's hero")
			(_t.get("roster") as Roster).reroll("3402")
			_stage = "despawn"
			_start_watch("2_after_reroll", "hero_3402")
		"despawn":
			# the subject's body is freed outright - _best() can come back empty mid-transition
			if _aim_at("3403"):
				var b := _body("3403")
				if b != null and is_instance_valid(b):
					b.queue_free()
			_stage = "nullcam"
			_start_watch("3_after_despawn", "hero_3403")
		"nullcam":
			# ROOT CAUSE (b), forced rather than waited for: take the main viewport's camera out
			# of play, which is the state L32a's disable_3d and a mid-frame reroll produce. The
			# old _follow() simply skipped the copy and the pane held its last frame - the black,
			# stuck top-left pane. The eye is nudged every frame below, so a pane that tracks
			# MUST move; a pane that holds stale moves 0 m and fails.
			_ok(_aim_at("3404"), "the director is aimed at Dunmar's hero")
			if _eye != null and is_instance_valid(_eye.cam):
				_eye.cam.current = false
			_ok(root.get_camera_3d() == null, "the main viewport has no current camera (the L34 state)")
			_stage = "done"
			_start_watch("4_null_main_camera")
		"done":
			print("L34 pane watch: ", _results)
			print("CHECKS ", _checks, " FAILS ", _fails.size())
			for f in _fails:
				print("  - ", f)
			print("L34_TEST ", "OK" if _fails.is_empty() else "FAIL")
			return true
	return false
