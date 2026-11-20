extends SceneTree
## U61: where does the rod grain stripe cross the CHRONICLE wordmark at the px(8) cap floor?
## WINDOWED. Env U61TAG=before|after. Draws ChronicleScroll at panel heights that sit on the
## cap floor (h*0.05 < 8 -> h < 160) and measures stripe rows vs glyph ink rows off the pixels.
var _f := 0
var _sc: Array = []
var _holder: Control
const OUT := "res://renders/cycles/20261117_u61"
const HS := [96, 120, 150, 159, 180]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_holder = Control.new()
	_holder.size = Vector2(1920, 1080)
	root.add_child(_holder)
	var bg := ColorRect.new(); bg.color = Color(0.1, 0.1, 0.12); bg.size = Vector2(1920, 1080); _holder.add_child(bg)
	var x := 20.0
	for h in HS:
		var s := HudDock.ChronicleScroll.new()
		s.position = Vector2(x, 40); s.size = Vector2(360, h)
		_holder.add_child(s); _sc.append(s); x += 380.0

func _near(c: Color, t: Color, tol: float) -> bool:
	return absf(c.r - t.r) < tol and absf(c.g - t.g) < tol and absf(c.b - t.b) < tol

func _process(_dt: float) -> bool:
	_f += 1
	if _f < 8:
		return false
	var tag := OS.get_environment("U61TAG"); if tag == "": tag = "shot"
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + "/all_%s.png" % tag))
	for i in HS.size():
		var s: Control = _sc[i]
		var g: Dictionary = s._geo()
		var cap: float = g.cap; var tcy: float = g.top_cy
		var ys0: float = tcy + cap * UiTheme.SCROLL_GRAIN_OFF
		var ys1: float = ys0 + maxf(1.0, cap * 0.20)
		var ox := int(s.position.x); var oy := int(s.position.y)
		# glyph ink rows: pixels within tolerance of WORD_HI in the top rod band, centre third of width
		var gy0 := 9999; var gy1 := -1
		var x0 := ox + int(s.size.x * 0.30); var x1 := ox + int(s.size.x * 0.70)
		for yy in range(oy, oy + int(tcy + cap + 2)):
			for xx in range(x0, x1):
				if _near(img.get_pixel(xx, yy), UiTheme.WORD_HI, 0.05):
					gy0 = mini(gy0, yy - oy); gy1 = maxi(gy1, yy - oy); break
		print("U61 h=%d cap=%.1f top_cy=%.1f stripe=[%.2f,%.2f] ink_rows=[%d,%d] overlap=%s" % [HS[i], cap, tcy, ys0, ys1, gy0, gy1, str(ys1 > gy0 and ys0 < gy1 + 1)])
		var box := Rect2i(ox, oy, int(s.size.x), int(tcy + cap + 4))
		var cr := img.get_region(box); cr.resize(cr.get_width() * 3, cr.get_height() * 3, Image.INTERPOLATE_NEAREST)
		cr.save_png(ProjectSettings.globalize_path(OUT + "/rod_h%d_%s.png" % [HS[i], tag]))
	print("U61_SHOT done ", tag)
	return true
