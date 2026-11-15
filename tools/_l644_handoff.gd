extends SceneTree
## L64.4 handoff test (WINDOWED). Director on, viewer heroes delving. Every frame: does any
## spotlight pane (ambient or paid) frame the body the director is on? Ambient panes must yield
## within 1.5 s; paid panes may legitimately hold (director yields to them). Saves a capture.
var _t: Node3D
var _eye: RtsCamera
var _f := 0
var dual_frames := 0
var dual_paid := 0
var frames := 0
var run_s := 90.0
var _streak := 0.0
var worst := 0.0
func _initialize() -> void:
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
var _force_at := -1.0
var _force_ok := -1
var _force_lane := ""
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
		Engine.time_scale = 4.0
	if _f < 60:
		return false
	var d: AutoDirector = _eye.director
	var s = HudDock.spot(_t)
	var dn = d._cur.get("node") if not d._cur.is_empty() else null
	if s != null and dn != null and is_instance_valid(dn):
		frames += 1
		var hit := false
		for l in Spotlight.LANES:
			if s._target(l) == dn:
				hit = true
				if frames % 200 == 0:
					print('DBG lane=%s dsub_same=%s susp=%s hand_t=%s eye=%s' % [l, s._director_subject() == dn, s._suspended, s._amb[l].get('hand_t'), s._eye() == _eye])
				if s.paid_target(l) != null:
					dual_paid += 1
				else:
					dual_frames += 1
		if hit and s.paid_target("bits") != dn and s.paid_target("subs") != dn and s.paid_target("points") != dn:
			_streak += _d
			worst = maxf(worst, _streak)
		else:
			_streak = 0.0
	if s != null and dn != null and _force_at < 0.0 and d._clock > 70.0:
		for l in Spotlight.LANES:
			if (s.lanes[l]["cur"] as Dictionary).is_empty():
				s._amb[l]["node"] = dn
				s._amb[l]["t"] = 25.0
				_force_lane = l
				_force_at = d._clock
				print("FORCE dbg susp=%s proc=%s dsub_same=%s eye_same=%s mode=%s" % [s._suspended, s.is_processing(), s._director_subject() == dn, s._eye() == _eye, s.mode_now()])
				print("FORCE lane=", l, " onto director subject ", dn.name)
				break
	if _force_at > 0.0 and _force_ok < 0 and d._clock > _force_at + 6.0:
		var still: bool = s._target(_force_lane) == d._cur.get("node") and d._cur.get("node") == dn
		_force_ok = 0 if still else 1
		print("FORCE result: pane yielded=", _force_ok == 1)
	if d._clock >= 60.0 and not FileAccess.file_exists("user://l644_cap.flag"):
		root.get_texture().get_image().save_png("user://l644_panes.png")
		FileAccess.open("user://l644_cap.flag", FileAccess.WRITE).store_string("1")
		print("SHOT l644_panes cur=", d._cur.get("key", "-"))
	if d._clock >= run_s:
		print("L644 frames=%d dual_ambient=%d dual_paid=%d worst_streak_s=%.2f swaps=%d" % [frames, dual_frames, dual_paid, worst, s.handoff_swaps if s else -1])
		print("L644_HANDOFF ", "OK" if (worst <= 1.6 and _force_ok != 0) else "FAIL")
		return true
	return false
