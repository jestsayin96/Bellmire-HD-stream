extends SceneTree
## U218: live level-up step on the Chronicle town band. Windowed. Prints U218_STEP lines and U218_DONE.
var _t: Node3D
var _f := 0
var _fails := 0
var _stage := 0
var _last := -1
var _seq := [0, 40, 60, 90, 120, 150, 200]
var _i := 0
var _at := 0
var _eye: RtsCamera
const OUT := "res://renders/cycles/20261128_u218"
func _initialize() -> void:
	root.size = Vector2i(1920, 1080)
	_t = (load("res://Town.tscn") as PackedScene).instantiate()
	root.add_child(_t)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
func _fh() -> FeedHUD:
	for n in root.find_children("*", "", true, false):
		if n is FeedHUD:
			return n
	return null
func _process(_dt: float) -> bool:
	_f += 1
	if _f == 20:
		_eye = RtsCamera.new()
		_t.add_child(_eye)
		_eye.setup(_t)
	if _f < 60:
		_at = _f
		return false
	var fh := _fh()
	if fh == null or not (fh._panel is HudDock.ChronicleScroll):
		print("U218_NOFEED")
		return true
	var cs: HudDock.ChronicleScroll = fh._panel
	var k := _f - _at
	if k == 1:
		var eco: Object = _t.get("economy")
		eco.set("renown", int(_seq[_i]))
	elif k == 50:
		var t: Dictionary = cs.town
		var br := cs.band_rect()
		var ok := not t.is_empty() and cs.sheet_rect().encloses(br)
		if not ok:
			_fails += 1
		print("U218_STEP renown=%d ok=%s town=%s band=%s" % [_seq[_i], ok, str(t), br])
		var img := root.get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path(OUT + "/step_%d.png" % _i))
		_i += 1
		_at = _f
		if _i >= _seq.size():
			print("U218_DONE fails=%d" % _fails)
			return true
	return false
