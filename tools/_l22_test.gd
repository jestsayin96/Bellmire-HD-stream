extends SceneTree
## L22: two spotlit heroes standing together made two panes of the same picture (every lane
## camera sat at the same offset behind its hero). With subjects within a few metres - two
## lanes' heroes, or a lane's hero and the director's - the panes must look different: a
## different angle round the subject (>= 60 deg apart) and a different zoom. Heroes apart:
## the usual offset again. Three viewers pinned in the market; the director follows one.
## Run windowed (--resolution 1920x1080) to also save renders/cycles/20261112_l22.
var _t: Node3D
var _eye: RtsCamera
var _f := 0
var _fails: Array = []
var _checks := 0
var _pin := {}            # uid -> spot
var _shots := not DisplayServer.get_name().to_lower().contains("headless")
const OUT := "res://renders/cycles/20261112_l22"
const IDS := ["2201", "2202", "2203"]

func _initialize() -> void:
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
	var c: ChatCmd = _t.get("chat")
	c._last.clear()
	_t.call("chat_line", uid, nm, msg)

func _body(uid: String) -> Node3D:
	return Spotlight.of(_t).body_of(uid)

func _save(tag: String) -> void:
	if not _shots:
		return
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + "/%s_1080.png" % tag))
	img.resize(854, 480, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(OUT + "/%s_phone480.png" % tag))

## the horizontal angle (deg) between two cameras' looks at their subjects
static func _yaw_apart(a: Camera3D, b: Camera3D) -> float:
	var fa := -a.global_transform.basis.z
	var fb := -b.global_transform.basis.z
	return rad_to_deg(Vector2(fa.x, fa.z).normalized().angle_to(Vector2(fb.x, fb.z).normalized()))

func _process(_dt: float) -> bool:
	_f += 1
	for uid in _pin:
		var b := _body(uid)
		if b:
			b.global_position = _pin[uid]
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
		for i in IDS.size():
			_say(IDS[i], ["Ash", "Bree", "Cole"][i], "!enlist " + ["knight", "mage", "rogue"][i])
	if _f == 40:
		var mp: Vector3 = _t.get("_market_pos")
		_pin = {IDS[0]: mp + Vector3(0, 0, 0), IDS[1]: mp + Vector3(1.5, 0, 0.5), IDS[2]: mp + Vector3(-1.0, 0, 1.2)}
		# long spotlights (the test runs past a points redeem's 15 s)
		var s := Spotlight.of(_t)
		s.put(IDS[0], "bits", 120.0, "cheered 100 bits")
		s.put(IDS[1], "subs", 120.0, "subscribed")
		s.put(IDS[2], "points", 120.0, "redeemed Spotlight")
		# the director's view on Ash too: the main camera follows Ash
		_eye._select(_body(IDS[0]))
		_eye._following = true
	if _f == 240:
		var s := Spotlight.of(_t)
		var cams := {}
		for l in Spotlight.LANES:
			cams[l] = s._panes[l]["cam"]
		cams["director"] = s._panes["director"]["cam"]
		var ks: Array = cams.keys()
		for i in ks.size():
			for j in range(i + 1, ks.size()):
				var a: Camera3D = cams[ks[i]]
				var b: Camera3D = cams[ks[j]]
				var ang := absf(_yaw_apart(a, b))
				_ok(ang >= 60.0, "close heroes: the %s and %s panes look from %.0f deg apart" % [ks[i], ks[j], ang])
		var dz: Array = []
		for l in Spotlight.LANES:
			var c: Camera3D = cams[l]
			dz.append(snappedf(c.global_position.distance_to(_body(s.lanes[l]["cur"]["uid"]).global_position), 0.1))
		_ok(dz.max() - dz.min() >= 2.0, "close heroes: the lanes are at different zooms (%s m)" % [dz])
		_save("close")
		# spread them out: the lanes go back to the usual view behind their hero
		var mp: Vector3 = _t.get("_market_pos")
		_pin = {IDS[0]: mp + Vector3(0, 0, 0), IDS[1]: mp + Vector3(30, 0, -10), IDS[2]: mp + Vector3(-28, 0, 14)}
	if _f == 480:
		var s := Spotlight.of(_t)
		for l in ["subs", "points"]:
			var c: Camera3D = s._panes[l]["cam"]
			var b := _body(s.lanes[l]["cur"]["uid"])
			var off := c.global_position - b.global_position
			var yaw := rad_to_deg(Vector2(0, 1).angle_to(Vector2(off.x, off.z).normalized()))
			_ok(absf(yaw) <= 30.0, "apart: the %s pane is back behind its hero (%.0f deg off the usual)" % [l, yaw])
		_save("apart")
		print("L22_TEST %s (%d checks, %d failed)" % ["OK" if _fails.is_empty() else "FAIL", _checks, _fails.size()])
		return true
	return false
