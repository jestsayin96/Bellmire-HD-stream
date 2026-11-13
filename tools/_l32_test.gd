extends SceneTree
## L32a: the 2x2 grid is the stream's RESTING state. Checked here, windowed
## (--resolution 1920x1080; FPS and panes cannot be judged headless):
##   - the grid is up from boot with all four panes live, the main view's 3D off
##   - every idle lane holds an AMBIENT subject and rotates to a new one (20-30 s real)
##   - a scripted influx of bits / subs / points takes the lanes QUEUED IN ORDER,
##     each payer for their FULL seconds, bright frame + timer bar while paid
##   - when the queues drain every lane returns to ambient, the grid never collapses
##   - F10's label toggle still works
##   - FPS holds, judged RELATIVE on this machine: first the OLD resting state
##     (full-screen director, no panes) is measured on the same scene, then the
##     idle grid must keep >= 65% of it and the paid grid >= 50% of the idle grid
##     (the paid window's scene varies run to run - a lord fight in three lanes
##     measured 56-75% across runs - so the bar sits under that natural variance)
## Spotlight seconds are REAL seconds (left -= delta / time_scale), so this runs
## ~3 min real; run it in the background. Prints L32_TEST OK / FAIL.
var _t: Node3D
var _eye: RtsCamera
var _d: Delve
var _f := 0
var _fails: Array = []
var _checks := 0
var _stage := "boot"
var _t0 := 0.0                    # stage start, real seconds
var _seen := {}                   # lane -> {instance id: true} - ambient subjects seen
var _fps_n := 0
var _fps_s := 0.0
var _fps_amb := 0.0
var _fps_paid := 0.0
var _fps_base := 0.0
var _bits_log: Array = []         # [uid, start_s] each time the bits lane's cur changes
var _bits_last := ""
var _shots := not DisplayServer.get_name().to_lower().contains("headless")
const OUT := "res://renders/cycles/20261112_l32"
const AMB_S := 75.0
const BASE_S := 20.0
const FPS_FLOOR := 15.0           # catastrophe only - the real check is relative

func _initialize() -> void:
	if not _shots:
		root.size = Vector2i(1920, 1080)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	if _shots:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fails.append(what)
		print("  FAIL ", what)

func _say(uid: String, nm: String, msg: String) -> void:
	var c: ChatCmd = _t.get("chat")
	c._last.clear()
	_t.call("chat_line", uid, nm, msg)

func _save(tag: String) -> void:
	if not _shots:
		return
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + "/%s_1080.png" % tag))
	print("L32_SHOT %s (window %s)" % [tag, root.size])

func _spot() -> Spotlight:
	return Spotlight.of(_t)

## the grid's standing facts, checked at every sample of every stage
func _grid_ok(tag: String) -> void:
	var s := _spot()
	_ok(s.mode_now() == "grid", "%s: the layout is the grid (got '%s')" % [tag, s.mode_now()])
	_ok(Spotlight.mode == "grid", "%s: Spotlight.mode is 'grid'" % tag)
	var up := 0
	for k in ["director", "bits", "subs", "points"]:
		if (s._panes[k]["box"] as Control).visible:
			up += 1
	_ok(up == 4, "%s: all four panes live (%d)" % [tag, up])
	_ok(not (s._panes["wide"]["box"] as Control).visible, "%s: no wide pane in the resting grid" % tag)
	_ok(root.disable_3d, "%s: the main view's 3D is off (the panes carry it)" % tag)

func _sample_amb() -> void:
	var s := _spot()
	for l in Spotlight.LANES:
		var n = (s._amb[l] as Dictionary).get("node")
		if n != null and is_instance_valid(n):
			if not _seen.has(l):
				_seen[l] = {}
			_seen[l][(n as Node).get_instance_id()] = true

func _sample_bits() -> void:
	var s := _spot()
	var cur: Dictionary = s.lanes["bits"]["cur"]
	var uid := String(cur.get("uid", ""))
	if uid != _bits_last:
		_bits_log.append([uid, _now()])
		_bits_last = uid

## ---- L43: THE WARM-UP, AND WHY IT EXISTS.
## This suite judges FPS RELATIVE to a base phase, which is what makes it portable between two
## very different machines. That design is kept. What was broken was the MEASUREMENT: the base
## phase was sampled the instant root.disable_3d was set back to false, and with D24's TAA on,
## a viewport whose 3D was just re-enabled has no temporal history to resolve against. The base
## came back as 1.0 FPS, and because every check is relative to it, the whole suite passed
## while testing nothing.
## So after ANY change to viewport 3D state - disable_3d toggled, the grid raised or lowered -
## samples are DISCARDED until TAA has refilled: at least 1 s of real time AND 60 frames,
## whichever finishes last.
const WARM_S := 1.0
const WARM_F := 60
const MIN_SAMPLES := 60         # a phase that sampled fewer frames than this measured nothing
var _warm_t := 0.0              # real time at which the warm-up may end
var _warm_f := 0                # frames remaining in the warm-up
var _warm_drop := 0             # frames discarded, reported per phase
var _n_base := 0
var _n_amb := 0
var _n_paid := 0

## call this immediately after touching disable_3d or raising/lowering the grid
func _warm_up() -> void:
	_warm_t = _now() + WARM_S
	_warm_f = WARM_F
	_warm_drop = 0
	_fps_n = 0
	_fps_s = 0.0

func _fps_tick() -> void:
	# L43: discard everything until TAA has had time to settle
	if _warm_f > 0 or _now() < _warm_t:
		_warm_f = maxi(0, _warm_f - 1)
		_warm_drop += 1
		return
	_fps_n += 1
	_fps_s += Engine.get_frames_per_second()

var _took_n := 0                # how many frames the phase just taken actually sampled

func _fps_take() -> float:
	_took_n = _fps_n
	var v := _fps_s / maxf(1.0, float(_fps_n))
	_fps_n = 0
	_fps_s = 0.0
	return v

func _process(_dt: float) -> bool:
	_f += 1
	if not _shots and root.size != Vector2i(1920, 1080):
		root.size = Vector2i(1920, 1080)
	match _stage:
		"boot":
			if _f == 20:
				_eye = RtsCamera.new()
				_t.add_child(_eye)
				_eye.setup(_t)
				var r: Roster = _t.get("roster")
				for v in [["3101", "AmberOak", "knight dwarf"], ["3102", "FernWisp", "mage elf"], ["3103", "TidePriest", "cleric human"], ["3104", "IronBrow", "barbarian orc"], ["3105", "Lark", "bard halfling"], ["3106", "StoneWard", "paladin dwarf"]]:
					_say(v[0], v[1], "!enlist " + v[2])
				for id in ["3101", "3104"]:
					var h: Dictionary = r.get_hero(id)
					h["weapon"] = 3
					h["armour"] = 3
					h["oil"] = 4
				_d = Delve.new()
				_d.town = _t
				_d.roster = r
				_d.start_floor = 4
				_d.max_floors = 6
				_t.add_child(_d)
				_d.start(["3104", "3101"])
				_eye.director._set_on(true)
				# the OLD resting state first (full-screen director, no panes), for the
				# relative FPS judgment on this machine
				var s := _spot()
				s.set_process(false)
				s.visible = false
				for k in s._panes:
					(s._panes[k]["vp"] as SubViewport).render_target_update_mode = SubViewport.UPDATE_DISABLED
				root.disable_3d = false
				_warm_up()                 # L43: 3D just came back - let TAA refill before sampling
				_stage = "base"
				_t0 = _now()
				print("L32 stage base (%.0f s real - the old full-screen resting state)" % BASE_S)
		"base":
			_fps_tick()
			if _now() - _t0 >= BASE_S:
				_fps_base = _fps_take()
				_n_base = _took_n
				print("L32 base measured %.1f fps over %d frames (%d discarded warming up)"
					% [_fps_base, _n_base, _warm_drop])
				var s := _spot()
				s.set_process(true)
				s.visible = true
				s._relayout(true)          # the grid back up (disable_3d, pane update modes)
				_warm_up()                 # L43: the grid is a 3D-state change too
				_stage = "amb"
				_t0 = _now()
				print("L32 stage amb (%.0f s real - ambient rotation soak)" % AMB_S)
		"amb":
			_fps_tick()
			if _f % 15 == 0:
				_sample_amb()
			if _f % 300 == 0:
				_grid_ok("amb")
				_ok(_spot().busy().is_empty(), "amb: no lane paid during the idle soak")
			if _now() - _t0 >= AMB_S:
				_fps_amb = _fps_take()
				_n_amb = _took_n
				print("L32 idle measured %.1f fps over %d frames (%d discarded warming up)" % [_fps_amb, _n_amb, _warm_drop])
				var s := _spot()
				for l in Spotlight.LANES:
					var n := (_seen.get(l, {}) as Dictionary).size()
					_ok(n >= 2, "amb: the %s lane rotated its ambient subject (%d seen in %.0f s)" % [l, n, AMB_S])
					_ok(s._target(l) != null, "amb: the %s lane holds an ambient subject now" % l)
					_ok(not (s._panes[l]["bar"] as ColorRect).visible, "amb: no timer bar on the idle %s lane" % l)
				_save("amb_grid")
				# the influx: three cheers into bits (A 20 s, B 15 s, C 30 s - queued in
				# order), two subs (30 s each), one redeem (15 s)
				_say("local_mre", "MrE", "!testbits 50 amberoak")
				_say("local_mre", "MrE", "!testbits 1 fernwisp")
				_say("local_mre", "MrE", "!testbits 300 tidepriest")
				_say("local_mre", "MrE", "!testsub ironbrow")
				_say("local_mre", "MrE", "!testsub lark")
				_say("local_mre", "MrE", "!testpoints stoneward")
				_bits_last = ""
				_bits_log.clear()
				_stage = "paid"
				_t0 = _now()
				print("L32 stage paid (the scripted influx plays out)")
		"paid":
			_fps_tick()
			_sample_bits()
			if _f % 15 == 0:
				_sample_amb()
			if _f % 300 == 0:
				_grid_ok("paid")
			if _now() - _t0 >= 2.0 and not _spot().busy().is_empty() and not get_meta("paid_checked", false):
				set_meta("paid_checked", true)
				var s := _spot()
				_ok(s.busy().size() == 3, "paid: all three lanes took their first payer (%s)" % [s.busy()])
				_ok((s.lanes["bits"]["q"] as Array).size() == 2, "paid: two cheers wait in the bits queue")
				_ok((s.lanes["subs"]["q"] as Array).size() == 1, "paid: one sub waits in the subs queue")
				for l in Spotlight.LANES:
					_ok((s._panes[l]["bar"] as ColorRect).visible, "paid: the %s lane shows its timer bar" % l)
				# F10: the labels toggle still works
				s.set_labels(false)
				var hid := not (s._panes["bits"]["label"] as Label).visible
				s.set_labels(true)
				var shown := (s._panes["bits"]["label"] as Label).visible
				_ok(hid and shown, "paid: F10's label toggle hides and shows the chips")
				_save("paid_grid")
			if _spot().busy().is_empty() and _now() - _t0 > 10.0:
				_fps_paid = _fps_take()
				_n_paid = _took_n
				print("L32 paid measured %.1f fps over %d frames (%d discarded warming up)" % [_fps_paid, _n_paid, _warm_drop])
				_check_order()
				_stage = "drain"
				_t0 = _now()
				print("L32 stage drain (back to ambient)")
		"drain":
			if _now() - _t0 >= 3.0:
				var s := _spot()
				_grid_ok("drain")
				for l in Spotlight.LANES:
					_ok((s.lanes[l]["cur"] as Dictionary).is_empty(), "drain: the %s lane's queue drained" % l)
					_ok(s._target(l) != null, "drain: the %s lane returned to ambient, not blank" % l)
					_ok(not (s._panes[l]["bar"] as ColorRect).visible, "drain: the %s timer bar is gone" % l)
				# The FPS judgment here is RELATIVE to the base phase, so a base that did not
				# measure makes every check below trivially true - "OK" while nothing was
				# tested. Seen for real on 2026-11-12: after D24 enabled TAA + MSAA the
				# laptop's full-screen base came back at 1.0 FPS and the whole suite still
				# printed OK. A base that low is a broken measurement, not a slow machine.
				# L43: the raw numbers, always printed, so a vacuous pass can never hide again
				print("L32_FPS_RAW base %.1f/%d frames  idle %.1f/%d  paid %.1f/%d"
					% [_fps_base, _n_base, _fps_amb, _n_amb, _fps_paid, _n_paid])
				# L43 guard 2: a phase that sampled almost nothing has not measured anything,
				# whatever average it reports. This is the companion to the base >= 10 assert:
				# that one catches a collapsed VALUE, this one catches a collapsed SAMPLE.
				_ok(_n_base >= MIN_SAMPLES, "fps: the base phase sampled enough frames to mean anything (%d, need %d)" % [_n_base, MIN_SAMPLES])
				_ok(_n_amb >= MIN_SAMPLES, "fps: the idle phase sampled enough frames (%d, need %d)" % [_n_amb, MIN_SAMPLES])
				_ok(_n_paid >= MIN_SAMPLES, "fps: the paid phase sampled enough frames (%d, need %d)" % [_n_paid, MIN_SAMPLES])
				_ok(_fps_base >= 10.0, "fps: the base phase measured a real frame rate (%.1f) - below this the relative checks mean nothing" % _fps_base)
				_ok(_fps_amb >= _fps_base * 0.65, "fps: the idle grid keeps 65%% of the old resting state (%.1f of %.1f)" % [_fps_amb, _fps_base])
				_ok(_fps_paid >= _fps_amb * 0.5, "fps: the paid grid within 50%% of the idle grid (%.1f of %.1f)" % [_fps_paid, _fps_amb])
				_ok(_fps_amb >= FPS_FLOOR and _fps_paid >= FPS_FLOOR, "fps: both over the catastrophe floor %.0f (%.1f / %.1f)" % [FPS_FLOOR, _fps_amb, _fps_paid])
				print("L32_FPS base %.1f idle %.1f paid %.1f" % [_fps_base, _fps_amb, _fps_paid])
				_save("drain_grid")
				print("L32_TEST %s (%d checks, %d failed)" % ["OK" if _fails.is_empty() else "FAIL", _checks, _fails.size()])
				return true
	return false

## the bits lane played its three cheers IN ORDER, each for the full seconds bought
func _check_order() -> void:
	var runs: Array = []           # [uid, held seconds]
	for i in _bits_log.size():
		var uid := String(_bits_log[i][0])
		if uid == "":
			continue
		var t0 := float(_bits_log[i][1])
		var t1 := float(_bits_log[i + 1][1]) if i + 1 < _bits_log.size() else t0
		runs.append([uid, t1 - t0])
	var want := [["3101", 20.0], ["3102", 15.0], ["3103", 30.0]]
	_ok(runs.size() == 3, "order: the bits lane played 3 cheers (%d: %s)" % [runs.size(), runs])
	for i in mini(runs.size(), 3):
		_ok(String(runs[i][0]) == String(want[i][0]), "order: cheer #%d was %s's (got %s)" % [i + 1, want[i][0], runs[i][0]])
		var held := float(runs[i][1])
		var full := float(want[i][1])
		_ok(held >= full - 1.5 and held <= full + 4.0, "order: cheer #%d held its full %.0f s (held %.1f)" % [i + 1, full, held])
