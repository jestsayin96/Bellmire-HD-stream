extends SceneTree
## S53: the eye's clock plate ("1x  Day N  HH:MM") at UI 100/125/150%, WINDOWED 1920x1080.
## U91 found it at y=1013.5 h=68 at 150% - centred on a 65 px chrome bar, so 1.5 px hung off the
## bottom of the frame. Per scale, for 60 frames while the spotlight panes are up (split): the plate
## is visible and its rect lies wholly inside the viewport, with NO tolerance (U91 allowed 1 px, which
## is why a 1.5 px overhang was a finding and not a gate). Shot at each scale.
## NO VERDICT unless the split was seen and the plate measured at every scale.
var _t: Node3D
var _eye: RtsCamera
var _f := 0
var _si := 0
var _n := 0
var _fails := 0
var _seen := [0, 0, 0]
var _worst := [0.0, 0.0, 0.0]
const SC := [1.0, 1.25, 1.5]
var _out := ""
func _initialize() -> void:
	_out = ProjectSettings.globalize_path("res://renders/cycles/s53/")
	DirAccess.make_dir_recursive_absolute(_out)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
func _process(_d: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new(); _t.add_child(_eye); _eye.setup(_t)
	if _f < 90: return false
	if _si >= SC.size():
		for i in SC.size():
			print("S53 scale ", int(SC[i] * 100.0), "% measured=", _seen[i], " worst bottom=", _worst[i])
		for i in SC.size():
			if _seen[i] < 30:
				print("S53_CLOCK NO VERDICT - scale ", int(SC[i] * 100.0), "% measured ", _seen[i], " frames in split")
				quit(2); return true
		print("S53_CLOCK ", "OK" if _fails == 0 else "FAIL", " fails=", _fails)
		quit(1 if _fails > 0 else 0); return true
	if _n == 0:
		UiTheme.set_scale(SC[_si])
	_n += 1
	if _n > 10:
		_measure()
	if _n == 50:
		root.get_texture().get_image().save_png(_out + "s53_clock_%d.png" % int(SC[_si] * 100.0))
	if _n >= 70:
		_si += 1; _n = 0
	return false
func _measure() -> void:
	if not HudDock.split(_t): return
	var lb: Label = _eye.get("_speed_lb")
	if lb == null or not lb.is_visible_in_tree() or lb.text == "": return
	var vp := Rect2(Vector2.ZERO, Vector2(root.get_visible_rect().size))
	var r := lb.get_global_rect()
	_seen[_si] += 1
	_worst[_si] = maxf(_worst[_si], r.end.y)
	if not vp.encloses(r):
		_fails += 1
		if _fails <= 6:
			print("  FAIL ", int(SC[_si] * 100.0), "% clock plate ", r, " outside ", vp, " '", lb.text, "'")
