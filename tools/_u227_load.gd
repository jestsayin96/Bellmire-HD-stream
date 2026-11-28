extends SceneTree
## U227 (L74): feed under load at UiTheme 100/125/150. Windowed. Floods fh.source, prints U227_STEP / U227_DONE.
var _t: Node3D
var _f := 0
var _fails := 0
var _i := 0
var _at := 0
var _sc := [1.0, 1.25, 1.5]
const OUT := "res://renders/cycles/20261128_u228"
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
	if fh == null:
		print("U227_NOFEED")
		return true
	var k := _f - _at
	if k == 1:
		UiTheme.set_scale(_sc[_i])
	elif k >= 10 and k < 130 and k % 2 == 0:
		var n := (k - 10) / 2
		var pre := ["Wren sold a loaf", "Tam bought a lamp", "Odo mended a fence", "The mill ground grain"]
		fh.source.append("%s %d" % [pre[n % 4], n])
		if n % 15 == 7:
			fh.source.append("LEVEL UP! Bellmire reaches a new tier %d" % n)
	elif k == 180:
		# U228: admit ONE MORE line after the scale change, then read again after a settle
		var b := fh._shown.size()
		fh.source.append("U228 settle line %d" % _i)
		print("U227_PRE scale=%.2f shown_before=%d cap=%d" % [_sc[_i], b, fh._cap()])
	elif k == 260:
		var painted := 0
		for c in fh._box.get_children():
			if not c.is_queued_for_deletion():
				painted += 1
		var pr: Rect2 = (fh._panel as Control).get_global_rect()
		var vp := Rect2(Vector2.ZERO, Vector2(root.size))
		var ok := vp.encloses(pr) and painted <= fh._cap() and fh._pending.size() <= fh.QUEUE_MAX
		if not ok:
			_fails += 1
		print("U227_STEP scale=%.2f ok=%s panel=%s shown=%d painted=%d cap=%d pending=%d stats=%s" % [_sc[_i], ok, pr, fh._shown.size(), painted, fh._cap(), fh._pending.size(), fh.stats])
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/s%d.png" % int(_sc[_i] * 100)))
		_i += 1
		_at = _f
		if _i >= _sc.size():
			print("U227_DONE fails=%d" % _fails)
			return true
	return false
