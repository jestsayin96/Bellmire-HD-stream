extends SceneTree
## U62: does the U61 grain-stripe clearance hold at 100/125/150% UI scale? WINDOWED.
## For each scale: draw ChronicleScroll at heights on the px(8) cap floor (scaled with the UI),
## measure stripe rows vs WORD_HI ink rows off the pixels, print the ratio.
var _f := 0
var _si := 0
var _sc: Array = []
var _holder: Control
const OUT := "res://renders/cycles/20261117_u62"
const HS := [96, 120, 150, 159]
const SCALES := [1.0, 1.25, 1.5]
var _bad := 0
var _n := 0  # U154: scrollers whose ink was actually found

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_build()

func _build() -> void:
	if _holder: _holder.queue_free()
	_sc.clear()
	UiTheme.set_scale(SCALES[_si])
	_holder = Control.new(); _holder.size = Vector2(1920, 1080); root.add_child(_holder)
	var bg := ColorRect.new(); bg.color = Color(0.1, 0.1, 0.12); bg.size = Vector2(1920, 1080); _holder.add_child(bg)
	var x := 10.0
	for h in HS:
		var s := HudDock.ChronicleScroll.new()
		s.position = Vector2(x, 40); s.size = Vector2(440, float(h) * SCALES[_si])
		_holder.add_child(s); _sc.append(s); x += 460.0
	_f = 0

func _near(c: Color, t: Color, tol: float) -> bool:
	return absf(c.r - t.r) < tol and absf(c.g - t.g) < tol and absf(c.b - t.b) < tol

func _process(_dt: float) -> bool:
	_f += 1
	if _f < 8: return false
	var sc: float = SCALES[_si]
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + "/all_%s_%d.png" % [OS.get_environment("U62TAG"), int(sc * 100)]))
	for i in HS.size():
		var s: Control = _sc[i]
		var g: Dictionary = s._geo()
		var cap: float = g.cap; var tcy: float = g.top_cy
		var rod_bot: float = tcy + cap
		var ys0: float = maxf(tcy + cap * UiTheme.SCROLL_GRAIN_OFF, s._wm_baseline(tcy)) if OS.get_environment("U62TAG") != "before" else tcy + cap * UiTheme.SCROLL_GRAIN_OFF
		var ys1: float = ys0 + (clampf(rod_bot - ys0, 1.0, maxf(1.0, cap * 0.20)) if OS.get_environment("U62TAG") != "before" else maxf(1.0, cap * 0.20))
		var ox := int(s.position.x); var oy := int(s.position.y)
		var gy0 := 9999; var gy1 := -1
		var x0 := ox + int(s.size.x * 0.30); var x1 := ox + int(s.size.x * 0.70)
		for yy in range(oy, oy + int(tcy + cap + 2)):
			for xx in range(x0, x1):
				if _near(img.get_pixel(xx, yy), UiTheme.WORD_HI, 0.05):
					gy0 = mini(gy0, yy - oy); gy1 = maxi(gy1, yy - oy); break
		if gy1 >= 0: _n += 1
		else: print("U62 NO INK FOUND - this scroller measured nothing"); _bad += 1
		var ink_bot := float(gy1 + 1)
		var ok := ys0 >= ink_bot - 0.05 and ys1 <= rod_bot + 0.05
		if not ok: _bad += 1
		print("U62 scale=%.2f h=%d px8=%d cap=%.2f top_cy=%.2f stripe=[%.2f,%.2f] ink=[%d,%d] ink_bot=%.0f rod_bot=%.2f stripe_top-ink_bot=%.2f clear=%s" % [sc, int(HS[i] * sc), UiTheme.px(8), cap, tcy, ys0, ys1, gy0, gy1, ink_bot, rod_bot, ys0 - ink_bot, str(ok)])
		var cr := img.get_region(Rect2i(ox, oy, int(s.size.x), int(tcy + cap + 4)))
		cr.resize(cr.get_width() * 3, cr.get_height() * 3, Image.INTERPOLATE_NEAREST)
		cr.save_png(ProjectSettings.globalize_path(OUT + "/rod_%s_s%d_h%d.png" % [OS.get_environment("U62TAG"), int(sc * 100), HS[i]]))
	_si += 1
	if _si < SCALES.size():
		_build(); return false
	UiTheme.set_scale(1.0)
	print("U62_SCALES %s bad=%d measured=%d" % ["OK" if _bad == 0 else "FAIL", _bad, _n])
	return true
