extends SceneTree
## U226: town band at UiTheme scale 100/125/150, renown 90. Windowed. Prints U226_STEP / U226_DONE.
var _t: Node3D
var _f := 0
var _fails := 0
var _i := 0
var _at := 0
var _sc := [1.0, 1.25, 1.5]
const OUT := "res://renders/cycles/20261128_u226"
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
		var eye := RtsCamera.new()
		_t.add_child(eye)
		eye.setup(_t)
	if _f < 60:
		_at = _f
		return false
	var fh := _fh()
	if fh == null or not (fh._panel is HudDock.ChronicleScroll):
		print("U226_NOFEED")
		return true
	var cs: HudDock.ChronicleScroll = fh._panel
	var k := _f - _at
	if k == 1:
		if _i == 0:
			(_t.get("economy") as Object).set("renown", 90)
		UiTheme.set_scale(_sc[_i])
	elif k == 50:
		var br := cs.band_rect()
		var sr := cs.sheet_rect()
		var ok := not cs.town.is_empty() and sr.encloses(br)
		if not ok:
			_fails += 1
		print("U226_STEP scale=%.2f ok=%s band=%s sheet=%s margin_r=%.1f" % [_sc[_i], ok, br, sr, sr.end.x - br.end.x])
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/s%d.png" % int(_sc[_i] * 100)))
		_i += 1
		_at = _f
		if _i >= _sc.size():
			print("U226_DONE fails=%d" % _fails)
			return true
	return false
